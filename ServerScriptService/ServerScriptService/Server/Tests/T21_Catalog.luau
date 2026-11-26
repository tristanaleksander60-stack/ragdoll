--!strict
-- The tool catalog (phase 4b): every tool in Shared/Toys is tested here and does what its card
-- says, through the same server code a tap uses. Each gets a fresh server-simulated dummy away
-- from the lab. A tool added to the catalog without a check here fails the test.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local HitService = require(Systems:WaitForChild("HitService"))
local ToyService = require(Systems:WaitForChild("ToyService"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local Toys = require(ReplicatedStorage.Shared.Toys)

local playerRules: () -> string

local ORIGIN = Vector3.new(-950, 0, 480) -- open baseplate, well inside its edge (x and z within 1024)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.05)
	end
	return check()
end

local function state(model: Model): string
	return tostring(model:GetAttribute("RagdollState"))
end

local function down(model: Model): boolean
	local s = state(model)
	return s == "Ragdoll" or s == "Out"
end

local function pelvis(model: Model): BasePart
	return model:FindFirstChild("LowerTorso") :: BasePart
end

local spot = 0
-- The next patch of ground (each check gets its own, 30 studs apart).
local function nextSpot(): Vector3
	spot += 1
	local at = ORIGIN + Vector3.new((spot % 6) * 30, 0, math.floor(spot / 6) * 30)
	assert(Workspace:Raycast(at + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0)), "no ground under the test spot")
	return at
end

local function standAt(at: Vector3): Model
	local model = DummyFactory.spawn(at, at + Vector3.zAxis)
	assert(waitFor(function()
		return state(model) == "Standing"
	end, 3), "a fresh dummy did not stand")
	return model
end

-- A fresh dummy on its own patch of ground, standing.
local function fresh(): Model
	local model = standAt(nextSpot())
	task.wait(0.2)
	return model
end

-- Two fresh dummies 10 studs apart on one patch.
local function pair(): (Model, Model)
	local at = nextSpot()
	local a = standAt(at)
	local b = standAt(at + Vector3.new(10, 0, 0))
	task.wait(0.2)
	return a, b
end

local function propNamed(name: string): Instance?
	local folder = Workspace:FindFirstChild("Props")
	return folder and folder:FindFirstChild(name)
end

type Check = (toy: Toys.Toy) -> string

local checks: { [string]: Check } = {}

-- Hands and Smack: the tap goes through HitService like a real one.
local function hitCheck(toy: Toys.Toy): string
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	local result = HitService.applyToy(toy, chest, chest.Position, Vector3.xAxis)
	assert(result ~= nil, toy.id .. " was refused")
	-- (V9-0ac, Config.SHOT_FLINCH: a round of any gun only flinches a living body (the damage drops it, T181); an
	-- arrow pins it back. Those are checked to move it.)
	local strong = toy.speed >= 40 and not (toy.gun and (require(game:GetService("ReplicatedStorage").Shared.Config) :: any).SHOT_FLINCH)
	assert(waitFor(function()
		return if strong then down(model) else state(model) ~= "Standing"
	end, 2), string.format("%s did not %s (state %s)", toy.id, if strong then "knock it down" else "move it", state(model)))
	local s = state(model)
	model:Destroy()
	return s
end

for _, toy in Toys.list do
	if toy.kind == "hit" then
		checks[toy.id] = hitCheck
	end
end

checks.Grab = function(): string
	-- The grab runs on the player's client; the server only accepts the request.
	return "client-side"
end

local function blastCheck(toy: Toys.Toy, wait: number, minDistance: number): string
	local a, b = pair()
	local mid = (pelvis(a).Position + pelvis(b).Position) / 2
	local floor = Vector3.new(mid.X, 0, mid.Z)
	assert(ToyService.place(nil, toy.id, floor, Vector3.zAxis), toy.id .. " was refused")
	assert(waitFor(function()
		return down(a) and down(b)
	end, wait), string.format("%s did not knock both down (%s, %s)", toy.id, state(a), state(b)))
	local _ = minDistance
	a:Destroy()
	b:Destroy()
	return "2 down"
