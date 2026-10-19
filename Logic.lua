local addonName, ns = ...

local Logic = {}
ns.Logic = Logic

-- Local helpers

local function copy(t)
  if type(t) ~= "table" then
    return t
  end

  local result = {}
  for k, v in pairs(t) do
    result[k] = copy(v)
  end
  return result
end

-- Public APIs

function Logic.ParseCommand(msg)
  local args = {}
  local command = ""
  for word in string.gmatch(msg, "%S+") do
    if command == "" then
      command = string.lower(word)
    else
      args[#args + 1] = word
    end
  end
  return command, args
end

function Logic.FindName(names, input)
  if input == nil then
    return nil
  end

  local lowerInput = string.lower(input)
  for _, name in ipairs(names) do
    if string.lower(name) == lowerInput then
      return name
    end
  end

  return nil
end

function Logic.FormatCoords(x, y)
  if x == nil or y == nil then
    return nil
  end

  return string.format("%.1f, %.1f", x * 100, y * 100)
end

function Logic.IsRectOnMap(minX, maxX, minY, maxY)
  return minX ~= nil and maxX ~= nil and minY ~= nil and maxY ~= nil and maxX > minX and maxY > minY
end

-- Caller checks Logic.IsRectOnMap first; no nil checks here.
function Logic.ProjectToParent(minX, maxX, minY, maxY, x, y)
  local parentX = minX + x * (maxX - minX)
  local parentY = minY + y * (maxY - minY)

  return parentX, parentY
end

function Logic.GreyLevel(playerLevel)
  if playerLevel <= 5 then
    return 0
  elseif playerLevel <= 39 then
    return playerLevel - math.floor(playerLevel / 10) - 5
  else
    return playerLevel - math.floor(playerLevel / 5) - 1
  end
end

function Logic.DifficultyKey(level, playerLevel)
  local diff = level - playerLevel
  if diff >= 5 then
    return "red"
  elseif diff >= 3 then
    return "orange"
  elseif diff >= -4 then
    return "yellow"
  elseif level > Logic.GreyLevel(playerLevel) then
    return "green"
  else
    return "grey"
  end
end

function Logic.MergeDefaults(saved, defaults)
  for k, v in pairs(defaults) do
    if saved[k] == nil then
      saved[k] = copy(v)
    elseif type(v) == "table" and type(saved[k]) == "table" then
      Logic.MergeDefaults(saved[k], v)
    end
  end
  return saved
end

function Logic.IsModuleEnabled(moduleSettings, name)
  return moduleSettings[name] ~= false
end

function Logic.Throttle(accumulated, elapsed, interval)
  local sum = accumulated + elapsed
  if sum >= interval then
    return true, sum % interval
  end
  return false, sum
end

function Logic.AppendLog(log, entry, max)
  log[#log + 1] = entry
  while #log > max do
    table.remove(log, 1)
  end
  return log
end

function Logic.FormatOutput(entry)
  local parts = {}
  parts[#parts + 1] = tostring(entry.time) .. " /ls " .. tostring(entry.command)
  for _, line in ipairs(entry.lines) do
    parts[#parts + 1] = line
  end

  return table.concat(parts, "\n")
end

function Logic.FormatZoneRow(mapID, name, minLevel, maxLevel, today)
  if minLevel ~= nil and minLevel > 0 then
    return string.format(
      "[%d] = { min = %d, max = %d, faction = \"\", kind = \"zone\" },  -- %s, forever, %s",
      mapID,
      minLevel,
      maxLevel,
      name,
      today
    )
  else
    return string.format(
      "[%d] = { faction = \"\", kind = \"zone\" },  -- %s, forever, %s",
      mapID,
      name,
      today
    )
  end
end

function Logic.FindKey(t, value)
  if t == nil then
    return nil
  end

  for k, v in pairs(t) do
    if v == value then
      return k
    end
  end
end

function Logic.FormatProbe(id, status, detail)
  local displayStatus = status == "fail" and "FAIL" or status
  return id .. " " .. displayStatus .. ": " .. detail
end

function Logic.FormatEntrance(x, y)
  return string.format("x = %.3f, y = %.3f", x, y)
end

function Logic.MergeZoneInfo(row, override, clientMin, clientMax)
  local info = {}

  if override and override.min and override.max then
    info.min = override.min
    info.max = override.max
    info.source = "override"
  elseif clientMin and clientMin > 0 and clientMax then
    info.min = clientMin
    info.max = clientMax
    info.source = "client"
  elseif row and row.min then
    info.min = row.min
    info.max = row.max
    info.source = "table"
  end

  info.faction = (override and override.faction) or (row and row.faction)
  info.kind = (override and override.kind) or (row and row.kind)
  info.labelX = (override and override.labelX) or (row and row.labelX)
  info.labelY = (override and override.labelY) or (row and row.labelY)

  return info
end

function Logic.ColorCode(r, g, b)
  return string.format(
    "|cff%02x%02x%02x",
    math.floor(r * 255 + 0.5),
    math.floor(g * 255 + 0.5),
    math.floor(b * 255 + 0.5)
  )
end

-- min and max come together (MergeZoneInfo); no nil check for max.
function Logic.FormatLevelRange(min, max, codeFor)
  if min == nil then
    return nil
  end

  if min == max then
    return codeFor(min) .. min .. "|r"
  end

  return codeFor(min) .. min .. "|r-" .. codeFor(max) .. max .. "|r"
end
