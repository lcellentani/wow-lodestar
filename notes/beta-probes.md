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
| P10 | A5 | [ ] | | |
| P11 | data | [ ] | | |
| P12 | data | [ ] | | |
| P13 | v2 | [ ] | | |
| P14 | taint | [ ] | | |
| P15 | taint | [ ] | | |

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

### P11: level ranges

Only ranges that differ from the seeded table, or all of them if `GetMapLevels` is missing.

Result:

### P12: new instance entrances

At each entrance:

```
/dump C_Map.GetBestMapForUnit("player"), C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player"):GetXY()
```

If the map is not a zone map, check with `/dump C_Map.GetMapInfo(<id>).mapType` (should be 3) and use the zone map's cursor position instead.

| Instance | Map ID | x | y | Notes |
| --- | --- | --- | --- | --- |

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
