# Beta probes

Raw in-game output for the probes in the design doc's "Beta verification checklist". Tick a probe when its output is recorded here. An API counts as confirmed (evidence rule) only once its output is in this file.

Client: World of Warcraft: Forever (beta until 2026-10-21, live from 2026-11-04).

**Setup, once:** `/console scriptErrors 1` so Lua errors show as popups. An error is a valid result: screenshot it.

Before the addon exists, run the `/dump` lines below (copy them from here and paste into chat with Ctrl+V) and take screenshots; Claude Code transcribes them here. If `/dump` itself is missing, use `/run print(<expression>)` instead and note it under P1.

## Status

| # | Checks | Status | Date | Client build |
| --- | --- | --- | --- | --- |
| P1 | A1 | [x] | 2026-10-12 | beta, interface 16001 |
| P2 | A2 | [x] | 2026-10-12 | beta, interface 16001 |
| P3 | A3 | [x] | 2026-10-12 | beta, interface 16001 |
| P4 | A3 | [x] | 2026-10-12 | beta, interface 16001 |
| P5 | A4 | [x] | 2026-10-12 | beta, interface 16001 |
| P6 | A7 | [x] | 2026-10-12 | beta, interface 16001 |
| P7 | A8 | [x] | 2026-10-12 | beta, interface 16001 |
| P8 | colors | [x] | 2026-10-12 | beta, interface 16001 |
| P9 | A6 | [x] | 2026-10-12 | beta, interface 16001 |
| P10 | A5 | [x] | 2026-10-18 | beta; `Data/Zones.lua` built from the dump, checked by `tests/zones_spec.lua` |
| P11 | data | [x] | 2026-10-19 | closed: zone ranges come from the group finder (P33), not from checks zone by zone |
| P12 | data | [ ] | 2026-10-19 | beta, in progress |
| P13 | v2 | [ ] | | |
| P14 | taint | [ ] | | |
| P15 | taint | [ ] | | |
| P16 | M2 APIs | [x] | 2026-10-13 | beta |
| P17 | M4-M5 APIs | [x] | 2026-10-13 | beta |
| P18 | A1, load | [x] | 2026-10-13 | beta |
| P19 | M2 chat, safe calls | [x] | 2026-10-14 | beta |
| P20 | M2 SavedVariables defaults | [x] | 2026-10-15 | beta |
| P21 | M2 event dispatcher | [x] | 2026-10-16 | beta, after client patch, interface 16001 |
| P22 | M2 module registry | [x] | 2026-10-16 | beta |
| P23 | M2 map tick | [x] | 2026-10-16 | beta |
| P24 | M2 slash commands | [x] | 2026-10-16 | beta |
| P25 | M2 toggle, debug | [x] | 2026-10-17 | beta |
| P26 | login vs /reload chat order | [ ] | | |
| P27 | M2 output and log | [x] | 2026-10-18 | beta |
| P28 | copy window methods (no addon) | [x] | 2026-10-18 | beta |
| P29 | M2 copy window | [x] | 2026-10-18 | beta |
| P30 | M2 /ls dump | [x] | 2026-10-18 | beta |
| P31 | M2 /ls probe | [x] | 2026-10-19 | beta |
| P32 | dungeon entrance API | [x] | 2026-10-19 | beta |
| P33 | group finder activities (levels) | [x] | 2026-10-19 | beta, Alliance character |
| P34 | M2 /ls probe here | [x] | 2026-10-19 | beta |
| P35 | M4 zone info, colors in /ls probe hover | [x] | 2026-10-19 | beta |
| P36 | pin hooks, pin template, label fonts | [x] | 2026-10-19 | beta |
| P37 | M4 ZoneLabels test pin | [x] | 2026-10-19 | beta |
| P38 | M4 ZoneLabels labels | [x] | 2026-10-19 | beta |
| P39 | M4 label names on the maximized map | [x] | 2026-10-19 | beta |
| P40 | level-up event | [ ] | | |
| P41 | dungeon and raid icons (atlases) | [ ] | | |

## Confirmed APIs

APIs whose output is recorded below. Each one also goes into `read_globals` in `.luacheckrc` when used.

| API | Probe | Notes |
| --- | --- | --- |
| `GetBuildInfo` | P1 | 4th return is the interface number (16001) |
| `print` | P1 | prints to the General chat tab |
| `/dump` | P1 | built-in slash command, works |
| `C_Map` | P2 | table exists |
| `C_Map.GetBestMapForUnit` | P2 | `"player"` in Stormwind returns 1453 |
| `C_Map.GetMapInfo` | P2 | returns `mapType`, `mapID`, `name`, `parentMapID`, `flags` |
| `WorldMapFrame.AddDataProvider` | P3 | function |
| `WorldMapFrame.AcquirePin` | P3 | function |
| `MapCanvasPinMixin` | P3 | exists |
| `C_Map.GetMapChildrenInfo` | P5 | `(1415, 3)` returns 26 entries with `mapType`, `mapID`, `name`, `parentMapID`, `flags` |
| `C_Map.GetMapRectOnMap` | P5 | `(childID, parentID)` returns minX, maxX, minY, maxY, normalized 0-1 on the parent map |
| `C_Map.GetMapLevels` | P6 | exists; returns 0, 0, 0, 0 for 1429, 1433 and 2548 (no level data on the beta) |
| `WorldMapFrame:GetMapID` | P7 | returns the shown map's uiMapID |
| `WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition` | P7 | returns the cursor's x, y on the shown map |
| `C_Map.GetMapInfoAtPosition` | P7 | `(mapID, x, y)` returns the child map info under that point |
| `GetQuestDifficultyColor` | P8 | `(level)` returns a color table `{r, g, b, font}`, then a lighter second table; orange at player level + 3 |
| `UnitLevel` | P8 | `("player")` |
| `WorldMapFrame` | P3, P4 | exists at login, before the map is first opened |
| `Enum.UIMapType` | P2 | Cosmic 0, World 1, Continent 2, Zone 3, Dungeon 4, Micro 5, Orphan 6 |
| `CreateFrame` | P16 | `"Frame"` with `RegisterEvent` and `SetScript("OnEvent")`; `"EditBox"` with `SetMultiLine`, `HighlightText`, `SetAutoFocus`; templates `UIPanelScrollFrameTemplate`, `BasicFrameTemplateWithInset`, `BackdropTemplate` |
| `hooksecurefunc` | P16 | `(WorldMapFrame, "OnMapChanged", fn)` works; fires before `OnShow` when the map opens |
| `WorldMapFrame:HookScript` | P16 | `"OnShow"` and `"OnHide"` |
| `UIParent` | P16 | table |
| `DEFAULT_CHAT_FRAME:AddMessage` | P16 | renders `\|cffRRGGBB...\|r`; in `/run` lines typed into chat, write `\|` as `\124` |
| `UISpecialFrames` | P16 | table |
| `SlashCmdList`, `SLASH_<NAME>1` | P16 | registration works; `/ls` and `/lodestar` are free |
| `time`, `date`, `GetTime` | P16 | `date("%Y-%m-%d %H:%M:%S")` returns local time |
| `CreateFromMixins`, `Mixin` | P17 | functions |
| `MapCanvasDataProviderMixin` | P17 | table |
| `WorldMapFrame.RemoveDataProvider`, `WorldMapFrame.RemoveAllPinsByTemplate` | P17 | functions |
| `MapCanvasPinMixin.SetPosition`, `MapCanvasPinMixin.SetScalingLimits` | P17 | functions |
| `C_Map.GetPlayerMapPosition` | P17 | function (output checked in P12) |
| `GameTooltip` | P17 | table |
| `CreateFrame("GameTooltip", name, UIParent, "GameTooltipTemplate")` | P17 | creates `<name>TextLeft1` and friends |
| `pcall` | P19 | catches addon errors without a popup; the message starts with `Interface/AddOns/Lodestar/<file>:<line>:` |
| Frame methods (`SetSize`, `SetPoint`, `SetMovable`, `EnableMouse`, `RegisterForDrag`, `StartMoving`, `StopMovingOrSizing`, `Show`, `IsShown`) | P28 | on a `BasicFrameTemplateWithInset` frame; its `.TitleText` has `SetText` |
| `ScrollFrame:SetScrollChild` | P28 | on a `UIPanelScrollFrameTemplate` scroll frame |
| EditBox methods (`SetText`, `SetFocus`, `SetFontObject`, `SetWidth`) | P28 | no character limit seen at about 360 characters (P29) |
| `ChatFontNormal` | P28 | global font object |
| Script names `OnDragStart`, `OnDragStop`, `OnEscapePressed` | P28 | `SetScript` accepts them |
| `GetQuestGreenRange` | P8 | **missing** |

## Design probes (no addon needed)

### P1: interface number (A1)

```
/dump (select(4, GetBuildInfo()))
```

Result (2026-10-12, beta; screenshot `screenshots/Screenshot 2026-10-12 182304.png`):

```
hello
Dump: value=(select(4, GetBuildInfo()))
[1]=16001
```

- Interface number **16001**: use `## Interface: 16001` in the `.toc`.
- `/dump` exists and prints to the General chat tab; `/run print(...)` also works.
- The first run only showed Blizzard's "custom scripts" warning and did not execute; after allowing scripts, rerunning worked.

### P2: C_Map exists (A2)

```
/dump C_Map ~= nil
/dump C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player"))
/dump Enum.UIMapType
```

Result (2026-10-12, beta):

```
/dump C_Map ~= nil
[1]=true

/dump C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player"))
[1]={
  mapType=3,
  mapID=1453,
  name="Stormwind City",
  parentMapID=1415,
  flags=0
}
```

- `C_Map.GetBestMapForUnit` and `C_Map.GetMapInfo` work (screenshot 182631). Stormwind City is 1453, mapType 3, parent 1415 (Eastern Kingdoms): all the same as Classic Era.

```
/dump Enum.UIMapType      (screenshot 183047)
[1]={
  Dungeon=4,
  Orphan=6,
  Zone=3,
  Continent=2,
  Cosmic=0,
  Micro=5,
  World=1
}
```

- Same values as Classic Era. Use the names (`Enum.UIMapType.Zone`), not the numbers, in code.

### P3: map canvas and pins (A3)

```
/dump WorldMapFrame.AddDataProvider, WorldMapFrame.AcquirePin, MapCanvasPinMixin ~= nil
```

All three should be non-nil. Then open the map, run `/fstack`, hover the map and note the frame names under `WorldMapFrame` (screenshot).

Result (2026-10-12, beta; screenshot 183309):

```
Dump: value=WorldMapFrame.AddDataProvider, WorldMapFrame.AcquirePin, MapCanvasPinMixin ~= nil
[1]=<function>,
[2]=<function>,
[3]=true
```

- The map canvas supports data providers and pins, as in Classic Era: the overlay design (data providers + `Pins.xml`) holds.

`/fstack` frame names (screenshot 183458, map open on Stormwind City, cursor over the map):

