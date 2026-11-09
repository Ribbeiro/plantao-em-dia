// Geração do resumo SBAR (Situação, Breve histórico, Avaliação, Recomendação)
// de cada paciente a partir dos registros feitos durante o turno.
const { medicacaoAtrasada, alertasSinais, HORA } = require('./regras');

const hhmm = (iso) => {
  const d = new Date(iso);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

const dentro = (iso, inicio, fim) => {
  const t = new Date(iso).getTime();
  return t >= inicio.getTime() && t <= fim.getTime();
};

const RISCO = { baixo: 'BAIXO', medio: 'MÉDIO', alto: 'ALTO' };

/**
 * Monta o SBAR de um paciente.
 * @param {object} p
 * @param {object} p.paciente
 * @param {object[]} p.sinaisVitais     todos os registros do paciente
 * @param {object[]} p.intercorrencias  todas as intercorrências do paciente
 * @param {object[]} p.medicacoes       todas as doses do paciente
 * @param {object[]} p.pendencias       todas as pendências do paciente
 * @param {Date} p.inicio               início do turno
 * @param {Date} p.fim                  fim do turno (momento do encerramento)
 */
function gerarSbarPaciente({ paciente, sinaisVitais, intercorrencias, medicacoes, pendencias, inicio, fim }) {
  const svTurno = sinaisVitais
    .filter((s) => dentro(s.registradoEm, inicio, fim))
    .sort((a, b) => new Date(a.registradoEm) - new Date(b.registradoEm));
  const intTurno = intercorrencias
    .filter((i) => dentro(i.horario, inicio, fim))
    .sort((a, b) => new Date(a.horario) - new Date(b.horario));
  const medsTurno = medicacoes.filter((m) => dentro(m.horario, inicio, fim));
  const administradas = medsTurno.filter((m) => m.status === 'administrada');
  const atrasadas = medicacoes
    .filter((m) => medicacaoAtrasada(m, fim))
    .sort((a, b) => new Date(a.horario) - new Date(b.horario));
  const proximas = medicacoes
    .filter((m) => m.status === 'pendente' && !medicacaoAtrasada(m, fim))
    .filter((m) => new Date(m.horario) <= new Date(fim.getTime() + 6 * HORA))
    .sort((a, b) => new Date(a.horario) - new Date(b.horario));
  const pendAbertas = pendencias.filter((p) => p.status === 'pendente');

  // S — Situação
  const graves = intTurno.filter((i) => i.gravidade === 'grave').length;
  const situacao = [
    `Leito ${paciente.leito} – ${paciente.nome}, ${paciente.idade} anos, internado(a) por ${paciente.diagnostico}.`,
    `Risco ${RISCO[paciente.risco] || paciente.risco}.`,
    paciente.alergias.length ? `ALERGIAS: ${paciente.alergias.join(', ')}.` : 'Sem alergias conhecidas.',
    intTurno.length
      ? `${intTurno.length} intercorrência(s) no turno${graves ? ` (${graves} grave)` : ''}.`
      : 'Sem intercorrências no turno.',
  ].join(' ');

  // B — Breve histórico
  const dias = Math.max(0, Math.floor((fim - new Date(paciente.dataInternacao)) / (24 * HORA)));
  const breveHistorico = [
    paciente.historico,
    `Internado(a) há ${dias} dia(s).`,
    paciente.dispositivos?.length ? `Dispositivos: ${paciente.dispositivos.join(', ')}.` : null,
    paciente.dieta ? `Dieta: ${paciente.dieta}.` : null,
  ]
    .filter(Boolean)
    .join(' ');

  // A — Avaliação
  const ultimo = svTurno[svTurno.length - 1];
  const alertas = alertasSinais(ultimo);
  const avaliacaoPartes = [];
  if (ultimo) {
    avaliacaoPartes.push(
      `Últimos SV (${hhmm(ultimo.registradoEm)}): PA ${ultimo.pas}/${ultimo.pad} mmHg, FC ${ultimo.fc} bpm, ` +
        `FR ${ultimo.fr} irpm, T ${ultimo.temperatura} °C, SatO2 ${ultimo.satO2}%, dor ${ultimo.dor}/10.`,
    );
    avaliacaoPartes.push(alertas.length ? `Alertas: ${alertas.join(', ')}.` : 'Sinais vitais dentro das faixas esperadas.');
    if (ultimo.observacao) avaliacaoPartes.push(`Obs.: ${ultimo.observacao}`);
  } else {
    avaliacaoPartes.push('Sem sinais vitais registrados no turno.');
  }
  for (const i of intTurno) {
    avaliacaoPartes.push(`${hhmm(i.horario)} – intercorrência ${i.gravidade}: ${i.descricao}`);
  }
  avaliacaoPartes.push(`Medicações do turno: ${administradas.length} de ${medsTurno.length} administradas.`);
  const avaliacao = avaliacaoPartes.join(' ');

  // R — Recomendação
  const rec = [];
  for (const m of atrasadas) rec.push(`ATRASADA: ${m.nome} ${m.dose} ${m.via} das ${hhmm(m.horario)}.`);
  for (const m of proximas) rec.push(`Próxima dose: ${m.nome} ${m.dose} ${m.via} às ${hhmm(m.horario)}.`);
  for (const p of pendAbertas) rec.push(`Pendente (${p.tipo}): ${p.descricao}.`);
  if (alertas.length) rec.push('Reavaliar sinais vitais no início do turno.');
  if (!ultimo) rec.push('Aferir sinais vitais no início do turno.');
  if (graves) rec.push('Acompanhar evolução após intercorrência grave.');
  if (!rec.length) rec.push('Manter cuidados e prescrição vigentes.');

  return {
    pacienteId: paciente.id,
    nome: paciente.nome,
    leito: paciente.leito,
    risco: paciente.risco,
    alergias: paciente.alergias,
    situacao,
    breveHistorico,
    avaliacao,
    recomendacao: rec.join(' '),
    alertas,
    medicacoesAtrasadas: atrasadas.length,
    pendenciasAbertas: pendAbertas.length,
  };
}

/** Gera o SBAR de todos os pacientes de um setor. */
function gerarSbarSetor({ pacientes, sinaisVitais, intercorrencias, medicacoes, pendencias, inicio, fim }) {
  return pacientes
    .slice()
    .sort((a, b) => a.leito.localeCompare(b.leito, 'pt-BR', { numeric: true }))
    .map((paciente) =>
      gerarSbarPaciente({
        paciente,
        sinaisVitais: sinaisVitais.filter((s) => s.pacienteId === paciente.id),
        intercorrencias: intercorrencias.filter((i) => i.pacienteId === paciente.id),
        medicacoes: medicacoes.filter((m) => m.pacienteId === paciente.id),
        pendencias: pendencias.filter((p) => p.pacienteId === paciente.id),
        inicio,
        fim,
      }),
    );
}

module.exports = { gerarSbarPaciente, gerarSbarSetor };
