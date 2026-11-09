const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('./db');
const { gerarToken, exigirLogin } = require('./auth');
const { validar, ErroHttp } = require('./validacao');
const { comStatus, medicacaoAtrasada, noDia, alertasSinais, HORA } = require('./regras');
const { gerarSbarSetor } = require('./sbar');

const router = express.Router();

// ---------- auxiliares ----------

const porData = (campo, desc = true) => (a, b) =>
  desc ? new Date(b[campo]) - new Date(a[campo]) : new Date(a[campo]) - new Date(b[campo]);

const ordenarLeito = (a, b) => a.leito.localeCompare(b.leito, 'pt-BR', { numeric: true });

function buscar(colecao, id, mensagem) {
  const item = db.colecao(colecao).find((x) => x.id === id);
  if (!item) throw new ErroHttp(404, mensagem);
  return item;
}

function setorOuErro(id) {
  return buscar('setores', id, `Setor "${id}" não encontrado`);
}

/** Pacientes internados (sem alta) – opcionalmente de um setor. */
function internados(setorId) {
  return db.colecao('pacientes').filter((p) => !p.alta && (!setorId || p.setorId === setorId));
}

/** Leitos do setor no formato "CM-01", "CM-02"... */
function leitosDoSetor(setor) {
  const prefixo = setor.id.toUpperCase();
  return Array.from({ length: setor.leitos }, (_, i) => `${prefixo}-${String(i + 1).padStart(2, '0')}`);
}

function internadoOuErro(id) {
  const p = buscar('pacientes', id, 'Paciente não encontrado');
  if (p.alta) throw new ErroHttp(409, `${p.nome} já saiu do setor (${ROTULO_SAIDA[p.alta.tipo]}) em ${dataBr(p.alta.em)}`);
  return p;
}

const ROTULO_SAIDA = { alta: 'alta hospitalar', transferencia: 'transferência', obito: 'óbito' };

const dataBr = (iso) =>
  new Date(iso).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

/** Aceita lista de textos ou texto separado por vírgula. */
function listaDeTextos(valor, rotulo, erros) {
  if (valor === undefined || valor === null || valor === '') return [];
  const lista = Array.isArray(valor) ? valor : typeof valor === 'string' ? valor.split(',') : null;
  if (!lista || lista.some((x) => typeof x !== 'string')) {
    erros.push(`${rotulo} deve ser uma lista de textos`);
    return [];
  }
  const limpa = [...new Set(lista.map((x) => x.trim()).filter(Boolean))];
  if (limpa.length > 20 || limpa.some((x) => x.length > 80)) erros.push(`${rotulo}: no máximo 20 itens de até 80 caracteres`);
  return limpa;
}

function resumoPaciente(p, agora = new Date()) {
  const atrasadas = db.colecao('medicacoes').filter((m) => m.pacienteId === p.id && medicacaoAtrasada(m, agora)).length;
  const abertas = db.colecao('pendencias').filter((x) => x.pacienteId === p.id && x.status === 'pendente').length;
  const ultimoSv = db
    .colecao('sinaisVitais')
    .filter((s) => s.pacienteId === p.id)
    .sort(porData('registradoEm'))[0];
  return {
    id: p.id,
    setorId: p.setorId,
    leito: p.leito,
    nome: p.nome,
    idade: p.idade,
    sexo: p.sexo,
    diagnostico: p.diagnostico,
    alergias: p.alergias,
    risco: p.risco,
    medicacoesAtrasadas: atrasadas,
    pendencias: atrasadas + abertas,
    alertas: alertasSinais(ultimoSv),
  };
}

const usuarioPublico = ({ senhaHash, ...u }) => u;

// ---------- rotas públicas ----------

router.get('/health', (_req, res) => res.json({ status: 'ok', horario: new Date().toISOString() }));

router.post('/auth/login', (req, res) => {
  const { usuario, senha } = validar(req.body, {
    usuario: { tipo: 'string', obrigatorio: true, rotulo: 'Usuário' },
    senha: { tipo: 'string', obrigatorio: true, rotulo: 'Senha' },
  });
  const u = db.colecao('usuarios').find((x) => x.usuario.toLowerCase() === usuario.toLowerCase());
  if (!u || !bcrypt.compareSync(senha, u.senhaHash)) throw new ErroHttp(401, 'Usuário ou senha incorretos');
  const setor = db.colecao('setores').find((s) => s.id === u.setorId);
  res.json({ token: gerarToken(u), usuario: { ...usuarioPublico(u), setor: setor || null } });
});

