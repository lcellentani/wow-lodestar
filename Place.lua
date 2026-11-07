local addonName, ns = ...

-- Placement tool (notes/spec-5.3-placement-tool.md): while on, a layer over the
-- continent map shows faint grid lines and a placeholder marker per placed zone
-- (a disc in the threat color, a dark tab with the minimum level, the zone name); left click sets
-- the zone's labelX/labelY override, right click removes it. Developer tool only.

local CELLS = 20
local GRID_ALPHA = 0.25
local DISC_SIZE = 20         -- placeholder for the threat marker's footprint (design doc, ThreatOverlay)
local TAB_WIDTH, TAB_HEIGHT = 20, 13
local DOT_TEXTURE = "Interface\\AddOns\\Lodestar\\Media\\probe-white"
local LAYER_LEVEL = 3000 -- above the map's pins, which use about 2000-2920 (P3)
local PLACE_USAGE = "place [clear] - click zones on a continent map to set label points; clear removes them all (no undo)."

local layer            -- built once, the first time the tool turns on
local verticalLines = {}
local horizontalLines = {}
local dots = {}        -- [zoneID] = { disc, tab, level, name, parts, x, y }
local active = false
local shownMapID       -- the map the layer was last drawn for
local justPlaced       -- zone ID of the last left click, drawn in yellow

local function IsContinent(mapID)
  local mapInfo = mapID and C_Map.GetMapInfo(mapID)
  return mapInfo ~= nil and mapInfo.mapType == Enum.UIMapType.Continent
end

local function LayoutGrid()
  local width, height = layer:GetSize()
  for i, fraction in ipairs(ns.Logic.GridLines(CELLS)) do
    local vertical = verticalLines[i]
    vertical:ClearAllPoints()
    vertical:SetPoint("TOPLEFT", layer, "TOPLEFT", fraction * width, 0)
    vertical:SetPoint("BOTTOMLEFT", layer, "BOTTOMLEFT", fraction * width, 0)
    vertical:SetWidth(1)

    local horizontal = horizontalLines[i]
    horizontal:ClearAllPoints()
    horizontal:SetPoint("TOPLEFT", layer, "TOPLEFT", 0, -fraction * height)
    horizontal:SetPoint("TOPRIGHT", layer, "TOPRIGHT", 0, -fraction * height)
    horizontal:SetHeight(1)
  end
end

local function PositionDot(dot)
  local width, height = layer:GetSize()
  dot.disc:ClearAllPoints()
  dot.disc:SetPoint("CENTER", layer, "TOPLEFT", dot.x * width, -dot.y * height)
end

local function LayoutDots()
  for _, dot in pairs(dots) do
    if dot.disc:IsShown() then
      PositionDot(dot)
    end
  end
end

-- One placeholder marker per zone, created the first time that zone needs one
-- and reused after. Its parts are shown and hidden together.
local function GetDot(zoneID)
  local dot = dots[zoneID]
  if dot == nil then
    local disc = layer:CreateTexture(nil, "OVERLAY")
    disc:SetTexture(DOT_TEXTURE)
    disc:SetSize(DISC_SIZE, DISC_SIZE)
    local tab = layer:CreateTexture(nil, "OVERLAY")
    tab:SetColorTexture(0.1, 0.08, 0.05, 0.9)
    tab:SetSize(TAB_WIDTH, TAB_HEIGHT)
    tab:SetPoint("TOP", disc, "BOTTOM", 0, 1)
    local level = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
    level:SetPoint("CENTER", tab, "CENTER", 0, 0)
    local name = layer:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
    name:SetPoint("LEFT", disc, "RIGHT", 2, 0)
    dot = { disc = disc, tab = tab, level = level, name = name }
    dot.parts = { disc, tab, level, name }
    dots[zoneID] = dot
  end
  return dot
end

local function HideDots()
  for _, dot in pairs(dots) do
    for _, part in ipairs(dot.parts) do
      part:Hide()
    end
  end
end

local function DrawDots()
  HideDots()
  for _, child in ipairs(C_Map.GetMapChildrenInfo(shownMapID, Enum.UIMapType.Zone) or {}) do
    local info = ns.GetZoneInfo(child.mapID)
    if info.labelX ~= nil and info.labelY ~= nil then
      local dot = GetDot(child.mapID)
      dot.x, dot.y = info.labelX, info.labelY
      if info.min ~= nil then
        local color = GetQuestDifficultyColor(info.min)
        dot.disc:SetVertexColor(color.r, color.g, color.b)
        dot.level:SetText(info.min)
      else
        dot.disc:SetVertexColor(0.5, 0.5, 0.5)
        dot.level:SetText("")
      end
      -- The last point placed has its name in yellow.
      if child.mapID == justPlaced then
        dot.name:SetTextColor(1, 0.85, 0)
      else
        dot.name:SetTextColor(1, 1, 1)
      end
      dot.name:SetText(child.name)
      PositionDot(dot)
      for _, part in ipairs(dot.parts) do
        part:Show()
      end
    end
  end
