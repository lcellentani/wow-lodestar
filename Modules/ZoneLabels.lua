local addonName, ns = ...

local TEMPLATE = "LodestarZoneLabelPinTemplate"

LodestarZoneLabelPinMixin = CreateFromMixins(MapCanvasPinMixin)

function LodestarZoneLabelPinMixin:OnAcquired(text, x, y)
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

  for _, child in ipairs(C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}) do
    local info = ns.GetZoneInfo(child.mapID)
    local text = ns.Logic.FormatLevelRange(info.min, info.max, ns.LevelColorCode)
    if text ~= nil then
      local minX, maxX, minY, maxY = ns.GetZoneRect(child.mapID, mapID)
      if minX ~= nil then
        local x, y = ns.Logic.LabelPosition(info, minX, maxX, minY, maxY)
        WorldMapFrame:AcquirePin(TEMPLATE, text, x, y)
      end
    end
  end
end

local ZoneLabels = {}

function ZoneLabels:OnEnable() -- luacheck: ignore 212/self
  WorldMapFrame:AddDataProvider(provider)
end

function ZoneLabels:OnDisable() -- luacheck: ignore 212/self
  WorldMapFrame:RemoveDataProvider(provider)
end

ns.RegisterModule("ZoneLabels", ZoneLabels)
