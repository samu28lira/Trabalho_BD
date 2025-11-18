const express = require("express");
const cors = require("./cors");

const app = express();
app.use(cors);
app.use(express.json());

app.use("/auth", require("./routes/auth"));
app.use("/tarefas", require("./routes/tarefas"));
app.use("/usuarios", require("./routes/usuarios"));

app.listen(3000, () => console.log("Servidor rodando na porta 3000"));
module.exports = app;