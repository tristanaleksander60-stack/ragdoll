--!strict
-- V9-0 / FIX_PATHS_SHOP F1 (owner, 21 Nov 2026: "boxy, boring bushes"): run in Studio (Edit) after the
-- Creator Store picks are inserted into ServerStorage.V9Scratch (malware pass done: every script
-- removed). Turns them into V3Assets roles the path dressing (PathBuilder.dressLine) places:
--   VergeBushRound   "Stylized Bush" by Esiduff (14614766320): one MeshPart + SurfaceAppearance
--   VergeBushLeafy   "Stylized Bush 3d Model" by mimangiolapizza2002 (14522316811): one MeshPart
--   VergeFlowersRed / VergeFlowersWhite / VergeFlowersYellow   rows of 4 mesh flowers from
--                    "3Colors |FlowerPack" by Pack_CR (11269785138)
-- Each: scripts stripped, pivot at its bottom middle, anchored, no collision/query/touch, no shadow
-- on the flowers, a fixed height (bush 3 studs, flowers 1.2).

local SS = game:GetService("ServerStorage")
local scratch = SS:FindFirstChild("V9Scratch")
local target = SS:FindFirstChild("V3Assets")
assert(scratch and target, "need ServerStorage.V9Scratch and V3Assets")

local function clean(m: Model, height: number, shadow: boolean)
	for _, d in m:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = shadow
			d.Massless = true
		end
	end
	local _, size = m:GetBoundingBox()
	if size.Y > 0.01 then
		m:ScaleTo(m:GetScale() * height / size.Y)
	end
	local cf, size2 = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size2.Y / 2, 0))
end

local function add(model: Model?, role: string, height: number, shadow: boolean)
	assert(model, "missing source for " .. role)
	local old = target:FindFirstChild(role)
	if old then
		old:Destroy()
	end
	local m = model:Clone()
	m.Name = role
	clean(m, height, shadow)
	m:SetAttribute("Source", "V9 foliage")
	m.Parent = target
end

-- lihfolk-ignore: findfirstchild-chain (add asserts the source exists)
add(scratch:FindFirstChild("BushB_Esiduff") :: Model?, "VergeBushRound", 3, true)
-- lihfolk-ignore: findfirstchild-chain (add asserts the source exists)
add(scratch:FindFirstChild("BushC_Blender") :: Model?, "VergeBushLeafy", 3, true)
local flowers = scratch:FindFirstChild("FlowersB_3Colors")
assert(flowers, "missing the flower pack")
for _, colour in { "Red", "White", "Yellow" } do
	-- lihfolk-ignore: findfirstchild-chain (add asserts the source exists)
	add(flowers:FindFirstChild(colour .. "-Flowers") :: Model?, "VergeFlowers" .. colour, 1.2, false)
end
return "V9 foliage roles in V3Assets: VergeBushRound, VergeBushLeafy, VergeFlowersRed/White/Yellow"
