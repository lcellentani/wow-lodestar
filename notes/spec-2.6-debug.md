# M2 step 2.6: `Debug.lua` (log, copy window, dump, probe)

Status: spec agreed 2026-10-17; 2.6a done (P27, 2026-10-18); 2.6b done (P28-P29, 2026-10-18); 2.6c done (P30, 2026-10-18); 2.6d outlined (detailed before it starts). User writes the code, Claude reviews.
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

## 2.6b: copy window, `/ls copy`

`/ls copy` opens `LodestarCopyFrame` with the last output, all selected, so Ctrl+C copies it. The window is created on first use, then reused; it can be dragged and closed with Escape or its close button.

### Evidence

Every API below is confirmed. P16g: `CreateFrame` for `"Frame"`, `"ScrollFrame"` and `"EditBox"`; the templates `BasicFrameTemplateWithInset` (`.CloseButton`) and `UIPanelScrollFrameTemplate`; `SetMultiLine`, `HighlightText`, `SetAutoFocus`; `UISpecialFrames`. P16c: `SetScript`. P28 part 1 (2026-10-18): `SetSize`, `SetPoint`, `SetMovable`, `EnableMouse`, `RegisterForDrag`, `StartMoving`, `StopMovingOrSizing`, `.TitleText`, `SetScrollChild`, `SetText`, `SetFocus`, `SetFontObject`, `SetWidth`, `ChatFontNormal`. P28 part 2 (below, done 2026-10-18): `Show`, `IsShown`, `TitleText:SetText`, and the script names `OnDragStart`, `OnDragStop`, `OnEscapePressed`.

### `Logic.FormatOutput(entry)` in `Logic.lua`

- Returns one string: a header line `"<time> /ls <command>"`, then each of `entry.lines`, joined with `"\n"`. For example `{ time = "2026-10-18 19:30:07", command = "emit", lines = { "line one", "line two" } }` gives `"2026-10-18 19:30:07 /ls emit\nline one\nline two"`.
- The header says where pasted text came from; it matters once several dumps are pasted into one note.

Tests (`describe("FormatOutput", ...)`):

- Header plus two lines, as in the example.
- An entry with no lines gives only the header (no trailing `"\n"`).
- An `error` entry gives `"<time> /ls error"` then the message (the command name is kept as is).

Hints:

- Build a list: `local parts = { header }`, append each line, then `table.concat(parts, "\n")`. Same pattern as `ns.Print`.
- Never change `entry.lines`: `Record` keeps that same table as the last output and in the log.

### The window in `Debug.lua`

- A file-level `local copyFrame = nil` and a `local function CreateCopyFrame()` that builds and returns the frame. `/ls copy` calls it only when `copyFrame` is `nil`.
- The frame: `CreateFrame("Frame", "LodestarCopyFrame", UIParent, "BasicFrameTemplateWithInset")`, size about 520 by 360, centered (`SetPoint("CENTER")`), title `"Lodestar: last output"` through `TitleText:SetText`. The global name is what lets Escape find it: `table.insert(UISpecialFrames, "LodestarCopyFrame")`, once, at creation.
- Dragging: `SetMovable(true)`, `EnableMouse(true)`, `RegisterForDrag("LeftButton")`, and `OnDragStart` / `OnDragStop` scripts that call `self:StartMoving()` / `self:StopMovingOrSizing()`.
- Inside: a `"ScrollFrame"` with `UIPanelScrollFrameTemplate`, anchored to the frame's top-left and bottom-right with offsets that leave room for the title bar and, on the right, for the scroll bar (about `12, -30` and `-32, 10`). Its scroll child is an `"EditBox"` with `SetMultiLine(true)`, `SetAutoFocus(false)`, `SetFontObject(ChatFontNormal)` and `SetWidth` equal to the scroll frame's width (520 - 12 - 32 = 476).
- `OnEscapePressed` on the edit box hides the frame. While the edit box has keyboard focus it receives Escape itself, so `UISpecialFrames` alone would not close the window then.
- `/ls copy`, usage `"copy - show the last output, selected for Ctrl+C"`:
  - No last output yet (`ns.GetLastOutput()` is `nil`): print `nothing to copy yet` and stop; no frame is created.
  - Otherwise create the frame if needed, `Show()` it, `SetText(ns.Logic.FormatOutput(entry))` on the edit box, then `HighlightText()` and `SetFocus()`.
  - When the window is already open, `/ls copy` refreshes it with the current last output (no toggle): the command always shows the latest.
- `/ls copy` does not record anything itself, so it never replaces the last output it shows.

Hints:

- Keep the edit box in a file-level local too (or as a field, `copyFrame.editBox = editBox`), since `/ls copy` needs it after creation.
- `SetScript` on our own frames is fine (CLAUDE.md, no-taint rule); `table.insert` into `UISpecialFrames` is the standard way to register a window for Escape and does not replace anything of Blizzard's.
- Script handlers get the frame as their first argument: `function(self) self:StartMoving() end`.
- `HighlightText()` with no arguments selects all the text.
- Claude adds `ChatFontNormal` to `read_globals` in `.luacheckrc` (done with this spec).

