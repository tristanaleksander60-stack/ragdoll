--!strict
-- F47 (owner: "Gør så ragdolls piller skuddene ud fra hinanden efter de har været døde, så de ikke sidder overalt på alle";
-- Config.PICK_OUT; docs/FIXES_26NOV.md F47): a lab ragdoll that wakes up after being dead or knocked out, with bullet
-- holes on it, gets them picked out: the nearest free ragdoll within HELP_REACH comes over (or, with none free, it does
-- it itself), says a line, and takes the holes out one by one (VitalsService.pickOneOut every STEP s, up to MAX), each
-- with a little plink; at the end a line ("All better!"). The holes and their X-ray slugs go on every screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PickOut = {}

PickOut.HELP_REACH = 30
PickOut.STEP = 0.5
PickOut.MAX = 8
PickOut.START = { "Hold still, this won't hurt.", "Let me get those out.", "Tweezers time!", "Don't move!" }
PickOut.DONE = { "All better!", "Good as new!", "There you go!", "Next!" }

local busy: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function holes(m: Model): number
	local raw = m:GetAttribute("Wounds")
	if type(raw) ~= "string" or raw == "" then
		return 0
	end
	return #string.split(raw, ";")
end

local function up(m: Model): boolean
	local st = m:GetAttribute("RagdollState")
	return m.Parent ~= nil and m:GetAttribute("Vital") ~= "Dead" and m:GetAttribute("Vital") ~= "Unconscious"
		and (st == nil or st == "Standing" or st == "Walking")
end

local function say(m: Model, line: string)
	m:SetAttribute("MoodSay", line)
	task.delay(2.5, function()
		if m.Parent and m:GetAttribute("MoodSay") == line then
			m:SetAttribute("MoodSay", nil)
		end
	end)
end

local function helperFor(patient: Model, at: Vector3): Model?
	local dummies = Workspace:FindFirstChild("Dummies")
	local best, bestD = nil :: Model?, PickOut.HELP_REACH
	for _, m in if dummies then dummies:GetChildren() else {} do
		local pe = m:FindFirstChild("LowerTorso")
		if m ~= patient and m:IsA("Model") and pe and pe:IsA("BasePart") and up(m) and not busy[m]
			and m:GetAttribute("Watch") == nil and m:GetAttribute("Role3") == nil and m:GetAttribute("Held") ~= true
			and m:GetAttribute("CommandedBy") == nil and m:GetAttribute("InMachine") == nil and m:GetAttribute("TryFor") == nil then
			local d = (pe.Position - at).Magnitude
			if d < bestD then
				best, bestD = m, d
			end
		end
	end
	return best
end

local function pickOut(patient: Model)
	if busy[patient] then
		return
	end
	busy[patient] = true
	task.wait(1.5) -- (it gets its bearings first)
	local pe = patient:FindFirstChild("LowerTorso")
	if not (pe and pe:IsA("BasePart")) or holes(patient) == 0 then
		busy[patient] = nil
		return
	end
	local VS = require(script.Parent:WaitForChild("VitalsService")) :: any
	local helper = helperFor(patient, pe.Position)
	local doer = helper or patient
	if helper then
		busy[helper] = true
		helper:SetAttribute("Watch", "Aid")
		local side = (pe.CFrame.RightVector * 2.2)
		helper:SetAttribute("Home", pe.Position + side)
		helper:SetAttribute("HomeLook", pe.Position)
		helper:SetAttribute("Pace", 1.6)
		local t0 = os.clock()
		while os.clock() - t0 < 10 do
			task.wait(0.25)
			local hp = helper:FindFirstChild("LowerTorso")
			if not up(helper) or not (hp and hp:IsA("BasePart")) then
				break
			end
			if (hp.Position - pe.Position).Magnitude < 4.5 then
				break
			end
		end
	end
	if up(doer) and patient.Parent then
		say(doer, PickOut.START[math.random(1, #PickOut.START)])
		for _ = 1, PickOut.MAX do
			if not (up(doer) and patient.Parent) or patient:GetAttribute("Vital") == "Dead" then
				break
			end
			task.wait(PickOut.STEP)
			local left = VS.pickOneOut(patient)
			pcall(function()
				local p = patient:FindFirstChild("UpperTorso")
				if p and p:IsA("BasePart") then
					(require(script.Parent:WaitForChild("FxService")) :: any).hit(p.Position, 6, "Punch")
				end
			end)
			if left <= 0 then
				break
			end
		end
		say(doer, PickOut.DONE[math.random(1, #PickOut.DONE)])
	end
	if helper then
		if helper.Parent and helper:GetAttribute("Watch") == "Aid" then
			helper:SetAttribute("Watch", nil)
			helper:SetAttribute("HomeLook", nil)
			helper:SetAttribute("Pace", nil)
		end
		busy[helper] = nil
	end
	busy[patient] = nil
end

local function watch(m: Instance)
	if not m:IsA("Model") then
		return
	end
	local last = m:GetAttribute("Vital")
	m:GetAttributeChangedSignal("Vital"):Connect(function()
		local now = m:GetAttribute("Vital")
		if (last == "Dead" or last == "Unconscious") and now ~= "Dead" and now ~= "Unconscious" and holes(m) > 0 then
			task.spawn(pickOut, m)
		end
		last = now
	end)
end

function PickOut.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.PICK_OUT then
		return
	end
	local _ = Players
	-- (never hold up the server's start: the Dummies folder comes later)
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies")
		dummies.ChildAdded:Connect(watch)
		for _, m in dummies:GetChildren() do
			watch(m)
		end
	end)
end

return PickOut
