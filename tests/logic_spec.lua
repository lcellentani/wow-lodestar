local ns = ...
local Logic = ns.Logic

-- Local helpers

local function near(a, b) return math.abs(a - b) < 1e-9 end

local function expectKey(levels, key, playerLevel)
  for _, level in ipairs(levels) do
    local result = Logic.DifficultyKey(level, playerLevel)
    if result ~= key then
      -- level 2: report the line of the test that called expectKey, not this line
      error("level " .. level .. ": got " .. tostring(result), 2)
    end
  end
end

-- Test cases

describe("ParseCommand", function()
  it("returns an empty command and args for empty input", function()
    local command, args = Logic.ParseCommand("")
    assert(command == "", "got " .. tostring(command))
    assert(#args == 0, "expected no args, got " .. #args)
  end)

  it("returns an empty command and args for whitespace input", function()
    local command, args = Logic.ParseCommand("   ")
    assert(command == "", "got " .. tostring(command))
    assert(#args == 0, "expected no args, got " .. #args)
  end)

  it("separates the command from its argument", function()
    local command, args = Logic.ParseCommand("toggle ZoneLabels")
    assert(command == "toggle", "got " .. tostring(command))
    assert(#args == 1, "expected 1 arg, got " .. #args)
    assert(args[1] == "ZoneLabels", "got " .. tostring(args[1]))
  end)

  it("ignores extra spaces and lowercases only the command", function()
    local command, args = Logic.ParseCommand("  TOGGLE   ZoneLabels  ")
    assert(command == "toggle", "got " .. tostring(command))
    assert(#args == 1, "expected 1 arg, got " .. #args)
    assert(args[1] == "ZoneLabels", "got " .. tostring(args[1]))
  end)

  it("keeps multiple arguments as strings", function()
    local command, args = Logic.ParseCommand("zone here 10 20")
    assert(command == "zone", "got " .. tostring(command))
    assert(#args == 3, "expected 3 args, got " .. #args)
    assert(args[1] == "here", "got " .. tostring(args[1]))
    assert(args[2] == "10", "got " .. tostring(args[2]))
    assert(args[3] == "20", "got " .. tostring(args[3]))
  end)
end)

describe("FindName", function()
  it("returns the canonical name for an exact match", function()
    local names = { "Instances", "Tooltip", "ZoneLabels" }
    local found = Logic.FindName(names, "ZoneLabels")
    assert(found == names[3], "expected " .. names[3] .. ", got " .. tostring(found))
  end)

  it("matches names without regard to case", function()
    local names = { "Instances", "Tooltip", "ZoneLabels" }
    local found = Logic.FindName(names, "zoneLabels")
    assert(found == names[3], "expected " .. names[3] .. ", got " .. tostring(found))
  end)

  it("returns nil when no name matches", function()
    local names = { "Instances", "Tooltip", "ZoneLabels" }
    local found = Logic.FindName(names, "ZoneLabel")
    assert(found == nil, "expected nil, got " .. tostring(found))
  end)

  it("returns nil when the input is nil", function()
    local names = { "Instances", "Tooltip", "ZoneLabels" }
    local found = Logic.FindName(names, nil)
    assert(found == nil, "expected nil, got " .. tostring(found))
  end)
end)

describe("FormatCoords", function()
  it("formats as percent with one decimal", function()
    local result = Logic.FormatCoords(0.4123, 0.6543)
    assert(result == "41.2, 65.4", "got " .. tostring(result))
  end)

  it("pads the map edges to one decimal", function()
    local result = Logic.FormatCoords(0, 1)
    assert(result == "0.0, 100.0", "got " .. tostring(result))
  end)

  it("returns nil when x is nil", function()
    local result = Logic.FormatCoords(nil, 0.5)
    assert(result == nil, "got '" .. tostring(result) .. "'")
  end)

  it("returns nil when y is nil", function()
    local result = Logic.FormatCoords(0.5, nil)
    assert(result == nil, "got '" .. tostring(result) .. "'")
  end)
end)

describe("IsRectOnMap", function()
  it("returns true when rectangle is on map", function()
    local result = Logic.IsRectOnMap(0.40, 0.55, 0.70, 0.85)
    assert(result == true, "got " .. tostring(result))
  end)
  it("returns false for the all-zero rectangle (zone not on this map)", function()
    local result = Logic.IsRectOnMap(0, 0, 0, 0)
    assert(result == false, "got " .. tostring(result))
  end)

  it("returns false when the rectangle is flipped", function()
    local result = Logic.IsRectOnMap(0.55, 0.40, 0.70, 0.85)
    assert(result == false, "got " .. tostring(result))
  end)

  it("returns false when the width is zero", function()
    local result = Logic.IsRectOnMap(0.5, 0.5, 0.1, 0.3)
    assert(result == false, "got " .. tostring(result))
  end)

  it("returns false when the height is zero", function()
    local result = Logic.IsRectOnMap(0.4, 0.55, 0.3, 0.3)
    assert(result == false, "got " .. tostring(result))
  end)

  it("returns false when all coordinates are nil", function()
    local result = Logic.IsRectOnMap(nil, nil, nil, nil)
    assert(result == false, "got " .. tostring(result))
  end)

  it("returns false when one coordinate is nil", function()
    for i = 1, 4 do
      local args = { 0.40, 0.55, 0.70, 0.85 }
      args[i] = nil
      local result = Logic.IsRectOnMap(unpack(args, 1, 4))
      assert(result == false, "nil at position " .. i .. ": got " .. tostring(result))
    end
  end)
end)

describe("ProjectToParent", function()
  it("projects to the top-left corner", function()
    local x, y = Logic.ProjectToParent(0.4, 0.6, 0.2, 0.5, 0, 0)
    assert(near(x, 0.4) and near(y, 0.2), "got " .. x .. ", " .. y)
  end)

  it("projects to the bottom-right corner", function()
    local x, y = Logic.ProjectToParent(0.4, 0.6, 0.2, 0.5, 1, 1)
    assert(near(x, 0.6) and near(y, 0.5), "got " .. x .. ", " .. y)
  end)

  it("projects to the center", function()
    local x, y = Logic.ProjectToParent(0.4, 0.6, 0.2, 0.5, 0.5, 0.5)
    assert(near(x, 0.5) and near(y, 0.35), "got " .. x .. ", " .. y)
  end)

  it("projects an off-center point", function()
    local x, y = Logic.ProjectToParent(0.4, 0.6, 0.2, 0.5, 0.25, 0.75)
    assert(near(x, 0.45) and near(y, 0.425), "got " .. x .. ", " .. y)
  end)
end)

describe("GreyLevel", function()
  it("at level 1 nothing is grey yet", function()
    local result = Logic.GreyLevel(1)
    assert(result == 0, "got " .. tostring(result))
  end)
  it("at level 5, nothing is grey", function()
    local result = Logic.GreyLevel(5)
    assert(result == 0, "got " .. tostring(result))
  end)

  it("at level 6, level 1 is grey", function()
    local result = Logic.GreyLevel(6)
    assert(result == 1, "got " .. tostring(result))
  end)

  it("at level 25, levels 1-18 are grey", function()
    local result = Logic.GreyLevel(25)
    assert(result == 18, "got " .. tostring(result))
  end)

  it("at level 39, levels 1-31 are grey", function()
    local result = Logic.GreyLevel(39)
    assert(result == 31, "got " .. tostring(result))
  end)

  it("at level 40, levels 1-31 are grey", function()
    local result = Logic.GreyLevel(40)
    assert(result == 31, "got " .. tostring(result))
  end)

  it("at level 45, levels 1-35 are grey", function()
    local result = Logic.GreyLevel(45)
    assert(result == 35, "got " .. tostring(result))
  end)

  it("at level 60, levels 1-47 are grey", function()
    local result = Logic.GreyLevel(60)
    assert(result == 47, "got " .. tostring(result))
  end)
end)

describe("DifficultyKey", function()
  -- player level 25 throughout; GreyLevel(25) = 18
  it("is red at 5 or more levels above", function()
    expectKey({ 30, 31 }, "red", 25)
  end)

  it("is orange at 3 or 4 levels above", function()
    expectKey({ 28, 29 }, "orange", 25)
  end)

  it("is yellow from 4 below to 2 levels above", function()
    expectKey({ 21, 23, 25, 27 }, "yellow", 25)
  end)

  it("is green from 6 below to 5 levels below", function()
    expectKey({ 19, 20 }, "green", 25)
  end)

  it("matches the Forever bands observed at player level 18", function()
    expectKey({ 14 }, "yellow", 18)
    expectKey({ 13 }, "green", 18)
    expectKey({ 12 }, "grey", 18)
  end)

  it("is grey from 7 or more levels below", function()
    expectKey({ 1, 18 }, "grey", 25)
  end)

  it("is yellow down to 4 levels below a low-level player", function()
    expectKey({ 1 }, "yellow", 5)
  end)
end)

describe("MergeDefaults", function()
  it("fills an empty saved table with defaults, including nested tables", function()
    local defaults = {
      version = 1,
      modules = {
        Tooltip = true,
      },
    }
    local saved = {}
    Logic.MergeDefaults(saved, defaults)

    assert(saved.version == 1, "got " .. tostring(saved.version))
    assert(saved.modules.Tooltip == true, "got " .. tostring(saved.modules.Tooltip))
  end)

  it("preserves saved values that differ from default", function()
    local defaults = {
      version = 1,
      modules = {
        Tooltip = true,
      },
    }
    local saved = {
      modules = {
        Tooltip = false,
      },
    }
    Logic.MergeDefaults(saved, defaults)

    assert(saved.version == 1, "got " .. tostring(saved.version))
    assert(saved.modules.Tooltip == false, "got " .. tostring(saved.modules.Tooltip))
  end)

  it("fills missing siblings when the saved nested table is partially filled", function()
    local defaults = {
      version = 1,
      modules = {
        ZoneLabels = true,
        Instances = true,
        Tooltip = true,
      },
    }
    local saved = {
      modules = {
        ZoneLabels = false,
      },
    }
    Logic.MergeDefaults(saved, defaults)

    assert(saved.version == 1, "got " .. tostring(saved.version))
    assert(saved.modules.ZoneLabels == false, "got " .. tostring(saved.modules.ZoneLabels))
    assert(saved.modules.Instances == true, "got " .. tostring(saved.modules.Instances))
    assert(saved.modules.Tooltip == true, "got " .. tostring(saved.modules.Tooltip))
  end)

  it("preserves saved keys that are absent from defaults", function()
    local defaults = {
      version = 1,
      modules = {
        ZoneLabels = true,
      },
    }
    local saved = {
      modules = {
        ZoneLabels = false,
      },
      overrides = {
        zones = {
          [1429] = { min = 10, max = 20 },
        },
      },
    }
    Logic.MergeDefaults(saved, defaults)

    assert(saved.version == 1, "got " .. tostring(saved.version))
    assert(saved.modules.ZoneLabels == false, "got " .. tostring(saved.modules.ZoneLabels))
    assert(type(saved.overrides.zones) == "table", "expected override table")
    assert(type(saved.overrides.zones[1429]) == "table", "expected zone override table")
    assert(saved.overrides.zones[1429].min == 10, "got " .. tostring(saved.overrides.zones[1429].min))
    assert(saved.overrides.zones[1429].max == 20, "got " .. tostring(saved.overrides.zones[1429].max))
  end)

  it("copies missing tables so saved data does not share defaults", function()
    local defaults = {
      log = {},
      overrides = {
        zones = {},
      },
    }
    local saved = {}

    Logic.MergeDefaults(saved, defaults)

    assert(saved.log ~= defaults.log, "expected separate log tables")
    assert(saved.overrides.zones ~= defaults.overrides.zones, "expected separate zone tables")

    saved.log[1] = "test entry"
    assert(#defaults.log == 0, "expected defaults.log to remain empty")
  end)
end)

describe("IsModuleEnabled", function()
  it("returns true when the module setting is true", function()
    local moduleSettings = {
      ZoneLabels = true,
    }

    local result = Logic.IsModuleEnabled(moduleSettings, "ZoneLabels")
    assert(result == true, "expected ZoneLabels enabled, got " .. tostring(result))
  end)
  it("returns false when the module setting is false", function()
    local moduleSettings = {
      ZoneLabels = false,
    }

    local result = Logic.IsModuleEnabled(moduleSettings, "ZoneLabels")
    assert(result == false, "expected ZoneLabels disabled, got " .. tostring(result))
  end)
  it("returns true when the module has no setting", function()
    local moduleSettings = {}

    local result = Logic.IsModuleEnabled(moduleSettings, "ZoneLabels")
    assert(result == true, "expected ZoneLabels enabled, got " .. tostring(result))
  end)
end)

describe("Throttle", function()
  it("returns false and keeps the elapsed time when below the interval", function()
    local result, leftover = Logic.Throttle(0, 0.05, 0.1)
    assert(result == false, "expected false, got " .. tostring(result))
    assert(near(leftover, 0.05), "got " .. tostring(leftover))
  end)

  it("returns true with no leftover when reaching the interval exactly", function()
    local result, leftover = Logic.Throttle(0.05, 0.05, 0.1)
    assert(result == true, "expected true, got " .. tostring(result))
    assert(near(leftover, 0), "got " .. tostring(leftover))
  end)

  it("returns true and preserves time beyond the interval as leftover", function()
    local result, leftover = Logic.Throttle(0.08, 0.05, 0.1)
    assert(result == true, "expected true, got " .. tostring(result))
    assert(near(leftover, 0.03), "got " .. tostring(leftover))
  end)

  it("keeps only the remainder after a lag spike", function()
    local result, leftover = Logic.Throttle(0, 0.35, 0.1)
    assert(result == true, "expected true, got " .. tostring(result))
    assert(near(leftover, 0.05), "got " .. tostring(leftover))
  end)
end)

describe("AppendLog", function()
  it("appends an entry to an empty log", function()
    local inLog = {}
    local entry = "first entry"
    local max = 3
    local outLog = Logic.AppendLog(inLog, entry, max)
    local size = #outLog
    assert(size == 1, "expected log with 1 entry, got " .. tostring(size))
    assert(outLog == inLog, "expected AppendLog to return the original log table")
    assert(outLog[1] == entry, "expected " .. entry .. ", got " .. tostring(outLog[1]))
  end)

  it("appends entries in order", function()
    local inLog = {
      "first entry",
      "second entry",
    }
    local expected = {
      "first entry",
      "second entry",
      "third entry",
    }
    local entry = "third entry"
    local max = 5
    local outLog = Logic.AppendLog(inLog, entry, max)
    local size = #outLog
    assert(size == 3, "expected log with 3 entries, got " .. tostring(size))
    assert(outLog == inLog, "expected AppendLog to return the original log table")
    for i in ipairs(outLog) do
      assert(expected[i] == outLog[i], "expected " .. expected[i] .. ", got " .. tostring(outLog[i]))
    end
  end)

  it("discards the oldest entry when the log exceeds its limit", function()
    local inLog = {
      "first entry",
      "second entry",
      "third entry",
    }
    local expected = {
      "second entry",
      "third entry",
      "fourth entry",
    }
    local entry = "fourth entry"
    local max = 3
    local outLog = Logic.AppendLog(inLog, entry, max)
    local size = #outLog
    assert(size == 3, "expected log with 3 entries, got " .. tostring(size))
    assert(outLog == inLog, "expected AppendLog to return the original log table")
    for i in ipairs(outLog) do
      assert(expected[i] == outLog[i], "expected " .. expected[i] .. ", got " .. tostring(outLog[i]))
    end
  end)

  it("keeps all entries when appending reaches the limit", function()
    local inLog = {
      "first entry",
      "second entry",
    }
    local expected = {
      "first entry",
      "second entry",
      "third entry",
    }
    local entry = "third entry"
    local max = 3
    local outLog = Logic.AppendLog(inLog, entry, max)
    local size = #outLog
    assert(size == 3, "expected log with 3 entries, got " .. tostring(size))
    assert(outLog == inLog, "expected AppendLog to return the original log table")
    for i in ipairs(outLog) do
      assert(expected[i] == outLog[i], "expected " .. expected[i] .. ", got " .. tostring(outLog[i]))
    end
  end)
end)

describe("FormatOutput", function()
  it("formats the header and output lines", function()
    local entry = {
      time = "2026-10-18 19:30:07",
      command = "emit",
      lines = { "line one", "line two" },
    }

    local result = Logic.FormatOutput(entry)

    local expected = "2026-10-18 19:30:07 /ls emit\nline one\nline two"
    assert(result == expected, "expected " .. expected .. ", got " .. tostring(result))
  end)

  it("formats an entry with no output lines without a trailing newline", function()
    local entry = {
      time = "2026-10-18 19:30:07",
      command = "empty",
      lines = {},
    }

    local result = Logic.FormatOutput(entry)

    local expected = "2026-10-18 19:30:07 /ls empty"
    assert(result == expected, "expected " .. expected .. ", got " .. tostring(result))
  end)

  it("keeps the error command and includes its message", function()
    local entry = {
      time = "2026-10-18 19:30:07",
      command = "error",
      lines = { "boom test" },
    }

    local result = Logic.FormatOutput(entry)

    local expected = "2026-10-18 19:30:07 /ls error\nboom test"
    assert(result == expected, "expected " .. expected .. ", got " .. tostring(result))
  end)
end)

describe("FormatZoneRow", function()
  it("formats a row with a client level range", function()
    local row = Logic.FormatZoneRow(1440, "Ashenvale", 20, 30, "2026-10-18")
    assert(
      row == '[1440] = { min = 20, max = 30, faction = "", kind = "zone" },  -- Ashenvale, forever, 2026-10-18',
      "got " .. tostring(row)
    )
  end)

  it("omits levels when the client range is zero", function()
    local row = Logic.FormatZoneRow(1440, "Ashenvale", 0, 0, "2026-10-18")
    assert(
      row == '[1440] = { faction = "", kind = "zone" },  -- Ashenvale, forever, 2026-10-18',
      "got " .. tostring(row)
    )
  end)

  it("omits levels when the client range is nil", function()
    local row = Logic.FormatZoneRow(1440, "Ashenvale", nil, nil, "2026-10-18")
    assert(
      row == '[1440] = { faction = "", kind = "zone" },  -- Ashenvale, forever, 2026-10-18',
      "got " .. tostring(row)
    )
  end)
end)

describe("FindKey", function()
  it("returns the key for a value that is present", function()
    local enum = { Zone = 3, Continent = 2 }
    local key = Logic.FindKey(enum, 2)
    assert(key == "Continent", "expected Continent, got " .. tostring(key))
  end)

  it("returns nil when the value is missing", function()
    local enum = { Zone = 3, Continent = 2 }
    local key = Logic.FindKey(enum, 1)
    assert(key == nil, "expected nil, got " .. tostring(key))
  end)

  it("returns nil when the table is nil", function()
    local key = Logic.FindKey(nil, 2)
    assert(key == nil, "expected nil, got " .. tostring(key))
  end)
end)

describe("FormatEntrance", function()
  it("formats the Hall of Thanes position to three decimals", function()
    local result = Logic.FormatEntrance(0.28077352046967, 0.47070151567459)
    assert(result == "x = 0.281, y = 0.471", "got " .. tostring(result))
  end)

  it("keeps three decimals when rounding up across a digit", function()
    local result = Logic.FormatEntrance(0.0996, 0.5)
    assert(result == "x = 0.100, y = 0.500", "got " .. tostring(result))
  end)
end)

describe("FormatProbe", function()
  it("formats a pass line", function()
    local result = Logic.FormatProbe("P1", "pass", "interface 16001")
    assert(result == "P1 pass: interface 16001", "got " .. tostring(result))
  end)

  it("capitalizes a fail status", function()
    local result = Logic.FormatProbe("P3", "fail", "AcquirePin missing")
    assert(result == "P3 FAIL: AcquirePin missing", "got " .. tostring(result))
  end)

  it("formats an info line", function()
    local result = Logic.FormatProbe("P6", "info", "client levels: none")
    assert(result == "P6 info: client levels: none", "got " .. tostring(result))
  end)
end)

describe("MergeZoneInfo", function()
  local elwynn = { min = 1, max = 14, faction = "Alliance", kind = "zone" }

  local function expectRange(info, min, max, source)
    assert(info.min == min and info.max == max and info.source == source,
      "got " .. tostring(info.min) .. "-" .. tostring(info.max) .. " (" .. tostring(info.source) .. ")")
  end

  it("uses the table range when the client range is zero", function()
    local info = Logic.MergeZoneInfo(elwynn, nil, 0, 0)
    expectRange(info, 1, 14, "table")
    assert(info.faction == "Alliance", "got " .. tostring(info.faction))
    assert(info.kind == "zone", "got " .. tostring(info.kind))
  end)

  it("uses the table range when the client range is nil", function()
    local info = Logic.MergeZoneInfo(elwynn, nil, nil, nil)
    expectRange(info, 1, 14, "table")
  end)

  it("prefers the client range over the table", function()
    local info = Logic.MergeZoneInfo(elwynn, nil, 2, 12)
    expectRange(info, 2, 12, "client")
  end)

  it("prefers a complete override range over client and table", function()
    local info = Logic.MergeZoneInfo(elwynn, { min = 5, max = 10 }, 2, 12)
    expectRange(info, 5, 10, "override")
  end)

  it("ignores an incomplete override range and falls back to the client", function()
    local info = Logic.MergeZoneInfo(elwynn, { min = 5 }, 2, 12)
    expectRange(info, 2, 12, "client")
  end)

  it("falls back to the table when an override range is incomplete", function()
    local info = Logic.MergeZoneInfo(elwynn, { min = 5 }, 0, 0)
    expectRange(info, 1, 14, "table")
  end)

  it("merges label coordinates independently and keeps zero coordinates", function()
    local row = { labelX = 0.4, labelY = 0.6 }
    local override = { labelY = 0.7 }
    local info = Logic.MergeZoneInfo(row, override, 0, 0)
    assert(info.labelX == 0.4, "got labelX " .. tostring(info.labelX))
    assert(info.labelY == 0.7, "got labelY " .. tostring(info.labelY))

    local zeroInfo = Logic.MergeZoneInfo({ labelX = 0 }, nil, 0, 0)
    assert(zeroInfo.labelX == 0, "got labelX " .. tostring(zeroInfo.labelX))
  end)

  it("prefers override faction and keeps the row kind", function()
    local info = Logic.MergeZoneInfo(elwynn, { faction = "Horde" }, 0, 0)
    assert(info.faction == "Horde", "got " .. tostring(info.faction))
    assert(info.kind == "zone", "got " .. tostring(info.kind))
  end)

  it("keeps city metadata without a level range", function()
    local city = { faction = "Horde", kind = "city" }
    local info = Logic.MergeZoneInfo(city, nil, 0, 0)
    assert(info.min == nil and info.max == nil and info.source == nil, "unexpected range or source")
    assert(info.faction == "Horde", "got " .. tostring(info.faction))
    assert(info.kind == "city", "got " .. tostring(info.kind))
  end)

  it("returns a table of nil fields when there is no data", function()
    local info = Logic.MergeZoneInfo(nil, nil, nil, nil)
    assert(type(info) == "table", "got " .. type(info))
    assert(info.min == nil and info.max == nil and info.source == nil, "unexpected range or source")
    assert(info.faction == nil and info.kind == nil, "unexpected faction or kind")
    assert(info.labelX == nil and info.labelY == nil, "unexpected label coordinates")
  end)

  it("returns a new table without modifying the row", function()
    local info = Logic.MergeZoneInfo(elwynn, nil, 0, 0)
    assert(info ~= elwynn, "returned the original row")
    info.min = 99
    assert(elwynn.min == 1, "changed the original row min to " .. tostring(elwynn.min))
  end)
end)

describe("ColorCode", function()
  it("formats white", function()
    local result = Logic.ColorCode(1, 1, 1)
    assert(result == "|cffffffff", "got " .. tostring(result))
  end)

  it("formats black", function()
    local result = Logic.ColorCode(0, 0, 0)
    assert(result == "|cff000000", "got " .. tostring(result))
  end)

  it("rounds the orange color channels to the nearest hex values", function()
    local result = Logic.ColorCode(1, 0.5, 0.25)
    assert(result == "|cffff8040", "got " .. tostring(result))
  end)

  it("formats the probed green color", function()
    local result = Logic.ColorCode(0.25, 0.75, 0.25)
    assert(result == "|cff40bf40", "got " .. tostring(result))
  end)
end)

describe("FormatLevelRange", function()
  local function fakeCode(level)
    return "<" .. level .. ">"
  end

  it("colors each end of a level range and leaves the dash neutral", function()
    local result = Logic.FormatLevelRange(15, 25, fakeCode)
    assert(result == "<15>15|r-<25>25|r", "got " .. tostring(result))
  end)

  it("formats a single-level range with one color", function()
    local result = Logic.FormatLevelRange(60, 60, fakeCode)
    assert(result == "<60>60|r", "got " .. tostring(result))
  end)

  it("returns nil when the minimum is nil", function()
    local result = Logic.FormatLevelRange(nil, nil, fakeCode)
    assert(result == nil, "got " .. tostring(result))
  end)
end)
