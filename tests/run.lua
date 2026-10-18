local passed, failed = 0, 0
local group = ""

function describe(name, func)
  group = name
  func()
end

function it(name, func)
  local ok, err = pcall(func)
  if ok then
    passed = passed + 1
    print(group .. " > " .. name .. ": PASSED")
  else
    failed = failed + 1
    print(group .. " > " .. name .. ": FAILED (" .. tostring(err) .. ")")
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
