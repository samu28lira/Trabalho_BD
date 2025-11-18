const bcrypt = require("bcryptjs");

async function gerarHash() {
    const senha = "1234"; 
    const saltRounds = 10;

    const hash = await bcrypt.hash(senha, saltRounds);
    console.log("Hash gerado:", hash);
}

gerarHash();
