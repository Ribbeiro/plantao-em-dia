// Testes de integração dos endpoints (node:test + fetch nativo, sem dependências extras).
process.env.NODE_ENV = 'test';
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

const db = require('../src/db');
const { criarApp } = require('../src/app');
const { gerarDados, SENHA_PADRAO } = require('../src/seed');

let servidor;
let base;
const arquivo = path.join(os.tmpdir(), `plantao-teste-${process.pid}.json`);

async function chamar(metodo, rota, { token, corpo } = {}) {
  const resp = await fetch(base + rota, {
    method: metodo,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: corpo ? JSON.stringify(corpo) : undefined,
  });
  return { status: resp.status, corpo: await resp.json() };
}

const login = async (usuario) =>
  (await chamar('POST', '/auth/login', { corpo: { usuario, senha: SENHA_PADRAO } })).corpo.token;

before(async () => {
  db.abrir(arquivo);
  db.substituir(gerarDados());
  servidor = criarApp().listen(0);
  await new Promise((r) => servidor.once('listening', r));
  base = `http://127.0.0.1:${servidor.address().port}`;
});

after(() => {
  servidor.close();
  fs.rmSync(arquivo, { force: true });
});

test('POST /auth/login devolve JWT com nome, cargo e setor', async () => {
  const ok = await chamar('POST', '/auth/login', { corpo: { usuario: 'ana.enfermeira', senha: SENHA_PADRAO } });
  assert.equal(ok.status, 200);
  assert.ok(ok.corpo.token);
  assert.equal(ok.corpo.usuario.cargo, 'Enfermeira');
  assert.equal(ok.corpo.usuario.setor.id, 'cm');
  assert.equal(ok.corpo.usuario.senhaHash, undefined, 'não pode vazar o hash da senha');
  const payload = JSON.parse(Buffer.from(ok.corpo.token.split('.')[1], 'base64url').toString());
  assert.equal(payload.nome, 'Ana Ribeiro');
  assert.equal(payload.setorId, 'cm');

  const errada = await chamar('POST', '/auth/login', { corpo: { usuario: 'ana.enfermeira', senha: 'x' } });
  assert.equal(errada.status, 401);
  assert.ok(errada.corpo.erro);

  const vazia = await chamar('POST', '/auth/login', { corpo: {} });
  assert.equal(vazia.status, 400);
  assert.equal(vazia.corpo.detalhes.length, 2);
});

test('rotas protegidas exigem token', async () => {
  const r = await chamar('GET', '/setores');
  assert.equal(r.status, 401);
});

test('GET /setores/:id/pacientes lista leitos com risco, alergias e pendências', async () => {
  const token = await login('ana.enfermeira');
  const r = await chamar('GET', '/setores/cm/pacientes', { token });
  assert.equal(r.status, 200);
  assert.equal(r.corpo.length, 11);
  const p = r.corpo[0];
  assert.equal(p.leito, 'CM-01');
  assert.ok(['baixo', 'medio', 'alto'].includes(p.risco));
  assert.ok(Array.isArray(p.alergias));
  assert.equal(typeof p.pendencias, 'number');

  const inexistente = await chamar('GET', '/setores/xyz/pacientes', { token });
  assert.equal(inexistente.status, 404);
});

test('POST sinais vitais valida faixas e devolve alertas', async () => {
  const token = await login('ana.enfermeira');
  const invalido = await chamar('POST', '/pacientes/cm_p1/sinais-vitais', {
    token,
    corpo: { pas: 120, pad: 80, fc: 80, fr: 18, temperatura: 36.5, satO2: 130, dor: 2 },
  });
  assert.equal(invalido.status, 400);
  assert.match(invalido.corpo.detalhes.join(' '), /SatO2/);

  const ok = await chamar('POST', '/pacientes/cm_p1/sinais-vitais', {
    token,
    corpo: { pas: 120, pad: 80, fc: 80, fr: 18, temperatura: '36,9', satO2: 89, dor: 2, observacao: 'teste' },
  });
  assert.equal(ok.status, 201);
  assert.equal(ok.corpo.temperatura, 36.9);
  assert.equal(ok.corpo.responsavel, 'Ana Ribeiro');
  assert.ok(ok.corpo.alertas.some((a) => a.includes('SatO2')));
});

