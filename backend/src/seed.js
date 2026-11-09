// Gera dados 100% FICTÍCIOS para demonstração. Nenhum dado real de paciente.
// Os horários das medicações são calculados a partir do momento em que o seed roda,
// para que sempre existam doses atrasadas, já administradas e futuras.
const bcrypt = require('bcryptjs');

const HORA = 60 * 60 * 1000;
const SENHA_PADRAO = 'plantao123';

// Gerador pseudoaleatório determinístico: os pacientes são sempre os mesmos.
function criarAleatorio(semente = 42) {
  let s = semente;
  const rnd = () => {
    s = (s * 1664525 + 1013904223) % 4294967296;
    return s / 4294967296;
  };
  return {
    rnd,
    entre: (min, max) => Math.floor(rnd() * (max - min + 1)) + min,
    um: (lista) => lista[Math.floor(rnd() * lista.length)],
    chance: (p) => rnd() < p,
  };
}

const SETORES = [
  { id: 'cm', nome: 'Clínica Médica', andar: '3º andar', leitos: 12 },
  { id: 'ped', nome: 'Pediatria', andar: '4º andar', leitos: 10 },
];

const PACIENTES_CM = [
  ['Aurora Vilela Prado', 74, 'F', 'Pneumonia comunitária', ['Dipirona'], 'alto', 'Hipertensa e diabética. Chegou pelo PS com dispneia há 3 dias.', ['Acesso venoso periférico MSE', 'Cateter nasal O2 2 L/min'], 'Branda hipossódica'],
  ['Benedito Ramos Quaresma', 68, 'M', 'Insuficiência cardíaca descompensada', [], 'alto', 'ICC classe III, em uso de diurético. Ganho de 3 kg na última semana.', ['Acesso venoso periférico MSD'], 'Hipossódica, restrição hídrica 1 L/dia'],
  ['Celina Duarte Fontes', 59, 'F', 'Infecção do trato urinário complicada', ['Penicilina'], 'medio', 'Diabética tipo 2. Febre e disúria há 4 dias.', ['Acesso venoso periférico MSE'], 'Para diabético'],
  ['Dorival Espíndola Neto', 81, 'M', 'AVC isquêmico (pós-fase aguda)', [], 'alto', 'Hemiparesia à direita. Alto risco de queda e de lesão por pressão.', ['Sonda nasoenteral', 'Fralda'], 'Enteral 60 mL/h'],
  ['Eunice Barreto Lins', 45, 'F', 'Celulite em membro inferior', ['Sulfa'], 'baixo', 'Sem comorbidades. Lesão em perna esquerda há 1 semana.', ['Acesso venoso periférico MSD'], 'Livre'],
  ['Fabrício Moura Teles', 52, 'M', 'Cetoacidose diabética (em resolução)', [], 'medio', 'DM1 com má adesão à insulina. Glicemias de 4/4 h.', ['Acesso venoso central jugular D'], 'Para diabético'],
  ['Glória Antunes Rocha', 66, 'F', 'DPOC exacerbado', ['AAS'], 'alto', 'Ex-tabagista (40 anos-maço). Usa O2 domiciliar.', ['Cateter nasal O2 1 L/min'], 'Branda'],
  ['Heitor Cavalcante Bispo', 39, 'M', 'Pancreatite aguda leve', [], 'medio', 'Etilista. Dor abdominal em faixa, melhorando.', ['Acesso venoso periférico MSE'], 'Jejum, reavaliar amanhã'],
  ['Iolanda Prates Viana', 77, 'F', 'Fratura de colo de fêmur (pré-operatório)', ['Látex', 'Iodo'], 'alto', 'Queda da própria altura. Aguarda cirurgia ortopédica.', ['Acesso venoso periférico MSD', 'Sonda vesical de demora'], 'Jejum a partir de 0 h'],
  ['Jurandir Teixeira Lobo', 63, 'M', 'Hemorragia digestiva alta (estável)', [], 'medio', 'Úlcera péptica. Recebeu 2 concentrados de hemácias ontem.', ['Acesso venoso periférico MSE'], 'Líquida'],
  ['Kátia Albuquerque Sá', 34, 'F', 'Pielonefrite aguda', ['Dipirona'], 'baixo', 'Gestação descartada. Boa resposta ao antibiótico.', ['Acesso venoso periférico MSD'], 'Livre'],
];

