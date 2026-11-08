# M5 step 5.3: the placement tool

Status: spec written 2026-11-07. Probe numbers reserved: P52 (combat API), P53 (the tool in game).
Design doc reference: "Label anchors" (ZoneLabels), "ThreatOverlay" (Position), "Architecture" (one namespace, no taint, `SetScript` only on our own frames).

## What this step is for

Every zone gets a hand-set point, shared by its range label and its threat marker (decided 2026-11-07): no automatic point fits every zone. This step builds a small in-game tool to set those points by clicking on the map, seeing each point at once, and correcting it until it looks right. It is a developer tool, like `/ls probe`, not a feature for play.

## Decisions

- **`/ls place` turns the tool on and off.** While it is on, a transparent layer covers the continent map: faint grid lines, a dot for every zone that already has a point, and clicks go to the tool instead of the map.
- **The click is the point.** Left click stores the exact cursor position for the zone under the cursor; the grid is only a visual aid and nothing snaps to it. Right click removes the point of the zone under the cursor. Clicking again on the same zone moves its point.
- **Points live in `LodestarDB.overrides.zones[zoneID].labelX/labelY`.** `ns.GetZoneInfo` already reads them, so ZoneLabels uses a new point at its next refresh with no other change. When a continent is done, Claude reads the SavedVariables file and copies the points into `Data/Zones.lua`; then `/ls place clear` removes them from the overrides.
- **Continent maps only.** `labelX, labelY` are positions on the continent map. On any other map the layer hides and clicks do nothing.
- **Cities are refused.** A click whose zone is a city (`kind == "city"` in `ns.Zones`, such as Stormwind City in Elwynn Forest) prints a hint and stores nothing: a city counts as the zone around it, so click a spot of that zone outside the city's hover area.
- **Never in combat.** A mouse-enabled frame on the map is where the P14 taint came from. The tool refuses to turn on in combat, turns itself off when combat starts, and turns off when the map closes. P52 confirms the two APIs this needs.
- **Pure parts go in `Logic.lua` with tests**: the grid line positions and the changes to the overrides table. The WoW side only draws and listens.

## P52: combat API (probe, before writing code)

```
/dump InCombatLockdown ~= nil, InCombatLockdown()
```

Expected out of combat: `true`, `false`.

```
/run local f=CreateFrame("Frame") f:RegisterEvent("PLAYER_REGEN_DISABLED") f:RegisterEvent("PLAYER_REGEN_ENABLED") f:SetScript("OnEvent",function(_,e) print(e, InCombatLockdown()) end)
```

Then attack something weak and let the fight end. Claude records P52 and adds the names to `.luacheckrc`.

Result (2026-11-07): `PLAYER_REGEN_DISABLED` fires just **before** the lockdown, so `InCombatLockdown()` is still `false` in its handler. That is what the tool needs: turning itself off on that event is still allowed. During a fight `InCombatLockdown()` returns `true` (P52 done).

## Logic.lua (pure, unit tested)

### `Logic.GridLines(cells)`

Returns the fractions where the inner grid lines go: for `cells = 4`, `{ 0.25, 0.5, 0.75 }`. Used for both directions.

- Hint: a `for i = 1, cells - 1` loop and `i / cells`.
- Tests: 4 cells give three lines at 0.25, 0.5, 0.75; 1 cell gives an empty table; 20 cells give 19 lines, the first `0.05`, the last `0.95` (compare with a small tolerance, floating point).

### `Logic.SetPlacement(overrides, zoneID, x, y)` and `Logic.ClearPlacement(overrides, zoneID)`

`overrides` is `LodestarDB.overrides.zones`. `SetPlacement` creates `overrides[zoneID]` if missing and sets `labelX, labelY`; `ClearPlacement` sets both to `nil` and removes `overrides[zoneID]` when nothing else is left in it (an override can also hold `min`, `max`, `faction`, `kind`, which must survive).

- Hint: `next(t) == nil` tells you a table is empty.
- Tests: set on an empty table creates the row; set twice keeps the last point; clear removes a row holding only the point; clear keeps a row that also has `min, max` (only the point goes); clear of a zone with no row does nothing and does not error.

### `Logic.ClearAllPlacements(overrides)`

Calls `ClearPlacement` for every zone and returns how many points it removed, for `/ls place clear`.

- Hint: collect the IDs first, then clear them; changing a table while `pairs` walks it is unsafe in Lua.
- Tests: two zones with points and one with only `min, max` return 2 and leave the third row.

## The WoW side: `Place.lua`

A new file after `Debug.lua` in `Lodestar.toc`, starting with `local addonName, ns = ...`. No new globals.

### The layer, built once

Build it the first time the tool turns on, never again (CLAUDE.md: no frames created per refresh):