// ---------- rotas autenticadas ----------

router.use(exigirLogin);

router.get('/setores', (_req, res) => {
  const agora = new Date();
  const setores = db.colecao('setores').map((s) => {
    const pacientes = internados(s.id);
    const resumos = pacientes.map((p) => resumoPaciente(p, agora));
    return {
      ...s,
      pacientes: pacientes.length,
      riscoAlto: pacientes.filter((p) => p.risco === 'alto').length,
      medicacoesAtrasadas: resumos.reduce((t, r) => t + r.medicacoesAtrasadas, 0),
    };
  });
  res.json(setores);
});

router.get('/setores/:id/pacientes', (req, res) => {
  setorOuErro(req.params.id);
  const agora = new Date();
  const lista = internados(req.params.id)
    .sort(ordenarLeito)
    .map((p) => resumoPaciente(p, agora));
  res.json(lista);
});

// Mapa de leitos do setor (livres e ocupados) – usado na admissão.
router.get('/setores/:id/leitos', (req, res) => {
  const setor = setorOuErro(req.params.id);
  const ocupados = new Map(internados(setor.id).map((p) => [p.leito, p]));
  res.json(
    leitosDoSetor(setor).map((leito) => {
      const p = ocupados.get(leito);
      return { leito, ocupado: Boolean(p), paciente: p ? { id: p.id, nome: p.nome } : null };
    }),
  );
});

// Admissão (entrada) de paciente em um leito livre.
router.post('/setores/:id/pacientes', (req, res) => {
  const setor = setorOuErro(req.params.id);
  const erros = [];
  let dados = {};
  try {
    dados = validar(req.body, {
      nome: { tipo: 'string', obrigatorio: true, maxLen: 120, rotulo: 'Nome' },
      idade: { tipo: 'inteiro', obrigatorio: true, min: 0, max: 120, rotulo: 'Idade' },
      sexo: { tipo: 'string', obrigatorio: true, opcoes: ['F', 'M'], rotulo: 'Sexo' },
      leito: { tipo: 'string', obrigatorio: true, rotulo: 'Leito' },
      diagnostico: { tipo: 'string', obrigatorio: true, maxLen: 200, rotulo: 'Diagnóstico' },
      risco: { tipo: 'string', obrigatorio: true, opcoes: ['baixo', 'medio', 'alto'], rotulo: 'Risco' },
      historico: { tipo: 'string', maxLen: 1000, rotulo: 'Histórico' },
      dieta: { tipo: 'string', maxLen: 200, rotulo: 'Dieta' },
    });
  } catch (e) {
    if (!(e instanceof ErroHttp)) throw e;
    erros.push(...e.detalhes);
  }
  // Junta todos os problemas numa única resposta (campos, listas e leito).
  const alergias = listaDeTextos(req.body?.alergias, 'Alergias', erros);
  const dispositivos = listaDeTextos(req.body?.dispositivos, 'Dispositivos', erros);
  const leito = typeof req.body?.leito === 'string' ? req.body.leito.trim().toUpperCase() : '';
  if (leito && !leitosDoSetor(setor).includes(leito)) erros.push(`Leito ${leito} não existe em ${setor.nome}`);
  if (erros.length) throw new ErroHttp(400, 'Dados inválidos', erros);
  const ocupante = internados(setor.id).find((p) => p.leito === leito);
  if (ocupante) throw new ErroHttp(409, `O leito ${leito} já está ocupado por ${ocupante.nome}`);

  const agora = new Date();
  const paciente = db.inserir('pacientes', {
    setorId: setor.id,
    leito,
    nome: dados.nome,
    idade: dados.idade,
    sexo: dados.sexo,
    diagnostico: dados.diagnostico,
    alergias,
    risco: dados.risco,
    historico: dados.historico || '',
    dispositivos,
    dieta: dados.dieta || '',
    dataInternacao: agora.toISOString(),
    admitidoPor: req.usuario.nome,
  });
  // Rotina de admissão: primeira aferição de sinais vitais em até 1 hora.
  db.inserir('pendencias', {
    pacienteId: paciente.id,
    tipo: 'procedimento',
    descricao: 'Admissão: aferir sinais vitais e conferir pulseira de identificação',
    prazo: new Date(agora.getTime() + HORA).toISOString(),
    status: 'pendente',
    criadoEm: agora.toISOString(),
  });
  res.status(201).json(resumoPaciente(paciente, agora));
});

