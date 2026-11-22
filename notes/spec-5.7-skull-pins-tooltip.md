# M5 step 5.7: skull-only threat pins and the zone Tooltip

Status: Draft, written 2026-11-22. Two decisions confirmed by the user the same day: the Tooltip follows the cursor, and the work is split as in step 5.6 (below). The open questions at the end need answers before the plan. Probe numbers reserved: **P61** (API checks, before any code) and **P62** (the step in game).
Design doc reference: "Feature set" (Two map sizes, Discovery), "Difficulty colors", "Tooltip" and "ThreatOverlay" (Module specs, including the 2026-11-22 note), "Map tick" and "No taint" (Architecture).

## What this step is for

Success criterion 4 (zone tooltip) and the 2026-11-22 ThreatOverlay decision, shipped together. The threat pin keeps the answer to "can I go there?" (the fit color) and drops the numbers; hovering anywhere over a zone answers "what is it exactly?" (name, range, faction, instances). The two ship as one step because a pin without its tab and without the Tooltip shows ranges nowhere.

What should be true afterwards, in game:

1. On both continent maps and both map sizes, threat pins are a colored skull on a dark disc, no tab, no range text. Same positions, same colors, same rules for which zones get one as today.
2. Hovering any zone on a continent map, the skull included, shows `LodestarTooltip` at the cursor with the zone's name, level range, faction and (once the zone was entered) its instances. Moving to another zone changes the tooltip; leaving the zones, the map canvas, or closing the map hides it.
3. Hovering an instance marker shows only the marker's own tooltip (`GameTooltip`), never both.
4. No error and no blocked action in combat (P14/P15 style check).
5. Entrances the tabs used to cover (P60 check 6: Shadowfang Keep, Maraudon, the AQ marker, Onyxia's Lair...) are readable.

## Non-goals

- **Zone maps.** No Tooltip there: the whole map is one zone, and Blizzard's area labels already show sub-areas.
- **The world map** (both continents) gets neither pins nor Tooltip, as today.
- **Quest information** in the Tooltip: M7.
- **New art.** The skull and disc textures from step 5.5 stay; only the tab, its edge and its shadow leave.
- **Draw order changes** between instance markers and threat pins: left as is, re-checked in P62 now that the tabs are gone (open since P60).
- **Pin size changes.** Disc 22 small, 30 maximized stay; P62 looks at whether they still read well without the tab, and a change would be its own small follow-up.
- **Zone shapes.** The Tooltip follows Blizzard's hover areas (`GetMapInfoAtPosition`), which spill over sea and borders (P50). Accepted: it matches Blizzard's own hover glow.

## Decisions

### Threat pins

- **One pin, no tab** (design doc ThreatOverlay, 2026-11-22). The pin keeps its skull, disc, disc edge and disc shadow; the `Tab`, `TabEdge`, `ShadowTab` textures and the `Range` font string go. The pin is still anchored at the disc's center, so `labelX, labelY` do not move.
- **Mouse-free, as now.** The pin gets no tooltip of its own; because it ignores the mouse, `GetMapInfoAtPosition` under it still finds the zone, so hovering the skull shows the zone's Tooltip (checked in P61).
- **Still on the same zones:** neighbors only on the small map, every zone on the maximized one; recolor on `PLAYER_LEVEL_UP`. `OnAcquired` still needs `min, max` for the fit color, only no longer prints them.
- The retired textures and the `tab` / `shadowSide` slice values in `ns.ThreatPinStyle` go too, with their art files and the parts of `scripts/make_marker_art.py` that draw them.

### Tooltip: when it shows

- **Where:** continent maps (`mapType` Continent), small and maximized. Not on the world map or zone maps.
- **Which zone:** on each map tick (0.1 s), `WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()` then `C_Map.GetMapInfoAtPosition(mapID, x, y)` (P7 on the beta, used on live in P50). The Tooltip is rebuilt only when the hovered map ID changes, and once more on `PLAYER_LEVEL_UP` (colors).
- **Hidden** when: no map info under the cursor (sea, edges); the cursor is not over the map canvas (`ScrollContainer:IsMouseOver()`, to confirm in P61: the quest log beside the small map, the title bar, menus over the map); an instance marker is hovered; the map closes; the module is toggled off; the map changes.
- **Instance markers win.** The instance pin's `OnMouseEnter` / `OnMouseLeave` set a namespace flag (for example `ns.instanceHovered`) that the Tooltip tick reads; while it is set, `LodestarTooltip` hides. Simpler than asking the game which frame is under the mouse, which is not probed.
- **Hovered zone is the player's zone:** shows like any other zone (it has no threat pin, so the Tooltip is the only place its range shows on the small map).
- **Cities:** whatever `GetMapInfoAtPosition` returns over a capital is shown. If it is the city (1453 Stormwind City...), the Tooltip shows the city's name, no range line (cities have none), its faction and its entrance (the Stockade...). If it is the zone around it, the zone shows and the city's entrance is listed with the zone's instances. P61 tells which; the spec takes the matching branch.

### Tooltip: what it shows

- **Frame:** `LodestarTooltip`, `CreateFrame("GameTooltip", "LodestarTooltip", UIParent, "GameTooltipTemplate")` (P17), created once when the module loads, never per tick. `SetOwner(UIParent, "ANCHOR_CURSOR")` so it follows the mouse (confirmed 2026-11-22; to check in P61 that it moves with the cursor without our help).
- **Lines,** in this order:
  1. The zone's name (`C_Map.GetMapInfo(id).name`), in the tooltip's title font.
  2. `Levels` and the range with each end colored for the player's level (`Logic.FormatLevelRange` with `ns.LevelColorCode`, as the instance tooltip); `No level data` in grey when no source has one (Shen'dralas). Left out for cities.
  3. The faction: `Alliance`, `Horde` or `Contested`, each in its own color; left out while the faction is `""` (Forever zones not filled in yet).
  4. The instances, after an empty line: one line per row of `ns.Instances` whose `map` is the hovered zone (or, per P61, a city of that zone), in data order; name on the left in white, `Logic.FormatInstanceDetail` on the right: the same look as the instance pin tooltip. Rows without `x`/`y` are listed too (design doc Data model). The section is left out when there are none, and when the zone has not been entered (`GetExploredMapTextures(zone)` empty, P44; for a city the zone around it), unless `/ls reveal` is on. An unvisited zone does not tell how many instances it holds.
