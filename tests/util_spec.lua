local ns = {}

local lines = {}

-- Local helpers

DEFAULT_CHAT_FRAME = {
  AddMessage = function(_, msg) table.insert(lines, msg) end,
}

---@diagnostic disable-next-line: undefined-global
assert(loadfile("Util.lua"))("Lodestar", ns)

local function reset() lines = {} end

local function pack(...) return select("#", ...), { ... } end

local PREFIX = "|cff33ff99Lodestar:|r "
local ERROR_PREFIX = "|cffff4040Error:|r"

-- Test cases

describe("Print", function()
  it("writes one message per call", function()
    reset()
    ns.Print("first")
    ns.Print("second")
    assert(#lines == 2, "expected 2 lines, got " .. #lines)
    for i, text in ipairs({ "first", "second" }) do
      local expected = PREFIX .. text
      assert(lines[i] == expected, "line " .. i .. ": got " .. tostring(lines[i]))
    end
  end)

  it("joins all arguments with spaces, including nil", function()
    reset()
    ns.Print("a", nil, "b", 42, true)
    assert(#lines == 1, "expected 1 line, got " .. #lines)
    local expected = PREFIX .. "a nil b 42 true"
    assert(lines[1] == expected, "got " .. tostring(lines[1]))
  end)

  it("prints only the prefix when given no arguments", function()
    reset()
    ns.Print()
    assert(#lines == 1, "expected 1 line, got " .. #lines)
    assert(lines[1] == PREFIX, "got '" .. tostring(lines[1]) .. "'")
  end)
end)

describe("SafeCall", function()
  it("returns true and all of the function's values, including nil", function()
    reset()
    local n, r = pack(ns.SafeCall(function() return 1, nil, 3 end))
    assert(n == 4, "expected 4 values, got " .. n)
    assert(r[1] == true, "r[1]: got " .. tostring(r[1]))
    assert(r[2] == 1, "r[2]: got " .. tostring(r[2]))
    assert(r[3] == nil, "r[3]: got " .. tostring(r[3]))
    assert(r[4] == 3, "r[4]: got " .. tostring(r[4]))
    assert(#lines == 0, "expected no output, got " .. #lines .. " lines")
  end)

  it("passes its extra arguments to the function", function()
    reset()
    local n, r = pack(ns.SafeCall(function(a, b) return a + b end, 2, 3))
    assert(n == 2, "expected 2 values, got " .. n)
    assert(r[1] == true, "r[1]: got " .. tostring(r[1]))
    assert(r[2] == 5, "r[2]: got " .. tostring(r[2]))
    assert(#lines == 0, "expected no output, got " .. #lines .. " lines")
  end)
  it("catches an error, returns false and the message, and prints it", function()
    reset()
    local n, r = pack(ns.SafeCall(function() error("boom") end))
    assert(n == 2, "expected 2 values, got " .. n)
    assert(r[1] == false, "r[1]: got " .. tostring(r[1]))
    local message = tostring(r[2])
    assert(string.find(message, "boom", 1, true), "expected message containing boom, got " .. message)
    assert(#lines == 1, "expected 1 line, got " .. #lines .. " lines")
    assert(string.find(lines[1], ERROR_PREFIX, 1, true), "expected error prefix in message, got " .. lines[1])
  end)

  it("catches a non-string error without crashing", function()
    reset()
    local n, r = pack(ns.SafeCall(function() error({}) end))
    assert(n == 2, "expected 2 values, got " .. n)
    assert(r[1] == false, "r[1]: got " .. tostring(r[1]))
    assert(type(r[2]) == "table", "r[2]: expected a table, got " .. type(r[2]))
    assert(#lines == 1, "expected 1 line, got " .. #lines .. " lines")
    assert(string.find(lines[1], ERROR_PREFIX, 1, true), "expected error prefix in message, got " .. lines[1])
  end)
end)

describe("DebugPrint", function()
  it("prints the message when debug mode is enabled", function()
    ns.debug = true
    reset()
    ns.DebugPrint("a", nil, "b", 42, true)
    assert(#lines == 1, "expected 1 line, got " .. #lines)
    local expected = PREFIX .. "a nil b 42 true"
    assert(lines[1] == expected, "got " .. tostring(lines[1]))
  end)

  it("prints nothing when debug mode is disabled", function()
    ns.debug = false
    reset()
    ns.DebugPrint("a", nil, "b", 42, true)
    assert(#lines == 0, "expected 0 lines, got " .. #lines)
  end)
end)
