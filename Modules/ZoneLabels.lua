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
  if mapInfo and mapInfo.mapType == Enum.UIMapType.Continent then
    WorldMapFrame:AcquirePin(TEMPLATE, "TEST", 0.5, 0.5)
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