- **One source of truth:** ranges and faction from `ns.GetZoneInfo`, as the pins. The "entered a zone" test moves out of `Modules/Instances.lua` into one shared helper so both modules ask the same question.

### Code split (confirmed 2026-11-22, as in step 5.6)

- **User:** the `Logic.lua` functions and their tests; the `Pins.lua` changes (tab removal in `LodestarThreatPinMixin:OnAcquired`; the hover flag in `LodestarInstancePinMixin`).
- **Claude:** `Pins.xml`, the art script and retired files, `Modules/Tooltip.lua`, the shared "entered" helper, `.toc`, `.luacheckrc`, design doc, CLAUDE.md status.

Logic functions (names are suggestions; the user may rename):

- `Logic.InstancesOfZone(instances, mapID)`: the rows whose `map` is `mapID`, in data order, as a new list. Hint: like `GroupByPosition`'s loop, without the grouping.
- `Logic.FactionColor(faction)`: `r, g, b` for `"Alliance"`, `"Horde"`, `"Contested"`; `nil` for `""` or anything else. The colors are ours (no Blizzard constant is probed); hint: one local table keyed by faction.
- Possibly `Logic.FormatLevelsLine(min, max, codeFor)` returning `Levels 18-34` or `No level data`, if the user prefers that tested rather than in the module.

## Open questions

1. **Faction colors.** Suggested: Alliance blue `0.25, 0.55, 1.0`, Horde red `1.0, 0.25, 0.2`, Contested yellow `1.0, 0.82, 0.0`. Take these, or pick in game during P62?
2. **Levels line shape.** `Levels 18-34` on one line (design doc), or a double line with `Levels` left and the range right, matching the instance lines below it?
3. **Instance section header.** Just an empty line before the instances, or a grey `Instances` / `Dungeons` heading?

## P61: API checks (before any code)

Out of combat. Each line alone. Some need the map open with the cursor somewhere: bind them to a key with a macro, as for P7.

1. The canvas knows whether the mouse is over it. Macro on a key; press it with the cursor over a zone, then over the quest log beside the small map, then over the map's title bar. Expect `true`, `false`, `false`:

```
/run print("over canvas", WorldMapFrame.ScrollContainer:IsMouseOver())
```

2. A cursor-anchored tooltip of our own follows the mouse. Run it, move the mouse around, then open the map (small and maximized): the line should follow the cursor and draw above the map. Screenshot, please.

```
/run local t=LodestarProbeTip or CreateFrame("GameTooltip","LodestarProbeTip",UIParent,"GameTooltipTemplate") t:SetOwner(UIParent,"ANCHOR_CURSOR") t:AddLine("Lodestar probe") t:Show()
```

Then hide it:

```
/run LodestarProbeTip:Hide()
```

3. What the hover lookup returns over a capital and over a pin. Eastern Kingdoms map, your `/ls probe hover` key: cursor over Stormwind City, over Ironforge, over Undercity; then over a threat pin's skull. Same on Kalimdor over Orgrimmar, Thunder Bluff and Darnassus. Expect a city ID (1453, 1455, 1458...) or the zone around it; over the skull, the zone under it.

## P62: the step in game (after the code)

Filled in with the plan; it will cover the five points of "What this step is for", the city branch, `/ls reveal` and `/ls toggle Tooltip`, a level-up recolor, combat, and a look at pin size and draw order without the tab.
