--!strict
-- The people (phase D): a crowd on the plaza behind the spawn, living their lives until something
-- happens. Each has a look that says who they are (baristas, office people, tourists), a name, and
-- goes about: strolls to a spot, stands a while looking around, walks up to someone and chats (the
-- talking itself is drawn by DummyLife on every screen). They are dummies like the lab's: hit them
-- and they fly, break, get up and walk on, limping.
--
-- Panic comes only from what reaches them (vault: NPC AI and Behaviour, perception in config): a
-- bang within earshot (a blast is heard far, a shot further than a slap), a body flying or lying out
-- cold in front of them within sight (a clear line, in front), or someone near them screaming off
-- (it spreads person to person with a beat of delay, never the whole plaza at once). A panicking
-- person runs from what scared them (ActiveRagdoll: PanicFrom / PanicUntil) and afterwards keeps to
-- a spot further away. A broken bone is patched up after a while.
--
-- Brains are cheap: perception is driven by the moments the server shares (FxService.onMoment) and
-- a sight scan four times a second; decisions run ten times a second in turns (each person twice a
-- second), and not at all while nobody is near the plaza. Walking, fleeing, limping and getting up
-- are ActiveRagdoll's (the brain only moves each person's Home). The server simulates the crowd:
-- phones only draw it.
--
-- Places (phase E): every room in Places has its own crowd (a zone), dressed for the place (chefs
-- in the food court, guards and cashiers in the supermarket, travellers in the hangar). A room's
-- people are brought in when a player comes near and sent home a while after the last one leaves,
-- so the server only carries the crowds someone is looking at (the plaza's always stays).
-- Each person has a personality (a voice card with one trait, vault: Writing Dialogue): Coward
-- (hears more, runs first and longest, screams furthest), Brave (runs least and comes back to look),
-- Grumpy (stands and shouts HEY! at what happened), Clown (often laughs at a body flying instead of
-- running, dances while it waits), Sleepy (slow to notice, dozes off while it lingers).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DummyFactory = require(script.Parent.DummyFactory)
local DummyControl = require(script.Parent.DummyControl)
local FxService = require(script.Parent.FxService)
local Blasts = require(script.Parent.Blasts)
local Log = require(ReplicatedStorage.Shared.Log)
local Places = require(ReplicatedStorage.Shared.Places)
local N7Models = require(ReplicatedStorage.Shared.N7Models)
local Toys = require(ReplicatedStorage.Shared.Toys)
local GunThreat = require(ReplicatedStorage.Shared.GunThreat)

local log = Log.new("Crowd")

local CrowdService = {}

------------------------------------------------------------------------------------------------
-- Config

CrowdService.SIZE = 12 -- people on the plaza
local ZONE_OFFSET = Vector3.new(0, 0, 85) -- the plaza's middle, from the lab's origin (behind the spawn)
local ZONE_RADIUS = 38
local ESCAPE_RADIUS = 58 -- how far from the middle a scared person may end up
local ACTIVE_RANGE = 260 -- studs from the plaza: nobody nearer, nobody thinks
local THINK_HZ = 10 -- brains per second, in turns
local THINK_EVERY = 0.5 -- s between one person's thoughts
local STROLL_MIN, STROLL_MAX = 8, 26 -- studs to the next spot
local LINGER_MIN, LINGER_MAX = 3, 8 -- s standing at a spot
local WALK_GIVE_UP = 20 -- s on the way to a spot before it picks another
local GREET_STUCK = 3 -- s a greeter gets no closer before it gives up
local CHAT_CHANCE = 0.35 -- of a person done lingering, if someone free is near
local MEET_RANGE = 30
-- Saying hi (round 2): a person done lingering may walk up to a player near it, wave and say "HI!"
-- (DummyLife draws it). Not everyone at once: one hello per player now and then.
local GREET_CHANCE = 0.3
local GREET_RANGE = 32 -- studs: a player this close may be greeted
local GREET_GAP = 20 -- s between two hellos to the same player
local GREET_STOP = 4.5 -- studs in front of the player where it stops
local GREET_TIME = 3 -- s it waves
local CHAT_MIN, CHAT_MAX = 6, 12 -- s
-- Studs between the two spots they head for: each stops up to HOME_ARRIVE (1.6) short of its spot
-- on the side it came from, so they end up about 3 to 5 studs apart, face to face.
local CHAT_GAP = 1.6
local CHAT_NEAR = 6 -- studs apart counts as together
CrowdService.HEAL_AFTER = 40 -- s with a broken bone before it is patched up
local RESPAWN_AFTER = 6 -- s after a person is lost (fell off, shattered)
local LOST_DISTANCE = 320
local EMPTY_AFTER = 30 -- s a room stays populated after the last player left it
local INVESTIGATE_GAP = 5 -- studs short of the trouble a brave person stops to look
CrowdService.LAUGH_CHANCE = 0.6 -- of a clown, at a body flying past
local DOZE_AFTER = 3 -- s of lingering before a sleepy person nods off

-- Perception.
CrowdService.HEARING = { -- studs a moment is heard from
	blastScale = 2.5, -- a blast is heard this many times its own radius off (a firecracker 22, Big Boom 90)
	cannon = 40, -- the cannons
	shot = 26, -- the Blaster (a shot on one side of the plaza is not heard on the far side)
	big = 40, -- a launch, a mega slap, an uppercut
	hit = 22, -- a slap, a punch, a bat
	land = 18, -- a body landing hard, a bone breaking
}
local CANNONS = { Cannon = true, CannonFire = true, CannonPad = true }
local SOUND_SPEED = 300 -- studs/s: the far ones hear it a beat later
local SIGHT_RANGE = 34
local SIGHT_CONE = 0.45 -- dot with the way it faces (about 63 degrees either side)
local SIGHT_SCAN = 0.25 -- s
local ALARMING_SPEED = 22 -- studs/s: a body moving this fast is flying
local SCREAM_RANGE = 14 -- a panicking person this close sets you off
local REACT_MIN, REACT_MAX = 0.15, 0.55 -- s from noticing to running
local SCREAM_MIN, SCREAM_MAX = 0.4, 0.9
-- A scream travels one person on from the one who saw or heard it, no further: panic spreads to
-- the people next to it, not across the whole plaza.
local SCREAM_HOPS = 1
local SIGHT_PER_SCAN = 3 -- people who notice a body in one look (the others are watching them)
local PANIC_MIN, PANIC_MAX = 4.5, 6.5 -- s of running

-- Who they are. Body colours by part, and what they wear (simple shapes on top).
local SKIN = {
	Color3.fromRGB(255, 220, 186),
	Color3.fromRGB(234, 190, 140),
	Color3.fromRGB(198, 140, 92),
	Color3.fromRGB(150, 98, 60),
	Color3.fromRGB(96, 64, 44),
}
local NAMES = {
	"Barry", "Linda", "Omar", "Priya", "Gus", "Mei", "Tomas", "Ada", "Kofi", "Nora", "Raj", "Elsa",
	"Hank", "Yuki", "Leo", "Fatima", "Dmitri", "Rosa", "Sven", "Amara", "Pete", "Ines", "Bo", "Lila",
	"Carl", "Zara", "Milo", "Greta", "Theo", "Nia",
}
export type Role = "Barista" | "Office" | "Tourist" | "Chef" | "Guard" | "Cashier" | "Traveler" | "Worker" | "Farmer" | "Soldier" | "Beachgoer"
export type Personality = "Coward" | "Brave" | "Grumpy" | "Clown" | "Sleepy"
local PERSONALITIES: { Personality } = { "Coward", "Brave", "Grumpy", "Clown", "Sleepy" }
type Traits = { panic: number, react: number, hearing: number, scream: number, linger: number, chat: number }
CrowdService.TRAITS = {
	Coward = { panic = 1.5, react = 0.6, hearing = 1.3, scream = 1.4, linger = 1, chat = 1 },
	Brave = { panic = 0.5, react = 0.8, hearing = 1, scream = 0.8, linger = 1, chat = 1.2 },
	Grumpy = { panic = 0.6, react = 1, hearing = 1, scream = 1, linger = 1.2, chat = 0.5 },
	Clown = { panic = 0.7, react = 1, hearing = 1, scream = 1, linger = 0.8, chat = 1.5 },
	Sleepy = { panic = 0.8, react = 1.8, hearing = 0.7, scream = 1, linger = 2, chat = 0.4 },
} :: { [Personality]: Traits }
local PLAIN: Traits = { panic = 1, react = 1, hearing = 1, scream = 1, linger = 1, chat = 1 }
local SHIRTS: { [Role]: { Color3 } } = {
	Barista = { Color3.fromRGB(35, 35, 40), Color3.fromRGB(240, 240, 235) },
	Office = { Color3.fromRGB(190, 215, 240), Color3.fromRGB(245, 245, 245), Color3.fromRGB(220, 200, 230) },
	Tourist = { Color3.fromRGB(255, 140, 60), Color3.fromRGB(40, 190, 180), Color3.fromRGB(240, 90, 150), Color3.fromRGB(250, 210, 60) },
	Chef = { Color3.fromRGB(248, 248, 248) },
	Guard = { Color3.fromRGB(40, 52, 88), Color3.fromRGB(30, 34, 44) },
	Cashier = { Color3.fromRGB(245, 245, 245), Color3.fromRGB(250, 230, 200) },
	Traveler = { Color3.fromRGB(120, 90, 170), Color3.fromRGB(70, 130, 90), Color3.fromRGB(200, 70, 70), Color3.fromRGB(90, 90, 100) },
	-- v4 B3: the open-air maps' people (dressed for the place).
	Worker = { Color3.fromRGB(70, 90, 120), Color3.fromRGB(110, 110, 115), Color3.fromRGB(150, 120, 90) },
	Farmer = { Color3.fromRGB(200, 60, 50), Color3.fromRGB(230, 220, 200), Color3.fromRGB(90, 130, 170) },
	Soldier = { Color3.fromRGB(85, 100, 60), Color3.fromRGB(100, 110, 75) },
	Beachgoer = { Color3.fromRGB(255, 120, 150), Color3.fromRGB(80, 200, 220), Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 255, 255) },
}
local PANTS: { [Role]: { Color3 } } = {
	Barista = { Color3.fromRGB(30, 30, 35), Color3.fromRGB(60, 50, 45) },
	Office = { Color3.fromRGB(55, 60, 75), Color3.fromRGB(95, 95, 100), Color3.fromRGB(35, 40, 60) },
	Tourist = { Color3.fromRGB(200, 180, 130), Color3.fromRGB(110, 140, 90), Color3.fromRGB(70, 110, 170) },
	Chef = { Color3.fromRGB(40, 40, 44), Color3.fromRGB(70, 70, 76) },
	Guard = { Color3.fromRGB(32, 40, 66) },
	Cashier = { Color3.fromRGB(40, 50, 70), Color3.fromRGB(60, 60, 64) },
	Traveler = { Color3.fromRGB(60, 80, 120), Color3.fromRGB(80, 70, 60), Color3.fromRGB(40, 40, 44) },
	Worker = { Color3.fromRGB(60, 70, 90), Color3.fromRGB(80, 70, 60) },
	Farmer = { Color3.fromRGB(50, 80, 140), Color3.fromRGB(60, 90, 150) }, -- (overalls)
	Soldier = { Color3.fromRGB(80, 95, 58), Color3.fromRGB(95, 105, 70) },
	Beachgoer = { Color3.fromRGB(40, 120, 200), Color3.fromRGB(240, 110, 60), Color3.fromRGB(60, 170, 110) }, -- (shorts)
}