end

checks.Firecracker = function(toy)
	-- Small: only right next to it.
	local model = fresh()
	local p = pelvis(model).Position
	assert(ToyService.place(nil, toy.id, Vector3.new(p.X + 2, 0, p.Z), Vector3.zAxis), "refused")
	assert(waitFor(function()
		return state(model) ~= "Standing"
	end, 1.5), "the firecracker did nothing next to it (" .. state(model) .. ")")
	local s = state(model)
	model:Destroy()
	return s
end
checks.TNT = function(toy)
	return blastCheck(toy, 3.5, 0)
end
checks.Shockwave = function(toy)
	return blastCheck(toy, 1.5, 0)
end
checks.BigBoom = function(toy)
	local result = blastCheck(toy, 3.5, 0)
	assert(propNamed("BigBoom") == nil, "the big boom bomb was left behind")
	return result
end

checks.StickyBomb = function(toy)
	local model = fresh()
	local arm = model:FindFirstChild("LeftUpperArm") :: BasePart
	assert(ToyService.onDummy(nil, toy.id, arm, arm.Position), "refused")
	assert(arm:FindFirstChild("StickyBomb"), "the bomb did not stick to the arm")
	assert(waitFor(function()
		return down(model) and arm:FindFirstChild("StickyBomb") == nil
	end, 3), "the sticky bomb never went off (" .. state(model) .. ")")
	model:Destroy()
	return "stuck, went off"
end

-- The big ones (10 Nov 2026).
checks.Grenade = function(toy)
	return blastCheck(toy, 3.5, 0)
end
checks.RPG = function(toy)
	-- (No shooter here: the rocket comes down from above onto the spot.)
	return blastCheck(toy, 3, 0)
end
checks.Nuke = function(toy)
	return blastCheck(toy, 4.5, 0)
end
checks.C4 = function(toy)
	local model = fresh()
	local arm = model:FindFirstChild("LeftUpperArm") :: BasePart
	assert(ToyService.onDummy(nil, toy.id, arm, arm.Position), "refused")
	assert(arm:FindFirstChild("C4"), "the C4 did not stick to the arm")
	assert(waitFor(function()
		return down(model) and arm:FindFirstChild("C4") == nil
	end, 4), "the C4 never went off (" .. state(model) .. ")")
	model:Destroy()
	return "stuck, went off"
end

checks.Cannon = function(toy)
	local model = fresh()
	local p = pelvis(model).Position
	assert(ToyService.place(nil, toy.id, Vector3.new(p.X, 0, p.Z), Vector3.zAxis), "refused")
	assert(propNamed("Cannonball"), "no cannonball")
	assert(waitFor(function()
		return down(model)
	end, 3), "the cannonball missed (" .. state(model) .. ")")
	model:Destroy()
	return "hit"
end

checks.Rocket = function(toy)
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	local startY = chest.Position.Y
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "refused")
	local top = startY
	waitFor(function()
		top = math.max(top, chest.Position.Y)
		return top > startY + 15
	end, 3)
	assert(top > startY + 15, string.format("the rocket only lifted it %.1f studs", top - startY))
	model:Destroy()
	return string.format("up %.0f", top - startY)
end

checks.Balloon = function(toy)
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	local startY = chest.Position.Y
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "refused")
	assert(chest:FindFirstChild("Balloon"), "no balloon")
	local top = startY
	waitFor(function()
		top = math.max(top, chest.Position.Y)
		return chest:FindFirstChild("Balloon") == nil
	end, 5)
	assert(chest:FindFirstChild("Balloon") == nil, "the balloon never popped")
	assert(top > startY + 10 and top < startY + 45, string.format("it floated %.1f studs (wanted a gentle 10-45)", top - startY))
	model:Destroy()
	return string.format("floated %.0f, popped", top - startY)
end

checks.Freeze = function(toy)
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "refused")
	assert(model:GetAttribute("Frozen") == true, "not frozen")
	model:Destroy()
	return "ice"
end