const PACIENTES_PED = [
  ['Lucas Andrade Peixoto', 6, 'M', 'Bronquiolite / broncoespasmo', [], 'medio', 'Asma leve. Mãe acompanha. Peso 21 kg.', ['Acesso venoso periférico MSE'], 'Livre para idade'],
  ['Manuela Siqueira Torres', 3, 'F', 'Pneumonia', ['Amoxicilina'], 'alto', 'Febre persistente há 5 dias. Peso 14 kg.', ['Acesso venoso periférico MSD', 'Cateter nasal O2 1 L/min'], 'Livre para idade'],
  ['Nicolas Freitas Amaral', 9, 'M', 'Apendicite (pós-operatório 1º dia)', [], 'medio', 'Apendicectomia ontem à tarde. Peso 30 kg.', ['Acesso venoso periférico MSE', 'Curativo FO abdominal'], 'Líquida'],
  ['Olívia Pacheco Ventura', 1, 'F', 'Gastroenterite com desidratação', [], 'alto', 'Lactente, 9 kg. Vômitos e diarreia há 2 dias.', ['Acesso venoso periférico MSD'], 'Soro de reidratação + leite materno'],
  ['Pedro Henrique Galvão', 12, 'M', 'Crise convulsiva (em investigação)', ['Carbamazepina'], 'alto', 'Primeira crise há 24 h. Aguarda eletroencefalograma.', ['Acesso venoso periférico MSE'], 'Livre'],
  ['Rafaela Moreira Dias', 7, 'F', 'Celulite periorbitária', [], 'baixo', 'Picada de inseto há 3 dias. Peso 24 kg.', ['Acesso venoso periférico MSD'], 'Livre'],
  ['Samuel Xavier Brito', 4, 'M', 'Infecção urinária febril', ['Dipirona'], 'medio', 'Refluxo vesicoureteral conhecido. Peso 16 kg.', ['Acesso venoso periférico MSE'], 'Livre para idade'],
  ['Talita Rezende Campos', 10, 'F', 'Diabetes tipo 1 (diagnóstico recente)', [], 'medio', 'Educação em diabetes com a família. Peso 32 kg.', ['Acesso venoso periférico MSD'], 'Para diabético'],
  ['Vicente Lacerda Moura', 2, 'M', 'Laringite (crupe)', [], 'baixo', 'Estridor leve, melhorando com corticoide. Peso 12 kg.', [], 'Livre para idade'],
];

// [nome, dose, via, intervalo em horas]
const MEDS_ADULTO = [
  ['Ceftriaxona', '1 g', 'EV', 12], ['Dipirona', '1 g', 'EV', 6], ['Omeprazol', '40 mg', 'EV', 24],
  ['Enoxaparina', '40 mg', 'SC', 24], ['Furosemida', '40 mg', 'EV', 12], ['Insulina regular', 'conforme glicemia', 'SC', 6],
  ['Ondansetrona', '8 mg', 'EV', 8], ['Paracetamol', '750 mg', 'VO', 6], ['Losartana', '50 mg', 'VO', 12],
  ['Piperacilina + Tazobactam', '4,5 g', 'EV', 8], ['Metoclopramida', '10 mg', 'EV', 8], ['Tramadol', '50 mg', 'EV', 8],
];
const MEDS_PED = [
  ['Amoxicilina + Clavulanato', '15 mg/kg', 'VO', 8], ['Paracetamol gotas', '10 mg/kg', 'VO', 6], ['Ceftriaxona', '50 mg/kg', 'EV', 12],
  ['Salbutamol spray', '4 jatos', 'Inalatória', 4], ['Prednisolona', '1 mg/kg', 'VO', 24], ['Ondansetrona', '0,15 mg/kg', 'EV', 8],
  ['Soro de manutenção', 'conforme prescrição', 'EV', 6],
];

const PENDENCIAS = [
  ['exame', 'Coletar hemograma e PCR de controle'], ['exame', 'Raio-X de tórax de controle'], ['exame', 'Resultado de hemocultura'],
  ['exame', 'Ultrassom de abdome agendado'], ['exame', 'Glicemia capilar 4/4 h'], ['procedimento', 'Troca de curativo'],
  ['procedimento', 'Trocar acesso venoso (72 h)'], ['procedimento', 'Passar sonda vesical de alívio se não urinar'],
  ['retorno', 'Aguardando parecer da cardiologia'], ['retorno', 'Avaliação da nutrição'], ['retorno', 'Retorno do cirurgião após exames'],
];

