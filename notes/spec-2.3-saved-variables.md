# M2 step 2.3: `LodestarDB` defaults and version

Status: done 2026-10-15 (user wrote the code, Claude reviewed); verified in game as P20 in `notes/beta-probes.md`.
Design doc reference: "SavedVariables" section.

## What `LodestarDB` is

`LodestarDB` is the addon's only persistent memory. Everything else in Lua is gone after `/reload` or logout; this table survives because the `.toc` declares `## SavedVariables: LodestarDB`.

How it works (think of a config file the engine serializes for you):

- At logout or `/reload`, the game writes the table to `WTF/Account/<ACCOUNT>/SavedVariables/Lodestar.lua` as Lua source (`LodestarDB = { ... }`).
- At the next load, the game runs that file before the addon's events fire, so the global `LodestarDB` exists again with the same contents.
- Only plain data survives: numbers, strings, booleans, nested tables. No functions, frames or Blizzard objects.
- It is per account: every character shares it.
- On the very first run there is no file, so `LodestarDB` is `nil`.

### What each field enables

| Field | Concretely | Used from |
| --- | --- | --- |
| `version` | Schema stamp. If a later version changes the shape, `Core.lua` sees `version == 1` and converts old data instead of breaking. | Inert until the schema changes |
| `modules` | On/off switch per feature, remembered across restarts (e.g. labels hidden with `/ls` stay hidden). | 2.4 (registry), 2.5 (`/ls`) |
| `overrides.zones` | User level-range corrections (`/ls zone ...`). They win over the client (`C_Map.GetMapLevels` returns zeros on the beta, P6) and over the shipped data. | M3 |
| `waypoints` | User map pins. | v2 |
| `log` | Bridge between the game and Claude Code: `/ls probe` and `/ls dump` append here, the game writes it to disk, Claude reads the file. Last 50 entries. | 2.6 |

### Why merge defaults

The saved table can be incomplete in two cases:

1. First run: nothing saved yet.
2. After an update: an older saved file lacks a key that new code added (e.g. `waypoints` in v2).

The merge fills in what is missing and keeps what the user already set, so the rest of the code can rely on `ns.db.modules.Tooltip` existing, with no nil checks everywhere.

## Goal

After login, `LodestarDB` always holds the full schema from the design doc. Saved values are preserved, missing keys are filled from defaults, and `version` is set.

## Decisions

- Init runs on `PLAYER_LOGIN` (confirmed in P18; SavedVariables are loaded by then). `ADDON_LOADED` is deferred to the event dispatcher in step 2.4.
- No migration code yet: with a single schema version there is nothing to migrate.
- Other files use `ns.db`, never the global `LodestarDB` directly.

## Part 1: `Logic.MergeDefaults(saved, defaults)` in `Logic.lua`

Rules, for each key `k` in `defaults`:

1. `saved[k] == nil` → put a **copy** of `defaults[k]` into `saved[k]`.
2. Both `saved[k]` and `defaults[k]` are tables → `MergeDefaults(saved[k], defaults[k])` (recursion).
3. Otherwise leave `saved[k]` alone: the saved value wins.

Keys in `saved` that are not in `defaults` are kept (e.g. `overrides.zones[1429]`). The function changes `saved` in place and returns it.

Hints:

- Walk with `for k, v in pairs(defaults) do ... end`; test with `type(v) == "table"`.
- **The trap:** tables are references, like pointers in C++. `saved.log = defaults.log` would make every log line also land in the defaults table. Write a `local function copy(t)` (deep, recursive) and use it in rule 1.
- Recursion: `Logic.MergeDefaults` can call itself by that name; `local function copy` can call itself too, because `local function f` declares the name before the body.

## Part 2: tests in `tests/logic_spec.lua`

A `describe("MergeDefaults", ...)` block with:

- Empty `saved` receives every default, nested tables included.
- A saved value that differs from the default (e.g. `modules.Tooltip = false`) stays.
- A partially filled nested table (e.g. `modules` with only `ZoneLabels`) gets the missing siblings.
- Extra saved keys not in `defaults` survive.
- No shared references: after the merge `saved.log ~= defaults.log`, and changing `saved` leaves `defaults` untouched.

## Part 3: `Core.lua`

- A file-level `local DEFAULTS = { ... }` copied from the design doc schema, `version = 1`:

  ```lua
  {
    version = 1,
    modules = { ZoneLabels = true, Instances = true, Tooltip = true },
    overrides = { zones = {} },
    waypoints = {},
    log = {},
  }
  ```

- In the `PLAYER_LOGIN` handler: `LodestarDB = ns.Logic.MergeDefaults(LodestarDB or {}, DEFAULTS)`, then `ns.db = LodestarDB`.
- The hello line shows the version, e.g. `"loaded, db v" .. ns.db.version`.

## Part 4: in-game check (probe P20)

1. `/reload` → the hello line shows `db v1`.
2. `/run LodestarDB.modules.Tooltip = false`, `/reload`, `/dump LodestarDB.modules` → `Tooltip` is still `false` (saved values survive the merge).
3. Log out, tell Claude; Claude reads `WTF/.../SavedVariables/Lodestar.lua` and records P20 in `notes/beta-probes.md`.

## Done when

- `scripts/check.ps1` passes (luacheck + tests).
- The P20 steps above behave as described.
