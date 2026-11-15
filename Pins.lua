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
