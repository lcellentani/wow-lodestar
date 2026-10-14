# Zed setup

**Status (2026-10-14):** done. Steps 1-5 and 8-9 applied, and verified in Zed: `C_Map` completions, the `string.format` hover, the 2-space Tab, 2-space indentation kept on Enter and save (after the `.zed/settings.json` fix, step 4), and the check task.

Steps to move Lodestar's editor setup from VS Code to Zed (Windows). Only the editor layer changes: the game junction, `tools/` (Lua 5.1, luacheck), `.luacheckrc`, `scripts/check.ps1` and the Claude Code CLI work as they are.

The plan moves editor settings into files that any editor reads (`.luarc.json`, `.editorconfig`), so Zed needs very little config of its own and VS Code keeps working during the switch.

Mark each step done as you go. Where a step says **Verify**, report what you see; anything that differs from what's expected here gets fixed in this file.

## 1. Install the Zed Lua extension

1. In Zed: `ctrl-shift-x` (Extensions), search **Lua**, install it.
2. It downloads lua-language-server (LuaLS) by itself the first time you open a `.lua` file. This is the same server the VS Code `sumneko.lua` extension runs.

**Verify:** open `Logic.lua`, hover a local function: a hover card appears.

## 2. Get the WoW API annotations without the VS Code extension

The annotations are plain `.lua` files in Ketho's GitHub repo. Clone them into the git-ignored `tools/` folder, pinned to a tag, so they only change when you choose to update.

```powershell
git ls-remote --tags https://github.com/Ketho/vscode-wow-api   # pick the newest tag
git clone --depth 1 --branch <tag> https://github.com/Ketho/vscode-wow-api tools\wow-api
```

Check that `tools\wow-api\Annotations\Core` exists. VS Code currently uses the same folder from inside the extension (`ketho.wow-api-0.22.3`).

To update later: delete `tools\wow-api` and clone again with the new tag, then record the tag in `notes/environment.md`.

## 3. Move the LuaLS settings to `.luarc.json`

LuaLS reads `.luarc.json` from the repo root in any editor. It replaces the `Lua.*` keys in `.vscode/settings.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "runtime.version": "Lua 5.1",
  "runtime.builtin": {
    "basic": "disable",
    "debug": "disable",
    "io": "disable",
    "math": "disable",
    "os": "disable",
    "package": "disable",
    "string": "disable",
    "table": "disable",
    "utf8": "disable"
  },
  "workspace.library": [
    "tools/wow-api/Annotations/Core"
  ],
  "workspace.ignoreDir": [
    "tools/lua",
    "tests"
  ]
}
```

Notes:

- The builtins are disabled because Ketho's annotations ship their own Lua standard library annotations (WoW's flavor of it). This is the same as in VS Code today.
- `workspace.ignoreDir` keeps LuaLS from indexing the Lua binaries folder. `tests` is ignored because the test harness defines `describe` and `it`, which would otherwise show as undefined globals. Remove `tests` from the list if you'd rather see diagnostics there.
- The library path is relative to the repo root.

**Verify** (after restarting Zed, or running `editor: restart language server`):

1. In a `.lua` file, type `C_Map.`: completions for `C_Map` functions appear.
2. Hover `string.format`: it shows a signature. If `string` shows as undefined instead, the annotations don't cover the standard library: change those `runtime.builtin` entries to `"enable"`.
3. `LodestarDB` and other addon globals may show as undefined-global warnings. That matches VS Code today; luacheck is the authority on globals, not LuaLS.

## 4. Move indentation to `.editorconfig`

Zed and VS Code (with the EditorConfig extension) both read it. It replaces the `[lua]` block in `.vscode/settings.json`:

```ini
root = true

[*]
charset = utf-8
insert_final_newline = true
trim_trailing_whitespace = true

[*.lua]
indent_style = space
indent_size = 2

[*.{toc,xml}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
```

`.editorconfig` alone is not enough for Lua in Zed. LuaLS reformats code in two places: the line you just finished when you press Enter (`textDocument/onTypeFormatting`) and the whole file on save. Both take the indent width from the `tabSize` Zed sends with the request, not from `.editorconfig`, and Zed kept sending 4. Tab inserted 2 spaces while Enter and save reindented to 4 (found 2026-10-14; read in LuaLS 3.19.2's `script/provider/provider.lua`). So Lua's indent is also set in `.zed/settings.json`:

```json
{
  "languages": {
    "Lua": {
      "tab_size": 2,
      "hard_tabs": false
    }
  }
}
```

There is no `end_of_line` setting on purpose. The repo stores LF (`git ls-files --eol`), and `core.autocrlf=true` handles the conversion on checkout, so Zed should keep whatever ending each file already has.

**Verify:** press Tab in a `.lua` file: it inserts 2 spaces. Then type a `for` loop inside a function, pressing Enter after each line, and save: every level stays 2 spaces.

## 5. Add a task for `check.ps1`

`.zed/tasks.json`:

```json
[
  {
    "label": "Lodestar: check",
    "command": "powershell",
    "args": ["-NoProfile", "-File", "scripts/check.ps1"],
    "cwd": "$ZED_WORKTREE_ROOT",
    "reveal": "always",
    "allow_concurrent_runs": false
  }
]
```

Run it with `task: spawn` from the command palette (`ctrl-shift-p`). To bind it to a key, add to your user keymap (`zed: open keymap`):

```json
{
  "context": "Workspace",
  "bindings": {
    "ctrl-shift-b": ["task::Spawn", { "task_name": "Lodestar: check" }]
  }
}
```

The execution policy is already `RemoteSigned` for your user (see `notes/environment.md`), so no `-ExecutionPolicy` flag is needed.

**Verify:** the task prints `All checks passed` in Zed's terminal panel.

## 6. Claude Code

Either option works with the repo as it is; `CLAUDE.md` and the memory files are read the same way.

- **CLI in Zed's terminal** (`` ctrl-` ``): run `claude` from the repo root. This is the setup we use today, minus the VS Code extension's diff view.
- **Zed agent panel:** Zed can host Claude Code as an external agent. Try it if you prefer reviewing edits inside the editor. If anything behaves differently from the CLI, use the CLI.

## 7. Files Zed doesn't support as well

- **`.toc`:** install the community **World of Warcraft TOC** extension (`wow-toc`, syntax highlighting only). Without it, `.toc` files show as plain text.
- **`Pins.xml` (M4):** install Zed's **XML** extension for highlighting. Neither editor validates against Blizzard's UI schema in this setup.

## 8. Retire VS Code config (after steps 1-5 pass)

1. Delete `.vscode/settings.json` and the `.vscode/` folder (it is tracked in git, so this is a commit).
2. Optionally uninstall `sumneko.lua` and `ketho.wow-api` from VS Code.

Until then, keeping both is harmless: `.luarc.json` takes precedence over the VS Code `Lua.*` settings in LuaLS.

## 9. Update the docs

Claude does this when you ask, after step 8:

- Design doc, "Dev environment setup": the intro line that recommends VS Code, step 8 (editor help) and the M1 done criterion ("VS Code shows WoW API completions").
- Design doc, Milestones, M1: "the VS Code extensions" becomes "the editor setup".
- `notes/environment.md`: replace the VS Code line with Zed, the Lua extension and the pinned `tools\wow-api` tag.
- `CLAUDE.md`, evidence rule: "VS Code WoW API annotations" becomes "WoW API annotations".
- Commit `.luarc.json`, `.editorconfig` and `.zed/tasks.json` with the doc changes.
