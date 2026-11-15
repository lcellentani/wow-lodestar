local addonName, ns = ...

-- Zone pins on the maximized continent map (notes/spec-5.5-pin-rework.md): the large
-- threat pin on every zone with a level range, in the color of its fit level. The pin
-- mixin is shared with ThreatOverlay (Pins.lua). The small map has ThreatOverlay's pins.

local TEMPLATE = "LodestarThreatPinLargeTemplate"

local provider = CreateFromMixins(MapCanvasDataProviderMixin)

function provider:RemoveAllData() -- luacheck: ignore 212/self
  WorldMapFrame:RemoveAllPinsByTemplate(TEMPLATE)
end

function provider:RefreshAllData()
  self:RemoveAllData()

  local mapID = WorldMapFrame:GetMapID()
  local mapInfo = C_Map.GetMapInfo(mapID)
  if mapInfo == nil or mapInfo.mapType ~= Enum.UIMapType.Continent then
    return
  end

  -- Maximized map only; the small map is for the threat markers (decided 2026-11-07).
  if not WorldMapFrame:IsMaximized() then
    return
  end

  for _, child in ipairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}) do
    local info = ns.GetZoneInfo(child.mapID)
    -- No range (Shen'dralas, cities): no pin.
    if info.min ~= nil then
      local minX, maxX, minY, maxY = ns.GetZoneRect(child.mapID, mapID)
      if minX ~= nil then
        local x, y = ns.Logic.LabelPosition(info, minX, maxX, minY, maxY)
        WorldMapFrame:AcquirePin(TEMPLATE, ns.ThreatPinStyle.large, info.min, info.max, x, y)
      end
    end
  end
end

local ZoneLabels = {}
local enabled = false
local sizeCallbacksAdded = false

local function RefreshIfShown()
  if enabled and WorldMapFrame:IsShown() then
    provider:RefreshAllData()
  end
end

-- The fit level follows the player's level; the event's arguments are not probed
-- (P40), so they are not used.
local function OnLevelUp()
  RefreshIfShown()
end

function ZoneLabels:OnEnable() -- luacheck: ignore 212/self
  WorldMapFrame:AddDataProvider(provider)
  enabled = true

  -- The map does not refresh its data providers when it is maximized or minimized.
  -- Listen to the map's size events rather than hooking Maximize and Minimize: in
  -- combat those hooks broke the map (P14, P42). The callbacks are added once and
  -- check whether the module is enabled.
  if not sizeCallbacksAdded then
    EventRegistry:RegisterCallback("WorldMapMaximized", RefreshIfShown, ZoneLabels)
    EventRegistry:RegisterCallback("WorldMapMinimized", RefreshIfShown, ZoneLabels)
    sizeCallbacksAdded = true
  end

  ns.RegisterEvent("PLAYER_LEVEL_UP", OnLevelUp)

  -- Adding a provider does not draw on a map that is already open.
  RefreshIfShown()
end

function ZoneLabels:OnDisable() -- luacheck: ignore 212/self
  enabled = false
  ns.UnregisterEvent("PLAYER_LEVEL_UP", OnLevelUp)
  provider:RemoveAllData()
  WorldMapFrame:RemoveDataProvider(provider)
end

ns.RegisterModule("ZoneLabels", ZoneLabels)
