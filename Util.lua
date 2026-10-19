local addonName, ns = ...

-- Local helpers

local FALLBACK_COLORS = {
  red = { r = 1, g = 0.1, b = 0.1 },
  orange = { r = 1, g = 0.5, b = 0.25 },
  yellow = { r = 1, g = 0.82, b = 0 },
  green = { r = 0.25, g = 0.75, b = 0.25 },
  grey = { r = 0.5, g = 0.5, b = 0.5 },
}

local lastOutput = nil
local LOG_MAX = 50

-- Public APIs

function ns.Print(...)
  local count = select("#", ...)
  local parts = {}
  for i = 1, count do
    parts[i] = tostring(select(i, ...))
  end
  local text = table.concat(parts, " ")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Lodestar:|r " .. text)
end

function ns.Record(command, lines)
  local entry = {
    time = date("%Y-%m-%d %H:%M:%S"),
    command = command,
    lines = lines,
  }
  lastOutput = entry

  if ns.db ~= nil then
    ns.Logic.AppendLog(ns.db.log, entry, LOG_MAX)
  end
end

function ns.Emit(command, lines)
  for _, line in ipairs(lines) do
    ns.Print(line)
  end
  ns.Record(command, lines)
end

function ns.GetLastOutput()
  return lastOutput
end

local function SafeCallHelper(ok, ...)
  if not ok then
    local message = ...
    ns.Print("|cffff4040Error:|r", message)
    ns.Record("error", { tostring(message) })
    return false, message
  end

  return true, ...
end

function ns.SafeCall(fn, ...)
  return SafeCallHelper(pcall(fn, ...))
end

function ns.DebugPrint(...)
  if ns.debug then
    ns.Print(...)
  end
end

function ns.LevelColorCode(level)
  local color
  if GetQuestDifficultyColor ~= nil then
    color = GetQuestDifficultyColor(level)
  else
    local key = ns.Logic.DifficultyKey(level, UnitLevel("player"))
    color = FALLBACK_COLORS[key]
  end
  return ns.Logic.ColorCode(color.r, color.g, color.b)
end
