const { validarToken } = require("../utils/token");

module.exports = function auth(req, res, next) {
    const token = req.headers["authorization"];

    if (!token) return res.status(401).json({ erro: "Token ausente" });

    const dados = validarToken(token);

    if (!dados) return res.status(401).json({ erro: "Token inválido" });

    req.user = dados;
    next();
};
