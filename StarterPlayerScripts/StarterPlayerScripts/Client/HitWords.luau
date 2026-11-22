--!strict
-- V8-1.2 (hits you can read, Config.REACTIONS_V8): what your hit did, on this screen, at once:
--   * a word over the body: "Dizzy" after a head hit, "Wobbly" after a leg hit, "Knocked out" when
--     it goes out cold; at most MAX words on screen (the oldest goes);
--   * dizzy stars circling the head after a head hit;
--   * a short hit-stop on the struck body (it holds still HIT_STOP s, then goes on with the speed
--     it had) for melee and big hits only; a light hit gets its sound and flash and nothing more.
-- PokeController calls onHit after its own local hit on a body this screen simulates.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HitWords = {}

HitWords.MAX = 2
HitWords.HIT_STOP = 0.07 -- s (66-80 ms)
HitWords.BIG = 60 -- a tool this fast (studs/s) is a big hit
HitWords.WORD_FOR = 1.4 -- s a word stays

local player = Players.LocalPlayer
local words: { BillboardGui } = {}

local function reducedMotion(): boolean
	local ok, Settings = pcall(function()
		return require(script.Parent:WaitForChild("Settings")) :: any
	end)
	return ok and type(Settings.get) == "function" and Settings.get().motion == 2 -- (Settings.MOTION[2]: LESS)
end

function HitWords.show(model: Model, word: string, color: Color3)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return
	end
	-- (One word per body: a new one replaces it.)
	for i = #words, 1, -1 do
		local w = words[i]
		if w.Adornee == head or not w.Parent then
			w:Destroy()
			table.remove(words, i)
		end
	end
	while #words >= HitWords.MAX do
		local oldest = table.remove(words, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	local b = Instance.new("BillboardGui")
	b.Name = "HitWord"
	b.Size = UDim2.fromOffset(160, 36)
	b.StudsOffset = Vector3.new(0, 2.6, 0)
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	b.Adornee = head
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = word
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(20, 20, 30)
	stroke.Parent = t
	t.Parent = b
	local scale = Instance.new("UIScale")
	scale.Scale = 0.5
	scale.Parent = t
	b.Parent = player:WaitForChild("PlayerGui")
	table.insert(words, b)
	TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(HitWords.WORD_FOR, function()
		if b.Parent then
			local fade = TweenService:Create(t, TweenInfo.new(0.25), { TextTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			b:Destroy()
		end
	end)
end

-- Three stars circling the head for a moment.
function HitWords.stars(model: Model)
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") or model:GetAttribute("MachineHidden") == true then
		return
	end
	local b = Instance.new("BillboardGui")
	b.Name = "DizzyStars"
	b.Size = UDim2.fromOffset(90, 40)
	b.StudsOffset = Vector3.new(0, 1.3, 0)
	b.LightInfluence = 0
	b.Adornee = head
	local stars = {}
	for i = 1, 3 do
		local s = Instance.new("TextLabel")
		s.BackgroundTransparency = 1
		s.Size = UDim2.fromOffset(22, 22)
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Font = Enum.Font.GothamBlack
		s.TextScaled = true
		s.TextColor3 = Color3.fromRGB(255, 220, 70)
		s.Text = "\u{2605}"
		s.Parent = b
		stars[i] = s
	end
	b.Parent = player:WaitForChild("PlayerGui")
	local t0 = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > 1.5 or not head.Parent or model:GetAttribute("MachineHidden") == true then -- (0.37.7: gone when it goes into the press)
			if conn then
				conn:Disconnect()
			end
			b:Destroy()
			return
		end
		for i, s in stars do
			local a = t * 7 + i * (2 * math.pi / 3)
			s.Position = UDim2.new(0.5, math.cos(a) * 34, 0.5, math.sin(a) * 9)
			s.TextTransparency = math.clamp((t - 1.1) / 0.4, 0, 1)
		end
	end)
end

-- The struck body holds still for a moment, then goes on as it was.
function HitWords.hitStop(model: Model, seconds: number)
	local roots: { BasePart } = {}
	local seen: { [BasePart]: boolean } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not d.Anchored then
			local r = d.AssemblyRootPart or d
			if not seen[r] then
				seen[r] = true
				table.insert(roots, r)
			end
		end
	end
	local saved: { [BasePart]: { v: Vector3, w: Vector3 } } = {}
	for _, r in roots do
		saved[r] = { v = r.AssemblyLinearVelocity, w = r.AssemblyAngularVelocity }
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection? = nil
	conn = RunService.Heartbeat:Connect(function()
		local done = os.clock() - t0 >= seconds
		for r, s in saved do
			if r.Parent and not r.Anchored then
				if done then
					r.AssemblyLinearVelocity, r.AssemblyAngularVelocity = s.v, s.w
				else
					r.AssemblyLinearVelocity, r.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				end
			end
		end
		if done and conn then
			conn:Disconnect()
		end
	end)
end

-- After our own hit: region is Poses.regionOf (head/arm/leg/body), state what the body is now,
-- speed the tool's, gun whether it was a round.
function HitWords.onHit(model: Model, region: string, state: string?, speed: number, gun: boolean)
	if state == "Out" then
		HitWords.show(model, "Knocked out", Color3.fromRGB(255, 120, 90))
	elseif region == "head" then
		HitWords.stars(model) -- (22 Nov 2026, owner: no "Dizzy" text by the ragdolls; the stars stay)
	end
	if not gun and (speed >= HitWords.BIG or state == "Out") and not reducedMotion() then
		HitWords.hitStop(model, HitWords.HIT_STOP)
	end
end

return HitWords
