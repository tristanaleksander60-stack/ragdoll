--!strict
-- Round 5 (the owner: the NPCs slowly change colour and back): every living dummy near you glows
-- slowly purple and fades back, each at its own moment (PERIOD s a round). Purple, not green: green
-- means dead in this game (VitalsService.paintDead). Drawn on this screen only with a Highlight on
-- the MAX nearest bodies (Roblox draws 31 Highlights at most); the dead never glow.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NpcGlow = {}

NpcGlow.PERIOD = 7 -- s from plain to purple and back
NpcGlow.STRONGEST = 0.8 -- the fill at its most (0: solid, 1: none): a faint wash, never the dead's solid green
NpcGlow.MAX = 24
-- (The owner, 10 Nov: green and back, not purple. Dead bodies are painted solid green and do not
-- pulse, so the two still read apart.)
NpcGlow.COLOR = Color3.fromRGB(90, 230, 110)

local player = Players.LocalPlayer
local glows: { [Model]: Highlight } = {}

local function phaseOf(model: Model): number
	-- (A steady offset from the model's name and position: neighbours do not pulse in step.)
	local p = model:GetPivot().Position
	return (math.abs(p.X * 0.37 + p.Z * 0.71) % NpcGlow.PERIOD)
end

function NpcGlow.start()
	-- LOOK_V3 (19 Nov 2026): no glow; the living read by their faces and moves, the dead by green.
	local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
	if Config.LOOK_V3 then
		return
	end
	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 0.1 then
			return
		end
		accumulated = 0
		local folder = Workspace:FindFirstChild("Dummies")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not folder or not root or not root:IsA("BasePart") then
			return
		end
		-- The nearest living bodies.
		local list = {}
		for _, m in folder:GetChildren() do
			if m:IsA("Model") and m:GetAttribute("Vital") ~= "Dead" and m:FindFirstChild("LowerTorso") then
				table.insert(list, { m = m, d = (m:GetPivot().Position - root.Position).Magnitude })
			end
		end
		table.sort(list, function(a, b)
			return a.d < b.d
		end)
		local keep: { [Model]: boolean } = {}
		local now = os.clock()
		for i = 1, math.min(#list, NpcGlow.MAX) do
			local m = list[i].m
			keep[m] = true
			local h = glows[m]
			if not h or h.Parent ~= m then
				local made = Instance.new("Highlight")
				made.Name = "NpcGlow"
				made.FillColor = NpcGlow.COLOR
				made.OutlineTransparency = 1
				made.DepthMode = Enum.HighlightDepthMode.Occluded
				made.FillTransparency = 1
				made.Parent = m
				glows[m] = made
				h = made
			end
			local t = ((now + phaseOf(m)) % NpcGlow.PERIOD) / NpcGlow.PERIOD
			-- 0 -> 1 -> 0, plain most of the round: only the middle third of it glows.
			local wave = math.max(0, (1 - math.cos(t * math.pi * 2)) / 2)
			wave = wave * wave * wave
			;(h :: Highlight).FillTransparency = 1 - wave * (1 - NpcGlow.STRONGEST)
		end
		for m, h in glows do
			if not keep[m] then
				h:Destroy()
				glows[m] = nil
			end
		end
	end)
end

return NpcGlow
