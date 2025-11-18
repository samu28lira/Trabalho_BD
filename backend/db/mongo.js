const { MongoClient } = require("mongodb");

const client = new MongoClient("mongodb://localhost:27017");

async function connectMongo() {
    await client.connect();
    return client.db("task_app_nosql");
}

module.exports = connectMongo;
