--!strict
-- V6-1: the notification centre. Everything that pops up by itself goes through here, under the
-- rules in Shared/NotifyRules: one big pop-up at a time with a gap between, small messages by
-- priority with a gap by kind, the same message never twice in two minutes, nothing but critical
-- in a newcomer's first 90 s (FirstVisit's NewcomerUntil) or right after a window closes, and
-- tips the player tapped away stay away. Replies to the player's own presses still call Toast
-- directly (they are answers, not interruptions).
--
--   Notify.push(text, kind, { key?, color?, icon? })   kind: "critical" | "reward" | "info" | "tip"
--   Notify.waitBig(name)   yields until a self-opening window/card may come up, then claims it
--   Notify.goodMoment()    after a wow moment: may ask for Roblox Experience Notifications opt-in
-- Config.NOTIFY = false sends everything straight to Toast as before.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NotifyRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NotifyRules"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast")) :: any

local Notify = {}

type Item = { text: string, kind: string, key: string, color: Color3?, icon: string?, at: number }

local state = NotifyRules.new()
if (Config :: any).V8_ONE_VOICE then
	NotifyRules.EARLY_GAP = 15 -- (V8-0.4: one toast per 15 s in the first 3 minutes)
	NotifyRules.EARLY_START = os.clock() - time() -- (the visit started time() s ago; blind review)
end
local queue: { Item } = {}
local bigNames: { [string]: boolean } = {} -- windows that opened by themselves (claimed here)
local started = false
local revealTrimmed = false
local player = Players.LocalPlayer

local COLORS = {
	critical = Color3.fromRGB(255, 120, 110),
	reward = Color3.fromRGB(120, 230, 140),
	info = Color3.fromRGB(245, 244, 240),
	tip = Color3.fromRGB(190, 210, 255),
}

local function on(): boolean
	return (Config :: any).NOTIFY ~= false
end

local chime: Sound? = nil
local function softSound()
	-- (A soft click through the UI mix group; rewards and critical only.)
	if not chime then
		local s = Instance.new("Sound")
		s.Name = "NotifyChime"
		s.SoundId = (Theme.Sounds and Theme.Sounds.click) or ""
		s.Volume = 0.3
		s.PlaybackSpeed = 1.25
		local ok, SoundMix = pcall(function()
			return require(Client:WaitForChild("SoundMix")) :: any
		end)
		if ok then
			s.SoundGroup = SoundMix.group("UI")
		end
		s.Parent = SoundService
		chime = s
	end
	if chime and chime.SoundId ~= "" then
		chime:Play()
	end
end

local function show(it: Item)
	NotifyRules.shown(state, it.kind, it.key, os.clock())
	local onTap: (() -> ())? = nil
	if it.kind == "tip" then
		-- "Don't show again": a tip tapped away stays away this visit.
		onTap = function()
			state.muted[it.key] = true
		end
	end
	if it.kind == "reward" or it.kind == "critical" then
		softSound()
	end
	Toast.show(it.text, it.color or COLORS[it.kind], nil, it.icon, onTap)
end

local function newcomerQuiet(): number
	local untilT = player:GetAttribute("NewcomerUntil")
	-- (Kept after it has passed too: the expiry clock of what waited starts there.)
	if type(untilT) == "number" then
		return os.clock() + (untilT - time())
	end
	return 0
end

local function tick()
	if #queue == 0 then
		return
	end
	local now = os.clock()
	state.newcomerUntil = newcomerQuiet()
	-- (At a newcomer's reveal, of the rewards that waited only the newest NOTIFY_REVEAL_KEEP come out:
	-- the early unlocks are on the bar anyway, and the reveal must not turn into a burst.)
	if not revealTrimmed and state.newcomerUntil > 0 and now >= state.newcomerUntil then
		revealTrimmed = true
		local keep = (Config :: any).NOTIFY_REVEAL_KEEP or 2
		local rewards = 0
		for i = #queue, 1, -1 do
			local it = queue[i]
			if it.kind == "reward" and it.at < state.newcomerUntil then
				rewards += 1
				if rewards > keep then
					table.remove(queue, i)
				end
			end
		end
	end
	-- (One at a time on screen: the next waits for the toast to go.)
	local busy = Toast.isShowing() or Toast.isPaused() -- (a held Toast would only queue and drop it)
	local order: { number } = {}
	for i in queue do
		table.insert(order, i)
	end
	table.sort(order, function(a, b)
		local pa = NotifyRules.PRIORITY[queue[a].kind] or 0
		local pb = NotifyRules.PRIORITY[queue[b].kind] or 0
		if pa ~= pb then
			return pa > pb
		end
		return queue[a].at < queue[b].at
	end)
	local drop: { [number]: boolean } = {}
	local shownOne = false
	for _, i in order do
		local it = queue[i]
		local verdict = NotifyRules.decide(state, it.kind, it.key, it.at, now)
		if verdict == "drop" then
			drop[i] = true
		elseif verdict == "show" and not shownOne and (not busy or it.kind == "critical") then
			show(it)
			drop[i] = true
			shownOne = true
		end
	end
	for i = #queue, 1, -1 do
		if drop[i] then
			table.remove(queue, i)
		end
	end
end

