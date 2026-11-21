--!strict
-- 21 Nov 2026 (the owner: "even a 9-year-old must understand how to use everything in the lab, like
-- feeding the spider a ragdoll, or the other monsters"). Vault: show, don't tell; one accent colour
-- means "you can use this"; a prompt is a verb and an object; labels of one or two words.
-- Every creature in the yard and every PUT RAGDOLL HERE station gets:
--   * a sign in the world (studs): the drawn "dummy -> " picture and two words, FEED ME!;
--   * a glowing cyan ring on the ground where a dummy goes (Client/LabGuideClient pulses it, and the
--     nearest one lights up with DROP HERE! while you carry a dummy);
--   * a button (ProximityPrompt "Feed / Spider"): press it and the nearest free dummy of the lab
--     flies in an arc right into it. So a child who only presses the button still sees it work,
--     and one who carries a dummy over learns the real way.
-- A leaf for the rest: it reads the yard (LabCreatures' Trigger attribute) and the stations, and
-- moves bodies only through DummyControl (the lab's player simulates them).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DrawnIcons = require(Shared:WaitForChild("DrawnIcons")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net")) :: any

local LabGuide = {}

LabGuide.ACCENT = Color3.fromRGB(40, 220, 255) -- (the one "use me" colour: nothing else in the lab is this cyan)
LabGuide.RING = 10 -- studs across a drop ring
LabGuide.PROMPT_REACH = 18 -- studs from the button's point
LabGuide.SPOT_GAP = 2 -- s between two tosses into one creature
LabGuide.PLAYER_GAP = 0.8 -- s between two presses of one player
LabGuide.FLIGHT_SPEED = 55 -- studs/s along the ground a tossed dummy covers (its flight time follows)
LabGuide.TAG = "GuideRing"

-- What each creature's button and sign say (verb, object, the sign's words).
LabGuide.WORDS = table.freeze({
	Spider = { "Feed", "Spider", "FEED ME!" },
	Frog = { "Feed", "Frog", "FEED ME!" },
	Plant = { "Feed", "Giant Plant", "FEED ME!" },
	Chicken = { "Feed", "Chicken", "FEED ME!" },
	Whale = { "Feed", "Whale", "FEED ME!" },
	Washer = { "Wash", "a Dummy", "WASH ME!" },
	Vacuum = { "Feed", "Robot Vacuum", "FEED ME!" },
	Mole = { "Feed", "Mole", "FEED ME!" },
	Slingshot = { "Load", "Slingshot", "LOAD ME!" },
}) :: { [string]: { string } }

-- The lab's machines that get a toss button too (part name -> verb, object, no sign: they have theirs).
LabGuide.MACHINES = table.freeze({
	CannonPad = { "Fire", "Cannon", "" },
	LavaPool = { "Dunk", "in the Lava", "" },
	SwingBall = { "Smash", "Wrecking Ball", "" }, -- (fix round 1: the wrecking ball takes a dummy too)
	TrampolinePad = { "Bounce", "Trampoline", "" },
}) :: { [string]: { string } }

local spotLast: { [Instance]: number } = {}
local playerLast: { [Player]: number } = {}
local tossedCount = 0

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function anchoredPart(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- The ground under a point (the lab floor, the yard, a pool's bottom), ignoring dummies and players.
local function groundUnder(at: Vector3, fallbackY: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(ignore, p.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), params)
	return if hit then hit.Position.Y else fallbackY
end

-- The sign over a spot: a white card with a cyan edge, the drawn picture and two words.
local function sign(point: BasePart, words: string, height: number)
	local g = Instance.new("BillboardGui")
	g.Name = "GuideSign"
	g.Size = UDim2.fromScale(10, 3.4) -- (studs: a sign in the world, smaller far off)
	g.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	g.MaxDistance = 80
	g.LightInfluence = 0
	g.Adornee = point
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = card
	local edge = Instance.new("UIStroke")
	edge.Color = LabGuide.ACCENT
	edge.Thickness = 4
	edge.Parent = card
	local pic = Instance.new("ImageLabel")
	pic.BackgroundTransparency = 1
	pic.Size = UDim2.fromScale(0.36, 1.1)
	pic.AnchorPoint = Vector2.new(0, 0.5)
	pic.Position = UDim2.fromScale(0.02, 0.5)
	pic.ScaleType = Enum.ScaleType.Fit
	pic.Image = DrawnIcons.ASSETS.guide_feed or ""
	pic.Parent = card
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AnchorPoint = Vector2.new(1, 0.5)
	text.Position = UDim2.fromScale(0.96, 0.5)
	text.Size = UDim2.fromScale(0.6, 0.78)
	text.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(24, 26, 40)
	text.Text = words
	text.Parent = card
	card.Parent = g
	g.Parent = point
end

-- A dummy of this lab to toss: free (not held, in no machine, not cooling down), the nearest to
-- where the player stands.
-- V9-2b fix round 1: the spares a lab's terminals dropped (counted in its body cap, reused first).
local spares: { [Player]: { Model } } = {}
local function sparesOf(owner: Player): { Model }
	local list = spares[owner] or {}
	spares[owner] = list
	for i = #list, 1, -1 do
		if not list[i].Parent then
			table.remove(list, i)
		end
	end
	return list
end

local function pickDummy(owner: Player, near: Vector3, target: Vector3?): Model?
	local Lab = lazy("Lab")
	local best: Model? = nil
	local bestD = math.huge
	local now = os.clock()
	local pool = table.clone(Lab.dummiesOf(owner))
	for _, s in sparesOf(owner) do
		table.insert(pool, s)
	end
	for _, model in pool do
		local pelvis = model:FindFirstChild("LowerTorso")
		-- (Fix round 1: never one just thrown (still flying, or landing) nor one already at the target:
		-- a run of presses sends the next dummy, not the same one again and again.)
		if model.Parent and pelvis and pelvis:IsA("BasePart") and model:GetAttribute("Held") ~= true
			and model:GetAttribute("InMachine") == nil and model:GetAttribute("Frozen") ~= true
			and now >= ((model:GetAttribute("MachineCool") :: number?) or 0)
			and now >= ((model:GetAttribute("GuideTossUntil") :: number?) or 0)
			and not (target and (pelvis.Position - target).Magnitude < 6) then
			local d = (pelvis.Position - near).Magnitude
			if d < bestD then
				best, bestD = model, d
			end
		end
	end
	return best
end

-- The velocity that lands a body from `from` at `to` after a flight that follows the distance.
function LabGuide.arc(from: Vector3, to: Vector3): Vector3
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
	local t = math.clamp(flat / LabGuide.FLIGHT_SPEED, 0.8, 1.5)
	local g = Workspace.Gravity
	return (to - from) / t + Vector3.new(0, 0.5 * g * t, 0)
end

-- Tosses one free dummy of the lab into `target`; true if one flew.
function LabGuide.toss(player: Player, owner: Player, target: Vector3): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local near = if root and root:IsA("BasePart") then root.Position else target
	local model = pickDummy(owner, near, target)
	if not model then
		return false
	end
	return LabGuide.tossModel(model, target)
end

-- Sends one body in an arc into `target`, marked so the next press picks another (fix round 1).
function LabGuide.tossModel(model: Model, target: Vector3): boolean
	local pelvis = model:FindFirstChild("LowerTorso")
	if not (pelvis and pelvis:IsA("BasePart")) then
		return false
	end
	local v = LabGuide.arc(pelvis.Position, target)
	local mass = (model:GetAttribute("Mass") :: number?) or 10
	local flat = Vector3.new(target.X - pelvis.Position.X, 0, target.Z - pelvis.Position.Z).Magnitude
	model:SetAttribute("GuideTossUntil", os.clock() + math.clamp(flat / LabGuide.FLIGHT_SPEED, 0.8, 1.5) + 0.8)
	lazy("DummyControl").hit(model, pelvis, v * mass, pelvis.Position, v.Magnitude + 20, nil)
	tossedCount += 1
	return true
end

------------------------------------------------------------------------------------------------
-- V9-2b / Phase T (owner, 21 Nov 2026: "a little computer terminal you walk up to and press FEED, and spam
-- it if you like"; Config.FEED_TERMINAL): by every thing in the lab that takes a dummy (the creatures, the
-- cannon, the lava, the trampoline, the PUT RAGDOLL HERE stations) a terminal on the near side, facing the
-- way you come: a console on a post, a screen (tag FeedTerminalScreen: each client draws its big FEED
-- button and the combo, Client/TerminalClient), a glowing button with the E / pad prompt, and a chute the
-- spare dummies drop from. It replaces the floating prompt.
-- Every press is checked here (remote Terminal "Press", or the prompt): the lab's player or a party guest,
-- within TERM_REACH studs, at most TERM_RATE presses a second, a queue of TERM_QUEUE. Each queued press
-- sends the next dummy flying in an arc into it; a quick run of presses is a combo ("x5!") and the feeding
-- speeds up a little. With no free dummy, a spare drops from the chute, within the lab's body cap, and
-- goes after SPARE_LIFE s if nothing took it.

LabGuide.TERM_REACH = 24 -- studs from the terminal
LabGuide.TERM_RATE = 4 -- presses a second, per player
LabGuide.TERM_QUEUE = 6
LabGuide.TERM_EVERY = 0.28 -- s between two queued tosses (a combo shortens it, to TERM_FASTEST)
LabGuide.TERM_FASTEST = 0.14
LabGuide.COMBO_GAP = 1.5 -- s without a press ends a combo
LabGuide.SPARE_LIFE = 40 -- s
LabGuide.TERM_OUT = 7 -- studs from the spot towards the lab's spawn
LabGuide.SPARE_MAX = 3 -- spares a lab's terminals may have out at once (fix round 1)
-- (Fix round 1: how far out a terminal starts, where the thing is big or moves: the vacuum drives a loop
-- 22 x 8 studs round its middle.)
local OUT_BY_ID: { [string]: number } = { Vacuum = 14 }

type Terminal = {
	screen: BasePart,
	button: BasePart,
	chute: Vector3,
	origin: Vector3,
	target: () -> Vector3,
	queue: number,
	working: boolean,
	combo: number,
	comboAt: number,
	presser: Player?,
	noticeAt: number,
	-- (Optional, per terminal: another machine's own press (the Compressor), its own pace and queue.)
	action: ((any) -> ())?,
	every: number?,
	queueMax: number?,
}
local terminals: { [Instance]: Terminal } = {}
local pressTimes: { [Player]: { number } } = {}
local termTossed = 0

-- Who may press: the lab's player, or someone the lab lets reach in (a party guest).
local function mayUse(player: Player, t: Terminal): (boolean, Player?)
	local owner = lazy("Lab").ownerAt(t.origin + Vector3.new(0, 1, 0))
	if not owner then
		return false, nil
	end
	if player ~= owner then
		local ok, may = pcall(function()
			return (require(Shared:WaitForChild("Zones")) :: any).mayReach(player, t.target())
		end)
		if not (ok and may) then
			return false, owner
		end
	end
	return true, owner
end

-- A spare from the chute when no free dummy is left, within the lab's body cap; it goes after
-- SPARE_LIFE s if nothing took it.
local function spare(owner: Player, t: Terminal): Model?
	-- (Fix round 1: the lab's spares count in its body cap, at most SPARE_MAX at once, reused before a new
	-- one is made (pickDummy), and they go once they are free after SPARE_LIFE s, or when the lab's player
	-- leaves.)
	local VisitorService = lazy("VisitorService")
	local mine = sparesOf(owner)
	if #mine >= LabGuide.SPARE_MAX or #VisitorService.bodiesOf(owner) + #mine >= VisitorService.capFor(owner) then
		return nil
	end
	local model = lazy("DummyFactory").spawn(t.chute, t.target(), owner, 3) -- (out of the chute: it drops in beside the terminal)
	model:SetAttribute("Spare", true)
	table.insert(mine, model)
	task.spawn(function()
		task.wait(LabGuide.SPARE_LIFE)
		while model.Parent do
			if model:GetAttribute("Held") ~= true and model:GetAttribute("InMachine") == nil then
				model:Destroy()
				break
			end
			task.wait(5)
		end
	end)
	return model
end

local function tossOne(t: Terminal)
	local presser = t.presser
	local owner = lazy("Lab").ownerAt(t.origin + Vector3.new(0, 1, 0))
	if not presser or not owner then
		return
	end
	local target = t.target() + Vector3.new(0, 1.5, 0)
	if LabGuide.toss(presser, owner, target) then
		termTossed += 1
		return
	end
	local m = spare(owner, t)
	if m then
		task.wait(0.35) -- (out of the chute first)
		if m.Parent and LabGuide.tossModel(m, target) then
			termTossed += 1
		end
	elseif os.clock() - t.noticeAt > 5 then
		t.noticeAt = os.clock()
		pcall(function()
			lazy("ProgressService").notice(presser, "No free dummy right now. Try again in a moment!")
		end)
	end
end

local function work(t: Terminal)
	if t.working then
		return
	end
	t.working = true
	task.spawn(function()
		while t.queue > 0 and t.screen.Parent do
			local act = t.action
			if act then
				local okAct, errAct = pcall(act, t)
				if not okAct then
					warn("[LabGuide] terminal action: " .. tostring(errAct))
				end
			else
				-- (Fix round 1: an error never leaves the terminal stuck "working" with a full queue.)
				local okToss, errToss = pcall(tossOne, t)
				if not okToss then
					warn("[LabGuide] terminal toss: " .. tostring(errToss))
				end
			end
			t.queue -= 1
			t.screen:SetAttribute("Queue", t.queue)
			task.wait(t.every or math.max(LabGuide.TERM_FASTEST, LabGuide.TERM_EVERY - 0.02 * t.combo))
		end
		t.working = false
	end)
end

-- One press, checked. Returns whether it was taken and, if not, why.
function LabGuide.press(player: Player, screen: Instance): (boolean, string?)
	local t = terminals[screen]
	if not t then
		return false, "no terminal"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or (root.Position - t.screen.Position).Magnitude > LabGuide.TERM_REACH then
		return false, "too far"
	end
	local ok = mayUse(player, t)
	if not ok then
		return false, "not your lab"
	end
	local now = os.clock()
	local times = pressTimes[player] or {}
	pressTimes[player] = times
	while times[1] and now - times[1] > 1 do
		table.remove(times, 1)
	end
	if #times >= LabGuide.TERM_RATE then
		return false, "slow down"
	end
	if t.queue >= (t.queueMax or LabGuide.TERM_QUEUE) then
		return false, "queue full"
	end
	table.insert(times, now)
	t.combo = if now - t.comboAt < LabGuide.COMBO_GAP then t.combo + 1 else 1
	t.comboAt = now
	t.presser = player
	t.queue += 1
	t.screen:SetAttribute("Queue", t.queue)
	t.screen:SetAttribute("Combo", t.combo)
	t.screen:SetAttribute("PressedAt", Workspace:GetServerTimeNow())
	work(t)
	return true, nil
end

-- The terminal for one spot: on the floor TERM_OUT studs from the spot towards the lab's spawn, facing it.
local function buildTerminal(into: Instance, origin: Vector3, id: string, target: () -> Vector3, words: { string }, opts: { action: ((any) -> ())?, every: number?, queueMax: number?, faceFrom: Vector3?, out: number? }?): BasePart
	local at = target()
	local from = (opts and opts.faceFrom) or origin
	local toward = Vector3.new(from.X - at.X, 0, from.Z - at.Z)
	local dir = if toward.Magnitude > 0.1 then toward.Unit else Vector3.zAxis
	-- (Fix round 1: out from the spot until clear of every trigger, the lava and the creatures' bodies,
	-- with 2 studs to spare: never inside the lava, a habitat or a trigger box.)
	local boxes: { { cf: CFrame, size: Vector3 } } = {}
	local lab = into.Parent or into
	for _, d in lab:GetDescendants() do
		if d:IsA("BasePart") and (string.find(d.Name, "Trigger", 1, true) or string.find(d.Name, "Lava", 1, true)) then
			table.insert(boxes, { cf = d.CFrame, size = d.Size })
		elseif d:IsA("BasePart") and (d.Name == "PathSlab" or d.Name == "PathJoint" or d.Name == "PathStone") then
			-- (V9-NOW: never on a walk either; the washer's and the vacuum's stood on the yard road, T150.)
			table.insert(boxes, { cf = d.CFrame, size = d.Size })
		elseif d:IsA("BasePart") and d.Name == "Walkway" and d.Parent and d.Parent:FindFirstChild("SwingBall") then
			-- (Owner, 21 Nov 2026: "the swinging ball only swings 20% and back": a terminal stood in its run and
			-- stopped it at 24 degrees. Its whole arc is kept clear: the run, wider and longer, as the ball reaches.)
			table.insert(boxes, { cf = d.CFrame, size = d.Size + Vector3.new(6, 0, 12) })
		elseif d:IsA("Model") and d:GetAttribute("Creature") ~= nil then
			local bcf, bsize = d:GetBoundingBox()
			table.insert(boxes, { cf = bcf, size = bsize })
		end
	end
	-- (V9-NOW: the footprint on the floor, whichever way a part lies: its most upright axis is left out, so a lying
	-- cylinder (the lava's discs, the walks' joints) is measured across its round face, not along its height.)
	local function blocked(p: Vector3): boolean
		for _, b in boxes do
			local rel = b.cf:PointToObjectSpace(p)
			local ups = { math.abs(b.cf.RightVector.Y), math.abs(b.cf.UpVector.Y), math.abs(b.cf.LookVector.Y) }
			local skip = if ups[1] >= ups[2] and ups[1] >= ups[3] then 1 elseif ups[2] >= ups[3] then 2 else 3
			local c = { rel.X, rel.Y, rel.Z }
			local s = { b.size.X, b.size.Y, b.size.Z }
			local inside = true
			for i = 1, 3 do
				if i ~= skip and math.abs(c[i]) >= s[i] / 2 + 2 then
					inside = false
				end
			end
			if inside then
				return true
			end
		end
		return false
	end
	local start = (opts and opts.out) or LabGuide.TERM_OUT
	local base = at + dir * start
	local side = Vector3.yAxis:Cross(dir)
	local found = false
	for _, sideways in { 0, 4, -4, 8, -8 } do -- (V9-NOW: a step aside when straight out is a walk)
		for step = 0, 10 do
			local p = at + dir * (start + step * 1.5) + side * sideways
			if not blocked(p) then
				base = p
				found = true
				break
			end
		end
		if found then
			break
		end
	end
	if not found then
		base = at + dir * (start + 15)
	end
	base = Vector3.new(base.X, groundUnder(base, origin.Y), base.Z)
	local cf = CFrame.lookAt(base, base + dir) -- (faces the way you come)
	local m = Instance.new("Model")
	m.Name = "FeedTerminal"
	m:SetAttribute("GuideId", id)
	local dark = Color3.fromRGB(36, 40, 52)
	local post = anchoredPart("Post", Vector3.new(0.9, 3, 0.9), cf * CFrame.new(0, 1.5, 0), m)
	post.Color = dark
	post.Material = Enum.Material.Metal
	post.CastShadow = true
	post.CanCollide = true -- (fix round 1: a solid post)
	local foot = anchoredPart("Foot", Vector3.new(2.6, 0.3, 2.2), cf * CFrame.new(0, 0.15, 0), m)
	foot.Color = dark
	foot.Material = Enum.Material.DiamondPlate
	-- The console, tilted back towards you.
	local console = anchoredPart("Console", Vector3.new(3.6, 2.4, 0.9), cf * CFrame.new(0, 3.6, 0) * CFrame.Angles(math.rad(28), 0, 0), m) -- (fix round 1: its top leans back, so the screen looks up at you)
	console.Color = dark
	console.Material = Enum.Material.Metal
	console.CastShadow = true
	console.CanCollide = true
	local screen = anchoredPart("Screen", Vector3.new(3.2, 2, 0.08), console.CFrame * CFrame.new(0, 0.05, -0.48), m)
	screen.Color = Color3.fromRGB(12, 16, 28)
	screen.Material = Enum.Material.SmoothPlastic
	screen.CanQuery = true -- (the taps reach the SurfaceGui on it)
	screen:SetAttribute("Verb", words[1])
	screen:SetAttribute("Object", words[2])
	screen:SetAttribute("GuideId", id)
	CollectionService:AddTag(screen, "FeedTerminalScreen")
	-- The big glowing button on the ledge under the screen (the E / pad prompt lives here).
	local button = anchoredPart("Button", Vector3.new(0.5, 1.3, 1.3), cf * CFrame.new(0, 2.05, -0.75) * CFrame.Angles(0, 0, math.rad(90)), m)
	button.Shape = Enum.PartType.Cylinder
	button.Material = Enum.Material.Neon
	button.Color = LabGuide.ACCENT
	button.CanQuery = true
	local ledge = anchoredPart("Ledge", Vector3.new(3, 0.4, 1.4), cf * CFrame.new(0, 1.85, -0.5), m)
	ledge.Color = dark
	ledge.Material = Enum.Material.Metal
	-- The chute on top, where spares drop from.
	local chute = anchoredPart("Chute", Vector3.new(1.4, 2.2, 1.4), cf * CFrame.new(1.2, 5.6, 0.6), m)
	chute.Shape = Enum.PartType.Cylinder
	chute.CFrame = cf * CFrame.new(1.2, 5.6, 0.6) * CFrame.Angles(0, 0, math.rad(90))
	chute.Color = Color3.fromRGB(255, 196, 64)
	chute.Material = Enum.Material.Metal
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Terminal"
	prompt.ActionText = words[1]
	prompt.ObjectText = words[2]
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(150, 0) -- (fix round 1: the prompt's panel beside the screen, not over its button)
	prompt.HoldDuration = 0
	prompt.Parent = button
	-- (Fix round 1: the glowing button is pressable too, by a click or a tap.)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = LabGuide.TERM_REACH
	click.Parent = button
	local t: Terminal = {
		screen = screen,
		button = button,
		chute = cf * Vector3.new(2.8, 6, 0), -- (fix round 1: a spare drops in beside the console, never on it)
		origin = origin,
		target = target,
		queue = 0,
		working = false,
		combo = 0,
		comboAt = 0,
		presser = nil,
		noticeAt = 0,
		action = opts and opts.action,
		every = opts and opts.every,
		queueMax = opts and opts.queueMax,
	}
	terminals[screen] = t
	screen.Destroying:Connect(function()
		terminals[screen] = nil
	end)
	prompt.Triggered:Connect(function(player: Player)
		LabGuide.pressFrom(player, screen)
	end)
	click.MouseClick:Connect(function(player: Player)
		LabGuide.pressFrom(player, screen)
	end)
	m.Parent = into
	return screen
end
-- (V9-0m: another machine's terminal, with its own press: the Compressor.)
LabGuide.addTerminal = buildTerminal

-- A press from any path (the screen, the glowing button, the prompt). Fix round 1: a refused press is
-- never silent: its reason goes back to that player's screen (TerminalClient: COME CLOSER, WAIT, FULL...).
function LabGuide.pressFrom(player: Player, screen: Instance)
	local took, why = LabGuide.press(player, screen)
	if not took and why and terminals[screen] then
		Net.event(Net.Names.Terminal):FireClient(player, "Refused", screen, why)
	end
end

function LabGuide.start()
	if not (Config :: any).FEED_TERMINAL then
		return
	end
	Net.event(Net.Names.Terminal).OnServerEvent:Connect(function(player: Player, kind: unknown, screen: unknown)
		if type(kind) ~= "string" or typeof(screen) ~= "Instance" then
			return -- (only a known terminal's screen counts: press() looks it up in the server's own table)
		end
		if kind == "Press" then
			LabGuide.pressFrom(player, screen)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		pressTimes[player] = nil
		-- (Fix round 1: the lab's spares go with its player.)
		for _, m in spares[player] or {} do
			if m.Parent then
				m:Destroy()
			end
		end
		spares[player] = nil
	end)
end

-- Tests: the terminals built, and how many tosses they made.
function LabGuide.terminalsForTest(): { [Instance]: any }
	return terminals
end
function LabGuide.termTossedForTest(): number
	return termTossed
end
function LabGuide.sparesForTest(owner: Player): { Model }
	return sparesOf(owner)
end

-- One guided spot: its point (sign and button), its ring, and what the button does.
local function addSpot(into: Instance, origin: Vector3, id: string, target: () -> Vector3, words: { string }, signHeight: number, signTop: (() -> number?)?)
	local at = target()
	local point = anchoredPart("GuidePoint", Vector3.new(1, 1, 1), CFrame.new(at), into)
	point.Transparency = 1
	point:SetAttribute("GuideId", id)
	local floorY = groundUnder(at, origin.Y)
	-- (A dashed ring of glowing pieces, a drop zone: it marks the spot without covering what is there,
	-- the lava or the cannon's pad. The ring part itself is invisible and carries the pieces.)
	local ring = anchoredPart(LabGuide.TAG, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at.X, floorY + 0.12, at.Z), into)
	ring.Transparency = 1
	-- (V9-NOW 7: Config.REAL_PADS: the pads and machines (Station: spots) show no glowing ring; their real pad
	-- and paint say where. The invisible ring part stays: it carries the DROP HERE while a body is carried.)
	local pieces = if (Config :: any).REAL_PADS and string.sub(id, 1, 8) == "Station:" then 0 else 14
	for k = 1, pieces do
		local a = k / pieces * math.pi * 2
		local seg = anchoredPart("GuideRingSeg", Vector3.new(LabGuide.RING * math.pi / pieces * 0.62, 0.12, 0.5), CFrame.new(at.X + math.cos(a) * LabGuide.RING / 2, floorY + 0.3, at.Z + math.sin(a) * LabGuide.RING / 2) * CFrame.Angles(0, -a + math.pi / 2, 0), ring)
		seg.Material = Enum.Material.Neon
		seg.Color = LabGuide.ACCENT
		seg.Transparency = 0.25
	end
	ring:SetAttribute("GuideId", id)
	CollectionService:AddTag(ring, LabGuide.TAG)
	sign(point, words[3], signHeight)
	local prompt: ProximityPrompt? = nil
	if (Config :: any).FEED_TERMINAL then
		-- (V9-2b: a terminal you walk up to instead of a prompt in the air; the ring and the sign stay and
		-- follow the trigger. Fix round 1: built once the creature has set its real trigger (its first
		-- look, 0.3 s in), clear of the triggers, the lava and the creatures.)
		task.delay(1.2, function()
			if into.Parent then
				local ok, err = pcall(buildTerminal, into, origin, id, target, words, { out = OUT_BY_ID[id] })
				if not ok then
					warn("[LabGuide] terminal " .. id .. ": " .. tostring(err))
				end
			end
		end)
	elseif (Config :: any).GUIDE_PROMPTS ~= false then -- (owner, 21 Nov 2026: no feed buttons either; you throw the ragdoll in)
		local p = Instance.new("ProximityPrompt")
		p.Name = "Guide"
		p.ActionText = words[1]
		p.ObjectText = words[2]
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.MaxActivationDistance = LabGuide.PROMPT_REACH
		p.RequiresLineOfSight = false
		p.HoldDuration = 0
		p.Parent = point
		prompt = p
	end
	-- (A creature that moves, the vacuum, or a trigger set on its first look: the point follows.)
	task.spawn(function()
		while point.Parent do
			task.wait(1)
			local now = target()
			if (now - point.Position).Magnitude > 0.5 then
				point.CFrame = CFrame.new(now)
				local moveBy = CFrame.new(now.X, groundUnder(now, origin.Y) + 0.12, now.Z) * ring.CFrame:Inverse()
				for _, seg in ring:GetChildren() do
					if seg:IsA("BasePart") then
						seg.CFrame = moveBy * seg.CFrame
					end
				end
				ring.CFrame = moveBy * ring.CFrame
			end
			-- (The sign stands clear over the creature's head: its top, measured, plus a little.)
			local top = if signTop then signTop() else nil
			local board = point:FindFirstChild("GuideSign")
			if top and board and board:IsA("BillboardGui") then
				board.StudsOffsetWorldSpace = Vector3.new(0, math.max(signHeight, top + 3 - now.Y), 0)
			end
		end
	end)
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player: Player)
		local now = os.clock()
		if now - (spotLast[point] or 0) < LabGuide.SPOT_GAP or now - (playerLast[player] or 0) < LabGuide.PLAYER_GAP then
			return
		end
		local Lab = lazy("Lab")
		local owner = Lab.ownerAt(origin + Vector3.new(0, 1, 0))
		if not owner then
			return
		end
		-- (The lab's player, or someone the lab lets in: the same rule as a blast's reach.)
		if player ~= owner then
			local okReach, mayReach = pcall(function()
				return (require(Shared:WaitForChild("Zones")) :: any).mayReach(player, target())
			end)
			if not (okReach and mayReach) then
				return
			end
		end
		spotLast[point] = now
		playerLast[player] = now
		if not LabGuide.toss(player, owner, target() + Vector3.new(0, 1.5, 0)) then
			pcall(function()
				lazy("ProgressService").notice(player, "No free dummy right now. Try again in a moment!")
			end)
		end
	end)
end

-- Builds the guide into a lab's Playground folder (after LabCreatures.build and the stations).
function LabGuide.build(folder: Instance, origin: Vector3)
	local into = Instance.new("Folder")
	into.Name = "Guide"
	into.Parent = folder
	-- The creatures.
	local yard = folder:FindFirstChild("CreatureYard")
	local layout = lazy("LabCreatures").LAYOUT
	for _, spot in layout do
		local words = LabGuide.WORDS[spot.id]
		local sub = yard and yard:FindFirstChild(spot.id)
		if words and sub then
			local fallback = origin + Vector3.new(spot.x, 3, spot.z)
			local function target(): Vector3
				local t = sub:GetAttribute("Trigger")
				return if typeof(t) == "Vector3" then t else fallback
			end
			-- (The creature's own model: LabCreatures marks it with "Creature".)
			local function signTop(): number?
				for _, c in sub:GetChildren() do
					if c:IsA("Model") and c:GetAttribute("Creature") == spot.id then
						local cf, size = c:GetBoundingBox()
						return cf.Position.Y + size.Y / 2
					end
				end
				return nil
			end
			addSpot(into, origin, spot.id, target, words, 6, signTop)
		end
	end
	-- The PUT RAGDOLL HERE stations (their own signs say it; the button and the ring are added).
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") and d.Name == "StationPad" then
			local station = tostring(d:GetAttribute("Station") or "PAD")
			local pad = d
			local function target(): Vector3
				return pad.Position + Vector3.new(0, 1.5, 0)
			end
			local name = string.upper(string.sub(station, 1, 1)) .. string.lower(string.sub(station, 2))
			addSpot(into, origin, "Station:" .. station, target, { "Launch", name, "" }, 0)
		end
	end
	-- (21 Nov 2026, research: the biggest games' machines teach themselves: 44 % of one game's players
	-- launched a dummy with its fan. The cannon, the lava and the trampoline get the same button.)
	for name, words in LabGuide.MACHINES do
		local partOf = folder:FindFirstChild(name, true)
		if partOf and partOf:IsA("BasePart") then
			local p = partOf
			local function target(): Vector3
				return p.Position + Vector3.new(0, 1.5, 0)
			end
			addSpot(into, origin, "Station:" .. name, target, words, 0)
		end
	end
	-- (A station already has its own sign: its guide sign is left out.)
	for _, g in into:GetDescendants() do
		if g:IsA("BillboardGui") and g.Name == "GuideSign" then
			local point = g.Parent
			local id = point and point:GetAttribute("GuideId")
			if type(id) == "string" and string.sub(id, 1, 8) == "Station:" then
				g:Destroy()
			end
		end
	end
	return into
end

-- Tests: how many dummies were tossed so far.
function LabGuide.tossedForTest(): number
	return tossedCount
end

Players.PlayerRemoving:Connect(function(player)
	playerLast[player] = nil
end)

return LabGuide
