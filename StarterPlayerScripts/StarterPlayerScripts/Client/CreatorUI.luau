--!strict
-- For creators (phase M): the CREATOR window (a launcher on PC, MENU on a phone).
--   CLIP (L): records a video of the game (Roblox's own recorder, up to 30 s; L or STOP ends it),
--     then offers to save it to your Captures and to share it with an invite to the game. A red
--     REC pill shows while it runs.
--   SCREENSHOT: a picture of the game, saved or shared the same way.
--   CREATOR MODE (U): every button on the screen hides, for clean clips; a small eye in the corner
--     (or U again) brings them back.
--   STREAMER MODE: for a TikTok LIVE. A gift tool (TikFinity) presses the STREAMER keys (F1-F8,
--     see Controls); each sets off something (StreamerService checks who may: your own private
--     server). The GIFT GUIDE card shows viewers which key does what; you pick which gift goes with
--     each from a fixed list (no typing). Gifts never give anything that lasts.

local CaptureService = game:GetService("CaptureService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))
local PokeController = require(Client:WaitForChild("PokeController"))
local Toys = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Toys"))

local player = Players.LocalPlayer

local CreatorUI = {}

-- The gifts a streamer can pair with each key (a fixed list: no typing).
CreatorUI.GIFTS = table.freeze({ "Rose", "TikTok", "Finger Heart", "Doughnut", "Perfume", "Hat", "Hand Hearts", "Galaxy", "Lion", "Universe" })
-- The STREAMER keys in order, what each does (StreamerService.ACTIONS) and its default gift.
local GIFT_KEYS = {
	{ key = "GiftDrop", action = "Drop", text = "Dummies drop in", gift = 1 },
	{ key = "GiftBoom", action = "Boom", text = "A big boom", gift = 2 },
	{ key = "GiftSlowmo", action = "Slowmo", text = "Slow-mo bubble", gift = 3 },
	{ key = "GiftRain", action = "Rain", text = "Dummy rain", gift = 8 },
	{ key = "GiftFling", action = "Fling", text = "Fling the streamer", gift = 4 },
	{ key = "GiftParty", action = "Party", text = "Party pops", gift = 7 },
	{ key = "GiftGiant", action = "Giant", text = "A giant dummy", gift = 9 },
	{ key = "GiftTool", action = "Tool", text = "Next tool", gift = 5 },
}
local MAX_CLIP = 30 -- s (Roblox stops a recording there)
local saveGifts: () -> ()
CreatorUI.WISH_GAP = 8 -- s between two viewers' wishes
local lastWish = -math.huge

local remote: RemoteEvent
local recording = false
local recordStarted = 0
local recPill: TextButton? = nil
local creatorMode = false
-- Creator mode sets the game's screens aside: each is moved out of PlayerGui into a holder that
-- is never drawn, untouched (its own scripts keep switching it on and off as they like: whatever
-- they last chose is simply what it is when it comes back).
local setAside = Instance.new("Folder")
setAside.Name = "CreatorSetAside"
local showEye: () -> ()
local eyeGui: ScreenGui? = nil
local streamerOn = false
local mayStream = false
local streamerRow: any = nil
local creatorRow: any = nil
local guideGui: ScreenGui? = nil
local guideLines: { TextLabel } = {}
local guideCard: Frame? = nil
local fitting = 0
local giftOf: { [number]: number } = {}
local giftButtons: { [number]: () -> () } = {}
local streamNote: TextLabel? = nil
-- The note under the Streamer switch: where it works, and the wish keys (whatever they are bound to).
local function drawStreamNote()
	local note = streamNote
	if not note then
		return
	end
	local keys = {}
	for i = 1, 4 do
		table.insert(keys, Keybinds.labelOf("Wish" .. i))
	end
	local wishes = "Wishes: " .. table.concat(keys, " ") .. " switch you to tool 1-4 of your bar."
	note.Text = if mayStream
		then "Tap a key's button to change its gift. " .. wishes
		else "Streamer Mode works in your own private server (make one on the game's page). Tap a key's button to change its gift. " .. wishes
end
local giftSaveToken = 0
local progressRemote: RemoteEvent? = nil

-- The gift pairings, kept with the profile (a moment after the last tap).
function saveGifts()
	giftSaveToken += 1
	local token = giftSaveToken
	task.delay(0.75, function()
		local r = progressRemote
		if token == giftSaveToken and r then
			local list = {}
			for i in GIFT_KEYS do
				list[i] = giftOf[i]
			end
			r:FireServer("Gifts", list)
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Clips and screenshots

local function offerCapture(capture: any)
	-- Save to the player's Captures first; once that prompt is answered, offer to share it with an
	-- invite to the game (one Roblox prompt at a time), and say what happened.
	local ok = pcall(function()
		CaptureService:PromptSaveCapturesToGallery({ capture }, function(results: any)
			local saved = false
			if type(results) == "table" then
				for _, yes in results do
					if yes == true then
						saved = true
					end
				end
			end
			Toast.show(if saved then "Saved to your Captures!" else "Not saved. Your clip is still yours to share")
			pcall(function()
				CaptureService:PromptShareCapture(capture, "clip", function()
					Toast.show("Shared! Your friends get an invite to Ragdoll Havoc")
				end, function() end)
			end)
		end)
	end)
	if not ok then
		Toast.show("Roblox's capture window isn't available here")
	end
end

local function setRec(on: boolean)
	recording = on
	local pill = recPill
	if pill then
		pill.Visible = on and not creatorMode
	end
	showEye()
end

local starting = false -- (a recording being started: a second press waits for it)
function CreatorUI.toggleClip()
	if recording then
		pcall(function()
			CaptureService:StopVideoCapture()
		end)
		return
	end
	if starting then
		return
	end
	starting = true
	Controller.closeAll() -- (before the first frame: the clip never shows this window)
	local ok, result = pcall(function()
		return CaptureService:StartVideoCaptureAsync(function(_result: any, capture: any)
			setRec(false)
			if capture then
				offerCapture(capture)
			else
				Toast.show("The clip could not be saved. Try again!")
			end
		end)
	end)
	starting = false
	if ok and result == Enum.VideoCaptureStartedResult.Success then
		recordStarted = os.clock()
		setRec(true)
	else
		Toast.show("Clips need Roblox's recorder (on in your settings, not in Studio)")
	end
end

function CreatorUI.screenshot()
	Controller.closeAll()
	task.wait(0.2)
	local ok = pcall(function()
		CaptureService:TakeScreenshotCaptureAsync(function(_result: any, capture: any)
			if capture then
				offerCapture(capture)
			end
		end)
	end)
	if not ok then
		Toast.show("Screenshots need Roblox's recorder (not in Studio)")
	end
end

------------------------------------------------------------------------------------------------
-- Creator mode

-- What creator mode never hides: its own eye and REC pill, the stream's gift guide, and Roblox's
-- own screens (the thumbstick and jump, the bubble chat, Studio's free camera): those are left
-- where Roblox keeps them.
local ROBLOX_SCREENS = { TouchGui = true, BubbleChat = true, Freecam = true, RbxCameraUI = true }
local function keepShown(g: ScreenGui): boolean
	return g == eyeGui or g == guideGui or g.Name == "CreatorRec" or ROBLOX_SCREENS[g.Name] == true
end

-- Sets a screen aside for creator mode (a new one made meanwhile too).
local function mute(g: ScreenGui)
	if keepShown(g) or g.Parent == setAside then
		return
	end
	-- (Deferred: moving a screen in the middle of its own parenting is refused by the engine.)
	task.defer(function()
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if creatorMode and playerGui and g.Parent == playerGui then
			g.Parent = setAside
		end
	end)
end
CreatorUI.mute = mute

-- The eye: on in creator mode; while a clean clip records it stays, faint, as the way to stop.
function showEye()
	local eye = eyeGui
	if not eye then
		return
	end
	eye.Enabled = creatorMode
	local button = eye:FindFirstChildOfClass("TextButton")
	if button then
		button.BackgroundTransparency = if recording then 0.85 else 0.4
		button.TextTransparency = if recording then 0.6 else 0
	end
end

function CreatorUI.setCreatorMode(on: boolean)
	if on == creatorMode then
		return
	end
	creatorMode = on
	if creatorRow then
		creatorRow.toggle.set(on, true) -- (the window's switch follows the eye and the key)
	end
	local gui = player:WaitForChild("PlayerGui")
	-- Messages wait while the screen is clean (the last ones show once it is back, below).
	if on then
		Toast.hold("Creator", true)
		Controller.closeAll()
		for _, g in gui:GetChildren() do
			if g:IsA("ScreenGui") then
				mute(g)
			end
		end
	else
		-- Every screen back as it is now (destroyed ones are simply gone).
		for _, g in setAside:GetChildren() do
			g.Parent = gui
		end
		Toast.hold("Creator", false) -- (after its screen is back: placed on the real screen size)
	end
	showEye()
	local pill = recPill
	if pill then
		pill.Visible = recording and not on -- (a clean clip has no REC in it)
	end
end

-- A clean clip: creator mode on, then the recording (the faint eye in the corner stops both).
function CreatorUI.cleanClip()
	if recording then
		return
	end
	if starting then
		return
	end
	CreatorUI.setCreatorMode(true)
	task.wait(0.15)
	CreatorUI.toggleClip()
	if not recording and not starting then
		CreatorUI.setCreatorMode(false) -- (no recorder here: the screen comes back with the reason)
	end
end

------------------------------------------------------------------------------------------------
-- Streamer mode

-- A line's width in the guide's own font (the text engine's measure: the legacy GetTextSize
-- comes out about a tenth narrower than FredokaOne draws, which cut the longest lines off).
local function measure(text: string): number
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = Theme.Fonts.display
	params.Size = 16
	params.Width = 10000
	local ok, bounds = pcall(function()
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and typeof(bounds) == "Vector2" then
		return bounds.X
	end
	return TextService:GetTextSize(text, 16, Enum.Font.FredokaOne, Vector2.new(10000, 40)).X * 1.2
end

-- The widest the card can ever get: the longest gift name with the longest effect (any pairing a
-- streamer can pick), measured as fitGuide measures (LayoutCheck checks this width). Yields.
function CreatorUI.guideWidthMax(): number
	local gift, effect = 0, 0
	for _, name in CreatorUI.GIFTS do
		gift = math.max(gift, measure(name))
	end
	for _, entry in GIFT_KEYS do
		effect = math.max(effect, measure("  \u{2192}  " .. entry.text))
	end
	return math.ceil(gift + effect + 24 + 8)
end

-- The card as wide as its widest line right now (+ 12 px each side and 8 px to spare).
local function fitGuide()
	fitting += 1
	local mine = fitting
	local widest = measure("GIFT GUIDE") * 20 / 16
	for _, label in guideLines do
		widest = math.max(widest, measure(label.Text))
	end
	local card = guideCard
	if card and mine == fitting then
		CreatorUI.GUIDE_WIDTH = math.ceil(widest + 24 + 8)
		card.Size = UDim2.fromOffset(CreatorUI.GUIDE_WIDTH, card.Size.Y.Offset)
	end
end

local function redrawGuide()
	for i, entry in GIFT_KEYS do
		local label = guideLines[i]
		if label then
			label.Text = string.format("%s  \u{2192}  %s", CreatorUI.GIFTS[giftOf[i] or entry.gift], entry.text)
		end
	end
	task.spawn(fitGuide)
	if guideGui then
		-- (Not while building: the build tools have that edge of the screen.)
		guideGui.Enabled = streamerOn and player:GetAttribute("Building") ~= true
	end
end

local function buildGuide()
	-- The GIFT GUIDE card on the right edge, for viewers (in the stream's picture).
	local g = Instance.new("ScreenGui")
	g.Name = "GiftGuide"
	g.ResetOnSpawn = false
	g.DisplayOrder = 30
	g.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	g.Enabled = false
	-- A first width (the longest gift with the longest effect, with room to spare); fitGuide sets
	-- the exact one for the lines shown (never a cut-off line on stream).
	local longestGift, longestText = 0, 0
	for _, name in CreatorUI.GIFTS do
		longestGift = math.max(longestGift, TextService:GetTextSize(name, 16, Enum.Font.FredokaOne, Vector2.new(1000, 40)).X)
	end
	for _, entry in GIFT_KEYS do
		longestText = math.max(longestText, TextService:GetTextSize("  \u{2192}  " .. entry.text, 16, Enum.Font.FredokaOne, Vector2.new(1000, 40)).X)
	end
	CreatorUI.GUIDE_WIDTH = math.ceil((longestGift + longestText) * 1.2 + 24 + 8)
	local card = Instance.new("Frame")
	-- Under the right-hand column (LAB VIEW, Replay, RAGDOLL), 12 px clear of it (LayoutCheck
	-- "Guide"): never over a button, on any PC window.
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(1, -10, 0, CreatorUI.GUIDE_TOP)
	card.Size = UDim2.fromOffset(CreatorUI.GUIDE_WIDTH, CreatorUI.GUIDE_HEIGHT)
	card.BackgroundColor3 = Theme.Palette.dusk
	card.BackgroundTransparency = 0.15
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Theme.Palette.ink
	stroke.Parent = card
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 30)
	title.FontFace = Theme.Fonts.display
	title.TextSize = 20
	title.TextColor3 = Theme.Palette.gold
	title.Text = "GIFT GUIDE"
	title.Parent = card
	for i in GIFT_KEYS do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(12, 30 + (i - 1) * 26)
		l.Size = UDim2.new(1, -24, 0, 24)
		l.FontFace = Theme.Fonts.display
		l.TextSize = 16
		l.TextColor3 = Theme.Palette.textHi
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.None
		l.Parent = card
		guideLines[i] = l
	end
	card.Parent = g
	guideCard = card
	g.Parent = player:WaitForChild("PlayerGui")
	guideGui = g
	redrawGuide()
end

-- The Streamer switch looks locked (and says why when tapped) where it can't go on: not this
-- player's private server, or not a PC.
local streamLock: TextButton? = nil
local function updateStreamLock()
	local row = streamerRow
	if not row then
		return
	end
	local reason = if not CreatorUI.streamDevice()
		then "Streamer Mode needs a PC: gift tools press its keys"
		elseif not mayStream then "Streamer Mode works in your own private server"
		else nil
	if reason and not streamLock then
		local lock = Instance.new("TextButton")
		lock.Name = "Locked"
		lock.Size = UDim2.fromScale(1, 1)
		lock.BackgroundColor3 = Theme.Palette.dusk
		lock.BackgroundTransparency = 0.3
		lock.TextColor3 = Theme.Palette.textHi
		lock.FontFace = Theme.Fonts.display
		lock.TextSize = 16
		lock.AutoButtonColor = false
		lock.ZIndex = 20
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Theme.Radius.card)
		corner.Parent = lock
		lock.Parent = row.root
		lock.Activated:Connect(function()
			local why = lock:GetAttribute("Why")
			Toast.show(if type(why) == "string" then why else "Streamer Mode isn't available here")
		end)
		streamLock = lock
	end
	local lock = streamLock
	if lock then
		lock.Visible = reason ~= nil
		lock.Text = if reason then "\u{1F512}  " .. (if CreatorUI.streamDevice() then "YOUR PRIVATE SERVER ONLY" else "PC ONLY") else ""
		lock:SetAttribute("Why", reason)
	end
end

CreatorUI.GUIDE_TOP = 194 -- px: the RAGDOLL slot ends at 182 (HudSlots)
CreatorUI.EYE_SIZE = 48
CreatorUI.EYE_INSET = 8
CreatorUI.GUIDE_HEIGHT = 34 + 8 * 26

-- A PC: a keyboard for the gift keys, and no touch controls under the guide.
function CreatorUI.streamDevice(): boolean
	return UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
end

local function setStreamer(on: boolean)
	if on and not CreatorUI.streamDevice() then
		-- Gift tools (TikFinity and the like) press keys on the streamer's PC: without a keyboard
		-- there is nothing for them to press, and a touch screen's controls own the right edge
		-- where the guide goes.
		if streamerRow then
			streamerRow.toggle.set(false, true)
		end
		Toast.show("Streamer Mode needs a PC: gift tools press its keys")
		return
	end
	remote:FireServer("Mode", on)
end

------------------------------------------------------------------------------------------------

local function build()
	local window = C.Window({ name = "Creator", title = "Creator", theme = "codes", icon = "camera" })
	C.Text("caption", "Make clips for TikTok, or go live with Streamer Mode.", { autoY = true, color = Theme.Palette.textMid, layoutOrder = -1, parent = window.body })
	local clipButton = C.Button({ text = "RECORD A CLIP", role = "danger", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 0, parent = window.body, onActivated = CreatorUI.toggleClip })
	local function clipLabel()
		clipButton.setText(if UserInputService.KeyboardEnabled then "RECORD A CLIP  [" .. Keybinds.labelOf("Clip") .. "]" else "RECORD A CLIP")
	end
	clipLabel()
	Keybinds.onChanged(clipLabel)
	-- A clean clip in one tap (on a phone too): every button hides, the recording starts, and the
	-- faint eye in the corner stops it.
	C.Button({ text = "RECORD A CLEAN CLIP", role = "premium", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 1, parent = window.body, onActivated = function()
		task.spawn(CreatorUI.cleanClip)
	end })
	C.Button({ text = "SCREENSHOT", role = "info", size = UDim2.new(1, 0, 0, Theme.Size.buttonH), layoutOrder = 2, parent = window.body, onActivated = function()
		task.spawn(CreatorUI.screenshot)
	end })
	creatorRow = C.SettingRow({
		label = "Creator mode",
		description = "Hides every button for clean clips. The eye in the corner brings them back",
		value = false,
		layoutOrder = 3,
		parent = window.body,
		onChanged = function(on)
			CreatorUI.setCreatorMode(on)
		end,
	})
	C.SectionHeader("STREAMER MODE (TIKTOK LIVE)", "codes", 4, window.body)
	C.Text("caption", "A gift tool presses the STREAMER keys (see Controls). Works in your own private server. Gifts never give anything that lasts.", { autoY = true, color = Theme.Palette.textMid, layoutOrder = 5, parent = window.body })
	streamerRow = C.SettingRow({
		label = "Streamer mode",
		description = "Gift keys on, and the GIFT GUIDE on screen for viewers",
		value = false,
		layoutOrder = 6,
		parent = window.body,
		onChanged = function(on)
			setStreamer(on)
		end,
	})
	-- AUTOPILOT (round 3, M9): a quiet stream keeps moving (StreamerService). On unless switched off.
	C.SettingRow({
		label = "Autopilot",
		description = "No gift for 90 s: something fun happens by itself every 45 s",
		value = true,
		layoutOrder = 40, -- (after the gift keys)
		parent = window.body,
		onChanged = function(on)
			remote:FireServer("Autopilot", on)
		end,
	})
	streamNote = C.Text("caption", "", { autoY = true, color = Theme.Palette.textMid, layoutOrder = 7, parent = window.body })
	drawStreamNote()
	Keybinds.onChanged(drawStreamNote)
	-- Which gift goes with each key (tap to change; the guide shows it; kept with your profile).
	for i, entry in GIFT_KEYS do
		giftOf[i] = entry.gift
		local b: any
		b = C.Button({
			text = "",
			role = "neutral",
			size = UDim2.new(1, 0, 0, 48),
			layoutOrder = 7 + i,
			parent = window.body,
			onActivated = function()
				giftOf[i] = (giftOf[i] % #CreatorUI.GIFTS) + 1
				b.setText(string.format("[%s] %s: %s", Keybinds.labelOf(entry.key), entry.text, CreatorUI.GIFTS[giftOf[i]]))
				redrawGuide()
				saveGifts()
			end,
		})
		local function label()
			b.setText(string.format("[%s] %s: %s", Keybinds.labelOf(entry.key), entry.text, CreatorUI.GIFTS[giftOf[i]]))
		end
		label()
		Keybinds.onChanged(label)
		giftButtons[i] = label
	end
	Controller.register(window)
end

local function buildOverlays()
	local gui = player:WaitForChild("PlayerGui")
	-- REC pill (tap to stop).
	local rec = Instance.new("ScreenGui")
	rec.Name = "CreatorRec"
	rec.ResetOnSpawn = false
	rec.DisplayOrder = 60
	rec.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local pill = Instance.new("TextButton")
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.new(0.5, 0, 0, 8)
	pill.Size = UDim2.fromOffset(150, 44)
	pill.BackgroundColor3 = Color3.fromRGB(230, 40, 60)
	pill.TextColor3 = Color3.new(1, 1, 1)
	pill.FontFace = Theme.Fonts.display
	pill.TextSize = 20
	pill.Text = "REC 0:00"
	pill.Visible = false
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = pill
	pill.Parent = rec
	pill.Activated:Connect(CreatorUI.toggleClip)
	rec.Parent = gui
	recPill = pill
	-- The eye that brings the buttons back in creator mode.
	local eye = Instance.new("ScreenGui")
	eye.Name = "CreatorEye"
	eye.ResetOnSpawn = false
	eye.DisplayOrder = 60
	eye.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	eye.Enabled = false
	local b = Instance.new("TextButton")
	-- Top-right: in creator mode that corner is empty (LAB VIEW is set aside), and it is clear of
	-- Roblox's jump button and thumbstick at the bottom (LayoutCheck "Eye").
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -CreatorUI.EYE_INSET, 0, CreatorUI.EYE_INSET)
	b.Size = UDim2.fromOffset(CreatorUI.EYE_SIZE, CreatorUI.EYE_SIZE)
	b.BackgroundColor3 = Theme.Palette.dusk
	b.BackgroundTransparency = 0.4
	b.TextColor3 = Color3.new(1, 1, 1)
	b.FontFace = Theme.Fonts.display
	b.TextSize = 22
	b.Text = "\u{25C9}"
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0.5, 0)
	bc.Parent = b
	b.Parent = eye
	b.Activated:Connect(function()
		if recording then
			CreatorUI.toggleClip() -- (a clean clip: the eye stops it first)
		end
		CreatorUI.setCreatorMode(false)
	end)
	eye.Parent = gui
	eyeGui = eye
end

function CreatorUI.start()
	remote = Net.event(Net.Names.Streamer)
	build()
	buildOverlays()
	buildGuide()
	Controller.addHudButton({ window = "Creator", label = "Creator", icon = "camera", theme = "codes", layoutOrder = 7 })
	remote.OnClientEvent:Connect(function(kind: unknown, data: unknown)
		local d = if type(data) == "table" then data :: any else {}
		if kind == "Hello" then
			mayStream = d.may == true
			updateStreamLock()
			-- Not this player's server: the switch says where Streamer Mode works.
			drawStreamNote()
		elseif kind == "Mode" then
			streamerOn = d.on == true
			if streamerRow then
				streamerRow.toggle.set(streamerOn, true)
			end
			redrawGuide()
			Toast.show(if streamerOn then "Streamer Mode on: gift keys are live" else "Streamer Mode off")
		elseif kind == "Refused" and type(d.text) == "string" then
			if streamerRow then
				streamerRow.toggle.set(false, true)
			end
			Toast.show(d.text)
		elseif kind == "Ran" and type(d.id) == "string" then
			-- On stream: which gift did what (the gift guide names the same).
			for i, entry in GIFT_KEYS do
				if entry.action == d.id then
					Toast.show(string.format("%s \u{2192} %s!", CreatorUI.GIFTS[giftOf[i] or entry.gift], entry.text), Theme.Palette.gold)
					break
				end
			end
		elseif kind == "Skipped" and type(d.text) == "string" then
			-- A gift that set nothing off (queue full, too many at once, no room for bodies): the
			-- streamer sees it rather than wondering.
			Toast.show(d.text)
		elseif kind == "NextTool" then
			local bar = PokeController.getLoadout()
			local at = table.find(bar, PokeController.getSelected()) or 0
			local nextId = bar[at % #bar + 1]
			if nextId then
				PokeController.select(nextId)
			end
		end
	end)
	remote:FireServer("Hello")
	-- (A keyboard plugged in, or a touch screen used, later on: the switch's lock follows.)
	UserInputService.LastInputTypeChanged:Connect(updateStreamLock)
	player:GetAttributeChangedSignal("Building"):Connect(redrawGuide)
	-- The kept gift pairings (asked with the radio's and the keys': ProgressService "Prefs").
	progressRemote = Net.event(Net.Names.Progress)
	;(progressRemote :: RemoteEvent).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "Gifts" and type(data) == "table" then
			for i in GIFT_KEYS do
				local g = (data :: any)[i]
				if type(g) == "number" and CreatorUI.GIFTS[g] then
					giftOf[i] = g
				end
			end
			for _, relabel in giftButtons do
				relabel()
			end
			redrawGuide()
		end
	end)
	-- A screen made while creator mode is on stays hidden too (one shown later by a tool).
	player:WaitForChild("PlayerGui").ChildAdded:Connect(function(g)
		if creatorMode and g:IsA("ScreenGui") then
			mute(g)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		-- Gift keys work even while the chat box has focus (a gift tool presses them at any time;
		-- F1-F8 never type a letter), but not while a key is being set in Controls.
		if streamerOn and not Keybinds.capturing then
			for _, entry in GIFT_KEYS do
				-- (Through the chat box only for function keys: a gift key moved onto a letter
				-- must not go off while the streamer types.)
				local isFunctionKey = input.KeyCode.Value >= Enum.KeyCode.F1.Value and input.KeyCode.Value <= Enum.KeyCode.F15.Value
				if Keybinds.is(entry.key, input.KeyCode) and (isFunctionKey or not processed) then
					remote:FireServer("Action", entry.action)
					return
				end
			end
			-- A viewer's wish: the streamer's hands switch to that tool of the bar (never while typing:
			-- INS and END move the cursor in a text box; WISH_GAP s between wishes, so the chat can't
			-- flick it about).
			for i = 1, 4 do
				if not processed and Keybinds.is("Wish" .. i, input.KeyCode) then
					local now = os.clock()
					local id = PokeController.getLoadout()[i]
					if id and now - lastWish >= CreatorUI.WISH_GAP then
						lastWish = now
						PokeController.select(id)
						local toy = Toys.byId[id]
						Toast.show(string.format("A viewer wished for the %s!", if toy then toy.label else id), Theme.Palette.gold)
					end
					return
				end
			end
		end
		if not Keybinds.live(processed) then
			return
		end
		if Keybinds.is("Clip", input.KeyCode) then
			CreatorUI.toggleClip()
		elseif Keybinds.is("Creator", input.KeyCode) then
			CreatorUI.setCreatorMode(not creatorMode)
		elseif Keybinds.is("CreatorWindow", input.KeyCode) then
			Controller.toggle("Creator")
		end
	end)
	-- The REC clock.
	local shown = -1
	RunService.Heartbeat:Connect(function()
		if not recording or not recPill then
			return
		end
		local t = math.min(MAX_CLIP, math.floor(os.clock() - recordStarted))
		local pill = recPill
		if t ~= shown and pill then
			shown = t
			pill.Text = string.format("REC 0:%02d  \u{25A0}", t)
		end
	end)

end

return CreatorUI