// Saída do paciente: alta hospitalar, transferência ou óbito. O leito fica livre.
router.post('/pacientes/:id/alta', (req, res) => {
  const p = internadoOuErro(req.params.id);
  const dados = validar(req.body, {
    tipo: { tipo: 'string', obrigatorio: true, opcoes: Object.keys(ROTULO_SAIDA), rotulo: 'Tipo de saída' },
    destino: { tipo: 'string', maxLen: 200, rotulo: 'Destino' },
    observacao: { tipo: 'string', maxLen: 1000, rotulo: 'Observação' },
  });
  p.alta = {
    tipo: dados.tipo,
    destino: dados.destino || '',
    observacao: dados.observacao || '',
    em: new Date().toISOString(),
    por: req.usuario.nome,
  };
  db.salvar();
  res.json({ ...p, ...resumoPaciente(p) });
});

// Altas e transferências recentes do setor (últimos 7 dias).
router.get('/setores/:id/altas', (req, res) => {
  setorOuErro(req.params.id);
  const limite = Date.now() - 7 * 24 * HORA;
  res.json(
    db
      .colecao('pacientes')
      .filter((p) => p.setorId === req.params.id && p.alta && new Date(p.alta.em).getTime() >= limite)
      .sort((a, b) => new Date(b.alta.em) - new Date(a.alta.em))
      .map((p) => ({ id: p.id, nome: p.nome, leito: p.leito, idade: p.idade, sexo: p.sexo, diagnostico: p.diagnostico, alta: p.alta })),
  );
});

router.get('/pacientes/:id', (req, res) => {
  const p = buscar('pacientes', req.params.id, 'Paciente não encontrado');
  const agora = new Date();
  const sinais = db.colecao('sinaisVitais').filter((s) => s.pacienteId === p.id).sort(porData('registradoEm'));
  res.json({
    ...p,
    ...resumoPaciente(p, agora),
    historico: p.historico,
    dispositivos: p.dispositivos,
    dieta: p.dieta,
    dataInternacao: p.dataInternacao,
    sinaisVitais: sinais.slice(0, 10),
    medicacoes: db
      .colecao('medicacoes')
      .filter((m) => m.pacienteId === p.id && (noDia(m, agora) || medicacaoAtrasada(m, agora)))
      .sort(porData('horario', false))
      .map((m) => comStatus(m, agora)),
    intercorrencias: db.colecao('intercorrencias').filter((i) => i.pacienteId === p.id).sort(porData('horario')),
    pendenciasLista: db
      .colecao('pendencias')
      .filter((x) => x.pacienteId === p.id)
      .sort(porData('prazo', false)),
  });
});

router.post('/pacientes/:id/sinais-vitais', (req, res) => {
  const p = internadoOuErro(req.params.id);
  const dados = validar(req.body, {
    pas: { tipo: 'inteiro', obrigatorio: true, min: 40, max: 300, rotulo: 'PA sistólica' },
    pad: { tipo: 'inteiro', obrigatorio: true, min: 20, max: 200, rotulo: 'PA diastólica' },
    fc: { tipo: 'inteiro', obrigatorio: true, min: 20, max: 250, rotulo: 'Frequência cardíaca' },
    fr: { tipo: 'inteiro', obrigatorio: true, min: 4, max: 80, rotulo: 'Frequência respiratória' },
    temperatura: { tipo: 'numero', obrigatorio: true, min: 30, max: 45, rotulo: 'Temperatura' },
    satO2: { tipo: 'inteiro', obrigatorio: true, min: 50, max: 100, rotulo: 'SatO2' },
    dor: { tipo: 'inteiro', obrigatorio: true, min: 0, max: 10, rotulo: 'Dor' },
    observacao: { tipo: 'string', maxLen: 500, rotulo: 'Observação' },
  });
  if (dados.pad >= dados.pas) throw new ErroHttp(400, 'Dados inválidos', ['PA diastólica deve ser menor que a sistólica']);
  const registro = db.inserir('sinaisVitais', {
    pacienteId: p.id,
    ...dados,
    temperatura: Math.round(dados.temperatura * 10) / 10,
    observacao: dados.observacao || '',
    registradoEm: new Date().toISOString(),
    responsavel: req.usuario.nome,
  });
  res.status(201).json({ ...registro, alertas: alertasSinais(registro) });
});

