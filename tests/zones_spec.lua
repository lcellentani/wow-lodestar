local ns = ...

assert(loadfile("Data/Zones.lua"))("Lodestar", ns)
local Zones = ns.Zones

-- Local helpers

-- Every zone /ls dump listed on the beta (P30, 2026-10-18): 26 Eastern Kingdoms, 23 Kalimdor, Zephras Isle.
local DUMPED_IDS = {
  1416, 1417, 1418, 1419, 1420, 1421, 1422, 1423, 1424, 1425, 1426, 1427, 1428,
  1429, 1430, 1431, 1432, 1433, 1434, 1435, 1436, 1437, 1453, 1455, 1458, 2548,
  1411, 1412, 1413, 1438, 1439, 1440, 1441, 1442, 1443, 1444, 1445, 1446, 1447,
  1448, 1449, 1450, 1451, 1452, 1454, 1456, 1457, 2482, 2652,
  2521,
}

-- "" marks a faction still unknown (the Forever zones), to fill in game.
local FACTIONS = { Alliance = true, Horde = true, Contested = true, [""] = true }
local KINDS = { zone = true, city = true }

-- The group finder suggests ranges up to 63, above the level cap (P33).
local MAX_SUGGESTED_LEVEL = 63

local function isLevel(n)
  return type(n) == "number" and n >= 1 and n <= MAX_SUGGESTED_LEVEL and n == math.floor(n)
end

-- Test cases

describe("Zones data", function()
  it("has a row for every zone /ls dump listed, and no others", function()
    local expected = {}
    for _, id in ipairs(DUMPED_IDS) do
      expected[id] = true
      assert(Zones[id] ~= nil, "missing row " .. id)
    end
    for id in pairs(Zones) do
      assert(expected[id], "row " .. tostring(id) .. " was not in the dump")
    end
  end)

  it("uses a known faction and kind in every row", function()
    for id, row in pairs(Zones) do
      assert(FACTIONS[row.faction], id .. ": faction " .. tostring(row.faction))
      assert(KINDS[row.kind], id .. ": kind " .. tostring(row.kind))
    end
  end)

  it("has min and max together, as levels 1-63 with min <= max", function()
    for id, row in pairs(Zones) do
      assert((row.min == nil) == (row.max == nil), id .. ": min and max must come together")
      if row.min ~= nil then
        assert(isLevel(row.min) and isLevel(row.max), id .. ": levels must be whole numbers 1-63")
        assert(row.min <= row.max, id .. ": min " .. row.min .. " above max " .. row.max)
      end
    end
  end)

  it("gives cities no level range", function()
    for id, row in pairs(Zones) do
      if row.kind == "city" then
        assert(row.min == nil, id .. ": a city has no range")
      end
    end
  end)
end)
