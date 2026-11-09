const config = require('./config');
const db = require('./db');
const { criarApp } = require('./app');
const { gerarDados } = require('./seed');

db.abrir(config.dbFile);
if (!db.existe()) {
  console.log('Banco não encontrado: gerando dados fictícios (equivale a "npm run seed")...');
  db.substituir(gerarDados());
}

criarApp().listen(config.port, '0.0.0.0', () => {
  console.log(`API Plantão em Dia rodando em http://localhost:${config.port}`);
  console.log('No emulador Android use http://10.0.2.2:' + config.port);
});
