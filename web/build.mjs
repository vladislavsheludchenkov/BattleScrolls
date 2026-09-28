// Client bundles: TypeScript sources -> fixed-name IIFE bundles in public/.
// The worker is NOT built here - wrangler bundles src/worker.ts natively.
import esbuild from "esbuild";

const common = {
    bundle: true,
    minify: true,
    sourcemap: false,
    target: ["es2019"],
    format: "iife",
    logLevel: "info",
};

await esbuild.build({ ...common, entryPoints: ["src/client/app.ts"], outfile: "public/app.js" });
await esbuild.build({ ...common, entryPoints: ["src/client/upload.ts"], outfile: "public/upload.js" });
await esbuild.build({ ...common, entryPoints: ["src/client/privacy.ts"], outfile: "public/privacy.js" });
