import { MongoClient } from "mongodb";
import { initialize } from "../src/migrate.js";
const client = new MongoClient(
  process.env.MONGODB_URI || "mongodb://127.0.0.1:27017",
  { promoteLongs: false },
);
try {
  await client.connect();
  await initialize(client.db(process.env.MONGODB_DB || "vi_an"), {
    seed: process.argv.includes("--seed"),
  });
  console.log("Database initialized. Existing records are preserved.");
} finally {
  await client.close();
}
