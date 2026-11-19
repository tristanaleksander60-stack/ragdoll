--!strict
-- Shots that feel real (round 3, M2), through the server's own code:
--   where a round lands decides what the body does: an arm flinches and it stays up; one leg
--     staggers it (a second leg shot soon after takes it down); the stomach takes it down; a nail
--     takes three in the body; a round only shoves (it never throws a body across the lab)
--   every round lowers the pulse at once and costs blood, the head more than the stomach
--   enough rounds kill: the body dies, lies still (never gets up) and goes only after DEAD_HOLD
--   a nail in the jaw kills on the spot and its line reaches the shooter as the kill, never held
--     back; a body killed in a grab goes limp (round 4, M10)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local Lab = require(Systems:WaitForChild("Lab"))
local HitService = require(Systems:WaitForChild("HitService"))
local VitalsService = require(Systems:WaitForChild("VitalsService"))
local DummyFactory = require(Systems:WaitForChild("DummyFactory"))
local Shared = ReplicatedStorage.Shared
local Anatomy = require(Shared.Anatomy)
local Toys = require(Shared.Toys)
local HitMath = require(Shared.HitMath)
local ActiveRagdoll = require(Shared.Ragdoll.ActiveRagdoll)

local function waitFor(check: () -> boolean, timeout: number): boolean
	local started = os.clock()
	while os.clock() - started < timeout do
		if check() then
			return true
		end
		task.wait(0.1)
	end
	return check()
end

