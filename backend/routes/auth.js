const express = require("express");
const bcrypt = require("bcryptjs");
const pool = require("../db/mysql");
const { gerarToken } = require("../utils/token");
const router = express.Router();

router.post("/login", async (req, res) => {
    const { email, senha } = req.body;

    const [[user]] = await pool.query(
        "SELECT * FROM usuarios WHERE email = ?",
        [email]
    );

    if (!user) return res.status(400).json({ erro: "Usuário não encontrado" });

    const ok = await bcrypt.compare(senha, user.senha_hash);

    if (!ok) return res.status(400).json({ erro: "Senha inválida" });

    const token = gerarToken(user.id_usuario);

    res.json({ token, id_usuario: user.id_usuario, grupo: user.id_grupo });
});

module.exports = router;