function Notify.start()
	if started then
		return
	end
	started = true
	-- (A window the player opened before the first message counts too.)
	state.playerWindow = Controller.getCurrent() ~= nil
	Controller.onChanged(function(name: string, isOpen: boolean)
		local now = os.clock()
		if bigNames[name] then
			if not isOpen then
				bigNames[name] = nil
				NotifyRules.bigClosed(state, name, now)
			end
			return
		end
		if isOpen then
			state.playerWindow = true
		else
			state.playerWindow = Controller.getCurrent() ~= nil
			NotifyRules.bigClosed(state, "", now) -- (only the quiet beat after it)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(tick)
			if not ok then
				warn("[Notify] " .. tostring(err))
			end
		end
	end)
end

function Notify.push(text: string, kind: string?, opts: { key: string?, color: Color3?, icon: string? }?)
	local k = if kind and NotifyRules.PRIORITY[kind] then kind else "info"
	local o = opts or {}
	if not on() then
		Toast.show(text, o.color or COLORS[k], nil, o.icon)
		return
	end
	Notify.start()
	local key = o.key or text
	for _, it in queue do
		if it.key == key and k ~= "reward" then
			it.text = text -- (the newest wording wins; it keeps its place)
			return
		end
	end
	table.insert(queue, { text = text, kind = k, key = key, color = o.color, icon = o.icon, at = os.clock() })
end

-- Yields until a window that opens by itself may come up, then claims the big slot for `name`
-- (released when the kit says the window closed). Gives up after `maxWait` (returns false).
function Notify.waitBig(name: string, maxWait: number?): boolean
	if not on() then
		return true
	end
	Notify.start()
	local t0 = os.clock()
	while true do
		state.newcomerUntil = newcomerQuiet()
		-- (A newcomer's first big pop-up comes NOTIFY_BIG_AFTER_REVEAL s after the HUD is in, not with it.)
		local reveal = player:GetAttribute("NewcomerUntil")
		local bigFrom = if type(reveal) == "number" then reveal + ((Config :: any).NOTIFY_BIG_AFTER_REVEAL or 20) else 0
		-- (V8-0.6: no window opens by itself for a newcomer before CALM_MODALS_AFTER s: the egg
		-- card, What's New and the favourite ask blocked play at 60-70 s.)
		if (Config :: any).V8_CALM_START and player:GetAttribute("Newcomer") == true then
			bigFrom = math.max(bigFrom, (Config :: any).CALM_MODALS_AFTER)
		end
		if NotifyRules.bigAllowed(state, os.clock()) and time() >= bigFrom then
			break
		end
		if maxWait and os.clock() - t0 > maxWait then
			return false
		end
		task.wait(0.5)
	end
	bigNames[name] = true
	NotifyRules.bigOpened(state, name)
	-- (A window the kit refused to open never reports closing: free the slot after a beat.)
	if name ~= "NotifyOptIn" then
		task.delay(2, function()
			if bigNames[name] and not Controller.isOpen(name) then
				Notify.releaseBig(name)
			end
		end)
	end
	return true
end

-- Frees the big slot claimed for `name` without a window (it was not needed after all).
function Notify.releaseBig(name: string)
	if bigNames[name] then
		bigNames[name] = nil
		-- (Nothing showed: the slot frees with no gap and no quiet after it.)
		if state.bigOpen == name then
			state.bigOpen = nil
		end
	end
end

-- Whether a big pop-up could come up right now (for code that only offers, never waits).
function Notify.bigFree(): boolean
	return not on() or NotifyRules.bigAllowed(state, os.clock())
end

-- Roblox Experience Notifications: asked once a visit, after a wow moment, never in the first
-- NOTIFY_OPTIN_AFTER seconds of play (Config.EXPERIENCE_NOTIFY). Roblox shows its own prompt; the
-- messages themselves are set up by the owner on the Creator Dashboard (docs/V6_PLAN.md).
local askedOptIn = false
function Notify.goodMoment()
	if askedOptIn or not (Config :: any).EXPERIENCE_NOTIFY then
		return
	end
	if time() < ((Config :: any).NOTIFY_OPTIN_AFTER or 480) then
		return
	end
	askedOptIn = true
	task.spawn(function()
		local ok, service = pcall(function()
			return game:GetService("ExperienceNotificationService")
		end)
		if not ok or not service then
			return
		end
		local can = false
		pcall(function()
			can = (service :: any):CanPromptOptInAsync()
		end)
		if not can then
			return
		end
		-- (A Like card from the same wow may hold the slot first: wait for it and its gap.)
		if not Notify.waitBig("NotifyOptIn", 300) then
			return
		end
		-- (The slot frees when Roblox says its prompt closed, or after 30 s if that never comes.)
		local freed = false
		local function free()
			if not freed then
				freed = true
				bigNames["NotifyOptIn"] = nil
				NotifyRules.bigClosed(state, "NotifyOptIn", os.clock())
			end
		end
		pcall(function()
			(service :: any).OptInPromptClosed:Once(free)
		end)
		local okPrompt = pcall(function()
			(service :: any):PromptOptIn()
		end)
		task.delay(if okPrompt then 30 else 0, free)
	end)
end

-- The same arguments as Toast.show, with the kind first (so a Toast call converts in place).
function Notify.say(kind: string, text: string, color: Color3?, key: string?)
	Notify.push(text, kind, { color = color, key = key })
end

-- For T100 and the debug tab: a copy of what waits.
function Notify.pending(): { { text: string, kind: string } }
	local out = {}
	for _, it in queue do
		table.insert(out, { text = it.text, kind = it.kind })
	end
	return out
end

return Notify
