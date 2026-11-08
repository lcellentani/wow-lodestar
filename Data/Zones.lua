local addonName, ns = ...

-- Zone data keyed by uiMapID. IDs from /ls dump on the beta (P30, 2026-10-18).
-- Levels: the beta's group finder (C_LFGList suggested ranges, P33, 2026-10-19) for the
-- 41 zones it lists; it can go above the level cap (53-63). Moonglade, Deadwind Pass and
-- Shen'dralas are not listed there and keep the earlier sources: Warcraft Wiki
-- "Zones by level (Classic)" and third-party guides.
-- Label points: placed by hand with /ls place on the live client (P53, 2026-11-08).
-- Factions: Warcraft Wiki "Classic zones" (PvP status); Forever zones unknown ("").
-- Neighbors: zones whose hover areas touch in grids sampled with C_Map.GetMapInfoAtPosition
-- (Eastern Kingdoms in step 5.1, 2026-11-06; Kalimdor 2026-11-08), cities folded into their zone.
-- A border counts whether or not it can be walked across.
-- [uiMapID] = { [min, max,] faction, kind [, labelX, labelY] [, neighbors] [, zone] }
-- neighbors: uiMapIDs of the zones sharing a border; zone: for a city, the zone around it
-- faction: "Alliance" | "Horde" | "Contested" | "" (unknown, fill in game); kind: "zone" | "city"
ns.Zones = {
  -- Kalimdor (1414)
  [1411] = { min = 1,  max = 14, faction = "Horde",     kind = "zone", labelX = 0.585, labelY = 0.487, neighbors = { 1413, 1440, 1447 } },  -- Durotar, forever, group finder P33
  [1412] = { min = 1,  max = 14, faction = "Horde",     kind = "zone", labelX = 0.475, labelY = 0.601, neighbors = { 1413, 1442, 1443, 1444, 2652 } },  -- Mulgore, forever, group finder P33
  [1413] = { min = 8,  max = 30, faction = "Horde",     kind = "zone", labelX = 0.530, labelY = 0.571, neighbors = { 1411, 1412, 1440, 1441, 1442, 1445 } },  -- The Barrens, forever, group finder P33
  [1438] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone", labelX = 0.426, labelY = 0.113 },  -- Teldrassil, forever, group finder P33
  [1439] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone", labelX = 0.462, labelY = 0.251, neighbors = { 1440, 1448, 1450 } },  -- Darkshore, forever, group finder P33
  [1440] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.491, labelY = 0.408, neighbors = { 1411, 1413, 1439, 1442, 1447, 1448 } },  -- Ashenvale, forever, group finder P33
  [1441] = { min = 23, max = 40, faction = "Contested", kind = "zone", labelX = 0.541, labelY = 0.746, neighbors = { 1413, 1444, 1445, 1446, 1449 } },  -- Thousand Needles, forever, group finder P33
  [1442] = { min = 13, max = 32, faction = "Contested", kind = "zone", labelX = 0.438, labelY = 0.468, neighbors = { 1412, 1413, 1440, 1443 } },  -- Stonetalon Mountains, forever, group finder P33
  [1443] = { min = 28, max = 44, faction = "Contested", kind = "zone", labelX = 0.418, labelY = 0.566, neighbors = { 1412, 1442, 2652 } },  -- Desolace, forever, group finder P33
  [1444] = { min = 38, max = 54, faction = "Contested", kind = "zone", labelX = 0.430, labelY = 0.705, neighbors = { 1412, 1441, 1451, 2652 } },  -- Feralas, forever, group finder P33
  [1445] = { min = 33, max = 50, faction = "Contested", kind = "zone", labelX = 0.559, labelY = 0.674, neighbors = { 1413, 1441 } },  -- Dustwallow Marsh, forever, group finder P33
  [1446] = { min = 38, max = 54, faction = "Contested", kind = "zone", labelX = 0.563, labelY = 0.846, neighbors = { 1441, 1449 } },  -- Tanaris, forever, group finder P33
  [1447] = { min = 43, max = 60, faction = "Contested", kind = "zone", labelX = 0.600, labelY = 0.383, neighbors = { 1411, 1440, 1452 } },  -- Azshara, forever, group finder P33
  [1448] = { min = 46, max = 60, faction = "Contested", kind = "zone", labelX = 0.494, labelY = 0.274, neighbors = { 1439, 1440, 1450, 1452, 2482 } },  -- Felwood, forever, group finder P33
  [1449] = { min = 45, max = 60, faction = "Contested", kind = "zone", labelX = 0.497, labelY = 0.814, neighbors = { 1441, 1446, 1451 } },  -- Un'Goro Crater, forever, group finder P33
  [1450] = { min = 55, max = 60, faction = "Contested", kind = "zone", labelX = 0.537, labelY = 0.196, neighbors = { 1439, 1448, 1452 } },  -- Moonglade, vanilla, unverified (not in the group finder; wiki "Classic zones": no range)
  [1451] = { min = 53, max = 60, faction = "Contested", kind = "zone", labelX = 0.428, labelY = 0.840, neighbors = { 1444, 1449 } },  -- Silithus, forever, group finder P33
  [1452] = { min = 53, max = 63, faction = "Contested", kind = "zone", labelX = 0.580, labelY = 0.237, neighbors = { 1447, 1448, 1450, 2482 } },  -- Winterspring, forever, group finder P33
  [1454] = { faction = "Horde",    kind = "city", zone = 1411 },  -- Orgrimmar, vanilla, unverified
  [1456] = { faction = "Horde",    kind = "city", zone = 1412 },  -- Thunder Bluff, vanilla, unverified
  [1457] = { faction = "Alliance", kind = "city", zone = 1438 },  -- Darnassus, vanilla, unverified
  [2482] = { min = 55, max = 60, faction = "", kind = "zone", labelX = 0.534, labelY = 0.329, neighbors = { 1448, 1452 } },  -- Mount Hyjal, forever, group finder P33
  [2652] = { faction = "", kind = "zone", labelX = 0.444, labelY = 0.639, neighbors = { 1412, 1443, 1444 } },  -- Shen'dralas, forever, unverified (not in the group finder; guides disagree on the range)

  -- Eastern Kingdoms (1415)
  [1416] = { min = 28, max = 44, faction = "Contested", kind = "zone", labelX = 0.469, labelY = 0.295, neighbors = { 1420, 1421, 1422, 1424, 1425 } },  -- Alterac Mountains, forever, group finder P33
  [1417] = { min = 28, max = 44, faction = "Contested", kind = "zone", labelX = 0.538, labelY = 0.376, neighbors = { 1424, 1425, 1437 } },  -- Arathi Highlands, forever, group finder P33
  [1418] = { min = 33, max = 50, faction = "Contested", kind = "zone", labelX = 0.548, labelY = 0.600, neighbors = { 1427, 1428, 1432, 2548 } },  -- Badlands, forever, group finder P33
  [1419] = { min = 43, max = 60, faction = "Contested", kind = "zone", labelX = 0.541, labelY = 0.807, neighbors = { 1430, 1434, 1435 } },  -- Blasted Lands, forever, group finder P33
  [1420] = { min = 1,  max = 14, faction = "Horde",     kind = "zone", labelX = 0.444, labelY = 0.221, neighbors = { 1416, 1421, 1422 } },  -- Tirisfal Glades, forever, group finder P33
  [1421] = { min = 8,  max = 24, faction = "Horde",     kind = "zone", labelX = 0.416, labelY = 0.299, neighbors = { 1416, 1420, 1424 } },  -- Silverpine Forest, forever, group finder P33
  [1422] = { min = 48, max = 60, faction = "Contested", kind = "zone", labelX = 0.505, labelY = 0.212, neighbors = { 1416, 1420, 1423, 1425 } },  -- Western Plaguelands, forever, group finder P33
  [1423] = { min = 53, max = 63, faction = "Contested", kind = "zone", labelX = 0.580, labelY = 0.217, neighbors = { 1422, 1425 } },  -- Eastern Plaguelands, forever, group finder P33
  [1424] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.479, labelY = 0.340, neighbors = { 1416, 1417, 1421, 1425 } },  -- Hillsbrad Foothills, forever, group finder P33
  [1425] = { min = 38, max = 54, faction = "Contested", kind = "zone", labelX = 0.553, labelY = 0.310, neighbors = { 1416, 1417, 1422, 1423, 1424 } },  -- The Hinterlands, forever, group finder P33
  [1426] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone", labelX = 0.460, labelY = 0.554, neighbors = { 1427, 1432, 1437 } },  -- Dun Morogh, forever, group finder P33
  [1427] = { min = 43, max = 60, faction = "Contested", kind = "zone", labelX = 0.486, labelY = 0.606, neighbors = { 1418, 1426, 1428, 1432 } },  -- Searing Gorge, forever, group finder P33
  [1428] = { min = 48, max = 60, faction = "Contested", kind = "zone", labelX = 0.508, labelY = 0.654, neighbors = { 1418, 1427, 1429, 1433, 2548 } },  -- Burning Steppes, forever, group finder P33
  [1429] = { min = 1,  max = 14, faction = "Alliance",  kind = "zone", labelX = 0.463, labelY = 0.704, neighbors = { 1428, 1431, 1433, 1436 } },  -- Elwynn Forest, forever, group finder P33
  [1430] = { min = 55, max = 60, faction = "Contested", kind = "zone", labelX = 0.510, labelY = 0.773, neighbors = { 1419, 1431, 1434, 1435 } },  -- Deadwind Pass, vanilla, unverified (not in the group finder)
  [1431] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.469, labelY = 0.772, neighbors = { 1429, 1430, 1433, 1434, 1436 } },  -- Duskwood, forever, group finder P33
  [1432] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone", labelX = 0.552, labelY = 0.543, neighbors = { 1418, 1426, 1427, 1437 } },  -- Loch Modan, forever, group finder P33
  [1433] = { min = 13, max = 30, faction = "Contested", kind = "zone", labelX = 0.532, labelY = 0.713, neighbors = { 1428, 1429, 1431, 1435, 2548 } },  -- Redridge Mountains, forever, group finder P33
  [1434] = { min = 28, max = 50, faction = "Contested", kind = "zone", labelX = 0.487, labelY = 0.847, neighbors = { 1419, 1430, 1431, 1436 } },  -- Stranglethorn Vale, forever, group finder P33
  [1435] = { min = 33, max = 50, faction = "Contested", kind = "zone", labelX = 0.551, labelY = 0.758, neighbors = { 1419, 1430, 1433, 2548 } },  -- Swamp of Sorrows, forever, group finder P33
  [1436] = { min = 8,  max = 24, faction = "Alliance",  kind = "zone", labelX = 0.419, labelY = 0.781, neighbors = { 1429, 1431, 1434 } },  -- Westfall, forever, group finder P33
  [1437] = { min = 18, max = 34, faction = "Contested", kind = "zone", labelX = 0.533, labelY = 0.468, neighbors = { 1417, 1426, 1432 } },  -- Wetlands, forever, group finder P33
  [1453] = { faction = "Alliance", kind = "city", zone = 1429 },  -- Stormwind City, vanilla, unverified
  [1455] = { faction = "Alliance", kind = "city", zone = 1426 },  -- Ironforge, vanilla, unverified
  [1458] = { faction = "Horde",    kind = "city", zone = 1420 },  -- Undercity, vanilla, unverified
  [2548] = { min = 33, max = 54, faction = "", kind = "zone", labelX = 0.583, labelY = 0.657, neighbors = { 1418, 1428, 1433, 1435 } },  -- Riverglades, forever, group finder P33

  -- Off the continents: a zone under the world map (947), P5
  [2521] = { min = 1,  max = 14, faction = "", kind = "zone" },  -- Zephras Isle, forever, group finder P33
}
