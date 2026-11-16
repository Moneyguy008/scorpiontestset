-- main.lua  (Scorpion UD loader — run this from the LOBBY)
--
-- WHAT CHANGED AND WHY:
--   It now fetches BOTH preload.lua and scorpion.lua here in the LOBBY, and embeds both
--   into the queued string. That means at teleport there is ZERO network traffic: the
--   script-hold starts instantly and the payload source is already in hand, so it can be
--   compiled inside the frozen window instead of after release.
--
--   The lobby has no anti-cheat, so doing the network here costs nothing.
--
-- Usage: inject / run this while sitting in the Fallen Survival LOBBY, then join a server.

local REPO         = "https://raw.githubusercontent.com/Moneyguy008/scorpiontestset/main"
local PRELOAD_URL  = REPO .. "/preload.lua"
local SCORPION_URL = REPO .. "/scorpion.lua"

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

local function fetch(url, what)
      local ok, body = pcall(function() return game:HttpGet(url) end)
      if not ok or type(body) ~= "string" or #body == 0 then
            warn(("[scorpion-ud] failed to fetch %s from %s"):format(what, url))
            return nil
      end
      print(("[scorpion-ud] fetched %s (%d bytes)"):format(what, #body))
      return body
end

local preloadSrc = fetch(PRELOAD_URL, "preload.lua")
if not preloadSrc then return end

-- Fetch the payload HERE, in the lobby, so the teleport-side hold needs no network.
local scorpionSrc = fetch(SCORPION_URL, "scorpion.lua")
if not scorpionSrc then
      warn("[scorpion-ud] continuing without an embedded payload — preload will HttpGet it")
      scorpionSrc = ""
end

-- Embed BOTH. SCORP_SRC is declared first so preload.lua (same chunk) can see it.
local queued = string.format("local SCORP_SRC = %q\n%s", scorpionSrc, preloadSrc)

queue(queued)

print(("[scorpion-ud] queued %d bytes (preload %d + payload %d). Press Play.")
      :format(#queued, #preloadSrc, #scorpionSrc))
