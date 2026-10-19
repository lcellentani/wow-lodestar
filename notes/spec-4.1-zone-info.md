# M4 step 4.1: zone info and colored level ranges

Status: spec written 2026-10-19; fallback colors probed and `DifficultyKey` change added the same day (P35). 4.1a done (`fa218ea`, 2026-10-19). User writes the code, Claude reviews.
Design doc reference: "Data model" (lookup rule, Zones "Level source"), "Feature set" (Difficulty colors), "Module specs" (ZoneLabels step 3).

## What this step is for

ZoneLabels (4.2) and the Tooltip (M5) both need two answers for a zone: "what is its level range, and where did it come from?" and "how do I show that range in color?". This step builds both answers without drawing anything on the map yet. Most of it is pure logic in `Logic.lua` with unit tests, so it can be written and checked without the game; a small WoW side connects it to the client, and `/ls probe hover` shows the result in game.

## Decisions

- **Two checkpoints.** 4.1a is pure logic and tests, no game needed. 4.1b is the WoW side and the in-game check (P35).
- **The merge returns a new table every time**, never the `Zones.lua` row or the override itself, so a caller that changes the result can never change the shipped data or the saved overrides. Fields with no source are `nil`; a zone with no data at all gives a table of `nil`s, not an error.
- **Logic builds the colored text but does not choose colors.** `Logic.FormatLevelRange` takes a function that gives the color code for a level. The game passes one based on `GetQuestDifficultyColor`; the tests pass a fake. This keeps the client call out of `Logic.lua`, and the tests stay readable.
- **Colors come from the client** (`GetQuestDifficultyColor`, P8). The `Logic.DifficultyKey` fallback is used only when that function is missing, which on the beta it is not. Its color values are probed in 4.1b, so they rest on evidence too.
- **The in-game check uses `/ls probe hover`**: it gains the zone's colored range and its source. That is useful afterwards too, when checking data in M3.
- **Commits**: your code as `[T2] feat(...)`, Claude's notes as a separate `[T4] docs(notes): ...`.

## 4.1a: pure logic in `Logic.lua`

### Change: `Logic.DifficultyKey` uses Forever's yellow band

P35 showed that Forever's client keeps yellow down to 4 levels below the player, not 2 as in Classic: at level 18, levels 14-18 are yellow, 13 green, 12 and below grey. The design doc's fallback table now says `diff >= -4` for yellow.

- In `DifficultyKey`, the yellow check becomes `diff >= -4`.
- Tests: "is yellow from 2 below to 2 levels above" becomes "from 4 below" (add level 21 at player 25); "is green from 6 below to 3 levels below" becomes "6 below to 5 below" (levels 19 and 20 at player 25; 22 is now yellow).
- Add a test with P35's own numbers at player level 18: 14 yellow, 13 green, 12 grey. It pins the rule to what the client showed.

### `Logic.MergeZoneInfo(row, override, clientMin, clientMax)`

Arguments, each possibly `nil`:

- `row`: the zone's `Data/Zones.lua` row, e.g. `{ min = 1, max = 14, faction = "Alliance", kind = "zone" }`.
- `override`: the user's saved override from `ns.db.overrides.zones[mapID]`, e.g. `{ min = 5, max = 10 }`.
- `clientMin`, `clientMax`: the first two values of `C_Map.GetMapLevels(mapID)` (zeros on the beta, P6).