```
HIGH
  <500> WorldMapFrame.BorderFrame.NineSlice
  <3>   WorldMapFrame.ScrollContainer.1c794946450
  <2>   WorldMapFrame.BorderFrame
MEDIUM
  <2920> <2009> <2008> <2007> <2002>  WorldMapFrame.ScrollContainer.Child.<unnamed>   (pins)
  <3>   WorldMapFrame.ScrollContainer.Child.1c7a7be8580 (+ one child)
  <3>   WorldMapFrame.ScrollContainer.Child
  <3>   WorldMapFrame.ScrollContainer.Child.TiledBackground
  <2>   WorldMapFrame.ScrollContainer
  <2>   WorldMapFrame.OverscrollBG (.Texture, .TopLeftVignette)
  <1>   WorldMapFrame
  <1>   WorldMapFrameBg
  <0>   UIParent
SOURCE
  Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.xml:85
```

- Structure matches the Classic Era / Wrath map canvas: `WorldMapFrame.ScrollContainer.Child` holds the pins, `WorldMapFrame.BorderFrame` is the frame chrome.
- The map is defined by the Blizzard addon `Blizzard_WorldMap` (relevant to P4: it may load on demand).
- The window is the combined "Map & Quest Log" (quest list on the right) with breadcrumb navigation (World > Eastern Kingdoms > Stormwind City).
- **The native map already shows coordinates**: bottom-left of the map, "Cursor: 41.9, 20.5" and "Player: 69.6, 74.1". This overlaps the planned Coords module.
- Zone name labels on the map are drawn by Blizzard (e.g. "Elwynn Forest" on the Stormwind map).

### P4: map loaded at login (A3)

Right after `/reload`, before opening the map:

```
/dump WorldMapFrame ~= nil
```

Result (2026-10-12, beta; after `/reload`, map not opened):

```
[1]=true
```

- `WorldMapFrame` exists right after login, before the map is opened: `Blizzard_WorldMap` is loaded at login, so map modules can register their data providers on `PLAYER_LOGIN`. Keep the `ADDON_LOADED` fallback in the core anyway; it costs nothing.

### P5: continent children and zone rectangles (A4)

Continent IDs below are Classic Era values (1414 Kalimdor, 1415 Eastern Kingdoms); this probe also checks they still hold.

```
/dump C_Map.GetMapChildrenInfo(1415, 3)
/dump C_Map.GetMapRectOnMap(1429, 1415)
/dump C_Map.GetMapChildrenInfo(1414, 3)
/dump C_Map.GetMapRectOnMap(1411, 1414)
```

1429 is Elwynn Forest, 1411 is Durotar. The four rectangle numbers should fall between 0 and 1 and match where the zone sits on the continent map.

The `/dump` of a children list is too long for the chat history (about 7 lines per entry, history keeps ~128 lines). Use one line per child instead:

```
/run for _,c in ipairs(C_Map.GetMapChildrenInfo(1415,3)) do print(c.mapID,c.name,c.mapType,c.flags) end
```

Result (2026-10-12, beta):

`/dump C_Map.GetMapChildrenInfo(1415, 3)` returned 26 entries; only the last one was still in the chat history (screenshot 184145):

```
[26]={
  mapType=3,
  mapID=2548,
  name="Riverglades",
  parentMapID=1415,
  flags=2
}
```

- `C_Map.GetMapChildrenInfo` works. Riverglades (new Forever zone) is mapID 2548, a zone of Eastern Kingdoms. `flags=2` differs from Stormwind's `flags=0` (meaning unknown yet).

Full list with the one-line `/run` loop (screenshots 184605, 184617, 184629, 184636; columns: mapID, name, mapType, flags):

```
1416 Alterac Mountains 3 2
1417 Arathi Highlands 3 2
1418 Badlands 3 2
1419 Blasted Lands 3 2
1420 Tirisfal Glades 3 2
1421 Silverpine Forest 3 2
1422 Western Plaguelands 3 2
1423 Eastern Plaguelands 3 2
1424 Hillsbrad Foothills 3 2
1425 The Hinterlands 3 2
1426 Dun Morogh 3 2
1427 Searing Gorge 3 2
1428 Burning Steppes 3 2
1429 Elwynn Forest 3 2
1430 Deadwind Pass 3 2
1431 Duskwood 3 2
1432 Loch Modan 3 2
1433 Redridge Mountains 3 2
1434 Stranglethorn Vale 3 2
1435 Swamp of Sorrows 3 2
1436 Westfall 3 2
1437 Wetlands 3 2
1453 Stormwind City 3 0
1455 Ironforge 3 0
1458 Undercity 3 0
2548 Riverglades 3 2
```

- 26 entries. 1416-1437 and the three capitals (1453, 1455, 1458) are the Classic Era IDs; Riverglades (2548) is the only addition.
- All are mapType 3, including the capitals. `flags` is 2 for every outdoor zone and 0 for the three capitals; the bit's meaning is not known, so do not rely on it.

```
/dump C_Map.GetMapRectOnMap(1429, 1415)      (screenshot 184943)
[1]=0.41092681884766,
[2]=0.50953030586243,
[3]=0.65651535987854,
[4]=0.75514841079712
```

- Four numbers between 0 and 1. Read as (minX, maxX, minY, maxY), Elwynn spans x 41-51 %, y 66-76 % of the Eastern Kingdoms map: bottom center, where it is. The other plausible order (left, top, right, bottom) would make it 25 % wide by 25 % tall, far too big.
- Order confirmed (2026-10-12, by eye, no screenshot): on the Eastern Kingdoms map, the native cursor coordinates read about x 41 at Elwynn's west edge and y 75 at its south edge. **`GetMapRectOnMap` returns minX, maxX, minY, maxY.**

Kalimdor children, one-line `/run` loop on 1414 (2026-10-12, typed by the user from the chat output; the user confirmed every ID after Ashenvale matches the Classic Era value):

```
1411 Durotar 3 2
1412 Mulgore 3 2
1413 The Barrens 3 2
1438 Teldrassil 3 2
1439 Darkshore 3 2
1440 Ashenvale 3 2
1441 Thousand Needles 3 2
1442 Stonetalon Mountains 3 2
1443 Desolace 3 2
1444 Feralas 3 2
1445 Dustwallow Marsh 3 2
1446 Tanaris 3 2
1447 Azshara 3 2
1448 Felwood 3 2
1449 Un'Goro Crater 3 2
1450 Moonglade 3 2
1451 Silithus 3 2
1452 Winterspring 3 2
1454 Orgrimmar 3 0
1456 Thunder Bluff 3 0
1457 Darnassus 3 0
2482 Mount Hyjal 3 2
2652 Shen'dralas 3 2
```

- 23 entries: the 21 Classic Era zones and capitals with their Classic Era IDs, plus Mount Hyjal (2482) and Shen'dralas (2652, not in the design doc).
- Zephras Isle is not a child of either continent; it may be its own map or not in the beta yet.

Zephras Isle, character standing on the island (2026-10-12, beta; screenshot 193517). `GetMapInfo` of the player's map, then the parent chain printed by a `/run` loop (mapID, name, mapType, parentMapID):

```
[1]={
  mapType=3,
  mapID=2521,
  name="Zephras Isle",
  parentMapID=947,
  flags=2
}
2521 Zephras Isle 3 947
947 Azeroth 1 0
```

- **Zephras Isle is mapID 2521, a zone (mapType 3) whose parent is the world map Azeroth (947, mapType 1)**, not a continent. It has no continent map, so the "labels on continent maps" rule does not cover it.
- Azeroth (947) is the top of the chain (parent 0), same ID as Classic Era.
- The world map (Azeroth) does not show Zephras Isle anywhere (user observation, 2026-10-12, no screenshot).

```
/dump C_Map.GetMapRectOnMap(2521, 947)      (screenshot 193851)
[1]=0,
[2]=0,
[3]=0,
[4]=0
```

- **A map with no placement on its parent returns a rectangle of four zeros, not nil.** Code must treat an all-zero rectangle as "not on this map".
- The Zephras Isle zone map exists (breadcrumb "World > Zephras Isle", screenshot 193851): an island with Thendal Village, Ruins of Ban'aethal, Shen'dar Village, Shrine of Akir, Falaath Village, Valan…. Native coordinates work there.
- Navigation: the world map has no clickable area for Zephras Isle, but the island's map is reachable from the breadcrumb: the dropdown next to a continent ("Kalimdor") lists the children of World, "Eastern Kingdoms, Kalimdor, Zephras Isle" (2026-10-12, screenshot 235204). This corrects an earlier note that the map had to be closed and reopened. It confirms Zephras Isle is a sibling of the continents under World (947), not a child of Kalimdor.

```
/dump C_Map.GetMapRectOnMap(1411, 1414)      (screenshot 185708)
[1]=0.51709777116776,
[2]=0.66078054904938,
[3]=0.4480282664299,
[4]=0.59171110391617
```

- Durotar spans x 52-66 %, y 45-59 % of the Kalimdor map (minX, maxX, minY, maxY): the east coast, middle height, where it is. Consistent with the Elwynn result.


### P6: client level data (A7)

The design doc said `C_Map.GetLodestar` (an error from the MapLevels to Lodestar rename, fixed 2026-10-12); the Classic function is `C_Map.GetMapLevels`.

```
/dump C_Map.GetMapLevels and C_Map.GetMapLevels(1429)
```

If it returns ranges, compare a few zones against quest and mob levels before trusting it.

Result (2026-10-12, beta):

```
/dump C_Map.GetMapLevels and C_Map.GetMapLevels(1429)
[1]=0
```

- `C_Map.GetMapLevels` exists (otherwise the result would be nil).
- Probe flaw: `a and f()` keeps only the first return value, so only playerMinLevel (0) is shown. Follow-up without `and`:

```
/dump C_Map.GetMapLevels(1429)
/dump C_Map.GetMapLevels(1433)
/dump C_Map.GetMapLevels(2548)
```

Follow-up results (screenshot 190321):

```
/dump C_Map.GetMapLevels(1429)
[1]=0,
[2]=0,
[3]=0,
[4]=0
```

- Elwynn Forest: all four values 0, so the client has no level range for it.
- Redridge Mountains (1433) and Riverglades (2548): also all four values 0 (reported by the user, no screenshot).
- **A7 is false on the beta**: `GetMapLevels` exists but returns no level data, for vanilla or new zones. Level ranges come from `Zones.lua`. Re-check on the live client after Nov 4, 2026.

### P7: zone under the cursor (A8)

Make a macro with this text, bind it to a key, open a continent map, hover a zone and press the key:

```
/dump C_Map.GetMapInfoAtPosition(WorldMapFrame:GetMapID(), WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition())
```

Also note what Blizzard shows on hover: name label, tooltip, or nothing.

Result (2026-10-12, beta; macro "probe" on key 0, Eastern Kingdoms map open, cursor over Elwynn Forest; screenshot 191010):

