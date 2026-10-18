local ns = ...

assert(loadfile("Data/Zones.lua"))("Lodestar", ns)
assert(loadfile("Data/Instances.lua"))("Lodestar", ns)
local Instances = ns.Instances

-- Local helpers

local KINDS = { dungeon = true, raid = true }

local function isLevel(n)
  return type(n) == "number" and n >= 1 and n <= 60 and n == math.floor(n)
end

local function isPosition(n)
  return type(n) == "number" and n > 0 and n < 1
end

-- Test cases

describe("Instances data", function()
  it("gives every row a unique name and a known kind", function()
    local seen = {}
    for i, row in ipairs(Instances) do
      assert(type(row.name) == "string" and row.name ~= "", "row " .. i .. ": missing name")
      assert(not seen[row.name], "duplicate name " .. row.name)
      seen[row.name] = true
      assert(KINDS[row.kind], row.name .. ": kind " .. tostring(row.kind))
    end
  end)

  it("places every row in a zone of Zones.lua", function()
    for _, row in ipairs(Instances) do
      assert(ns.Zones[row.map] ~= nil, row.name .. ": map " .. tostring(row.map) .. " is not in Zones.lua")
    end
  end)

  it("has x and y together, inside the map", function()
    for _, row in ipairs(Instances) do
      assert((row.x == nil) == (row.y == nil), row.name .. ": x and y must come together")
      if row.x ~= nil then
        assert(isPosition(row.x) and isPosition(row.y), row.name .. ": x and y must be between 0 and 1")
      end
    end
  end)

  it("has min and max together, as levels 1-60 with min <= max", function()
    for _, row in ipairs(Instances) do
      assert((row.min == nil) == (row.max == nil), row.name .. ": min and max must come together")
      if row.min ~= nil then
        assert(isLevel(row.min) and isLevel(row.max), row.name .. ": levels must be whole numbers 1-60")
        assert(row.min <= row.max, row.name .. ": min " .. row.min .. " above max " .. row.max)
      end
    end
  end)
end)
