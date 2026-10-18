# M2 step 2.6: `Debug.lua` (log, copy window, dump, probe)

Status: spec agreed 2026-10-17; 2.6a detailed, 2.6b-2.6d outlined (each detailed before it starts). User writes the code, Claude reviews.
Design doc reference: "Settings and slash commands", "Getting output out of the game".

## What this step is for

The chat window cannot be copied from, so output that matters (dumps, probes, caught errors) must also reach a place where it can be read later: the log in `LodestarDB.log`, which Claude Code reads from the SavedVariables file, and the copy window, which selects the text for Ctrl+C. This step builds both, then the two commands that produce most of that output: `/ls dump` (collects the zone data) and `/ls probe` (re-runs the design probes from code).

## Decisions

- **Four checkpoints**, each with an in-game check and its own commits: 2.6a output and log (P27), 2.6b copy window (P28 method probe, P29 check), 2.6c `/ls dump` (P30), 2.6d `/ls probe` (P31). Dump comes before probe: the beta closes Oct 21, and dump is what collects the beta's zone IDs; probe repeats checks already done by hand, so it can wait for the live client.
- **Dump starts basic**: it reports what the client knows (map, children, client level ranges, a ready-made row per child). The comparison with `Data/Zones.lua` comes in M3, once that table exists.
- **Commands collect their lines, then emit once**: a command builds a list of lines and calls `ns.Emit(command, lines)`, which prints them, logs them and keeps them for `/ls copy`. No hidden capture of `ns.Print` calls.
- **The log trim is pure**: `Logic.AppendLog` gets unit tests; the WoW side (`date`, `ns.db`) stays in `Util.lua`.
- **Commits per checkpoint** (from 2.6 on): the user's code as `[T2] feat(...)`, Claude's notes as a separate `[T4] docs(notes): ...`.

## 2.6a: output, log, `/ls log clear`

### `Logic.AppendLog(log, entry, max)` in `Logic.lua`

- Appends `entry` to the list `log`, then drops the oldest entries (from the front) until `#log <= max`. Returns `log`.
- It changes `log` in place (like `MergeDefaults` changes `saved`): `ns.db.log` must stay the same table, since it is part of `LodestarDB`.

Tests (`describe("AppendLog", ...)`):

- Appending to an empty list gives one entry.
- Entries keep their order (oldest first).
- With `max = 3` and four appends, the list holds the last three, oldest dropped.
- With exactly `max` entries nothing is dropped.

Hints:

- `table.remove(t, 1)` removes the first element and shifts the rest down; `t[#t + 1] = x` appends.
- A `while #log > max do ... end` loop handles it even if the list was already too long (for example if `max` changes later).
- In the tests, entries can be plain strings or numbers: `AppendLog` never looks inside them.

### Output functions in `Util.lua`

