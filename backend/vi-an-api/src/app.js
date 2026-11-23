import Fastify from "fastify";
import { documentResponses } from "./openapi-contract.js";
import cors from "@fastify/cors";
import jwt from "@fastify/jwt";
import rateLimit from "@fastify/rate-limit";
import compress from "@fastify/compress";
import swagger from "@fastify/swagger";
import swaggerUI from "@fastify/swagger-ui";
import { z } from "zod";
import { ApiError, atomic, oid, json, fail } from "./common.js";
import { authRoutes } from "./routes-auth.js";
import { financeRoutes } from "./routes-finance.js";
import { billRoutes } from "./routes-bills.js";
import { experienceRoutes } from "./routes-experience.js";
import { signalRoutes } from "./signals.js";
import { dataRoutes } from "./routes-data.js";

export async function buildApp(ctx, config = {}) {
  const app = Fastify({
    logger: config.logger ?? false,
    bodyLimit: 6 * 1024 * 1024,
    ajv: { customOptions: { removeAdditional: false, coerceTypes: false } },
    // Tối ưu cho production
    trustProxy: true,
    disableRequestLogging: true,
  });
  
  // Compression - giảm 70-80% kích thước response
  await app.register(compress, {
    global: true,
    threshold: 1024, // Chỉ compress response > 1KB
    encodings: ['br', 'gzip', 'deflate'], // br (brotli) nhỏ hơn gzip ~15-20%
  });
  

  const allowedOrigins = [
    "https://vi-an-web.vercel.app",
    "http://localhost:3000",
    "http://localhost:5000",
    ...(config.origins || []),
  ];
  await app.register(cors, {
    origin: (origin, cb) => {
      if (
        !origin ||
        allowedOrigins.includes(origin) ||
        allowedOrigins.includes("*") ||
        /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
      ) {
        cb(null, true);
        return;
      }
      cb(new Error("CORS not allowed"), false);
    },
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Idempotency-Key",
      "Accept",
      "retry_attempt",
    ],
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  });

  await app.register(jwt, {
    secret: config.jwtSecret || "documentation-only-not-for-running-server",
  });
  await app.register(rateLimit, { max: 200, timeWindow: "1 minute" });
  await app.register(swagger, {
    transformObject: documentResponses,
    openapi: {
      info: {
        title: "Ví An API",
        version: "1.0.0",
        description:
          "REST API; tiền VND là chuỗi số. Các lệnh ghi yêu cầu Idempotency-Key.",
      },
      components: {
        securitySchemes: {
          bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
        },
      },
    },
  });
  await app.register(swaggerUI, { routePrefix: "/docs" });
  app.setErrorHandler((e, req, reply) => {
    if (e instanceof z.ZodError)
      return reply
        .code(422)
        .send({
          error: {
            code: "VALIDATION_ERROR",
            message: "Dữ liệu không hợp lệ.",
            details: e.issues,
          },
        });
    const status =
      e.code === 11000 ? 409 : e.code === 121 ? 422 : e.statusCode || 500;
    const code =
      e.code === 11000
        ? "DUPLICATE"
        : e.code === 121
          ? "DATABASE_VALIDATION"
          : typeof e.code === "string"
            ? e.code
            : "INTERNAL_ERROR";
    if (status >= 500) app.log.error({ err: e, requestId: req.id });
    reply
      .code(status)
      .send({
        error: {
          code,
          message:
            status >= 500 && !(e instanceof ApiError)
              ? "Lỗi hệ thống."
              : e.message,
          ...(e.details ? { details: e.details } : {}),
        },
        requestId: req.id,
      });
  });
  // --- Cache tokenVersion (TTL 30s) ---
  // Tránh query DB "users" mỗi request được xác thực.
  // Logout-all tăng tokenVersion trong DB; cache cũ hết hạn sau ≤30s.
  const _tvCache = new Map(); // userId_hex → { ver: number, exp: number }
  const _TV_TTL = 30_000;
  // Dọn cache hết hạn định kỳ (5 phút) để tránh memory leak
  setInterval(() => {
    const t = Date.now();
    for (const [k, v] of _tvCache) if (t > v.exp) _tvCache.delete(k);
  }, 300_000).unref();

  const convert = (s, isQuery = false) => {
    const j = z.toJSONSchema(s, { target: "draft-7", io: "input" });
    delete j.$schema;
    if (isQuery)
      for (const [k, v] of Object.entries(j.properties || {}))
        if (["integer", "number"].includes(v.type))
          j.properties[k] = { type: "string", pattern: "^[0-9]+$" };
    return j;
  };
  function route(
    method,
    url,
    {
      body,
      query,
      write = false,
      publicRoute = false,
      summary = "",
      tag = "General",
      raw = false,
    } = {},
    handler,
  ) {
    app.route({
      method,
      url: "/api/v1" + url,
      schema: {
        summary,
        operationId: method.toLowerCase() + url.replace(/[^a-zA-Z0-9]/g, "_"),
        ...(!raw
          ? {
              response: {
                200: {
                  type: "object",
                  required: ["data"],
                  properties: { data: {} },
                  additionalProperties: false,
                },
                "4xx": { type: "object", additionalProperties: true },
                "5xx": { type: "object", additionalProperties: true },
              },
            }
          : {}),
        tags: [tag],
        security: publicRoute ? [] : [{ bearerAuth: [] }],
        ...(body ? { body: convert(body) } : {}),
        ...(query ? { querystring: convert(query, true) } : {}),
        ...(url.includes(":id")
          ? {
              params: {
                type: "object",
                required: ["id"],
                properties: {
                  id: { type: "string", pattern: "^[a-fA-F0-9]{24}$" },
                },
                additionalProperties: false,
              },
            }
          : {}),
        ...(write
          ? {
              headers: {
                type: "object",
                required: ["idempotency-key"],
                properties: {
                  "idempotency-key": {
                    type: "string",
                    minLength: 8,
                    maxLength: 128,
                  },
                },
              },
            }
          : {}),
      },
      preHandler: async (req) => {
        if (!publicRoute) {
          await req.jwtVerify();
          fail(
            /^[a-f\d]{24}$/i.test(req.user.sub),
            "UNAUTHORIZED",
            "Token không hợp lệ.",
            401,
          );
          req.owner = oid(req.user.sub);
          const sub = req.user.sub;
          const jwtVer = Number(req.user.ver || 0);
          const cached = _tvCache.get(sub);
          if (cached && Date.now() < cached.exp) {
            // Cache còn hạn — không cần query DB
            fail(cached.ver === jwtVer, "UNAUTHORIZED", "Phiên đăng nhập đã hết hạn.", 401);
          } else {
            // Cache hết hạn hoặc chưa có — query DB và cập nhật cache
            const u = await ctx.db
              .collection("users")
              .findOne({ _id: req.owner }, { projection: { tokenVersion: 1 } });
            fail(
              u && Number(u.tokenVersion || 0) === jwtVer,
              "UNAUTHORIZED",
              "Phiên đăng nhập đã hết hạn.",
              401,
            );
            if (u) _tvCache.set(sub, { ver: Number(u.tokenVersion || 0), exp: Date.now() + _TV_TTL });
          }
        }
      },
      handler: async (req, reply) => {
        req.input = body ? body.parse(req.body) : {};
        req.filters = query ? query.parse(req.query) : {};
        const invoke = (session) => handler(req, reply, session);
        const value = write
          ? await atomic(
              ctx,
              req.owner,
              req.headers["idempotency-key"],
              method + ":" + req.url.split("?")[0],
              req.input,
              invoke,
            )
          : await invoke();
        if (raw) return value;
        // Cache-Control cho GET: private (có auth), 10s max-age, stale 30s
        if (method === "GET" && !write)
          reply.header("Cache-Control", "private, max-age=10, stale-while-revalidate=30");
        return { data: json(value) };
      },
    });
  }
  app.get("/health", async () => ({
    status: "ok",
    transactionCapable: ctx.transactionCapable,
  }));
  app.get("/openapi.json", async () => app.swagger());
  authRoutes(app, ctx, config, route);
  financeRoutes(app, ctx, route);
  billRoutes(app, ctx, route);
  experienceRoutes(app, ctx, route);
  dataRoutes(app, ctx, route);
  signalRoutes(ctx, route);
  await app.ready();
  return app;
}