router.post('/pacientes/:id/intercorrencias', (req, res) => {
  const p = internadoOuErro(req.params.id);
  const dados = validar(req.body, {
    descricao: { tipo: 'string', obrigatorio: true, maxLen: 1000, rotulo: 'Descrição' },
    gravidade: { tipo: 'string', obrigatorio: true, opcoes: ['leve', 'moderada', 'grave'], rotulo: 'Gravidade' },
    horario: { tipo: 'data', rotulo: 'Horário' },
  });
  const agora = new Date();
  if (dados.horario && new Date(dados.horario) > new Date(agora.getTime() + 5 * 60 * 1000)) {
    throw new ErroHttp(400, 'Dados inválidos', ['Horário não pode estar no futuro']);
  }
  const registro = db.inserir('intercorrencias', {
    pacienteId: p.id,
    descricao: dados.descricao,
    gravidade: dados.gravidade,
    horario: dados.horario || agora.toISOString(),
    registradoEm: agora.toISOString(),
    responsavel: req.usuario.nome,
  });
  res.status(201).json(registro);
});

router.patch('/medicacoes/:id', (req, res) => {
  const med = buscar('medicacoes', req.params.id, 'Medicação não encontrada');
  const dados = validar(req.body, {
    status: { tipo: 'string', opcoes: ['administrada', 'pendente'], rotulo: 'Status' },
    administradaEm: { tipo: 'data', rotulo: 'Horário de administração' },
  });
  const status = dados.status || 'administrada';
  if (status === 'administrada') {
    if (med.status === 'administrada') throw new ErroHttp(409, `Esta dose já foi administrada por ${med.responsavel}`);
    med.status = 'administrada';
    med.administradaEm = dados.administradaEm || new Date().toISOString();
    med.responsavel = req.usuario.nome;
  } else {
    // Desfazer um registro feito por engano.
    med.status = 'pendente';
    med.administradaEm = null;
    med.responsavel = null;
  }
  db.salvar();
  res.json(comStatus(med));
});

router.patch('/pendencias/:id', (req, res) => {
  const pend = buscar('pendencias', req.params.id, 'Pendência não encontrada');
  const { status } = validar(req.body, {
    status: { tipo: 'string', obrigatorio: true, opcoes: ['pendente', 'concluida'], rotulo: 'Status' },
  });
  pend.status = status;
  pend.concluidaEm = status === 'concluida' ? new Date().toISOString() : null;
  pend.concluidaPor = status === 'concluida' ? req.usuario.nome : null;
  db.salvar();
  res.json(pend);
});

router.get('/pendencias', (req, res) => {
  const setorId = req.query.setor;
  if (!setorId) throw new ErroHttp(400, 'Informe o setor: /pendencias?setor=<id>');
  setorOuErro(setorId);
  const agora = new Date();
  const pacientes = new Map(internados(setorId).map((p) => [p.id, p]));
  const comPaciente = (x) => {
    const p = pacientes.get(x.pacienteId);
    return { ...x, paciente: { id: p.id, nome: p.nome, leito: p.leito, risco: p.risco } };
  };
  const medicacoesAtrasadas = db
    .colecao('medicacoes')
    .filter((m) => pacientes.has(m.pacienteId) && medicacaoAtrasada(m, agora))
    .sort(porData('horario', false))
    .map((m) => comPaciente(comStatus(m, agora)));
  const abertas = db
    .colecao('pendencias')
    .filter((x) => pacientes.has(x.pacienteId) && x.status === 'pendente')
    .sort(porData('prazo', false))
    .map((x) => ({ ...comPaciente(x), vencida: new Date(x.prazo) < agora }));
  const exames = abertas.filter((x) => x.tipo === 'exame');
  const procedimentos = abertas.filter((x) => x.tipo === 'procedimento');
  const retornos = abertas.filter((x) => x.tipo === 'retorno');
  res.json({
    setorId,
    total: medicacoesAtrasadas.length + abertas.length,
    medicacoesAtrasadas,
    exames,
    procedimentos,
    retornos,
  });
});