-- Round 4, M11: real Roblox clothes and hair, as people in the top ragdoll games wear (the owner:
-- "much nicer NPCs"). All free Roblox-made catalog items: shirts and trousers by their texture
-- (no loading), hair loaded once at start (InsertService) and copied onto each person. The uniformed
-- roles (chef, guard, cashier) keep their painted uniforms; hats keep their heads (no hair under).
local function tex(id: number): string
	return "rbxassetid://" .. tostring(id)
end
local CLOTHES: { [Role]: { shirts: { string }, pants: { string } } } = {
	Barista = { -- (under the apron)
		shirts = { tex(3670737337), tex(382537700), tex(607785311) }, -- Simple Pattern, Teal, ROBLOX Jacket
		pants = { tex(382537568), tex(382538502) }, -- Black Jeans, Black Jeans with Sneakers
	},
	Office = {
		shirts = { tex(398635080), tex(144076435), tex(398633582) }, -- Blue Plaid, Grey Striped with Denim Jacket, Denim Jacket with White Hoodie
		pants = { tex(382537568), tex(144076759), tex(398633811) }, -- Black Jeans, Dark Green Jeans, Black Jeans with White Shoes
	},
	Tourist = {
		shirts = { tex(382537084), tex(4047884910), tex(382538058), tex(4047886039) }, -- I <3 Pizza, My Favorite Pizza, Green Jersey, Purple and Teal
		pants = { tex(382537805), tex(382537949) }, -- Jean Shorts, Jean Shorts with White Shoes
	},
	Traveler = {
		shirts = { tex(144076357), tex(398634294), tex(4047884003) }, -- Motorcycle Shirt, Pastel Starburst with Gray Jacket, Guitar Tee with Black Jacket
		pants = { tex(398635336), tex(398634485), tex(382538502) }, -- Ripped Skater, Beautiful You Jeans, Black Jeans with Sneakers
	},
}
-- Free Roblox hair (catalog ids), a mix of short, long, tied and curly in natural colours. Tall ones
-- would poke through a Santa hat: under one, only the others are picked.
CrowdService.HAIR_IDS = {
	9243992729, -- Short and Sleek - Black
	9244021842, -- Side Part - Black
	7193419595, -- Side Part - Brown
	7193386173, -- Side Part - Blonde
	7193442167, -- Pony Tail - Black
	9244097555, -- Pony Tail - Brown
	7193448258, -- Wavy Middle Part - Brown
	7193445686, -- Wavy Middle Part - Blonde
	7193450455, -- Curly Afro - Black
	9174355709, -- Sideswept Dreads - Black
	7193401217, -- Short Fringe - Black
	9244089488, -- Medium Middle Part - Black
	7193449810, -- Straight Bangs - Brown
	9174354743, -- Top Knot - Black
}
local TALL_HAIR: { [number]: boolean } = { [7193450455] = true, [9174355709] = true, [9174354743] = true }
local HAT_ROLES: { [string]: boolean } = { Chef = true, Guard = true, Tourist = true, Worker = true, Farmer = true, Soldier = true, Beachgoer = true }
CrowdService.HAT_ROLES = HAT_ROLES -- (roles with a hat of their own: no hair, no Santa hat; tests)
local hairs: { { accessory: Accessory, tall: boolean } } = {} -- loaded at start, copied per person
local looks = Random.new() -- (clothes and hair: the crowd's own rng is declared further down)

-- Loads the hair once, all at the same time (a failed one is left out), in the background: the
-- server never waits for it. `done` runs when every load has answered.
local function loadHair(done: () -> ())
	local InsertService = game:GetService("InsertService")
	local left = #CrowdService.HAIR_IDS
	for _, id in CrowdService.HAIR_IDS do
		task.spawn(function()
			local ok, asset = pcall(InsertService.LoadAsset, InsertService, id)
			local accessory = if ok and asset then asset:FindFirstChildOfClass("Accessory") else nil
			if accessory then
				accessory.Parent = nil
				table.insert(hairs, { accessory = accessory, tall = TALL_HAIR[id] == true })
			else
				log.warn("hair", id, "did not load")
			end
			if ok and asset then
				asset:Destroy()
			end
			left -= 1
			if left == 0 then
				done()
			end
		end)
	end
end

-- Puts a hair on a head, welded where the hair says it goes (its attachment's twin on the head,
-- HairAttachment), inside the outfit (worn, never a limb). Under a hat (a Santa hat) only a flat
-- style. Returns whether it went on.
local function giveHair(outfit: Model, head: BasePart, underHat: boolean): boolean
	local choices = {}
	for _, h in hairs do
		if not (underHat and h.tall) then
			table.insert(choices, h)
		end
	end
	if #choices == 0 then
		return false
	end
	local pick = choices[looks:NextInteger(1, #choices)]
	local hair = pick.accessory:Clone()
	-- (A tall one keeps a Santa hat off if Christmas comes on later: ChristmasService.)
	hair:SetAttribute("TallHair", if pick.tall then true else nil)
	local handle = hair:FindFirstChild("Handle")
	local own = handle and handle:FindFirstChildOfClass("Attachment")
	local at = own and head:FindFirstChild(own.Name)
	if not (handle and handle:IsA("BasePart") and own and at and at:IsA("Attachment")) then
		hair:Destroy()
		return false
	end
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.CastShadow = false
	handle.CFrame = head.CFrame * at.CFrame * own.CFrame:Inverse()
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = handle
	weld.C0 = at.CFrame
	weld.C1 = own.CFrame
	weld.Parent = handle
	hair.Parent = outfit
	return true
end

------------------------------------------------------------------------------------------------

type Mode = "Idle" | "Walk" | "Meet" | "Chat" | "Panic" | "Greet"
type Zone = {
	id: string,
	center: Vector3, -- the floor's middle (its height is the floor's)
	radius: number, -- where they stroll
	escape: number, -- how far out a scared person may end up
	lost: number, -- further than this from the middle: lost
	size: number, -- people
	roles: { Role },
	persistent: boolean, -- the plaza: always populated
	populated: boolean,
	emptySince: number?,
	active: boolean, -- a player is near: brains on
	filling: boolean, -- still bringing its people in (a few per tick)
}
type Npc = {
	model: Model,
	zone: Zone,
	personality: Personality,
	scaredBy: Vector3?, -- the last trouble (a brave person comes back to look)
	dozing: boolean,
	role: Role,
	name: string,
	mode: Mode,
	untilAt: number,
	partner: Npc?,
	spot: Vector3,
	thinkAt: number,
	panicUntil: number,
	panicPending: boolean,
	panicStarted: number?,
	healAt: number?,
	greeting: Player?, -- the player it is walking up to (Greet)
	greetBest: number, -- closest it has got to them so far (studs)
	greetProgressAt: number, -- when it last got a stud closer
}

local npcs: { Npc } = {}
local byModel: { [Model]: Npc } = {}
local zones: { Zone } = {}
local zoneById: { [string]: Zone } = {}
local plaza: Zone? = nil
local held = false -- tests: no thinking
local deaf = false -- tests: no noticing either
local plain = false -- tests: everyone the same (no personality changes timings or reach)
local rng = Random.new()

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function pelvisOf(npc: Npc): BasePart?
	local p = npc.model:FindFirstChild("LowerTorso")
	return if p and p:IsA("BasePart") then p else nil
end

local function stateOf(npc: Npc): string
	return (npc.model:GetAttribute("RagdollState") :: string?) or "Standing"
end

local function traitsOf(npc: Npc): Traits
	return if plain then PLAIN else CrowdService.TRAITS[npc.personality]
end

-- Floor at this spot (not a table top or a shelf): a ray down lands at the zone's floor height.
local function onFloor(zone: Zone, spot: Vector3, params: RaycastParams): boolean
	-- (From well above: a ray from 5 up started inside the island's grass hill, met the floor under it
	-- and stood people inside the hill, v4 A2. A roof, a tree or a hill over the spot now refuses it.)
	local hit = Workspace:Raycast(Vector3.new(spot.X, zone.center.Y + 40, spot.Z), Vector3.new(0, -45, 0), params)
	-- (2 studs: the open-air city's streets stand 1.0 and its sidewalks 1.6 over its floor; at 1 every
	-- spot failed and the whole crowd piled up in the middle, 19 Nov. Tables are higher.)
	-- (5 on an open-air map: terrain is uneven by a few studs, the army base's road and grass too.)
	local place = Places.byId[zone.id]
	local tolerance = if place and place.outdoor then 5 else 2
	return hit ~= nil and math.abs(hit.Position.Y - zone.center.Y) < tolerance
end

local function pick<T>(list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

local function rayParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ignore, dummies)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	return params
end

------------------------------------------------------------------------------------------------
-- Looks

local function weldOn(outfit: Model, to: BasePart, name: string, size: Vector3, color: Color3, offset: CFrame, shape: Enum.PartType?, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = to.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = to
	weld.Part1 = p
	weld.C0 = offset
	weld.Parent = p
	p.Parent = outfit
end

-- A real piece of clothing (round 2, N7: ServerStorage.N7Assets.Wear.<name> via N7Models, Studio-generated
-- meshes kept with the pivot at the middle and the front facing -Z), fitted inside `box` with its
-- middle at `offset` from the part it is welded to (a hat: its brim's bottom there, `onTop`). False
-- when the place has none (the built shapes stand in).
local function wear(outfit: Model, to: BasePart, name: string, box: Vector3, offset: CFrame, onTop: boolean?): boolean
	local piece = N7Models.clone("Wear", name)
	if not piece then
		return false
	end
	piece:SetAttribute("Worn", true) -- (the nearest model holding each part says it is worn)
	local _, size = piece:GetBoundingBox()
	local k = math.min(box.X / size.X, box.Y / size.Y, box.Z / size.Z)
	piece:ScaleTo(piece:GetScale() * k)
	piece:PivotTo(to.CFrame * offset * CFrame.new(0, if onTop then size.Y * k / 2 else 0, 0))
	for _, d in piece:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.CastShadow = false
			local weld = Instance.new("Weld")
			weld.Part0 = to
			weld.Part1 = d
			weld.C0 = to.CFrame:ToObjectSpace(d.CFrame)
			weld.Parent = d
		end
	end
	piece.Parent = outfit
	return true
end

local function paint(model: Model, names: { string }, color: Color3)
	for _, name in names do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
end

-- Dresses a fresh dummy as one of the crowd: skin, shirt and trousers, and the one thing that says
-- what they do (an apron, a tie, a bucket hat and a camera).
local function dress(model: Model, role: Role)
	DummyFactory.removeMarks(model)
	local skin = pick(SKIN)
	local shirt = pick(SHIRTS[role])
	model:SetAttribute("CrowdTint", shirt) -- (FIXES_28NOV 13, V6_EVERYONE: the clients draw the crowd in the v6 body, tinted by role)
	local pants = pick(PANTS[role])
	paint(model, { "Head", "LeftHand", "RightHand" }, skin)
	paint(model, { "UpperTorso", "LeftUpperArm", "RightUpperArm" }, shirt)
	paint(model, { "LeftLowerArm", "RightLowerArm" }, if role == "Office" or role == "Guard" or role == "Chef" or role == "Soldier" then shirt else skin)
	paint(model, { "LowerTorso", "LeftUpperLeg", "RightUpperLeg" }, pants)
	paint(model, { "LeftLowerLeg", "RightLowerLeg" }, if role == "Tourist" or role == "Beachgoer" then skin else pants)
	paint(model, { "LeftFoot", "RightFoot" }, Color3.fromRGB(40, 36, 34))
	-- Round 4, M11: real clothes where the role is not a uniform (skin under them, so a T-shirt's
	-- sleeves and shorts show arms and legs).
	local clothes = CLOTHES[role]
	if clothes then
		paint(model, { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg" }, skin)
		local shirtPiece = Instance.new("Shirt")
		shirtPiece.ShirtTemplate = pick(clothes.shirts)
		shirtPiece.Parent = model
		local pantsPiece = Instance.new("Pants")
		pantsPiece.PantsTemplate = pick(clothes.pants)
		pantsPiece.Parent = model
	end

	local outfit = Instance.new("Model")
	outfit.Name = "Outfit"
	outfit:SetAttribute("Worn", true) -- never part of the body when it goes limp
	local chest = model:FindFirstChild("UpperTorso") :: BasePart?
	local belly = model:FindFirstChild("LowerTorso") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	if chest and belly and head then
		local front = -chest.Size.Z / 2 - 0.06
		if role == "Barista" then
			local apron = pick({ Color3.fromRGB(60, 120, 80), Color3.fromRGB(150, 90, 50) })
			weldOn(outfit, chest, "Apron", Vector3.new(chest.Size.X * 0.7, chest.Size.Y * 0.7, 0.1), apron, CFrame.new(0, -chest.Size.Y * 0.12, front))
			weldOn(outfit, belly, "ApronSkirt", Vector3.new(belly.Size.X * 0.8, belly.Size.Y + 0.5, 0.1), apron, CFrame.new(0, -0.3, -belly.Size.Z / 2 - 0.06))
		elseif role == "Office" then
			weldOn(outfit, chest, "Tie", Vector3.new(0.22, chest.Size.Y * 0.75, 0.08), pick({ Color3.fromRGB(170, 30, 40), Color3.fromRGB(30, 50, 110), Color3.fromRGB(40, 40, 45) }), CFrame.new(0, -chest.Size.Y * 0.08, front))
		elseif role == "Chef" then
			if not wear(outfit, head, "ChefHat", Vector3.new(head.Size.X * 1.2, 1.6, head.Size.X * 1.2), CFrame.new(0, head.Size.Y * 0.5 - 0.3, 0), true) then
				weldOn(outfit, head, "ChefHat", Vector3.new(1.4, head.Size.X * 1.05, head.Size.X * 1.05), Color3.fromRGB(252, 252, 252), CFrame.new(0, head.Size.Y * 0.5 + 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
				weldOn(outfit, head, "ChefPuff", Vector3.new(head.Size.X * 1.25, head.Size.X * 1.25, head.Size.X * 1.25), Color3.fromRGB(252, 252, 252), CFrame.new(0, head.Size.Y * 0.5 + 1.3, 0), Enum.PartType.Ball)
			end
			weldOn(outfit, chest, "Apron", Vector3.new(chest.Size.X * 0.75, chest.Size.Y * 0.75, 0.1), Color3.fromRGB(235, 235, 235), CFrame.new(0, -chest.Size.Y * 0.1, front))
			weldOn(outfit, belly, "ApronSkirt", Vector3.new(belly.Size.X * 0.85, belly.Size.Y + 0.6, 0.1), Color3.fromRGB(235, 235, 235), CFrame.new(0, -0.3, -belly.Size.Z / 2 - 0.06))
		elseif role == "Guard" then
			if not wear(outfit, head, "GuardCap", Vector3.new(head.Size.X * 1.12, 0.9, head.Size.Z * 1.4), CFrame.new(0, head.Size.Y * 0.5 - 0.32, -head.Size.Z * 0.08), true) then
				weldOn(outfit, head, "Cap", Vector3.new(head.Size.X * 1.04, 0.45, head.Size.Z * 1.04), Color3.fromRGB(26, 32, 54), CFrame.new(0, head.Size.Y * 0.45, 0))
				weldOn(outfit, head, "Peak", Vector3.new(head.Size.X * 0.9, 0.12, 0.7), Color3.fromRGB(16, 18, 26), CFrame.new(0, head.Size.Y * 0.32, -head.Size.Z / 2 - 0.3))
			end
			weldOn(outfit, chest, "Badge", Vector3.new(0.4, 0.45, 0.08), Color3.fromRGB(240, 200, 70), CFrame.new(-chest.Size.X * 0.25, chest.Size.Y * 0.18, front), nil, Enum.Material.Metal)
		elseif role == "Cashier" then
			local vest = Color3.fromRGB(40, 170, 90)
			weldOn(outfit, chest, "VestL", Vector3.new(chest.Size.X * 0.32, chest.Size.Y * 0.9, 0.1), vest, CFrame.new(-chest.Size.X * 0.3, -chest.Size.Y * 0.04, front))
			weldOn(outfit, chest, "VestR", Vector3.new(chest.Size.X * 0.32, chest.Size.Y * 0.9, 0.1), vest, CFrame.new(chest.Size.X * 0.3, -chest.Size.Y * 0.04, front))
			weldOn(outfit, chest, "NameTag", Vector3.new(0.5, 0.25, 0.06), Color3.fromRGB(250, 250, 250), CFrame.new(chest.Size.X * 0.3, chest.Size.Y * 0.2, front - 0.07))
		elseif role == "Worker" then
			-- v4 B3: hi-vis vest and a hard hat.
			local vest = pick({ Color3.fromRGB(255, 140, 20), Color3.fromRGB(220, 240, 40) })
			weldOn(outfit, chest, "VestL", Vector3.new(chest.Size.X * 0.36, chest.Size.Y * 0.92, 0.1), vest, CFrame.new(-chest.Size.X * 0.28, -chest.Size.Y * 0.03, front))
			weldOn(outfit, chest, "VestR", Vector3.new(chest.Size.X * 0.36, chest.Size.Y * 0.92, 0.1), vest, CFrame.new(chest.Size.X * 0.28, -chest.Size.Y * 0.03, front))
			weldOn(outfit, chest, "Stripe", Vector3.new(chest.Size.X * 0.95, 0.14, 0.12), Color3.fromRGB(230, 230, 230), CFrame.new(0, -chest.Size.Y * 0.18, front - 0.02), nil, Enum.Material.Neon)
			weldOn(outfit, head, "HardHat", Vector3.new(head.Size.X * 1.18, 0.55, head.Size.Z * 1.18), Color3.fromRGB(255, 205, 30), CFrame.new(0, head.Size.Y * 0.47, 0))
			weldOn(outfit, head, "HatBrim", Vector3.new(head.Size.X * 1.3, 0.12, head.Size.Z * 1.4), Color3.fromRGB(240, 190, 25), CFrame.new(0, head.Size.Y * 0.3, -0.08))
		elseif role == "Farmer" then
			-- Overall straps and a straw hat.
			for _, x in { -0.28, 0.28 } do
				weldOn(outfit, chest, "Strap", Vector3.new(0.22, chest.Size.Y * 0.95, 0.08), Color3.fromRGB(50, 80, 140), CFrame.new(chest.Size.X * x, 0, front))
			end
			weldOn(outfit, chest, "Bib", Vector3.new(chest.Size.X * 0.55, chest.Size.Y * 0.42, 0.08), Color3.fromRGB(50, 80, 140), CFrame.new(0, -chest.Size.Y * 0.28, front))
			weldOn(outfit, head, "StrawBrim", Vector3.new(0.14, head.Size.X * 2, head.Size.X * 2), Color3.fromRGB(225, 195, 120), CFrame.new(0, head.Size.Y * 0.42, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, Enum.Material.Fabric)
			weldOn(outfit, head, "StrawTop", Vector3.new(0.6, head.Size.X * 1.05, head.Size.X * 1.05), Color3.fromRGB(215, 185, 110), CFrame.new(0, head.Size.Y * 0.68, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, Enum.Material.Fabric)
		elseif role == "Soldier" then
			-- An olive helmet and a belt.
			weldOn(outfit, head, "Helmet", Vector3.new(head.Size.X * 1.22, 0.75, head.Size.Z * 1.25), Color3.fromRGB(70, 82, 50), CFrame.new(0, head.Size.Y * 0.43, 0), nil, Enum.Material.Fabric)
			weldOn(outfit, belly, "Belt", Vector3.new(belly.Size.X * 1.04, 0.25, belly.Size.Z * 1.04), Color3.fromRGB(45, 40, 32), CFrame.new(0, belly.Size.Y * 0.3, 0))
		elseif role == "Beachgoer" then
			-- A sun hat and sunglasses.
			weldOn(outfit, head, "SunBrim", Vector3.new(0.12, head.Size.X * 1.9, head.Size.X * 1.9), pick({ Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 180, 200) }), CFrame.new(0, head.Size.Y * 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, Enum.Material.Fabric)
			weldOn(outfit, head, "SunTop", Vector3.new(0.5, head.Size.X * 1.02, head.Size.X * 1.02), Color3.fromRGB(255, 240, 200), CFrame.new(0, head.Size.Y * 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, Enum.Material.Fabric)
			weldOn(outfit, head, "Shades", Vector3.new(head.Size.X * 0.85, 0.22, 0.1), Color3.fromRGB(20, 20, 24), CFrame.new(0, head.Size.Y * 0.08, -head.Size.Z / 2 - 0.05), nil, Enum.Material.Glass)
		elseif role == "Traveler" then
			-- (The backpack is worn on the back: its front, the side with the pocket, faces away.)
			if not wear(outfit, chest, "Backpack", Vector3.new(chest.Size.X * 0.85, chest.Size.Y * 1.05, 0.95), CFrame.new(0, -chest.Size.Y * 0.05, chest.Size.Z / 2 + 0.45) * CFrame.Angles(0, math.pi, 0)) then
				weldOn(outfit, chest, "Backpack", Vector3.new(chest.Size.X * 0.75, chest.Size.Y * 0.9, 0.8), pick({ Color3.fromRGB(230, 120, 40), Color3.fromRGB(50, 90, 160), Color3.fromRGB(60, 60, 64) }), CFrame.new(0, -chest.Size.Y * 0.05, chest.Size.Z / 2 + 0.42))
			end
			-- (A travel pillow round the neck, its open end at the chin.)
			if not wear(outfit, head, "NeckPillow", Vector3.new(head.Size.X * 1.35, 0.55, head.Size.Z * 1.35), CFrame.new(0, -head.Size.Y * 0.5 - 0.02, head.Size.Z * 0.08)) then
				weldOn(outfit, head, "Pillow", Vector3.new(head.Size.X * 1.2, 0.45, 0.6), Color3.fromRGB(120, 180, 230), CFrame.new(0, -head.Size.Y * 0.5, head.Size.Z * 0.2))
			end
		else
			if not wear(outfit, head, "BucketHat", Vector3.new(head.Size.X * 1.6, 0.9, head.Size.X * 1.6), CFrame.new(0, head.Size.Y * 0.5 - 0.38, 0), true) then
				weldOn(outfit, head, "HatBrim", Vector3.new(0.2, head.Size.X * 1.6, head.Size.X * 1.6), Color3.fromRGB(235, 220, 170), CFrame.new(0, head.Size.Y * 0.42, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
				weldOn(outfit, head, "HatTop", Vector3.new(0.5, head.Size.X * 1.05, head.Size.X * 1.05), Color3.fromRGB(235, 220, 170), CFrame.new(0, head.Size.Y * 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
			end
			if not wear(outfit, chest, "Camera", Vector3.new(0.8, 0.6, 0.6), CFrame.new(0.2, -chest.Size.Y * 0.18, front - 0.28)) then
				weldOn(outfit, chest, "Camera", Vector3.new(0.7, 0.45, 0.35), Color3.fromRGB(30, 30, 34), CFrame.new(0.2, -chest.Size.Y * 0.18, front - 0.15))
				weldOn(outfit, chest, "Lens", Vector3.new(0.2, 0.3, 0.3), Color3.fromRGB(90, 140, 200), CFrame.new(0.2, -chest.Size.Y * 0.18, front - 0.42) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder, Enum.Material.Glass)
			end
		end
		if not HAT_ROLES[role] then
			local underHat = model:FindFirstChild("XmasHat") ~= nil
			if not giveHair(outfit, head, underHat) and role == "Office" then
				-- (The hair has not loaded yet: a plain cap of hair stands in until it has.)
				weldOn(outfit, head, "Hair", Vector3.new(head.Size.X * 1.02, 0.35, head.Size.Z * 1.02), Color3.fromRGB(45, 35, 30), CFrame.new(0, head.Size.Y / 2, 0))
			end
		end
	end
	outfit.Parent = model
	-- A Christmas hat (ChristmasService, on as the body was made) never sits on a hat of their own:
	-- the chef, the guard and the tourist keep theirs (and the scarf).
	local xmas = model:FindFirstChild("XmasHat")
	if xmas and HAT_ROLES[role] then
		xmas:Destroy()
		DummyControl.reassertOwner(model)
	end
end

-- Hair for the people dressed before it had loaded (the plaza's, at start).
local function backfillHair()
	if #hairs == 0 then
		return
	end
	for _, npc in npcs do
		local outfit = npc.model:FindFirstChild("Outfit")
		local head = npc.model:FindFirstChild("Head")
		if HAT_ROLES[npc.role] or not (outfit and outfit:IsA("Model") and head and head:IsA("BasePart")) then
			continue
		end
		if not outfit:FindFirstChildOfClass("Accessory") and giveHair(outfit, head, npc.model:FindFirstChild("XmasHat") ~= nil) then
			local stand = outfit:FindFirstChild("Hair") -- (the plain cap that stood in, now the hair is on)
			if stand then
				stand:Destroy()
			end
			DummyControl.reassertOwner(npc.model)
		end
	end
end

------------------------------------------------------------------------------------------------
-- Going about

local function wake(npc: Npc)
	if npc.dozing then
		npc.dozing = false
		npc.model:SetAttribute("Dozing", nil)
	end
end

local function setGoal(npc: Npc, spot: Vector3, facing: Vector3?)
	wake(npc)
	local pelvis = pelvisOf(npc)
	local y = if pelvis then pelvis.Position.Y else spot.Y
	npc.spot = Vector3.new(spot.X, y, spot.Z)
	npc.model:SetAttribute("Home", npc.spot)
	local face = facing or (npc.spot + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)))
	npc.model:SetAttribute("HomeLook", Vector3.new(face.X, y, face.Z))
end

-- Somewhere to stroll to: on the plaza, a stroll away, on open floor with nothing in the way and
-- nobody else headed there.
local function strollSpot(npc: Npc, from: Vector3, radius: number?): Vector3?
	local params = rayParams()
	local zone = npc.zone
	local center = zone.center
	local limit = radius or zone.radius
	for _ = 1, 8 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local distance = rng:NextNumber(STROLL_MIN, STROLL_MAX)
		local spot = flat(from) + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
		local offCentre = flat(spot - center)
		if offCentre.Magnitude > limit then
			spot = flat(center) + offCentre.Unit * limit * rng:NextNumber(0.5, 0.95)
		end
		local taken = false
		for _, other in npcs do
			if other ~= npc and flat(other.spot - spot).Magnitude < 4 then
				taken = true
				break
			end
		end
		-- (At the zone's own floor height; not onto a table or a shelf.)
		local waist = Vector3.new(0, center.Y + 2, 0)
		local clear = not taken
			and onFloor(zone, spot, params)
			and Workspace:Raycast(flat(from) + waist, flat(spot - from), params) == nil
		if clear then
			return spot
		end
	end
	return nil
end

local function endChat(npc: Npc, now: number)
	local partner = npc.partner
	npc.partner = nil
	npc.model:SetAttribute("Chatting", nil)
	npc.mode = "Idle"
	npc.untilAt = now + rng:NextNumber(1, 3)
	if partner and partner.partner == npc then
		endChat(partner, now)
	end
end

local function stroll(npc: Npc, from: Vector3, now: number)
	local spot = strollSpot(npc, from)
	if spot then
		setGoal(npc, spot)
		npc.mode = "Walk"
		npc.untilAt = now + WALK_GIVE_UP
	else
		npc.mode = "Idle"
		npc.untilAt = now + rng:NextNumber(1, 3)
	end
end

-- Two people walk up to each other and turn to talk.
-- What nobody meets inside (N7: the plaza's fountain, a model marked KeepOut = its radius in studs).
local keepOutCache: { { at: Vector3, radius: number } }? = nil
local function keepOuts(): { { at: Vector3, radius: number } }
	if keepOutCache then
		return keepOutCache
	end
	local list = {}
	local dressing = Workspace:FindFirstChild("PlazaDressing")
	for _, m in if dressing then dressing:GetChildren() else {} do
		local r = m:GetAttribute("KeepOut")
		if m:IsA("Model") and type(r) == "number" then
			table.insert(list, { at = flat(m:GetPivot().Position), radius = r })
		end
	end
	if dressing then
		keepOutCache = list -- (built once the plaza is)
	end
	return list
end

local function meet(a: Npc, b: Npc, now: number)
	local pa, pb = pelvisOf(a), pelvisOf(b)
	if not pa or not pb then
		return
	end
	local mid = (flat(pa.Position) + flat(pb.Position)) / 2
	local across = flat(pb.Position - pa.Position)
	across = if across.Magnitude > 0.1 then across.Unit else Vector3.xAxis
	-- (Never in the fountain: the meeting moves out to its rim, on the side it was nearest.)
	for _, k in keepOuts() do
		local out = mid - k.at
		local clear = k.radius + CHAT_GAP
		if out.Magnitude < clear then
			local dir = if out.Magnitude > 0.1 then out.Unit else Vector3.new(-across.Z, 0, across.X)
			mid = k.at + dir * clear
		end
	end
	local spotA = mid - across * CHAT_GAP / 2
	local spotB = mid + across * CHAT_GAP / 2
	setGoal(a, spotA, spotB)
	setGoal(b, spotB, spotA)
	for _, npc in { a, b } do
		npc.mode = "Meet"
		npc.untilAt = now + WALK_GIVE_UP
		-- (Walking up, not talking yet: a chat it was in is over; its old partner sees that and stops.)
		npc.model:SetAttribute("Chatting", nil)
	end
	a.partner = b
	b.partner = a
end

local lastGreeted: { [Player]: number } = {}
Players.PlayerRemoving:Connect(function(player)
	lastGreeted[player] = nil
end)

-- Walks up to the nearest player near it to say hi (if nobody greeted them a moment ago).
local function greet(npc: Npc, here: Vector3, now: number): boolean
	local best: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDistance = GREET_RANGE
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- (Not to someone who just fired a gun: GunThreat.)
		if root and root:IsA("BasePart") and now - (lastGreeted[player] or -math.huge) >= GREET_GAP and not GunThreat.raised(character) then
			local d = flat(root.Position - here).Magnitude
			if d < bestDistance and d > GREET_STOP + 1 and math.abs(root.Position.Y - here.Y) < 8 then
				best, bestRoot, bestDistance = player, root, d
			end
		end
	end
	if not best or not bestRoot then
		return false
	end
	local toward = flat(bestRoot.Position - here).Unit
	local spot = flat(bestRoot.Position) - toward * GREET_STOP + Vector3.new(0, here.Y, 0)
	if not onFloor(npc.zone, spot, rayParams()) then
		return false
	end
	lastGreeted[best] = now
	-- (Done with any chat first: a partner ending it later must not end this hello.)
	if npc.partner then
		endChat(npc, now)
	end
	setGoal(npc, spot, bestRoot.Position)
	npc.mode = "Greet"
	npc.greeting = best
	npc.greetBest = bestDistance
	npc.greetProgressAt = now
	npc.untilAt = now + WALK_GIVE_UP / 2
	return true
end
CrowdService.greetForTest = function(model: Model): boolean
	local npc = byModel[model]
	local pelvis = npc and pelvisOf(npc)
	if not npc or not pelvis then
		return false
	end
	for player in lastGreeted do
		lastGreeted[player] = nil
	end
	return greet(npc, pelvis.Position, os.clock())
end

-- (Tests: a person kept to itself, so nobody walks up to chat while a check watches it.)
local alone: { [Model]: boolean } = {}

local function free(npc: Npc): boolean
	return (npc.mode == "Idle" or npc.mode == "Walk") and stateOf(npc) == "Standing" and npc.panicUntil < os.clock() and not alone[npc.model]
end

local function think(npc: Npc, now: number)
	local model = npc.model
	local pelvis = pelvisOf(npc)
	if not pelvis then
		return
	end
	local state = stateOf(npc)
	-- A broken bone gets patched up once it has had time to hurt (standing or walking about).
	local broken = (model:GetAttribute("Broken") :: number?) or 0
	if broken > 0 then
		npc.healAt = npc.healAt or now + CrowdService.HEAL_AFTER
		if now >= (npc.healAt :: number) and (state == "Standing" or state == "Walking") then
			npc.healAt = nil
			DummyControl.heal(model)
			FxService.hit(pelvis.Position + Vector3.new(0, 1, 0), 0, "Heal")
		end
	else
		npc.healAt = nil
	end
	-- v4 B4: a body a player has talked to follows that player's commands (NpcCommand), not ours.
	if model:GetAttribute("CommandedBy") ~= nil then
		return
	end
	if npc.mode == "Panic" then
		if now < npc.panicUntil then
			return
		end
		npc.mode = "Idle"
		npc.untilAt = now + rng:NextNumber(LINGER_MIN, LINGER_MAX) * traitsOf(npc).linger -- catches its breath where it is
		-- A brave one goes back to see what happened; a grumpy one turns and shouts at it.
		local scare = npc.scaredBy
		npc.scaredBy = nil
		if scare and not plain and (state == "Standing" or state == "Walking") then
			if npc.personality == "Brave" then
				local toward = flat(scare - pelvis.Position)
				if toward.Magnitude > INVESTIGATE_GAP + 2 then
					local spot = flat(scare) - toward.Unit * INVESTIGATE_GAP
					if onFloor(npc.zone, spot, rayParams()) then
						setGoal(npc, spot, scare)
						npc.mode = "Walk"
						npc.untilAt = now + WALK_GIVE_UP
						return
					end
				end
			elseif npc.personality == "Grumpy" then
				setGoal(npc, pelvis.Position, scare)
				model:SetAttribute("AngryUntil", Workspace:GetServerTimeNow() + 3)
			end
		end
	end
	if state ~= "Standing" and state ~= "Walking" then
		-- Knocked about, getting up, running: no plans for now (a chat is over).
		if npc.mode == "Chat" or npc.mode == "Meet" then
			endChat(npc, now)
		end
		return
	end
	local here = pelvis.Position
	local arrived = state == "Standing" and flat(npc.spot - here).Magnitude < 3
	if npc.mode == "Walk" then
		if arrived or now >= npc.untilAt then
			npc.mode = "Idle"
			npc.untilAt = now + rng:NextNumber(LINGER_MIN, LINGER_MAX) * traitsOf(npc).linger
			-- Looks about while it stands there.
			setGoal(npc, npc.spot, npc.spot + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)))
		end
	elseif npc.mode == "Meet" then
		local partner = npc.partner
		local pp = partner and pelvisOf(partner)
		if not partner or not pp or partner.partner ~= npc or now >= npc.untilAt then
			endChat(npc, now)
		elseif arrived and stateOf(partner) == "Standing" and flat(pp.Position - here).Magnitude <= CHAT_NEAR then
			local talk = now + rng:NextNumber(CHAT_MIN, CHAT_MAX)
			-- 1 and 2: they take turns talking (DummyLife).
			for turn, n in { npc, partner } do
				n.mode = "Chat"
				n.untilAt = talk
				n.model:SetAttribute("Chatting", turn)
			end
		end
	elseif npc.mode == "Chat" then
		-- (Done when the time is up, or when the partner went off with someone else.)
		local partner = npc.partner
		if now >= npc.untilAt or not partner or partner.partner ~= npc then
			endChat(npc, now)
		end
	elseif npc.mode == "Greet" then
		local player = npc.greeting
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- (There, or near enough that it never set off: a body does not set off for a spot under 5
		-- studs away, so from up to GREET_STOP + 5.5 it waves from where it stands.)
		local close = root and root:IsA("BasePart") and state == "Standing" and flat(root.Position - here).Magnitude <= GREET_STOP + 5.5
		if (arrived or close) and root and root:IsA("BasePart") then
			-- There: it turns to them, waves and says hi, then lingers a moment.
			setGoal(npc, npc.spot, root.Position)
			model:SetAttribute("GreetUntil", Workspace:GetServerTimeNow() + GREET_TIME)
			npc.greeting = nil
			npc.mode = "Idle"
			npc.untilAt = now + GREET_TIME + rng:NextNumber(0.5, 1.5)
		else
			-- (Getting no closer -- steering round a bench or a stall, or the player keeps away:
			-- it gives up after GREET_STUCK and goes about its day.)
			local d = if root and root:IsA("BasePart") then flat(root.Position - here).Magnitude else math.huge
			if d < npc.greetBest - 1 then
				npc.greetBest = d
				npc.greetProgressAt = now
			end
			if now >= npc.untilAt or not root or now - npc.greetProgressAt > GREET_STUCK then
				npc.greeting = nil
				npc.mode = "Idle"
				npc.untilAt = now + rng:NextNumber(1, 3)
			end
		end
	elseif npc.mode == "Idle" and now < npc.untilAt then
		-- A sleepy one nods off when it has a while to stand about.
		if npc.personality == "Sleepy" and not plain and not npc.dozing and npc.untilAt - now > DOZE_AFTER then
			npc.dozing = true
			task.delay(DOZE_AFTER, function()
				if npc.dozing and npc.mode == "Idle" and model.Parent then
					model:SetAttribute("Dozing", true)
				end
			end)
		end
	elseif npc.mode == "Idle" and now >= npc.untilAt then
		if not plain and npc.personality ~= "Coward" and npc.personality ~= "Grumpy" and rng:NextNumber() < GREET_CHANCE and greet(npc, here, now) then
			return
		end
		if rng:NextNumber() < CHAT_CHANCE * traitsOf(npc).chat then
			for _, other in npcs do
				local op = pelvisOf(other)
				if other ~= npc and other.zone == npc.zone and free(other) and op and flat(op.Position - here).Magnitude < MEET_RANGE then
					meet(npc, other, now)
					return
				end
			end
		end
		stroll(npc, here, now)
	end
end

------------------------------------------------------------------------------------------------
-- Panic

local function panic(npc: Npc, from: Vector3, delay: number, hops: number?)
	local now = os.clock()
	if npc.panicPending or npc.panicUntil > now + 1 or not npc.model.Parent then
		return
	end
	if ((npc.model:GetAttribute("Seed") :: number?) or 0) >= 6 then
		return -- (only half run: ActiveRagdoll RUNNER_SEED)
	end
	local traits = traitsOf(npc)
	npc.panicPending = true
	task.delay(delay * traits.react, function()
		npc.panicPending = false
		local model = npc.model
		local pelvis = pelvisOf(npc)
		if deaf or not model.Parent or not pelvis then
			return
		end
		-- A clown still laughing at what it saw does not then run from the same thing.
		local laughing = model:GetAttribute("LaughUntil")
		if type(laughing) == "number" and laughing > Workspace:GetServerTimeNow() then
			return
		end
		local seconds = rng:NextNumber(PANIC_MIN, PANIC_MAX) * traits.panic
		local at = os.clock()
		wake(npc)
		npc.scaredBy = from
		local center = npc.zone.center
		npc.panicUntil = at + seconds
		npc.panicStarted = at
		if npc.mode == "Chat" or npc.mode == "Meet" then
			endChat(npc, at)
		end
		npc.mode = "Panic"
		-- Where it ends up: away from it, further out (never back towards the trouble).
		local away = flat(pelvis.Position - from)
		away = if away.Magnitude > 0.1 then away.Unit else Vector3.xAxis
		local escape = flat(pelvis.Position) + away * rng:NextNumber(18, 28)
		local offCentre = flat(escape - center)
		if offCentre.Magnitude > npc.zone.escape then
			escape = flat(center) + offCentre.Unit * npc.zone.escape
		end
		-- Only somewhere with floor under it (else it stays where it ends up running).
		if not onFloor(npc.zone, escape, rayParams()) then
			escape = flat(pelvis.Position)
		end
		setGoal(npc, escape, escape + away)
		model:SetAttribute("PanicFrom", from)
		model:SetAttribute("PanicUntil", Workspace:GetServerTimeNow() + seconds)
		-- A scream: the ones close by catch it a beat later (a few people on, no further).
		local hop = hops or 0
		if hop < SCREAM_HOPS then
			for _, other in npcs do
				local op = pelvisOf(other)
				if other ~= npc and op and (op.Position - pelvis.Position).Magnitude <= SCREAM_RANGE * traits.scream then
					panic(other, from, rng:NextNumber(SCREAM_MIN, SCREAM_MAX), hop + 1)
				end
			end
		end
	end)
end

-- What a moment sounds like, as how far it carries (0: nothing to hear).
function CrowdService.loudness(kind: string, speed: number, toyId: string): number
	local h = CrowdService.HEARING
	if kind == "Hit" then
		local blast = Blasts.KINDS[toyId]
		if blast then
			return blast.radius * h.blastScale
		elseif CANNONS[toyId] then
			return h.cannon
		elseif toyId == "Blaster" or (Toys.byId[toyId] and Toys.byId[toyId].gun) then
			return h.shot
		elseif toyId == "Heal" or toyId == "Balloon" or speed < 6 then
			return 0
		elseif speed >= 60 then
			return h.big
		end
		return h.hit
	elseif kind == "Break" or (kind == "Land" and speed >= 40) then
		return h.land
	elseif kind == "Shot" then
		return h.shot -- (a shot that hit nothing is still a bang)
	end
	return 0
end

local function onMoment(kind: string, position: Vector3, speed: number, toyId: string)
	if deaf then
		return
	end
	local radius = CrowdService.loudness(kind, speed, toyId)
	if radius <= 0 then
		return
	end
	for _, npc in npcs do
		local pelvis = pelvisOf(npc)
		if pelvis then
			local distance = (pelvis.Position - position).Magnitude
			-- (The one it happened to is busy flying, not panicking.)
			if distance <= radius * traitsOf(npc).hearing and distance > 4 then
				panic(npc, position, distance / SOUND_SPEED + rng:NextNumber(REACT_MIN, REACT_MAX))
			end
		end
	end
end

-- Sight: a body flying or lying out cold, in front, within range, with nothing in between.
local function look()
	local folder = Workspace:FindFirstChild("Dummies")
	if not folder then
		return
	end
	local alarming: { { model: Model, at: Vector3 } } = {}
	local bodies: { Instance } = folder:GetChildren()
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(bodies, player.Character) -- a player sent flying is just as alarming
		end
	end
	for _, model in bodies do
		local pelvis = model:FindFirstChild("LowerTorso")
		local state = model:GetAttribute("RagdollState")
		if pelvis and pelvis:IsA("BasePart") and (state == "Out" or ((state == "Ragdoll" or state == "Stumble") and pelvis.AssemblyLinearVelocity.Magnitude >= ALARMING_SPEED)) then
			table.insert(alarming, { model = model :: Model, at = pelvis.Position })
		end
	end
	if #alarming == 0 then
		return
	end
	local params: RaycastParams? = nil
	local noticed = 0
	for _, npc in npcs do
		local pelvis = pelvisOf(npc)
		if noticed >= SIGHT_PER_SCAN then
			break
		end
		if pelvis and npc.zone.active and npc.mode ~= "Panic" and not npc.panicPending and stateOf(npc) ~= "Ragdoll" then
			local eye = pelvis.Position + Vector3.new(0, 2.5, 0)
			local facing = flat(pelvis.CFrame.LookVector)
			for _, a in alarming do
				if a.model ~= npc.model then
					local to = a.at - eye
					local distance = to.Magnitude
					if distance <= SIGHT_RANGE and facing.Magnitude > 0.1 and flat(to).Unit:Dot(facing.Unit) >= SIGHT_CONE then
						params = params or rayParams()
						if not Workspace:Raycast(eye, to, params) then
							local laughing = (npc.model:GetAttribute("LaughUntil") :: number?) or 0
							if laughing > Workspace:GetServerTimeNow() then
								break -- still laughing at the last one
							elseif npc.personality == "Clown" and not plain and rng:NextNumber() < CrowdService.LAUGH_CHANCE then
								-- A clown thinks a body flying past is the funniest thing ever.
								npc.model:SetAttribute("LaughUntil", Workspace:GetServerTimeNow() + 2.5)
								setGoal(npc, pelvis.Position, a.at)
							else
								panic(npc, a.at, rng:NextNumber(REACT_MIN, REACT_MAX))
							end
							noticed += 1
							break
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------------------------------
-- Spawning

-- A free spot on a zone's floor (not inside a counter or under a table), or the middle.
local function floorSpot(zone: Zone, radius: number): Vector3
	local params = rayParams()
	for _ = 1, 12 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local spot = zone.center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius * math.sqrt(rng:NextNumber(0.05, 0.9))
		if onFloor(zone, spot, params) then
			-- Nothing standing there or hanging over it (a dummy is dropped onto the first thing below).
			-- (From 3 studs over the floor line up: a street or a sidewalk under the feet is the ground, not
			-- something in the way; at 1 up every city spot was refused and the crowd piled up, v4 A2.)
			local box = Workspace:GetPartBoundsInBox(CFrame.new(spot + Vector3.new(0, 12.5, 0)), Vector3.new(2.5, 19, 2.5))
			local blocked = false
			for _, p in box do
				if p.CanQuery and p.Anchored and p.Name ~= "Floor" then
					blocked = true
					break
				end
			end
			if not blocked then
				return spot
			end
		end
	end
	return zone.center
end

-- The personality this zone has fewest of (so every room has a mix), ties at random.
local function nextPersonality(zone: Zone): Personality
	local counts: { [Personality]: number } = {}
	for _, p in PERSONALITIES do
		counts[p] = 0
	end
	for _, other in npcs do
		if other.zone == zone then
			counts[other.personality] += 1
		end
	end
	local best: { Personality } = {}
	local least = math.huge
	for _, p in PERSONALITIES do
		if counts[p] < least then
			least = counts[p]
			best = { p }
		elseif counts[p] == least then
			table.insert(best, p)
		end
	end
	return pick(best)
end

local function spawnOne(zone: Zone, at: Vector3?): Npc
	local role = pick(zone.roles)
	local spot = at or floorSpot(zone, zone.radius)
	local model = DummyFactory.spawn(spot :: Vector3, (spot :: Vector3) + Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)))
	model.Name = "Person"
	dress(model, role)
	local used: { [string]: boolean } = {}
	for _, other in npcs do
		if other.zone == zone then
			used[other.name] = true
		end
	end
	local name = pick(NAMES)
	for _ = 1, 10 do
		if not used[name] then
			break
		end
		name = pick(NAMES)
	end
	local personality = nextPersonality(zone)
	model:SetAttribute("Crowd", true)
	model:SetAttribute("Role", role)
	model:SetAttribute("PersonName", name)
	model:SetAttribute("Personality", personality)
	model:SetAttribute("Zone", zone.id)
	local npc: Npc = {
		model = model,
		zone = zone,
		personality = personality,
		scaredBy = nil,
		dozing = false,
		role = role,
		name = name,
		mode = "Idle",
		untilAt = os.clock() + rng:NextNumber(0.5, LINGER_MAX),
		partner = nil,
		spot = spot :: Vector3,
		thinkAt = os.clock() + rng:NextNumber(0, THINK_EVERY),
		panicUntil = 0,
		panicPending = false,
		panicStarted = nil,
		healAt = nil,
		greetBest = math.huge,
		greetProgressAt = 0,
	}
	setGoal(npc, spot :: Vector3)
	table.insert(npcs, npc)
	byModel[model] = npc
	return npc
end

local function forget(npc: Npc)
	local index = table.find(npcs, npc)
	if index then
		table.remove(npcs, index)
	end
	byModel[npc.model] = nil
	if npc.partner and npc.partner.partner == npc then
		endChat(npc.partner, os.clock())
	end
end

local function anyoneNear(zone: Zone): boolean
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and (root.Position - zone.center).Magnitude <= ACTIVE_RANGE then
			return true
		end
	end
	return false
end

local function countIn(zone: Zone): number
	local n = 0
	for _, npc in npcs do
		if npc.zone == zone then
			n += 1
		end
	end
	return n
end

-- Brings a zone's people in a few per tick (a room does not fill in one heavy frame).
local SPAWN_PER_TICK = 3
local function populate(zone: Zone)
	zone.populated = true
	zone.emptySince = nil
	zone.filling = true
	local missing = zone.size - countIn(zone)
	for _ = 1, math.min(SPAWN_PER_TICK, missing) do
		spawnOne(zone)
	end
	if missing <= SPAWN_PER_TICK then
		zone.filling = false
	end
end

-- Everyone in a room nobody is in any more goes home (except the ones someone carries).
local function empty(zone: Zone)
	zone.populated = false
	for i = #npcs, 1, -1 do
		local npc = npcs[i]
		if npc.zone == zone and npc.model:GetAttribute("Held") ~= true then
			forget(npc)
			npc.model:Destroy()
		end
	end
end

local function makeZone(id: string, center: Vector3, radius: number, escape: number, lost: number, size: number, roles: { Role }, persistent: boolean): Zone
	local zone: Zone = {
		id = id,
		center = center,
		radius = radius,
		escape = escape,
		lost = lost,
		size = size,
		roles = roles,
		persistent = persistent,
		populated = false,
		emptySince = nil,
		active = false,
		filling = false,
	}
	table.insert(zones, zone)
	zoneById[id] = zone
	return zone
end

------------------------------------------------------------------------------------------------
-- Tests and API

-- The people in a zone (the plaza's when none is named).
-- v4 B4 (NpcCommand): walk one of the crowd to `spot`, facing `facing`; false if it is not ours.
function CrowdService.goTo(model: Model, spot: Vector3, facing: Vector3?): boolean
	for _, npc in npcs do
		if npc.model == model then
			setGoal(npc, spot, facing)
			return true
		end
	end
	return false
end

function CrowdService.people(zoneId: string?): { Model }
	local list = {}
	for _, npc in npcs do
		if npc.zone.id == (zoneId or "Plaza") then
			table.insert(list, npc.model)
		end
	end
	return list
end

function CrowdService.center(zoneId: string?): Vector3
	local zone = zoneById[zoneId or "Plaza"]
	return if zone then zone.center else Vector3.zero
end

-- Tests: id -> { populated, active, people } for every zone.
function CrowdService.zones(): { [string]: { populated: boolean, active: boolean, people: number } }
	local out = {}
	for _, zone in zones do
		out[zone.id] = { populated = zone.populated, active = zone.active, people = countIn(zone) }
	end
	return out
end

function CrowdService.personalityOf(model: Model): string?
	local npc = byModel[model]
	return npc and npc.personality
end

-- Tests: give someone a personality (the effects of each one checked on their own).
function CrowdService.setPersonalityForTest(model: Model, personality: Personality)
	local npc = byModel[model]
	if npc then
		npc.personality = personality
		model:SetAttribute("Personality", personality)
	end
end

-- Tests: personalities on (they are off while the crowd is held, so timings are everyone's).
function CrowdService.plainForTest(on: boolean)
	plain = on
end

-- Tests: what a person has in mind for the trouble it just ran from.
function CrowdService.scaredByForTest(model: Model): Vector3?
	local npc = byModel[model]
	return npc and npc.scaredBy
end

-- Tests: when a person last started to panic (os.clock), or nil.
function CrowdService.panickedAt(model: Model): number?
	local npc = byModel[model]
	return npc and npc.panicStarted
end

-- Tests: a person stops where it is and stands about for `seconds` (its usual linger, made sure).
-- Tests: keeps one person to itself (no chats, no greetings) while a check watches it.
function CrowdService.aloneForTest(model: Model, on: boolean)
	alone[model] = if on then true else nil
end

function CrowdService.idleForTest(model: Model, seconds: number)
	local npc = byModel[model]
	local pelvis = npc and pelvisOf(npc)
	if npc and pelvis then
		npc.mode = "Idle"
		npc.spot = pelvis.Position
		npc.untilAt = os.clock() + seconds
		npc.dozing = false
	end
end

function CrowdService.modeOf(model: Model): string?
	local npc = byModel[model]
	return npc and npc.mode
end

-- Tests: stops the crowd thinking (their plans) and, unless `noticing`, noticing anything; false
-- lets it carry on. Held, everyone reacts the same (no personality timings).
function CrowdService.holdForTest(on: boolean, noticing: boolean?)
	held = on
	deaf = on and not noticing
	plain = on
end

-- Tests: brings in extra people (the 20-at-once check) and takes them away again.
-- V6-2: the owner's admin menu sets how many people a zone has (+/- `delta`, at most `max`).
function CrowdService.adjust(zoneId: string, delta: number, max: number): number
	local zone = zoneById[zoneId]
	if not zone or not zone.populated then -- (an empty room drops strays at once)
		return -1
	end
	local list = CrowdService.people(zoneId)
	if delta > 0 then
		for _ = 1, math.min(delta, max - #list) do
			spawnOne(zone)
		end
	else
		local free = {}
		for _, m in list do
			if m:GetAttribute("Held") ~= true then -- (never one someone is holding)
				table.insert(free, m)
			end
		end
		list = free
		for i = 1, math.min(-delta, #list) do
			local model = list[#list - i + 1]
			local npc = byModel[model]
			if npc then
				forget(npc)
			end
			model:Destroy()
		end
	end
	return #CrowdService.people(zoneId)
end

function CrowdService.addForTest(count: number, zoneId: string?): { Model }
	local added = {}
	local zone = zoneById[zoneId or "Plaza"]
	for _ = 1, count do
		table.insert(added, spawnOne(zone).model)
	end
	return added
end

function CrowdService.removeForTest(models: { Model })
	for _, model in models do
		local npc = byModel[model]
		if npc then
			forget(npc)
		end
		model:Destroy()
	end
end

-- Tests: a person's next thought now (to step the brain without waiting).
function CrowdService.thinkForTest(model: Model)
	local npc = byModel[model]
	if npc then
		think(npc, os.clock())
	end
end

-- Tests: who a person is talking to (or walking up to), if anyone.
function CrowdService.partnerOfForTest(model: Model): Model?
	local npc = byModel[model]
	local partner = npc and npc.partner
	return partner and partner.model
end

-- Tests: sets two people talking (walks them up to each other).
function CrowdService.meetForTest(a: Model, b: Model)
	local na, nb = byModel[a], byModel[b]
	if na and nb then
		meet(na, nb, os.clock())
	end
end

-- Tests: a room's people sent home now (as if everyone left a while ago).
function CrowdService.emptyForTest(zoneId: string)
	local zone = zoneById[zoneId]
	if zone and not zone.persistent then
		empty(zone)
	end
end

function CrowdService.start(labOrigin: Vector3)
	-- (The hair loads meanwhile; the plaza's people get theirs when it is in.)
	loadHair(backfillHair)
	plaza = makeZone("Plaza", labOrigin + ZONE_OFFSET, ZONE_RADIUS, ESCAPE_RADIUS, LOST_DISTANCE, CrowdService.SIZE, { "Barista", "Office", "Tourist" }, true)
	for _, place in Places.list do
		local centre = Places.floorCenter(labOrigin, place.id)
		-- (An open-air map stands on measured terrain: its built Floor's top is the real floor line, v4 A2;
		-- the planned one was a few studs off and every spot on the farm and the base was refused.)
		local places = Workspace:FindFirstChild("Places")
		local built = places and places:FindFirstChild(place.id)
		local floorPart = built and built:FindFirstChild("Floor")
		if centre and floorPart and floorPart:IsA("BasePart") then
			centre = Vector3.new(centre.X, floorPart.Position.Y + floorPart.Size.Y / 2, centre.Z)
		end
		if centre then
			local half = math.min(place.size.X, place.size.Z) / 2
			local roles: { Role } = {}
			for _, role in place.roles do
				table.insert(roles, (role :: any) :: Role)
			end
			makeZone(place.id, centre, half - 10, half - 5, math.max(place.size.X, place.size.Z) / 2 + 30, place.crowd, roles, false)
		end
	end
	-- (23 Nov 2026: in singleplayer the plaza fills when someone comes near, and empties again: no people built at the join.)
	local cfg = require(game:GetService("ReplicatedStorage").Shared.Config) :: any
	local solo = cfg.MULTI_PLACE ~= 0 and game.PlaceId == cfg.START_PLACE
	if solo then
		(plaza :: Zone).persistent = false
	end
	while not solo and ((plaza :: Zone).filling or not (plaza :: Zone).populated) do
		populate(plaza :: Zone)
	end
	FxService.onMoment(onMoment)

	local turn = 0
	local lookAt = 0
	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 1 / THINK_HZ then
			return
		end
		accumulated = 0
		local now = os.clock()
		-- Rooms come to life when someone is near and go quiet a while after the last one left.
		for _, zone in zones do
			zone.active = anyoneNear(zone)
			if zone.active then
				zone.emptySince = nil
				if not zone.populated or zone.filling then
					populate(zone)
				end
			elseif zone.populated and not zone.persistent then
				zone.emptySince = zone.emptySince or now
				if now - (zone.emptySince :: number) >= EMPTY_AFTER then
					empty(zone)
				end
			end
		end
		-- Lost people (fell off, shattered, flung far): a new one walks in after a while.
		for i = #npcs, 1, -1 do
			local npc = npcs[i]
			local zone = npc.zone
			local pelvis = pelvisOf(npc)
			-- (Not while someone carries them off: a grabbed person is theirs until let go.)
			local carried = npc.model:GetAttribute("Held") == true
			-- (Someone carried off while their room emptied goes home once let go.)
			local strayed = not carried and not zone.populated
			if strayed or not npc.model.Parent or not pelvis or pelvis.Position.Y < zone.center.Y - 40 or (not carried and flat(pelvis.Position - zone.center).Magnitude > zone.lost) then
				log.info(string.format("%s lost from %s (%s)", npc.name, zone.id, if not npc.model.Parent then "removed" elseif not pelvis then "no pelvis" else string.format("at %.0f, %.0f, %.0f", pelvis.Position.X - zone.center.X, pelvis.Position.Y - zone.center.Y, pelvis.Position.Z - zone.center.Z)))
				forget(npc)
				if npc.model.Parent then
					npc.model:Destroy()
				end
				task.delay(RESPAWN_AFTER, function()
					if zone.populated and countIn(zone) < zone.size then
						local angle = rng:NextNumber(0, math.pi * 2)
						local edge = zone.center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * zone.radius
						spawnOne(zone, if onFloor(zone, edge, rayParams()) then edge else nil)
					end
				end)
			end
		end
		if now >= lookAt and not deaf then
			lookAt = now + SIGHT_SCAN
			look()
		end
		if held then
			return
		end
		-- Each person in a room someone is near thinks every THINK_EVERY s, spread over the ticks.
		local count = #npcs
		if count == 0 then
			return
		end
		local per = math.max(1, math.ceil(count / (THINK_HZ * THINK_EVERY)))
		for _ = 1, math.min(per, count) do
			turn = turn % count + 1
			local npc = npcs[turn]
			if npc and npc.zone.active and now >= npc.thinkAt then
				-- (One tick early: the turns come round every THINK_EVERY s, give or take a tick.)
				npc.thinkAt = now + THINK_EVERY - 1 / THINK_HZ
				think(npc, now)
			end
		end
	end)
	log.info(string.format("%d people on the plaza, %d rooms waiting", #npcs, #zones - 1))
end

return CrowdService