```
[1]={
  mapType=3,
  mapID=1429,
  name="Elwynn Forest",
  parentMapID=1415,
  flags=2
}
```

- `WorldMapFrame:GetMapID`, `WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition` and `C_Map.GetMapInfoAtPosition` all work: the hovered zone can be found from the cursor.

Blizzard hover behavior:

- Zone map (Elwynn Forest, cursor over Northshire; screenshot 191151): Blizzard shows the hovered sub-area's name ("Northshire Valley") as a large label at the top left of the map. No tooltip near the cursor.
- Continent map (Eastern Kingdoms, breadcrumb "World > Eastern Kingdoms"; screenshots 191458, 191506): hovering a zone shows its name as the same top-left label ("Dun Morogh"), and the zone appears lighter than its neighbors (likely a hover highlight). Capitals are drawn as small house icons; hovering the Ironforge icon shows "Ironforge" in the label. No tooltip near the cursor.
- Conclusion: Blizzard shows only a one-line name label (plus a highlight) on hover, as in Classic Era. Lodestar's own zone tooltip does not duplicate anything.

Blizzard hover behavior:

### P8: difficulty colors

```
/dump GetQuestDifficultyColor, GetQuestGreenRange and GetQuestGreenRange()
/dump GetQuestDifficultyColor(UnitLevel("player") + 3)
```

The second line should be orange.

Result (2026-10-12, beta, character level 18; screenshot 191846):

```
Dump: value=GetQuestDifficultyColor, GetQuestGreenRange and GetQuestGreenRange()
[1]=<function [GetQuestDifficultyColor]>

Dump: value=GetQuestDifficultyColor(UnitLevel("player") + 3)
[1]={
  b=0.25,
  font="QuestDifficulty_VeryDifficult",
  g=0.5,
  r=1
},
[2]={
  b=0.44,
  font="QuestDifficulty_VeryDifficult",
  g=0.75,
  r=1
}
```

- `GetQuestDifficultyColor` exists. For level + 3 it returns orange (`r=1, g=0.5, b=0.25`, font `QuestDifficulty_VeryDifficult`) as the first value, and a second, lighter orange table (`r=1, g=0.75, b=0.44`, same font), likely the highlight color.
- `GetQuestGreenRange` is **missing**: `/dump GetQuestGreenRange == nil` returned `[1]=true` (reported by the user, no screenshot). The `Logic.lua` fallback derives the green range from the Classic grey-level formula; it is only used if `GetQuestDifficultyColor` is missing, which it is not.
- `UnitLevel("player")` works.

### P9: native zone levels (A6)

Open the world map, look at continent and zone maps, and hover zones. Does Blizzard already show level ranges anywhere? Screenshot what you see.

Result (2026-10-12, beta): **no native zone levels anywhere** on the map.

- Continent map, zone map and hover label show zone names only (screenshots 183458, 191151, 191333, 191458, 191506).
- Breadcrumb zone dropdown (Eastern Kingdoms, screenshot 192117): the 26 zones of P5, in alphabetical order, names only, no levels.
- A6 holds: Lodestar's level labels do not duplicate a native feature.

## Data probes (need the M2 skeleton)

### P10: zone IDs vs seeded table (A5)

`/ls dump` on each continent map. Note missing zones (Mount Hyjal 2482, Riverglades 2548, Shen'dralas 2652) and IDs that differ from vanilla. Zephras Isle (2521) is not on a continent: run `/ls dump` while standing on the island.

Result:

Part 1 (2026-10-18, beta, through `/ls dump`; full output under P30): the client's zone IDs. Eastern Kingdoms has 26 zones and Kalimdor 23, the same IDs and names as P5; Zephras Isle (2521) is a zone under the world map with no child zones. Every vanilla ID matches Classic Era; the Forever additions are Riverglades (2548), Mount Hyjal (2482), Shen'dralas (2652) and Zephras Isle (2521). Part 2, comparing these with `Data/Zones.lua`, waits until that table is seeded (M0).

Part 2 (2026-10-18): `Data/Zones.lua` was seeded from these rows, so its IDs match the client by construction; `tests/zones_spec.lua` fails if a dumped zone is missing or an extra one appears.

### P11: level ranges

Only ranges that differ from the seeded table, or all of them if `GetMapLevels` is missing.

Result:

### P12: new instance entrances

At each entrance:

```
/dump C_Map.GetBestMapForUnit("player"), C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY()
```

If the map is not a zone map, check with `/dump C_Map.GetMapInfo(<id>).mapType` (should be 3) and use the zone map's cursor position instead.

Line used from 2026-10-19 (prints map ID, name, type and position in one go):

```
/run local m=C_Map.GetBestMapForUnit("player") local i=C_Map.GetMapInfo(m) local x,y=C_Map.GetPlayerMapPosition(m,"player"):GetXY() print(m,i.name,i.mapType,x,y)
```

| Instance | Map ID | x | y | Notes |
| --- | --- | --- | --- | --- |
| Hall of Thanes | 1455 Ironforge (type 3) | 0.28077 | 0.47070 | 2026-10-19, beta, standing in front of the dungeon's meeting stone (screenshot 010643; first reported as the portal, corrected by the user); the zone is Ironforge, not Dun Morogh |
| Excavation Site: Wetlands | 1437 Wetlands (type 3) | 0.53649 | 0.65965 | 2026-10-19, beta, standing at the dungeon's **meeting stone**, not the portal (screenshot 012839); "Discovered Thelgen Rock" on arrival, so the portal is likely in or by the Thelgen Rock cave; the level 18 character could not go further |
| The Stockade (vanilla) | 1453 Stormwind City (type 3) | 0.53353 | 0.70861 | 2026-10-19, beta, at the dungeon's meeting stone, which stands just outside the door of the building that holds the prison (screenshot 013104; user), so it marks the entrance well. The seeded approximate value (Claude's recall, 0.405, 0.559) was about 0.13 and 0.15 off, so recalled entrances can be badly wrong: check each one in game before trusting its marker |
| Ragefire Chasm (vanilla) | 1454 Orgrimmar (type 3) | 0.51230 | 0.48991 | 2026-10-19, beta, Horde character at the dungeon's meeting stone (screenshot 014823). The seeded approximate value (0.513, 0.500) was close, within 0.001 and 0.010 |
| City of Dalaran | 1416 Alterac Mountains (type 3) | 0.089 | 0.577 | 2026-10-19, beta, at the dungeon's meeting stone, read with `/ls probe here` (P34; screenshot 190032), so three decimals only. Confirms the zone assumed when seeding: Alterac Mountains, not Hillsbrad Foothills. The user reached it by travelling from Southshore, since the portal was gone |
| Ruins of Lordaeron | 1458 Undercity (type 3) | 0.70740 | 0.17820 | 2026-10-19, beta, Horde character standing in front of the dungeon's meeting stone (screenshot 015445; first reported as the portal, corrected by the user). The entrance is in Undercity, not in Tirisfal Glades as the guides said |

- City of Dalaran: the user's portal to Dalaran was no longer available on 2026-10-19 (probably disabled); the meeting stone was reached over land the same evening (row above).
- From 2026-10-19 on, readings use `/ls probe here` (P34) instead of the `/run` line: same values, rounded to three decimals, and saved in the log.

## Other probes

### P13: exploration API (v2)

```
/dump C_MapExplorationInfo
```

Result:

```
```

### P14: map in combat (after M4, repeat at M5)

Open the map in combat; no errors should appear.

Result:

### P15: taint log (after M4, repeat at M5)

`/console taintLog 1`, `/reload`, then open and close the map in combat and use an action bar ability while still in combat. No "Interface action failed because of an AddOn" message, and no Lodestar lines in `Logs/taint.log`. Afterwards `/console taintLog 0`.

Result:

## API probes (before M2)

Globals and widget features the code will use that P1-P9 did not cover. Each line fits in the chat box (255 characters); copy and paste it as is. `type(x)` keeps the output short: `function`, `table` or `nil`. Frames made by these `/run` lines live until the next `/reload`.

### P16: core APIs for M2 (events, hooks, chat, slash command, copy window)

a. Globals exist; expect `function, function, table, table, table, table`:

```
/dump type(CreateFrame), type(hooksecurefunc), type(UIParent), type(DEFAULT_CHAT_FRAME), type(UISpecialFrames), type(SlashCmdList)
```

b. Time functions for the log; expect `function, function`, the current date and time, `function`:

```
/dump type(time), type(date), date("%Y-%m-%d %H:%M:%S"), type(GetTime)
```

c. Event frame; then target or untarget something. Expect `event PLAYER_TARGET_CHANGED` in chat:

```
/run local f = CreateFrame("Frame"); f:RegisterEvent("PLAYER_TARGET_CHANGED"); f:SetScript("OnEvent", function(_, e) print("event", e) end)
```

d. Map hooks; then open the map, click into another map, and close it. Expect `map OnShow`, `map changed <id>`, `map OnHide`:

```
/run WorldMapFrame:HookScript("OnShow", function() print("map OnShow") end); WorldMapFrame:HookScript("OnHide", function() print("map OnHide") end)
/run hooksecurefunc(WorldMapFrame, "OnMapChanged", function(self) print("map changed", self:GetMapID()) end)
```

e. Colored chat line; expect "Lodestar" in green. Write `|` as `\124` in `/run` lines (see the result):

```
/run DEFAULT_CHAT_FRAME:AddMessage("\124cff33ff99Lodestar\124r probe: colored text")
```

f. Slash commands. First type `/ls` and then `/lodestar` on their own: both should be unknown commands, so the names are free. Then register a test command and run `/lsprobe hello`; expect `slash ok: hello`:

```
/run SLASH_LSPROBE1 = "/lsprobe"; SlashCmdList.LSPROBE = function(msg) print("slash ok:", msg) end
```

g. Copy window building blocks; each line should print `true` for every value:

```
/run local e = CreateFrame("EditBox", nil, UIParent); print("EditBox", e.SetMultiLine ~= nil, e.HighlightText ~= nil, e.SetAutoFocus ~= nil)
/run local s = CreateFrame("ScrollFrame", nil, UIParent, "UIPanelScrollFrameTemplate"); print("ScrollTemplate", s.ScrollBar ~= nil)
/run local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset"); f:Hide(); print("BasicTemplate", f.CloseButton ~= nil)
/run local b = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); print("Backdrop", b.SetBackdrop ~= nil)
```

Result:

a. (2026-10-13, beta; screenshot 231116)

```
Dump: value=type(CreateFrame), type(hooksecurefunc), type(UIParent), type(DEFAULT_CHAT_FRAME), type(UISpecialFrames), type(SlashCmdList)
[1]="function",
[2]="function",
[3]="table",
[4]="table",
[5]="table",
[6]="table"
```

- All six exist with the expected types.

b. (2026-10-13, beta; screenshot 231243)

```
Dump: value=type(time), type(date), date("%Y-%m-%d %H:%M:%S"), type(GetTime)
[1]="function",
[2]="function",
[3]="2026-10-13 23:12:34",
[4]="function"
```

