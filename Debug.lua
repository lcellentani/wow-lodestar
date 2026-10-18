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
