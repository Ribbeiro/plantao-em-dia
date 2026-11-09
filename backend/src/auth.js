const jwt = require('jsonwebtoken');
const config = require('./config');
const { ErroHttp } = require('./validacao');

function gerarToken(usuario) {
  return jwt.sign(
    { sub: usuario.id, nome: usuario.nome, cargo: usuario.cargo, setorId: usuario.setorId },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn },
  );
}

/** Middleware: exige "Authorization: Bearer <token>" e coloca o usuário em req.usuario. */
function exigirLogin(req, _res, next) {
  const cabecalho = req.headers.authorization || '';
  const [tipo, token] = cabecalho.split(' ');
  if (tipo !== 'Bearer' || !token) return next(new ErroHttp(401, 'Token ausente. Faça login novamente.'));
  try {
    const p = jwt.verify(token, config.jwtSecret);
    req.usuario = { id: p.sub, nome: p.nome, cargo: p.cargo, setorId: p.setorId };
    return next();
  } catch {
    return next(new ErroHttp(401, 'Sessão expirada ou token inválido. Faça login novamente.'));
  }
}

module.exports = { gerarToken, exigirLogin };
