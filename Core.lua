local addonName, ns = ...

-- Dev mode: off in release packages, where the packager comments out the
-- debug block below. The block must come after this line.
ns.devMode = false
--@debug@
ns.devMode = true
--@end-debug@

local eventFrame = CreateFrame("Frame")
local rectCache = {}

local DEFAULTS = {
  version = 1,
  modules = {
    ZoneLabels = true,
    ThreatOverlay = true,
    Instances = true,
    Tooltip = true,
  },
  overrides = {
    zones = {},
  },
  waypoints = {},
  log = {},
}

-- Zone lookup

function ns.GetZoneInfo(mapID)
  local row = ns.Zones[mapID]
  local override = ns.db.overrides.zones[mapID]
  local clientMin, clientMax

  if C_Map.GetMapLevels then
    clientMin, clientMax = C_Map.GetMapLevels(mapID)
  end

  return ns.Logic.MergeZoneInfo(row, override, clientMin, clientMax)
end

function ns.GetZoneRect(zoneID, mapID)
  local mapCache = rectCache[mapID]
  if mapCache == nil then
    mapCache = {}
    rectCache[mapID] = mapCache
  end

  local rect = mapCache[zoneID]
  if rect == nil then
    local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(zoneID, mapID)
    if ns.Logic.IsRectOnMap(minX, maxX, minY, maxY) then
      rect = { minX, maxX, minY, maxY }
    else
      rect = false
    end
    mapCache[zoneID] = rect
  end

  if rect == false then
    return nil
  end

  return unpack(rect)
end

-- Module registry

local modules = {}
local runningModules = {}

function ns.RegisterModule(name, module)
  modules[name] = module
end

function ns.GetModuleNames()
  local names = {}
  for name in pairs(modules) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

function ns.IsModuleRunning(name)
  return runningModules[name] == true
end

function ns.SetModuleEnabled(name, enabled)
  ns.db.modules[name] = enabled

  local module = modules[name]
  if enabled and not ns.IsModuleRunning(name) then
    local ok = ns.SafeCall(module.OnEnable, module)
    if ok then
      runningModules[name] = true
    end
  elseif not enabled and ns.IsModuleRunning(name) then
    ns.SafeCall(module.OnDisable, module)
    runningModules[name] = nil
  end
end

-- Commands

local commands = {}

-- access: "player", "dev" or "hidden"; nil counts as "dev" (see Logic).
function ns.RegisterCommand(name, handler, usage, access)
  local lowerName = string.lower(name)
  commands[lowerName] = {
    handler = handler,
    usage = usage,
    access = access,
  }

  if access == nil and ns.devMode then
    ns.Print("|cffff4040Warning:|r command \"" .. lowerName .. "\" has no access level")
  end
end

function ns.RunCommand(msg)
  local command, args = ns.Logic.ParseCommand(msg)
  if command == "" then
    local names = {}
    for name, entry in pairs(commands) do
      if ns.Logic.IsCommandListed(entry.access, ns.devMode) then
        names[#names + 1] = name
      end
    end
    table.sort(names)
    for _, name in ipairs(names) do
      ns.Print("/ls " .. commands[name].usage)
    end
    return
  end

  local entry = commands[command]
  if entry == nil or not ns.Logic.IsCommandRunnable(entry.access, ns.devMode) then
    ns.Print("|cffff4040Error:|r unknown command \"" .. command .. "\", type /ls for help")
    return
  end

  ns.SafeCall(entry.handler, args)
end

-- Map tick handlers

local tickHandlers = {}
local tickAccumulator = 0
local tickRunning = false

function ns.RegisterMapTick(handler)
  tickHandlers[handler] = true
end

function ns.UnregisterMapTick(handler)
  tickHandlers[handler] = nil
end

function ns.IsMapTickRunning()
  return tickRunning
end

local function OnUpdate(_, elapsed)
  local fire, newAccumulator = ns.Logic.Throttle(tickAccumulator, elapsed, 0.1)
  tickAccumulator = newAccumulator

  if fire then
    for handler in pairs(tickHandlers) do
      ns.SafeCall(handler)
    end
  end
end

-- Event dispatcher

local handlersByEvent = {}

function ns.RegisterEvent(event, handler)
  if handlersByEvent[event] == nil then
    handlersByEvent[event] = {}
    eventFrame:RegisterEvent(event)
  end
  handlersByEvent[event][handler] = true
end

function ns.UnregisterEvent(event, handler)
  local handlers = handlersByEvent[event]
  if handlers ~= nil then
    handlers[handler] = nil
    if next(handlers) == nil then
      eventFrame:UnregisterEvent(event)
      handlersByEvent[event] = nil
    end
  end
end

local function OnLogin()
  LodestarDB = ns.Logic.MergeDefaults(LodestarDB or {}, DEFAULTS)
  ns.db = LodestarDB

  -- P63: C_AddOns.GetAddOnMetadata reads the .toc Version.
  local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
  local loginLine = tostring(version) .. " loaded"
  if ns.devMode then
    local interface = select(4, GetBuildInfo())
    loginLine = loginLine .. " (interface " .. interface .. "), db v" .. ns.db.version
  end
  ns.Print(loginLine)

  if not WorldMapFrame then
    ns.Print("|cffff4040Error:|r WorldMapFrame is missing; map tick unavailable")
  else
    WorldMapFrame:HookScript("OnShow", function()
      tickAccumulator = 0
      tickRunning = true
      eventFrame:SetScript("OnUpdate", OnUpdate)
    end)

    WorldMapFrame:HookScript("OnHide", function()
      tickRunning = false
      eventFrame:SetScript("OnUpdate", nil)
    end)
  end

  for name, module in pairs(modules) do
    if ns.Logic.IsModuleEnabled(ns.db.modules, name) then
      local ok = ns.SafeCall(module.OnEnable, module)
      if ok then
        runningModules[name] = true
      end
    end
  end
end

local function OnEventDispatcher(_, event, ...)
  local handlers = handlersByEvent[event]
  if handlers ~= nil then
    for handler in pairs(handlers) do
      ns.SafeCall(handler, event, ...)
    end
  end
end

-- Startup

ns.RegisterEvent("PLAYER_LOGIN", OnLogin)

eventFrame:SetScript("OnEvent", OnEventDispatcher)