-- The nearest other body (anything with a Humanoid in the world, players' avatars aside) to a point.
local function nearestOther(at: Vector3, except: Model?): number
	local nearest = math.huge
	for _, h in game:GetService("Workspace"):GetDescendants() do
		if h:IsA("Humanoid") then
			local m = h.Parent
			local pelvis = m and m:FindFirstChild("LowerTorso")
			if m and m ~= except and pelvis and pelvis:IsA("BasePart") and not game:GetService("Players"):GetPlayerFromCharacter(m) then
				nearest = math.min(nearest, (pelvis.Position - at).Magnitude)
			end
		end
	end
	return nearest
end

-- (Run after T37's horde, rain and bomb, the plaza can still have their bodies walking about:
-- the test row waits, up to 20 s, until nothing else is within 12 studs of it.)
local function waitClear()
	local row = Lab.plazaOrigin() + Vector3.new(-12, 0, -40)
	local started = os.clock()
	while os.clock() - started < 20 and nearestOther(row) < 22 do
		task.wait(0.5)
	end
end

local spawned: { Model } = {}
local function body(offset: Vector3): Model
	local spot = Lab.plazaOrigin() + offset
	local m = DummyFactory.spawn(spot, spot - Vector3.zAxis) -- (the server simulates it)
	table.insert(spawned, m)
	task.wait(0.8)
	return m
end

local function part(model: Model, name: string): BasePart
	return model:FindFirstChild(name) :: BasePart
end

local function state(model: Model): string
	return tostring(model:GetAttribute("RagdollState"))
end

local function down(model: Model): boolean
	local s = state(model)
	return s == "Ragdoll" or s == "Out" or s == "GettingUp"
end

local function shoot(toyId: string, model: Model, partName: string): string?
	local p = part(model, partName)
	return HitService.applyToy(Toys.byId[toyId], p, p.Position, Vector3.new(0, 0, -1))
end

local function run(results: { string })
	-- 1. The rule itself.
	local rig: any = {}
	local now = os.clock()
	assert(ActiveRagdoll.gunReaction({}, "arm", 1.6, now) == "Flinch", "an arm shot does more than flinch")
	-- (Round 5: rounds in the limbs add up, the third takes it down.)
	local limbs: any = {}
	assert(ActiveRagdoll.gunReaction(limbs, "arm", 1, now) == "Flinch" and ActiveRagdoll.gunReaction(limbs, "arm", 1, now + 0.5) == "Flinch", "two arm shots took it down")
	assert(ActiveRagdoll.gunReaction(limbs, "arm", 1, now + 1) == "Ragdoll", "a third round in the limbs did not take it down")
	assert(ActiveRagdoll.gunReaction(rig, "leg", 1, now, 1) == "Flinch", "one leg shot does more than buckle the knee")
	assert(ActiveRagdoll.gunReaction(rig, "leg", 1, now + 1, 1) == "Flinch", "the same leg twice took it down")
	assert(ActiveRagdoll.gunReaction(rig, "leg", 1, now + 2, -1) == "Ragdoll", "the other leg soon after does not take it down")
	assert(ActiveRagdoll.gunReaction({}, "leg", 1, now, -1) == "Flinch", "a fresh body falls from one leg")
	local old: any = {}
	ActiveRagdoll.gunReaction(old, "leg", 1, now, 1)
	assert(ActiveRagdoll.gunReaction(old, "leg", 1, now + 30, -1) == "Flinch", "an old leg shot still counts")
	assert(ActiveRagdoll.gunReaction({}, "torso", 1, now) == "Ragdoll" and ActiveRagdoll.gunReaction({}, "head", 1, now) == "Ragdoll", "a round in the body or the head does not take it down")
	local nails: any = {}
	assert(ActiveRagdoll.gunReaction(nails, "torso", 0.5, now) == "Stumble" and ActiveRagdoll.gunReaction(nails, "torso", 0.5, now + 0.3) == "Stumble", "one or two nails take it down")
	assert(ActiveRagdoll.gunReaction(nails, "torso", 0.5, now + 0.6) == "Ragdoll", "three nails do not take it down")
	assert(HitMath.gunPush(Toys.byId.Shotgun) <= 18 and HitMath.gunPush(Toys.byId.Blaster) <= 12, "a round throws the body")
	table.insert(results, string.format("the rule: arm flinch, one leg buckles (the same leg again too), both legs fall, body or head fall, nails 3 to fall; a round shoves %d-%d studs/s (never a throw)", HitMath.gunPush(Toys.byId.NailGun), HitMath.gunPush(Toys.byId.Shotgun)))

	-- 2. On real bodies (the server simulates them).
	waitClear()
	local armed = body(Vector3.new(-20, 0, -40))
	assert(shoot("Deagle", armed, "LeftUpperArm"), "the arm shot did not land")
	task.wait(1)
	assert(not down(armed), "a Deagle round in the arm put the body down: " .. state(armed))
	local legged = body(Vector3.new(-12, 0, -40))
	shoot("Blaster", legged, "RightUpperLeg")
	task.wait(1)
	if down(legged) then
		-- (What took it down: its wounds, and how near the nearest other body came: a body bumped
		-- by a passer-by falls for that reason, not for the round.)
		local nearest = nearestOther(part(legged, "LowerTorso").Position, legged)
		error(string.format("one leg shot put the body down: %s (wounds %s; nearest other body %.1f studs)", state(legged), tostring(legged:GetAttribute("Wounds")), nearest))
	end
	shoot("Blaster", legged, "LeftUpperLeg")
	assert(waitFor(function()
		return down(legged)
	end, 1.5), "two leg shots did not put the body down: " .. state(legged))
	local gut = body(Vector3.new(-4, 0, -40))
	local pelvisBefore = part(gut, "LowerTorso").Position
	shoot("Shotgun", gut, "LowerTorso")
	assert(waitFor(function()
		return down(gut)
	end, 1.5), "a round in the stomach did not put the body down: " .. state(gut))
	task.wait(1)
	local slid = (part(gut, "LowerTorso").Position - pelvisBefore) * Vector3.new(1, 0, 1)
	assert(slid.Magnitude < 9, string.format("a shotgun round sent the body %.1f studs", slid.Magnitude))
	table.insert(results, string.format("bodies: a Deagle round in the arm (still up), one G17 round in a leg (still up), a second in the other leg (down), a shotgun round in the stomach (down, moved %.1f studs)", slid.Magnitude))

	-- 2b. The part the round really meets decides (fix 2): named the arm, but the line from the
	-- shooter's head meets the stomach: the body goes down and the wound is the body's, not the arm's.
	local shooter = game:GetService("Players"):GetPlayers()[1]
	local character = shooter and shooter.Character
	if character and character:FindFirstChild("Head") then
		local mixed = body(Vector3.new(44, 0, -40))
		local belly = part(mixed, "LowerTorso")
		local front = belly.CFrame.LookVector
		character:PivotTo(CFrame.lookAt(belly.Position + front * 7 + Vector3.new(0, 1, 0), belly.Position))
		task.wait(0.3)
		local line = HitService.applyToy(Toys.byId.Blaster, part(mixed, "LeftUpperArm"), belly.Position, -front, shooter)
		assert(waitFor(function()
			return down(mixed)
		end, 1.5), "a round the line puts in the stomach (the arm named) did not put the body down: " .. state(mixed))
		local wounds = tostring(mixed:GetAttribute("Wounds"))
		assert(not string.find(wounds, "Arm", 1, true) and not string.find(wounds, "Hand", 1, true), "the wound went on the arm named, not where the round met: " .. wounds)
		character:PivotTo(CFrame.new(Lab.plazaOrigin() + Vector3.new(0, 3.5, 20)))
		table.insert(results, "the arm named but the stomach met: down, wound " .. wounds .. " (" .. tostring(line) .. ")")
	end
	-- 2c. A leg round is noted on the body (server time): a fresh simulator (ownership moved) still
	-- takes it down with the other leg.
	local noted = body(Vector3.new(52, 0, -40))
	shoot("Blaster", noted, "RightLowerLeg")
	assert(type(noted:GetAttribute("LegShotRight")) == "number", "a leg round left no note on the body")
	assert(ActiveRagdoll.gunReaction({ model = noted }, "leg", 1, os.clock(), -1) == "Ragdoll", "a new simulator forgot the other leg")
	table.insert(results, "a leg round is noted on the body: a new simulator takes it down with the other leg")

	-- 3. Every round lowers the pulse and costs blood; the head more.
	local a, b = body(Vector3.new(4, 0, -40)), body(Vector3.new(12, 0, -40))
	local restA, restB = VitalsService.pulseOf(a), VitalsService.pulseOf(b)
	local torso = part(a, "UpperTorso")
	VitalsService.wound(a, torso, torso.Position, nil, 1, { zone = Anatomy.zones.Stomach })
	local head = part(b, "Head")
	VitalsService.wound(b, head, head.Position, nil, 1, { zone = Anatomy.zones.Skull })
	local va, vb = VitalsService.of(a) :: any, VitalsService.of(b) :: any
	local dropA, dropB = restA - va.pulse, restB - vb.pulse
	local lossA, lossB = 100 - va.blood, 100 - vb.blood
	assert(dropA >= 3, string.format("a stomach round lowered the pulse by %.1f", dropA))
	assert(dropB > dropA, string.format("the head (%.1f) did not lower it more than the stomach (%.1f)", dropB, dropA))
	assert(lossA > 0 and lossB > lossA, string.format("blood lost: stomach %.1f, head %.1f", lossA, lossB))
	local before = va.pulse
	VitalsService.wound(a, torso, torso.Position, nil, 1, { zone = Anatomy.zones.Stomach })
	assert((VitalsService.of(a) :: any).pulse <= before - 3, "a second round did not lower the pulse again")
	table.insert(results, string.format("one round: stomach -%.0f bpm, -%.0f%% blood; skull -%.0f bpm, -%.0f%% blood; a second stomach round lowers it again", dropA, lossA, dropB, lossB))

	-- 4. Enough rounds kill; the dead body lies still and stays a while.
	VitalsService.liveForTest(true)
	local victim = body(Vector3.new(20, 0, -40))
	local liverPart = part(victim, "UpperTorso")
	local started = os.clock()
	for _ = 1, 8 do
		VitalsService.wound(victim, liverPart, liverPart.Position, nil, 1, { zone = Anatomy.zones.Liver })
		task.wait(0.15)
	end
	local died = waitFor(function()
		return victim:GetAttribute("Vital") == "Dead"
	end, 20)
	local diedAt = os.clock()
	VitalsService.liveForTest(false)
	assert(died, "eight liver rounds did not kill: " .. tostring(victim:GetAttribute("Vital")) .. ", " .. tostring(victim:GetAttribute("Blood")) .. "%")
	-- Hit again while dead: still dead ("no pulse"), still lying.
	local again = VitalsService.wound(victim, liverPart, liverPart.Position, nil, 1, { zone = Anatomy.zones.Stomach })
	assert(again and string.find(again, "no pulse", 1, true) and victim:GetAttribute("Vital") == "Dead", "a dead body hit again: " .. tostring(again))
	-- Watched for 6 s: down at every look (never getting up), and lying still at the end unless
	-- something else bumped it (the plaza's people walk about: then it only slides, still down).
	local slowest = math.huge
	for _ = 1, 12 do
		task.wait(0.5)
		assert(victim.Parent ~= nil, "the dead body went before DEAD_HOLD")
		assert(down(victim), "the dead body got up: " .. state(victim))
		slowest = math.min(slowest, part(victim, "LowerTorso").AssemblyLinearVelocity.Magnitude)
	end
	local lying = slowest
	assert(lying < 3, string.format("the dead body never lay still (%.1f studs/s at the slowest)", lying))
	-- 5. A limb torn off by a round (a close shotgun): an arm never puts the body down, a leg does.
	local Config = require(Shared.Config)
	if Config.SEVERING then
		VitalsService.liveForTest(true)
		local armless = body(Vector3.new(28, 0, -40))
		local arm = part(armless, "LeftUpperArm")
		local cut = VitalsService.wound(armless, arm, arm.Position, nil, 1.8, { sever = 1 })
		local legless = body(Vector3.new(36, 0, -40))
		local leg = part(legless, "RightUpperLeg")
		VitalsService.wound(legless, leg, leg.Position, nil, 1.8, { sever = 1 })
		task.wait(1.2)
		VitalsService.liveForTest(false)
		assert(cut and string.find(cut, "severed", 1, true), "the arm was not torn off: " .. tostring(cut))
		assert(armless:GetAttribute("Vital") == "Alive" and not down(armless), "an arm torn off put the body down: " .. tostring(armless:GetAttribute("Vital")) .. ", " .. state(armless))
		assert(legless:GetAttribute("Vital") ~= "Alive", "a leg torn off left the body up")
		table.insert(results, "an arm torn off by a round: still up (Alive, " .. state(armless) .. "); a leg torn off: down")
	end
	table.insert(results, string.format("eight liver rounds: dead in %.1f s; hit again while dead: still dead; down at every look for 6 s (%s, %.1f studs/s at the slowest); it goes %d s after dying", diedAt - started, state(victim), lying, VitalsService.DEAD_HOLD))

	-- 6. Round 4, M10: a nail in the jaw (a gun round under the blade's power) kills on the spot, and
	-- its line goes to the shooter marked as the kill even right after another line (INFO_GAP).
	if shooter then
		VitalsService.liveForTest(true) -- (quiet self-tests never kill: this one must)
		local nailed = body(Vector3.new(60, 0, -40))
		local chest = part(nailed, "UpperTorso")
		VitalsService.wound(nailed, chest, chest.Position, shooter, 0.3, { zone = Anatomy.zones.Stomach, round = true })
		local jaw = part(nailed, "Head")
		VitalsService.wound(nailed, jaw, jaw.CFrame:PointToWorldSpace(Vector3.new(0, 0, -0.95 * jaw.Size.Z / 2)), shooter, Toys.byId.NailGun.wound, { round = true })
		VitalsService.liveForTest(false)
		local sent = VitalsService.lastSent[shooter]
		assert(nailed:GetAttribute("Vital") == "Dead", "a nail in the jaw left it " .. tostring(nailed:GetAttribute("Vital")))
		assert(sent and sent.killed and string.find(sent.line, "Jaw", 1, true), "the killing line was held back or not marked: " .. tostring(sent and sent.line))
		table.insert(results, string.format("a nail in the jaw: dead on the spot; its line (%q) sent marked as the kill right after another", sent.line))
	end

	-- 7. Round 4, M10: a body held in a grab that dies goes limp (no dangling and kicking).
	local held = body(Vector3.new(68, 0, -40))
	ActiveRagdoll.setHeld(held, true)
	assert(waitFor(function()
		return ActiveRagdoll.limpProfileOf(held) == "Held"
	end, 1), "a grabbed body does not dangle: " .. tostring(ActiveRagdoll.limpProfileOf(held)))
	local heldHead = part(held, "Head")
	VitalsService.liveForTest(true)
	VitalsService.wound(held, heldHead, heldHead.Position, nil, 1, { zone = Anatomy.zones.Brain })
	VitalsService.liveForTest(false)
	assert(waitFor(function()
		return ActiveRagdoll.limpProfileOf(held) == "Ragdoll"
	end, 1), "a dead body in a grab still hangs " .. tostring(ActiveRagdoll.limpProfileOf(held)))
	ActiveRagdoll.setHeld(held, false)
	table.insert(results, "a grabbed body dangles; killed in the grab it goes limp")
end

return {
	name = "guns-reactions-pulse-death",
	timeout = 120,
	run = function(): string?
		local results = {}
		local ok, err = pcall(run, results)
		for _, m in spawned do
			if m.Parent then
				m:Destroy()
			end
		end
		table.clear(spawned)
		VitalsService.liveForTest(false)
		if not ok then
			error(err, 0)
		end
		return table.concat(results, "; ")
	end,
}
