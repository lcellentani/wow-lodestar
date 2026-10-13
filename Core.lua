local addonName, ns = ...

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local function OnEvent()
  local interface = select(4, GetBuildInfo())
  local test = ns.Logic.FormatCoords(0.5, 0.5)
  print("Lodestar loaded (interface " .. interface .. "), test: " .. test)
end

eventFrame:SetScript("OnEvent", OnEvent)
