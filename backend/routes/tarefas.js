const express = require("express");
const pool = require("../db/mysql");
const auth = require("../middleware/auth");
const router = express.Router();

router.get("/", auth, async (req, res) => {
    const [rows] = await pool.query(
        "SELECT * FROM tarefas WHERE id_usuario_responsavel = ?",
        [req.user.idUsuario]
    );
    res.json(rows);
});

router.post("/", auth, async (req, res) => {
    const { titulo, descricao, prioridade, id_categoria } = req.body;

    let idTarefa = "";
    await pool.query("CALL gerar_tarefa_id(@id)");
    const [[idData]] = await pool.query("SELECT @id AS id");

    idTarefa = idData.id;

    await pool.query(
        `INSERT INTO tarefas(id_tarefa, titulo, descricao, prioridade, id_categoria, id_usuario_responsavel)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [idTarefa, titulo, descricao, prioridade, id_categoria, req.user.idUsuario]
    );

    res.json({ sucesso: true, id: idTarefa });
});

router.put("/:id/concluir", auth, async (req, res) => {
    const { id } = req.params;

    await pool.query(
        "UPDATE tarefas SET status = 'concluida' WHERE id_tarefa = ? AND id_usuario_responsavel = ?",
        [id, req.user.idUsuario]
    );

    res.json({ sucesso: true });
});

router.put("/:id", auth, async (req, res) => {
    const { id } = req.params;
    const { titulo, descricao } = req.body;

    await pool.query(
        "UPDATE tarefas SET titulo = ?, descricao = ? WHERE id_tarefa = ? AND id_usuario_responsavel = ?",
        [titulo, descricao, id, req.user.idUsuario]
    );

    res.json({ sucesso: true });
});

router.delete("/:id", auth, async (req, res) => {
    const { id } = req.params;

    await pool.query(
        "DELETE FROM tarefas WHERE id_tarefa = ? AND id_usuario_responsavel = ?",
        [id, req.user.idUsuario]
    );

    res.json({ sucesso: true });
});

module.exports = router;

