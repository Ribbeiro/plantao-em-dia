// Regras de negócio compartilhadas entre as rotas e a geração do SBAR.
const config = require('./config');

const HORA = 60 * 60 * 1000;

/** Uma medicação está atrasada se não foi administrada e passou do horário + tolerância. */
function medicacaoAtrasada(med, agora = new Date(), toleranciaMin = config.toleranciaAtrasoMin) {
  if (med.status !== 'pendente') return false;
  return new Date(med.horario).getTime() + toleranciaMin * 60 * 1000 < agora.getTime();
}

/** Acrescenta o campo calculado "atrasada" sem alterar o registro salvo. */
function comStatus(med, agora = new Date()) {
  return { ...med, atrasada: medicacaoAtrasada(med, agora) };
}

/** Janela das "prescrições do dia": 12 h para trás e 12 h para frente. */
function noDia(med, agora = new Date()) {
  const t = new Date(med.horario).getTime();
  return t >= agora.getTime() - 12 * HORA && t <= agora.getTime() + 12 * HORA;
}

/** Alertas clínicos simples a partir de um registro de sinais vitais. */
function alertasSinais(sv) {
  if (!sv) return [];
  const a = [];
  if (sv.satO2 != null && sv.satO2 < 92) a.push(`SatO2 baixa (${sv.satO2}%)`);
  if (sv.fc != null && sv.fc > 120) a.push(`taquicardia (FC ${sv.fc})`);
  if (sv.fc != null && sv.fc < 50) a.push(`bradicardia (FC ${sv.fc})`);
  if (sv.pas != null && sv.pas >= 160) a.push(`PA elevada (${sv.pas}/${sv.pad})`);
  if (sv.pas != null && sv.pas < 90) a.push(`hipotensão (${sv.pas}/${sv.pad})`);
  if (sv.temperatura != null && sv.temperatura >= 37.8) a.push(`febre (${sv.temperatura} °C)`);
  if (sv.fr != null && sv.fr > 24) a.push(`taquipneia (FR ${sv.fr})`);
  if (sv.dor != null && sv.dor >= 7) a.push(`dor intensa (${sv.dor}/10)`);
  return a;
}

module.exports = { medicacaoAtrasada, comStatus, noDia, alertasSinais, HORA };
