# M2 step 2.4: event dispatcher, module registry, map tick

Status: done 2026-10-16: 2.4a, 2.4b, 2.4c (P21, P22, P23 in `notes/beta-probes.md`). User writes the code, Claude reviews.
Design doc reference: "Architecture" → "Rules" (module contract, one event frame, map tick, safe calls).

## What this step is for

Today `Core.lua` has one frame that listens to one event (`PLAYER_LOGIN`) with one hard-wired handler. From M3 on, several modules (ZoneLabels, Instances, Tooltip) need to react to events, be switched on and off, and follow the cursor while the map is open. Step 2.4 builds the three services they will use, so no module ever creates its own frame or `OnUpdate`:

| Service | API for modules | Think of it as |
| --- | --- | --- |
| Event dispatcher | `ns.RegisterEvent(event, handler)`, `ns.UnregisterEvent(event, handler)` | A pub/sub bus over the game's events, on one shared frame |
| Module registry | `ns.RegisterModule(name, module)` | A service locator: modules register, the core starts them |
| Map tick | `ns.RegisterMapTick(handler)`, `ns.UnregisterMapTick(handler)` | A 10 Hz timer that runs only while the world map is open |

Nothing visible changes for the player yet; each part has a temporary test in `Core.lua` to see it work in game, removed before the commit.

## Decisions

- Three checkpoints: 2.4a, 2.4b, 2.4c. Each one ends with checks, an in-game test, review and its own commit.
- No `ADDON_LOADED` fallback for the map: P4 showed `WorldMapFrame` exists at `PLAYER_LOGIN`. If it is ever missing, print a clear error and skip the map tick. The design doc is updated to match (Claude does this with the 2.4c commit).
- Handlers are stored as **sets**: `handlers[fn] = true`. Registering the same function twice is harmless, unregistering is `handlers[fn] = nil`, and order between handlers is not guaranteed (no module may depend on it).
- Every call into module code (event handlers, `OnEnable`, tick handlers) goes through `ns.SafeCall`, so one module's error is printed and the others still run (doc rule "Safe calls").
- Dot form for core functions: `function ns.RegisterEvent(event, handler)`, called as `ns.RegisterEvent(...)`. `ns` is a single namespace, so its functions need no `self` (a colon definition adds an unused `self` that luacheck flags as 212). Module methods (`OnEnable`, `OnDisable`) keep the colon: they work on their own module table through `self`. Never mix the two forms for one function: a colon call to a dot function shifts every argument by one, silently.

## 2.4a: event dispatcher (`Core.lua`)

What to build:

- A file-level `local handlersByEvent = {}`: `handlersByEvent[event]` is a set of handler functions.
- `ns.RegisterEvent(event, handler)`: if there is no set for this event yet, create it **and** call `eventFrame:RegisterEvent(event)` (only the first time). Then add the handler.
- `ns.UnregisterEvent(event, handler)`: remove the handler from the set. Optional: when the set becomes empty, `eventFrame:UnregisterEvent(event)` and drop the set (needs `next(set) == nil` to test emptiness, since `#` does not work on sets).
- The frame's `OnEvent` script becomes the dispatcher: `function(_, event, ...)` looks up the set and calls `ns.SafeCall(handler, event, ...)` for each handler. Handlers receive `(event, ...)`.
- The DB init and hello line move into a `local function OnLogin()` registered with `ns.RegisterEvent("PLAYER_LOGIN", OnLogin)`. The core uses its own bus.

Hints:

- `...` (varargs) passes the event's arguments through unchanged; you used it in `ns.Print` and `ns.SafeCall`.
- Setting an **existing** key to `nil` while iterating with `pairs` is allowed in Lua, so a handler that unregisters itself during dispatch is safe. Adding **new** keys during `pairs` is not; nothing here does that.
- `eventFrame:UnregisterEvent` is the counterpart of `RegisterEvent` on the same frame object; it is not in a probe yet, so the in-game test below confirms it (P21).

Temporary in-game test (remove before commit): register a handler for `PLAYER_TARGET_CHANGED` (P16c) that prints the event name, and a second handler for the same event that prints once, then unregisters itself.

Check in game:

```
/reload
```

Then target an NPC twice. Expected: the hello line as before; first target → both handlers print; second target → only the first prints.

## 2.4b: module registry (`Core.lua`, plus one pure function)

What to build:

- A file-level `local modules = {}`: `modules[name] = module`.
- `ns.RegisterModule(name, module)`: store it. Modules call this at file load, which runs before `PLAYER_LOGIN` (the core loads first, the modules after it in the `.toc`).
- At the end of `OnLogin` (after the DB is ready): for each registered module that is enabled, `ns.SafeCall(module.OnEnable, module)`.
- "Enabled" is a pure function in `Logic.lua`: `Logic.IsModuleEnabled(moduleSettings, name)` returns `true` unless `moduleSettings[name] == false`. A module missing from `LodestarDB.modules` (for example a new module added later) counts as enabled. Call it with `ns.db.modules`.
- `OnDisable` is part of the contract but nothing calls it yet; `/ls toggle` (step 2.5) will.

Hints:

- `module.OnEnable` is written `function Module:OnEnable()` in a module, so it expects the module as `self`: that is why the call passes `module` as the first argument.
- The registry is a plain table keyed by name, like a `std::unordered_map<std::string, Module*>`.

Tests (`tests/logic_spec.lua`, `describe("IsModuleEnabled", ...)`):

- `true` when the setting is `true`.
- `false` when the setting is `false`.
- `true` when the module has no entry.

Temporary in-game test (remove before commit): at the bottom of `Core.lua`, register two test modules, `TestA` (prints in `OnEnable`) and `TestB` (calls `error("boom")` in `OnEnable`).

Check in game:

```
/reload
```

Expected: TestA's line, plus a red `Error:` line for TestB, and no Lua error popup. Then disable TestA and reload:

```
/run LodestarDB.modules.TestA = false
```

```
/reload
```

Expected: TestA's line is gone. Afterwards clean up the test entry:

```
/run LodestarDB.modules.TestA = nil
```

## 2.4c: map tick (`Core.lua`, plus one pure function)

What to build:

- A file-level set `local tickHandlers = {}`, with `ns.RegisterMapTick(handler)` and `ns.UnregisterMapTick(handler)`.
- In `OnLogin`, before enabling modules: if `WorldMapFrame` is missing, print an error and skip the rest of this list. Otherwise hook `WorldMapFrame:HookScript("OnShow", ...)` to start the tick and `WorldMapFrame:HookScript("OnHide", ...)` to stop it (P16d).
- Start: `eventFrame:SetScript("OnUpdate", OnUpdate)`. Stop: `eventFrame:SetScript("OnUpdate", nil)`. `SetScript` on our own frame is allowed by the no-taint rule; on `WorldMapFrame` we only use `HookScript`.
- `OnUpdate(_, elapsed)` receives seconds since the last frame. Accumulate them and call every tick handler (through `ns.SafeCall`) at most once per 0.1 s.
- The throttle is a pure function in `Logic.lua`: `Logic.Throttle(accumulated, elapsed, interval)` returns `fire, newAccumulated`. It adds `elapsed`; when the sum reaches `interval` it returns `true` and the leftover within one interval (`sum % interval`), otherwise `false` and the sum. Keeping only the remainder means a lag spike (one long frame) fires one tick, not a burst of catch-up ticks on the following frames.
- Add `ns.IsMapTickRunning()` for `/ls debug` later (doc success criterion 5, "Idle cost"). It returns a file-level `tickRunning` flag set in the `OnShow` and `OnHide` hooks (no `GetScript`: not probed).

Hints:

- Keep the accumulator in a file-level `local`, and reset it to 0 when the tick starts, so a stale value from the last time the map was open does not fire an early tick.
- Remember P16d: `OnMapChanged` fires **before** `OnShow`. Nothing in this step depends on it, but code that later runs on map change must not assume the tick is already running.
- Returning two values is plain Lua: `return true, sum % interval`; the caller writes `local fire, acc = Logic.Throttle(...)`.

Tests (`describe("Throttle", ...)`):

- Below the interval: `Throttle(0, 0.05, 0.1)` → `false, 0.05`.
- Reaching it exactly: `Throttle(0.05, 0.05, 0.1)` → `true`, leftover 0.
- Crossing it: `Throttle(0.08, 0.05, 0.1)` → `true`, leftover 0.03.
- Lag spike: `Throttle(0, 0.35, 0.1)` → `true`, leftover 0.05 (one tick, not three queued).
- Use a `near(a, b)` comparison for the leftovers (floating point); `logic_spec.lua` already has one.

Temporary in-game test (remove before commit): register a tick handler that counts calls and prints the count every 10th call (about once a second).

Check in game:

```
/reload
```

Open the map, wait about three seconds, close it, wait again. Expected: a few count lines while the map is open (roughly one per second), none after closing, and counting resumes when it is opened again.

## Done when (each checkpoint)

- `scripts/check.ps1` passes (luacheck + tests).
- The in-game check behaves as described; Claude records it in `notes/beta-probes.md` (P21 for 2.4a, P22 for 2.4b, P23 for 2.4c).
- The temporary test code is removed, then the part is committed.
