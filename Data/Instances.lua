local addonName, ns = ...

-- Dungeon and raid entrances. Levels: the group finder on the beta (P33, 2026-10-19) where it lists
-- the instance; otherwise vanilla values (raids) or third-party guides (Forever). Vanilla entrances:
-- Claude's recall of Classic Era data, approximate (Deadmines from Warcraft Wiki), to check when the
-- markers draw. Forever entrances: unknown until found in game (P12), so x and y are left out.
-- { name, map = zone uiMapID, x, y (0-1 on that zone's map), min, max, kind }
-- kind: "dungeon" | "raid"; x/y and min/max are optional but come in pairs.
-- One row per instance: wings and instances behind one entrance share its position.
ns.Instances = {
  -- Eastern Kingdoms, vanilla
  { name = "The Deadmines", map = 1436, x = 0.424, y = 0.726, min = 17, max = 26, kind = "dungeon" },  -- Westfall; levels P33, entrance Warcraft Wiki
  { name = "Shadowfang Keep", map = 1421, x = 0.448, y = 0.678, min = 20, max = 30, kind = "dungeon" },  -- Silverpine Forest; levels P33, entrance approximate
  { name = "The Stockade", map = 1453, x = 0.405, y = 0.559, min = 24, max = 32, kind = "dungeon" },  -- Stormwind City; levels P33, entrance approximate
  { name = "Gnomeregan", map = 1426, x = 0.243, y = 0.398, min = 29, max = 38, kind = "dungeon" },  -- Dun Morogh; levels P33, entrance approximate
  { name = "Scarlet Monastery - Graveyard", map = 1420, x = 0.848, y = 0.306, min = 30, max = 38, kind = "dungeon" },  -- Tirisfal Glades; levels P33, entrance approximate
  { name = "Scarlet Monastery - Library", map = 1420, x = 0.848, y = 0.306, min = 33, max = 41, kind = "dungeon" },  -- Tirisfal Glades; levels P33, entrance approximate
  { name = "Scarlet Monastery - Armory", map = 1420, x = 0.848, y = 0.306, min = 36, max = 44, kind = "dungeon" },  -- Tirisfal Glades; levels P33, entrance approximate
  { name = "Scarlet Monastery - Cathedral", map = 1420, x = 0.848, y = 0.306, min = 38, max = 46, kind = "dungeon" },  -- Tirisfal Glades; levels P33, entrance approximate
  { name = "Uldaman", map = 1418, x = 0.424, y = 0.186, min = 41, max = 51, kind = "dungeon" },  -- Badlands; levels P33, entrance approximate
  { name = "Sunken Temple", map = 1435, x = 0.696, y = 0.536, min = 50, max = 60, kind = "dungeon" },  -- Swamp of Sorrows; levels P33, entrance approximate
  { name = "Blackrock Depths", map = 1428, x = 0.295, y = 0.380, min = 52, max = 60, kind = "dungeon" },  -- Burning Steppes (Blackrock Mountain); levels P33, entrance approximate
  { name = "Lower Blackrock Spire", map = 1428, x = 0.295, y = 0.380, min = 55, max = 60, kind = "dungeon" },  -- Burning Steppes (Blackrock Mountain); levels P33, entrance approximate
  { name = "Upper Blackrock Spire", map = 1428, x = 0.295, y = 0.380, min = 59, max = 60, kind = "dungeon" },  -- Burning Steppes (Blackrock Mountain); levels P33 (10 players), entrance approximate
  { name = "Scholomance", map = 1422, x = 0.697, y = 0.732, min = 58, max = 60, kind = "dungeon" },  -- Western Plaguelands; levels P33, entrance approximate
  { name = "Stratholme (Main Gate)", map = 1423, x = 0.310, y = 0.150, min = 58, max = 60, kind = "dungeon" },  -- Eastern Plaguelands; levels P33, entrance approximate
  { name = "Stratholme (Service Gate)", map = 1423, x = 0.475, y = 0.240, min = 58, max = 60, kind = "dungeon" },  -- Eastern Plaguelands; levels P33, entrance approximate (least sure)
  { name = "Molten Core", map = 1428, x = 0.295, y = 0.380, min = 60, max = 60, kind = "raid" },  -- Burning Steppes (Blackrock Mountain); levels vanilla, entrance approximate
  { name = "Blackwing Lair", map = 1428, x = 0.295, y = 0.380, min = 60, max = 60, kind = "raid" },  -- Burning Steppes (Blackrock Mountain); levels vanilla, entrance approximate
  { name = "Zul'Gurub", map = 1434, x = 0.537, y = 0.172, min = 60, max = 60, kind = "raid" },  -- Stranglethorn Vale; levels vanilla, entrance approximate
  { name = "Naxxramas", map = 1423, x = 0.399, y = 0.259, min = 60, max = 60, kind = "raid" },  -- Eastern Plaguelands; levels vanilla, entrance approximate (least sure)

  -- Kalimdor, vanilla
  { name = "Ragefire Chasm", map = 1454, x = 0.513, y = 0.500, min = 13, max = 16, kind = "dungeon" },  -- Orgrimmar; levels Warcraft Wiki pre-Cataclysm (not in P33 for an Alliance character), entrance approximate
  { name = "Wailing Caverns", map = 1413, x = 0.460, y = 0.365, min = 15, max = 24, kind = "dungeon" },  -- The Barrens; levels P33, entrance approximate
  { name = "Blackfathom Deeps", map = 1440, x = 0.145, y = 0.142, min = 24, max = 32, kind = "dungeon" },  -- Ashenvale; levels P33, entrance approximate
  { name = "Razorfen Kraul", map = 1413, x = 0.425, y = 0.895, min = 29, max = 38, kind = "dungeon" },  -- The Barrens; levels P33, entrance approximate
  { name = "Razorfen Downs", map = 1413, x = 0.480, y = 0.920, min = 37, max = 46, kind = "dungeon" },  -- The Barrens (south edge); levels P33, entrance approximate (least sure)
  { name = "Zul'Farrak", map = 1446, x = 0.387, y = 0.200, min = 44, max = 54, kind = "dungeon" },  -- Tanaris; levels P33, entrance approximate
  { name = "Maraudon", map = 1443, x = 0.291, y = 0.625, min = 46, max = 55, kind = "dungeon" },  -- Desolace; levels P33, entrance approximate
  { name = "Dire Maul (East)", map = 1444, x = 0.590, y = 0.445, min = 54, max = 60, kind = "dungeon" },  -- Feralas; levels P33, entrance approximate
  { name = "Dire Maul (West)", map = 1444, x = 0.590, y = 0.445, min = 56, max = 60, kind = "dungeon" },  -- Feralas; levels P33, entrance approximate
  { name = "Dire Maul (North)", map = 1444, x = 0.590, y = 0.445, min = 56, max = 60, kind = "dungeon" },  -- Feralas; levels P33, entrance approximate
  { name = "Onyxia's Lair", map = 1445, x = 0.526, y = 0.768, min = 60, max = 60, kind = "raid" },  -- Dustwallow Marsh; levels vanilla, entrance approximate
  { name = "Ruins of Ahn'Qiraj", map = 1451, x = 0.286, y = 0.924, min = 60, max = 60, kind = "raid" },  -- Silithus; levels vanilla, entrance approximate
  { name = "Temple of Ahn'Qiraj", map = 1451, x = 0.244, y = 0.875, min = 60, max = 60, kind = "raid" },  -- Silithus; levels vanilla, entrance approximate

  -- Forever: entrances to find in game (P12)
  { name = "Hall of Thanes", map = 1455, min = 13, max = 20, kind = "dungeon" },  -- Ironforge (guides: beneath Ironforge; one says Dun Morogh); levels P33
  { name = "Ruins of Lordaeron", map = 1420, min = 15, max = 22, kind = "dungeon" },  -- Tirisfal Glades (guides); levels P33
  { name = "Excavation Site: Wetlands", map = 1437, min = 26, max = 33, kind = "dungeon" },  -- Wetlands (name); levels P33
  { name = "City of Dalaran", map = 1416, min = 28, max = 35, kind = "dungeon" },  -- Alterac Mountains (assumed: where Dalaran stands in vanilla); levels P33
  { name = "The Drowned City", map = 1434, kind = "dungeon" },  -- Stranglethorn Vale (guides); not in the beta, guides disagree on levels
  { name = "Krol'dok Stronghold", map = 2548, kind = "dungeon" },  -- Riverglades (guides); not in the beta, guides disagree on levels
  { name = "Alcaz Island Prison", map = 1445, min = 48, max = 53, kind = "dungeon" },  -- Dustwallow Marsh (guides); not in the beta, levels from one guide
  { name = "Shaper's Terrace", map = 1449, min = 58, max = 60, kind = "dungeon" },  -- Un'Goro Crater (guides); not in the beta, levels from guides
  { name = "Hyjal Summit", map = 2482, min = 60, max = 60, kind = "raid" },  -- Mount Hyjal (guides); raids unlock 2026-12-09
}
