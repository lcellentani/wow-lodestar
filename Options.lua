local addonName, ns = ...

SLASH_LODESTAR1 = "/ls"
SLASH_LODESTAR2 = "/lodestar"
SlashCmdList.LODESTAR = ns.RunCommand

local TOGGLE_USAGE = "toggle <module> - turn a module on or off."
local DEBUG_USAGE = "debug - toggle verbose logging."

ns.RegisterCommand(
  "toggle",
  function(args)
    local names = ns.GetModuleNames()

    local canonicalName = ns.Logic.FindName(names, args[1])
    if canonicalName == nil then
      ns.Print("/ls " .. TOGGLE_USAGE .. " Modules: " .. table.concat(names, ", ") .. ".")
      return
    end

    local newState = not ns.IsModuleRunning(canonicalName)
    ns.SetModuleEnabled(canonicalName, newState)
    local stateText = ns.IsModuleRunning(canonicalName) and "on" or "off"
    ns.Print(canonicalName .. ": " .. stateText)
  end,
  TOGGLE_USAGE
)

ns.RegisterCommand(
  "debug",
  function()
    local currentState = ns.debug
    ns.debug = not currentState

    local debugStateText = ns.debug and "on" or "off"
    ns.Print("debug " .. debugStateText)

    if ns.debug then
      local names = ns.GetModuleNames()
      for _, name in ipairs(names) do
        local enabledStateText = ns.IsModuleRunning(name) and "on" or "off"
        ns.Print(name .. ": " .. enabledStateText)
      end
      ns.Print("map tick running: " .. tostring(ns.IsMapTickRunning()))
    end
  end,
  DEBUG_USAGE
)
