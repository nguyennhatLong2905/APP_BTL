import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
const files = {
  "/": ["../frontend/example.html", "text/html; charset=utf-8"],
  "/vi-an-client.js": [
    "../frontend/vi-an-client.js",
    "text/javascript; charset=utf-8",
  ],
};
createServer(async (req, res) => {
  const file = files[new URL(req.url, "http://localhost").pathname];
  if (!file) {
    res.writeHead(404).end();
    return;
  }
  try {
    res.writeHead(200, { "Content-Type": file[1] });
    res.end(await readFile(new URL(file[0], import.meta.url)));
  } catch {
    res.writeHead(500).end();
  }
}).listen(5173, "127.0.0.1", () =>
  console.log("Frontend example: http://127.0.0.1:5173"),
);
