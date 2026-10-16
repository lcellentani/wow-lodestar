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

-- Event handlers

local function OnLogin()
  local interface = select(4, GetBuildInfo())

  LodestarDB = ns.Logic.MergeDefaults(LodestarDB or {}, DEFAULTS)
  ns.db = LodestarDB
  ns.Print("loaded (interface " .. interface .. "), db v" .. ns.db.version)
end

-- WoW events & dispatcher

local function OnEventDispatcher(_, event, ...)
  local handlers = handlersByEvent[event]
  if handlers ~= nil then
    for handler in pairs(handlers) do
      ns.SafeCall(handler, event, ...)
    end
  end
end

ns.RegisterEvent("PLAYER_LOGIN", OnLogin)

eventFrame:SetScript("OnEvent", OnEventDispatcher)
