const pool = require("../db/mysql");

module.exports = async function admin(req, res, next) {
    const [[usuario]] = await pool.query(
        "SELECT id_grupo FROM usuarios WHERE id_usuario = ?",
        [req.user.idUsuario]
    );

    if (!usuario || usuario.id_grupo !== "ADM") {
        return res.status(403).json({ erro: "Acesso negado (somente admin)" });
    }

    next();
};
