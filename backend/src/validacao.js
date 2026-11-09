// Validação de entrada simples, sem dependências externas.

class ErroHttp extends Error {
  constructor(status, mensagem, detalhes) {
    super(mensagem);
    this.status = status;
    this.detalhes = detalhes;
  }
}

/**
 * Valida um objeto contra um esquema.
 * Regras por campo: { tipo: 'string'|'numero'|'inteiro'|'data', obrigatorio, min, max, opcoes, maxLen }
 * Lança ErroHttp 400 com a lista de problemas encontrados.
 */
function validar(corpo, esquema) {
  const dados = corpo && typeof corpo === 'object' ? corpo : {};
  const erros = [];
  const saida = {};

  for (const [campo, regra] of Object.entries(esquema)) {
    let valor = dados[campo];
    const rotulo = regra.rotulo || campo;
    if (valor === undefined || valor === null || valor === '') {
      if (regra.obrigatorio) erros.push(`${rotulo} é obrigatório`);
      continue;
    }
    switch (regra.tipo) {
      case 'string':
        if (typeof valor !== 'string') {
          erros.push(`${rotulo} deve ser texto`);
          continue;
        }
        valor = valor.trim();
        if (regra.obrigatorio && !valor) erros.push(`${rotulo} é obrigatório`);
        if (regra.maxLen && valor.length > regra.maxLen) erros.push(`${rotulo} deve ter no máximo ${regra.maxLen} caracteres`);
        if (regra.opcoes && !regra.opcoes.includes(valor)) erros.push(`${rotulo} deve ser um de: ${regra.opcoes.join(', ')}`);
        break;
      case 'numero':
      case 'inteiro': {
        const n = typeof valor === 'string' ? Number(valor.replace(',', '.')) : valor;
        if (typeof n !== 'number' || Number.isNaN(n)) {
          erros.push(`${rotulo} deve ser um número`);
          continue;
        }
        if (regra.tipo === 'inteiro' && !Number.isInteger(n)) erros.push(`${rotulo} deve ser inteiro`);
        if (regra.min !== undefined && n < regra.min) erros.push(`${rotulo} deve ser no mínimo ${regra.min}`);
        if (regra.max !== undefined && n > regra.max) erros.push(`${rotulo} deve ser no máximo ${regra.max}`);
        valor = n;
        break;
      }
      case 'data': {
        const d = new Date(valor);
        if (typeof valor !== 'string' || Number.isNaN(d.getTime())) {
          erros.push(`${rotulo} deve ser uma data ISO 8601`);
          continue;
        }
        valor = d.toISOString();
        break;
      }
      default:
        break;
    }
    saida[campo] = valor;
  }

  if (erros.length) throw new ErroHttp(400, 'Dados inválidos', erros);
  return saida;
}

module.exports = { validar, ErroHttp };
