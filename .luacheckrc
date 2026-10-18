std = "lua51"
max_line_length = false
exclude_files = { "tools/**" }
-- Every file starts with `local addonName, ns = ...`; not every file uses addonName.
ignore = { "211/addonName" }

-- Globals Lodestar writes (see the design doc's "One namespace" rule)
globals = {
  "LodestarDB", "SLASH_LODESTAR1", "SLASH_LODESTAR2", "SlashCmdList",
  "LodestarTooltip", "LodestarCopyFrame",
  -- one line per pin mixin, e.g. "LodestarZoneLabelPinMixin",
}

-- WoW API the addon reads. Only APIs confirmed in notes/beta-probes.md (evidence rule);
-- add each one here when a probe confirms it.
read_globals = {
  "GetBuildInfo",            -- P1
  "C_Map", "Enum",           -- P2, P5, P6, P7
  "WorldMapFrame",           -- P3, P4, P7
  "MapCanvasPinMixin",       -- P3
  "GetQuestDifficultyColor", -- P8
  "UnitLevel",               -- P8
  "CreateFrame", "hooksecurefunc", "UIParent", "DEFAULT_CHAT_FRAME", "UISpecialFrames", -- P16
  "ChatFontNormal",          -- P28
  "time", "date", "GetTime", -- P16
  "CreateFromMixins", "Mixin", "MapCanvasDataProviderMixin", "GameTooltip", -- P17
}

files["tests/**"] = { globals = { "describe", "it", "DEFAULT_CHAT_FRAME", "date" } }  -- harness helpers; fakes for util_spec
