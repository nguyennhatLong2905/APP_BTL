import { existsSync, writeFileSync } from "node:fs";
import { randomBytes } from "node:crypto";
if (existsSync(".env")) {
  console.log(".env exists; no changes.");
  process.exit(0);
}
writeFileSync(
  ".env",
  `HOST=127.0.0.1\nPORT=3000\nMONGODB_URI=mongodb://127.0.0.1:27017/?replicaSet=rs0\nMONGODB_DB=vi_an\nJWT_SECRET=${randomBytes(48).toString("hex")}\nCORS_ORIGINS=http://localhost:5173,http://localhost:3001,http://127.0.0.1:5173\nALLOW_DEMO_LOGIN=true\nJOBS_ENABLED=true\nNODE_ENV=development\n`,
  { mode: 0o600 },
);
console.log("Created .env with a random signing secret.");
