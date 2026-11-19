--!strict
-- Living dummies 2 (phase 3b), on a lab dummy the player's client simulates:
--   knocked away, it walks home by itself (no teleport) and turns to face the lab again
--   one broken leg: it limps home, slower
--   both legs broken: it crawls
--   a hard knock to the head: out cold for a few seconds before it gets up
--   hurt, then someone walks up to it: it runs away from them
--   resting at home hurt: it is patched up (by the lab, after a while)
--   a reset forgets it was hurt (no running from people afterwards)
--   frozen mid-walk: the ice statue stops where it is; a rewind thaws it
--   knocked further off on its way home: it still walks back, no teleport
-- Needs a player in the session.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local DummyControl = require(Systems:WaitForChild("DummyControl"))
local HitService = require(Systems:WaitForChild("HitService"))
local Toys = require(ReplicatedStorage.Shared.Toys)

local function slotDummy(slot: number): Model?
	local folder = Workspace:FindFirstChild("Dummies")
	if folder then
		for _, model in folder:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("Slot") == slot then
				return model
			end
		end
	end
	return nil
end

local function waitFor(check: () -> boolean, timeout: number): boolean
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if check() then
			return true
		end
		task.wait(0.1)
	end
	return check()
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

return {
	name = "dummies-walk-limp-crawl-faint-flee",
	timeout = 300,
	run = function(): string?
		local waited = os.clock()
		while (#Players:GetPlayers() == 0 or not Players:GetPlayers()[1].Character) and os.clock() - waited < 15 do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		assert(player and player.Character, "needs a player in the session")
		local model = slotDummy(4)
		assert(model, "no dummy in slot 4")
		assert(waitFor(function()
			return model:GetAttribute("SimulatedBy") == player.UserId and model:GetAttribute("RagdollState") == "Standing"
		end, 10), "the dummy is not standing on the player's client")
		local home = model:GetAttribute("Home") :: Vector3
		local look = model:GetAttribute("HomeLook") :: Vector3
		assert(typeof(home) == "Vector3" and typeof(look) == "Vector3", "the dummy has no Home")
		local pelvis = model:FindFirstChild("LowerTorso") :: BasePart
		-- Keep the tester's avatar out of the way (and out of fleeing range).
		local character = player.Character :: Model
		character:PivotTo(CFrame.new(home + Vector3.new(0, 3, 60)))
		local results = {}

		-- 1. Away from home: it walks back, smoothly, and faces the lab again.
		local away = home + Vector3.new(14, 0, 8)
		DummyControl.reset(model, CFrame.lookAt(away, away + Vector3.zAxis))
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Walking"
		end, 4), "it never set off home")
		-- (The reset is a teleport by the server: the client simulating it takes it over within a
		-- few frames, and a stale report can land in that gap. The walk is judged from then on.)
		task.wait(0.3)
		local last = pelvis.Position
		local biggestJump = 0
		local t0 = os.clock()
		local arrived = waitFor(function()
			local now = pelvis.Position
			biggestJump = math.max(biggestJump, flatDistance(now, last))
			last = now
			return model:GetAttribute("RagdollState") == "Standing" and flatDistance(pelvis.Position, home) < 2.5
		end, 14)
		assert(arrived, string.format("it did not walk home (%.1f studs left, state %s)", flatDistance(pelvis.Position, home), tostring(model:GetAttribute("RagdollState"))))
		local walkTime = os.clock() - t0
		assert(biggestJump < 3, string.format("it jumped %.1f studs in a tenth of a second (teleported?)", biggestJump))
		-- (It turns round once it has stopped: a moment to finish the turn.)
		local facingDot = -1
		assert(waitFor(function()
			local toLab = Vector3.new(look.X - pelvis.Position.X, 0, look.Z - pelvis.Position.Z).Unit
			local facing = Vector3.new(pelvis.CFrame.LookVector.X, 0, pelvis.CFrame.LookVector.Z).Unit
			facingDot = facing:Dot(toLab)
			return facingDot > 0.8
		end, 2), string.format("it does not face the lab after walking home (%.2f)", facingDot))
		assert(math.abs(pelvis.CFrame.UpVector.Y) > 0.9, "it is not upright after walking home")
		table.insert(results, string.format("walked %.0f studs home in %.1fs", flatDistance(away, home), walkTime))

		-- 2. A Launch on the shin breaks the leg: it limps home, slower.
		local shin = model:FindFirstChild("LeftLowerLeg") :: BasePart
		HitService.applyToy(Toys.byId.Launch, shin, shin.Position, Vector3.new(1, 0, 0))
		assert(waitFor(function()
			return (model:GetAttribute("Broken") :: number? or 0) >= 1
		end, 3), "Launch on the shin did not break the leg")
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Walking"
		end, 15), "it never got up to limp home")
		local from = pelvis.Position
		task.wait(2)
		local limpSpeed = flatDistance(pelvis.Position, from) / 2
		assert(limpSpeed < 4.5, string.format("limping at %.1f studs/s is not slower than walking", limpSpeed))
		assert(limpSpeed > 0.8, string.format("limping at %.1f studs/s is hardly moving", limpSpeed))
		table.insert(results, string.format("limped at %.1f studs/s", limpSpeed))

		-- 3. The other leg too: it crawls.
		local otherShin = model:FindFirstChild("RightLowerLeg") :: BasePart
		HitService.applyToy(Toys.byId.Launch, otherShin, otherShin.Position, Vector3.new(-1, 0, 0))
		assert(waitFor(function()
			return (model:GetAttribute("Broken") :: number? or 0) >= 2
		end, 3), "the second leg did not break")
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Crawling"
		end, 15), "with both legs broken it does not crawl")
		from = pelvis.Position
		task.wait(2)
		local crawlSpeed = flatDistance(pelvis.Position, from) / 2
		assert(pelvis.Position.Y < (home.Y - 0.5), "crawling, but the pelvis is still up at standing height")
		assert(crawlSpeed > 0.5, string.format("crawling at %.1f studs/s is hardly moving", crawlSpeed))
		table.insert(results, string.format("crawled at %.1f studs/s", crawlSpeed))

		-- 4. Patched up: legs mend, it gets up.
		DummyControl.heal(model)
		assert(waitFor(function()
			local s = model:GetAttribute("RagdollState")
			return (model:GetAttribute("Broken") :: number?) == 0 and (s == "Standing" or s == "Walking")
		end, 12), "healing did not get it back on its feet")

		-- 5. A hard knock to the head: out cold, then up again.
		assert(waitFor(function()
			local s = model:GetAttribute("RagdollState")
			return s == "Standing" or s == "Walking"
		end, 10), "not up before the head test")
		local head = model:FindFirstChild("Head") :: BasePart
		local mass = (model:GetAttribute("Mass") :: number?) or 10
		DummyControl.hit(model, head, Vector3.new(0, 10, -45) * mass, head.Position)
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Out"
		end, 2), "a hard knock to the head did not knock it out")
		local outAt = os.clock()
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") ~= "Out"
		end, 10), "it never came round")
		local outFor = os.clock() - outAt
		assert(outFor >= 3, string.format("out cold for only %.1fs", outFor))
		table.insert(results, string.format("out cold %.1fs", outFor))

		-- 6. Hurt, then someone walks up: it runs away from them.
		assert(waitFor(function()
			local s = model:GetAttribute("RagdollState")
			return s == "Standing" or s == "Walking"
		end, 10), "not up before the flee test")
		local chest = model:FindFirstChild("UpperTorso") :: BasePart
		DummyControl.hit(model, chest, Vector3.new(12, 0, 0) * mass, chest.Position)
		task.wait(1.4)
		local spot = pelvis.Position
		character:PivotTo(CFrame.new(spot + Vector3.new(0, 1, 7)))
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Fleeing"
		end, 4), "a hurt dummy did not run from the player walking up")
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local start = flatDistance(pelvis.Position, root.Position)
		task.wait(1.5)
		local after = flatDistance(pelvis.Position, root.Position)
		assert(after > start + 4, string.format("fleeing, but only %.1f -> %.1f studs from the player", start, after))
		table.insert(results, string.format("fled %.0f -> %.0f studs", start, after))

		-- 7. A reset forgets the hurt: the player standing close does not scare it.
		DummyControl.reset(model, CFrame.lookAt(home, Vector3.new(look.X, home.Y, look.Z)))
		task.wait(0.5)
		character:PivotTo(CFrame.new(home + Vector3.new(0, 1, 6)))
		local scared = waitFor(function()
			return model:GetAttribute("RagdollState") == "Fleeing"
		end, 2.5)
		assert(not scared, "after a reset it still runs from people (it remembered being hurt)")
		character:PivotTo(CFrame.new(home + Vector3.new(0, 3, 60)))

		-- 8. A broken arm, then home: the lab patches it up after a rest.
		task.wait(0.5)
		local forearm = model:FindFirstChild("LeftLowerArm") :: BasePart
		HitService.applyToy(Toys.byId.Launch, forearm, forearm.Position, Vector3.new(0, 0, 1))
		assert(waitFor(function()
			return (model:GetAttribute("Broken") :: number? or 0) >= 1
		end, 3), "Launch on the forearm did not break the arm")
		local brokeAt = os.clock()
		-- (A Launch can send it 40+ studs; it limps or walks back, then rests HEAL_AFTER s: 28-40 s seen.)
		assert(waitFor(function()
			return (model:GetAttribute("Broken") :: number?) == 0
		end, 75), "the lab never patched up the arm")
		table.insert(results, string.format("arm patched up %.0fs after the break", os.clock() - brokeAt))

		-- 9. Frozen mid-walk: it stops where it is.
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Standing"
		end, 10), "not standing before the freeze test")
		local start2 = home + Vector3.new(-14, 0, 6)
		DummyControl.reset(model, CFrame.lookAt(start2, start2 + Vector3.zAxis))
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Walking"
		end, 4), "it never set off before the freeze")
		task.wait(0.6)
		DummyControl.freeze(model)
		task.wait(0.3)
		-- The statue keeps its walking momentum for a moment (ice is slippery), then stops: no
		-- motor keeps pushing it.
		local frozenAt = pelvis.Position
		task.wait(1.5)
		local settled = pelvis.Position
		task.wait(1)
		local slid = flatDistance(settled, frozenAt)
		local creep = flatDistance(pelvis.Position, settled)
		assert(slid < 5, string.format("the frozen dummy slid %.1f studs", slid))
		assert(creep < 0.4, string.format("the frozen dummy is still moving (%.1f studs in a second)", creep))
		table.insert(results, string.format("frozen mid-walk slid %.1f studs", slid))
		-- A rewind (Workshop Stop) on the ice statue: it thaws and stands, every machine agreeing.
		DummyControl.reset(model, CFrame.lookAt(home, Vector3.new(look.X, home.Y, look.Z)))
		assert(waitFor(function()
			return model:GetAttribute("Frozen") ~= true and model:GetAttribute("RagdollState") == "Standing"
		end, 4), "a reset frozen dummy did not thaw and stand")

		-- 10. Knocked further off on its way home: it still walks the whole way (no teleport).
		task.wait(1)
		local start3 = home + Vector3.new(10, 0, 8)
		DummyControl.reset(model, CFrame.lookAt(start3, start3 + Vector3.zAxis))
		assert(waitFor(function()
			return model:GetAttribute("RagdollState") == "Walking"
		end, 4), "it never set off before the second knock")
		task.wait(0.8)
		local away3 = Vector3.new(pelvis.Position.X - home.X, 0, pelvis.Position.Z - home.Z).Unit
		DummyControl.hit(model, chest, (away3 * 38 + Vector3.new(0, 14, 0)) * mass, chest.Position)
		local lastPos = pelvis.Position
		local worstJump = 0
		local farthest = 0
		assert(waitFor(function()
			local p = pelvis.Position
			worstJump = math.max(worstJump, flatDistance(p, lastPos))
			farthest = math.max(farthest, flatDistance(p, home))
			lastPos = p
			return model:GetAttribute("RagdollState") == "Standing" and flatDistance(p, home) < 2.5
		end, 40), "knocked further off, it never got home")
		-- (The dummy is simulated on the player's client and seen here through replication, which now
		-- and then delivers a quarter second of a 40 studs/s flight at once, up to about 10 studs; being
		-- popped home from where it was knocked to is a jump of 15 or more.)
		assert(worstJump < 12, string.format("it jumped %.1f studs in a tenth of a second (teleported home?)", worstJump))
		table.insert(results, string.format("knocked %.0f studs off mid-walk, walked back", farthest))

		-- Tidy up: the avatar out of the way, the dummy home.
		character:PivotTo(CFrame.new(home + Vector3.new(0, 3, 40)))
		DummyControl.reset(model, CFrame.lookAt(home, Vector3.new(look.X, home.Y, look.Z)))
		return table.concat(results, "; ")
	end,
}
