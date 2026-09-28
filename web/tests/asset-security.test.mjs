import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { test } from "node:test";
import { createTestHarness } from "wrangler";

// Run Cloudflare's actual asset router: calling worker.fetch with a mocked
// ASSETS binding cannot catch headers missing on asset-first requests.
test("page routes and direct HTML assets share the same security policy", async t => {
  const server = createTestHarness({
    root: fileURLToPath(new URL("../", import.meta.url)),
    workers: [{ configPath: "wrangler.jsonc" }],
  });
  t.after(() => server.close());
  await server.listen();
  let policy;
  for (const path of ["/u", "/u/", "/upload.html", "/s/audit12345", "/viewer.html",
    "/privacy", "/privacy/?l=ru", "/privacy.html"]) {
    for (const method of ["GET", "HEAD"]) {
      const response = await server.fetch(path, { method });
      assert.equal(response.status, 200, `${method} ${path}`);
      assert.match(response.headers.get("content-type"), /text\/html/);
      assert.equal(response.headers.get("referrer-policy"), "same-origin", path);
      assert.equal(response.headers.get("x-content-type-options"), "nosniff", path);
      const csp = response.headers.get("content-security-policy");
      assert.ok(csp?.includes("script-src 'self'"), path);
      assert.ok(csp.includes("object-src 'none'"), path);
      policy ??= csp;
      assert.equal(csp, policy, path);
      await response.arrayBuffer();
    }
  }
});
