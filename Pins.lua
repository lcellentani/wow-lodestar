local addonName, ns = ...

ns.ThreatPinStyle = {
  small = { tab = 4, shadowSide = 17 },
  large = { tab = 5, shadowSide = 18 },
}

local PLATE_R, PLATE_G, PLATE_B = 0.1, 0.08, 0.05

LodestarThreatPinMixin = CreateFromMixins(MapCanvasPinMixin)

function LodestarThreatPinMixin:OnAcquired(style, min, max, x, y)
  local fit = ns.Logic.FitLevel(UnitLevel("player"), min, max)
  local color = GetQuestDifficultyColor(fit)

  self.TabEdge:SetTextureSliceMargins(style.tab, style.tab, style.tab, style.tab)
  self.Tab:SetTextureSliceMargins(style.tab, style.tab, style.tab, style.tab)
  self.ShadowTab:SetTextureSliceMargins(style.shadowSide, 16, style.shadowSide, 16)

  self.DiscEdge:SetVertexColor(color.r, color.g, color.b)
  self.TabEdge:SetVertexColor(color.r, color.g, color.b)
  self.Skull:SetVertexColor(color.r, color.g, color.b)
  self.Disc:SetVertexColor(PLATE_R, PLATE_G, PLATE_B)
  self.Tab:SetVertexColor(PLATE_R, PLATE_G, PLATE_B)
  self.ShadowDisc:SetVertexColor(0, 0, 0)
  self.ShadowTab:SetVertexColor(0, 0, 0)

  if max == nil or min == max then
    self.Range:SetText(min)
  else
    self.Range:SetText(min .. "-" .. max)
  end

  self:SetPosition(x, y)
  self:SetScalingLimits(1, 1.0, 1.2)
end

-- AcquirePin calls this; the inherited one calls SetPassThroughButtons,
-- which is blocked in combat (P14). Our pins ignore the mouse, so skip it.
function LodestarThreatPinMixin:CheckMouseButtonPassthrough() -- luacheck: ignore 212/self
end

local KIND_ATLAS = { dungeon = "Dungeon", raid = "Raid" }  -- P41

LodestarInstancePinMixin = CreateFromMixins(MapCanvasPinMixin)

-- Once per pin, from the template's OnLoad: hover works, clicks reach the map (P59).
function LodestarInstancePinMixin:OnLoad()
  self:SetMouseMotionEnabled(true)
  self:SetMouseClickEnabled(false)
end

-- group comes from Logic.GroupByPosition; x, y are already projected by the module.
function LodestarInstancePinMixin:OnAcquired(group, x, y)
  self.group = group
  self.Icon:SetAtlas(KIND_ATLAS[ns.Logic.GroupKind(group.entries)])
  self:SetPosition(x, y)
  self:SetScalingLimits(1, 1.0, 1.2)
end

-- One line per instance behind the door; colors are read now, so a level-up needs no refresh.
function LodestarInstancePinMixin:OnMouseEnter()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  for _, row in ipairs(self.group.entries) do
    local detail = ns.Logic.FormatInstanceDetail(row.min, row.max, row.kind, ns.LevelColorCode)
    GameTooltip:AddDoubleLine(row.name, detail, 1, 1, 1, 1, 1, 1)
  end
  GameTooltip:Show()
end

function LodestarInstancePinMixin:OnMouseLeave() -- luacheck: ignore 212/self
  GameTooltip:Hide()
end

-- AcquirePin calls this; the inherited one calls SetPassThroughButtons,
-- which is blocked in combat (P14). OnLoad already turned clicks off, so skip it.
function LodestarInstancePinMixin:CheckMouseButtonPassthrough() -- luacheck: ignore 212/self
end
