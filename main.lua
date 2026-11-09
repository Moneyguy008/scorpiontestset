-- main.lua  (Scorpion UD loader — run this from the LOBBY)
--
-- Fetches preload.lua and queue_on_teleport's it so it runs the instant you teleport into
-- a Fallen Survival server — BEFORE the game's scripts (and anti-cheat) execute. The full
-- preload source is embedded into the queued string so there is no network delay on
-- teleport (the script-hold must happen immediately, before any game script runs).
--
-- Usage: inject / run this while sitting in the Fallen Survival LOBBY, then join a server.

local REPO        = "https://raw.githubusercontent.com/YOURUSER/YOURREPO/main/FallenSurvival"
local PRELOAD_URL = REPO .. "/preload.lua"

local queue = queue_on_teleport
      or queueonteleport
      or queueteleport
      or (syn and syn.queue_on_teleport)
      or (fluxus and fluxus.queue_on_teleport)

if type(queue) ~= "function" then
      local msg = "[scorpion-ud] your executor has no queue_on_teleport.\n"
            .. "Use a supported executor, or run preload.lua yourself right after you join."
      warn(msg)
      pcall(function() if messagebox then messagebox(msg, "scorpion-ud", 48) end end)
      return
end

local ok, preloadSrc = pcall(function() return game:HttpGet(PRELOAD_URL) end)
if not ok or type(preloadSrc) ~= "string" then
      warn("[scorpion-ud] failed to fetch preload.lua from " .. PRELOAD_URL)
      return
end

-- Embed the full preload so the hold runs with zero network latency on teleport.
queue(string.format("loadstring(%q)()", preloadSrc))

print("[scorpion-ud] queued. Join a Fallen Survival server from the lobby.")
