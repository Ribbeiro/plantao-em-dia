// Persistência simples em arquivo JSON (sem banco de dados para instalar).
// O conteúdo fica em memória e é gravado no disco a cada alteração.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const COLECOES = [
  'usuarios',
  'setores',
  'pacientes',
  'medicacoes',
  'sinaisVitais',
  'intercorrencias',
  'pendencias',
  'plantoes',
];

let arquivo = null;
let dados = null;

function vazio() {
  const base = { geradoEm: null };
  for (const c of COLECOES) base[c] = [];
  return base;
}

function abrir(caminho) {
  arquivo = caminho;
  if (fs.existsSync(caminho)) {
    dados = { ...vazio(), ...JSON.parse(fs.readFileSync(caminho, 'utf8')) };
  } else {
    dados = null;
  }
  return dados;
}

function existe() {
  return dados !== null;
}

function substituir(novos) {
  dados = { ...vazio(), ...novos };
  salvar();
}

function salvar() {
  if (!arquivo) throw new Error('Banco não foi aberto');
  fs.mkdirSync(path.dirname(arquivo), { recursive: true });
  const tmp = `${arquivo}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(dados, null, 2));
  fs.renameSync(tmp, arquivo);
}

function colecao(nome) {
  if (!dados) throw new Error('Banco vazio: rode "npm run seed"');
  return dados[nome];
}

function inserir(nome, item) {
  const registro = { id: novoId(nome), ...item };
  colecao(nome).push(registro);
  salvar();
  return registro;
}

function novoId(nome) {
  const prefixos = {
    medicacoes: 'med',
    sinaisVitais: 'sv',
    intercorrencias: 'int',
    pendencias: 'pend',
    plantoes: 'plt',
  };
  return `${prefixos[nome] || nome.slice(0, 3)}_${crypto.randomBytes(5).toString('hex')}`;
}

module.exports = { abrir, existe, substituir, salvar, colecao, inserir, COLECOES };