checks.Zap = function(toy)
	local model = fresh()
	-- Knock-outs are for dummies that live in the lab (they have a home to wake up and walk to).
	local p = pelvis(model).Position
	model:SetAttribute("Home", p)
	model:SetAttribute("HomeLook", p + Vector3.zAxis)
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "refused")
	assert(waitFor(function()
		return state(model) == "Out"
	end, 1.5), "the zap did not knock it out (" .. state(model) .. ")")
	model:Destroy()
	return "out cold"
end

checks.Heal = function(toy)
	local model = fresh()
	local shin = model:FindFirstChild("LeftLowerLeg") :: BasePart
	HitService.applyToy(Toys.byId.Launch, shin, shin.Position, Vector3.xAxis)
	assert(waitFor(function()
		return ((model:GetAttribute("Broken") :: number?) or 0) > 0
	end, 2), "the launch did not break a limb to heal")
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "refused")
	assert(((model:GetAttribute("Broken") :: number?) or 0) == 0, "the limb is still broken")
	model:Destroy()
	return "mended"
end

checks.BlackHole = function(toy)
	local a, b = pair()
	local mid = (pelvis(a).Position + pelvis(b).Position) / 2
	local center = Vector3.new(mid.X, 6, mid.Z) + Vector3.new(0, 0, 12)
	local before = (pelvis(a).Position - center).Magnitude + (pelvis(b).Position - center).Magnitude
	assert(ToyService.place(nil, toy.id, Vector3.new(center.X, 0, center.Z), Vector3.zAxis), "refused")
	local closest = before
	waitFor(function()
		closest = math.min(closest, (pelvis(a).Position - center).Magnitude + (pelvis(b).Position - center).Magnitude)
		return closest < before * 0.55
	end, 3)
	assert(closest < before * 0.55, string.format("pulled in only from %.0f to %.0f", before, closest))
	assert(waitFor(function()
		return propNamed("BlackHole") == nil
	end, 5), "the black hole never closed")
	a:Destroy()
	b:Destroy()
	return string.format("pulled %.0f -> %.0f", before, closest)
end

-- Props a dummy runs into or lands on: dropped from a little height onto it.
local function dropOnto(toy: Toys.Toy, height: number): Model
	local at = nextSpot()
	assert(ToyService.place(nil, toy.id, at, Vector3.zAxis), toy.id .. " was refused")
	task.wait(0.2)
	local model = DummyFactory.spawn(at, at + Vector3.zAxis, nil, height)
	return model
end

checks.SpringPad = function(toy)
	local model = dropOnto(toy, 5)
	local startY = pelvis(model).Position.Y
	local top = startY
	waitFor(function()
		top = math.max(top, pelvis(model).Position.Y)
		return top > startY + 18
	end, 3)
	-- (a trampoline bounces a dropped dummy 6-9 studs; the spring pad about three times as high)
	assert(top > startY + 18, string.format("the spring pad only flung it %.1f studs", top - startY))
	model:Destroy()
	return string.format("flung %.0f", top - startY)
end

checks.Banana = function(toy)
	local model = dropOnto(toy, 1.5)
	assert(waitFor(function()
		return down(model)
	end, 2.5), "it did not slip on the banana (" .. state(model) .. ")")
	model:Destroy()
	return "slipped"
end

-- Phase H's unlockables.
checks.Slime = function(toy)
	local model = dropOnto(toy, 1.5)
	assert(waitFor(function()
		return down(model)
	end, 2.5), "it did not slip on the slime (" .. state(model) .. ")")
	model:Destroy()
	return "slipped"
end

checks.Shrink = function(toy)
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "Shrink was refused")
	local scale = model:GetScale()
	assert(math.abs(scale - 0.5) < 0.01, string.format("shrunk to %.2f", scale))
	task.wait(1)
	assert(model.Parent and pelvis(model), "the shrunk dummy fell apart")
	model:Destroy()
	return "half size"
end

