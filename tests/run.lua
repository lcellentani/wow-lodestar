local passed, failed = 0, 0
-- Open describe blocks, outermost first; nested blocks join into one label.
local groups = {}

function describe(name, func)
  groups[#groups + 1] = name
  func()
  groups[#groups] = nil
end

function it(name, func)
  local label = table.concat(groups, " > ") .. " > " .. name
  local ok, err = pcall(func)
  if ok then
    passed = passed + 1
    print(label .. ": PASSED")
  else
    failed = failed + 1
    print(label .. ": FAILED (" .. tostring(err) .. ")")
  end
end

local ns = {}
assert(loadfile("Logic.lua"))("Lodestar", ns)
assert(loadfile("Util.lua"))("Lodestar", ns)

for file in io.popen('dir /b tests\\*_spec.lua'):lines() do
  assert(loadfile("tests/" .. file))(ns)
end

if passed + failed == 0 then
  print("No tests found")
  os.exit(1)
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed > 0 and 1 or 0)
