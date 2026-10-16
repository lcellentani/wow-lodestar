local addonName, ns = ...

local eventFrame = CreateFrame("Frame")

local DEFAULTS = {
  version = 1,
  modules = {
    ZoneLabels = true,
    Instances = true,
    Tooltip = true,
  },
  overrides = {
    zones = {},
  },
  waypoints = {},
  log = {},
}

-- Module registry

local modules = {}

function ns.RegisterModule(name, module)
  modules[name] = module
end

-- Commands

local commands = {}

function ns.RegisterCommand(name, handler, usage)
  local lowerName = string.lower(name)
  commands[lowerName] = {
    handler = handler,
    usage = usage,
  }
end

function ns.RunCommand(msg)
  local command, args = ns.Logic.ParseCommand(msg)
  if command == "" then
    local names = {}
    for name in pairs(commands) do
      names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
      ns.Print("/ls " .. commands[name].usage)
    end
    return
  end

  local entry = commands[command]
  if entry == nil then
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
  local interface = select(4, GetBuildInfo())

  LodestarDB = ns.Logic.MergeDefaults(LodestarDB or {}, DEFAULTS)
  ns.db = LodestarDB
  ns.Print("loaded (interface " .. interface .. "), db v" .. ns.db.version)

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
      ns.SafeCall(module.OnEnable, module)
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
