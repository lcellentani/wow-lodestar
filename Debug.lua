local addonName, ns = ...

local LOG_CLEAR_USAGE = "log clear - empty the saved output log."

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
