local addonName, ns = ...

function ns.Print(...)
  local count = select("#", ...)
  local parts = {}
  for i = 1, count do
    parts[i] = tostring(select(i, ...))
  end
  local text = table.concat(parts, " ")
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Lodestar:|r " .. text)
end

local function SafeCallHelper(ok, ...)
  if not ok then
    local message = ...
    ns.Print("|cffff4040Error:|r", message)
    return false, message
  end

  return true, ...
end

function ns.SafeCall(fn, ...)
  return SafeCallHelper(pcall(fn, ...))
end
