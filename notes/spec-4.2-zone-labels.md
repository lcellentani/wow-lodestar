# M4 step 4.2: ZoneLabels, the first map overlay

Status: spec written 2026-10-19; P36 done the same day: no `MapCanvasPinTemplate` on Forever, so `Pins.xml` uses a plain frame. 4.2a test pin checked in game (P37, 2026-10-19). 4.2b labels checked in game (P38, 2026-10-19); overlaps and capital icons left for 4.3. User writes the code, Claude reviews and does `.luacheckrc`.
Design doc reference: "Architecture" (load order, `Pins.xml`, one namespace, no taint), "Data model" (map positions, `ns.GetZoneRect`), "Module specs" (how map overlays draw, ZoneLabels).

## What this step is for

Step 4.1 knows each zone's range and how to color it; this step draws it on the continent maps. It is the first time Lodestar draws on the map, and the riskiest part of the MVP: P3 and P17 showed that the data provider and pin functions exist, but nothing has used them in game yet. So the step starts with one test pin, and only then draws the real labels.

## Decisions

- **Two checkpoints.** 4.2a: a probe (P36), then one test pin at the center of each continent (P37). 4.2b: one label per zone with its colored range (P38).
- **The provider talks to `WorldMapFrame` directly** (`GetMapID`, `AcquirePin`, `RemoveAllPinsByTemplate`, all confirmed in P3, P7, P17), not to the provider's own `GetMap()`, which is unprobed. There is only one map canvas anyway.
- **The pin is set up in `OnAcquired`**: text, position and scaling, each time the map hands out the pin. No `OnLoad` script: the template has no base template that would call it (P36).
- **Labels never take the mouse.** Clicking a zone on a continent map zooms into it; a label sitting on top must not block that.
- **Left for 4.3**: refresh on `PLAYER_LEVEL_UP` (the event name is unprobed), tuning the zoom scaling, overlap with Blizzard's zone names, both map sizes, labels that need `labelX, labelY`.
- **Who writes what**: you write `Pins.xml`, `Modules/ZoneLabels.lua`, the `.toc` lines and the Lua changes; Claude adds `LodestarZoneLabelPinMixin` to `.luacheckrc` (done with this spec) and records the probes. Commits as before: your code `[T2]`, Claude's notes `[T4]`.

## 4.2a: one test pin

### Probe first (P36), no addon code

The pieces the pin needs that no probe has covered yet. Each line on its own:

```
/dump type(MapCanvasPinMixin.OnAcquired), type(MapCanvasPinMixin.SetScalingLimits), type(MapCanvasDataProviderMixin.RefreshAllData), type(MapCanvasDataProviderMixin.RemoveAllData)
```

Expected: four `"function"`.

```
/dump C_XMLUtil and C_XMLUtil.GetTemplateInfo("MapCanvasPinTemplate")
```

Expected: a table describing the template (its type `Frame`). If `C_XMLUtil` is missing (`nil`/`false`), no problem: the test pin itself shows whether the template exists.

```
/dump type(GameFontHighlightOutline), type(GameFontNormalOutline)
```

Expected: two `"table"`: font objects for the label text. Claude records P36 and adds the confirmed names to `.luacheckrc` before you write the code.

Result (P36): the four functions and both fonts exist, but **`MapCanvasPinTemplate` does not**: `C_XMLUtil.GetTemplateInfo` finds `GameTooltipTemplate` and returns `nil` for it. Forever's Blizzard UI is the Mainline (retail) code, and its own map pins (`AreaPOIPinTemplate`, `DungeonEntrancePinTemplate`) inherit only POI-specific templates (`LegendHighlightableMapPoiPinTemplate`, `BaseSuperTrackableMapPoiPinTemplate`). So the Lodestar template is a plain `Frame` with the mixin and no `inherits`; the skeleton below is already changed.

### `Pins.xml` (new file, repo root)

