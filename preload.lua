-- preload.lua  (Scorpion UD preload — amongus-style script-hold)
--
-- Runs on teleport INTO Fallen Survival, queued by main.lua via queue_on_teleport so it
-- executes before the game's own scripts. It:
--   1. HOLDS every game LocalScript/Script disabled (freezes the game, incl. the AC
--      bootstrap ReplicatedFirst.Preload — so AssetContainer has NOT run yet).
--   2. Installs Scorpion's trampolines on the AC-watched module functions while frozen,
--      so when AssetContainer finally runs it captures our trampolines AS the baseline
--      and its self-probe (islclosure/checkcaller/getrawmetatable) finds no tamper diff.
--   3. RELEASES the scripts; the game boots on top of the already-installed trampolines.
--   4. Loads the (patched) Scorpion, which only writes handler closures into the
--      __SCORP.hooks slots — plain table writes the AC does not watch.
--
-- NOTE: this is client-hook stealth only. It does NOT change server-side shot validation;
-- if the server independently re-checks combat geometry, silent aim can still flag.

local REPO         = "https://raw.githubusercontent.com/YOURUSER/YOURREPO/main/FallenSurvival"
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
ReleaseScripts()           -- game boots on top of our trampolines

task.spawn(function()      -- load Scorpion in the normal post-release environment
      local ok, src = pcall(httpget, SCORPION_URL)
      if not ok or type(src) ~= "string" then
            warn("[scorpion-ud] failed to fetch scorpion.lua")
            return
      end
      local fn, err = loadstring(src)
      if type(fn) ~= "function" then
            warn("[scorpion-ud] scorpion.lua syntax error: " .. tostring(err))
            return
      end
      fn()                 -- fills __SCORP.hooks; trampolines route to them
end)