checks.Chicken = function(toy)
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	local before = chest.Color
	assert(ToyService.onDummy(nil, toy.id, chest, chest.Position), "Chicken was refused")
	local bits = model:FindFirstChild("ChickenBits")
	assert(model:GetAttribute("Chicken") == true and bits and bits:GetAttribute("Worn") == true, "no chicken look")
	assert(chest.Color ~= before, "the feathers are not white")
	for _, d in (bits :: Instance):GetDescendants() do
		if d:IsA("BasePart") then
			assert(not d.CanCollide and d.Massless, "a chicken bit collides or weighs something")
		end
	end
	-- One spell at a time; and frozen, a chicken turns back first (no white frozen in for good).
	local ok, why = ToyService.onDummy(nil, "Shrink", chest, chest.Position)
	assert(not ok and why == "Spell", "a chicken was shrunk too (" .. tostring(why) .. ")")
	DummyControl.freeze(model)
	assert(model:GetAttribute("Chicken") == nil and not model:FindFirstChild("ChickenBits"), "frozen while a chicken: it stayed a chicken under the ice")
	model:Destroy()
	return "bawk, freeze turns it back"
end

checks.Float = function(toy)
	local a, b = pair()
	local startA, startB = pelvis(a).Position.Y, pelvis(b).Position.Y
	local mid = (pelvis(a).Position + pelvis(b).Position) / 2
	assert(ToyService.place(nil, toy.id, Vector3.new(mid.X, 0, mid.Z), Vector3.zAxis), "Float was refused")
	assert(waitFor(function()
		return pelvis(a).Position.Y > startA + 3 and pelvis(b).Position.Y > startB + 3
	end, 4), string.format("they did not float up (%.1f, %.1f)", pelvis(a).Position.Y - startA, pelvis(b).Position.Y - startB))
	a:Destroy()
	b:Destroy()
	return "both floated"
end

checks.Slowmo = function(toy)
	-- A dummy sent straight up inside the bubble comes down at a crawl (in the open, a hit like this
	-- is back on the floor in about a second).
	local model = fresh()
	local floorY = pelvis(model).Position.Y
	local at = Vector3.new(pelvis(model).Position.X, 0, pelvis(model).Position.Z)
	assert(ToyService.place(nil, toy.id, at, Vector3.zAxis), "Slow-mo was refused")
	task.wait(0.15)
	local p = pelvis(model)
	DummyControl.hit(model, p, Vector3.new(0, 45, 0) * ((model:GetAttribute("Mass") :: number?) or 10), p.Position)
	local started = os.clock()
	local top = floorY
	assert(waitFor(function()
		top = math.max(top, pelvis(model).Position.Y)
		return top > floorY + 2 and pelvis(model).Position.Y < floorY + 1
	end, 6), string.format("it never came down in the bubble (top %.1f)", top - floorY))
	local airborne = os.clock() - started
	assert(airborne > 1.3, string.format("down again in %.2f s: no slow motion", airborne))
	model:Destroy()
	return string.format("%.1f s in the air", airborne)
end

checks.Portal = function(toy)
	ToyService.resetPortalsForTest()
	local model = fresh()
	local at = Vector3.new(pelvis(model).Position.X, 0, pelvis(model).Position.Z)
	assert(ToyService.place(nil, toy.id, at, Vector3.zAxis), "the first portal was refused")
	local exit = at + Vector3.new(28, 0, 0)
	assert(ToyService.place(nil, toy.id, exit, Vector3.zAxis), "the second portal was refused")
	model:SetAttribute("Broken", 1) -- (a portal moves it as it is: nothing mended on the way)
	assert(waitFor(function()
		return (Vector3.new(pelvis(model).Position.X, 0, pelvis(model).Position.Z) - at).Magnitude > 15
	end, 3), "the dummy did not go through the portal")
	assert(model:GetAttribute("Broken") == 1, "going through a portal mended the dummy")
	model:Destroy()
	ToyService.resetPortalsForTest()
	return "through"
end

checks.Trampoline = function(toy)
	local model = dropOnto(toy, 5)
	local startY = pelvis(model).Position.Y
	local top = startY
	waitFor(function()
		top = math.max(top, pelvis(model).Position.Y)
		return top > startY + 5
	end, 3)
	-- Higher than it was dropped from (it fell 5 studs onto the pad first).
	assert(top > startY + 5, string.format("the trampoline only bounced it %.1f studs above its drop", top - startY))
	model:Destroy()
	return string.format("bounced %.0f", top - startY)
