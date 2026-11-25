import { MongoClient } from "mongodb";
import { buildApp } from "../src/app.js";
import { initialize } from "../src/migrate.js";

let appPromise;

async function getApp() {
  if (!appPromise) {
    appPromise = (async () => {
      const secret = process.env.JWT_SECRET;

      if (!secret || secret.length < 32) {
        throw new Error("JWT_SECRET must contain at least 32 characters");
      }

      const client = new MongoClient(process.env.MONGODB_URI, {
        promoteLongs: false,
        serverSelectionTimeoutMS: 5000,
        connectTimeoutMS: 5000,
        socketTimeoutMS: 30_000,
        // Connection pool — tránh tạo kết nối mới mỗi request
        maxPoolSize: 20,
        minPoolSize: 2,
        maxIdleTimeMS: 60_000,
        // Nén dữ liệu ở tầng driver
        compressors: ["zlib"],
      });

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
        allowDemo: false,
        origins: (process.env.CORS_ORIGINS || "").split(","),
        logger: {
          redact: [
            "req.headers.authorization",
            "req.body.password",
            "req.body.currentPassword",
            "req.body.newPassword",
            "req.body.otp",
            "req.body.resetToken",
          ],
        },
      });

      ctx.log = app.log;
      return app;
    })();
  }

  return appPromise;
}

export default async function handler(req, res) {
  try {
    const app = await getApp();
    app.server.emit("request", req, res);
  } catch (error) {
    console.error("Backend startup error:", error);
    if (!res.headersSent) {
      res.statusCode = 500;
      res.end("Internal Server Error");
    }
  }
}