- A file-level `local lastOutput = nil` and a constant `local LOG_MAX = 50` (the doc's "last 50 entries").
- `ns.Record(command, lines)`: builds one entry `{ time = date("%Y-%m-%d %H:%M:%S"), command = command, lines = lines }`, keeps it as `lastOutput`, and, if `ns.db` exists, appends it with `ns.Logic.AppendLog(ns.db.log, entry, LOG_MAX)`. Prints nothing.
- `ns.Emit(command, lines)`: prints each line with `ns.Print`, then `ns.Record(command, lines)`.
- `ns.GetLastOutput()`: returns `lastOutput` (the entry table, or `nil`). Step 2.6b's copy window reads it.
- `ns.SafeCall`: on error, after printing as today, also `ns.Record("error", { tostring(message) })`, so caught errors reach the log (the doc: "errors caught by the safe-call wrapper").

Hints:

- `if ns.db then ... end`: errors can happen before `PLAYER_LOGIN` (while files load), when there is no `ns.db` yet. Then the entry is kept as last output only.
- `date` is confirmed (P16b) and already in `read_globals`.
- `Record` keeps the `lines` table itself, not a copy, so a command must build a new list for each call.
- `Util.lua` loads before `Core.lua`, but `Record` only reads `ns.db` and `ns.Logic` when it runs, so the order is fine.

Tests (`tests/util_spec.lua`):

- The spec loads only `Util.lua`, so it needs fakes: `ns.Logic` (load `Logic.lua` into the same `ns`, like `logic_spec` does), a fake `date` returning a fixed string, and `ns.db = { log = {} }` where a test needs the log. Claude adds `date` to the test globals in `.luacheckrc`.
- `Emit` prints one line per entry in `lines`, and `GetLastOutput()` returns an entry with that command and those lines.
- `Record` with `ns.db` set appends one entry with `time`, `command` and `lines`.
- `Record` with `ns.db = nil` does not fail and still sets the last output.
- `SafeCall` on error records an entry with command `"error"` and a line containing the message.
- Reset the shared state at the start of each test (`ns.db`, `lines`), since tests run in one file and share it.

### `Debug.lua` (new file)

- Starts with `local addonName, ns = ...`.
- Registers `log` with usage `"log clear - empty the saved output log"`: `/ls log clear` empties `ns.db.log` and prints how many entries it removed; anything else prints the usage.
- Add `Debug.lua` to `Lodestar.toc` before `Options.lua` (the doc's load order).

Hints:

- Args keep their case, so compare `string.lower(args[1] or "")` with `"clear"`. `args[1] or ""` turns `nil` into an empty string, since `string.lower(nil)` is an error.
- To empty the log, either `ns.db.log = {}` (a new table; `ns.db` is `LodestarDB`, so it is saved) or remove entries in a loop. Count first, then empty.

### Temporary in-game test (remove before commit)

Two temporary commands in `Debug.lua`:

- `emit`: calls `ns.Emit("emit", { "line one", "line two" })`.
- `boom`: calls `error("boom test")`.

Check in game (P27):

```
/reload
```

```
/ls emit
```

Expected: `line one`, `line two` in chat.

```
/ls boom
```

Expected: the red error line with `boom test`.

```
/reload
```

Then tell Claude: the SavedVariables file should hold two log entries, `emit` with the two lines and `error` with the message, each with a timestamp.

```
/ls log clear
```

Expected: `log cleared (2 entries)` or similar.

```
/reload
```

Then tell Claude again: the file should show an empty `log`.

## 2.6b: copy window (outline)

- `/ls copy` opens `LodestarCopyFrame` (an allowed global, already in `.luacheckrc`) with the lines of `ns.GetLastOutput()` joined by `"\n"`, all selected, so Ctrl+C copies them. Escape closes it (`UISpecialFrames`). Created on first use, then reused. Movable.
- Built from the pieces confirmed in P16g: a `"Frame"` with `BasicFrameTemplateWithInset`, a `"ScrollFrame"` with `UIPanelScrollFrameTemplate`, a multi-line `"EditBox"` as the scroll child.
- The frame methods it needs were not part of P16g. **P28** checks them; it needs no addon, so it can run any time before 2.6b (ideally while the beta is open):

```
/run local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset"); f:Hide(); print("Frame", f.SetSize ~= nil, f.SetPoint ~= nil, f.SetMovable ~= nil, f.EnableMouse ~= nil, f.RegisterForDrag ~= nil, f.StartMoving ~= nil, f.StopMovingOrSizing ~= nil, f.TitleText ~= nil)
```

```
/run local s = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate"); s:Hide(); print("Scroll", s.SetScrollChild ~= nil, s.SetPoint ~= nil)
```

```
/run local e = CreateFrame("EditBox", nil, UIParent); e:Hide(); print("EditBox", e.SetText ~= nil, e.SetFocus ~= nil, e.SetFontObject ~= nil, e.SetWidth ~= nil, ChatFontNormal ~= nil)
```

Expected: every value `true`. In-game check of the window: P29.

## 2.6c: `/ls dump` (outline)

- Prints, through `ns.Emit("dump", lines)`: the map's ID, name and type, then each child zone (`C_Map.GetMapChildrenInfo(mapID, 3)`, P5) with its ID, name and client level range (`C_Map.GetMapLevels`, P6; four zeros mean no data), then a ready-made `Zones.lua` row per child, for example `[1440] = { min = 20, max = 30, faction = "", kind = "zone" },  -- forever, 2026-10-17`.
- Which map: the shown map (`WorldMapFrame:GetMapID()`, P7) when the map is open, otherwise the player's map (`C_Map.GetBestMapForUnit("player")`, P2). To decide when 2.6c is detailed.
- The row text is a pure function in `Logic.lua` with tests.
- The comparison with `Zones.lua` (mismatch and missing-row flags) comes in M3.
- In-game check: P30, which also starts the data probe P10 (dump on each continent map).

## 2.6d: `/ls probe` (outline)

- Runs the design probes that work from code (P1-P6 and P8) and emits one pass, fail or value line per probe; `/ls probe hover` reports the zone under the cursor (P7), meant for a key-bound macro.
- Uses only APIs those probes already confirmed.
- In-game check: P31, on the beta if time allows, otherwise on the live client after Nov 4.

## Done when (each checkpoint)

- `scripts/check.ps1` passes (luacheck + tests).
- The in-game check behaves as described; Claude records it in `notes/beta-probes.md`.
- The temporary test code is removed, then the code and the notes are committed separately.