const OBS_SV = ['', '', '', 'Paciente tranquilo(a).', 'Refere dor leve.', 'Aceitou bem a dieta.', 'Sonolento(a), desperta ao chamado.'];

function gerarDados(agora = new Date(), semente = 42) {
  const r = criarAleatorio(semente);
  const hashSenha = bcrypt.hashSync(SENHA_PADRAO, 8);

  const usuarios = [
    { id: 'u1', usuario: 'ana.enfermeira', nome: 'Ana Ribeiro', cargo: 'Enfermeira', registro: 'COREN-SP 000001 (fictício)', setorId: 'cm' },
    { id: 'u2', usuario: 'bruno.tecnico', nome: 'Bruno Carvalho', cargo: 'Técnico de enfermagem', registro: 'COREN-SP 000002 (fictício)', setorId: 'cm' },
    { id: 'u3', usuario: 'carla.medica', nome: 'Dra. Carla Nogueira', cargo: 'Médica', registro: 'CRM-SP 000003 (fictício)', setorId: 'ped' },
    { id: 'u4', usuario: 'diego.enfermeiro', nome: 'Diego Martins', cargo: 'Enfermeiro', registro: 'COREN-SP 000004 (fictício)', setorId: 'ped' },
  ].map((u) => ({ ...u, senhaHash: hashSenha }));

  const pacientes = [];
  const montar = (lista, setorId, prefixo) =>
    lista.forEach(([nome, idade, sexo, diagnostico, alergias, risco, historico, dispositivos, dieta], i) => {
      pacientes.push({
        id: `${setorId}_p${i + 1}`,
        setorId,
        leito: `${prefixo}-${String(i + 1).padStart(2, '0')}`,
        nome,
        idade,
        sexo,
        diagnostico,
        alergias,
        risco,
        historico,
        dispositivos,
        dieta,
        dataInternacao: new Date(agora.getTime() - r.entre(1, 9) * 24 * HORA).toISOString(),
      });
    });
  montar(PACIENTES_CM, 'cm', 'CM');
  montar(PACIENTES_PED, 'ped', 'PED');

  // Doses alinhadas a horários "de relógio" (múltiplos do intervalo), entre -12 h e +12 h.
  const medicacoes = [];
  let contMed = 0;
  const profissionais = { cm: ['Ana Ribeiro', 'Bruno Carvalho'], ped: ['Diego Martins', 'Dra. Carla Nogueira'] };
  for (const p of pacientes) {
    // Nunca prescreve um medicamento ao qual o paciente fictício é alérgico.
    const catalogo = (p.setorId === 'ped' ? MEDS_PED : MEDS_ADULTO).filter(
      ([nome]) => !p.alergias.some((a) => nome.toLowerCase().includes(a.toLowerCase())),
    );
    const escolhidas = new Set();
    const qtd = r.entre(2, 4);
    while (escolhidas.size < qtd) escolhidas.add(r.um(catalogo));
    for (const [nome, dose, via, intervalo] of escolhidas) {
      // Começa à meia-noite de ontem e percorre 3 dias; ex.: 12/12 h → 08:00 e 20:00.
      const ontem = new Date(agora);
      ontem.setHours(0, 0, 0, 0);
      ontem.setDate(ontem.getDate() - 1);
      for (let h = 8 % intervalo; h < 72; h += intervalo) {
        const horario = new Date(ontem.getTime() + h * HORA);
        const diff = horario.getTime() - agora.getTime();
        if (diff < -12 * HORA || diff > 12 * HORA) continue;
        const passou = diff < 0;
        // ~75% das doses passadas foram administradas; o resto vira "atrasada".
        const administrada = passou && (diff < -30 * 60 * 1000 ? r.chance(0.75) : r.chance(0.4));
        medicacoes.push({
          id: `med_${++contMed}`,
          pacienteId: p.id,
          nome,
          dose,
          via,
          horario: horario.toISOString(),
          status: administrada ? 'administrada' : 'pendente',
          administradaEm: administrada ? new Date(horario.getTime() + r.entre(0, 25) * 60 * 1000).toISOString() : null,
          responsavel: administrada ? r.um(profissionais[p.setorId]) : null,
        });
      }
    }
  }

  const sinaisVitais = [];
  let contSv = 0;
  for (const p of pacientes) {
    const crianca = p.idade < 12;
    const n = r.entre(1, 3);
    for (let k = 0; k < n; k++) {
      const grave = p.risco === 'alto' && r.chance(0.35);
      sinaisVitais.push({
        id: `sv_${++contSv}`,
        pacienteId: p.id,
        pas: crianca ? r.entre(90, 110) : grave ? r.entre(150, 170) : r.entre(105, 140),
        pad: crianca ? r.entre(55, 70) : r.entre(65, 90),
        fc: crianca ? r.entre(90, 130) : grave ? r.entre(105, 125) : r.entre(64, 98),
        fr: crianca ? r.entre(20, 32) : grave ? r.entre(22, 28) : r.entre(14, 20),
        temperatura: Number((grave ? 37.6 + r.rnd() * 1.2 : 36.1 + r.rnd() * 1.1).toFixed(1)),
        satO2: grave ? r.entre(88, 92) : r.entre(94, 99),
        dor: r.entre(0, grave ? 7 : 4),
        observacao: r.um(OBS_SV),
        registradoEm: new Date(agora.getTime() - (2 + k * 3 + r.rnd()) * HORA).toISOString(),
        responsavel: r.um(profissionais[p.setorId]),
      });
    }
  }

  const intercorrencias = [
    { id: 'int_1', pacienteId: 'cm_p1', descricao: 'Queda de saturação para 88% em ar ambiente; instalado O2 2 L/min com melhora.', gravidade: 'moderada', horas: 3 },
    { id: 'int_2', pacienteId: 'cm_p4', descricao: 'Episódio de vômito após dieta enteral; dieta pausada por 1 h.', gravidade: 'leve', horas: 5 },
    { id: 'int_3', pacienteId: 'ped_p5', descricao: 'Nova crise convulsiva de 2 min, revertida com diazepam conforme prescrição.', gravidade: 'grave', horas: 2 },
    { id: 'int_4', pacienteId: 'ped_p2', descricao: 'Febre de 39,1 °C; administrado antitérmico e compressas.', gravidade: 'moderada', horas: 4 },
  ].map(({ horas, ...i }) => {
    const horario = new Date(agora.getTime() - horas * HORA).toISOString();
    return { ...i, horario, registradoEm: horario, responsavel: i.pacienteId.startsWith('cm') ? 'Ana Ribeiro' : 'Diego Martins' };
  });

  const pendencias = [];
  let contPend = 0;
  for (const p of pacientes) {
    const n = r.chance(0.3) ? 0 : r.entre(1, 2);
    const usadas = new Set();
    while (usadas.size < n) usadas.add(r.um(PENDENCIAS));
    for (const [tipo, descricao] of usadas) {
      pendencias.push({
        id: `pend_${++contPend}`,
        pacienteId: p.id,
        tipo,
        descricao,
        prazo: new Date(agora.getTime() + r.entre(-3, 10) * HORA).toISOString(),
        status: 'pendente',
        criadoEm: new Date(agora.getTime() - r.entre(4, 30) * HORA).toISOString(),
      });
    }
  }

  return {
    geradoEm: agora.toISOString(),
    aviso: 'Todos os dados são fictícios e gerados automaticamente para fins acadêmicos.',
    usuarios,
    setores: SETORES,
    pacientes,
    medicacoes,
    sinaisVitais,
    intercorrencias,
    pendencias,
    plantoes: [],
  };
}

module.exports = { gerarDados, SENHA_PADRAO };

if (require.main === module) {
  const config = require('./config');
  const db = require('./db');
  db.abrir(config.dbFile);
  const dados = gerarDados();
  db.substituir(dados);
  const atrasadas = dados.medicacoes.filter(
    (m) => m.status === 'pendente' && new Date(m.horario).getTime() + config.toleranciaAtrasoMin * 60000 < Date.now(),
  ).length;
  console.log(`Seed concluído em ${config.dbFile}`);
  console.log(
    `  ${dados.setores.length} setores, ${dados.pacientes.length} pacientes, ${dados.medicacoes.length} doses ` +
      `(${atrasadas} atrasadas), ${dados.sinaisVitais.length} sinais vitais, ${dados.pendencias.length} pendências, ` +
      `${dados.usuarios.length} usuários (senha padrão: ${SENHA_PADRAO})`,
  );
}
