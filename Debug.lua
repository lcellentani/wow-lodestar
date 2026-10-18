local addonName, ns = ...

-- Local helpers

local copyFrame = nil

local function CreateCopyFrame()
  local newFrame = CreateFrame("Frame", "LodestarCopyFrame", UIParent, "BasicFrameTemplateWithInset")
  newFrame:SetSize(520, 360)
  newFrame:SetPoint("CENTER")
  newFrame.TitleText:SetText("Lodestar: last output")

  table.insert(UISpecialFrames, "LodestarCopyFrame")

  newFrame:SetMovable(true)
  newFrame:EnableMouse(true)
  newFrame:RegisterForDrag("LeftButton")
  newFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  newFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)

  local scrollFrame = CreateFrame("ScrollFrame", nil, newFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", newFrame, "TOPLEFT", 12, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", newFrame, "BOTTOMRIGHT", -32, 10)

  local editBoxFrame = CreateFrame("EditBox", nil, scrollFrame)
  editBoxFrame:SetMultiLine(true)
  editBoxFrame:SetAutoFocus(false)
  editBoxFrame:SetFontObject(ChatFontNormal)
  editBoxFrame:SetWidth(476)
  editBoxFrame:SetScript("OnEscapePressed", function()
    newFrame:Hide()
  end)

  scrollFrame:SetScrollChild(editBoxFrame)

  newFrame.editBox = editBoxFrame

  return newFrame
end

-- Commands

local LOG_CLEAR_USAGE = "log clear - empty the saved output log."
local COPY_USAGE = "copy - show the last output, selected for Ctrl+C."
local DUMP_USAGE = "dump - list the shown (or current) map's zones with ready-made Zones.lua rows."
local PROBE_USAGE = "probe [hover] - re-run the design probes, or report the zone under the cursor."
local EXPECTED_INTERFACE = 16001 -- Must match ## Interface in Lodestar.toc.

