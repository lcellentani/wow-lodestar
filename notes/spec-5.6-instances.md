# M5 step 5.6: instance markers

Status: spec written 2026-11-15; its three open decisions (one marker per entrance, the icon of a mixed entrance, `/ls reveal`) confirmed by the user the same day. P59 passed the same day (`notes/beta-probes.md`); it found city maps have no fog of war, so city entrances got their own rule (below). Built 2026-11-21/22; P60 checks 1-8 passed on 2026-11-22 after two fixes (no `OnEnter`/`OnLeave` in the template; a map-name title in the tooltip) and one change (28 px markers on the maximized map). Pending in play: check 9 and the negative city case (`notes/todo-p60-pending-checks.md`). The `Logic` functions and the pin mixin by the user; `Pins.xml`, the module, `/ls reveal`, `.toc`, `.luacheckrc` and the design doc by Claude. Probe numbers reserved: **P59** (API checks, before any code) and **P60** (the markers in game).
Design doc reference: "Discovery" (Feature set), "Instances" (Data model and Module specs), "Difficulty colors" (each end colored on its own), "How map overlays draw", "No taint".

## What this step is for

Success criterion 3: every discovered entrance in `Data/Instances.lua` shows a marker on its zone map and on its continent map; hovering it shows name, kind and level range. With the debug switch on, every entrance shows. This is a fact the character has earned by exploring, like a flight path: no marker for an entrance whose area is still under the fog of war.

## Decisions

