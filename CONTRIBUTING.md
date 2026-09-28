# Contributing to Battle Scrolls

Bug reports, fixes, translations, and improvements to the combat reports are welcome. For a larger feature, open an [issue](https://github.com/vladislavsheludchenkov/BattleScrolls/issues) describing the player problem and proposed behavior before starting a broad change.

## Reporting problems

Include your platform, ESO version, Battle Scrolls version, steps to reproduce, and expected versus actual behavior. Add error text or a screenshot when useful. For viewer problems, also include the browser and affected tab. Shared reports and SavedVariables can contain player names and builds; send private material to **v@sheludchenkov.com** instead of posting it in an issue.

## Repository layout

| Path | Purpose |
| --- | --- |
| `BattleScrolls/` | The addon: combat collection, storage, group sharing, localization, and gamepad UI. |
| `web/` | TypeScript viewer and upload pages, Cloudflare Worker, D1 migrations, and web tests. |
| `tests/` | Offline Lua tests, ESO/LibAsync mocks, and fixtures used by both test suites. |
| `scripts/` | Lua test runner, Lua type checker, and game metadata importer. |
| `BattleScrollsAbilityDump/` | Separate development addon for mining game metadata; also exercised by the Lua tests. |
| `release-notes/` | Plain-text publishing notes, one file per release. |
| `GLOSSARY.md` | Terminology shared by the addon, viewer, and release notes. |

Only `BattleScrolls/` goes into the downloadable addon ZIP. The metadata miner is a development tool, installed separately when needed.

## Addon development

Clone the repository, then install or link its inner `BattleScrolls/` directory into your ESO PC `live/AddOns/` directory. Install **LibAsync** and **LibGroupBroadcast** there as well. Enable gamepad mode, open **Journal → Battle Scrolls**, and use `/reloadui` after edits. The Lua/XML addon has no build step.

The manifest is `BattleScrolls/BattleScrolls.addon`. Its file order is significant: add new Lua/XML files after their dependencies. Leave the version placeholders intact; the release workflow fills them in.

For type checking, install `lua-language-server` and place these reference directories at the repository root, next to the inner addon directory:

- `esoui/`: [ESO UI sources](https://github.com/esoui/esoui).
- `eso-api-lua-intellij-baertram_API101048_2/`: ESO API definitions matching the path in `.luarc.json`.
- `LibAsync/` and `LibGroupBroadcast/`: copies or symlinks of the required libraries.

These references are not committed or included in release ZIPs. On macOS, the command-line tools can be installed with `brew install lua lua-language-server`.

The group-sharing tests load the real ESO base object and LibGroupBroadcast codecs, with the transport mocked. For a fresh checkout, these commands install the exact revisions used in CI (skip existing directories if you already have these revisions):

```sh
git clone https://github.com/esoui/esoui.git esoui
git -C esoui checkout b8e5666e237ebb6fe5cf4a18edd5790df8137584
mkdir -p .test-deps
git clone https://github.com/vladislavsheludchenkov/ESO-LibGroupBroadcast.git .test-deps/LibGroupBroadcast
git -C .test-deps/LibGroupBroadcast checkout 3c07711ce9d4221f7971594524477fc76a1ef934
ln -s .test-deps/LibGroupBroadcast/src LibGroupBroadcast
```

The pinned LibGroupBroadcast revision is a fork containing the deserialization-error fix required by the truncated-message recovery test. An unpatched upstream copy will fail that test. This checkout is for development and testing; it is not bundled in the Battle Scrolls release ZIP.

Then run from the repository root:

```sh
./scripts/typecheck.sh
./scripts/test.sh
```

Allow at least two minutes for type checking. Use the script's results rather than IDE diagnostics and keep both errors and warnings at zero. The offline Lua tests use Lua 5.4; the runner can also locate `lua5.4` or `lua5.3` when `lua` is unavailable.

## Web development

Use **Node.js 24** and npm, matching the release workflow, plus **Lua 5.4** on `PATH` as `lua`. Some web tests generate fixtures through the addon and exercise the metadata importer. Run web commands from `web/`:

```sh
cd web
npm ci
npm run check
npm test
npm run build
npx --no-install wrangler d1 migrations apply DB --local
npm run dev
```

`npm run dev` checks and builds the sources, then starts Wrangler's local server. Restart it after edits to rebuild the client bundles. Local migrations prepare the schema; they do not populate the game metadata database. Some names, tooltips, and icons need imported metadata or access to the icon source.

`web/migrations/0001_init.sql` defines the release schema. Add future schema changes as new migrations; keep released migration files and their names unchanged. Wrangler records applied filenames in `d1_migrations`.

`npm run gen` derives icon overrides from the addon. It runs automatically before checks and builds, so keep the complete repository checkout. The generated `web/src/shared/icon_overrides.ts` is committed; include changes to it when its Lua source changes. The browser bundles in `web/public/*.js` are build outputs and stay untracked.

The existing `wrangler.jsonc` targets the production `bs-share` Worker, `bs-share` D1 database, `bs-icons` R2 bucket, and `bs.sheludchenkov.com` domain. Normal local development uses local bindings. For your own deployment, configure your own resources and domain first. `npm run deploy` checks, builds, and deploys to the configured Cloudflare target; it does not apply database migrations.

Keep local credentials in ignored `.dev.vars` or `.env` files. The Worker's `IMPORT_TOKEN` protects metadata imports and is separate from the Cloudflare deployment token. The production importer, `scripts/import-abilities.sh`, reads `~/.bs-share-import-token` (or `BS_IMPORT_TOKEN_FILE`) and sends mined data to the production service. Its test cases use fixtures and mocked uploads.

## Verification and test limitations

**The Lua and web tests are mostly AI-maintained and have less human review than the rest of the codebase.** Review test assumptions and mocks alongside the implementation. A green suite is useful evidence, but it does not establish that the code behaves correctly inside ESO or that the game API assumptions are correct.

The Lua suite runs outside ESO with small mocks for the game API and asynchronous scheduler. The web suite uses Node's test runner, SQLite, and mocked Worker bindings. Neither suite reproduces ESO's Havok runtime, a live group encounter, or the deployed Cloudflare environment.

For a pull request:

- Run `./scripts/typecheck.sh` for addon behavior changes and `./scripts/test.sh` for Lua changes covered by the suite.
- Run `npm run check`, `npm test`, and `npm run build` in `web/` for web changes. For deployment changes, also run `npx --no-install wrangler deploy --dry-run` after the build.
- Exercise affected behavior in ESO or a browser. Changes to sharing or binary formats need checks at both ends, including older stored encounters and fixtures.
- Explain what you checked, what passed, and what you could not verify. Keep the PR focused and describe the resulting behavior.

## Code and translations

Follow the surrounding code and fix the underlying cause. Check callers before changing shared functions, formats, or string IDs. Avoid unused compatibility code and speculative abstractions.

Lua modules use `BattleScrolls.*`, local module tables, `PascalCase` types, `.new()` constructors, `camelCase` methods and locals, and `SCREAMING_SNAKE_CASE` constants. Add precise LuaLS annotations; prefer named `---@class` types for parameter and return structures. Keep Journal UI modules declarative: only `journal.lua` defines methods on `BattleScrolls_Journal_Gamepad`.

Read [GLOSSARY.md](GLOSSARY.md) before changing UI text or release notes. Prefer the names and descriptions players see in ESO. Addon strings belong in `BattleScrolls/lang/default.lua` and all six translations (`de`, `es`, `fr`, `jp`, `ru`, `zh`). Add new string IDs to the sorted `diagnostics.globals` list in `.luarc.json`. Update all languages when the meaning changes; do not hardcode user-visible text. Web translations live in `web/src/client/strings.ts` and `privacy-copy.ts`; the web Japanese locale is `ja`.

Keep the English in-game release notes consistent with their publishing text. Bethesda publishing notes must stay below 2,000 characters.

## License

Contributions are distributed under the [MIT License](LICENSE). Keep the license with redistributed or modified copies of the addon.