local PROBES = {
  {
    id = "P1",
    run = function()
      local interface = select(4, GetBuildInfo())
      if interface == EXPECTED_INTERFACE then
        return "pass", "interface " .. interface
      end
      return "fail", "interface " .. tostring(interface) .. " (expected " .. EXPECTED_INTERFACE .. ")"
    end,
  },
  {
    id = "P2",
    run = function()
      local mapID = C_Map.GetBestMapForUnit("player")
      local mapInfo = mapID and C_Map.GetMapInfo(mapID)
      if mapInfo ~= nil then
        return "pass", "player map " .. mapID .. " " .. mapInfo.name .. ", " .. tostring(ns.Logic.FindKey(Enum.UIMapType, mapInfo.mapType))
      end
      return "fail", "player map unavailable"
    end,
  },
  {
    id = "P3",
    run = function()
      if WorldMapFrame == nil then
        return "fail", "WorldMapFrame missing"
      end

      local missing = {}
      if WorldMapFrame.AddDataProvider == nil then
        missing[#missing + 1] = "AddDataProvider"
      end
      if WorldMapFrame.AcquirePin == nil then
        missing[#missing + 1] = "AcquirePin"
      end
      if MapCanvasPinMixin == nil then
        missing[#missing + 1] = "MapCanvasPinMixin"
      end
      if #missing == 0 then
        return "pass", "data providers and pins available"
      end
      return "fail", table.concat(missing, ", ") .. " missing"
    end,
  },
  {
    id = "P4",
    run = function()
      if WorldMapFrame ~= nil then
        return "pass", "WorldMapFrame loaded"
      end
      return "fail", "WorldMapFrame missing"
    end,
  },
  {
    id = "P5",
    run = function()
      local easternKingdoms = C_Map.GetMapChildrenInfo(1415, Enum.UIMapType.Zone) or {}
      local kalimdor = C_Map.GetMapChildrenInfo(1414, Enum.UIMapType.Zone) or {}
      local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(1429, 1415)
      local rectOk = ns.Logic.IsRectOnMap(minX, maxX, minY, maxY)
      local detail = "Eastern Kingdoms " .. #easternKingdoms .. " zones, Kalimdor " .. #kalimdor .. " zones, Elwynn rect " .. (rectOk and "ok" or "invalid")
      if #easternKingdoms > 0 and #kalimdor > 0 and rectOk then
        return "pass", detail
      end
      return "fail", detail
    end,
  },
  {
    id = "P6",
    run = function()
      local minLevel, maxLevel = C_Map.GetMapLevels(1429)
      local levels = "none"
      if minLevel ~= nil and minLevel > 0 then
        levels = minLevel .. "-" .. tostring(maxLevel)
      end
      return "info", "Elwynn Forest client levels: " .. levels
    end,
  },
  {
    id = "P8",
    run = function()
      local level = UnitLevel("player")
      local targetLevel = level + 3
      local color = GetQuestDifficultyColor(targetLevel)
      local key = ns.Logic.DifficultyKey(targetLevel, level)
      if color ~= nil and color.font == "QuestDifficulty_VeryDifficult" and key == "orange" then
        return "pass", "level " .. targetLevel .. " is orange (" .. color.font .. ")"
      end
      return "fail", "level " .. targetLevel .. " expected orange (" .. tostring(color and color.font) .. ", " .. key .. ")"
    end,
  },
}

ns.RegisterCommand(
  "log",
  function(args)
    local op = string.lower(args[1] or "")
    if op == "clear" and args[2] == nil then
      local count = #ns.db.log
      ns.db.log = {}
      local entryLabel = count == 1 and "entry" or "entries"
      ns.Print("log cleared (" .. count .. " " .. entryLabel .. ")")
    else
      ns.Print("/ls " .. LOG_CLEAR_USAGE)
    end
  end,
  LOG_CLEAR_USAGE
)

ns.RegisterCommand(
  "copy",
  function()
    local entry = ns.GetLastOutput()
    if entry == nil then
      ns.Print("nothing to copy yet")
      return
    end

    if copyFrame == nil then
      copyFrame = CreateCopyFrame()
    end

    copyFrame:Show()
    copyFrame.editBox:SetText(ns.Logic.FormatOutput(entry))
    copyFrame.editBox:HighlightText()
    copyFrame.editBox:SetFocus()
  end,
  COPY_USAGE
)

ns.RegisterCommand(
  "probe",
  function(args)
    local op = string.lower(args[1] or "")
    if op == "hover" and args[2] == nil then
      if not WorldMapFrame:IsShown() then
        ns.Print("open the world map first")
        return
      end

      local mapID = WorldMapFrame:GetMapID()
      local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
      local coords = ns.Logic.FormatCoords(x, y)
      if coords == nil then
        coords = "unknown"
      end
      local mapInfo = C_Map.GetMapInfoAtPosition(mapID, x, y)
      local detail = "cursor " .. coords .. " on " .. tostring(mapID) .. ": "
      if mapInfo == nil then
        detail = detail .. "no zone"
      else
        detail = detail .. mapInfo.mapID .. " " .. mapInfo.name
      end
      ns.Emit("probe", { ns.Logic.FormatProbe("P7", "info", detail) })
      return
    end

    if #args > 0 then
      ns.Print("/ls " .. PROBE_USAGE)
      return
    end

    local lines = {}
    local failed = 0
    for _, probe in ipairs(PROBES) do
      local ok, status, detail = pcall(probe.run)
      if not ok then
        detail = "error: " .. tostring(status)
        status = "fail"
      end
      if status == "fail" then
        failed = failed + 1
      end
      lines[#lines + 1] = ns.Logic.FormatProbe(probe.id, status, detail)
    end
    lines[#lines + 1] = "probes: " .. #PROBES .. ", failed: " .. failed
    ns.Emit("probe", lines)
  end,
  PROBE_USAGE
)

ns.RegisterCommand(
  "dump",
  function()
    local mapID, source
    if WorldMapFrame:IsShown() then
      mapID = WorldMapFrame:GetMapID()
      source = "shown map"
    else
      mapID = C_Map.GetBestMapForUnit("player")
      source = "player's map"
    end

    if mapID == nil then
      ns.Print("no map to dump")
      return
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    if mapInfo == nil then
      ns.Print("no map to dump")
      return
    end

    local today = date("%Y-%m-%d")
    local lines = {}
    local mapTypeName = ns.Logic.FindKey(Enum.UIMapType, mapInfo.mapType)
    lines[#lines + 1] = string.format(
      "map %d %s, %s (%s)",
      mapID,
      mapInfo.name,
      tostring(mapTypeName),
      source
    )

    local children = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}
    table.sort(children, function(a, b) return a.mapID < b.mapID end)
    lines[#lines + 1] = "zones: " .. #children
    local rows = {}
    for i = 1, #children do
      local child = children[i]
      local minLevel, maxLevel = C_Map.GetMapLevels(child.mapID)
      local levels = "none"
      if minLevel ~= nil and minLevel > 0 then
        levels = minLevel .. "-" .. maxLevel
      end
      lines[#lines + 1] = string.format(
        "%d %s, client levels: %s",
        child.mapID,
        child.name,
        levels
      )
      rows[#rows + 1] = ns.Logic.FormatZoneRow(
        child.mapID,
        child.name,
        minLevel,
        maxLevel,
        today
      )
    end

    lines[#lines + 1] = "rows:"
    if mapInfo.mapType == Enum.UIMapType.Zone then
      local minLevel, maxLevel = C_Map.GetMapLevels(mapID)
      lines[#lines + 1] = ns.Logic.FormatZoneRow(
        mapID,
        mapInfo.name,
        minLevel,
        maxLevel,
        today
      )
    end

    for i = 1, #rows do
      lines[#lines + 1] = rows[i]
    end

    ns.Emit("dump", lines)
  end,
  DUMP_USAGE
)