- `time`, `date` and `GetTime` exist; `date` takes a format string and returns local time, so log entries can carry a readable timestamp.

c. (2026-10-13, beta; reported by the user, no screenshot): after targeting an NPC, chat printed `event PLAYER_TARGET_CHANGED`.

- A frame made with `CreateFrame("Frame")` receives events through `RegisterEvent` and `SetScript("OnEvent", ...)`: the core's single event frame works as designed.

d. (2026-10-13, beta; screenshot 231834; map opened in Stormwind, then up to Eastern Kingdoms, then closed)

```
map changed 1453
map OnShow
map changed 1415
map OnHide
```

- `WorldMapFrame:HookScript("OnShow" / "OnHide", ...)` and `hooksecurefunc(WorldMapFrame, "OnMapChanged", ...)` both work, with no error: the beta's map has an `OnMapChanged` method, so the P3 fallback in the design doc holds.
- **Order on open: `OnMapChanged` fires before `OnShow`.** The map picks the player's map (1453, Stormwind City) first, then shows. Code that runs on map change must not assume the map tick (started in `OnShow`) is already running.
- Navigating to the continent fired `OnMapChanged` with 1415 (Eastern Kingdoms); `self:GetMapID()` inside the hook returns the new map.

e. (2026-10-13, beta; screenshots 232039, 232212)

