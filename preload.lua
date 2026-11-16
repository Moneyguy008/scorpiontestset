-- preload.lua  (Scorpion UD preload — amongus-style script-hold)
--
-- WHAT CHANGED AND WHY (this is the fix):
--   The previous version did  Hold -> Trampolines -> RELEASE -> fetch+loadstring Scorpion.
--   That put the ENTIRE obfuscated payload -- the network fetch, the compile, and the VM
--   unpack -- OUTSIDE the quiet window, with AssetContainer already booted and sampling.
--   Fallen's AC samples memory over time (FN 207 = gcinfo + table.create/insert/clear),
--   so a VM unpacking megabytes mid-session is exactly the spike it is built to notice.
--
--   amongus does the opposite:  hold() -> request() -> loadstring() -> payload(release).
--   Nothing expensive ever happens while the anti-cheat is awake; the payload itself
--   decides when to release.
--
--   So now:  HOLD -> trampolines -> COMPILE the payload (the big allocation) -> collect
--            -> RELEASE -> run it.
--   The compile lands inside the frozen window. Execution happens after release because
--   Scorpion's WaitForChild calls need a running game.
--
-- NOTE: client-hook stealth only. Does NOT change server-side shot validation.

local REPO         = "https://raw.githubusercontent.com/Moneyguy008/scorpiontestset/main"
local SCORPION_URL = REPO .. "/scorpion.lua"
local GAME_IDS     = { 13800717766, 15479377118, 16849012343 } -- Fallen Survival place ids

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local CoreGui      = (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local CorePackages = (pcall(game.GetService, game, "CorePackages")) and game:GetService("CorePackages") or nil
local httpget      = function(url) return game:HttpGet(url) end

-- Game check
local okId, placeId = pcall(function() return game.PlaceId end)
if okId and not table.find(GAME_IDS, placeId) then return end

---------------------------------------------------------------------- 1. HOLD
local released              = false
local heldScripts           = {}
local connections           = {}

local function RunOnInstance(inst)
      if inst.ClassName ~= "LocalScript" and inst.ClassName ~= "Script" then return end
      if inst.Enabled then
            inst.Enabled = false
            table.insert(heldScripts, inst)
      end
end

local function HoldScripts()
      for _, service in game:GetChildren() do
            if service == CoreGui or service == CorePackages then continue end
            for _, inst in service:GetDescendants() do
                  RunOnInstance(inst)
            end
            table.insert(connections, service.DescendantAdded:Connect(RunOnInstance))
      end
end

local function ReleaseScripts()
      if released then return end
      released = true
      for _, c in connections do c:Disconnect() end
      for _, s in heldScripts do s.Enabled = true end
      table.clear(connections)
      table.clear(heldScripts)
end

-- FAILSAFE: if we are still holding by the time the loading screen exists, something went
-- wrong and the game is frozen. Release rather than leave the client stuck. (amongus kicks
-- here instead; releasing is friendlier and equally safe.)
task.spawn(function()
      local t0 = os.clock()
      while not released and os.clock() - t0 < 25 do task.wait(0.5) end
      if not released then
            warn("[scorpion-ud] hold exceeded 25s — releasing so the client is not stuck")
            ReleaseScripts()
      end
end)

---------------------------------------------------------- 2. TRAMPOLINES (pre-AC)
local SCORP = getgenv().__SCORP or { real = {}, hooks = {} }
getgenv().__SCORP = SCORP

local function tramp(tbl, name)
      if not tbl or type(tbl[name]) ~= "function" or SCORP.real[name] then return end
      SCORP.real[name] = tbl[name]
      tbl[name] = function(...)
            local h = SCORP.hooks[name]
            if h then return h(...) end
            return SCORP.real[name](...)
      end
end

local function InstallTrampolines()
      local Mods = RS:WaitForChild("Modules", 30)
      if not Mods then return false end
      pcall(function()
            local m = require(Mods:WaitForChild("VFXModule", 15))
            tramp(m, "CreateProjectile"); tramp(m, "CreateBlood"); tramp(m, "CreateHole")
      end)
      pcall(function()
            local m = require(Mods:WaitForChild("ItemClass", 15))
            tramp(m, "AttachmentStats")
      end)
      pcall(function()
            local m = require(Mods:WaitForChild("RaycastUtil", 15))
            tramp(m, "Raycast")
      end)
      pcall(function()
            if setreadonly then setreadonly(math, false) end
            SCORP.real.abs = math.abs
            math.abs = function(...)
                  local h = SCORP.hooks.abs
                  if h then return h(...) end
                  return SCORP.real.abs(...)
            end
            if setreadonly then setreadonly(math, true) end
      end)
      return true
end

---------------------------------------------------------------- 3. ORCHESTRATE
HoldScripts()              -- freeze the game (and the AC bootstrap) first
InstallTrampolines()       -- swap the module functions while nothing is watching

-- ===== the payload is fetched and COMPILED here, INSIDE the frozen window =====
-- SCORP_SRC is embedded by main.lua so there is no network round-trip at teleport.
-- Falls back to HttpGet if it was not embedded.
local payloadFn
do
      local src = SCORP_SRC
      if type(src) ~= "string" or #src == 0 then
            local ok, fetched = pcall(httpget, SCORPION_URL)
            if ok and type(fetched) == "string" then src = fetched end
      end

      if type(src) == "string" and #src > 0 then
            local fn, err = loadstring(src, "=Animate")   -- innocuous chunkname
            if type(fn) == "function" then
                  payloadFn = fn
            else
                  warn("[scorpion-ud] payload syntax error: " .. tostring(err))
            end
      else
            warn("[scorpion-ud] could not obtain the payload source")
      end

      -- collapse the transient garbage from compiling before anything starts watching
      pcall(function() collectgarbage("collect") end)
end

ReleaseScripts()           -- only NOW does the game (and the AC) boot

task.spawn(function()
      if not payloadFn then return end
      task.wait(0.5)       -- let the game come up; Scorpion's WaitForChilds need it
      local ok, err = pcall(payloadFn)
      if not ok then warn("[scorpion-ud] payload runtime error: " .. tostring(err)) end
end)
