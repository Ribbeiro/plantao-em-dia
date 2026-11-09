// Testes unitários da geração do SBAR.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { gerarSbarPaciente } = require('../src/sbar');

const agora = new Date('2026-11-08T19:00:00');
const inicio = new Date('2026-11-08T07:00:00');
const h = (hora) => new Date(`2026-11-08T${hora}:00`).toISOString();

const paciente = {
  id: 'p1',
  leito: 'CM-01',
  nome: 'Paciente Teste',
  idade: 70,
  diagnostico: 'Pneumonia',
  alergias: ['Dipirona'],
  risco: 'alto',
  historico: 'Hipertenso.',
  dispositivos: ['AVP MSE'],
  dieta: 'Branda',
  dataInternacao: '2026-11-05T10:00:00',
};

test('SBAR completo com alertas, atrasos e pendências', () => {
  const r = gerarSbarPaciente({
    paciente,
    inicio,
    fim: agora,
    sinaisVitais: [
      { registradoEm: h('09:00'), pas: 120, pad: 80, fc: 80, fr: 18, temperatura: 36.5, satO2: 97, dor: 1 },
      { registradoEm: h('17:30'), pas: 120, pad: 80, fc: 80, fr: 18, temperatura: 38.2, satO2: 90, dor: 2 },
      { registradoEm: h('05:00'), pas: 200, pad: 100, fc: 80, fr: 18, temperatura: 36, satO2: 99, dor: 0 }, // fora do turno
    ],
    intercorrencias: [{ horario: h('15:00'), gravidade: 'grave', descricao: 'Dessaturação' }],
    medicacoes: [
      { nome: 'Ceftriaxona', dose: '1 g', via: 'EV', horario: h('08:00'), status: 'administrada' },
      { nome: 'Dipirona', dose: '1 g', via: 'EV', horario: h('14:00'), status: 'pendente' },
      { nome: 'Omeprazol', dose: '40 mg', via: 'EV', horario: h('22:00'), status: 'pendente' },
    ],
    pendencias: [
      { tipo: 'exame', descricao: 'Raio-X de tórax', status: 'pendente' },
      { tipo: 'exame', descricao: 'Hemograma', status: 'concluida' },
    ],
  });

  assert.match(r.situacao, /CM-01/);
  assert.match(r.situacao, /Risco ALTO/);
  assert.match(r.situacao, /ALERGIAS: Dipirona/);
  assert.match(r.situacao, /1 intercorrência\(s\) no turno \(1 grave\)/);
  assert.match(r.breveHistorico, /Internado\(a\) há 3 dia\(s\)/);
  assert.match(r.avaliacao, /17:30/, 'usa o último SV do turno');
  assert.doesNotMatch(r.avaliacao, /200\//, 'ignora SV de fora do turno');
  assert.match(r.avaliacao, /SatO2 baixa/);
  assert.match(r.avaliacao, /febre/);
  assert.match(r.avaliacao, /1 de 2 administradas/);
  assert.match(r.recomendacao, /ATRASADA: Dipirona 1 g EV das 14:00/);
  assert.match(r.recomendacao, /Próxima dose: Omeprazol 40 mg EV às 22:00/);
  assert.match(r.recomendacao, /Raio-X de tórax/);
  assert.doesNotMatch(r.recomendacao, /Hemograma/, 'pendência concluída não entra');
  assert.equal(r.medicacoesAtrasadas, 1);
  assert.equal(r.pendenciasAbertas, 1);
});

test('SBAR sem registros no turno recomenda aferir sinais vitais', () => {
  const r = gerarSbarPaciente({
    paciente: { ...paciente, alergias: [], dispositivos: [] },
    inicio,
    fim: agora,
    sinaisVitais: [],
    intercorrencias: [],
    medicacoes: [],
    pendencias: [],
  });
  assert.match(r.situacao, /Sem alergias conhecidas/);
  assert.match(r.situacao, /Sem intercorrências no turno/);
  assert.match(r.avaliacao, /Sem sinais vitais registrados/);
  assert.match(r.recomendacao, /Aferir sinais vitais/);
  assert.deepEqual(r.alertas, []);
});