- First run with a literal `|` in the `/run` line: chat printed `|cff33ff99Lodestar|r probe: colored text` as plain text. **The chat box doubles every `|` typed or pasted into it** (to stop fake links), so the color code arrives as `||c...` and shows literally. This affects only text typed into chat, not addon files.
- Rerun with `\124` (Lua's byte escape for `|`) instead of `|`: "Lodestar" in green, then "probe: colored text" in the default color. `DEFAULT_CHAT_FRAME:AddMessage` works and renders `|cffRRGGBB...|r` color codes.
- For future probes: any `/run` line with a color code or link must write `|` as `\124`.

f. (2026-10-13, beta; screenshots 232414, 232513)

```
/ls          -> Type '/help' for a listing of a few commands.
/lodestar    -> Type '/help' for a listing of a few commands.
/lsprobe hello  (after registering it)
slash ok: hello
```

- `/ls` and `/lodestar` are unknown to the game: both names are free for Lodestar.
- Registering through `SLASH_<NAME>1` and `SlashCmdList.<NAME>` works; the handler gets the text after the command (`hello`).

g. (2026-10-13, beta; screenshot 232728)

```
EditBox true true true
ScrollTemplate true
BasicTemplate true
Backdrop true
```

- `CreateFrame("EditBox")` has `SetMultiLine`, `HighlightText` and `SetAutoFocus`; the templates `UIPanelScrollFrameTemplate` (has `.ScrollBar`), `BasicFrameTemplateWithInset` (has `.CloseButton`) and `BackdropTemplate` (has `SetBackdrop`) all exist. Every piece of the copy window is available.

P16 conclusion: every API M2 needs (core event frame, map hooks, chat output, slash commands, log timestamps, copy window) works on the beta. One gotcha: `|` must be written `\124` in `/run` lines typed into chat.

### P17: overlay APIs for M4-M5

Checked now because there is no client between the beta's end (Oct 21) and launch (Nov 4).

a. Mixins, map and tooltip globals; expect `function, function, table, function, function, table`:

```
/dump type(CreateFromMixins), type(Mixin), type(MapCanvasDataProviderMixin), type(WorldMapFrame.RemoveDataProvider), type(WorldMapFrame.RemoveAllPinsByTemplate), type(GameTooltip)
```

b. Pin methods and player position; expect `function, function, function`:

```
/dump type(MapCanvasPinMixin.SetPosition), type(MapCanvasPinMixin.SetScalingLimits), type(C_Map.GetPlayerMapPosition)
```

c. Own tooltip from the Blizzard template; expect `GameTooltipTemplate true true`:

```
/run local t = CreateFrame("GameTooltip", "LodestarProbeTip", UIParent, "GameTooltipTemplate"); print("GameTooltipTemplate", t.AddLine ~= nil, _G.LodestarProbeTipTextLeft1 ~= nil)
```

Result:

a. (2026-10-13, beta; screenshot 232908)

```
Dump: value=type(CreateFromMixins), type(Mixin), type(MapCanvasDataProviderMixin), type(WorldMapFrame.RemoveDataProvider), type(WorldMapFrame.RemoveAllPinsByTemplate), type(GameTooltip)
[1]="function",
[2]="function",
[3]="table",
[4]="function",
[5]="function",
[6]="table"
```

- All six exist with the expected types: overlays can build their data provider with `CreateFromMixins(MapCanvasDataProviderMixin)`, add and remove it, and clear their pins by template; `GameTooltip` is available for instance pins.

b. (2026-10-13, beta; screenshot 232949)

```
Dump: value=type(MapCanvasPinMixin.SetPosition), type(MapCanvasPinMixin.SetScalingLimits), type(C_Map.GetPlayerMapPosition)
[1]="function",
[2]="function",
[3]="function"
```

- Pins can place themselves (`SetPosition`) and limit how they scale with zoom (`SetScalingLimits`), as the module specs assume. `C_Map.GetPlayerMapPosition` exists, which P12 (instance entrances) needs.

c. (2026-10-13, beta; screenshot 233038)

```
GameTooltipTemplate true true
```

- `CreateFrame("GameTooltip", name, UIParent, "GameTooltipTemplate")` works and creates the template's named lines (`<name>TextLeft1`): Lodestar's own `LodestarTooltip` can be built this way.

P17 conclusion: every overlay API the M4-M5 module specs use exists on the beta.

### P18: first load and PLAYER_LOGIN (M2 step 2.1)

`Lodestar.toc` (`## Interface: 16001`, files `Logic.lua`, `Core.lua`) through the junction; `Core.lua` registers `PLAYER_LOGIN` on its own frame and prints a line using `GetBuildInfo` and `ns.Logic.FormatCoords`.

Result (2026-10-13, beta; screenshot 234728, after logging in):

```
Lodestar loaded (interface 16001), test: 50.0, 50.0
```

- The game loads the addon from the junction with interface 16001 (A1 holds: `.toc`, Lua 5.1 environment).
- `PLAYER_LOGIN` fires once the character is in the world, before the login chat messages (code of conduct, guild message of the day).
- Files listed in the `.toc` share the `ns` table: `Core.lua` called `FormatCoords` from `Logic.lua`.
- Character select, AddOn List (screenshot 235033): Lodestar is listed and enabled with "Load out of date AddOns" unticked, so 16001 matches the client. The icon next to the name is a red question mark, the placeholder shown when the `.toc` has no `## IconTexture:` line (cosmetic, optional).

### P19: chat printing and safe calls (M2 step 2.2)

`Util.lua` added to the `.toc` after `Logic.lua`, with `ns.Print(...)` (green `Lodestar:` prefix through `DEFAULT_CHAT_FRAME:AddMessage`) and `ns.SafeCall(fn, ...)` (`pcall`, prints caught errors in red). `Core.lua` printed the hello through `ns.Print`, then ran two temporary test calls: one raising `error("SafeCall test")`, one returning `a + b, "x"` for `2, 3`.

Result (2026-10-14, beta; screenshot 234230, after `/reload`):

```
Lodestar: loaded (interface 16001), test: 50.0, 50.0
Lodestar: Error: Interface/AddOns/Lodestar/Core.lua:10: SafeCall test
Lodestar: true 5 x
```

- `|cff33ff99` (prefix) and `|cffff4040` (`Error:`) render as colors from an addon file; no `\124` needed outside chat input.
- `pcall` catches the error: no error popup, and the next line still runs.
- Error messages name the file as `Interface/AddOns/Lodestar/<file>:<line>:`, with forward slashes. The long line wraps in the chat frame.
- `SafeCall` passes on all of the function's return values (`true 5 x`).

### P20: SavedVariables defaults (M2 step 2.3)

`Core.lua` holds a local `DEFAULTS` table (the design doc schema, `version = 1`). On `PLAYER_LOGIN` it runs `LodestarDB = ns.Logic.MergeDefaults(LodestarDB or {}, DEFAULTS)`, sets `ns.db = LodestarDB` and prints the DB version. Spec: `notes/spec-2.3-saved-variables.md`.

Result (2026-10-15, beta; screenshots 202121 and 202321):

```
Lodestar: loaded (interface 16001), db v1
```

After `/run LodestarDB.modules.Tooltip = false`, `/reload`, `/dump LodestarDB.modules`:

```
Dump: value=LodestarDB.modules
[1]={
  ZoneLabels=true,
  Tooltip=false,
  Instances=true
}
```

`WTF/Account/<ACCOUNT>/SavedVariables/Lodestar.lua` after logout:

```lua
LodestarDB = {
["modules"] = {
["ZoneLabels"] = true,
["Tooltip"] = false,
["Instances"] = true,
},
["log"] = {
},
["version"] = 1,
["waypoints"] = {
},
["overrides"] = {
["zones"] = {
},
},
}
```

- SavedVariables are loaded by `PLAYER_LOGIN`: a value set before `/reload` is there when the handler runs, and the merge keeps it.
- The game writes the file at logout as plain Lua with `["key"] =` syntax, empty tables included, in no fixed key order. Claude Code can read it from the path in `notes/environment.md`.
- `/dump` evaluates a Lua expression: `/dump LodestarDB.modules: Tooltip` fails with "function arguments expected" (`:` is method-call syntax).

### P21: event dispatcher (M2 step 2.4a)

`Core.lua` dispatches every event from its one frame to sets of handlers (`ns.RegisterEvent`, `ns.UnregisterEvent`; `PLAYER_LOGIN` itself goes through the dispatcher). Temporary test: two handlers on `PLAYER_TARGET_CHANGED`, A unregisters itself on its 2nd call, B on its 1st; when the set is empty, the core calls `eventFrame:UnregisterEvent`. Spec: `notes/spec-2.4-core-dispatch.md`.

Result (2026-10-16, beta after the client patch; screenshots 084859, 085045; `/reload`, then four target changes):

```
Lodestar: loaded (interface 16001), db v1
Lodestar: test handler A: PLAYER_TARGET_CHANGED
Lodestar: test handler B: PLAYER_TARGET_CHANGED
Lodestar: test handler A: PLAYER_TARGET_CHANGED
```

- The interface number is still 16001 after the 2026-10-16 client patch.
- One event reaches every handler in the set; a handler can unregister itself during dispatch.
- `frame:UnregisterEvent` exists: the 3rd and 4th target changes printed nothing and raised no error.
- `/reload` resets all Lua state: the test handlers are registered again and the sequence starts over.

### P22: module registry (M2 step 2.4b)

`ns.RegisterModule(name, module)` at file load; on `PLAYER_LOGIN`, after the DB merge, every module with `Logic.IsModuleEnabled(ns.db.modules, name)` gets `OnEnable` through `ns.SafeCall`. Temporary test modules: TestA prints, TestB raises `error("boom")`.

Result (2026-10-16, beta; screenshots 085045, 085549):

```
Lodestar: loaded (interface 16001), db v1
Lodestar: Error: Interface/AddOns/Lodestar/Core.lua:91: boom
Lodestar: TestA enabled
```

After `/run LodestarDB.modules.TestA = false` and `/reload`:

```
Lodestar: loaded (interface 16001), db v1
Lodestar: Error: Interface/AddOns/Lodestar/Core.lua:91: boom
```

- A module's error is caught and printed; the other modules still start, with no error popup.
- Modules start on `PLAYER_LOGIN`, before the game's login messages (code of conduct, guild message of the day).
- `false` in `LodestarDB.modules` skips the module; the SavedVariables file kept `["TestA"] = false` as an extra key next to the defaults.
- Order between modules is not fixed (`pairs`): TestB ran before TestA here.

### P23: map tick (M2 step 2.4c)

On `PLAYER_LOGIN` the core hooks `WorldMapFrame:HookScript("OnShow" / "OnHide", ...)`: `OnShow` resets the accumulator, sets a `tickRunning` flag and `eventFrame:SetScript("OnUpdate", OnUpdate)`; `OnHide` clears both. `OnUpdate(_, elapsed)` runs the tick handlers (`ns.RegisterMapTick`) at most once per 0.1 s, throttled by `Logic.Throttle` (keeps `sum % interval`, so a lag spike fires one tick, not a burst). Temporary test: a tick handler printing every 10th call; the hooks print `ns.IsMapTickRunning()`.

Result (2026-10-16, beta; screenshots 200419, 200556; map opened for a few seconds, closed, opened again, closed):

```
Lodestar: loaded (interface 16001), db v1
Lodestar: OnShow - map tick running: true
Lodestar: map tick 10
Lodestar: map tick 20
Lodestar: map tick 30
Lodestar: map tick 40
Lodestar: OnHide - map tick running: false
Lodestar: OnShow - map tick running: true
Lodestar: map tick 50
Lodestar: map tick 60
Lodestar: map tick 70
Lodestar: map tick 80
Lodestar: OnHide - map tick running: false
```

- The hooks fire on every open and close, and the tick restarts on each open. The test counter is never reset, so it carries on from 40; only the throttle's accumulator is reset in `OnShow`.

- `SetScript("OnUpdate", fn)` on our own frame runs `fn` every frame with the elapsed seconds; `SetScript("OnUpdate", nil)` stops it.
- The tick reaches the registered handler while the map is open and stops when it closes: no `OnUpdate` cost with the map closed (doc success criterion 5).
- Rate: slightly under 10 per second at high frame rates, since six 1/60 s frames sum to just under 0.1 in floating point (smoke test outside the game); "at most once per 0.1 s" as designed.

### P24: slash commands and help (M2 step 2.5a)

`Options.lua` sets `SLASH_LODESTAR1 = "/ls"`, `SLASH_LODESTAR2 = "/lodestar"` and `SlashCmdList.LODESTAR = ns.RunCommand`. `ns.RunCommand` splits the text with `Logic.ParseCommand` (command lowercased, args keep case), prints the sorted help for an empty command, an error for an unknown one, and otherwise runs the handler through `ns.SafeCall`. Temporary test command: `echo`, printing its args joined with ` | `. Spec: `notes/spec-2.5-slash-commands.md`.

Result (2026-10-16, beta; screenshot 225400; fresh login, then `/ls`, `/lodestar`, `/ls   ECHO  Hello   World`, `/ls nope`):

```
Lodestar: /ls echo <words...> - print each word separated by |
Lodestar: /ls echo <words...> - print each word separated by |
Lodestar: Hello | World
Lodestar: Error: unknown command "nope", type /ls for help
```

- `/ls` and `/lodestar` both reach the handler, with the text after the command as the first argument.
- The command matches case-insensitively, extra spaces collapse, and the args keep their case.
- A lone `|` followed by a space or at the end of a line renders as a plain `|` in the chat frame: only `|` followed by an escape letter (`|c`, `|r`, ...) is special.
- After this fresh login the hello line came after the guild message of the day, while P18, P21 and P22 saw it before the login messages. Those were probably fresh logins too (the user usually starts the game from scratch), so the difference is not login vs `/reload`; P26 checks it. Until then, nothing may rely on the order of login chat lines.

### P25: module toggle and debug (M2 step 2.5b)

Core tracks running modules (`runningModules`, marked only when `OnEnable` succeeds) and exposes `ns.GetModuleNames`, `ns.IsModuleRunning` and `ns.SetModuleEnabled` (saves `ns.db.modules[name]`, calls `OnEnable`/`OnDisable` only on a state change). `Options.lua` registers `toggle` (module name through `Logic.FindName`, case-insensitive) and `debug` (session-only `ns.debug`, lists module states and `ns.IsMapTickRunning()`). Temporary test module `TestA` printing `TestA on` / `TestA off`. Spec: `notes/spec-2.5-slash-commands.md`.

Result (2026-10-17, beta; screenshots 003544, 003709, 003857, 004310, 004418):

```
Lodestar: loaded (interface 16001), db v1
Lodestar: TestA on
Lodestar: TestA off                      <- /ls toggle testa
Lodestar: TestA: off
Lodestar: TestA on                       <- /ls toggle TestA
Lodestar: TestA: on
Lodestar: debug on                       <- /ls debug, map closed
Lodestar: TestA: on
Lodestar: map tick running: false
Lodestar: debug off                      <- /ls debug, map open
Lodestar: debug on                       <- /ls debug, map open
Lodestar: TestA: on
Lodestar: map tick running: true
Lodestar: /ls toggle <module> - turn a module on or off. Modules: TestA.   <- /ls toggle
```

- Toggling calls `OnDisable` and `OnEnable` at runtime, and the module name matches case-insensitively.
- `ns.IsMapTickRunning()` reports the map state correctly (false with the map closed, true with it open).
- Persistence: after `/ls toggle TestA` (off) and `/reload`, no `TestA on` at login; the SavedVariables file held `["TestA"] = false`.
- Default: after `/run LodestarDB.modules.TestA = nil` (`/dump LodestarDB.modules` showed only the three default modules) and `/reload`, `TestA on` printed again: a module with no saved setting is enabled.
- The first cleanup `/run` did not take effect (file still had `TestA = false`); the second, checked with `/dump`, did. Check a `/run` edit with `/dump` before relying on it.
- Chat order data point for P26: in the first screenshot (after `/reload`) the hello line came after the guild message of the day.

### P26: login vs /reload chat order (pending)

P24 saw the Lodestar hello line after the guild message of the day on a fresh login; P18, P21 and P22 saw it before the login messages. Check whether the order depends on how the UI loads.

1. Exit the game completely, start it, log in; screenshot the chat.
2. Run `/reload`; screenshot the chat.
3. Repeat both once more.

Record for each run whether the hello line comes before or after the code-of-conduct line and the guild message of the day. Nothing in the design depends on the answer; it only tells whether login output can be expected at a fixed place in chat.

Data point (2026-10-18, P27 screenshot 193029, after `/reload`): the hello line came after the guild message of the day.

### P27: output and log (M2 step 2.6a)

`Util.lua` adds `ns.Record(command, lines)` (keeps the entry as last output and, once `ns.db` exists, appends `{ time, command, lines }` to `ns.db.log` through `Logic.AppendLog`, capped at 50), `ns.Emit(command, lines)` (prints each line, then records), `ns.GetLastOutput()`, and makes `ns.SafeCall` record caught errors as command `"error"`. `Debug.lua` registers `/ls log clear`. Temporary test commands: `emit` (two lines) and `boom` (`error("boom test")`). Spec: `notes/spec-2.6-debug.md`.

Result (2026-10-18, beta; screenshots 193029, 193320):

```
Lodestar: line one                                                  <- /ls emit
Lodestar: line two
Lodestar: Error: Interface/AddOns/Lodestar/Debug.lua:34: boom test  <- /ls boom
Lodestar: log cleared (2 entries)                                   <- /ls log clear, after /reload
```

- After `/reload`, the SavedVariables file held both entries in order: `emit` (`time = "2026-10-18 19:30:07"`, lines `line one`, `line two`) and `error` (`time = "2026-10-18 19:30:15"`, line `Interface/AddOns/Lodestar/Debug.lua:34: boom test`).
- After `/ls log clear` and `/reload`, the file held `["log"] = {}`: replacing `ns.db.log` with a new table is saved, since `ns.db` is `LodestarDB`.
- `date("%Y-%m-%d %H:%M:%S")` gives local time in that format.
- The error message carries the file path and line number (`Debug.lua:34:`) added by `error` at level 1.
- The game writes SavedVariables only on `/reload` or logout: the file did not change between the commands and the next `/reload`, so check the file's time before reading it.

### P28: copy window methods (M2 step 2.6b, no addon)

Checks the frame methods the copy window needs beyond P16g. Lines from `notes/spec-2.6-debug.md`, 2.6b.

Part 1 result (2026-10-18, beta; screenshots 194058, 194720):

```
Frame1 true true true true      <- SetSize, SetPoint, SetMovable, EnableMouse
Frame2 true true true true      <- RegisterForDrag, StartMoving, StopMovingOrSizing, .TitleText
Scroll true true                <- SetScrollChild, SetPoint
EditBox true true true true true  <- SetText, SetFocus, SetFontObject, SetWidth, ChatFontNormal
```

- Every method exists; `ChatFontNormal` is a global font object. Added to `.luacheckrc`.
- **The chat box cuts typed lines at 255 characters.** The first attempt used one 284-character `Frame` line: it printed nothing and showed no error (script errors are not displayed on this client). Split into `Frame1` and `Frame2`, both passed. Keep every `/run` line under 255 characters.

Part 2 result (2026-10-18, beta; screenshot 195553):

```
Frame3 true true true           <- Show, IsShown, TitleText:SetText
DragScripts ok                  <- SetScript with OnDragStart and OnDragStop
EscapeScript ok                 <- SetScript with OnEscapePressed on an EditBox
```

- `Show`, `IsShown` and `SetText` on the template's `TitleText` exist.
- `SetScript` accepts `OnDragStart`, `OnDragStop` (Frame) and `OnEscapePressed` (EditBox): an unknown script name would have raised an error and skipped the print.

P28 conclusion: every API the copy window in the 2.6b spec uses is confirmed on the beta.

### P29: copy window (M2 step 2.6b)

`Logic.FormatOutput(entry)` builds the copy text: a header `"<time> /ls <command>"`, then the entry's lines, joined with `"
"`. `Debug.lua` creates `LodestarCopyFrame` on the first `/ls copy` (`BasicFrameTemplateWithInset`, 520 by 360, centered, draggable, registered in `UISpecialFrames`), with a `UIPanelScrollFrameTemplate` scroll frame whose child is a multi-line `EditBox` (`ChatFontNormal`, width 476, `OnEscapePressed` hides the frame). `/ls copy` prints `nothing to copy yet` without an output, otherwise shows the frame, sets the text, selects it and focuses it; when open, it refreshes. Temporary test command: `emit` with `line 1` to `line 40`. Spec: `notes/spec-2.6-debug.md`.

Result (2026-10-18, beta; screenshot 215205; steps as in the spec, reported by the user as passing):

- The window opens with the title `Lodestar: last output`, the header `2026-10-18 21:51:48 /ls emit` and the lines, all selected; the scroll bar appears since 41 lines are taller than the window.
- Ctrl+C and a paste into Claude Code gave the header and exactly `line 1` to `line 40`: a plain `CreateFrame("EditBox")` has no character limit at this size (about 360 characters), and the line breaks survive the copy.
- Dragging moves the window; `/ls copy` reopens it where it was left (the frame is reused).
- Escape with the cursor in the text closes it through `OnEscapePressed`, and Enter then opens chat normally: the hidden edit box releases the keyboard.
- Escape after clicking the title bar (text not focused) closes it through `UISpecialFrames`; the close button closes it.
- `/ls copy` with the window open refreshes it to the newer output.

### P30: `/ls dump` (M2 step 2.6c)

`Logic.FormatZoneRow(mapID, name, minLevel, maxLevel, today)` builds a `Zones.lua` row (`min`/`max` only when the client has a range above 0; comment `-- <name>, forever, <date>`); `Logic.FindKey(t, value)` turns `info.mapType` into its `Enum.UIMapType` name. `/ls dump` takes the shown map when the world map is open (`WorldMapFrame:GetMapID()`), otherwise the player's map (`C_Map.GetBestMapForUnit("player")`), then emits the map line, its child zones (`C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone)`, sorted by ID) with their client levels (`C_Map.GetMapLevels`), and one row per child, plus one for the map itself when it is a zone. Spec: `notes/spec-2.6-debug.md`.

Result (2026-10-18, beta; read from the SavedVariables log after `/reload`; Stormwind, then the world map open on each map):

```
23:35:09  map 1453 Stormwind City, Zone (player's map)     zones: 0   1 row (itself)
23:35:31  map 1415 Eastern Kingdoms, Continent (shown map)  zones: 26  26 rows
23:35:40  map 1414 Kalimdor, Continent (shown map)          zones: 23  23 rows
23:35:48  map 2521 Zephras Isle, Zone (shown map)           zones: 0   1 row (itself)
```

- Both branches work: map closed gives the player's map, map open gives the shown map.
- **Chat accepts typing while the world map is open**: `/ls dump` runs on whatever map is browsed, from anywhere, no travel and no macro needed.
- The child lists match P5 exactly (IDs and names, including the capitals).
- `client levels: none` for every zone: `GetMapLevels` still returns zeros on the beta (P6), so every row leaves out `min` and `max`.
- `/ls copy` after the four dumps showed the Zephras Isle dump: the copy window holds the last output.
- The dump of Zephras Isle reached through the breadcrumb dropdown gives the island's own row, so it needs no visit.

All 50 zone rows (26 + 23 + Zephras Isle), de-duplicated and sorted by ID (the starting point for seeding `Data/Zones.lua`; `faction` and the level ranges still to fill in):

```lua
[1411] = { faction = "", kind = "zone" },  -- Durotar, forever, 2026-10-18
[1412] = { faction = "", kind = "zone" },  -- Mulgore, forever, 2026-10-18
[1413] = { faction = "", kind = "zone" },  -- The Barrens, forever, 2026-10-18
[1416] = { faction = "", kind = "zone" },  -- Alterac Mountains, forever, 2026-10-18
[1417] = { faction = "", kind = "zone" },  -- Arathi Highlands, forever, 2026-10-18
[1418] = { faction = "", kind = "zone" },  -- Badlands, forever, 2026-10-18
[1419] = { faction = "", kind = "zone" },  -- Blasted Lands, forever, 2026-10-18
[1420] = { faction = "", kind = "zone" },  -- Tirisfal Glades, forever, 2026-10-18
[1421] = { faction = "", kind = "zone" },  -- Silverpine Forest, forever, 2026-10-18
[1422] = { faction = "", kind = "zone" },  -- Western Plaguelands, forever, 2026-10-18
[1423] = { faction = "", kind = "zone" },  -- Eastern Plaguelands, forever, 2026-10-18
[1424] = { faction = "", kind = "zone" },  -- Hillsbrad Foothills, forever, 2026-10-18
[1425] = { faction = "", kind = "zone" },  -- The Hinterlands, forever, 2026-10-18
[1426] = { faction = "", kind = "zone" },  -- Dun Morogh, forever, 2026-10-18
[1427] = { faction = "", kind = "zone" },  -- Searing Gorge, forever, 2026-10-18
[1428] = { faction = "", kind = "zone" },  -- Burning Steppes, forever, 2026-10-18
[1429] = { faction = "", kind = "zone" },  -- Elwynn Forest, forever, 2026-10-18
[1430] = { faction = "", kind = "zone" },  -- Deadwind Pass, forever, 2026-10-18
[1431] = { faction = "", kind = "zone" },  -- Duskwood, forever, 2026-10-18
[1432] = { faction = "", kind = "zone" },  -- Loch Modan, forever, 2026-10-18
[1433] = { faction = "", kind = "zone" },  -- Redridge Mountains, forever, 2026-10-18
[1434] = { faction = "", kind = "zone" },  -- Stranglethorn Vale, forever, 2026-10-18
[1435] = { faction = "", kind = "zone" },  -- Swamp of Sorrows, forever, 2026-10-18
[1436] = { faction = "", kind = "zone" },  -- Westfall, forever, 2026-10-18
[1437] = { faction = "", kind = "zone" },  -- Wetlands, forever, 2026-10-18
[1438] = { faction = "", kind = "zone" },  -- Teldrassil, forever, 2026-10-18
[1439] = { faction = "", kind = "zone" },  -- Darkshore, forever, 2026-10-18
[1440] = { faction = "", kind = "zone" },  -- Ashenvale, forever, 2026-10-18
[1441] = { faction = "", kind = "zone" },  -- Thousand Needles, forever, 2026-10-18
[1442] = { faction = "", kind = "zone" },  -- Stonetalon Mountains, forever, 2026-10-18
[1443] = { faction = "", kind = "zone" },  -- Desolace, forever, 2026-10-18
[1444] = { faction = "", kind = "zone" },  -- Feralas, forever, 2026-10-18
[1445] = { faction = "", kind = "zone" },  -- Dustwallow Marsh, forever, 2026-10-18
[1446] = { faction = "", kind = "zone" },  -- Tanaris, forever, 2026-10-18
[1447] = { faction = "", kind = "zone" },  -- Azshara, forever, 2026-10-18
[1448] = { faction = "", kind = "zone" },  -- Felwood, forever, 2026-10-18
[1449] = { faction = "", kind = "zone" },  -- Un'Goro Crater, forever, 2026-10-18
[1450] = { faction = "", kind = "zone" },  -- Moonglade, forever, 2026-10-18
[1451] = { faction = "", kind = "zone" },  -- Silithus, forever, 2026-10-18
[1452] = { faction = "", kind = "zone" },  -- Winterspring, forever, 2026-10-18
[1453] = { faction = "", kind = "zone" },  -- Stormwind City, forever, 2026-10-18
[1454] = { faction = "", kind = "zone" },  -- Orgrimmar, forever, 2026-10-18
[1455] = { faction = "", kind = "zone" },  -- Ironforge, forever, 2026-10-18
[1456] = { faction = "", kind = "zone" },  -- Thunder Bluff, forever, 2026-10-18
[1457] = { faction = "", kind = "zone" },  -- Darnassus, forever, 2026-10-18
[1458] = { faction = "", kind = "zone" },  -- Undercity, forever, 2026-10-18
[2482] = { faction = "", kind = "zone" },  -- Mount Hyjal, forever, 2026-10-18
[2521] = { faction = "", kind = "zone" },  -- Zephras Isle, forever, 2026-10-18
[2548] = { faction = "", kind = "zone" },  -- Riverglades, forever, 2026-10-18
[2652] = { faction = "", kind = "zone" },  -- Shen'dralas, forever, 2026-10-18
```

### P31: `/ls probe` (M2 step 2.6d)

`Logic.FormatProbe(id, status, detail)` builds `"<id> <status>: <detail>"` with `fail` written `FAIL`. `Debug.lua` keeps a `PROBES` list (P1-P6 and P8, each a function returning status and detail) and runs each through `pcall`, so a probe that raises an error becomes a `FAIL` line; a summary line counts the failures. `/ls probe hover` reports the zone under the cursor (P7). Spec: `notes/spec-2.6-debug.md`.

Result (2026-10-19, beta, level 18 character in Stormwind; screenshots 002050, 002229, 002311; also read from the SavedVariables log):

```
P1 pass: interface 16001
P2 pass: player map 1453 Stormwind City, Zone
P3 pass: data providers and pins available
P4 pass: WorldMapFrame loaded
P5 pass: Eastern Kingdoms 26 zones, Kalimdor 23 zones, Elwynn rect ok
P6 info: Elwynn Forest client levels: none
P8 pass: level 21 is orange (QuestDifficulty_VeryDifficult)
probes: 7, failed: 0
P7 info: cursor 48.1, 70.2 on 1415: 1429 Elwynn Forest     <- /ls probe hover, map open on Eastern Kingdoms
open the world map first                                   <- /ls probe hover, map closed
```

- Every line matches the manual probes (P1-P8) and the counts from P30: the code-run probes agree with the hand-run ones on the beta.
- Hover works by typing `/ls probe hover`, moving the cursor onto the zone, then pressing Enter; no macro needed. The cursor position (48.1, 70.2) falls inside Elwynn's rectangle from P5 (x 41-51 %, y 66-76 %).
- A mistyped `/ls prove` printed `Error: unknown command "prove", type /ls for help` (the 2.5 registry's error path).
- To repeat on the live client after Nov 4: `/ls probe`, the hover check, then `/reload` and compare with this section.

### P32: dungeon entrance API (seeding `Data/Instances.lua`)

Classic Era draws dungeon entrances on zone maps through `C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID)`; if Forever returned data, entrance names and positions could be read from the game instead of seeded by hand.

```
/dump C_EncounterJournal ~= nil, C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap ~= nil
/dump C_EncounterJournal.GetDungeonEntrancesForMap(1436)
/dump C_EncounterJournal.GetDungeonEntrancesForMap(1415)
```

Result (2026-10-19, beta, character in Stormwind; screenshots 003041, 003331, 003525):

```
[1]=true, [2]=true     <- the table and the function exist
[1]={}                 <- Westfall (1436)
[1]={}                 <- Eastern Kingdoms (1415)
```

- **`GetDungeonEntrancesForMap` exists but returns an empty table**, even for Westfall, which has The Deadmines: the same pattern as `GetMapLevels` (P6). Not usable for entrances; not added to `.luacheckrc`.
- A first `/run` loop over the Westfall result printed nothing, consistent with the empty table.
- **The Westfall map shows no dungeon entrance icon** near Moonbrook (screenshot 003525, user has been in The Deadmines). Only quest markers are drawn.
- The map's native readout at the bottom left shows `Cursor: x, y` (percent on the shown map) and `Player: x, y (map)`, so an entrance's position can be read by hovering its spot on the zone map, without travel; `/ls probe hover` gives the same numbers into the log.
- Consequence: vanilla entrances are seeded from public data; the Forever dungeons' entrances need P12 (stand at the entrance, or hover a known spot on the zone map).

### P33: group finder activities (level ranges from the client)

Classic Era's Looking for Group tool lists activities with suggested level ranges (`C_LFGList`). If Forever has it, the client gives level ranges for dungeons, and for the Forever dungeons no public source covers.

```
/dump C_LFGList ~= nil, C_LFGList and C_LFGList.GetAvailableActivities ~= nil
/run local a = C_LFGList.GetAvailableActivities(); print(#a)
/dump C_LFGList.GetActivityInfoTable(C_LFGList.GetAvailableActivities()[1])
/run local a=C_LFGList.GetAvailableActivities() for i=1,24 do local t=C_LFGList.GetActivityInfoTable(a[i]) print(i,t.fullName,t.minLevelSuggestion,t.maxLevelSuggestion,t.maxNumPlayers) end
```

(the last line repeated for 25-48 and 49-71)

Result (2026-10-19, beta, level 18 Alliance character in Stormwind; screenshots 004239, 004356, 004446, 004506):

- `C_LFGList` and `GetAvailableActivities` exist; **71 activities**.
- `GetActivityInfoTable(id)` returns a table with `fullName`, `shortName`, `minLevelSuggestion`, `maxLevelSuggestion`, `minLevel`, `maxNumPlayers`, `mapID`, `categoryID`, `groupFinderActivityGroupID`, `difficultyID`, `displayType`, `filters`, `orderIndex`, `ilvlSuggestion`, `allowCrossFaction`, `useDungeonRoleExpectations`, `redirectedDifficultyID`, `useHonorLevel`, `showQuickJoinToast` and the flags `isHeroicActivity`, `isMythicActivity`, `isMythicPlusActivity`, `isNormalActivity`, `isPvpActivity`, `isRatedPvpActivity`, `isCurrentRaidActivity`. Activity 1 is `Custom` with all zeros.

All 71 (index, fullName, minLevelSuggestion, maxLevelSuggestion, maxNumPlayers):

```
 1 Custom 0 0 0
 2 Alterac Mountains 28 44 0
 3 Silverpine Forest 8 24 0
 4 Tirisfal Glades 1 14 0
 5 Eastern Plaguelands 53 63 0
 6 Western Plaguelands 48 60 0
 7 Hinterlands 38 54 0
 8 Hillsbrad Foothills 18 34 0
 9 Arathi Highlands 28 44 0
10 Badlands 33 50 0
11 Searing Gorge 43 60 0
12 Burning Steppes 48 60 0
13 Redridge Mountains 13 30 0
14 Swamp of Sorrows 33 50 0
15 Blasted Lands 43 60 0
16 Stranglethorn Vale 28 50 0
17 Wetlands 18 34 0
18 Loch Modan 8 24 0
19 Dun Morogh 1 14 0
20 Duskwood 18 34 0
21 Westfall 8 24 0
22 Elwynn Forest 1 14 0
23 Zephras Isle 1 14 0
24 Mount Hyjal 55 60 0
25 Winterspring 53 63 0
26 Azshara 43 60 0
27 Felwood 46 60 0
28 Ashenvale 18 34 0
29 Darkshore 8 24 0
30 Teldrassil 1 14 0
31 Silithus 53 60 0
32 Un'Goro Crater 45 60 0
33 Tanaris 38 54 0
34 Dustwallow Marsh 33 50 0
35 Riverglades 33 54 0
36 Feralas 38 54 0
37 Durotar 1 14 0
38 Mulgore 1 14 0
39 The Barrens 8 30 0
40 Stonetalon Mountains 13 32 0
41 Thousand Needles 23 40 0
42 Desolace 28 44 0
43 Hall of Thanes 13 20 5
44 City of Dalaran 28 35 5
45 Ruins of Lordaeron 15 22 5
46 Excavation Site: Wetlands 26 33 5
47 Stratholme (Service Gate) 58 60 5
48 Upper Blackrock Spire 59 60 10
49 Scarlet Monastery - Library 33 41 5
50 Scarlet Monastery - Cathedral 38 46 5
51 Scarlet Monastery - Armory 36 44 5
52 Stratholme (Main Gate) 58 60 5
53 Dire Maul (North) 56 60 5
54 Dire Maul (West) 56 60 5
55 Dire Maul (East) 54 60 5
56 Lower Blackrock Spire 55 60 5
57 Blackrock Depths 52 60 5
58 Sunken Temple 50 60 5
59 Maraudon 46 55 5
60 Zul'Farrak 44 54 5
61 Uldaman 41 51 5
62 Razorfen Downs 37 46 5
63 Scarlet Monastery - Graveyard 30 38 5
64 Razorfen Kraul 29 38 5
65 Gnomeregan 29 38 5
66 Wailing Caverns 15 24 5
67 Scholomance 58 60 5
68 Deadmines 17 26 5
69 Shadowfang Keep 20 30 5
70 Blackfathom Deeps 24 32 5
71 Stormwind Stockades 24 32 5
```

- **41 zone activities** (players 0), each with Forever's suggested range. They are wider than the Classic wiki ranges seeded in `Data/Zones.lua` (Elwynn 1-14 vs 1-10, Westfall 8-24 vs 10-20) and include the Forever zones: Zephras Isle 1-14, Mount Hyjal 55-60, Riverglades 33-54. Missing: Moonglade, Deadwind Pass, Shen'dralas and the six capitals. Decided 2026-10-19: zone labels use these ranges; `Data/Zones.lua` was updated with all 41 (see the design doc's Zones "Level source").
- **29 dungeons** (players 5, Upper Blackrock Spire 10), one activity per wing (Scarlet Monastery x4, Dire Maul x3, Stratholme x2). Four Forever dungeons are in the beta: Hall of Thanes 13-20, City of Dalaran 28-35, Ruins of Lordaeron 15-22, Excavation Site: Wetlands 26-33.
- **Missing**: Ragefire Chasm for the Alliance character; a Horde character's list has it as `Ragefire Chasm 13 18` (2026-10-19, screenshot 014906), so the group finder lists faction dungeons only to their faction. Also missing: all raids (the guides say raids unlock on 2026-12-09), and the Forever dungeons the guides list but the beta lacks (The Drowned City, Krol'dok Stronghold, Alcaz Island Prison, Blackmaw Hold, Shaper's Terrace).
- Only `minLevelSuggestion`, `maxLevelSuggestion`, `maxNumPlayers` and `fullName` were read per activity; `mapID` was 0 for `Custom` and is not yet checked for a dungeon.
- Not used in addon code yet, so not added to `.luacheckrc`; Claude seeds `Data/Instances.lua` levels from this table.

### P34: `/ls probe here` (M2 step 2.6e)

`/ls probe here` reports the character's own map and position as one `P12 info` line, with a ready-made `x = ..., y = ...` fragment for `Data/Instances.lua` (`Logic.FormatEntrance`, three decimals). It replaces the long `/run` line of P12. Spec: `notes/spec-2.6-debug.md`.

Result (2026-10-19, beta; screenshots 183343, 183529, 190032):

```
P12 info: player 4.7, 57.3 on 1437 Wetlands, Zone: x = 0.047, y = 0.573          <- by Menethil Harbor's docks
P12 info: player 8.9, 57.7 on 1416 Alterac Mountains, Zone: x = 0.089, y = 0.577 <- City of Dalaran meeting stone
```

- **Matches the game's readout**: at Menethil the world map's `Player: 4.7, 57.3` (screenshot 183529) is the same as the readable part of the line.
- **Copy window**: `/ls copy` after the Dalaran reading gave `2026-10-19 19:00:24 /ls probe` and the line above, so readings land in the output kept for `/ls copy` (and the log).
- The spec's comparison at an already measured meeting stone (Hall of Thanes) was not repeated; the match with the map readout covers the same thing, since the `/run` line read the same `GetPlayerMapPosition`.
- The copy header says `/ls probe`, not `/ls probe here`: `Emit` is given the command name only, as for `hover`.
- No "not a zone map" case seen yet (both readings on zone maps).

### P35: zone info and colored ranges (M4 step 4.1)

Spec: `notes/spec-4.1-zone-info.md`. Two parts: the client's difficulty colors (for the fallback table and the `DifficultyKey` rule), then the hover check of 4.1b.

**Difficulty colors** (2026-10-19, beta, level 18 character in Stormwind; screenshots 191328, 191438, 191456, 191512, 191700):

```
/dump GetQuestDifficultyColor(UnitLevel("player") + 5)
/dump GetQuestDifficultyColor(UnitLevel("player"))
/dump GetQuestDifficultyColor(UnitLevel("player") - 4)
/dump GetQuestDifficultyColor(1)
/run local p=UnitLevel("player") for d=-12,0 do local c=GetQuestDifficultyColor(p+d) print(d,p+d,c.font,c.r,c.g,c.b) end
```

| Key | Font | First color `r, g, b` | Second (lighter) `r, g, b` | Source |
| --- | --- | --- | --- | --- |
| red | `QuestDifficulty_Impossible` | 1, 0.1, 0.1 | 1, 0.4, 0.4 | level + 5 |
| orange | `QuestDifficulty_VeryDifficult` | 1, 0.5, 0.25 | 1, 0.75, 0.44 | level + 3 (P8) |
| yellow | `QuestDifficulty_Difficult` | 1, 0.82, 0 | 1, 1, 0.1 | own level, level - 4 |
| green | `QuestDifficulty_Standard` | 0.25, 0.75, 0.25 | not read | the loop, level - 5 |
| grey | `QuestDifficulty_Trivial` | 0.5, 0.5, 0.5 | 0.7, 0.7, 0.7 | level 1 |

The loop (player level 18), diff and level:

```
-12 to -6 (levels 6-12)  Trivial    0.5 0.5 0.5
-5        (level 13)     Standard   0.25 0.75 0.25
-4 to 0   (levels 14-18) Difficult  1 0.82 0
```

- **Yellow reaches 4 levels below, not 2**: Forever's rule is `diff >= -4` for yellow, where the design doc's fallback (Classic's rule) said `diff >= -2`. `Logic.DifficultyKey` and its tests change to match (spec 4.1a).
- **Grey at or below 12 at level 18**, as `Logic.GreyLevel(18) = 18 - 1 - 5 = 12` says: the grey formula holds at this level; checked at one level only.
- So at level 18 green is a single level (13). Not checked: above the player (+1, +2 yellow, +4 orange are assumed from P8's +3 orange and +5 red).
- The five first colors become `FALLBACK_COLORS` in `Util.lua` (4.1b). Labels use the client's own colors anyway, since `GetQuestDifficultyColor` exists.

**Hover check** (2026-10-19, beta, level 18 character; screenshot 222659). `/ls probe hover` with the world map on Eastern Kingdoms:

```
P7 info: cursor 39.0, 0.0 on 1415: no zone
P7 info: cursor 45.7, 70.3 on 1415: 1429 Elwynn Forest, 1-14 (table)        <- 1 grey, 14 yellow
P7 info: cursor 54.8, 70.2 on 1415: 1433 Redridge Mountains, 13-30 (table)  <- 13 green, 30 red
P7 info: cursor 46.6, 30.2 on 1415: 1416 Alterac Mountains, 28-44 (table)   <- both red
```


- Every color matches the client's bands at level 18: 12 and below grey, 13 green, 14-18 yellow (the loop above), and red from 23 (level + 5). Redridge's 13 is the single green level, so the wider yellow band (`DifficultyKey` change in 4.1a) and the client agree in game.
- Source `table` everywhere, as expected: `GetMapLevels` still returns zeros (P6) and no override is saved.
- Not hovered in game: a city (Stormwind, `no level data`) and Burning Steppes. Both were checked outside the game the same evening with the real `Logic.lua`, `Util.lua`, `Core.lua` and `Data/Zones.lua` and stubbed WoW functions, which also showed the fallback colors (`GetQuestDifficultyColor` removed) giving the same result as the client at level 18.
- The SavedVariables log (after the next `/reload`, 22:27) has the same four lines with the raw codes: grey `|cff808080`, yellow `|cffffd100`, green `|cff40bf40`, red `|cffff1a1a`, the client's P35 colors through `Logic.ColorCode`.

### P36: pin hooks, pin template, label fonts (M4 step 4.2a)

The pieces the ZoneLabels pin needs that P3 and P17 did not cover. Spec: `notes/spec-4.2-zone-labels.md`.

Result (2026-10-19, beta; screenshots 223511, 223636, 223914):

```
/dump type(MapCanvasPinMixin.OnAcquired), type(MapCanvasPinMixin.SetScalingLimits), type(MapCanvasDataProviderMixin.RefreshAllData), type(MapCanvasDataProviderMixin.RemoveAllData)
[1]="function", [2]="function", [3]="function", [4]="function"

/dump C_XMLUtil and C_XMLUtil.GetTemplateInfo("MapCanvasPinTemplate")
empty result

/dump type(GameFontHighlightOutline), type(GameFontNormalOutline)
[1]="table", [2]="table"

/dump C_XMLUtil ~= nil, C_XMLUtil and C_XMLUtil.GetTemplateInfo("GameTooltipTemplate")
[1]=true,
[2]={ inherits="SharedTooltipTemplate", type="GameTooltip", keyValues={ { key="supportsDataRefresh", type="boolean", value="true", keyType="string" } },
      height=0, width=0, sourceLocation="Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.xml:4" }

/run for _,n in ipairs({"MapCanvasPinTemplate","AreaPOIPinTemplate","DungeonEntrancePinTemplate"}) do local t=C_XMLUtil.GetTemplateInfo(n) print(n, t and t.type, t and t.inherits, t and t.sourceLocation) end
MapCanvasPinTemplate nil nil nil
AreaPOIPinTemplate Frame LegendHighlightableMapPoiPinTemplate, BaseSuperTrackableMapPoiPinTemplate Interface/AddOns/Blizzard_SharedMapDataProviders/AreaPOIDataProvider.xml:5
DungeonEntrancePinTemplate Frame LegendHighlightableMapPoiPinTemplate, BaseSuperTrackableMapPoiPinTemplate Interface/AddOns/Blizzard_SharedMapDataProviders/DungeonEntranceDataProvider.xml:5
```

- The pin hook `OnAcquired`, `SetScalingLimits`, and the provider's `RefreshAllData` and `RemoveAllData` exist.
- `GameFontHighlightOutline` and `GameFontNormalOutline` exist: font objects for the label text.
- **`MapCanvasPinTemplate` does not exist.** `C_XMLUtil.GetTemplateInfo` works (it finds `GameTooltipTemplate`), so its `nil` for that name is real. Blizzard's own map pins are `Frame` templates that inherit only POI-specific templates (legend highlight, super-tracking), not a common pin base. Lodestar's pin template is therefore a plain virtual `Frame` with its mixin; the design doc and spec 4.2 are changed.
- **Forever's Blizzard UI is the Mainline (retail) code**: `GameTooltip.xml` loads from `Blizzard_GameTooltip/Mainline/`. The APIs probed so far match Classic Era, but templates and frame details can follow retail, so each one is checked before use (design doc, "Target client and API assumptions").
- `C_XMLUtil.GetTemplateInfo(name)` is a handy probe for any template: it returns `type`, `inherits` and `sourceLocation`. Not used in addon code, so not in `.luacheckrc`.

### P37: ZoneLabels test pin (M4 step 4.2a)

`Modules/ZoneLabels.lua` adds a data provider that, on a continent map, acquires one pin from `LodestarZoneLabelPinTemplate` (`Pins.xml`: a plain virtual `Frame` with the mixin, no base template, P36) with the text `TEST` at 0.5, 0.5. Spec: `notes/spec-4.2-zone-labels.md`.

Result (2026-10-19, beta, level 18 character in Stormwind; screenshots 225843, 225851, 225859, 225923, 225954; script errors on):

- Eastern Kingdoms and Kalimdor: `TEST` at the center of each, white with an outline. Switching between them moves it, so the map calls `RefreshAllData` on a map change.
- Zone maps (Elwynn Forest, Zephras Isle) and the world map: no `TEST`. Zephras Isle is reached from the same breadcrumb dropdown as the continents but is a zone map (P5), so the provider is right to skip it.
- Clicking the zone under `TEST` zooms into it: the pin does not take the mouse (`enableMouse="false"`).
- Zooming in keeps the text about the same size while the map grows (`SetScalingLimits(1, 1.0, 1.2)`).
- `/ls toggle ZoneLabels` off removes the pin on the next map open; on brings it back, no `/reload`: `RemoveDataProvider` and `AddDataProvider` work at runtime.
- No errors.
- So a pin template with no base template works with the map's pin pool on Forever: the overlay design holds (assumption A3 in practice, not only by function names).
- For 4.3: the text is small next to Blizzard's lettering; Blizzard draws small building icons on the continent maps (one sits just under the center), so real labels may meet some of them.

### P38: ZoneLabels, one label per zone (M4 step 4.2b)

`RefreshAllData` labels every child zone of the shown continent that has a range (`ns.GetZoneInfo`, `Logic.FormatLevelRange`) and a rectangle on it (`ns.GetZoneRect`, cached), at `Logic.LabelPosition` (the rectangle center unless `labelX, labelY` are set). Spec: `notes/spec-4.2-zone-labels.md`.

Result (2026-10-19, beta, level 18 character; screenshots 232203, 232213, 232235):

- **Eastern Kingdoms: 23 labels**, one per zone, none on Stormwind, Ironforge or Undercity (26 children minus the 3 capitals).
- **Kalimdor: 19 labels**, none on the three capitals or Shen'dralas (no range); Teldrassil's island and Mount Hyjal labeled.
- **Colors** match level 18 (P35): Stonetalon 13-32 and Redridge 13-30 green to red, Wetlands and Hillsbrad 18-34 yellow to red, the 1-14 and 8-24 zones grey at the low end.
- **Zone map** (Elwynn Forest): no labels (`Westfall` at its top is Blizzard's hover name).
- Same counts as the smoke test outside the game the same evening (real Lua files, P5's child lists, stubbed rectangles): 23, 19, 0.

Problems for step 4.3:

- **Overlapping labels** where a small zone's rectangle center lands near a neighbor's: Searing Gorge 43-60 and Badlands 33-50; Duskwood 18-34 and Deadwind Pass 55-60; Felwood 46-60 and Moonglade 55-60 (Moonglade lies inside Felwood's rectangle).
- **Labels on Blizzard's capital icons** in the zones that hold a capital: Tirisfal Glades (Undercity), Dun Morogh (Ironforge), Durotar (Orgrimmar), Mulgore (Thunder Bluff), Teldrassil (Darnassus). Readable, but crowded.
- The player arrow is drawn above the labels (Elwynn's `1` hidden under it): expected wherever the player stands; no change planned.
- Fix in the design: `labelX, labelY` in `Data/Zones.lua` for the zones above, read off the map's `Cursor:` readout.

### P39: zone names on the maximized map (M4 step 4.3, first iteration)

Names plus ranges were tried on every label after P38. In the small Map & Quest Log window they overlapped badly (screenshots 233840, 233848); on the maximized map they read well (233953), since the labels keep their screen size while the map doubles. Shrinking every label with `SetScalingLimits(1, 0.75, 1.0)` made them hard to read on the maximized map (234149) and was reverted. Decided with the user: **names only on the maximized map**, ranges only in the small window; zone details on hover come from the M5 Tooltip. Hand-placed `labelX, labelY` were rejected for now: they need upkeep if maps change.

Code written by Claude at the user's request for fast iteration (2026-10-19): `Pins.xml` gets a `Name` FontString anchored above `Label` (`relativeKey="$parent.Label"`), with `Label` centered on the pin; `RefreshAllData` passes the zone name only when `WorldMapFrame:IsMaximized()`.

Result (2026-10-19, beta, level 18 character; screenshots 234400, 234638, 234649, 235131, 235651, 235658):

```
/dump type(WorldMapFrame.IsMaximized), WorldMapFrame:IsMaximized()
[1]="function", [2]=false        <- small window; true when maximized (user)

/dump type(WorldMapFrame.Maximize), type(WorldMapFrame.Minimize)
[1]="function", [2]="function"
```

- `WorldMapFrame:IsMaximized()` exists and tells the two window sizes apart.
- **The map does not refresh data providers on maximize or minimize**: names appeared only after a continent switch. Fixed with `hooksecurefunc(WorldMapFrame, "Maximize" / "Minimize", ...)`, installed once, which calls `RefreshAllData` while the module is enabled and the map shown; names now follow the window size at once.
- **`AddDataProvider` does not draw on a map that is already open**: after `/ls toggle ZoneLabels` off and on with the map open, labels came back only after a continent switch. `OnEnable` now calls `RefreshAllData` when the map is shown, and `OnDisable` calls `RemoveAllData` before `RemoveDataProvider`; toggling now works at once in both sizes.
- The ranges sit at the zone centers in both sizes; names hang above them on the maximized map.
- Still overlapping: Duskwood, Deadwind Pass and Swamp of Sorrows (both sizes); Searing Gorge and Badlands (small window). Candidate fix: automatic collision handling (nudge or hide), not hand-placed positions.

