const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env'), quiet: true });

const raiz = path.join(__dirname, '..');

module.exports = {
  port: Number(process.env.PORT) || 3000,
  jwtSecret: process.env.JWT_SECRET || 'plantao-em-dia-segredo-de-desenvolvimento',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '12h',
  dbFile: path.resolve(raiz, process.env.DB_FILE || 'data/db.json'),
  toleranciaAtrasoMin: Number(process.env.TOLERANCIA_ATRASO_MIN) || 30,
};