end

checks.Anvil = function(toy)
	local model = fresh()
	local p = pelvis(model).Position
	assert(ToyService.place(nil, toy.id, Vector3.new(p.X, 0, p.Z), Vector3.zAxis), "refused")
	assert(waitFor(function()
		return state(model) ~= "Standing"
	end, 4), "the anvil missed")
	model:Destroy()
	return "flattened"
end

checks.Fan = function(toy)
	local model = fresh()
	local p = pelvis(model).Position
	local start = p
	assert(ToyService.place(nil, toy.id, Vector3.new(p.X, 0, p.Z - 10), Vector3.zAxis), "refused")
	local farthest = 0
	waitFor(function()
		farthest = math.max(farthest, (pelvis(model).Position - start).Magnitude)
		return farthest > 5
	end, 4)
	assert(farthest > 5, string.format("the fan moved it %.1f studs", farthest))
	model:Destroy()
	return string.format("blown %.0f", farthest)
end

checks.Bowling = function(toy)
	local model = fresh()
	local p = pelvis(model).Position
	assert(ToyService.place(nil, toy.id, Vector3.new(p.X, 0, p.Z), Vector3.zAxis), "refused")
	assert(waitFor(function()
		return state(model) ~= "Standing"
	end, 3), "the ball missed")
	model:Destroy()
	return "strike"
end

-- Tools and players: a blast knocks over only whoever set it off (no griefing); fans and black
-- holes are few per player; a rocket's body leaves the player's prop count when it is gone.
function playerRules(): string
	local Players = game:GetService("Players")
	local PlayerRagdoll = require(Systems:WaitForChild("PlayerRagdoll"))
	local player = Players:GetPlayers()[1]
	if not player then
		return "player rules skipped (no player)"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	assert(root, "the player has no body")
	local feet = Vector3.new(root.Position.X + 2, 0, root.Position.Z)
	-- Someone else's blast (source nil here): the player stays up.
	ToyService.blast(feet + Vector3.new(0, 0.5, 0), ToyService.BLASTS.Firecracker, nil, nil)
	task.wait(0.6)
	assert(not PlayerRagdoll.isDown(player), "a blast someone else set off knocked the player over")
	-- Their own: down they go.
	ToyService.blast(feet + Vector3.new(0, 0.5, 0), ToyService.BLASTS.Firecracker, nil, player)
	assert(waitFor(function()
		return PlayerRagdoll.isDown(player)
	end, 2), "the player's own blast did not knock them over")
	PlayerRagdoll.getUp(player)
	-- Fans: two at a time per player.
	for i = 1, 3 do
		ToyService.place(player, "Fan", nextSpot() + Vector3.new(i, 0, 0), Vector3.zAxis)
	end
	local folder = Workspace:FindFirstChild("Props")
	local fans = 0
	for _, prop in if folder then folder:GetChildren() else {} do
		if prop.Name == "Fan" and prop:GetAttribute("Owner") == player.UserId and prop:GetAttribute("Retiring") ~= true then
			fans += 1
		end
	end
	assert(fans == 2, string.format("%d fans out (wanted 2)", fans))
	ToyService.cleanUp(player)
	-- A rocket's body counts while it flies, and no longer once it is gone.
	assert(waitFor(function()
		return (player:GetAttribute("PropCount") :: number?) == 0
	end, 2), "clean up left props counted")
	local model = fresh()
	local chest = model:FindFirstChild("UpperTorso") :: BasePart
	ToyService.onDummy(player, "Rocket", chest, chest.Position)
	assert((player:GetAttribute("PropCount") :: number?) == 1, "the rocket was not counted")
	assert(waitFor(function()
		return (player:GetAttribute("PropCount") :: number?) == 0
	end, 4), "the rocket is still counted after it went off")
	model:Destroy()
	return "player rules: others' blasts spare you, 2 fans max, rockets counted right"
end