- **The frame**: `CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)`, `SetAllPoints()` on that child, `SetFrameLevel(3000)` so it sits above the map's pins (they use about 2000-2920, P3), and hidden by default.
- **Grid lines**: 20 cells, so 19 vertical and 19 horizontal textures from `Logic.GridLines(20)`, each `SetColorTexture(1, 1, 1, 0.25)` (0.12 was barely visible, 2026-11-07) and 1 pixel thick. Faint is the point: they help you judge spacing without covering the map.
- **Placing the lines**: the canvas changes size when the map is maximized, so position them in an `OnSizeChanged` script on your frame: for a vertical line at fraction `f`, `SetPoint("TOPLEFT", frame, "TOPLEFT", f * width, 0)` and `SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", f * width, 0)`, then `SetWidth(1)`; the horizontal lines the same way with the height. Call the same function once after building, since the size is already set.
- **Dots**: one texture per zone, created the first time that zone needs one and kept in a local table keyed by zone ID. Use `Media/probe-white.tga` (the soft disc from P46) at about 10 x 10, tinted with `SetVertexColor`: white for points already saved, yellow for the one you just placed. Optional: a small `FontString` with the zone name next to each dot.

### Turning on and off

- `/ls place`: if `InCombatLockdown()` is true, print "not in combat" and stop. If the map is closed, print "open the world map first", as `/ls probe hover` does. Otherwise toggle: show the frame, `EnableMouse(true)`, draw the dots; or hide it and `EnableMouse(false)`.
- `/ls place clear`: `Logic.ClearAllPlacements(ns.db.overrides.zones)`, then print the count. Confirm there is no undo in the usage text.
- Turn off automatically on `PLAYER_REGEN_DISABLED` (through `ns.RegisterEvent`, P52) and when the map closes: `WorldMapFrame:HookScript("OnHide", ...)`, never `SetScript` on a Blizzard frame.
- Register the command with `ns.RegisterCommand("place", handler, usage)`; the usage string has a literal `|`, so write `||` (the `/ls probe` help bug, 2026-11-05).

### Clicks

`frame:SetScript("OnMouseDown", function(self, button) ... end)` on your own frame:

1. Read the shown map: `WorldMapFrame:GetMapID()`; skip unless `C_Map.GetMapInfo(mapID).mapType == Enum.UIMapType.Continent`.
2. Cursor: `WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()` (P7), then `C_Map.GetMapInfoAtPosition(mapID, x, y)`; no zone means the sea: print nothing, do nothing.
3. A city (`ns.Zones[zoneID]` with `kind == "city"`): print "<name> is a city: click its zone outside the city".
4. `"LeftButton"`: `Logic.SetPlacement(ns.db.overrides.zones, zoneID, x, y)`, move or create the zone's dot, print "placed <name> at <coords>" with `ns.Logic.FormatCoords`.
5. `"RightButton"`: `Logic.ClearPlacement(...)`, hide the zone's dot, print "removed <name>".

### The map changing under the tool

Switching from Eastern Kingdoms to Kalimdor while the tool is on must redraw the dots for the new continent; switching to a zone map must hide the layer. The map tick (`ns.RegisterMapTick`, step 2.4) runs while the map is open: compare `WorldMapFrame:GetMapID()` with the last one you drew, and redraw only when it changed. Register the tick while the tool is on, unregister when it turns off.

Which dots to draw on a continent: every child zone from `C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone)` (P5) whose `ns.GetZoneInfo(id)` has `labelX` and `labelY`.

## P53: the tool in game

1. `/ls place` with the map closed prints the hint; in combat it refuses.
2. Map open on Eastern Kingdoms, small and maximized: faint grid over the whole map, lines following the map when it is maximized.
3. Left click in Wetlands: a yellow dot where you clicked, a chat line with the coordinates; click again elsewhere in Wetlands: the dot moves.
4. Right click in Wetlands: the dot goes.
5. Click on Stormwind City's area: the city hint, no dot. Click in the sea: nothing.
6. Switch to Kalimdor and back: each continent shows its own dots.
7. `/reload`: the placed points come back as white dots when the tool is turned on again, and the range labels sit at the new points.
8. Start a fight with the tool on: it turns off. Close the map with it on: it turns off.
9. `/ls place` again off: clicks reach the map again (a zone click zooms in).

Screenshots of 2, 3 and 7, and any error popup. Claude records P53 and reads the placed points from the SavedVariables file.

## After the step

The placement pass itself: every zone on both continents, small map first, since that is where the threat markers live. Claude copies the points into `Data/Zones.lua` (`[T4]` data), then `/ls place clear`. Commits for this step: your code `[T2]`, Claude's notes `[T4]`, separately.

Done 2026-11-08: 43 points placed (Shen'dralas included, though it has no range and so no label), copied into `Data/Zones.lua`, overrides cleared; labels on the maximized map sit on the points. Two name pairs touch (Duskwood and Deadwind Pass, Silverpine Forest and Alterac Mountains), left for the label style pass.