### Temporary in-game test (remove before commit)

A temporary `emit` command that emits 40 numbered lines (`"line 1"` ... `"line 40"`), enough to need the scroll bar.

### P28 part 2 (done 2026-10-18)

Three lines, each under 255 characters. Each should print its label, and `Frame3` three `true`s; a missing line means the call failed:

```
/run local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset"); f:Hide(); print("Frame3", f.Show ~= nil, f.IsShown ~= nil, f.TitleText.SetText ~= nil)
```

```
/run local f = CreateFrame("Frame", nil, UIParent); f:SetScript("OnDragStart", function() end); f:SetScript("OnDragStop", function() end); print("DragScripts ok")
```

```
/run local e = CreateFrame("EditBox", nil, UIParent); e:Hide(); e:SetScript("OnEscapePressed", function() end); print("EscapeScript ok")
```

### In-game check (P29)

```
/reload
```

```
/ls copy
```

Expected: `nothing to copy yet`, no window.

```
/ls emit
```

```
/ls copy
```

Expected: the window opens in the middle of the screen with the header line and `line 1` to `line 40`, all selected; the scroll bar reaches `line 40`. Then:

1. Press Ctrl+C, close the window, paste into the Claude Code prompt: the header and 40 lines arrive.
2. Drag the window by its title bar; it moves.
3. Press Escape with the cursor in the text: the window closes.
4. `/ls copy` again: it opens where it was dragged to. Click the title bar (the text loses focus), press Escape: it closes.
5. `/ls copy`, then the close button: it closes.

6. Refresh: `/ls copy`, click the title bar (so Enter opens the chat box instead of typing into the window), wait a second, then run the two commands below. The window stays open and shows the new output (a later time in the header).

```
/ls emit
```

```
/ls copy
```

### P28 part 1 (done 2026-10-18)

```
/run local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset"); f:Hide(); print("Frame1", f.SetSize ~= nil, f.SetPoint ~= nil, f.SetMovable ~= nil, f.EnableMouse ~= nil)
```

```
/run local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset"); f:Hide(); print("Frame2", f.RegisterForDrag ~= nil, f.StartMoving ~= nil, f.StopMovingOrSizing ~= nil, f.TitleText ~= nil)
```

(The frame check is split in two: the chat box cuts typed lines at 255 characters, and the single 284-character line failed silently on 2026-10-18.)

```
/run local s = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate"); s:Hide(); print("Scroll", s.SetScrollChild ~= nil, s.SetPoint ~= nil)
```

```
/run local e = CreateFrame("EditBox", nil, UIParent); e:Hide(); print("EditBox", e.SetText ~= nil, e.SetFocus ~= nil, e.SetFontObject ~= nil, e.SetWidth ~= nil, ChatFontNormal ~= nil)
```

Result: every value `true` (see `notes/beta-probes.md`, P28).

## 2.6c: `/ls dump`

`/ls dump` reports one map: its ID, name and type, its child zones with the client's level range, and a ready-made `Zones.lua` row per zone. It is how `Data/Zones.lua` gets seeded and checked (doc: "`/ls dump` is the most important command early on"). The comparison with `Zones.lua` (mismatch and missing-row flags) comes in M3, once that table exists.

### Decisions

- **Which map** (decided 2026-10-18): the map shown in the world map when it is open, otherwise the player's map. With the map open, any continent or zone can be dumped from anywhere by browsing to it; no travel. With the map closed it is a quick "where am I" dump.
- **A zone map gets its own row.** The player's map is always a zone (P2: Stormwind City is mapType 3), and so is Zephras Isle (P5: 2521, a zone under the world map, not under a continent). A zone has no child zones, so the dump adds a row for the map itself when its type is Zone; otherwise those dumps would give no row at all.
- **Rows without a client range leave `min` and `max` out.** On the beta `GetMapLevels` returns four zeros (P6). A row without `min`/`max` is still valid Lua and, by the doc's lookup rule, just shows no label until the range is filled in; `min = 0` would look like data.
- **The row comment carries the zone name**: `-- <name>, forever, <date>`. The doc's tag rule (`-- forever, YYYY-MM-DD`: recorded in game) is kept; the name makes a pasted block readable, since `Zones.lua` rows are keyed by number.

### Evidence

All confirmed: `WorldMapFrame:GetMapID` (P7), `IsShown` on a frame (P28), `C_Map.GetBestMapForUnit("player")` and `C_Map.GetMapInfo` (P2, fields `mapID`, `name`, `mapType`, `parentMapID`), `Enum.UIMapType` (P2), `C_Map.GetMapChildrenInfo(mapID, mapType)` (P5, a list of the same info tables), `C_Map.GetMapLevels` (P6, four return values: player min, player max, pet min, pet max), `date` (P16b).

