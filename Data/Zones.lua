local addonName, ns = ...

-- Zone data keyed by uiMapID. IDs from /ls dump on the beta (P30, 2026-10-18).
-- Levels: the beta's group finder (C_LFGList suggested ranges, P33, 2026-10-19) for the
-- 41 zones it lists; it can go above the level cap (53-63). Moonglade, Deadwind Pass and
-- Shen'dralas are not listed there and keep the earlier sources: Warcraft Wiki
-- "Zones by level (Classic)" and third-party guides.
-- Factions: Warcraft Wiki "Classic zones" (PvP status); Forever zones unknown ("").
-- [uiMapID] = { [min, max,] faction, kind [, labelX, labelY] }
-- faction: "Alliance" | "Horde" | "Contested" | "" (unknown, fill in game); kind: "zone" | "city"
ns.Zones = {
  -- Kalimdor (1414)
  [1411] = { min = 1,  max = 14, faction = "Horde",     kind = "zone" },  -- Durotar, forever, group finder P33
  [1412] = { min = 1,  max = 14, faction = "Horde",     kind = "zone" },  -- Mulgore, forever, group finder P33
  [1413] = { min = 8,  max = 30, faction = "Horde",     kind = "zone" },  -- The Barrens, forever, group finder P33
  [1438] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone" },  -- Teldrassil, forever, group finder P33
  [1439] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone" },  -- Darkshore, forever, group finder P33
  [1440] = { min = 18, max = 34, faction = "Contested", kind = "zone" },  -- Ashenvale, forever, group finder P33
  [1441] = { min = 23, max = 40, faction = "Contested", kind = "zone" },  -- Thousand Needles, forever, group finder P33
  [1442] = { min = 13, max = 32, faction = "Contested", kind = "zone" },  -- Stonetalon Mountains, forever, group finder P33
  [1443] = { min = 28, max = 44, faction = "Contested", kind = "zone" },  -- Desolace, forever, group finder P33
  [1444] = { min = 38, max = 54, faction = "Contested", kind = "zone" },  -- Feralas, forever, group finder P33
  [1445] = { min = 33, max = 50, faction = "Contested", kind = "zone" },  -- Dustwallow Marsh, forever, group finder P33
  [1446] = { min = 38, max = 54, faction = "Contested", kind = "zone" },  -- Tanaris, forever, group finder P33
  [1447] = { min = 43, max = 60, faction = "Contested", kind = "zone" },  -- Azshara, forever, group finder P33
  [1448] = { min = 46, max = 60, faction = "Contested", kind = "zone" },  -- Felwood, forever, group finder P33
  [1449] = { min = 45, max = 60, faction = "Contested", kind = "zone" },  -- Un'Goro Crater, forever, group finder P33
  [1450] = { min = 55, max = 60, faction = "Contested", kind = "zone" },  -- Moonglade, vanilla, unverified (not in the group finder; wiki "Classic zones": no range)
  [1451] = { min = 53, max = 60, faction = "Contested", kind = "zone" },  -- Silithus, forever, group finder P33
  [1452] = { min = 53, max = 63, faction = "Contested", kind = "zone" },  -- Winterspring, forever, group finder P33
  [1454] = { faction = "Horde",    kind = "city" },  -- Orgrimmar, vanilla, unverified
  [1456] = { faction = "Horde",    kind = "city" },  -- Thunder Bluff, vanilla, unverified
  [1457] = { faction = "Alliance", kind = "city" },  -- Darnassus, vanilla, unverified
  [2482] = { min = 55, max = 60, faction = "", kind = "zone" },  -- Mount Hyjal, forever, group finder P33
  [2652] = { faction = "", kind = "zone" },  -- Shen'dralas, forever, unverified (not in the group finder; guides disagree on the range)

  -- Eastern Kingdoms (1415)
  [1416] = { min = 28, max = 44, faction = "Contested", kind = "zone" },  -- Alterac Mountains, forever, group finder P33
  [1417] = { min = 28, max = 44, faction = "Contested", kind = "zone" },  -- Arathi Highlands, forever, group finder P33
  [1418] = { min = 33, max = 50, faction = "Contested", kind = "zone" },  -- Badlands, forever, group finder P33
  [1419] = { min = 43, max = 60, faction = "Contested", kind = "zone" },  -- Blasted Lands, forever, group finder P33
  [1420] = { min = 1,  max = 14, faction = "Horde",     kind = "zone" },  -- Tirisfal Glades, forever, group finder P33
  [1421] = { min = 8,  max = 24, faction = "Horde",     kind = "zone" },  -- Silverpine Forest, forever, group finder P33
  [1422] = { min = 48, max = 60, faction = "Contested", kind = "zone" },  -- Western Plaguelands, forever, group finder P33
  [1423] = { min = 53, max = 63, faction = "Contested", kind = "zone" },  -- Eastern Plaguelands, forever, group finder P33
  [1424] = { min = 18, max = 34, faction = "Contested", kind = "zone" },  -- Hillsbrad Foothills, forever, group finder P33
  [1425] = { min = 38, max = 54, faction = "Contested", kind = "zone" },  -- The Hinterlands, forever, group finder P33
  [1426] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone" },  -- Dun Morogh, forever, group finder P33
  [1427] = { min = 43, max = 60, faction = "Contested", kind = "zone" },  -- Searing Gorge, forever, group finder P33
  [1428] = { min = 48, max = 60, faction = "Contested", kind = "zone" },  -- Burning Steppes, forever, group finder P33
  [1429] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone" },  -- Elwynn Forest, forever, group finder P33
  [1430] = { min = 55, max = 60, faction = "Contested", kind = "zone" },  -- Deadwind Pass, vanilla, unverified (not in the group finder)
  [1431] = { min = 18, max = 34, faction = "Contested", kind = "zone" },  -- Duskwood, forever, group finder P33
  [1432] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone" },  -- Loch Modan, forever, group finder P33
  [1433] = { min = 13, max = 30, faction = "Contested", kind = "zone" },  -- Redridge Mountains, forever, group finder P33
  [1434] = { min = 28, max = 50, faction = "Contested", kind = "zone" },  -- Stranglethorn Vale, forever, group finder P33
  [1435] = { min = 33, max = 50, faction = "Contested", kind = "zone" },  -- Swamp of Sorrows, forever, group finder P33
  [1436] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone" },  -- Westfall, forever, group finder P33
  [1437] = { min = 18, max = 34, faction = "Contested", kind = "zone" },  -- Wetlands, forever, group finder P33
  [1453] = { faction = "Alliance", kind = "city" },  -- Stormwind City, vanilla, unverified
  [1455] = { faction = "Alliance", kind = "city" },  -- Ironforge, vanilla, unverified
  [1458] = { faction = "Horde",    kind = "city" },  -- Undercity, vanilla, unverified
  [2548] = { min = 33, max = 54, faction = "", kind = "zone" },  -- Riverglades, forever, group finder P33

  -- Off the continents: a zone under the world map (947), P5
  [2521] = { min = 1,  max = 14, faction = "", kind = "zone" },  -- Zephras Isle, forever, group finder P33
}