- **Which entrances** (design doc, "Discovery"): an entrance's marker shows once the game's fog of war has lifted at its position: `C_MapExplorationInfo.GetExploredAreaIDsAtPosition(entry.map, CreateVector2D(entry.x, entry.y))` returns at least one area ID (P44). Lodestar keeps no record of its own. Rows without `x`/`y` (the Forever dungeons not found yet) get no marker.
- **Entrances on a city map** (decided 2026-11-15 after P59: city maps have no fog of war, so the rule above never reveals them): the marker shows once the zone around the city has been entered, the same test as the doc's "Entered a zone" row: `C_MapExplorationInfo.GetExploredMapTextures(zone)` returns at least one piece (P44), where `zone` is the city row's `zone` in `Data/Zones.lua`. Four entrances: Ragefire Chasm (Orgrimmar, Durotar), The Stockade (Stormwind, Elwynn Forest), Hall of Thanes (Ironforge, Dun Morogh), Ruins of Lordaeron (Undercity, Tirisfal Glades).
- **Which maps:** zone maps show their own entrances at the stored position; continent maps show every entrance whose zone is on them, projected with `ns.GetZoneRect` and `Logic.ProjectToParent` (both exist since M4). Same marker on the small and the maximized map. Nothing on the world map, in dungeons or on any other map type.
- **One marker per entrance** (confirmed 2026-11-15). Rows that share a position (Blackrock Mountain: 5 instances; Scarlet Monastery: 4; Dire Maul's wings) become one marker, and its tooltip lists them all, one line each. The design doc's other idea, offsetting markers slightly, puts five icons on one spot of Blackrock Mountain and makes them hard to hover; one marker reads as "one door, several instances", which is how the game works.
- **Icon:** the game's `Dungeon` and `Raid` atlases (P41), 20 x 20 on the small map and 28 x 28 on the maximized one (decided 2026-11-22 in P60 check 6: 20 was hard to spot next to the large threat pins, whose disc is 30), scaling like the other pins (`SetScalingLimits(1, 1.0, 1.2)`). **A mixed entrance shows the dungeon icon** (confirmed 2026-11-15): the raid icon only when every instance behind the door is a raid (Molten Core and Blackwing Lair share Blackrock Mountain with three dungeons, so it shows the dungeon icon; Zul'Gurub, Onyxia's Lair show the raid icon).
- **Tooltip:** `GameTooltip` (P17), anchored to the marker. A title line with the name of the entrance's map (`C_Map.GetMapInfo(group.map).name`, P2: "Burning Steppes", "Stormwind City"), decided 2026-11-22 in P60 check 3: `GameTooltip` draws its first line in a larger title font, so without a title the first instance stood out. Then one line per instance: the name on the left in white; on the right the range with each end colored for the player's level (`Logic.FormatLevelRange` with `ns.LevelColorCode`, already used by `/ls probe hover`), then the kind, `Dungeon` or `Raid`. A row without levels shows the kind alone. Colors are computed on hover, so a level-up needs no refresh.
- **Mouse:** the marker reacts to the mouse moving over it but **not to clicks**, so a click on a marker still reaches the map underneath (left click opens the zone, right click zooms out). `SetMouseMotionEnabled(true)` and `SetMouseClickEnabled(false)`, if P59 shows both exist and run in combat without a blocked action. The empty `CheckMouseButtonPassthrough` stays (P14: `SetPassThroughButtons` is blocked in combat).
- **Debug switch: `/ls reveal`** (name confirmed 2026-11-15) toggles showing every entrance regardless of the fog of war. Session only (off after `/reload`), prints `reveal on` / `reveal off`, and redraws the markers if the map is open. The Tooltip step will use the same switch for its instance list. `/ls debug` stays what it is (verbose logging).
- **Refresh:** when the map opens or changes (the data provider), on `/ls reveal`, and on `/ls toggle Instances`. On map size changes too since P60 check 6 (the size differs; `EventRegistry` callbacks as in ZoneLabels, P42). Not on level-up (colors are read on hover). An entrance discovered while the map is open appears at the next map change; exploring with the map open is rare.

## P59: API checks (before any code)

Out of combat unless the step says otherwise. Each line alone; `/reload` clears what they draw.

1. Tooltip and mouse methods. Expect six `true`:

```
/run local f=CreateFrame("Frame") print(GameTooltip.SetOwner~=nil,GameTooltip.AddLine~=nil,GameTooltip.AddDoubleLine~=nil,GameTooltip.Hide~=nil,f.SetMouseMotionEnabled~=nil,f.SetMouseClickEnabled~=nil)
```

2. How the two atlases look at marker size: a dungeon icon left and a raid icon right, below the screen center. Screenshot, please.

```
/run for i,a in ipairs({"Dungeon","Raid"}) do local t=UIParent:CreateTexture(nil,"OVERLAY") t:SetAtlas(a) t:SetSize(20,20) t:SetPoint("CENTER",(i-1.5)*40,-60) end
```

3. **In combat** (fight a mob, run it mid-fight). Expect `combat true` and no "blocked" message; then hover the spot just above the screen center: chat prints `enter`.

```
/run local f=CreateFrame("Frame",nil,UIParent) f:SetSize(40,40) f:SetPoint("CENTER",0,60) f:SetMouseMotionEnabled(true) f:SetMouseClickEnabled(false) f:SetScript("OnEnter",function() print("enter") end) print("combat",InCombatLockdown())
```

4. Stormwind City's map: its type (Zone is 3) and its rectangle on Eastern Kingdoms. The Stockade is stored on the city map (1453), so it can only reach the continent if this rectangle is not four zeros.

```
/dump C_Map.GetMapInfo(1453).mapType, C_Map.GetMapRectOnMap(1453, 1415)
```

5. Fog of war in a city, at the Stockade's door. Run it with a character that has been in Stormwind (anywhere). An empty result there would mean cities have no fog of war; the Stockade would then need its own rule.

```
/dump C_MapExplorationInfo.GetExploredAreaIDsAtPosition(1453, CreateVector2D(0.534, 0.709))
```

6. An approximate vanilla entrance: Gnomeregan in Dun Morogh, with the level 19 character (who has been in Dun Morogh). P44 warned that an approximate point near an area's edge may read as unexplored.

```
/dump C_MapExplorationInfo.GetExploredAreaIDsAtPosition(1426, CreateVector2D(0.243, 0.398))
```

Claude records P59 and adjusts the spec if anything fails before you start.

## Logic.lua (yours, unit tested)

### `Logic.GroupByPosition(entries)`

Takes a list of instance rows and returns a list of groups, one per distinct `map, x, y`, each `{ map = ..., x = ..., y = ..., entries = { row, row, ... } }`.

- Groups come out in the order their first row appears in `entries`; rows inside a group keep their order too (the tooltip lists them in data order).
- Rows without `x` or `y` are skipped.
- Same position means the same three values exactly: rows behind one door share the same numbers in `Data/Instances.lua`.
- Hint: a lookup table keyed by a string built from the three values (`map .. ":" .. x .. ":" .. y`) finds an existing group; a second, plain list keeps the order. Lua tables keyed by string do not keep insertion order.
- Tests in `tests/logic_spec.lua`: an empty list gives an empty list; two rows at one position give one group with both rows in order; two positions give two groups in first-seen order; same `x, y` on two different maps give two groups; a row without `x` is skipped; the input table is not changed.

### `Logic.GroupKind(entries)`

Returns `"raid"` when every row in `entries` has `kind == "raid"`, otherwise `"dungeon"` (an empty list returns `"dungeon"`).

- Tests: all raids; all dungeons; mixed (the Blackrock Mountain case); one raid alone; empty.

### `Logic.FormatInstanceDetail(min, max, kind, codeFor)`

The right-hand side of a tooltip line: the colored range from `Logic.FormatLevelRange(min, max, codeFor)`, a space, then `"Dungeon"` or `"Raid"`. When `FormatLevelRange` returns `nil` (no levels), the kind alone.

- Tests with the fake `codeFor` the `FormatLevelRange` tests already use: a range and a dungeon; a single level and a raid (`60 Raid` with its color code); no levels gives `"Dungeon"`.

## The pin mixin (yours): `LodestarInstancePinMixin` in `Pins.lua`

Based on `MapCanvasPinMixin` like the threat pin; the template (Claude) calls `OnLoad` once when the pin is created. The map itself calls `OnMouseEnter` / `OnMouseLeave`: for a pin with mouse motion on, `AcquirePin` sets its own `OnEnter` / `OnLeave` scripts, and fails an assertion if the template already has them (P60 check 1, 2026-11-22).

- **`OnLoad()`**: motion on, clicks off (see "Mouse"). Runs once per pin, never per refresh.
- **`OnAcquired(group, x, y)`**: keep `group` on the pin (`self.group`) for the tooltip; set `self.Icon`'s atlas from `Logic.GroupKind(group.entries)` (`"Raid"` or `"Dungeon"`); `SetPosition(x, y)` (x, y are already projected by the module, so they are not always `group.x, group.y`); `SetScalingLimits(1, 1.0, 1.2)`.
- **`OnMouseEnter()`**: `GameTooltip:SetOwner(self, "ANCHOR_RIGHT")`, then the title (`AddLine` with the map's name), then one `AddDoubleLine` per row of `self.group.entries`: the name, and `Logic.FormatInstanceDetail(row.min, row.max, row.kind, ns.LevelColorCode)`; the left text white (`1, 1, 1` as the left color), the right side carries its own color codes. Then `GameTooltip:Show()`.
- **`OnMouseLeave()`**: `GameTooltip:Hide()`.
- **`CheckMouseButtonPassthrough()`**: empty, as on the threat pin, with the same comment.

Hint: `AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb)` takes the colors after the two texts; pass white for both sides, the color codes inside the right text win.

## The WoW side (Claude)

- **`Pins.xml`**: `LodestarInstancePinTemplate`, mixin `LodestarInstancePinMixin`, virtual, 20 x 20, one `ARTWORK` texture `Icon` filling it; `<Scripts>` with `OnLoad` only (no `OnEnter` / `OnLeave`, see the pin mixin). No `enableMouse` attribute: `OnLoad` sets the mouse.
- **`Modules/Instances.lua`**: the data provider. `RefreshAllData` removes its pins, reads the map type, and on a zone map takes the rows with `map` equal to it; on a continent map, every row whose zone has a rectangle on it (`ns.GetZoneRect`). It keeps only discovered rows (or all with reveal on), groups them with `Logic.GroupByPosition`, projects each group on a continent, and acquires one pin per group. The discovery check treats both `nil` and an empty table as "not explored" (P44 and P59 showed an empty result, not which of the two it is); for a row on a city map (`ns.Zones[row.map].kind == "city"`) it asks `GetExploredMapTextures` of the city's `zone` instead. `/ls reveal` lives here (`ns.RegisterCommand`), its state in `ns.reveal`.
- **`.toc`**: `Modules\Instances.lua` after `Modules\ThreatOverlay.lua`.
- **`.luacheckrc`**: `LodestarInstancePinMixin` in `globals`; nothing new in `read_globals` unless P59 changes the plan (`GameTooltip`, `C_MapExplorationInfo`, `CreateVector2D` and `C_Texture` are in already; methods are not globals).
- **Design doc**: "Instances" module spec and "Discovery" updated with the confirmed decisions on 2026-11-15, with this spec; the module spec gets the built details after P60.

## Order

1. P59 (you, in game); Claude records it.
2. You: the three `Logic` functions and their tests; run `scripts/check.ps1`.
3. You: the pin mixin. Claude, at the same time: `Pins.xml`, `.toc`, `.luacheckrc`.
4. Claude: `Modules/Instances.lua` and `/ls reveal`, once the mixin is in.
5. Claude reviews your part and runs the checks; then P60.

## P60: the markers in game

`/reload` is enough (no new texture files). Other addons off.

1. **Fog of war:** with reveal off, on Eastern Kingdoms and on the zone maps you have explored, markers only on entrances in explored areas; none in black (unexplored) areas.
2. **Reveal:** `/ls reveal` prints `reveal on`; every entrance with a position shows on both continents. Blackrock Mountain and Scarlet Monastery are one marker each. `/ls reveal` again hides the unexplored ones.
3. **Tooltip:** hovering Blackrock Mountain lists its five instances in data order, names white, ranges colored per end, kind after each; Zul'Gurub shows `60 Raid`. Moving off hides it.
4. **Clicks pass through:** left click on a marker on the continent map opens the zone under it, right click on a zone map goes back up, as if the marker were not there.
5. **Zone and city maps:** the marker at the entrance's stored position; the Stockade on the Stormwind City map and on the continent (P59 step 4 gave a rectangle). With reveal off, a city's entrance shows once its zone has been entered: the Stockade for a character that has been in Elwynn Forest, none for one that has not.
6. **Look:** dungeon and raid icons readable on the parchment at both map sizes; whether markers draw above or below the threat pins, and any marker hidden under one (likely: Blackrock Mountain under the Burning Steppes or Searing Gorge pin). Screenshots of both continents with reveal on.
7. **Toggle:** `/ls toggle Instances` removes only the markers, then brings them back.
8. **Combat** (P14 repeat for M5): open the map in a fight at each size and hover a marker: no error popup, no "blocked action" message.
9. **Entrances that look wrong:** note any marker clearly off its entrance (most vanilla positions are approximate); Claude fixes them in `Data/Instances.lua` from your notes or a `/ls probe here` at the door.

Claude records P60. Commits: your code `[T2]`; Claude's XML, module, wiring and notes `[T4]`, separately.