### `Logic.FormatZoneRow(mapID, name, minLevel, maxLevel, today)` in `Logic.lua`

- With a client range (`minLevel` above 0): `[1440] = { min = 20, max = 30, faction = "", kind = "zone" },  -- Ashenvale, forever, 2026-10-18`.
- Without one (`minLevel` is 0 or `nil`): `[1440] = { faction = "", kind = "zone" },  -- Ashenvale, forever, 2026-10-18`.
- Two spaces before `--`, as in the doc's examples.

Tests (`describe("FormatZoneRow", ...)`):

- A range gives the row with `min` and `max`.
- Zero levels give the row without them.
- `nil` levels give the row without them.

Hints:

- `string.format` builds this in one call: `%d` for numbers, `%s` for strings. `string.format("[%d] = { ... },  -- %s, forever, %s", mapID, name, today)`.
- `minLevel ~= nil and minLevel > 0` guards against `nil`: comparing `nil > 0` is an error in Lua.

### `Logic.FindKey(t, value)` in `Logic.lua`

- Returns the first key of `t` whose value equals `value`, or `nil`. The dump uses it to print the type name: `Logic.FindKey(Enum.UIMapType, 2)` is `"Continent"`.
- `Enum.UIMapType` is passed in, so the function stays free of WoW globals and the tests pass their own table, for example `{ Zone = 3, Continent = 2 }`.

Tests: a value present gives its key; a value missing gives `nil`.

Hint: `for key, v in pairs(t) do ... end`. `pairs` visits in no fixed order, which is fine here since the enum's values are unique.

### The command in `Debug.lua`

Usage `"dump - list the shown (or current) map's zones with ready-made Zones.lua rows."`.

1. Pick the map: `WorldMapFrame:IsShown()` gives `WorldMapFrame:GetMapID()`, otherwise `C_Map.GetBestMapForUnit("player")`. Remember which (`"shown map"` or `"player's map"`) for the header.
2. If there is no map ID, or `C_Map.GetMapInfo(mapID)` returns `nil`: print `no map to dump` and stop (it can happen in some instances or during loading screens).
3. Build `lines` (a new table on each call):
   - `map 1415 Eastern Kingdoms, Continent (shown map)`: ID, name, type name through `ns.Logic.FindKey(Enum.UIMapType, info.mapType)`, source.
   - `zones: 26`, then one line per child zone: `1429 Elwynn Forest, client levels: none`, or `client levels: 20-30` when the first value is above 0.
   - `rows:`, then one `FormatZoneRow` line per child zone, and also one for the map itself when `info.mapType == Enum.UIMapType.Zone`.
4. `ns.Emit("dump", lines)`.

Hints:

- `C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}`: if the client returns `nil` for a map with no children, the loop still works.
- Sort the children by ID before printing (`table.sort(children, function(a, b) return a.mapID < b.mapID end)`), so two dumps of the same map compare line by line.
- `local minLevel, maxLevel = C_Map.GetMapLevels(child.mapID)` keeps only the first two of the four values.
- `date("%Y-%m-%d")` once per dump, passed to every row as `today`.
- A continent prints about 55 lines into chat. That is expected: the copy window and the log are the places to read it.

### In-game check (P30, also data probe P10)

No temporary code. In Stormwind, with the world map closed:

```
/ls dump
```

Expected: `map 1453 Stormwind City, Zone (player's map)`, `zones: 0`, and one row for Stormwind City.

Open the world map, go up to Eastern Kingdoms, then type in chat with the map still open:

```
/ls dump
```

Expected: `map 1415 Eastern Kingdoms, Continent (shown map)`, 26 zones (P5 lists them), 26 rows. If chat cannot be typed into while the map is open, tell Claude; the fallback is a macro with `/ls dump` on a key.

Then the same on Kalimdor, and on Zephras Isle (reached through the breadcrumb dropdown next to the continent name, P5):

```
/ls dump
```

```
/ls dump
```

Expected: Kalimdor (1414) with its zones; Zephras Isle (2521, Zone) with `zones: 0` and one row for itself.

```
/ls copy
```

Expected: the Zephras Isle dump in the copy window.

```
/reload
```

Then tell Claude: the log holds the four dumps, which Claude copies into `notes/beta-probes.md` (P30 and P10).

## 2.6d: `/ls probe` (outline)

- Runs the design probes that work from code (P1-P6 and P8) and emits one pass, fail or value line per probe; `/ls probe hover` reports the zone under the cursor (P7), meant for a key-bound macro.
- Uses only APIs those probes already confirmed.
- In-game check: P31, on the beta if time allows, otherwise on the live client after Nov 4.

## Done when (each checkpoint)

- `scripts/check.ps1` passes (luacheck + tests).
- The in-game check behaves as described; Claude records it in `notes/beta-probes.md`.
- The temporary test code is removed, then the code and the notes are committed separately.