Templates only; all behavior is in Lua. The skeleton (XML is boilerplate, not part of learning Lua, so it is given almost whole):

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
  <Frame name="LodestarZoneLabelPinTemplate" mixin="LodestarZoneLabelPinMixin"
         enableMouse="false" virtual="true">
    <Size x="1" y="1"/>
    <Layers>
      <Layer level="OVERLAY">
        <FontString parentKey="Label" inherits="GameFontHighlightOutline">
          <Anchors>
            <Anchor point="CENTER"/>
          </Anchors>
        </FontString>
      </Layer>
    </Layers>
  </Frame>
</Ui>
```

- `virtual="true"`: a template, not a frame; the map creates frames from it.
- No `inherits`: Forever has no `MapCanvasPinTemplate` (P36). The map's pin behavior comes from the mixin, which is built on `MapCanvasPinMixin`.
- `parentKey="Label"`: the FontString becomes `self.Label` in the mixin, like a member pointer set up by the template.
- `mixin=` names a global table, so the mixin must exist before `Pins.xml` loads: `.toc` order matters (below).
- The 1x1 frame is only an anchor point; the text is centered on it and drawn outside it.
- XML errors do not appear in chat: if the pin does not show, the game writes them to `Logs\FrameXML.log` in the game folder. Tell Claude, who reads it.

### `Modules/ZoneLabels.lua` (new file)

Starts with `local addonName, ns = ...` like every file. Three parts:

1. **The pin mixin**, a global (the template finds it by name):
   - `LodestarZoneLabelPinMixin = CreateFromMixins(MapCanvasPinMixin)`.
   - `function LodestarZoneLabelPinMixin:OnAcquired(text, x, y)`: `self.Label:SetText(text)`, `self:SetPosition(x, y)`, and `self:SetScalingLimits(1, 1.0, 1.2)` (first try; 4.3 tunes it).
2. **The data provider**, a file-local table:
   - `local provider = CreateFromMixins(MapCanvasDataProviderMixin)`.
   - `function provider:RemoveAllData()`: `WorldMapFrame:RemoveAllPinsByTemplate(TEMPLATE)`.
   - `function provider:RefreshAllData()`: first `self:RemoveAllData()`; then, if the shown map is a continent (`C_Map.GetMapInfo(WorldMapFrame:GetMapID()).mapType == Enum.UIMapType.Continent`), `WorldMapFrame:AcquirePin(TEMPLATE, "TEST", 0.5, 0.5)`.
3. **The module**, registered with the core:
   - `local ZoneLabels = {}`, `ZoneLabels:OnEnable()` calls `WorldMapFrame:AddDataProvider(provider)`, `ZoneLabels:OnDisable()` calls `WorldMapFrame:RemoveDataProvider(provider)`.
   - `ns.RegisterModule("ZoneLabels", ZoneLabels)`.

Hints:

- `local TEMPLATE = "LodestarZoneLabelPinTemplate"` at the top: the name must match `Pins.xml` exactly, and a constant keeps the three uses in step.
- `AcquirePin(template, ...)` passes everything after the template name on to the pin's `OnAcquired`: `"TEST", 0.5, 0.5` arrive as `text, x, y`. That is how data reaches a pin.
- `provider` uses the colon (`function provider:RefreshAllData()`): the map calls it as a method. Inside, `self` is `provider`.
- `GetMapInfo` can return `nil` for odd maps; check it before reading `.mapType`.
- `RefreshAllData` gets an argument (`fromOnShow`) that we do not use: leave it out of the parameter list, or luacheck warns.

### `.toc`

Add `Modules\ZoneLabels.lua` after `Data\Instances.lua`, then `Pins.xml` after it, before `Debug.lua` (the doc's load order: the mixin before the template that names it).

### In-game check (P37)

No temporary code beyond the test pin itself.

```
/reload
```

1. Open the world map on Eastern Kingdoms: a white `TEST` at the center of the map. Switch to Kalimdor: `TEST` at its center. (This proves the map calls `RefreshAllData` on a map change.)
2. Open a zone map (Elwynn Forest) and the world map (Azeroth): no `TEST`.
3. On Eastern Kingdoms, click the zone under `TEST`: the map zooms into that zone (the label does not take the click).
4. Zoom in with the mouse wheel: `TEST` grows a little, then stops growing.
5. Toggle the module off:

```
/ls toggle ZoneLabels
```

Reopen the map: no `TEST`. Toggle it on again: `TEST` is back, with no `/reload`.

Then `/reload` and tell Claude: no errors in chat, and (if anything failed) `Logs\FrameXML.log`.

## 4.2b: one label per zone

### `Logic.LabelPosition(info, minX, maxX, minY, maxY)` in `Logic.lua`

- Returns `info.labelX, info.labelY` when both are set, otherwise the center of the rectangle, `(minX + maxX) / 2, (minY + maxY) / 2`.
- Tests (`describe("LabelPosition", ...)`): Elwynn's rectangle from P5 (`0.411, 0.510, 0.657, 0.755`) gives its center; an `info` with `labelX = 0.3, labelY = 0.4` gives `0.3, 0.4`; an `info` with only `labelX` falls back to the center (both or neither, like `min` and `max`).

### `ns.GetZoneRect(zoneID, mapID)` in `Core.lua`

- Returns `minX, maxX, minY, maxY` from `C_Map.GetMapRectOnMap(zoneID, mapID)`, or `nil` when `Logic.IsRectOnMap` says the zone is not on that map (P5: four zeros, not `nil`).
- Caches the answer, since a zone's rectangle never changes: a file-level `local rectCache = {}`, keyed by map then zone (`rectCache[mapID][zoneID]`). Store a rectangle as a table `{ minX, maxX, minY, maxY }`, and a zone not on the map as `false`.
- Hint: `false`, not `nil`, for "not on the map": `rectCache[mapID][zoneID] == nil` must keep meaning "not asked yet". Storing `nil` in a table is the same as storing nothing, so the cache would ask again every time.
- Hint: `unpack(t)` returns a list table's values as separate return values: `return unpack(rect)`.

### Real labels in `Modules/ZoneLabels.lua`

`RefreshAllData` on a continent, replacing the test pin:

1. `for _, child in ipairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}) do`.
2. `local info = ns.GetZoneInfo(child.mapID)`, `local text = ns.Logic.FormatLevelRange(info.min, info.max, ns.LevelColorCode)`.
3. Skip the zone when `text` is `nil` (cities, Shen'dralas) or when `ns.GetZoneRect(child.mapID, mapID)` returns `nil`.
4. `local x, y = ns.Logic.LabelPosition(info, minX, maxX, minY, maxY)`, then `WorldMapFrame:AcquirePin(TEMPLATE, text, x, y)`.

Hint: `GetMapChildrenInfo(id, 3)` lists the children P5 showed: 26 on Eastern Kingdoms, 23 on Kalimdor, cities included.

### In-game check (P38)

```
/reload
```

1. Eastern Kingdoms: one label per zone, 23 in all (26 children minus the three capitals), each inside its zone, colored for your level (at 18: Elwynn grey 1 and yellow 14, Redridge green 13 and red 30). No label on Stormwind, Ironforge or Undercity.
2. Kalimdor: 19 labels (23 children minus three capitals and Shen'dralas, which has no range).
3. Note where labels look wrong: overlapping a zone name Blizzard draws, sitting in water, or crowding a neighbor. Screenshot both continents; those notes are 4.3's input.
4. A zone map and the world map: no labels.

Then `/reload`, and Claude reads the log and records P38.

## Done when (each checkpoint)

- `scripts/check.ps1` passes (luacheck + tests).
- The in-game check behaves as described; Claude records it in `notes/beta-probes.md`.
- The code and the notes are committed separately.
