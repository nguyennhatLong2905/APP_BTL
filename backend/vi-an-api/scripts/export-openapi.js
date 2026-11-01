import { writeFile } from "node:fs/promises";
import { buildApp } from "../src/app.js";
const app = await buildApp({ transactionCapable: true });
const spec = app.swagger();
await writeFile("openapi.json", JSON.stringify(spec, null, 2));
const groups = new Map();
let count = 0;
for (const [path, methods] of Object.entries(spec.paths))
  for (const [method, op] of Object.entries(methods)) {
    if (!path.startsWith("/api/v1")) continue;
    count++;
    const tag = op.tags?.[0] || "General";
    if (!groups.has(tag)) groups.set(tag, []);
    const key = op.parameters?.some(
      (p) => p.in === "header" && p.name.toLowerCase() === "idempotency-key",
    );
    groups
      .get(tag)
      .push(
        `| ${method.toUpperCase()} | \`${path}\` | ${op.summary || ""} | ${key ? "Có" : "Không"} |`,
      );
  }
let text = `# Danh mục API Ví An\n\n${count} operations. Header Authorization cần cho mọi API trừ /auth/register, /auth/login, /auth/demo. Cột Key là Idempotency-Key. Body, query, các model response chính và ví dụ nằm trong openapi.json hoặc Swagger /docs.\n`;
for (const [tag, rows] of groups)
  text += `\n## ${tag}\n\n| Method | Endpoint | Chức năng | Key |\n|---|---|---|---|\n${rows.join("\n")}\n`;
await writeFile("API_REFERENCE.md", text);
await app.close();
console.log(`Saved openapi.json and API_REFERENCE.md (${count} operations)`);
