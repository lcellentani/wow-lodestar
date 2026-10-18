local addonName, ns = ...

-- Zone data keyed by uiMapID. IDs from /ls dump on the beta (P30, 2026-10-18).
-- Vanilla levels: Warcraft Wiki "Zones by level (Classic)"; factions: Warcraft Wiki
-- "Classic zones" (PvP status). Forever zones: third-party guides, faction unknown ("").
-- [uiMapID] = { [min, max,] faction, kind [, labelX, labelY] }
-- faction: "Alliance" | "Horde" | "Contested" | "" (unknown, fill in game); kind: "zone" | "city"
ns.Zones = {
  -- Kalimdor (1414)
  [1411] = { min = 1,  max = 10, faction = "Horde",     kind = "zone" },  -- Durotar, vanilla, unverified
  [1412] = { min = 1,  max = 10, faction = "Horde",     kind = "zone" },  -- Mulgore, vanilla, unverified
  [1413] = { min = 10, max = 25, faction = "Horde",     kind = "zone" },  -- The Barrens, vanilla, unverified
  [1438] = { min = 1,  max = 10, faction = "Alliance",  kind = "zone" },  -- Teldrassil, vanilla, unverified
  [1439] = { min = 10, max = 20, faction = "Alliance",  kind = "zone" },  -- Darkshore, vanilla, unverified
  [1440] = { min = 18, max = 30, faction = "Contested", kind = "zone" },  -- Ashenvale, vanilla, unverified
  [1441] = { min = 25, max = 35, faction = "Contested", kind = "zone" },  -- Thousand Needles, vanilla, unverified
  [1442] = { min = 15, max = 27, faction = "Contested", kind = "zone" },  -- Stonetalon Mountains, vanilla, unverified
  [1443] = { min = 30, max = 40, faction = "Contested", kind = "zone" },  -- Desolace, vanilla, unverified
  [1444] = { min = 40, max = 50, faction = "Contested", kind = "zone" },  -- Feralas, vanilla, unverified
  [1445] = { min = 35, max = 45, faction = "Contested", kind = "zone" },  -- Dustwallow Marsh, vanilla, unverified (wiki "Classic zones": 35-40)
  [1446] = { min = 40, max = 50, faction = "Contested", kind = "zone" },  -- Tanaris, vanilla, unverified
  [1447] = { min = 45, max = 55, faction = "Contested", kind = "zone" },  -- Azshara, vanilla, unverified
  [1448] = { min = 48, max = 55, faction = "Contested", kind = "zone" },  -- Felwood, vanilla, unverified
  [1449] = { min = 48, max = 55, faction = "Contested", kind = "zone" },  -- Un'Goro Crater, vanilla, unverified
  [1450] = { min = 55, max = 60, faction = "Contested", kind = "zone" },  -- Moonglade, vanilla, unverified (wiki "Classic zones": no range)
  [1451] = { min = 55, max = 60, faction = "Contested", kind = "zone" },  -- Silithus, vanilla, unverified
  [1452] = { min = 53, max = 60, faction = "Contested", kind = "zone" },  -- Winterspring, vanilla, unverified
  [1454] = { faction = "Horde",    kind = "city" },  -- Orgrimmar, vanilla, unverified
  [1456] = { faction = "Horde",    kind = "city" },  -- Thunder Bluff, vanilla, unverified
  [1457] = { faction = "Alliance", kind = "city" },  -- Darnassus, vanilla, unverified
  [2482] = { min = 60, max = 60, faction = "", kind = "zone" },  -- Mount Hyjal, forever, unverified (guides: level 60 endgame)
  [2652] = { faction = "", kind = "zone" },  -- Shen'dralas, forever, unverified (guides disagree on the range)

  -- Eastern Kingdoms (1415)
  [1416] = { min = 30, max = 40, faction = "Contested", kind = "zone" },  -- Alterac Mountains, vanilla, unverified
  [1417] = { min = 30, max = 40, faction = "Contested", kind = "zone" },  -- Arathi Highlands, vanilla, unverified
  [1418] = { min = 35, max = 45, faction = "Contested", kind = "zone" },  -- Badlands, vanilla, unverified
  [1419] = { min = 45, max = 55, faction = "Contested", kind = "zone" },  -- Blasted Lands, vanilla, unverified
  [1420] = { min = 1,  max = 10, faction = "Horde",     kind = "zone" },  -- Tirisfal Glades, vanilla, unverified
  [1421] = { min = 10, max = 20, faction = "Horde",     kind = "zone" },  -- Silverpine Forest, vanilla, unverified
  [1422] = { min = 51, max = 58, faction = "Contested", kind = "zone" },  -- Western Plaguelands, vanilla, unverified
  [1423] = { min = 53, max = 60, faction = "Contested", kind = "zone" },  -- Eastern Plaguelands, vanilla, unverified
  [1424] = { min = 20, max = 35, faction = "Contested", kind = "zone" },  -- Hillsbrad Foothills, vanilla, unverified
  [1425] = { min = 40, max = 50, faction = "Contested", kind = "zone" },  -- The Hinterlands, vanilla, unverified
  [1426] = { min = 1,  max = 10, faction = "Alliance",  kind = "zone" },  -- Dun Morogh, vanilla, unverified
  [1427] = { min = 45, max = 50, faction = "Contested", kind = "zone" },  -- Searing Gorge, vanilla, unverified
  [1428] = { min = 50, max = 58, faction = "Contested", kind = "zone" },  -- Burning Steppes, vanilla, unverified
  [1429] = { min = 1,  max = 10, faction = "Alliance",  kind = "zone" },  -- Elwynn Forest, vanilla, unverified
  [1430] = { min = 55, max = 60, faction = "Contested", kind = "zone" },  -- Deadwind Pass, vanilla, unverified
  [1431] = { min = 18, max = 30, faction = "Contested", kind = "zone" },  -- Duskwood, vanilla, unverified
  [1432] = { min = 10, max = 20, faction = "Alliance",  kind = "zone" },  -- Loch Modan, vanilla, unverified
  [1433] = { min = 15, max = 25, faction = "Contested", kind = "zone" },  -- Redridge Mountains, vanilla, unverified
  [1434] = { min = 30, max = 45, faction = "Contested", kind = "zone" },  -- Stranglethorn Vale, vanilla, unverified
  [1435] = { min = 35, max = 45, faction = "Contested", kind = "zone" },  -- Swamp of Sorrows, vanilla, unverified
  [1436] = { min = 10, max = 20, faction = "Alliance",  kind = "zone" },  -- Westfall, vanilla, unverified
  [1437] = { min = 20, max = 30, faction = "Contested", kind = "zone" },  -- Wetlands, vanilla, unverified
  [1453] = { faction = "Alliance", kind = "city" },  -- Stormwind City, vanilla, unverified
  [1455] = { faction = "Alliance", kind = "city" },  -- Ironforge, vanilla, unverified
  [1458] = { faction = "Horde",    kind = "city" },  -- Undercity, vanilla, unverified
  [2548] = { min = 35, max = 45, faction = "", kind = "zone" },  -- Riverglades, forever, unverified (guides)

  -- Off the continents: a zone under the world map (947), P5
  [2521] = { min = 1,  max = 12, faction = "", kind = "zone" },  -- Zephras Isle, forever, unverified (guides: Skyborne starting zone)
}
