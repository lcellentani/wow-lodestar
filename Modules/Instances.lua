local addonName, ns = ...

-- Instance entrances (notes/spec-5.6-instances.md): one marker per door, on zone maps at
-- the stored position and on continent maps projected from the row's map. Only entrances
-- the character has discovered show (the game's fog of war, P44), unless /ls reveal is on.
-- Same marker on the small and the maximized map. The pin is LodestarInstancePinMixin.

local TEMPLATE = "LodestarInstancePinTemplate"

-- Marker side in pixels: 20 on the small map, 32 on the maximized one, a little above the
-- large threat disc (30); 28 from P60 check 6, raised to 32 on trial 2026-11-22.
local SIZE_SMALL = 20
local SIZE_LARGE = 32

-- An exploration result counts only when it has something in it: P44 and P59 showed an
-- empty result without telling whether it was nil or an empty table.
local function HasAny(list)
  return list ~= nil and #list > 0
end

-- City maps have no fog of war (P59): a city's entrance is discovered once the zone around
-- the city has been entered (Ragefire Chasm, The Stockade, Hall of Thanes, Ruins of
-- Lordaeron). Every other entrance: the fog has lifted at its position.
local function IsDiscovered(row)
  local zone = ns.Zones[row.map]
  if zone ~= nil and zone.kind == "city" then
    return HasAny(C_MapExplorationInfo.GetExploredMapTextures(zone.zone))
  end
  return HasAny(C_MapExplorationInfo.GetExploredAreaIDsAtPosition(row.map, CreateVector2D(row.x, row.y)))
end

-- Rows that belong on the shown map, with a position, discovered (or all with reveal on).
-- On a continent, rects[map] keeps each row map's rectangle for the projection (false: not
-- on this continent).
local function CollectRows(mapID, isContinent)
  local rows = {}
  local rects = {}
  for _, row in ipairs(ns.Instances) do
    local onMap
    if isContinent then
      if rects[row.map] == nil then
        local minX, maxX, minY, maxY = ns.GetZoneRect(row.map, mapID)
        rects[row.map] = minX ~= nil and { minX, maxX, minY, maxY } or false
      end
      onMap = rects[row.map] ~= false
    else
      onMap = row.map == mapID
    end
    if onMap and row.x ~= nil and row.y ~= nil and (ns.reveal or IsDiscovered(row)) then
      rows[#rows + 1] = row
    end
  end
  return rows, rects
end

local provider = CreateFromMixins(MapCanvasDataProviderMixin)

function provider:RemoveAllData() -- luacheck: ignore 212/self
  WorldMapFrame:RemoveAllPinsByTemplate(TEMPLATE)
end

function provider:RefreshAllData()
  self:RemoveAllData()

  local mapID = WorldMapFrame:GetMapID()
  local mapInfo = C_Map.GetMapInfo(mapID)
  if mapInfo == nil then
    return
  end
  local isContinent = mapInfo.mapType == Enum.UIMapType.Continent
  if not isContinent and mapInfo.mapType ~= Enum.UIMapType.Zone then
    return -- world map, dungeons, micro maps: nothing
  end

  local size = WorldMapFrame:IsMaximized() and SIZE_LARGE or SIZE_SMALL
  local rows, rects = CollectRows(mapID, isContinent)
  for _, group in ipairs(ns.Logic.GroupByPosition(rows)) do
    local x, y = group.x, group.y
    if isContinent then
      local rect = rects[group.map]
      x, y = ns.Logic.ProjectToParent(rect[1], rect[2], rect[3], rect[4], x, y)
    end
    WorldMapFrame:AcquirePin(TEMPLATE, group, x, y, size)
  end
end

local Instances = {}
local enabled = false
local sizeCallbacksAdded = false

local function RefreshIfShown()
  if enabled and WorldMapFrame:IsShown() then
    provider:RefreshAllData()
  end
end

-- No level-up event: the tooltip reads colors on hover. An entrance discovered with the
-- map open appears at the next map change.
function Instances:OnEnable() -- luacheck: ignore 212/self
  WorldMapFrame:AddDataProvider(provider)
  enabled = true

  -- The marker size follows the map size, and the map does not refresh its providers on
  -- resize. Same callbacks as ZoneLabels (P42): hooking Maximize/Minimize broke the map in
  -- combat (P14).
  if not sizeCallbacksAdded then
    EventRegistry:RegisterCallback("WorldMapMaximized", RefreshIfShown, Instances)
    EventRegistry:RegisterCallback("WorldMapMinimized", RefreshIfShown, Instances)
    sizeCallbacksAdded = true
  end

  -- Adding a provider does not draw on a map that is already open.
  RefreshIfShown()
end

function Instances:OnDisable() -- luacheck: ignore 212/self
  enabled = false
  provider:RemoveAllData()
  WorldMapFrame:RemoveDataProvider(provider)
end

ns.RegisterModule("Instances", Instances)

-- Debug switch, session only: every entrance with a position, explored or not. The Tooltip
-- step reads ns.reveal too.
local REVEAL_USAGE = "reveal - show every instance entrance, explored or not, until /reload."

ns.RegisterCommand(
  "reveal",
  function()
    ns.reveal = not ns.reveal
    ns.Print("reveal " .. (ns.reveal and "on" or "off"))
    RefreshIfShown()
  end,
  REVEAL_USAGE
)
