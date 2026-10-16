# M2 step 2.5: slash commands (`/ls`, `/lodestar`)

Status: 2.5a done 2026-10-16 (P24 in `notes/beta-probes.md`); 2.5b not started. User writes the code, Claude reviews.
Design doc reference: "Settings and slash commands".

## What this step is for

The MVP has no settings window: everything is a slash command. This step builds the command plumbing and the first two real commands. The other commands come with the code they drive:

| Command | Step |
| --- | --- |
| `/ls` (help), `/ls toggle <module>`, `/ls debug` | 2.5 (this step) |
| `/ls probe`, `/ls dump`, `/ls copy`, `/ls log clear` | 2.6 (`Debug.lua`) |
| `/ls zone ...`, `/ls overrides` | M3 (they need the zone lookup) |

## Decisions

- **The command registry lives in `Core.lua`**, next to the event, module and map tick registries: `ns.RegisterCommand(name, handler, usage)`. Each file registers its own commands, so `Debug.lua` (2.6) adds its commands without touching `Options.lua`.
- **`Options.lua` owns the slash command globals** (`SLASH_LODESTAR1`, `SLASH_LODESTAR2`, `SlashCmdList.LODESTAR`, allowed by the doc's "One namespace" rule and already in `.luacheckrc`) and registers `toggle` and `debug`.
- **The debug flag is session-only**: `ns.debug`, reset by `/reload`. No schema change.
- **Parsing is pure**: `Logic.ParseCommand` and `Logic.FindName` get unit tests.
- Command names are case-insensitive (`/ls TOGGLE` works); module names too (`zonelabels` finds `ZoneLabels`).
- Two checkpoints, each with an in-game check and its own commit: 2.5a (plumbing and help, P24) and 2.5b (toggle and debug, P25).

## 2.5a: parsing, registry, slash command, help

### `Logic.ParseCommand(msg)` in `Logic.lua`

Splits what the player typed after `/ls` into a command and its arguments:

- Returns `command, args`: `command` is the first word, lowercased; `args` is a list (array table) of the remaining words, case kept.
- Empty or blank input returns `""` and an empty list.
- Any run of spaces separates words; leading and trailing spaces are ignored.

Hints:

- `for word in string.gmatch(msg, "%S+") do ... end` walks the words. `%S` is a Lua pattern class meaning "not a space" (Lua patterns are simpler than regex: no `|`, no `{n}`).
- `string.lower(s)`, or `s:lower()`, lowercases. The colon works on strings because strings share a method table.
- Append to a list with `args[#args + 1] = word` (or `table.insert(args, word)`).

Tests (`describe("ParseCommand", ...)`):

- `""` → `""`, `{}`.
- `"   "` → `""`, `{}`.
- `"toggle ZoneLabels"` → `"toggle"`, `{ "ZoneLabels" }`.
- `"  TOGGLE   ZoneLabels  "` → `"toggle"`, `{ "ZoneLabels" }` (spaces and case).
- `"zone here 10 20"` → `"zone"`, `{ "here", "10", "20" }` (several args; numbers stay strings).

### Command registry in `Core.lua`

- `local commands = {}`: `commands[name] = { handler = fn, usage = "..." }`, with `name` stored lowercased.
- `ns.RegisterCommand(name, handler, usage)`: stores it. `usage` is one help line, for example `"toggle <module> - turn a module on or off"`.
- `ns.RunCommand(msg)`: `ParseCommand`, then:
  - empty command → print the help;
  - unknown command → print `unknown command "<name>", type /ls for help`;
  - otherwise `ns.SafeCall(entry.handler, args)`.
- Help prints one line per command, **sorted by name**, so the list does not change order between reloads.

Hints:

- `pairs` has no order. To sort, copy the names into a list, then `table.sort(list)` (sorts strings alphabetically in place), then walk it with `ipairs`.
- Handlers get the `args` list only; they already know their own name.

### `Options.lua` (new file)

- Starts with `local addonName, ns = ...` like every file.
- Sets `SLASH_LODESTAR1 = "/ls"`, `SLASH_LODESTAR2 = "/lodestar"` and `SlashCmdList.LODESTAR = ns.RunCommand` (P16f: the game passes the text after the command as the first argument).
- Add `Options.lua` to `Lodestar.toc`, last (the doc's load order: Debug.lua and Options.lua come last).

### Temporary in-game test (remove before commit)

A temporary command in `Options.lua`: `echo`, whose handler prints each argument between `|` separators (or with `table.concat(args, " | ")`).

Check in game (P24):

```
/reload
```

```
/ls
```

Expected: the help list, with the `echo` line.

```
/lodestar
```

Expected: the same help list (the alias works).

```
/ls   ECHO  Hello   World
```

Expected: `Hello | World` (case kept for args, spaces collapsed, command matched case-insensitively).

```
/ls nope
```

Expected: the unknown-command line.

## 2.5b: `/ls toggle` and `/ls debug`

### `Logic.FindName(names, input)` in `Logic.lua`

- `names` is a list of canonical names (for example `{ "Instances", "Tooltip", "ZoneLabels" }`); returns the entry that matches `input` ignoring case, or `nil`.
- `nil` input returns `nil`.

Tests (`describe("FindName", ...)`): exact match; different case (`"zonelabels"` → `"ZoneLabels"`); no match → `nil`; `nil` input → `nil`.

### Module on/off in `Core.lua`

Today `OnLogin` calls `OnEnable` once and nothing ever calls `OnDisable`. Toggling at runtime needs the core to know which modules are running:

- A file-level set `local runningModules = {}`. `OnLogin` marks each module it enables.
- `ns.GetModuleNames()`: the registered names, sorted (same `table.sort` trick as the help).
- `ns.IsModuleRunning(name)`: boolean.
- `ns.SetModuleEnabled(name, enabled)`:
  - saves the choice: `ns.db.modules[name] = enabled`;
  - if `enabled` and not running → `ns.SafeCall(module.OnEnable, module)`, mark running;
  - if not `enabled` and running → `ns.SafeCall(module.OnDisable, module)`, unmark;
  - otherwise does nothing (no double `OnEnable`).
- Mark the module running only if `OnEnable` succeeded: `ns.SafeCall` returns `true` first when the call worked (step 2.2).

### Commands in `Options.lua`

- `toggle`: `args[1]` through `Logic.FindName(ns.GetModuleNames(), args[1])`.
  - No match or no argument → print the usage and the module names (`table.concat(names, ", ")`).
  - Match → `ns.SetModuleEnabled(name, not ns.IsModuleRunning(name))`, then print `<name>: on` or `<name>: off`.
- `debug`: flips `ns.debug`, prints `debug on` or `debug off`. When turning on, also prints each module with on/off and `map tick running: true/false` (`ns.IsMapTickRunning()`).
- `ns.DebugPrint(...)` in `Util.lua`: same as `ns.Print`, but only when `ns.debug` is true. Nothing calls it yet; modules will use it for verbose output.

Hints:

- `not x` flips a boolean. `x and "on" or "off"` is Lua's ternary idiom (works when the middle value is not `false` or `nil`).
- A module without `OnDisable` would make `SafeCall` print an error: the contract says every module has both.

### Temporary in-game test (remove before commit)

A temporary module `TestA` at the bottom of `Core.lua`, with `OnEnable` printing `TestA on` and `OnDisable` printing `TestA off`.

Check in game (P25):

```
/reload
```

Expected: `TestA on` at login.

```
/ls toggle testa
```

Expected: `TestA off` (from `OnDisable`), then `TestA: off`.

```
/ls toggle TestA
```

Expected: `TestA on`, then `TestA: on`.

```
/ls toggle
```

Expected: the usage line and `TestA` in the module list.

```
/ls debug
```

Expected: `debug on`, `TestA: on`, `map tick running: false`.

Then open the map and run the command again with the map open:

```
/ls debug
```

Expected: `debug off`. (Turn it on again with the map open to see `map tick running: true`.)

Finally, check the choice is saved: toggle TestA off, `/reload`, and TestA must not print `TestA on` at login. Clean up afterwards:

```
/run LodestarDB.modules.TestA = nil
```

## Done when (each checkpoint)

- `scripts/check.ps1` passes (luacheck + tests).
- The in-game check behaves as described; Claude records it in `notes/beta-probes.md` (P24 for 2.5a, P25 for 2.5b).
- The temporary test code is removed, then the part is committed.
