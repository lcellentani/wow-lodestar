local addonName, ns = ...

-- Zone data keyed by uiMapID. IDs from /ls dump on the beta (P30, 2026-10-18).
-- Levels: the beta's group finder (C_LFGList suggested ranges, P33, 2026-10-19) for the
-- 41 zones it lists; it can go above the level cap (53-63). Moonglade, Deadwind Pass and
-- Shen'dralas are not listed there and keep the earlier sources: Warcraft Wiki
-- "Zones by level (Classic)" and third-party guides.
-- Label points: placed by hand with /ls place on the live client (P53, 2026-11-08).
-- Factions: Warcraft Wiki "Classic zones" (PvP status); Forever zones unknown ("").
-- [uiMapID] = { [min, max,] faction, kind [, labelX, labelY] }
-- faction: "Alliance" | "Horde" | "Contested" | "" (unknown, fill in game); kind: "zone" | "city"
ns.Zones = {
  -- Kalimdor (1414)
  [1411] = { min = 1,  max = 14, faction = "Horde",     kind = "zone", labelX = 0.585, labelY = 0.487 },  -- Durotar, forever, group finder P33
  [1412] = { min = 1,  max = 14, faction = "Horde",     kind = "zone", labelX = 0.475, labelY = 0.601 },  -- Mulgore, forever, group finder P33
  [1413] = { min = 8,  max = 30, faction = "Horde",     kind = "zone", labelX = 0.530, labelY = 0.571 },  -- The Barrens, forever, group finder P33
  [1438] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone", labelX = 0.426, labelY = 0.113 },  -- Teldrassil, forever, group finder P33
  [1439] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone", labelX = 0.462, labelY = 0.251 },  -- Darkshore, forever, group finder P33
  [1440] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.491, labelY = 0.408 },  -- Ashenvale, forever, group finder P33
  [1441] = { min = 23, max = 40, faction = "Contested", kind = "zone", labelX = 0.541, labelY = 0.746 },  -- Thousand Needles, forever, group finder P33
  [1442] = { min = 13, max = 32, faction = "Contested", kind = "zone", labelX = 0.438, labelY = 0.468 },  -- Stonetalon Mountains, forever, group finder P33
  [1443] = { min = 28, max = 44, faction = "Contested", kind = "zone", labelX = 0.418, labelY = 0.566 },  -- Desolace, forever, group finder P33
  [1444] = { min = 38, max = 54, faction = "Contested", kind = "zone", labelX = 0.430, labelY = 0.705 },  -- Feralas, forever, group finder P33
  [1445] = { min = 33, max = 50, faction = "Contested", kind = "zone", labelX = 0.559, labelY = 0.674 },  -- Dustwallow Marsh, forever, group finder P33
  [1446] = { min = 38, max = 54, faction = "Contested", kind = "zone", labelX = 0.563, labelY = 0.846 },  -- Tanaris, forever, group finder P33
  [1447] = { min = 43, max = 60, faction = "Contested", kind = "zone", labelX = 0.600, labelY = 0.383 },  -- Azshara, forever, group finder P33
  [1448] = { min = 46, max = 60, faction = "Contested", kind = "zone", labelX = 0.494, labelY = 0.274 },  -- Felwood, forever, group finder P33
  [1449] = { min = 45, max = 60, faction = "Contested", kind = "zone", labelX = 0.497, labelY = 0.814 },  -- Un'Goro Crater, forever, group finder P33
  [1450] = { min = 55, max = 60, faction = "Contested", kind = "zone", labelX = 0.537, labelY = 0.196 },  -- Moonglade, vanilla, unverified (not in the group finder; wiki "Classic zones": no range)
  [1451] = { min = 53, max = 60, faction = "Contested", kind = "zone", labelX = 0.428, labelY = 0.840 },  -- Silithus, forever, group finder P33
  [1452] = { min = 53, max = 63, faction = "Contested", kind = "zone", labelX = 0.580, labelY = 0.237 },  -- Winterspring, forever, group finder P33
  [1454] = { faction = "Horde",    kind = "city" },  -- Orgrimmar, vanilla, unverified
  [1456] = { faction = "Horde",    kind = "city" },  -- Thunder Bluff, vanilla, unverified
  [1457] = { faction = "Alliance", kind = "city" },  -- Darnassus, vanilla, unverified
  [2482] = { min = 55, max = 60, faction = "", kind = "zone", labelX = 0.534, labelY = 0.329 },  -- Mount Hyjal, forever, group finder P33
  [2652] = { faction = "", kind = "zone" },  -- Shen'dralas, forever, unverified (not in the group finder; guides disagree on the range)

  -- Eastern Kingdoms (1415)
  [1416] = { min = 28, max = 44, faction = "Contested", kind = "zone", labelX = 0.469, labelY = 0.295 },  -- Alterac Mountains, forever, group finder P33
  [1417] = { min = 28, max = 44, faction = "Contested", kind = "zone", labelX = 0.538, labelY = 0.376 },  -- Arathi Highlands, forever, group finder P33
  [1418] = { min = 33, max = 50, faction = "Contested", kind = "zone", labelX = 0.548, labelY = 0.600 },  -- Badlands, forever, group finder P33
  [1419] = { min = 43, max = 60, faction = "Contested", kind = "zone", labelX = 0.541, labelY = 0.807 },  -- Blasted Lands, forever, group finder P33
  [1420] = { min = 1,  max = 14, faction = "Horde",     kind = "zone", labelX = 0.444, labelY = 0.221 },  -- Tirisfal Glades, forever, group finder P33
  [1421] = { min = 8,  max = 24, faction = "Horde",     kind = "zone", labelX = 0.416, labelY = 0.299 },  -- Silverpine Forest, forever, group finder P33
  [1422] = { min = 48, max = 60, faction = "Contested", kind = "zone", labelX = 0.505, labelY = 0.212 },  -- Western Plaguelands, forever, group finder P33
  [1423] = { min = 53, max = 63, faction = "Contested", kind = "zone", labelX = 0.580, labelY = 0.217 },  -- Eastern Plaguelands, forever, group finder P33
  [1424] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.479, labelY = 0.340 },  -- Hillsbrad Foothills, forever, group finder P33
  [1425] = { min = 38, max = 54, faction = "Contested", kind = "zone", labelX = 0.553, labelY = 0.310 },  -- The Hinterlands, forever, group finder P33
  [1426] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone", labelX = 0.460, labelY = 0.554 },  -- Dun Morogh, forever, group finder P33
  [1427] = { min = 43, max = 60, faction = "Contested", kind = "zone", labelX = 0.486, labelY = 0.606 },  -- Searing Gorge, forever, group finder P33
  [1428] = { min = 48, max = 60, faction = "Contested", kind = "zone", labelX = 0.508, labelY = 0.654 },  -- Burning Steppes, forever, group finder P33
  [1429] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone", labelX = 0.463, labelY = 0.704 },  -- Elwynn Forest, forever, group finder P33
  [1430] = { min = 55, max = 60, faction = "Contested", kind = "zone", labelX = 0.510, labelY = 0.773 },  -- Deadwind Pass, vanilla, unverified (not in the group finder)
  [1431] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.469, labelY = 0.772 },  -- Duskwood, forever, group finder P33
  [1432] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone", labelX = 0.552, labelY = 0.543 },  -- Loch Modan, forever, group finder P33
  [1433] = { min = 13, max = 30, faction = "Contested", kind = "zone", labelX = 0.532, labelY = 0.713 },  -- Redridge Mountains, forever, group finder P33
  [1434] = { min = 28, max = 50, faction = "Contested", kind = "zone", labelX = 0.487, labelY = 0.847 },  -- Stranglethorn Vale, forever, group finder P33
  [1435] = { min = 33, max = 50, faction = "Contested", kind = "zone", labelX = 0.551, labelY = 0.758 },  -- Swamp of Sorrows, forever, group finder P33
  [1436] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone", labelX = 0.419, labelY = 0.781 },  -- Westfall, forever, group finder P33
  [1437] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.533, labelY = 0.468 },  -- Wetlands, forever, group finder P33
  [1453] = { faction = "Alliance", kind = "city" },  -- Stormwind City, vanilla, unverified
  [1455] = { faction = "Alliance", kind = "city" },  -- Ironforge, vanilla, unverified
  [1458] = { faction = "Horde",    kind = "city" },  -- Undercity, vanilla, unverified
  [2548] = { min = 33, max = 54, faction = "", kind = "zone", labelX = 0.583, labelY = 0.657 },  -- Riverglades, forever, group finder P33

  -- Off the continents: a zone under the world map (947), P5
  [2521] = { min = 1,  max = 14, faction = "", kind = "zone" },  -- Zephras Isle, forever, group finder P33
}
