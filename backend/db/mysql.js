const mysql = require("mysql2/promise");

const pool = mysql.createPool({
    host: "localhost",
    user: "app_user",
    password: "senha_app",
    database: "app"
});

module.exports = pool;
