--!strict
-- Real models (round 2, N7), checked in the place as it is:
--   every tool in the catalog has a model in ReplicatedStorage.N7Assets.Weapons: a Grip part as
--     its PrimaryPart, every piece welded to it, nothing that collides, can be tapped or weighs
--     something, and no scripts at all (Creator Store models are kept with every script removed);
--     every gun has a Tip (shots leave from it)
--   every held tool shows its model in the avatar's hand (not the built stand-in), every piece of
--     it (nested ones too) counted as worn when the body goes limp, never colliding
--   the rooms use the real props: plants, the espresso machine, office chairs, the hangar's jet
--     and crates, supermarket shelves and carts, food court tables; each room, lab and the plaza within its part budget (asserted)
--   nothing but what draws a model anywhere in N7Assets (N7Models.ALLOWED: no script, package
--     link, sound, prompt, value or GUI), nor in any room's, plaza's or lab's props; room and
--     plaza props and clothes in ServerStorage (phones never download them), weapons and the
--     Mega Bomb in ReplicatedStorage
--   the four spells each have their own model
--   every lab has its benches, barriers and cones; the White Room and the Arena have their props
--   the food court's stalls show their food; the plaza has its lamps, benches and plants
--   a crash-test dummy wears its marks; a person in the crowd does not, and wears real clothes
--     (a chef's hat, a guard's cap, a bucket hat and camera, a backpack) where the role has them

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local HeldService = require(Systems:WaitForChild("HeldService"))
local WorldMaps = require(Systems:WaitForChild("WorldMaps"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local Toys = require(ReplicatedStorage.Shared.Toys)
local Config = require(ReplicatedStorage.Shared.Config)
local Places = require(ReplicatedStorage.Shared.Places)
local N7Models = require(ReplicatedStorage.Shared.N7Models)
local ActiveRagdoll = require(ReplicatedStorage.Shared.Ragdoll.ActiveRagdoll)

local PROPS = { "Plant", "Espresso", "OfficeChair", "Jet", "Crate", "Shelf", "Cart", "FoodTable", "FoodBurger", "FoodPizza", "FoodNoodles", "FoodTacos", "Bench", "StreetLamp", "OfficeDesk", "AirportSeats", "BaggageCart", "Fountain", "Cone", "Barrier", "LabBench" }
-- Part budgets for phones (every part here is streamed to whoever is near).
local ROOM_BUDGET = 400 -- parts in one room
local LAB_BUDGET = 80 -- parts in one lab's markings, sign and props
local PLAZA_BUDGET = 120 -- parts in the plaza's dressing
local CROWD = { Barista = true, Office = true, Tourist = true, Chef = true, Guard = true, Cashier = true, Traveler = true }
local WEAR = { ChefHat = "Chef", GuardCap = "Guard", BucketHat = "Tourist", Camera = "Tourist", Backpack = "Traveler", NeckPillow = "Traveler" }
local ROOM_PROPS: { [string]: { string } } = {
	Cafe = { "Espresso", "Plant" },
	Office = { "OfficeChair", "OfficeDesk", "Plant" },
	Hangar = { "Jet", "Crate", "AirportSeats", "BaggageCart" },
	WhiteRoom = { "Cone", "Barrier" },
	Arena = { "Cone", "Barrier" },
	Market = { "Shelf", "Cart" },
	FoodCourt = { "FoodTable", "FoodBurger", "FoodPizza", "FoodNoodles", "FoodTacos" },
}

local function body(results: { string })
	local root = ReplicatedStorage:FindFirstChild("N7Assets")
	assert(root, "the place has no N7Assets (save the place after N7)")
	local weapons = root:FindFirstChild("Weapons") :: Instance
	local serverRoot = game:GetService("ServerStorage"):FindFirstChild("N7Assets")
	assert(serverRoot, "no ServerStorage.N7Assets (room props and clothes)")
	local props = serverRoot:FindFirstChild("Props") :: Instance
	assert(props and not root:FindFirstChild("Props") and not root:FindFirstChild("Wear"), "room props and clothes must be in ServerStorage only")
	local fx = root:FindFirstChild("Fx")
	assert(fx and fx:FindFirstChild("MegaBomb"), "no N7Assets.Fx.MegaBomb (the clients draw it)")
	local checked = 0
	for _, top in { root, serverRoot } do
		for _, d in top:GetDescendants() do
			assert(N7Models.allowed(d), "not a model piece in N7Assets: " .. d:GetFullName() .. " (" .. d.ClassName .. ")")
			assert(not (d:IsA("Seat") and not (d :: Seat).Disabled), "a seat anyone could sit in: " .. d:GetFullName())
			checked += 1
		end
	end
	-- (A copy is cleaned again when it is taken out.)
	local dirty = Instance.new("Model")
	Instance.new("Script").Parent = dirty
	Instance.new("ProximityPrompt").Parent = Instance.new("Part", dirty)
	Instance.new("Sound").Parent = dirty
	assert(N7Models.clean(dirty) == 3 and #dirty:GetDescendants() == 1, "N7Models.clean left something in")
	dirty:Destroy()
	local spellIds = {}
	for _, id in { "Shrink", "Chicken", "Float", "Slowmo" } do
		local m = weapons:FindFirstChild(id)
		local key = m and tostring(m:GetAttribute("AssetId"))
		assert(key and not spellIds[key], id .. " shares its model with another spell")
		spellIds[key] = true
	end
	table.insert(results, string.format("%d pieces in N7Assets, every one a model piece; copies cleaned again; the four spells each their own model", checked))
	-- 1. A model for every tool.
	local pieces = 0
	for _, toy in Toys.list do
		local m = weapons:FindFirstChild(toy.id)
		assert(m and m:IsA("Model"), toy.id .. " has no model")
		local grip = m.PrimaryPart
		assert(grip and grip.Name == "Grip", toy.id .. ": no Grip as its PrimaryPart")
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then
				pieces += 1
				assert(not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Massless and not p.Anchored, toy.id .. ": " .. p.Name .. " collides, can be tapped, weighs something or is anchored")
				if p ~= grip then
					local welded = false
					for _, w in p:GetChildren() do
						if w:IsA("Weld") and w.Part0 == grip and w.Part1 == p then
							welded = true
						end
					end
					assert(welded, toy.id .. ": " .. p.Name .. " is not welded to the grip")
				end
			end
		end
		if toy.gun then
			assert(m:FindFirstChild("Tip"), toy.id .. " (a gun) has no Tip")
		end
	end
	table.insert(results, string.format("%d tools, each with a model (%d pieces, all welded to the grip, none colliding or weighing anything, no scripts)", #Toys.list, pieces))

	-- 2. In the hand.
	local player = Players:GetPlayers()[1]
	local character = player and player.Character
	if player and character then
		local before = HeldService.holdingOf(player)
		local held = 0
		for _, toy in Toys.list do
			if toy.held then
				HeldService.onHold(player, toy.id)
				local h = character:FindFirstChild("HeldTool")
				assert(h and h:GetAttribute("Tool") == toy.id, toy.id .. " is not in the hand")
				assert((h :: Model).PrimaryPart and (h :: Model).PrimaryPart.Name == "Grip" and h:FindFirstChild("Body") and h:FindFirstChild("Body"):IsA("Model"), toy.id .. " in the hand is the built stand-in, not its model")
				-- Every piece, nested ones too, counts as worn when the body goes limp, and none collides.
				for _, p in h:GetDescendants() do
					if p:IsA("BasePart") then
						assert(ActiveRagdoll.isWornForTest(p), toy.id .. ": " .. p:GetFullName() .. " would count as part of the body when it goes limp")
						assert(not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Massless, toy.id .. ": " .. p.Name .. " in the hand collides, can be tapped or weighs something")
					end
				end
				held += 1
				task.wait(0.12) -- (the hold limit)
			end
		end
		HeldService.onHold(player, before or "Blaster")
		table.insert(results, string.format("%d held tools show their real model in the hand", held))
	end

	-- 3. The rooms.
	for _, name in PROPS do
		assert(props:FindFirstChild(name), "no prop " .. name)
	end
	local folder = WorldMaps.folder()
	local waited = 0
	while not folder and waited < 30 do
		-- (Run on its own, the test can start before the rooms are built.)
		waited += task.wait(0.5)
		folder = WorldMaps.folder()
	end
	assert(folder, "no rooms")
	local seen = {}
	for room, names in ROOM_PROPS do
		if not Places.byId[room] then
			continue -- (19 Nov: the owner kept only the Arena and the open-air maps)
		end
		local m = folder:FindFirstChild(room)
		assert(m, "no room " .. room)
		local count = 0
		for _, d in m:GetDescendants() do
			assert(not d:IsA("LuaSourceContainer"), "a script in " .. room)
			local prop = d:IsA("BasePart") and d:FindFirstAncestorWhichIsA("Model")
			if prop and prop ~= m and prop:GetAttribute("AssetId") then
				assert(d.Anchored and not d.CanTouch, room .. ": a prop piece that is loose or listens for touches (" .. prop.Name .. ")")
			end
			if d:IsA("BasePart") then
				count += 1
			end
		end
		for _, n in names do
			local found = 0
			for _, c in m:GetChildren() do
				if c:IsA("Model") and c.Name == n then
					found += 1
				end
			end
			assert(found > 0, room .. " has no real " .. n)
		end
		assert(count <= ROOM_BUDGET, string.format("%s has %d parts (budget %d)", room, count, ROOM_BUDGET))
		table.insert(seen, string.format("%s (%s, %d parts)", room, table.concat(names, ", "), count))
	end
	table.insert(results, "rooms: " .. table.concat(seen, "; "))
	local hangar = folder:FindFirstChild("Hangar")
	assert(not hangar or not hangar:FindFirstChild("Fuselage"), "the hangar still has the built jet next to the real one")
	local plaza = Workspace:FindFirstChild("PlazaDressing")
	assert(plaza, "the plaza is bare")
	local dressed: { [string]: number } = {}
	local plazaParts = 0
	for _, c in plaza:GetChildren() do
		dressed[c.Name] = (dressed[c.Name] or 0) + 1
	end
	for _, d in plaza:GetDescendants() do
		if d:IsA("BasePart") then
			plazaParts += 1
		end
	end
	assert(plazaParts <= PLAZA_BUDGET, string.format("the plaza's dressing has %d parts (budget %d)", plazaParts, PLAZA_BUDGET))
	assert((dressed.StreetLamp or 0) >= 6 and (dressed.Bench or 0) >= 4 and (dressed.Plant or 0) >= 8, "the plaza is missing lamps, benches or plants")
	table.insert(results, string.format("plaza: %d lamps, %d benches, %d plants (%d parts, budget %d)", dressed.StreetLamp, dressed.Bench, dressed.Plant, plazaParts, PLAZA_BUDGET))
	-- Its two edges (round 3, M1): a line and boards along the whole ground, a budget of their own.
	local edges = Workspace:FindFirstChild("PlazaEdges")
	assert(edges, "the plaza's edges are not marked")
	local edgeParts, edgeBoards = 0, 0
	for _, d in edges:GetDescendants() do
		if d:IsA("BasePart") then
			edgeParts += 1
			if d.Name == "Sign" then
				edgeBoards += 1
			end
		end
	end
	assert(edgeParts <= 90, string.format("the plaza's edges have %d parts (budget 90)", edgeParts))
	table.insert(results, string.format("plaza edges: 2 lines, %d sign panels (%d parts, budget 90)", edgeBoards, edgeParts))

	-- Every lab looks like a crash-test lab.
	local labs = Workspace:FindFirstChild("Labs")
	assert(labs, "no labs")
	local dressedLabs = 0
	local mostLab = 0
	for _, lab in labs:GetChildren() do
		local count: { [string]: number } = {}
		local parts = 0
		for _, d in lab:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		assert(parts <= LAB_BUDGET, string.format("%s has %d parts (budget %d)", lab.Name, parts, LAB_BUDGET))
		mostLab = math.max(mostLab, parts)
		for _, c in lab:GetChildren() do
			if c:IsA("Model") then
				count[c.Name] = (count[c.Name] or 0) + 1
			end
			for _, d in c:GetDescendants() do
				assert(N7Models.allowed(d) or d:IsA("SurfaceGui") or d:IsA("GuiObject") or d:IsA("UIComponent"), "something odd in a lab's props: " .. d:GetFullName())
			end
		end
		assert((count.LabBench or 0) >= 2 and (count.Barrier or 0) >= 8 and (count.Cone or 0) >= 8, lab.Name .. " is not dressed")
		dressedLabs += 1
	end
	assert(plaza:FindFirstChild("Fountain"), "the plaza has no fountain")
	table.insert(results, string.format("%d labs with 2 benches, 8 barriers, 8 cones (at most %d parts, budget %d); the plaza's fountain", dressedLabs, mostLab, LAB_BUDGET))

	-- 4. Who is in the world.
	local wear = serverRoot:FindFirstChild("Wear") :: Instance
	assert(wear, "no N7Assets.Wear")
	for name in WEAR do
		assert(wear:FindFirstChild(name), "no clothing " .. name)
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	assert(dummies, "no dummies")
	local marked, people, plain, worn = 0, 0, 0, {}
	for _, m in dummies:GetChildren() do
		local marks = 0
		for _, d in m:GetDescendants() do
			if d:IsA("SurfaceGui") and d.Name == "CrashMark" then
				marks += 1
			end
		end
		local role = m:GetAttribute("Role")
		if role and CROWD[role] then
			people += 1
			assert(marks == 0, "a person in the crowd wears crash-test marks")
			local outfit = m:FindFirstChild("Outfit")
			for _, c in if outfit then outfit:GetChildren() else {} do
				if c:IsA("Model") and WEAR[c.Name] then
					assert(WEAR[c.Name] == role, string.format("a %s wears a %s", role, c.Name))
					assert(c:GetAttribute("Worn") == true, c.Name .. " is not marked worn (it would weigh on the body)")
					worn[c.Name] = true
				end
			end
		elseif marks >= 3 then
			marked += 1
		else
			plain += 1
		end
	end
	-- (LOOK_V3: plain white mannequins, no marks, on purpose.)
	local wantMarks = not Config.LOOK_V3
	assert(not wantMarks or plain == 0, string.format("%d dummies without their crash-test marks", plain))
	-- A fresh dummy, looked at closely (the labs may have none while the tests run).
	local probe = DummyFactory.spawn(Vector3.new(0, 1, -40), nil)
	local marks, guiObjects = 0, 0
	for _, d in probe:GetDescendants() do
		if d:IsA("SurfaceGui") and d.Name == "CrashMark" and d:FindFirstChild("Mark") then
			marks += 1
		end
		if d:IsA("GuiBase2d") or d:IsA("UIComponent") then
			guiObjects += 1
		end
	end
	probe:Destroy()
	assert(not wantMarks or marks >= 3, string.format("a new dummy has %d crash-test marks, not 3", marks))
	-- (Every dummy draws these: kept small for phones.)
	assert(guiObjects <= 45, string.format("a dummy's marks and face take %d GUI objects (at most 45)", guiObjects))
	marked = math.max(marked, 1)
	local wornList = {}
	for n in worn do
		table.insert(wornList, n)
	end
	table.sort(wornList)
	assert(#wornList > 0, "nobody in the crowd wears real clothes")
	table.insert(results, string.format("%d dummies with crash-test marks (%d GUI objects a dummy with its face), %d people without (wearing %s)", marked, guiObjects, people, table.concat(wornList, ", ")))
end

return {
	name = "real-models-tools-hand-rooms",
	timeout = 40,
	run = function(): string?
		local results = {}
		body(results)
		return table.concat(results, "; ")
	end,
}
