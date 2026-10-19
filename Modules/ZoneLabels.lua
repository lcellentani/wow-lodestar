local addonName, ns = ...

local TEMPLATE = "LodestarZoneLabelPinTemplate"
-- Soft parchment tone for zone names, so the colored ranges stand out.
local NAME_COLOR = ns.Logic.ColorCode(0.93, 0.86, 0.70)

LodestarZoneLabelPinMixin = CreateFromMixins(MapCanvasPinMixin)

-- name is nil when the map is too small for names (not maximized).
function LodestarZoneLabelPinMixin:OnAcquired(name, text, x, y)
  if name ~= nil then
    self.Name:SetText(NAME_COLOR .. name .. "|r")
  else
    self.Name:SetText("")
  end
  self.Label:SetText(text)
  self:SetPosition(x, y)
  self:SetScalingLimits(1, 1.0, 1.2)
end

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

  -- Names fit only on the maximized map; the small window shows ranges alone.
  local showNames = WorldMapFrame:IsMaximized()

  for _, child in ipairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}) do
    local info = ns.GetZoneInfo(child.mapID)
    local text = ns.Logic.FormatLevelRange(info.min, info.max, ns.LevelColorCode)
    if text ~= nil then
      local minX, maxX, minY, maxY = ns.GetZoneRect(child.mapID, mapID)
      if minX ~= nil then
        local x, y = ns.Logic.LabelPosition(info, minX, maxX, minY, maxY)
        local name = showNames and child.name or nil
        WorldMapFrame:AcquirePin(TEMPLATE, name, text, x, y)
      end
    end
  end
end

local ZoneLabels = {}
local enabled = false
local sizeHooked = false

-- The map does not refresh its data providers when it is maximized or
-- minimized, so names would keep the old window size's state until the
-- next map change. Secure hooks cannot be removed, so they are installed
-- once and check whether the module is enabled.
local function OnMapSizeChanged()
  if enabled and WorldMapFrame:IsShown() then
    provider:RefreshAllData()
  end
end

function ZoneLabels:OnEnable() -- luacheck: ignore 212/self
  WorldMapFrame:AddDataProvider(provider)
  enabled = true

  if not sizeHooked then
    if WorldMapFrame.Maximize then
      hooksecurefunc(WorldMapFrame, "Maximize", OnMapSizeChanged)
    end
    if WorldMapFrame.Minimize then
      hooksecurefunc(WorldMapFrame, "Minimize", OnMapSizeChanged)
    end
    sizeHooked = true
  end

  -- Adding a provider does not draw on a map that is already open.
  if WorldMapFrame:IsShown() then
    provider:RefreshAllData()
  end
end

function ZoneLabels:OnDisable() -- luacheck: ignore 212/self
  enabled = false
  provider:RemoveAllData()
  WorldMapFrame:RemoveDataProvider(provider)
end

ns.RegisterModule("ZoneLabels", ZoneLabels)
