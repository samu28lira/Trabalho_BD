const express = require("express");
const pool = require("../db/mysql");
const auth = require("../middleware/auth");
const admin = require("../middleware/admin");
const router = express.Router();

router.get("/", auth, admin, async (req, res) => {
    const [rows] = await pool.query("SELECT id_usuario, nome, email, id_grupo FROM usuarios");
    res.json(rows);
});

module.exports = router;