test('PATCH /medicacoes/:id marca como administrada e impede duplicidade', async () => {
  const token = await login('bruno.tecnico');
  const det = await chamar('GET', '/pacientes/cm_p2', { token });
  const pendente = det.corpo.medicacoes.find((m) => m.status === 'pendente');
  assert.ok(pendente, 'seed deve gerar pelo menos uma dose pendente');
  const r = await chamar('PATCH', `/medicacoes/${pendente.id}`, { token, corpo: {} });
  assert.equal(r.status, 200);
  assert.equal(r.corpo.status, 'administrada');
  assert.equal(r.corpo.responsavel, 'Bruno Carvalho');
  assert.equal(r.corpo.atrasada, false);
  const dup = await chamar('PATCH', `/medicacoes/${pendente.id}`, { token, corpo: {} });
  assert.equal(dup.status, 409);
});

test('GET /pendencias agrupa medicações atrasadas, exames e procedimentos', async () => {
  const token = await login('ana.enfermeira');
  const r = await chamar('GET', '/pendencias?setor=cm', { token });
  assert.equal(r.status, 200);
  assert.ok(Array.isArray(r.corpo.medicacoesAtrasadas));
  assert.ok(r.corpo.medicacoesAtrasadas.every((m) => m.atrasada && m.paciente.leito.startsWith('CM')));
  assert.equal(
    r.corpo.total,
    r.corpo.medicacoesAtrasadas.length + r.corpo.exames.length + r.corpo.procedimentos.length + r.corpo.retornos.length,
  );
  assert.equal((await chamar('GET', '/pendencias', { token })).status, 400);
});

test('fluxo completo: encerrar turno gera SBAR, histórico e confirmação de leitura', async () => {
  const ana = await login('ana.enfermeira');
  await chamar('POST', '/pacientes/cm_p3/intercorrencias', {
    token: ana,
    corpo: { descricao: 'Pico febril 38,5 °C', gravidade: 'moderada' },
  });

  const criado = await chamar('POST', '/plantoes', { token: ana, corpo: { setorId: 'cm', observacoes: 'Plantão tranquilo' } });
  assert.equal(criado.status, 201);
  const plantao = criado.corpo;
  assert.equal(plantao.resumo.length, 11);
  assert.equal(plantao.responsavel.nome, 'Ana Ribeiro');
  assert.equal(plantao.confirmacao, null);

  const sbar = plantao.resumo.find((r) => r.pacienteId === 'cm_p3');
  for (const campo of ['situacao', 'breveHistorico', 'avaliacao', 'recomendacao']) {
    assert.ok(sbar[campo].length > 10, `campo ${campo} deve ser preenchido`);
  }
  assert.match(sbar.situacao, /CM-03/);
  assert.match(sbar.situacao, /Penicilina/, 'alergia aparece na situação');
  assert.match(sbar.avaliacao, /Pico febril/, 'intercorrência do turno aparece na avaliação');

  const proprio = await chamar('POST', `/plantoes/${plantao.id}/confirmar`, { token: ana });
  assert.equal(proprio.status, 422);

  const bruno = await login('bruno.tecnico');
  const conf = await chamar('POST', `/plantoes/${plantao.id}/confirmar`, { token: bruno });
  assert.equal(conf.status, 200);
  assert.equal(conf.corpo.confirmacao.nome, 'Bruno Carvalho');
  assert.ok(conf.corpo.confirmacao.confirmadoEm);

  const repetido = await chamar('POST', `/plantoes/${plantao.id}/confirmar`, { token: bruno });
  assert.equal(repetido.status, 409);

  const hist = await chamar('GET', '/plantoes?setor=cm', { token: bruno });
  assert.equal(hist.status, 200);
  assert.equal(hist.corpo[0].id, plantao.id);
  assert.equal(hist.corpo[0].resumo, undefined, 'histórico não traz o resumo completo');

  const det = await chamar('GET', `/plantoes/${plantao.id}`, { token: bruno });
  assert.equal(det.corpo.resumo.length, 11);
});
