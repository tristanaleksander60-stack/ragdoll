--!strict
-- Fights that feel real (phase C), on the server side:
--   a dummy sent flying is unhurt in the air and hurt by the landing (out cold after a huge hit)
--   a gentle shove hurts nothing, landing included
--   the smackers sit in the avatar's fist on a fixed grip; the Blaster shoots as fast as you click
--   (ten a second through the real handler, none refused)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local HitService = require(Systems:WaitForChild("HitService"))
local HeldService = require(Systems:WaitForChild("HeldService"))
local OnboardingService = require(Systems:WaitForChild("OnboardingService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

local ORIGIN = Vector3.new(1000, 0, 640) -- open baseplate, by the other tests, away from the lab

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

local function labDummy(at: Vector3): Model
	local model = DummyFactory.spawn(at, at + Vector3.zAxis)
	task.wait(0.4)
	-- Knock-outs are for dummies that live in the lab (they have a home to wake up and walk to).
	local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
	model:SetAttribute("Home", pelvis.Position)
	model:SetAttribute("HomeLook", pelvis.Position + Vector3.zAxis)
	return model
end

return {
	name = "combat-hurt-on-landing-held-rapid-fire",
	timeout = 90,
	run = function(): string?
		local results = {}

		-- 1. A huge hit straight up: no harm in the air, out cold when it comes down.
		local model = labDummy(ORIGIN)
		local chest = model:FindFirstChild("UpperTorso") :: BasePart
		local mass = (model:GetAttribute("Mass") :: number?) or 10
		DummyControl.hit(model, chest, Vector3.new(0, 110, 0) * mass, chest.Position)
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
		-- Unhurt all the way up (checked every frame until it starts to fall).
		task.wait(0.1)
		while pelvis.AssemblyLinearVelocity.Y > 0 do
			local midair = model:GetAttribute("RagdollState")
			local brokenMidair = (model:GetAttribute("Broken") :: number?) or 0
			assert(midair ~= "Out" and brokenMidair == 0, string.format("hurt in the air (%s, %d broken)", tostring(midair), brokenMidair))
			task.wait()
		end
		local peak = pelvis.Position.Y
		local landedOut = waitFor(function()
			peak = math.max(peak, pelvis.Position.Y)
			return model:GetAttribute("RagdollState") == "Out"
		end, 6)
		assert(landedOut, "the landing after a huge hit did not knock it out (" .. tostring(model:GetAttribute("RagdollState")) .. ")")
		table.insert(results, string.format("flew %.0f studs up unhurt, out cold on landing", peak - ORIGIN.Y))
		model:Destroy()

		-- 1b. A knock to the head that sends it flying (out cold, but only once it lands): the knock is
		-- carried to the landing, which by itself is far too soft to knock anything out.
		local knocked = labDummy(ORIGIN + Vector3.new(0, 0, 30))
		local head = knocked:FindFirstChild("Head") :: BasePart
		local kMass = (knocked:GetAttribute("Mass") :: number?) or 10
		DummyControl.hit(knocked, head, Vector3.new(45, 6, 0) * kMass, head.Position)
		task.wait(0.15)
		assert(knocked:GetAttribute("RagdollState") ~= "Out", "the head knock put it out cold in the air")
		assert(waitFor(function()
			return knocked:GetAttribute("RagdollState") == "Out"
		end, 6), "a head knock that sent it flying never put it out cold on landing")
		table.insert(results, "head knock: out cold when it lands, not before")
		knocked:Destroy()

		-- 1c. A heavy blow that cannot send it anywhere (a hammer straight down on a dummy lying on
		-- the floor) hurts at once.
		local lying = labDummy(ORIGIN + Vector3.new(0, 0, 60))
		local lChest = lying:FindFirstChild("UpperTorso") :: BasePart
		local lMass = (lying:GetAttribute("Mass") :: number?) or 10
		DummyControl.hit(lying, lChest, Vector3.new(34, 0, 0) * lMass, lChest.Position) -- knocked down
		local lPelvis = lying:FindFirstChild("LowerTorso") :: BasePart
		assert(waitFor(function()
			return lPelvis.AssemblyLinearVelocity.Magnitude < 3 and lying:GetAttribute("RagdollState") == "Ragdoll"
		end, 4), "the dummy did not lie still to be hammered")
		local arm = lying:FindFirstChild("RightUpperArm") :: BasePart
		HitService.applyToy(Toys.byId.Hammer, arm, arm.Position, Vector3.new(0, -1, 0))
		assert(waitFor(function()
			return ((lying:GetAttribute("Broken") :: number?) or 0) >= 1
		end, 0.5), "a hammer straight down on a dummy lying still broke nothing at once")
		table.insert(results, "hammer on a lying dummy breaks at once")
		lying:Destroy()

		-- 1d. Everyday blows by hand knock them about but break nothing, landing included (breaks are
		-- for big launches, falls and heavy smackers).
		for i, id in { "Punch", "Kick", "Uppercut" } do
			local d = labDummy(ORIGIN + Vector3.new(60, 0, 30 * i))
			local c = d:FindFirstChild("UpperTorso") :: BasePart
			HitService.applyToy(Toys.byId[id], c, c.Position, Vector3.xAxis)
			task.wait(2.5)
			assert(((d:GetAttribute("Broken") :: number?) or 0) == 0, id .. " broke a limb (on landing)")
			d:Destroy()
		end
		table.insert(results, "punch, kick, uppercut: nothing broken")

		-- 2. A shove: down, but nothing broken and not out cold, landing included.
		local soft = labDummy(ORIGIN + Vector3.new(30, 0, 0))
		local softChest = soft:FindFirstChild("UpperTorso") :: BasePart
		HitService.applyToy(Toys.byId.Shove, softChest, softChest.Position, Vector3.xAxis)
		task.wait(2.5)
		assert(((soft:GetAttribute("Broken") :: number?) or 0) == 0, "a shove broke something")
		assert(soft:GetAttribute("RagdollState") ~= "Out", "a shove knocked it out")
		table.insert(results, "a shove hurts nothing")
		soft:Destroy()

		-- 3 and 4 need a player (an avatar to hold things, a reach to shoot from).
		local player = Players:GetPlayers()[1]
		local character = player and player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not player or not character or not root or not root:IsA("BasePart") then
			table.insert(results, "held/rapid fire skipped (no player)")
			return table.concat(results, "; ")
		end

		-- 3. The smackers in the fist, each on a fixed grip (a Weld, not a pose frozen at pick time).
		local before = HeldService.holdingOf(player)
		for _, id in { "Bat", "Pan", "Hammer", "Golf" } do
			assert(Toys.byId[id].held, id .. " is not a held tool")
			HeldService.onHold(player, id)
			local held = character:FindFirstChild("HeldTool")
			assert(held and held:GetAttribute("Tool") == id, id .. " is not in the hand")
			local grip = (held :: Model).PrimaryPart :: BasePart
			local hand = character:FindFirstChild("RightHand")
			local inHand = false
			for _, w in grip:GetChildren() do
				if w:IsA("Weld") and w.Part0 == hand then
					inHand = true
				end
			end
			assert(inHand, id .. " is not welded to the hand on a fixed grip")
			-- Every piece stays where it was built on the tool (not knocked off by the hand weld).
			local asset = HeldService.assetFor(id)
			if asset then
				-- A real model (N7): every piece where it is in the kept model, relative to the grip.
				-- (The clone keeps the order of its pieces: the n-th piece of each is the same one.)
				local keptGrip = asset.PrimaryPart :: BasePart
				local function pieces(m: Instance): { BasePart }
					local list = {}
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") then
							table.insert(list, d)
						end
					end
					return list
				end
				local kept, got = pieces(asset), pieces(held :: Model)
				assert(#kept == #got, id .. " lost pieces in the hand")
				for i, piece in got do
					local want = keptGrip.CFrame:PointToObjectSpace(kept[i].Position)
					local now = grip.CFrame:PointToObjectSpace(piece.Position)
					assert((want - now).Magnitude < 0.1, string.format("%s: %s came off the grip (%.2f studs)", id, piece.Name, (want - now).Magnitude))
				end
			else
				local body = (held :: Model):FindFirstChild("Body") :: BasePart
				local striker = (held :: Model):FindFirstChild("Striker") :: BasePart
				local along = body.CFrame:PointToObjectSpace(striker.Position)
				assert(math.abs(along.X) < 0.05 and math.abs(along.Y) < 0.05 and along.Z < 0, id .. "'s striking end came off its handle")
			end
			task.wait(0.15) -- the hold limit (10/s)
		end
		HeldService.onHold(player, before or "Blaster")
		table.insert(results, "bat, pan, hammer, golf club held on a fixed grip, every piece in place")

		-- 4. The Blaster: ten shots a second, none refused.
		OnboardingService.finishForTest(player)
		local target = DummyFactory.spawn(root.Position + Vector3.new(0, 0, 25), root.Position)
		task.wait(0.5)
		local torso = target:FindFirstChild("UpperTorso") :: BasePart
		assert(Toys.byId.Blaster.cooldown <= 0.1, "the Blaster cannot shoot ten a second")
		task.wait(1.1) -- a fresh second for the 12-a-second limit
		-- Counted by what went through (a cooldown refusal is silent, so "nothing refused" proves
		-- nothing): every shot must be used.
		local used = 0
		local why: { string } = {} -- (for a refused shot: the server's reason and where the target was)
		for _ = 1, 10 do
			local before = HitService.lastUseOf(player, "Blaster")
			HitService.lastRefusal[player] = nil
			HitService.onRequest(player, torso, torso.Position, (torso.Position - root.Position).Unit, "Blaster")
			if HitService.lastUseOf(player, "Blaster") ~= before then
				used += 1
			else
				local r = HitService.lastRefusal[player]
				local here = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				table.insert(why, string.format("%s at %.0f studs, %s", if r then r.reason else "no reason (silent: cooldown, burst or no hit)", if here then (here.Position - torso.Position).Magnitude else -1, tostring(target:GetAttribute("RagdollState"))))
			end
			task.wait(0.1)
		end
		assert(used == 10, string.format("rapid Blaster fire: only %d of 10 shots went through (%s)", used, table.concat(why, "; ")))
		table.insert(results, "Blaster 10 shots/s, all 10 went through")
		-- A flurry of blows by hand, at the pace the client lands them (its cooldown runs from each
		-- landing): every one is taken.
		local blows = 0
		for _, id in { "Poke", "Punch", "Bat" } do
			local toy = Toys.byId[id]
			for _ = 1, 4 do
				local before = HitService.lastUseOf(player, id)
				HitService.onRequest(player, torso, torso.Position, (torso.Position - root.Position).Unit, id, true)
				if HitService.lastUseOf(player, id) ~= before then
					blows += 1
				end
				task.wait(toy.cooldown + 0.02)
			end
		end
		target:Destroy()
		assert(blows == 12, string.format("a flurry at the client's pace: only %d of 12 blows were taken", blows))
		table.insert(results, "flurries of poke, punch, bat at the client's pace: all 12 taken")
		return table.concat(results, "; ")
	end,
}