router.post('/plantoes', (req, res) => {
  const dados = validar(req.body, {
    setorId: { tipo: 'string', rotulo: 'Setor' },
    inicio: { tipo: 'data', rotulo: 'Início do turno' },
    observacoes: { tipo: 'string', maxLen: 2000, rotulo: 'Observações' },
  });
  const setorId = dados.setorId || req.usuario.setorId;
  const setor = setorOuErro(setorId);
  const fim = new Date();

  // Por padrão o turno começa no fim do último plantão do setor (no máximo 12 h atrás).
  let inicio;
  if (dados.inicio) {
    inicio = new Date(dados.inicio);
    if (inicio >= fim) throw new ErroHttp(400, 'Dados inválidos', ['Início do turno deve ser anterior a agora']);
    if (fim - inicio > 24 * HORA) throw new ErroHttp(400, 'Dados inválidos', ['O turno não pode ter mais de 24 horas']);
  } else {
    const ultimo = db
      .colecao('plantoes')
      .filter((p) => p.setorId === setorId)
      .sort(porData('fim'))[0];
    const limite = new Date(fim.getTime() - 12 * HORA);
    inicio = ultimo && new Date(ultimo.fim) > limite ? new Date(ultimo.fim) : limite;
  }

  const pacientes = internados(setorId);
  const ids = new Set(pacientes.map((p) => p.id));
  const noTurno = (iso) => iso && new Date(iso) >= inicio && new Date(iso) <= fim;
  const movimentacoes = {
    // Inclui quem foi admitido e já saiu no mesmo turno.
    admissoes: db
      .colecao('pacientes')
      .filter((p) => p.setorId === setorId && p.admitidoPor && noTurno(p.dataInternacao))
      .map((p) => ({ leito: p.leito, nome: p.nome, por: p.admitidoPor, em: p.dataInternacao })),
    saidas: db
      .colecao('pacientes')
      .filter((p) => p.setorId === setorId && p.alta && noTurno(p.alta.em))
      .map((p) => ({ leito: p.leito, nome: p.nome, tipo: p.alta.tipo, destino: p.alta.destino, por: p.alta.por, em: p.alta.em })),
  };
  const doSetor = (c) => db.colecao(c).filter((x) => ids.has(x.pacienteId));
  const resumo = gerarSbarSetor({
    pacientes,
    sinaisVitais: doSetor('sinaisVitais'),
    intercorrencias: doSetor('intercorrencias'),
    medicacoes: doSetor('medicacoes'),
    pendencias: doSetor('pendencias'),
    inicio,
    fim,
  });

  const plantao = db.inserir('plantoes', {
    setorId,
    setorNome: setor.nome,
    responsavel: { id: req.usuario.id, nome: req.usuario.nome, cargo: req.usuario.cargo },
    inicio: inicio.toISOString(),
    fim: fim.toISOString(),
    observacoes: dados.observacoes || '',
    movimentacoes,
    totais: {
      pacientes: resumo.length,
      medicacoesAtrasadas: resumo.reduce((t, r) => t + r.medicacoesAtrasadas, 0),
      pendencias: resumo.reduce((t, r) => t + r.pendenciasAbertas, 0),
      comAlerta: resumo.filter((r) => r.alertas.length).length,
    },
    resumo,
    confirmacao: null,
  });
  res.status(201).json(plantao);
});

router.get('/plantoes', (req, res) => {
  const setorId = req.query.setor;
  if (setorId) setorOuErro(setorId);
  const lista = db
    .colecao('plantoes')
    .filter((p) => !setorId || p.setorId === setorId)
    .sort(porData('fim'))
    .map(({ resumo, ...p }) => p);
  res.json(lista);
});

router.get('/plantoes/:id', (req, res) => {
  res.json(buscar('plantoes', req.params.id, 'Plantão não encontrado'));
});

router.post('/plantoes/:id/confirmar', (req, res) => {
  const plantao = buscar('plantoes', req.params.id, 'Plantão não encontrado');
  if (plantao.confirmacao) {
    throw new ErroHttp(409, `Este plantão já foi assumido por ${plantao.confirmacao.nome}`);
  }
  if (plantao.responsavel.id === req.usuario.id) {
    throw new ErroHttp(422, 'Quem encerrou o turno não pode confirmar o próprio plantão. Peça para o profissional que assume.');
  }
  plantao.confirmacao = {
    usuarioId: req.usuario.id,
    nome: req.usuario.nome,
    cargo: req.usuario.cargo,
    confirmadoEm: new Date().toISOString(),
  };
  db.salvar();
  res.json(plantao);
});

module.exports = router;
