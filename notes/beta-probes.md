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
| P16 | M2 APIs | [x] | 2026-10-13 | beta |
| P17 | M4-M5 APIs | [x] | 2026-10-13 | beta |
| P18 | A1, load | [x] | 2026-10-13 | beta |
| P19 | M2 chat, safe calls | [x] | 2026-10-14 | beta |

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
