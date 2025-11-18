const { v4: uuid } = require("uuid");

const tokens = {};

function gerarToken(idUsuario) {
    const token = uuid();
    tokens[token] = { idUsuario, criadoEm: Date.now() };
    return token;
}

function validarToken(token) {
    return tokens[token] || null;
}

module.exports = { gerarToken, validarToken };