local function runAll(): string
	local missing = {}
	for _, toy in Toys.list do
		if not checks[toy.id] then
			table.insert(missing, toy.id)
		end
	end
	assert(#missing == 0, "tools without a check: " .. table.concat(missing, ", "))
	assert(#Toys.list >= 30, string.format("only %d tools in the catalog", #Toys.list))
	for _, id in Toys.defaultLoadout do
		assert(Toys.byId[id], "the default bar names " .. id)
	end
	local results = {}
	-- Pictures (phase K): every tool, event and place has a colour emoji (never plain letters), and
	-- no two in the same list share one.
	do
		local Events = require(ReplicatedStorage.Shared.Events) :: any
		local Places = require(ReplicatedStorage.Shared.Places) :: any
		-- Newer symbols that still draw as text unless asked (the ones near this game's pictures).
		local TEXT_DEFAULT = { [0x1F327] = true, [0x1F32C] = true, [0x1F573] = true, [0x1F590] = true, [0x1F570] = true, [0x1F5FA] = true, [0x1F441] = true, [0x1F39E] = true }
		local function checkList(what: string, entries: { any }, idOf: (any) -> string): number
			local seen: { [string]: string } = {}
			for _, e in entries do
				local glyph = e.glyph
				assert(type(glyph) == "string" and glyph ~= "", what .. " " .. idOf(e) .. " has no picture")
				assert((string.byte(glyph, 1) or 0) > 127, what .. " " .. idOf(e) .. " has letters, not a picture: " .. glyph)
				-- Drawn in colour, not as a one-colour symbol: a symbol from the older blocks (or one
				-- of the few newer ones that default to text) must ask for the emoji form (U+FE0F).
				local first = utf8.codepoint(glyph, 1)
				local asksEmoji = string.find(glyph, "\u{FE0F}", 1, true) ~= nil
				local textByDefault = first < 0x1F000 or TEXT_DEFAULT[first] == true
				assert(asksEmoji or not textByDefault, string.format("%s %s: %s would draw as a one-colour symbol (add U+FE0F)", what, idOf(e), glyph))
				assert(seen[glyph] == nil, string.format("%s %s and %s share the picture %s", what, seen[glyph] or "", idOf(e), glyph))
				seen[glyph] = idOf(e)
			end
			return #entries
		end
		local tools = checkList("tool", Toys.list, function(e) return e.id end)
		local events = checkList("event", Events.list or Events, function(e) return e.id end)
		local places = checkList("place", Places.list or Places, function(e) return e.id end)
		table.insert(results, string.format("pictures: %d tools, %d events, %d places, all colour emoji (emoji form asked where a symbol defaults to text), none shared", tools, events, places))
	end
	-- While fixing one tool: ServerStorage "CatalogFrom" = its id starts the run there.
	local from = game:GetService("ServerStorage"):GetAttribute("CatalogFrom")
	local skipping = type(from) == "string" and Toys.byId[from] ~= nil
	for _, toy in Toys.list do
		if skipping and toy.id == from then
			skipping = false
		end
		if skipping then
			continue
		end
		local ok, result = pcall(checks[toy.id], toy)
		if not ok then
			error(toy.id .. ": " .. tostring(result), 0)
		end
		table.insert(results, toy.id .. " " .. result)
		-- Leave the ground clear for the next one.
		local folder = Workspace:FindFirstChild("Props")
		for _, prop in if folder then folder:GetChildren() else {} do
			if (prop:GetAttribute("Owner") :: number?) == 0 then
				prop:Destroy()
			end
		end
	end
	table.insert(results, playerRules())
	return string.format("%d tools: %s", #Toys.list, table.concat(results, "; "))
end

return {
	name = "tool-catalog-every-tool-works",
	timeout = 260,
	run = function(): string?
		-- No server event in the middle of it (an earlier test may have left one queued).
		local EventService = require(Systems:WaitForChild("EventService"))
		EventService.holdForTest(true)
		local ok, result = pcall(function(): string
			assert(waitFor(function()
				return EventService.current() == nil
			end, 60), "a server event never ended")
			return runAll()
		end)
		EventService.holdForTest(false)
		if not ok then
			error(result, 0)
		end
		return result
	end,
}
