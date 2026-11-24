--!strict
-- 21 Nov 2026 (the lab guide, Server/Systems/LabGuide): the cyan drop rings breathe softly; while
-- you carry a dummy (GrabController), the nearest ring in reach lights up, grows, and a bouncing
-- "DROP HERE!" with an arrow floats over it. A few rings near you only, 15 times a second.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LabGuideClient = {}

LabGuideClient.TAG = "GuideRing"
LabGuideClient.NEAR = 140 -- studs: rings further away are left alone
LabGuideClient.CARRY_REACH = 90 -- studs: the ring that lights up while you carry a dummy
LabGuideClient.REST = 0.3 -- a ring's pieces at rest (they breathe 0.15 around it)

-- A ring is an invisible part carrying its glowing pieces: they take the look.
-- (0.50.3, fps: off a computer the rings rest still; every new transparency made the engine rebuild what it draws.)
local LITE = not game:GetService("UserInputService").KeyboardEnabled
local function setRing(ring: BasePart, transparency: number)
	for _, seg in ring:GetChildren() do
		if seg:IsA("BasePart") and seg.Transparency ~= transparency then
			seg.Transparency = transparency
		end
	end
end

local player = Players.LocalPlayer
local marker: BillboardGui? = nil
local lit: BasePart? = nil

local function makeMarker(): BillboardGui
	local g = Instance.new("BillboardGui")
	g.Name = "DropHere"
	g.Size = UDim2.fromScale(8, 4)
	g.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	g.AlwaysOnTop = true
	g.LightInfluence = 0
	g.MaxDistance = 200
	local text = Instance.new("TextLabel")
	text.Name = "Words"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 0.55)
	text.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(40, 220, 255)
	text.Text = "DROP HERE!"
	local ink = Instance.new("UIStroke")
	ink.Color = Color3.fromRGB(10, 20, 30)
	ink.Thickness = 3
	ink.Parent = text
	text.Parent = g
	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.Position = UDim2.fromScale(0, 0.5)
	arrow.Size = UDim2.fromScale(1, 0.5)
	arrow.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
	arrow.TextScaled = true
	arrow.TextColor3 = Color3.fromRGB(255, 255, 255)
	arrow.Text = "\u{25BC}"
	local ink2 = Instance.new("UIStroke")
	ink2.Color = Color3.fromRGB(10, 20, 30)
	ink2.Thickness = 3
	ink2.Parent = arrow
	arrow.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	return g
end

function LabGuideClient.start()
	local GrabController = require(script.Parent:WaitForChild("GrabController")) :: any
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 15 then
			return
		end
		acc = 0
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local here = root.Position
		local carrying = GrabController.isGrabbing()
		local t = os.clock()
		local best: BasePart? = nil
		local bestD = LabGuideClient.CARRY_REACH
		for _, ring in CollectionService:GetTagged(LabGuideClient.TAG) do
			if ring:IsA("BasePart") then
				local d = (ring.Position - here).Magnitude
				if d < LabGuideClient.NEAR then
					setRing(ring, if LITE then LabGuideClient.REST else LabGuideClient.REST + 0.15 * math.sin(t * 2.6 + ring.Position.X * 0.1))
					if carrying and d < bestD then
						best, bestD = ring, d
					end
				end
			end
		end
		-- The ring you would drop into: bright, a little bigger, and DROP HERE! over it.
		if lit and lit ~= best then
			setRing(lit, LabGuideClient.REST)
			lit = nil
		end
		if best then
			setRing(best, 0.05 + 0.1 * math.sin(t * 8))
			lit = best
			local m = marker or makeMarker()
			marker = m
			m.Adornee = best
			m.Enabled = true
			local arrow = m:FindFirstChild("Arrow")
			if arrow and arrow:IsA("TextLabel") then
				arrow.Position = UDim2.fromScale(0, 0.5 + 0.08 * math.abs(math.sin(t * 6)))
			end
		elseif marker then
			marker.Enabled = false
		end
	end)
end

return LabGuideClient
