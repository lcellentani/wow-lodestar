# M5 step 5.4: threat markers

Status: spec written 2026-11-08; `Logic.PlayerZone` by the user, the rest delegated to Claude and written 2026-11-08, awaiting P54. Probe number reserved: P54 (the markers in game). No API probe needed: everything used is already confirmed (P2, P5, P8, P17, P40, P42, P46).
Design doc reference: "ThreatOverlay" (What, Look, Art, Position), "Neighbors" (Data model), "Architecture" (one namespace, no taint, pins from `Pins.xml`).

## What this step is for

The small continent map answers "from here, what is next door, and is it safe?". This step draws a marker on each zone that borders the player's zone: a skull in the threat color on a dark disc, and a dark tab with the zone's minimum level underneath. The maximized map keeps the range labels and gets no markers.

## Decisions

The behavior rules were settled on 2026-11-08 (design doc, ThreatOverlay, "Behavior rules"):

- **Which zones**: the `neighbors` of the player's zone in `Data/Zones.lua`. A city counts as the zone around it (its `zone` field). The player's own zone gets no marker.
- **When**: only on the small map, and only when the continent shown is the one the player's zone is on. In a dungeon, on Zephras Isle, or browsing the other continent, nothing is drawn.
- **Color and number**: both from the neighbor's `min`, through `GetQuestDifficultyColor(min)` (P8), as for the labels. A neighbor with no range (Shen'dralas) or no point gets no marker.
- **Refresh**: when the map opens or changes (the data provider's `RefreshAllData`), when it is maximized or minimized (P42), when the player levels up (P40), and when the player crosses into another zone while the map is open (the map tick).
- **Sub-zone maps**: if the game reports a micro map (`mapType == Enum.UIMapType.Micro`, such as a cave), the zone is its parent. A dungeon (`Enum.UIMapType.Dungeon`) is "away": nothing.
- **Data stays in `ns.Zones`**: `neighbors` and `zone` are facts, not overridable, so `Logic.MergeZoneInfo` does not change. Read them from `ns.Zones` directly; read `min`, `labelX`, `labelY` through `ns.GetZoneInfo` as ZoneLabels does.

## The art (Claude, before you start)

Claude writes `scripts/make_marker_art.py` and three white textures with the shape in the alpha channel (like `Media/probe-white.tga`, P46), all tinted in game with `SetVertexColor`:

| File | Shape | Used as |
| --- | --- | --- |
| `Media/threat-disc.tga` | filled disc, crisp edge | the outline (threat color) and, drawn smaller on top, the dark plate |
| `Media/threat-tab.tga` | filled rounded rectangle | the same, for the tab |
| `Media/threat-skull.tga` | flat skull | the skull (threat color) |

The outline is the colored shape drawn behind a dark copy 2 pixels smaller (the edges grew instead in the 2026-11-08 tuning, so the plates keep their room), so three textures give the whole look. **New files need a full client restart**, not just `/reload`: the game only sees files that existed when it started (P46).

## Logic.lua (pure, unit tested)

### `Logic.PlayerZone(zones, mapID, isMicro, parentID)`

Returns the zone whose neighbors get markers, or `nil` for "away".

1. `zones[mapID]` is a zone row (`kind == "zone"`): return `mapID`.
2. It is a city: return its `zone`.
3. `isMicro` is true and `zones[parentID]` is a zone row: return `parentID`.
4. Anything else: `nil`.

- Hint: `isMicro` is a plain boolean, so `Logic.lua` stays free of `Enum`; the WoW side computes it.
- Tests (use a small fake `zones` table, not `ns.Zones`): a zone returns itself; a city returns its zone; a micro map whose parent is a zone returns the parent; a micro map whose parent is a city or unknown returns `nil`; a non-micro unknown map (a dungeon) returns `nil` even if its parent is a zone; `mapID == nil` returns `nil`.

## The WoW side

### `Pins.xml`: a second template

`LodestarThreatPinTemplate`, mixin `LodestarThreatPinMixin`, `enableMouse="false"`, `virtual="true"`, size 1 x 1 like the label pin. Five regions, all anchored to the pin's center so the disc sits on the zone's point:

| parentKey | Layer | Size | Anchor |
| --- | --- | --- | --- |
| `DiscEdge` | `BACKGROUND` | 22 x 22 | `CENTER` |
| `TabEdge` | `BACKGROUND` | 24 x 18 | `TOP` to `DiscEdge`'s `BOTTOM`, y offset 1 (overlap) |
| `Disc`, `Tab` | `BORDER` | 2 pixels smaller each way: 18 x 18, 20 x 14 | `CENTER` on their edge |
| `Skull` | `ARTWORK` | 14 x 14 | `CENTER` on `Disc` |
| `Level` (FontString, `GameFontHighlightSmallOutline`, 10 pt, P55) | `OVERLAY` | | `CENTER` on `Tab` |

Textures: `file="Interface\AddOns\Lodestar\Media\threat-disc"` and so on. The sizes started from the placement tool's placeholder and were tuned on the live client on 2026-11-08: a 10 pt number, and a tab grown so the number has about 3 pixels of margin (screenshots 200747, 201140, 201147). A 1-pixel outline was tried and dropped: the final outline is 2 pixels, grown outward so the plates keep their size.

### `Modules/ThreatOverlay.lua`

A new file after `Modules\ZoneLabels.lua` in `Lodestar.toc`. Add `LodestarThreatPinMixin` to `globals` in `.luacheckrc` (the "One namespace" rule allows `Lodestar...PinMixin`), and `ThreatOverlay = true` to `DEFAULTS.modules` in `Core.lua`.

**The mixin**, built like `LodestarZoneLabelPinMixin`:

- `OnAcquired(min, x, y)`: color = `GetQuestDifficultyColor(min)`; `DiscEdge`, `TabEdge` and `Skull` get `SetVertexColor(color.r, color.g, color.b)`; `Disc` and `Tab` a dark plate (start with `0.1, 0.08, 0.05`, the placeholder's); `Level:SetText(min)`; `SetPosition(x, y)`; `SetScalingLimits(1, 1.0, 1.2)`.
- An empty `CheckMouseButtonPassthrough`, as in ZoneLabels: the inherited one is blocked in combat (P14).

**The provider's `RefreshAllData`**:

1. `RemoveAllData()` first, as in ZoneLabels.
2. Skip unless the shown map is a continent and the map is **not** maximized (the opposite of ZoneLabels).
3. Player: `local mapID = C_Map.GetBestMapForUnit("player")`; if it is `nil`, stop. `local info = C_Map.GetMapInfo(mapID)`; `isMicro = info.mapType == Enum.UIMapType.Micro`; `zoneID = ns.Logic.PlayerZone(ns.Zones, mapID, isMicro, info.parentMapID)`. Stop if `nil`.
4. Same continent: `C_Map.GetMapInfo(zoneID).parentMapID` must equal `WorldMapFrame:GetMapID()`. Otherwise stop: you are looking at the other continent.
5. For each ID in `ns.Zones[zoneID].neighbors or {}`: `local n = ns.GetZoneInfo(id)`; if `n.min`, `n.labelX` and `n.labelY` are all set, `WorldMapFrame:AcquirePin(TEMPLATE, n.min, n.labelX, n.labelY)`.
6. Remember `zoneID` in a local (`drawnZone`) for the tick below.

**Refresh triggers** (`OnEnable` adds them, `OnDisable` removes them where it can):

- Map size: the same `EventRegistry` callbacks as ZoneLabels (`WorldMapMaximized`, `WorldMapMinimized`), added once, checking `enabled`. Use your module table as the owner, not ZoneLabels'.
- Level up: `ns.RegisterEvent("PLAYER_LEVEL_UP", handler)`; the handler refreshes only if the map is shown. The colors come from `GetQuestDifficultyColor`, which reads the level itself; do not rely on the event's arguments (P40 did not probe them).
- Zone crossing: `ns.RegisterMapTick(handler)` (runs only while the map is open). The handler resolves the player's zone as in steps 3 and computes `zoneID`; if it differs from `drawnZone`, refresh. Keep it cheap: two `C_Map` calls and a compare, ten times a second.
- `OnDisable`: `enabled = false`, remove pins and provider, `ns.UnregisterEvent(...)`, `ns.UnregisterMapTick(...)`.

Hint: the resolve in step 3 is needed twice (refresh and tick), so make it one local function returning `zoneID` or `nil`.

## P54: the markers in game

Restart the client first (new textures). Other addons off.

1. Small map on your current continent: a marker on each neighbor of your zone, none on your own zone. Compare with the `neighbors` list of your zone in `Data/Zones.lua`.
2. Colors and numbers: each marker's skull, outline and tab edge in the color of its number, as the maximized map's labels color the same `min`.
3. Maximize: markers gone, labels shown. Minimize: markers back.
4. Switch to the other continent and to a zone map: no markers. Back to your continent: markers back.
5. Walk into the neighboring zone with the map open: the markers move to the new zone's neighbors within a moment.
6. In a capital (or a cave, if one is near): the markers of the zone around it.
7. `/ls toggle ThreatOverlay` off: markers gone; on: back, with the map open.
8. Fight something with the small map open: no error popup, no "blocked action" message (a light P14; the full P14/P15 rerun comes at the end of M5).
9. Level up, when it happens next: the colors update without reopening the map.

Screenshots of 1, 3 and 6, and any error popup. Claude records P54.

## After the step

Look tuning on the live client (sizes, plate darkness, skull shape) in small follow-ups. Commits: your code `[T2]`, Claude's art script, textures and notes `[T4]`, separately.
