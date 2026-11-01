import { MongoClient } from "mongodb";
import { buildApp } from "./app.js";
import { initialize } from "./migrate.js";
import { runJobs } from "./jobs.js";
const secret = process.env.JWT_SECRET,
  host = process.env.HOST || "127.0.0.1";
if (!secret || secret.length < 32)
  throw new Error(
    "Run npm run setup:env or set JWT_SECRET with at least 32 characters.",
  );
const allowDemo =
  process.env.ALLOW_DEMO_LOGIN === "true" &&
  process.env.NODE_ENV !== "production";
if (allowDemo && !["127.0.0.1", "localhost", "::1"].includes(host))
  throw new Error(
    "Disable demo login before binding to a public network interface.",
  );
const client = new MongoClient(
  process.env.MONGODB_URI || "mongodb://127.0.0.1:27017",
  { promoteLongs: false, serverSelectionTimeoutMS: 5000 },
);
await client.connect();
const db = client.db(process.env.MONGODB_DB || "vi_an");
await initialize(db);
const hello = await db.admin().command({ hello: 1 });
const ctx = {
  db,
  client,
  transactionCapable: !!(hello.setName || hello.msg === "isdbgrid"),
  backupSecret: secret,
};
const app = await buildApp(ctx, {
  jwtSecret: secret,
  allowDemo,
  origins: (process.env.CORS_ORIGINS || "http://localhost:5173").split(","),
  logger: { redact: ["req.headers.authorization", "req.body.password"] },
});
ctx.log = app.log;
await app.listen({ host, port: Number(process.env.PORT || 3000) });
let timer,
  running = false;
async function tick() {
  if (running) return;
  running = true;
  try {
    await runJobs(ctx);
  } catch (e) {
    app.log.error(e);
  } finally {
    running = false;
  }
}
if (process.env.JOBS_ENABLED !== "false") {
  await tick();
  timer = setInterval(tick, 60000);
  timer.unref();
}
async function stop() {
  clearInterval(timer);
  await app.close();
  await client.close();
  process.exit(0);
}
process.on("SIGINT", stop);
process.on("SIGTERM", stop);