end

-- Show the layer on continent maps only; redraw when the shown map changes.
local function OnMapTick()
  local mapID = WorldMapFrame:GetMapID()
  if mapID == shownMapID then
    return
  end
  shownMapID = mapID
  if IsContinent(mapID) then
    layer:Show()
    LayoutGrid()
    DrawDots()
  else
    layer:Hide()
  end
end

local function OnClick(_, button)
  if not IsContinent(shownMapID) then
    return
  end

  local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
  if x == nil or y == nil then
    return
  end

  -- The sea gives nil; coastal land can give the continent itself (P50).
  local zone = C_Map.GetMapInfoAtPosition(shownMapID, x, y)
  if zone == nil or zone.mapID == shownMapID then
    return
  end

  local row = ns.Zones[zone.mapID]
  if row ~= nil and row.kind == "city" then
    ns.Print(zone.name .. " is a city: click its zone outside the city")
    return
  end

  local zones = ns.db.overrides.zones
  if button == "LeftButton" then
    ns.Logic.SetPlacement(zones, zone.mapID, x, y)
    justPlaced = zone.mapID
    DrawDots()
    ns.Print("placed " .. zone.name .. " at " .. (ns.Logic.FormatCoords(x, y) or "unknown"))
  elseif button == "RightButton" then
    ns.Logic.ClearPlacement(zones, zone.mapID)
    if justPlaced == zone.mapID then
      justPlaced = nil
    end
    DrawDots()
    ns.Print("removed " .. zone.name)
  end
end

local TurnOff

local function OnCombatStart()
  -- Fires just before the lockdown starts (P52), so hiding is still allowed.
  TurnOff("combat started")
end

local function OnMapHidden()
  if active then
    TurnOff("map closed")
  end
end

local function BuildLayer()
  layer = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)
  layer:SetAllPoints()
  layer:SetFrameLevel(LAYER_LEVEL)
  layer:Hide()

  for i = 1, CELLS - 1 do
    local vertical = layer:CreateTexture(nil, "ARTWORK")
    vertical:SetColorTexture(1, 1, 1, GRID_ALPHA)
    verticalLines[i] = vertical
    local horizontal = layer:CreateTexture(nil, "ARTWORK")
    horizontal:SetColorTexture(1, 1, 1, GRID_ALPHA)
    horizontalLines[i] = horizontal
  end

  -- The canvas changes size when the map is maximized or minimized.
  layer:SetScript("OnSizeChanged", function()
    LayoutGrid()
    LayoutDots()
  end)
  layer:SetScript("OnMouseDown", OnClick)

  WorldMapFrame:HookScript("OnHide", OnMapHidden)
end

local function TurnOn()
  if InCombatLockdown() then
    ns.Print("not in combat")
    return
  end
  if not WorldMapFrame:IsShown() then
    ns.Print("open the world map first")
    return
  end

  if layer == nil then
    BuildLayer()
  end
  active = true
  shownMapID = nil
  layer:EnableMouse(true)
  OnMapTick()
  ns.RegisterMapTick(OnMapTick)
  ns.RegisterEvent("PLAYER_REGEN_DISABLED", OnCombatStart)
  ns.Print("placement on: left click sets a zone's point, right click removes it, /ls place to stop")
end

TurnOff = function(reason)
  active = false
  justPlaced = nil
  shownMapID = nil
  ns.UnregisterMapTick(OnMapTick)
  ns.UnregisterEvent("PLAYER_REGEN_DISABLED", OnCombatStart)
  layer:EnableMouse(false)
  layer:Hide()
  ns.Print("placement off" .. (reason and (": " .. reason) or ""))
end

ns.RegisterCommand(
  "place",
  function(args)
    local op = string.lower(args[1] or "")
    if op == "" then
      if active then
        TurnOff()
      else
        TurnOn()
      end
    elseif op == "clear" and args[2] == nil then
      local count = ns.Logic.ClearAllPlacements(ns.db.overrides.zones)
      ns.Print("cleared " .. count .. " " .. (count == 1 and "point" or "points"))
      if active and IsContinent(shownMapID) then
        justPlaced = nil
        DrawDots()
      end
    else
      ns.Print("/ls " .. PLACE_USAGE)
    end
  end,
  PLACE_USAGE
)
