--!strict
-- The first minute, taught by doing (no intro, no shop, no button to press first):
--   0 s      you appear with the Blaster in hand and the starter bar; a dummy walks up to you
--            (GreeterService) under a bouncing arrow; one line: "Tap the dummy to shoot!"
--   1-5 s    the first shot; then "Now try another tool!" and, once, the choice of view (walk as
--            yourself or the lab view), with how to switch back on the card itself
--   later    the first big moment plays back as an Instant Replay and opens the whole catalog (or
--            25 s after you appeared); later big moments offer a Replay button
--   +10 s    if you never flopped yourself yet: "Press F / Tap RAGDOLL" and the button bounces
-- Been here before (the server remembers): no intro, everything open, your view as you left it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Config = require(Shared:WaitForChild("Config"))
local PadMap = require(Shared:WaitForChild("PadMap"))

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local ToolCatalog = require(Client:WaitForChild("ToolCatalog"))
local FxController = require(Client:WaitForChild("FxController"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local Toast = require(Client:WaitForChild("Toast"))
local Notify = require(Client:WaitForChild("Notify")) :: any -- V6-1: what pops up by itself goes through the notification centre
local PlayerBody = require(Client:WaitForChild("PlayerBody"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local HudSlots = require(Client:WaitForChild("HudSlots"))

local player = Players.LocalPlayer

-- Phase 0: a tip waits at least `delay` s, and until the quiet start (Config.QUIET_START) is over.
local function afterQuiet(delay: number, fn: () -> ())
	task.delay(math.max(delay, Config.QUIET_START - time()), fn)
end

-- Phase 0: the button's name when the last input was a gamepad (Shared\PadMap), else nil.
local function padGlyph(name: string): string?
	local UIS = game:GetService("UserInputService")
	if not PadMap.isPad(UIS:GetLastInputType()) then
		return nil
	end
	local ok, a = pcall(function()
		return UIS:GetStringForKeyCode(Enum.KeyCode.ButtonA)
	end)
	local ps = ok and type(a) == "string" and string.find(string.lower(a), "cross", 1, true) ~= nil
	return PadMap.glyph(name, ps)
end
local function weaponsCall(): string
	local y = padGlyph("Weapons")
	return if y then "Press " .. y .. " for WEAPONS" else "Tap WEAPONS"
end

-- The first minute's bar is the bar you keep (no swap after the first replay).
local STARTERS = Toys.defaultLoadout
local REPLAY_OFFER_SECONDS = 6
local REPLAY_OFFER_GAP = 20 -- s between two replay offers (not after every big hit)
local UNLOCK_FALLBACK = Toys.UNLOCK_FALLBACK -- the server keeps the same clock (OnboardingService)
local REPLAY_DELAY = 1.9 -- wait for the moment to finish before replaying it
local RAGDOLL_TIP_DELAY = 10 -- s after the first replay: if you never flopped yourself, a tip
local CHOICE_DELAY = 3 -- s after the first shot: the choice of view (when the player pauses)
local CHOICE_FALLBACK = 15 -- s: asked anyway if there was no shot by then
local HAZARD_TIP_DELAY = 16 -- s after the unlock: the lava, the cannon and its bullseye

local OnboardingController = {}

local gui: ScreenGui
local stage: "Spawn" | "FirstToy" | "Free" = "Spawn"
local whenFree: { () -> () } = {} -- told once, when the first minute's weapons unlock
local released = false

-- The first minute is over (its replay may still be playing).
local function becomeFree()
	stage = "Free"
end

-- Everything the first minute held back shows at one moment: the bar's whole loadout and
-- WEAPONS (PokeController.setAllowed(nil)), and with them SANDBOX and the Robux packs (whenFree).
local function release()
	PokeController.setAllowed(nil)
	if released then
		return
	end
	released = true
	local list = whenFree
	whenFree = {}
	for _, fn in list do
		task.spawn(fn)
	end
	-- (10 Nov 2026: the game's picture is bodies flying over lava and spikes. A new player is pointed
	-- at the lab's own: after the unlock and the gift's line.)
	if player:GetAttribute("Returning") ~= true then
		afterQuiet(HAZARD_TIP_DELAY, function()
			-- (Only with a lab of their own: the hazards are in the labs, not the plaza.)
			local plot = player:GetAttribute("LabPlot")
			-- (V8-0.4: not once they have done it: no tip for a thing already done.)
			local done = (Config :: any).V8_ONE_VOICE and (((player:GetAttribute("CannonShots") :: number?) or 0) > 0 or player:GetAttribute("HazardDone") == true)
			if not done and not ReplayController.isPlaying() and type(plot) == "number" and plot > 0 then
				Notify.say("tip", if (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).BULLSEYE == false then "Jump in the LAVA or blast off the CANNON!" else "Jump in the LAVA or blast off the CANNON at the BULLSEYE!", Color3.fromRGB(255, 140, 40), "tip_machines")
			end
		end)
	end
end
local tried: { [string]: boolean } = {}
local hint: TextLabel? = nil
local replayButton: TextButton? = nil
local offeredAt: number? = nil
local firstShotDone = false
local replayQueued = false -- the first big moment's replay is about to play (the view card waits)
local askChoiceLater: () -> () = function() end -- set below (the view card asks again after a replay)

local function pulse(object: GuiObject)
	if Theme.isReducedMotion() then
		return -- Reduced Motion: it stands out by its colour alone
	end
	local scale = Instance.new("UIScale")
	scale.Parent = object
	local tween = TweenService:Create(scale, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Scale = 1.08,
	})
	tween:Play()
end

local function makeButton(name: string, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color
	b.Text = text
	KitStyle.button(b)
	b.TextSize = math.clamp(math.floor(size.Y.Offset * 0.42), 18, 36)
	b.Parent = gui
	return b
end

local function showHint(text: string)
	if hint then
		hint:Destroy()
	end
	local label = Instance.new("TextLabel")
	label.Name = "Hint"
	label.AnchorPoint = Vector2.new(0.5, 1)
	-- Just above the tool bar, however tall it is on this screen.
	label.Position = UDim2.new(0.5, 0, 1, -(PokeController.height() + 14))
	label.Size = UDim2.fromOffset(260, 44) -- 44: clear of a three-line toast above it on a phone
	label.BackgroundColor3 = Theme.Palette.dusk
	label.BackgroundTransparency = Theme.Glass.panel
	label.Text = text
	KitStyle.label(label)
	-- (Dark glass with a gold edge: it still draws the eye in the first minute.)
	local edge = label:FindFirstChildOfClass("UIStroke")
	if edge then
		edge.Color = Theme.Palette.gold
		edge.Thickness = 2
	end
	-- (Out of the way while a hit line shows in the same place: HitInfo.)
	label.Visible = gui:GetAttribute("HitLine") ~= true
	label.Parent = gui
	pulse(label)
	hint = label
	-- (Phase 0: one hint at a time: the first minute's line steps aside while a toast shows.)
	task.spawn(function()
		while hint == label and label.Parent do
			label.Visible = gui:GetAttribute("HitLine") ~= true and not Toast.isShowing()
			task.wait(0.15)
		end
	end)
end

local function clearHint()
	if hint then
		hint:Destroy()
		hint = nil
	end
end

local function playReplay(at: number, first: boolean)
	task.wait(math.max(0, at + REPLAY_DELAY - os.clock()))
	local completed = ReplayController.play(at)
	if first then
		replayQueued = false
		askChoiceLater() -- the card that waited (also when the replay had too little to show)
		Net.event(Net.Names.Onboarding):FireServer(if completed then "ReplayDone" else "ReplaySkipped")
		release()
		-- (Audit area 1: a newcomer hears this once the HUD is in, never over the first objective.)
		task.spawn(function()
			while time() < HudSlots.newcomerUntil do
				task.wait(0.5)
			end
			-- (V8-0.4: the starters were never unlocked; that toast was not true.)
			if not (Config :: any).V8_ONE_VOICE then
				Notify.say("reward", Toys.starterCount() .. " weapons unlocked! " .. weaponsCall(), Color3.fromRGB(120, 230, 140))
			end
		end)
		PokeController.highlightTools()
	end
end

local function offerReplay(at: number)
	-- (Audit area 1: not in a newcomer's first 90 s: one objective, nothing else to press.)
	if not HudSlots.shownNow("Replay", HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()), time(), Config.QUIET_START) then
		return
	end
	offeredAt = at
	if not replayButton then
		-- Top right, under LAB VIEW (HudSlots keeps it clear of everything else).
		local b = makeButton("ReplayButton", "Replay", UDim2.fromOffset(120, 52), UDim2.new(), KitStyle.GO)
		HudSlots.apply(b, "Replay", HudSlots.context(ViewMode.isTouch(), ViewMode.isLab()))
		b.Activated:Connect(function()
			local when = offeredAt
			b.Visible = false
			if when and not ReplayController.isPlaying() then
				task.spawn(playReplay, when, false)
			end
		end)
		replayButton = b
	end
	local b = replayButton :: TextButton
	b.Visible = true
	task.delay(REPLAY_OFFER_SECONDS, function()
		if offeredAt == at then
			b.Visible = false
		end
	end)
end

local lastOwnBigToy = 0
local lastOffer = -math.huge

local function onBigEvent(_toyId: string, at: number, _position: Vector3)
	-- The first replay must be of the player's own doing, not something else in the world.
	if stage == "FirstToy" and os.clock() - lastOwnBigToy < 4 then
		-- The player's first big moment always plays back once, on its own.
		becomeFree()
		clearHint()
		replayQueued = true -- the view card waits for it (and for the unlock toast after it)
		task.spawn(playReplay, at, true)
		-- The next verb, taught only to those who have not found it: your own body is a ragdoll too.
		afterQuiet(RAGDOLL_TIP_DELAY, function()
			if not PlayerBody.hasGoneLimp() and not ViewMode.isLab() then
				local b = padGlyph("Ragdoll")
				Notify.say("tip", if b then "Press " .. b .. " to ragdoll yourself!" elseif ViewMode.isTouch() then "Tap RAGDOLL to flop yourself!" else "Press F to ragdoll yourself!", nil, "tip_ragdoll")
				PlayerBody.highlight()
			end
		end)
	elseif stage == "Free" and not ReplayController.isPlaying() and os.clock() - lastOffer >= REPLAY_OFFER_GAP then
		lastOffer = os.clock()
		offerReplay(at)
	end
end


-- The greeter's pointer: a gold marker bobbing over the dummy that walks up to you, until the first
-- shot (a small neon diamond in the world, only on this client; it never blocks a tap).
local pointer: BasePart? = nil
local pointerFollow: RBXScriptConnection? = nil

local function clearPointer()
	if pointerFollow then
		pointerFollow:Disconnect()
		pointerFollow = nil
	end
	if pointer then
		pointer:Destroy()
		pointer = nil
	end
end

local function pointAt(model: Model)
	clearPointer()
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	local marker = Instance.new("Part")
	marker.Name = "GreeterPointer"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.CastShadow = false
	marker.Material = Enum.Material.Neon
	marker.Color = Color3.fromRGB(255, 214, 70)
	marker.Size = Vector3.new(1.1, 1.1, 1.1)
	local outline = Instance.new("SelectionBox")
	outline.Adornee = marker
	outline.Color3 = Theme.Palette.ink
	outline.LineThickness = 0.06
	outline.Parent = marker
	marker.Parent = workspace:FindFirstChild("LocalFx") or workspace
	pointer = marker
	local still = Theme.isReducedMotion()
	pointerFollow = RunService.RenderStepped:Connect(function()
		if not head.Parent then
			clearPointer()
			return
		end
		local t = os.clock()
		local bob = if still then 0 else 0.35 * math.sin(t * 5)
		marker.CFrame = CFrame.new(head.Position + Vector3.new(0, 3 + bob, 0))
			* CFrame.Angles(0, if still then 0 else t * 2, 0)
			* CFrame.Angles(math.rad(45), 0, math.rad(45))
	end)
end

-- The view card's state (the card itself is further down).
local CHOICE_SIZE = Vector2.new(270, 104) -- clear of the chaos meter and THROW on the smallest phone (LayoutCheck)
local CHOICE_TIME = 10 -- s before it closes by itself (nothing changes)
local CHOICE_QUIET = 1.2 -- s without a tap before it may come
local CHOICE_ARM = 0.4 -- s after it appears before its buttons take a tap (a tap meant for a dummy)
local choiceCard: Frame? = nil
local choiceAsked = false
local choicePending = false
local lastUse = -math.huge
-- Finds this player's greeter (GreeterService) as it appears and points at it (until the first shot).
local greeterWatch: RBXScriptConnection? = nil
local greeterModel: Model? = nil

local function shootHint()
	local fire = padGlyph("Fire")
	showHint(if fire then "Press " .. fire .. " to shoot!" elseif ViewMode.isTouch() then "Tap the dummy to shoot!" else "Click the dummy to shoot!")
end

local function watchGreeter()
	local dummies = workspace:WaitForChild("Dummies", 10)
	if not dummies then
		return
	end
	local function check(model: Instance)
		if model:IsA("Model") and model:GetAttribute("Greeter") == player.UserId then
			greeterModel = model
			model:WaitForChild("Head", 5)
			if stage == "FirstToy" and not firstShotDone and not choiceCard then
				pointAt(model)
			end
		end
	end
	greeterWatch = dummies.ChildAdded:Connect(check)
	for _, model in dummies:GetChildren() do
		check(model)
	end
end

local function stopWatchingGreeter()
	if greeterWatch then
		greeterWatch:Disconnect()
		greeterWatch = nil
	end
	clearPointer()
end

------------------------------------------------------------------------------------------------
-- Walk, or the lab view from above? Asked once, a few seconds after the first shot when the player
-- pauses (never in the middle of tapping, never over a replay), with how to switch back on the card
-- itself. Whatever view the player is in is kept for next time, whichever way they switched.
------------------------------------------------------------------------------------------------

local function triedOther(): boolean
	for id in tried do
		if id ~= "Blaster" then
			return true
		end
	end
	return false
end

local function closeChoice()
	if choiceCard then
		choiceCard:Destroy()
		choiceCard = nil
	end
	Toast.setPaused(false)
	-- The guidance comes back: still no shot, the shoot hint and marker; shot but still in the first
	-- minute, the nudge to try another tool.
	if stage == "FirstToy" and not firstShotDone then
		shootHint()
		local model = greeterModel
		if model and model.Parent then
			pointAt(model)
		end
	elseif stage == "FirstToy" and not triedOther() then
		showHint("Now try another tool!")
	end
end

-- A replay starts while the card is up: it goes and is asked again after the replay (its time would
-- otherwise run out unseen behind the replay).
local function setChoiceAside()
	local card = choiceCard
	if card then
		card:Destroy()
		choiceCard = nil
		Toast.setPaused(false)
		choiceAsked = false
		choicePending = true
	end
end

local function choose(mode: "Player" | "Lab")
	closeChoice()
	ViewMode.set(mode) -- saved by the view watcher below
	local key = if ViewMode.isTouch() then "" else " (or press " .. Keybinds.labelOf("View") .. ")"
	Toast.show(if mode == "Lab"
		then "Back to walking any time: WALK, top right" .. key
		else "Lab view any time: LAB VIEW, top right" .. key)
end

local askChoice: () -> ()

function askChoice()
	if choiceAsked or player:GetAttribute("Returning") == true then
		return -- once, and only for new players
	end
	if not Config.VIEW_CARD then
		choiceAsked = true -- (phase 0: no card; the player view, LAB VIEW stays a button)
		choicePending = false
		return
	end
	-- Not over a replay, nor one about to start (asked after it), and not while the player is busy
	-- tapping (a moment later).
	if ReplayController.isPlaying() or replayQueued then
		choicePending = true
		return
	end
	-- Never over the catalog or the pick chip: asked again once the catalog closes / the pick ends.
	if ToolCatalog.isOpen() or PokeController.isPicking() then
		choicePending = true
		task.delay(1.5, askChoice)
		return
	end
	if os.clock() - lastUse < CHOICE_QUIET then
		task.delay(CHOICE_QUIET, askChoice)
		return
	end
	choiceAsked = true
	choicePending = false
	clearHint()
	clearPointer()
	Toast.setPaused(true) -- the card sits where toasts would go on a phone; they wait
	local P = Theme.Palette
	local card = Instance.new("Frame")
	card.Name = "ModeChoice"
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = UDim2.new(0.5, 0, 1, -(PokeController.height() + 10))
	card.Size = UDim2.fromOffset(CHOICE_SIZE.X, CHOICE_SIZE.Y)
	card.BackgroundColor3 = P.dusk
	card.BackgroundTransparency = 0.05
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.card)
	corner.Parent = card
	local outline = Instance.new("UIStroke")
	outline.Color = P.ink
	outline.Thickness = Theme.Stroke.card
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Parent = card
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(10, 6)
	title.Size = UDim2.new(1, -20, 0, 22)
	title.FontFace = Theme.Fonts.display
	title.TextSize = 20
	title.TextColor3 = P.textHi
	title.Text = "Walk, or view from above?"
	title.Parent = card
	local shownAt = os.clock()
	local function option(name: string, text: string, x: number, color: Color3, mode: "Player" | "Lab")
		local b = Instance.new("TextButton")
		b.Name = name
		b.Position = UDim2.fromOffset(x, 32)
		b.Size = UDim2.fromOffset(119, 44)
		b.BackgroundColor3 = color
		b.Text = text
		KitStyle.button(b)
		b.TextSize = 18
		b.Parent = card
		b.Activated:Connect(function()
			if os.clock() - shownAt >= CHOICE_ARM then
				choose(mode)
			end
		end)
	end
	option("Walk", "WALK", 12, KitStyle.GO, "Player")
	option("Lab", "LAB VIEW", 139, KitStyle.SLAB, "Lab")
	local note = Instance.new("TextLabel")
	note.Name = "Note"
	note.BackgroundTransparency = 1
	note.Position = UDim2.fromOffset(10, 80)
	note.Size = UDim2.new(1, -20, 0, 18)
	note.FontFace = Theme.Fonts.body
	note.TextSize = 16
	note.TextColor3 = P.textHi
	note.Text = if ViewMode.isTouch() then "Switch any time: top-right button" else "Switch any time: top-right or " .. Keybinds.labelOf("View")
	note.Parent = card
	-- In with a small pop (a fade under Reduced Motion).
	local scale = Instance.new("UIScale")
	scale.Parent = card
	if Theme.isReducedMotion() then
		card.BackgroundTransparency = 1
		TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
	else
		scale.Scale = 0.85
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	card.Parent = gui
	choiceCard = card
	task.delay(CHOICE_TIME, function()
		if choiceCard == card then
			closeChoice()
		end
	end)
end

askChoiceLater = function()
	if choicePending then
		task.delay(2.6, askChoice) -- after the unlock toast that follows the first replay
	end
end

local function onUsed(toyId: string, _position: Vector3)
	lastUse = os.clock()
	if firstShotDone and toyId ~= "Blaster" and hint and hint.Text == "Now try another tool!" then
		clearHint() -- done: another tool tried
	end
	if stage == "FirstToy" and not firstShotDone then
		firstShotDone = true
		clearHint()
		stopWatchingGreeter()
		if not choiceCard then
			showHint("Now try another tool!") -- (the view card, if already up, keeps that place)
		end
		task.delay(CHOICE_DELAY, askChoice)
	end
	if Toys.byId[toyId] and Toys.byId[toyId].big then
		lastOwnBigToy = os.clock()
	end
	if not tried[toyId] then
		tried[toyId] = true
		if stage ~= "Spawn" and toyId ~= "Blaster" then
			Notify.say("reward", "New tool: " .. Toys.byId[toyId].label .. "!")
		end
	end
end

-- Opens the catalog on the client when the server does: UNLOCK_FALLBACK s after the avatar appeared
-- (the server's own clock, read from SpawnedAt), unless the first replay opened it already.
local function unlockFallback()
	local started = os.clock()
	while typeof(player:GetAttribute("SpawnedAt")) ~= "number" and os.clock() - started < 10 do
		task.wait(0.1)
	end
	local spawnedAt = player:GetAttribute("SpawnedAt")
	local wait = if typeof(spawnedAt) == "number"
		then (spawnedAt :: number) + UNLOCK_FALLBACK - workspace:GetServerTimeNow()
		else UNLOCK_FALLBACK
	task.wait(math.max(0, wait) + 0.2) -- just after the server, never before
	if stage == "FirstToy" then
		becomeFree()
		clearHint()
		stopWatchingGreeter()
		Net.event(Net.Names.Onboarding):FireServer("ReplaySkipped")
		release()
		-- (Audit area 1: a newcomer hears this once the HUD is in, never over the first objective.)
		task.spawn(function()
			while time() < HudSlots.newcomerUntil do
				task.wait(0.5)
			end
			-- (V8-0.4: the starters were never unlocked; that toast was not true.)
			if not (Config :: any).V8_ONE_VOICE then
				Notify.say("reward", Toys.starterCount() .. " weapons unlocked! " .. weaponsCall(), Color3.fromRGB(120, 230, 140))
			end
		end)
		PokeController.highlightTools()
	end
end

-- The first minute of a new player: Blaster in hand, the greeter walking up, one line, one marker.
local function startNew()
	stage = "FirstToy"
	PokeController.setAllowed(STARTERS)
	PokeController.select("Blaster")
	PokeController.setEnabled(true)
	shootHint()
	task.spawn(watchGreeter)
	-- Nobody shot yet after a while: the choice comes anyway (the guidance returns after it).
	task.delay(CHOICE_FALLBACK, askChoice)
	task.spawn(unlockFallback)
end

-- Been here before: everything from the first second, in the view you left in.
local function startReturning()
	becomeFree()
	choiceAsked = true -- the view question is for new players only
	choicePending = false
	if choiceCard then
		choiceCard:Destroy()
		choiceCard = nil
		Toast.setPaused(false)
	end
	clearHint()
	stopWatchingGreeter()
	release()
	PokeController.setEnabled(true)
	Notify.say("info", "Welcome back!", Color3.fromRGB(120, 230, 140))
end

local viewPickedHere = false -- the player switched the view themselves this visit
local restoringView = false -- the saved view is being put back (not a new choice)

-- Whatever view the player switches to (card, button or its key) is kept for next time; the server
-- saves it once it settles.
local function keepView()
	ViewMode.onChanged(function(mode)
		if restoringView then
			return -- the server's own answer: nothing new to keep
		end
		Net.event(Net.Names.Onboarding):FireServer("Mode", mode)
		if choiceCard then
			closeChoice() -- answered with the top-right button or its key
		end
	end)
end

-- The view you left in, once the server has said it and no replay holds the camera; never over a
-- view you already picked yourself this visit.
local function restoreView()
	local view = player:GetAttribute("PreferredView")
	if view ~= "Lab" and view ~= "Player" then
		return
	end
	while ReplayController.isPlaying() do
		task.wait(0.25)
	end
	if viewPickedHere then
		return
	end
	restoringView = true
	ViewMode.set(view)
	restoringView = false
end

local function begin()
	-- Nothing waits for the DataStore: unless the server already knows you (then straight to the
	-- returning start), the first five seconds start now; the server's answer (OnboardingReady,
	-- usually a fraction of a second, however late) switches a returning player out of the intro
	-- and restores their view. Every view change from the start is kept for next time.
	ViewMode.onChanged(function()
		if not restoringView then
			viewPickedHere = true
		end
	end)
	keepView()
	if player:GetAttribute("Returning") == true then
		startReturning()
	else
		startNew()
	end
	local function onAnswer()
		if player:GetAttribute("Returning") == true and stage ~= "Free" then
			startReturning()
		end
		task.spawn(restoreView)
	end
	if player:GetAttribute("OnboardingReady") == true then
		onAnswer()
	else
		player:GetAttributeChangedSignal("OnboardingReady"):Once(onAnswer)
	end
	player:GetAttributeChangedSignal("Returning"):Connect(function()
		if player:GetAttribute("Returning") == true and stage ~= "Free" then
			startReturning()
		end
	end)
end

function OnboardingController.start()
	local g = Instance.new("ScreenGui")
	g.Name = "Onboarding"
	g.ResetOnSpawn = false
	g.DisplayOrder = 10
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- the same frame as the kit (HudSlots)
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	g:GetAttributeChangedSignal("HitLine"):Connect(function()
		if hint then
			hint.Visible = g:GetAttribute("HitLine") ~= true
		end
	end)

	ReplayController.onStateChanged = function(isPlaying: boolean)
		-- (Building owns the bar: build mode turns it off and back on itself.)
		if player:GetAttribute("Building") ~= true then
			PokeController.setEnabled(not isPlaying and stage ~= "Spawn")
		end
		g.Enabled = not isPlaying
		if isPlaying then
			setChoiceAside()
		else
			askChoiceLater() -- the view question that waited: after the replay and its unlock toast
		end
	end
	FxController.onBigEvent = onBigEvent
	PokeController.onUsed = onUsed
	PokeController.setEnabled(false)
	-- Opening the catalog answers nothing, but the card must not sit over the pick chip.
	ToolCatalog.onOpenChanged(function(open: boolean)
		if open and choiceCard then
			setChoiceAside()
		elseif not open and choicePending then
			task.delay(1.5, askChoice) -- back from the catalog: asked again once things settle
		end
	end)
	task.spawn(begin) -- never holds up the other client systems
end

-- Tests and debug: current stage.
function OnboardingController.stage(): string
	return stage
end

-- Calls back once the first minute's weapons unlock (at once if they have): what the first minute
-- keeps off the screen (SANDBOX in the left column, the Robux packs) shows then, with WEAPONS.
function OnboardingController.whenFree(fn: () -> ())
	if released then
		task.spawn(fn)
	else
		table.insert(whenFree, fn)
	end
end

return OnboardingController
