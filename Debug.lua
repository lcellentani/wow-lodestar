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
