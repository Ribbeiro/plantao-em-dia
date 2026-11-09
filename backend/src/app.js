const express = require('express');
const cors = require('cors');
const rotas = require('./rotas');
const { ErroHttp } = require('./validacao');

function criarApp() {
  const app = express();
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));

  // Log enxuto das requisições (útil na apresentação).
  if (process.env.NODE_ENV !== 'test') {
    app.use((req, res, next) => {
      const t = Date.now();
      res.on('finish', () => console.log(`${req.method} ${req.originalUrl} → ${res.statusCode} (${Date.now() - t} ms)`));
      next();
    });
  }

  app.get('/', (_req, res) =>
    res.json({ api: 'Plantão em Dia', versao: '1.0.0', aviso: 'Todos os dados são fictícios.', saude: '/health' }),
  );
  app.use(rotas);

  app.use((req, _res, next) => next(new ErroHttp(404, `Rota não encontrada: ${req.method} ${req.path}`)));

  // Todos os erros saem em JSON: { erro, detalhes? }
  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({ erro: 'JSON inválido no corpo da requisição' });
    }
    const status = err.status || 500;
    if (status >= 500) console.error(err);
    const corpo = { erro: status >= 500 ? 'Erro interno no servidor' : err.message };
    if (err.detalhes) corpo.detalhes = err.detalhes;
    return res.status(status).json(corpo);
  });

  return app;
}

module.exports = { criarApp };
