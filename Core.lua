local addonName, ns = ...

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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local function OnEvent()
  local interface = select(4, GetBuildInfo())

  LodestarDB = ns.Logic.MergeDefaults(LodestarDB or {}, DEFAULTS)
  ns.db = LodestarDB
  ns.Print("loaded (interface " .. interface .. "), db v" .. ns.db.version)
end

eventFrame:SetScript("OnEvent", OnEvent)
