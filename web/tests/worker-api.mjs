import { readFileSync, readdirSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import { build } from "esbuild";

const bundle = await build({ entryPoints: [new URL("../src/worker.ts", import.meta.url).pathname], bundle: true, write: false, format: "esm", platform: "node" });
const { default: worker } = await import(`data:text/javascript;base64,${Buffer.from(bundle.outputFiles[0].text).toString("base64")}`);

export function api() {
  const db = new DatabaseSync(":memory:");
  db.exec("PRAGMA foreign_keys = ON");
  const migrations = new URL("../migrations/", import.meta.url);
  for (const file of readdirSync(migrations).filter(f => f.endsWith(".sql")).sort()) db.exec(readFileSync(new URL(file, migrations), "utf8"));
  function prepare(sql, values = []) {
    return {
      bind(...args) { return prepare(sql, args.map(v => v instanceof ArrayBuffer ? new Uint8Array(v) : v)); },
      async all() { return { results: db.prepare(sql).all(...values) }; },
      async first() { return db.prepare(sql).get(...values) ?? null; },
      async run() { return db.prepare(sql).run(...values); },
    };
  }
  const env = { IMPORT_TOKEN: "test-token", DB: {
    prepare,
    async batch(statements) {
      db.exec("BEGIN");
      try {
        const results = [];
        for (const statement of statements) results.push(await statement.all());
        db.exec("COMMIT");
        return results;
      } catch (error) {
        db.exec("ROLLBACK");
        throw error;
      }
    },
  }, ASSETS: { fetch: async request => new Response(new URL(request.url).pathname, {
    headers: { "content-type": "text/html" },
  }) } };
  const request = async (path, body, token = "test-token") => {
    const response = await worker.fetch(new Request(`https://test/api/${path}`, {
      method: "POST", headers: { "content-type": "application/json", authorization: `Bearer ${token}` }, body: JSON.stringify(body),
    }), env, {});
    return { status: response.status, body: await response.json() };
  };
  request.db = db;
  request.fetch = (path, options) => worker.fetch(new Request(`https://test${path}`, options), env, {});
  request.scheduled = () => worker.scheduled({}, env, {});
  return request;
}
