local addonName, ns = ...

local Logic = {}
ns.Logic = Logic

function Logic.FormatCoords(x, y)
  if x == nil or y == nil then
    return nil
  end

  return string.format("%.1f, %.1f", x * 100, y * 100)
end

function Logic.IsRectOnMap(minX, maxX, minY, maxY)
  return minX ~= nil and maxX ~= nil and minY ~= nil and maxY ~= nil and maxX > minX and maxY > minY
end

-- Caller checks Logic.IsRectOnMap first; no nil checks here.
function Logic.ProjectToParent(minX, maxX, minY, maxY, x, y)
  local parentX = minX + x * (maxX - minX)
  local parentY = minY + y * (maxY - minY)

  return parentX, parentY
end

function Logic.GreyLevel(playerLevel)
  if playerLevel <= 5 then
    return 0
  elseif playerLevel <= 39 then
    return playerLevel - math.floor(playerLevel / 10) - 5
  else
    return playerLevel - math.floor(playerLevel / 5) - 1
  end
end

function Logic.DifficultyKey(level, playerLevel)
  local diff = level - playerLevel
  if diff >= 5 then
    return "red"
  elseif diff >= 3 then
    return "orange"
  elseif diff >= -2 then
    return "yellow"
  elseif level > Logic.GreyLevel(playerLevel) then
    return "green"
  else
    return "grey"
  end
end