Returns a new table with the fields `min`, `max`, `source`, `faction`, `kind`, `labelX`, `labelY`. All but `source` are copied from the inputs; `source` is not in any input: the function writes it, as the string `"override"`, `"client"` or `"table"`, to record which input the range came from (the doc's lookup rule):

- **Range**, from the first source that has one:
  1. `override`, if it has both `min` and `max`: `source = "override"`.
  2. the client, if `clientMin` is not `nil` and above 0, and `clientMax` is not `nil`: `source = "client"`.
  3. `row`, if it has `min`: `source = "table"`.
  4. none: `min`, `max` and `source` stay `nil`.
- **`faction`, `kind`, `labelX`, `labelY`**: each from `override` if it has that field, otherwise from `row`, otherwise `nil`. (`/ls zone` only saves ranges, but the doc's lookup rule lets an override carry any field.)

Tests (`describe("MergeZoneInfo", ...)`):

- Table only (the beta case): Elwynn's row with client `0, 0` gives `1, 14`, source `"table"`, faction `"Alliance"`, kind `"zone"`.
- Client `nil, nil` behaves like client `0, 0`.
- The client wins over the table: same row, client `2, 12` gives `2, 12`, `"client"`.
- An override wins over both: override `{ min = 5, max = 10 }` with client `2, 12` gives `5, 10`, `"override"`.
- An override with only `min` is ignored for the range: falls through to the client or the table.
- An override's `faction` wins over the row's; the row's `kind` is kept.
- A city (`{ faction = "Horde", kind = "city" }`, no client range) gives `min`, `max` and `source` `nil`, faction and kind kept.
- No data at all (`nil, nil, nil, nil`) gives a table whose fields are all `nil`, without an error.
- The result is a new table: `result ~= row`, and setting `result.min = 99` leaves `row.min` unchanged.

Hints:

- Build `local info = {}` and fill it field by field; never `return row`.
- `override and override.min` is `nil` when `override` is `nil`, so one `if` per source covers the missing tables.
- For the four plain fields, a small loop over `{ "faction", "kind", "labelX", "labelY" }` avoids four nearly identical `if`s. Mind the `false` trap: `a and a.x or b.x` does the wrong thing if `a.x` is `false`; these fields are never `false`, so `or` is fine here.

### `Logic.ColorCode(r, g, b)`

- Returns the WoW color escape `"|cffRRGGBB"` for color parts between 0 and 1, each turned into two lowercase hex digits.
- Tests (`describe("ColorCode", ...)`): white `1, 1, 1` gives `"|cffffffff"`; black `0, 0, 0` gives `"|cff000000"`; P8's orange `1, 0.5, 0.25` gives `"|cffff8040"` (0.5 rounds to 128, `80`; 0.25 to 64, `40`).
- Hint: `string.format("%02x", n)` writes a whole number as two hex digits; `math.floor(v * 255 + 0.5)` rounds to the nearest whole number. In chat code the `|` is a plain character in a Lua string; only `/run` lines typed into chat need `\124`.

### `Logic.FormatLevelRange(min, max, codeFor)`

What it is for: it builds the text a zone label shows, a range like `15-25` with each number in its own difficulty color and the dash left white. WoW colors text with escapes inside the string: `|cffRRGGBB` starts a color, `|r` ends it. For a level 21 character and a 15-25 zone, the label needs `|cff40bf4015|r-|cffff804025|r` (green 15, orange 25). Choosing a color needs the client (`GetQuestDifficultyColor`), which `Logic.lua` may not call, so the caller passes `codeFor`, a function that returns the code for a level; this function only puts the pieces in order. In game the caller passes `ns.LevelColorCode` (4.1b); the tests pass a fake that returns readable markers.

- `codeFor` is a function: `codeFor(level)` returns a color code such as `"|cffff8040"`.
- `min == nil`: returns `nil` (no label).
- `min == max`: one colored number, `codeFor(min) .. min .. "|r"`.
- Otherwise: each end colored on its own, the dash neutral: `codeFor(min) .. min .. "|r-" .. codeFor(max) .. max .. "|r"`.
- Tests (`describe("FormatLevelRange", ...)`), with a fake `local function fakeCode(level) return "<" .. level .. ">" end`:
  - `15, 25` gives `"<15>15|r-<25>25|r"`.
  - `60, 60` gives `"<60>60|r"`.
  - `nil, nil` gives `nil`.
- Hint: a function is a value in Lua, like any other: pass `fakeCode` (no parentheses) and call it inside as `codeFor(min)`. This is the same idea as a function pointer or a lambda in C++.

## 4.1b: WoW side and in-game check

### Fallback colors (probed, P35)

The client's first color for each key, from P35 and P8:

| Key | `r, g, b` |
| --- | --- |
| red | 1, 0.1, 0.1 |
| orange | 1, 0.5, 0.25 |
| yellow | 1, 0.82, 0 |
| green | 0.25, 0.75, 0.25 |
| grey | 0.5, 0.5, 0.5 |

### `ns.LevelColorCode(level)` in `Util.lua`

- If `GetQuestDifficultyColor` exists: `local color = GetQuestDifficultyColor(level)` (the first return value is the color, P8) and return `ns.Logic.ColorCode(color.r, color.g, color.b)`.
- Otherwise: `local key = ns.Logic.DifficultyKey(level, UnitLevel("player"))` and return the code for `FALLBACK_COLORS[key]`, a file-level table with the five colors above.
- Hint: write `FALLBACK_COLORS` as `{ red = { r = ..., g = ..., b = ... }, ... }` so both branches end in the same `ColorCode(c.r, c.g, c.b)` call.

### `ns.GetZoneInfo(mapID)` in `Core.lua`

- `row = ns.Zones[mapID]`, `override = ns.db.overrides.zones[mapID]`.
- `clientMin, clientMax = C_Map.GetMapLevels(mapID)`, only if `C_Map.GetMapLevels` exists; otherwise leave both `nil`.
- Returns `ns.Logic.MergeZoneInfo(row, override, clientMin, clientMax)`.
- Hint: `Data\Zones.lua` loads after `Core.lua`, so `ns.Zones` does not exist yet while `Core.lua` itself runs. That is fine: `ns.GetZoneInfo` reads it only when called, long after every file has loaded. Do not copy `ns.Zones` into a local at the top of `Core.lua`.

### `/ls probe hover` shows the range

When the cursor is over a zone, add its range and source to the detail:

```
P7 info: cursor 48.1, 70.2 on 1415: 1429 Elwynn Forest, 1-14 (table)
```

- `local info = ns.GetZoneInfo(mapInfo.mapID)`, then `ns.Logic.FormatLevelRange(info.min, info.max, ns.LevelColorCode)`; when it returns `nil`, write `no level data`; the source in parentheses only when there is one.
- The numbers show in color in chat. The log and the copy window keep the raw `|cff...` codes; that is expected and harmless.

### In-game check (P35)

No temporary code.

```
/reload
```

Open the world map on Eastern Kingdoms, type `/ls probe hover`, move the cursor onto Elwynn Forest and press Enter. Expected: `..., 1429 Elwynn Forest, 1-14 (table)`, both numbers colored for your level (at level 20: `1` grey, `14` green).

Then the same over Stormwind City (a city has no range). Expected: `..., 1453 Stormwind City, no level data`.

Then over a high zone, such as Burning Steppes. Expected: `48-60 (table)`, both red.

Then `/reload`, and Claude reads the log and records P35.

## Done when (each checkpoint)

- `scripts/check.ps1` passes (luacheck + tests).
- 4.1b: the in-game check behaves as described; Claude records it in `notes/beta-probes.md`.
- The code and the notes are committed separately.
