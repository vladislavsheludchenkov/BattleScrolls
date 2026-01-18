# Contributing to Battle Scrolls

Thank you for your interest in contributing to Battle Scrolls!

## Ways to Contribute

### Bug Reports

If you find a bug, please [open an issue](https://github.com/YOUR_USERNAME/BattleScrolls/issues/new) with:
- ESO client version and console platform (PlayStation/Xbox)
- Steps to reproduce the issue
- Expected vs actual behavior
- Any error messages from chat

### Feature Requests

Have an idea? Open an issue describing:
- What problem it would solve
- How you envision it working
- Any alternatives you've considered

### Translations

Battle Scrolls supports multiple languages. To contribute or improve translations:

1. Fork the repository
2. Edit the appropriate file in `BattleScrolls/lang/`:
   - `de.lua` - German
   - `es.lua` - Spanish
   - `fr.lua` - French
   - `jp.lua` - Japanese
   - `ru.lua` - Russian
   - `zh.lua` - Chinese
3. Submit a pull request

**Translation format:**
```lua
SafeAddString(BATTLESCROLLS_STRING_ID, "Your translation", 1)
```

### Adding New Strings

When adding new UI text:

1. Add the string ID to `lang/default.lua` (English):
   ```lua
   ZO_CreateStringId("BATTLESCROLLS_MY_NEW_STRING", "English text here")
   ```
2. Add the string ID to `.luarc.json` globals list (for type checking)
3. Submit your PR - translations can be added later by the community

You don't need to translate to all languages yourself. Once the string exists in `default.lua`, translators can add it to other language files.

### Code Contributions

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run type checking: `./scripts/typecheck.sh`
5. Test in-game with `/reloadui`
6. Submit a pull request

## Development Setup

> **Note**: While Battle Scrolls is distributed for consoles via Bethesda.net, development and testing is done on PC.

### Prerequisites
- ESO PC installed
- Text editor with Lua support (VS Code with [Lua extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) recommended)
- Git

### Getting Started

1. Clone the repo and set up type checking libraries inside it:
   ```bash
   git clone https://github.com/YOUR_USERNAME/BattleScrolls.git
   cd BattleScrolls

   # Clone ESO UI source (for type checking)
   git clone https://github.com/esoui/esoui.git
   ```

2. Set up additional type checking libraries. The `.luarc.json` expects these at the repo root (siblings to the `BattleScrolls/` addon folder).

   **Option A: Download directly** (extract into repo root):
   - [ESO API Lua autocomplete](https://www.esoui.com/downloads/info2654) - Extract as `eso-api-lua-intellij-baertram_API101048_2`
   - [LibAsync](https://www.esoui.com/downloads/info2125) - Extract as `LibAsync`
   - [LibGroupBroadcast](https://www.esoui.com/downloads/info1337) - Extract as `LibGroupBroadcast`

   **Option B: Symlink from your ESO AddOns folder** (if already installed):
   ```bash
   # From repo root
   ln -s ~/Documents/Elder\ Scrolls\ Online/live/AddOns/LibAsync LibAsync
   ln -s ~/Documents/Elder\ Scrolls\ Online/live/AddOns/LibGroupBroadcast LibGroupBroadcast
   ```

3. Your repo should look like:
   ```
   BattleScrolls/                  # Repo root (open this in your editor)
   ├── BattleScrolls/              # Addon folder (manifest + lua files)
   ├── .luarc.json                 # Type checker config (paths relative to addon folder)
   ├── scripts/
   ├── esoui/                      # Type checking: ESO UI source
   ├── eso-api-lua-intellij-baertram_API101048_2/  # Type checking: API definitions
   ├── LibAsync/                   # Type checking: symlink or download
   └── LibGroupBroadcast/          # Type checking: symlink or download
   ```

4. Set up ESO to load the addon. Symlink the `BattleScrolls/` addon folder to your AddOns:
   ```bash
   # macOS/Linux
   ln -s /path/to/repo/BattleScrolls/BattleScrolls ~/Documents/Elder\ Scrolls\ Online/live/AddOns/BattleScrolls

   # Windows (run as admin)
   mklink /D "Documents\Elder Scrolls Online\live\AddOns\BattleScrolls" "C:\path\to\repo\BattleScrolls\BattleScrolls"
   ```

5. Ensure LibGroupBroadcast and LibAsync are in your ESO AddOns folder (via Minion or manual download)

6. Launch ESO and test with `/reloadui`

### Type Checking

The project uses lua-language-server for type checking. The `.luarc.json` configures library paths.

```bash
./scripts/typecheck.sh
```

Maintain zero errors and warnings. If a warning must be suppressed, use:
```lua
---@diagnostic disable-next-line: reason-code -- explanation why
```

### Code Style

- Use local variables where possible
- Prefix addon-specific globals with `BattleScrolls.`
- Use `BattleScrolls.log.Debug/Info/Warn/Error` for logging
- Add type annotations for function parameters and return values
- Keep functions focused and reasonably sized

## Pull Request Guidelines

- Keep PRs focused on a single change
- Update relevant documentation
- Test your changes in-game before submitting
- Describe what your PR does and why

## License

Battle Scrolls is licensed under the MIT License. By contributing, you agree that your contributions will be licensed under the same terms.

When distributing the addon (including modified versions), you must include the LICENSE file.

## Questions?

Feel free to open an issue for any questions about contributing.
