local addonName, ns = ...

-- Threat markers (notes/spec-5.4-threat-markers.md): on the small continent map, a
-- marker on each zone bordering the player's zone, in the threat color of its minimum
-- level. Nothing on the maximized map (it has the range labels) or when the player's
-- zone is not on the continent shown.

local TEMPLATE = "LodestarThreatPinTemplate"
local PLATE_R, PLATE_G, PLATE_B = 0.1, 0.08, 0.05

LodestarThreatPinMixin = CreateFromMixins(MapCanvasPinMixin)

function LodestarThreatPinMixin:OnAcquired(min, x, y)
  local color = GetQuestDifficultyColor(min)
  self.DiscEdge:SetVertexColor(color.r, color.g, color.b)
  self.TabEdge:SetVertexColor(color.r, color.g, color.b)
  self.Skull:SetVertexColor(color.r, color.g, color.b)
  self.Disc:SetVertexColor(PLATE_R, PLATE_G, PLATE_B)
  self.Tab:SetVertexColor(PLATE_R, PLATE_G, PLATE_B)
  self.Level:SetText(min)
  self:SetPosition(x, y)
  self:SetScalingLimits(1, 1.0, 1.2)
end

-- AcquirePin calls this; the inherited one calls SetPassThroughButtons,
-- which is blocked in combat (P14). Our pins ignore the mouse, so skip it.
function LodestarThreatPinMixin:CheckMouseButtonPassthrough() -- luacheck: ignore 212/self
end

-- The zone whose neighbors get markers, or nil when away (dungeon, loading screen).
local function ResolvePlayerZone()
  local mapID = C_Map.GetBestMapForUnit("player")
  if mapID == nil then
    return nil
  end
  local info = C_Map.GetMapInfo(mapID)
  if info == nil then
    return nil
  end
  local isMicro = info.mapType == Enum.UIMapType.Micro
  return ns.Logic.PlayerZone(ns.Zones, mapID, isMicro, info.parentMapID)
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

  -- Small map only; the maximized map has the range labels (decided 2026-11-07).
  if WorldMapFrame:IsMaximized() then
    return
  end

  local zoneID = ResolvePlayerZone()
  if zoneID == nil then
    return
  end

  -- The player's zone must be on the continent shown, not the other one.
  local zoneInfo = C_Map.GetMapInfo(zoneID)
  if zoneInfo == nil or zoneInfo.parentMapID ~= mapID then
    return
  end

  for _, id in ipairs(ns.Zones[zoneID].neighbors or {}) do
    local info = ns.GetZoneInfo(id)
    -- No range (Shen'dralas) or no point: no marker.
    if info.min ~= nil and info.labelX ~= nil and info.labelY ~= nil then
      WorldMapFrame:AcquirePin(TEMPLATE, info.min, info.labelX, info.labelY)
    end
  end
end

local ThreatOverlay = {}
local enabled = false
local sizeCallbacksAdded = false
local tickZone -- the player's zone at the last tick, nil when away

local function RefreshIfShown()
  if enabled and WorldMapFrame:IsShown() then
    provider:RefreshAllData()
  end
end

-- GetQuestDifficultyColor reads the level itself; the event's arguments are not
-- probed (P40), so they are not used.
local function OnLevelUp()
  RefreshIfShown()
end

-- Runs while the map is open: redraw when the player crosses into another zone.
-- The shown map changing is handled by the map itself (RefreshAllData). The tick
-- keeps its own last zone, so browsing the other continent (nothing drawn) does
-- not redraw on every tick.
local function OnMapTick()
  local zoneID = ResolvePlayerZone()
  if zoneID ~= tickZone then
    tickZone = zoneID
    RefreshIfShown()
  end
end

function ThreatOverlay:OnEnable() -- luacheck: ignore 212/self
  WorldMapFrame:AddDataProvider(provider)
  enabled = true

  -- Same reason as ZoneLabels: the map does not refresh providers on resize, and
  -- hooking Maximize/Minimize broke the map in combat (P14, P42).
  if not sizeCallbacksAdded then
    EventRegistry:RegisterCallback("WorldMapMaximized", RefreshIfShown, ThreatOverlay)
    EventRegistry:RegisterCallback("WorldMapMinimized", RefreshIfShown, ThreatOverlay)
    sizeCallbacksAdded = true
  end

  ns.RegisterEvent("PLAYER_LEVEL_UP", OnLevelUp)
  ns.RegisterMapTick(OnMapTick)

  -- Adding a provider does not draw on a map that is already open.
  RefreshIfShown()
end

function ThreatOverlay:OnDisable() -- luacheck: ignore 212/self
  enabled = false
  ns.UnregisterEvent("PLAYER_LEVEL_UP", OnLevelUp)
  ns.UnregisterMapTick(OnMapTick)
  provider:RemoveAllData()
  WorldMapFrame:RemoveDataProvider(provider)
  tickZone = nil
end

ns.RegisterModule("ThreatOverlay", ThreatOverlay)
