--!strict
-- The dummies' sculpted mannequin bodies, on this screen only (10 Nov 2026, the owner: dummies that
-- look like the big Steam ragdoll games, no gaps at the joints, holes where they are hit).
--
-- The server's dummy is the engine's R15 block body (simulated, hit and jointed as before) marked
-- Mannequin. Here each limb gets the sculpted mesh of ReplicatedStorage.DummySkin worn over it, in
-- the limb's own colour, a little longer than the block so neighbouring limbs overlap (no gaps at
-- elbows, knees, hips or shoulders), and the block is hidden on this screen only
-- (LocalTransparencyModifier: everything that asks the part itself still sees it). Nothing of this
-- crosses the network. A person in the crowd (Mannequin off) keeps the plain body under its clothes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TONE = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).DUMMY_TONE

local DummySkins = {}

DummySkins.OVERLAP = 1.0 -- (V10, owner: "the body must not overlap in several places": each skin its limb's own length; was 1.12)
DummySkins.LEG_REACH = 0 -- (V10: was 0.22: the thigh tops stuck out round at the hips; the hips reach down instead, HIP_REACH)
DummySkins.HIP_REACH = 0.3 -- (V10: the hips this much longer, downward over the tops of the thighs)
DummySkins.DETAILS = true -- V7-4: crash-test joint rings, belt and test targets on the mannequins
DummySkins.TARGET = "rbxassetid://91578612138787" -- the yellow and black crash-test target (art/dummy/target.png)
-- V9-0o (Config.DUMMY_TONE): matte skins, no shine in the bright sun.
DummySkins.MATERIAL = if TONE then TONE.material else Enum.Material.SmoothPlastic -- (V10, owner: "exactly the same as their head", not fabric: the head's material, DUMMY_TONE)
DummySkins.REFLECTANCE = if TONE then (TONE.reflectance or 0) else 0.04 -- (V10: glossy)

-- (23 Nov 2026, owner's pictures of their own ragdoll: glossy grey; a hurt arm or leg turns purple, the struck piece the
-- darkest, and a badly hurt one wears a white bandage.) On this screen only, from the shared Wounds list; healed or
-- dead (green) it goes.
local Anatomy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anatomy")) :: any
-- (Two purples, owner 23 Nov 2026: a little hurt, badly hurt, by how much that piece bleeds.)
local BRUISE = Color3.fromRGB(142, 112, 206)
local BRUISE_BAD = Color3.fromRGB(66, 40, 128)
local BAD_AT = 0.58 -- bleed (%/s, all its wounds) a piece is badly hurt from
local function shade(color: Color3, hurt: number?): Color3
	if not hurt or hurt <= 0 then
		return color
	end
	return color:Lerp(if hurt >= 2 then BRUISE_BAD else BRUISE, 0.9)
end
local XRAY_TIME = 3 -- s the x-ray shows
local XRAY_SHOTS = 3 -- hits on one piece of a limb until it is seen through
local BRUISE_AT: { [string]: string } = { UpperArm = "UpperArm", ArmStump = "UpperArm", Forearm = "LowerArm", Hand = "Hand",
	Thigh = "UpperLeg", Femoral = "UpperLeg", Shin = "LowerLeg", Foot = "Foot" }
local function hurtOf(model: Model): ({ [string]: number }, { [string]: string }, { [string]: number })
	local count: { [string]: number } = {}
	local flow: { [string]: number } = {}
	local shots: { [string]: number } = {} -- (rounds and blades, no blows)
	do
		for _, w in Anatomy.parseWounds(model:GetAttribute("Wounds")) do
			local side, rest = string.match(w.zone.id, "^(%u%l+)(%u.*)$")
			local piece = rest and BRUISE_AT[rest]
			if piece and (side == "Left" or side == "Right") then
				count[side .. piece] = (count[side .. piece] or 0) + 1
				shots[side .. piece] = (shots[side .. piece] or 0) + 1 -- (23 Nov 2026, owner: blows too, bat and all)
				flow[side .. piece] = (flow[side .. piece] or 0) + w.zone.bleed * (if w.blunt then 0.5 else 1)
			end
		end
	end
	local tint: { [string]: number } = {}
	local wrap: { [string]: string } = {}
	for _, side in { "Left", "Right" } do
		for _, limb in { { "UpperArm", "LowerArm", "Hand" }, { "UpperLeg", "LowerLeg", "Foot" } } do
			local total, worst, most = 0, limb[1], 0
			for _, piece in limb do
				local n = count[side .. piece] or 0
				total += n
				if n > most then
					worst, most = piece, n
				end
			end
			if total > 0 then
				for _, piece in limb do
					-- (23 Nov 2026, owner: only the struck piece, not the whole limb.)
					local n = count[side .. piece] or 0
					if n > 0 then
						tint[side .. piece] = if (flow[side .. piece] or 0) >= BAD_AT then 2 else 1
					end
				end
				if (count[side .. limb[2]] or 0) >= 2 then
					wrap[side .. limb[2]] = worst
				end
			end
		end
	end
	-- (23 Nov 2026, owner: no bandage on a limb that is seen through.)
	for name in table.clone(wrap) do
		if (shots[name] or 0) >= XRAY_SHOTS then
			wrap[name] = nil
		end
	end
	return tint, wrap, shots
end
-- White wraps round the top of a forearm or a shin.
local function bandage(limb: BasePart, folder: Instance)
	for i = 0, 3 do
		local r = Instance.new("Part")
		r.Name = "Bandage"
		r.Shape = Enum.PartType.Cylinder
		local thick = limb.Size.Y * 0.15
		local wide = math.max(limb.Size.X, limb.Size.Z) * (1.2 - i * 0.015)
		r.Size = Vector3.new(thick, wide, wide)
		r.Color = if i % 2 == 0 then Color3.fromRGB(236, 236, 232) else Color3.fromRGB(222, 222, 216)
		r.Material = Enum.Material.SmoothPlastic
		r.CanCollide, r.CanQuery, r.CanTouch, r.Massless, r.Anchored, r.CastShadow = false, false, false, true, false, false
		r.CFrame = limb.CFrame * CFrame.new(0, limb.Size.Y * (0.42 - i * 0.13), 0) * CFrame.Angles(0, 0, math.rad(90 + (if i % 2 == 0 then 6 else -5)))
		local w = Instance.new("WeldConstraint")
		w.Part0 = limb
		w.Part1 = r
		w.Parent = r
		r.Parent = folder
	end
end

-- The shape of the owner's ragdoll (ReplicatedStorage.DummySkin2, place file): a straight rounded torso over the hips,
-- slim arms and legs, big hands, rounded shoes. FIT: each skin's size against its limb's block; DROP: how far along the
-- block it sits (of the block's length).
local FIT: { [string]: Vector3 } = {
	UpperArm = Vector3.new(0.7, 1.16, 0.8), LowerArm = Vector3.new(0.66, 1.2, 0.74), Hand = Vector3.new(0.8, 2.5, 0.8),
	UpperLeg = Vector3.new(0.76, 1.1, 0.8), LowerLeg = Vector3.new(0.72, 1.1, 0.8), Foot = Vector3.new(0.82, 1.55, 1.12),
	UpperTorso = Vector3.new(1.0, 1.18, 0.98), LowerTorso = Vector3.new(0.86, 1.3, 0.84),
}
local DROP: { [string]: number } = { Hand = -0.7, Foot = 0.24, UpperTorso = -0.08, LowerTorso = 0.3 }
local shaped = false

-- X-ray (23 Nov 2026, owner: "shot 3 times on the same limb you see through that limb only: its bone, broken where the
-- bullets struck"). The piece's skin goes see-through and wears its bone inside, broken at its bullet holes.
-- (24 Nov 2026, owner: on a phone it must be plain that it is an x-ray, not a limb gone: a bigger bone that is never
-- shot away whole, in a limb that stays a clear x-ray blue.)
local XRAY_PHONE = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
local XRAY_CLEAR = if XRAY_PHONE then 0.55 else 0.74
local XRAY_TINT = if XRAY_PHONE then Color3.fromRGB(52, 96, 176) else Color3.fromRGB(104, 138, 186)
local XRAY_BLUE = if XRAY_PHONE then 0.85 else 0.55
local BONE = Color3.fromRGB(168, 152, 118)
local BONE_END = Color3.fromRGB(180, 166, 134)
local MARROW = Color3.fromRGB(96, 44, 40)
local function xrayBone(limb: BasePart, skin: BasePart, folder: Instance, key: string, hits: number)
	local rng = Random.new(#limb.Name * 7 + 3) -- (the same bone every time it is drawn again)
	local size = skin.Size
	local len = size.Y * 0.94
	local thick = math.min(size.X, size.Z) * 0.2 * (if not XRAY_PHONE then 1 elseif key == "Hand" or key == "Foot" then 1.35 else 1.6)
	local function bit(shape: Enum.PartType, s: Vector3, at: CFrame, colour: Color3, round: boolean?): Part
		local p = Instance.new("Part")
		p.Name = "XrayBone"
		p:SetAttribute("Of", limb.Name)
		p.Shape = if round then Enum.PartType.Block else shape
		p.Size = s
		p.Color = colour
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.Anchored, p.CastShadow = false, false, false, true, false, false
		if round then -- (an egg shape: the knuckles and the flares)
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Sphere
			m.Parent = p
		end
		p.CFrame = skin.CFrame * at
		local w = Instance.new("WeldConstraint")
		w.Part0 = limb
		w.Part1 = p
		w.Parent = p
		p.Parent = folder
		return p
	end
	local turn = CFrame.Angles(0, 0, math.rad(90)) -- (a cylinder's axis is X: along the limb)
	-- (23 Nov 2026, owner: no holes and cracks: the bone itself is shot away bit by bit, where it is hit.) Where it was
	-- struck: its bullet holes, else spread over the bone for blows.
	local marks: { { y: number, x: number, hard: number } } = {}
	for _, hole in limb:GetChildren() do
		if hole.Name == "BulletHole" and hole:IsA("BasePart") and #marks < 20 then
			local l = skin.CFrame:PointToObjectSpace(hole.Position)
			table.insert(marks, { y = math.clamp(l.Y, -len * 0.44, len * 0.44), x = l.X, hard = 1 })
		end
	end
	for i = 1, math.clamp(hits - #marks, 0, 8) do
		table.insert(marks, { y = ({ 0.06, -0.24, 0.27, -0.06, 0.16, -0.34, 0.36, -0.15 })[i] * len, x = (if i % 2 == 0 then 1 else -1) * thick, hard = 0.8 })
	end
	local boneXs: { number } = if key == "LowerArm" then { -thick * 0.62, thick * 0.62 } elseif key == "LowerLeg" then { -thick * 0.32, thick * 0.92 } else {}
	-- How much is gone of the bone at (x, y): 0 whole .. 1 shot through.
	local function gone(x: number, y: number, step: number): number
		local sum = 0
		for _, m in marks do
			local share = 1
			if #boneXs == 2 then -- (two bones side by side: most of it on the nearer one)
				local other = if x == boneXs[1] then boneXs[2] else boneXs[1]
				share = if math.abs(m.x - x) <= math.abs(m.x - other) then 1 else 0.35
			end
			local d = math.abs(m.y - y) / step
			if d < 1.6 then
				sum += 0.42 * m.hard * share * (1 - d / 1.6)
			end
		end
		return math.min(sum, if XRAY_PHONE then 0.7 else 1)
	end
	local SLICES = if key == "Hand" or key == "Foot" then 5 else 13
	-- One long bone in slices: each slice thinner, crooked and darker the more of it is shot away, at last gone; splinters
	-- lie round the gaps. Flared ends with two knuckles (they go too).
	local function bone(x: number, z: number, t: number, length: number, knuckle: number)
		local half = length / 2
		local step = length * 0.94 / SLICES
		for k = 1, SLICES do
			local y = -length * 0.47 + (k - 0.5) * step
			local g = gone(x, y, step)
			local mid = math.abs(y) / half
			local wide = t * (0.92 + 0.22 * mid * mid) -- (slim in the middle)
			if g < 0.9 then
				local left = 1 - g * 0.78
				local side = rng:NextNumber(0, math.pi * 2)
				local off = wide * g * 0.34 -- (bitten from one side)
				local tilt = math.rad(rng:NextNumber(-16, 16)) * g
				bit(Enum.PartType.Cylinder, Vector3.new(step * (1.04 + 0.1 * g), wide * left, wide * left * rng:NextNumber(1 - 0.25 * g, 1)),
					CFrame.new(x + math.cos(side) * off, y, z + math.sin(side) * off) * CFrame.Angles(tilt, 0, tilt * 0.8) * turn,
					if g < 0.12 then BONE else BONE:Lerp(MARROW, math.min(0.55, g * 0.6)))
			end
			if g > 0.3 then
				-- Splinters: standing out of the broken edges, the more the worse.
				for _ = 1, if g > 0.65 then 3 else 1 do
					local c = t * rng:NextNumber(0.12, 0.26)
					bit(Enum.PartType.Block, Vector3.new(c * 0.55, c * rng:NextNumber(1.4, 3.2), c * 0.45),
						CFrame.new(x + rng:NextNumber(-0.85, 0.85) * t, y + rng:NextNumber(-0.9, 0.9) * step, z + rng:NextNumber(-0.85, 0.85) * t)
							* CFrame.Angles(math.rad(rng:NextNumber(-55, 55)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-55, 55))),
						if rng:NextNumber() < 0.6 then BONE else BONE_END)
				end
			end
		end
		for _, e in { 1, -1 } do
			local at = e * half
			local g = gone(x, at * 0.9, step)
			if g < 0.85 then
				local left = 1 - g * 0.55
				bit(Enum.PartType.Block, Vector3.new(t * 1.45, length * 0.24, t * 1.35) * left, CFrame.new(x, at * 0.84, z), BONE, true) -- (the flare)
				bit(Enum.PartType.Block, Vector3.new(t * 1.15, t * 1.2, t * 1.3) * knuckle * left, CFrame.new(x - t * 0.46 * knuckle, at * 0.97, z), BONE_END, true)
				if g < 0.45 then
					bit(Enum.PartType.Block, Vector3.new(t * 1.15, t * 1.2, t * 1.3) * knuckle, CFrame.new(x + t * 0.46 * knuckle, at * 0.97, z), BONE_END, true)
				end
			end
		end
	end
	if key == "LowerArm" then
		bone(-thick * 0.62, 0, thick * 0.74, len, 0.95)
		bone(thick * 0.62, 0, thick * 0.62, len * 0.96, 0.9)
	elseif key == "LowerLeg" then
		bone(-thick * 0.32, 0, thick * 1.0, len, 1.15)
		bone(thick * 0.92, 0, thick * 0.42, len * 0.92, 0.95)
	elseif key == "Hand" or key == "Foot" then
		local n = if key == "Hand" then 4 else 5
		for k = 1, n do
			local x = (k - (n + 1) / 2) * thick * 0.72
			bone(x, 0, thick * 0.3, len * 0.42, 1)
			bit(Enum.PartType.Block, Vector3.new(thick * 0.4, len * 0.22, thick * 0.4), CFrame.new(x, -len * 0.34, 0), BONE, true)
		end
		for k = 1, 5 do -- (the little wrist or ankle bones)
			bit(Enum.PartType.Block, Vector3.new(thick * 0.75, thick * 0.62, thick * 0.65),
				CFrame.new((k - 3) * thick * 0.52, len * 0.31 + (k % 2) * thick * 0.4, rng:NextNumber(-0.2, 0.2) * thick), BONE_END, true)
		end
	else
		bone(0, 0, thick * 1.08, len, 1.2)
	end
end

local template: Instance? = nil
local template: Instance? = nil
local skins: { [BasePart]: MeshPart } = {}

-- The sculpted surface over a limb, if it has one (BulletHoles puts holes on it).
function DummySkins.skinOf(part: BasePart): MeshPart?
	local s = skins[part]
	if s and s.Parent then
		return s
	end
	return nil
end

local function strip(model: Model)
	local folder = model:FindFirstChild("Skins")
	if folder then
		folder:Destroy()
	end
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") then
			skins[d] = nil
			d.LocalTransparencyModifier = 0
		end
	end
end

local function dress(model: Model)
	local source = template
	if not source or model:FindFirstChild("Skins") then
		return
	end
	-- (Worn, like a hat: the ragdoll leaves it out of the body it simulates.)
	local folder = Instance.new("Model")
	folder.Name = "Skins"
	folder:SetAttribute("Worn", true)
	local tint: { [string]: number } = {}
	for _, d in model:GetChildren() do
		if d:IsA("BasePart") and d.Name ~= "Head" and d.Name ~= "HumanoidRootPart" then
			local src = source:FindFirstChild(d.Name, true)
			if src and src:IsA("MeshPart") then
				local skin = src:Clone()
				skin:ClearAllChildren()
				skin.Name = d.Name
				skin.Anchored = false
				skin.CanCollide = false
				skin.CanQuery = false
				skin.CanTouch = false
				skin.Massless = true
				skin.TextureID = ""
				skin.Material = DummySkins.MATERIAL
				skin.Reflectance = DummySkins.REFLECTANCE
				for _, sa in skin:GetChildren() do
					if sa:IsA("SurfaceAppearance") then
						sa:Destroy() -- (V10: a surface appearance would bring its own shine back)
					end
				end
				skin.Color = d.Color
				-- (V10, owner: "legs and hips must hang together"): the thighs reach up into the hips (LEG_REACH of their
				-- length, upward only, so the knees stay where they are).
				local up = if d.Name == "LeftUpperLeg" or d.Name == "RightUpperLeg" then DummySkins.LEG_REACH elseif d.Name == "LowerTorso" then -DummySkins.HIP_REACH else 0
				skin.Size = Vector3.new(d.Size.X, d.Size.Y * (DummySkins.OVERLAP + math.abs(up)), d.Size.Z)
				skin.CFrame = d.CFrame * CFrame.new(0, d.Size.Y * up / 2, 0)
				local key = string.gsub(string.gsub(d.Name, "^Left", ""), "^Right", "")
				local fit = if shaped then FIT[key] else nil
				if fit then
					skin.Size = d.Size * fit
					local side = if string.sub(d.Name, 1, 4) == "Left" then 1 elseif string.sub(d.Name, 1, 5) == "Right" then -1 else 0
					local inward = if key == "UpperArm" or key == "LowerArm" or key == "Hand" then side * (d.Size.X * (1 - fit.X) * 0.5 + 0.1) else 0
					skin.CFrame = d.CFrame * CFrame.new(inward, (DROP[key] or 0) * d.Size.Y, 0)
					if key == "UpperTorso" then
						-- (Its shape is a rounded head: the faint eyes in it go under the arm, out of sight.)
						skin.Size = Vector3.new(skin.Size.Z, skin.Size.Y, skin.Size.X)
						skin.CFrame *= CFrame.Angles(0, math.rad(90), 0)
					end
				end
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = d
				weld.Part1 = skin
				weld.Parent = skin
				skin.Parent = folder
				skins[d] = skin
				d.LocalTransparencyModifier = 1
				-- (A limb recoloured later, a frozen one, keeps its skin the same colour.)
				local recolour = d:GetPropertyChangedSignal("Color"):Connect(function()
					skin.Color = shade(d.Color, tint[d.Name])
				end)
				skin.Destroying:Once(function()
					recolour:Disconnect() -- (stripped and dressed again: no pile of old connections)
				end)
			end
		end
	end
	-- V7-4 (the owner: "every ragdoll must look better, details and all"): the white mannequin gets
	-- crash-test details: dark joint rings at the elbows, knees and ankles,
	-- and the yellow and black test targets on both sides of the head and on
	-- the chest. All of it welded to the limbs on this screen only (no network, no physics).
	if DummySkins.DETAILS then
		local DARK = Color3.fromRGB(56, 60, 68)
		local function ring(limbName: string, top: boolean, thick: number, grow: number)
			local limb = model:FindFirstChild(limbName)
			if not limb or not limb:IsA("BasePart") then
				return
			end
			local d = math.min(limb.Size.X, limb.Size.Z) * grow
			local r = Instance.new("Part")
			r.Name = "JointRing"
			local at = limb.CFrame * CFrame.new(0, (if top then 1 else -1) * (limb.Size.Y / 2 - thick / 2), 0)
			if limbName == "LowerTorso" then
				-- (The belt follows the waist's own shape: a band, not a round disc on an oval waist.)
				r.Size = Vector3.new(limb.Size.X * grow, thick, limb.Size.Z * grow)
				r.CFrame = at
			else
				r.Shape = Enum.PartType.Cylinder
				r.Size = Vector3.new(thick, d, d)
				r.CFrame = at * CFrame.Angles(0, 0, math.rad(90))
			end
			r.Color = DARK
			r.Material = DummySkins.MATERIAL
			r.Reflectance = if TONE then 0 else 0.06
			r.CanCollide, r.CanQuery, r.CanTouch, r.Massless, r.Anchored = false, false, false, true, false
			r.CastShadow = false
			local w = Instance.new("WeldConstraint")
			w.Part0 = limb
			w.Part1 = r
			w.Parent = r
			r.Parent = folder
		end
		-- (V9-NOW 8, owner 21 Nov 2026: "a black thing through the arms": the rings are sized on the hidden limb
		-- blocks, wider than the sculpted grey skin, so at the elbow they stuck out as a dark bar. The grey matte
		-- dummies (DUMMY_TONE) wear none; the old white mannequins keep them.)
		for _, side in if TONE then {} else { "Left", "Right" } do
			ring(side .. "LowerArm", true, 0.14, 1.16) -- elbow
			ring(side .. "LowerLeg", true, 0.16, 1.14) -- knee
			ring(side .. "Foot", true, 0.12, 1.12) -- ankle
		end
		-- (No belt: the waist block is wider than the sculpted waist, so any belt stuck out like a tray.)
		-- The test targets: thin plates with the target picture.
		local function mark(limbName: string, offset: CFrame, size: number)
			if true then
				return -- (V10, owner: "remove the yellow and black logo on the ragdolls")
			end
			local limb = model:FindFirstChild(limbName)
			if not limb or not limb:IsA("BasePart") then
				return
			end
			local p = Instance.new("Part")
			p.Name = "TestMark"
			p.Size = Vector3.new(size, size, 0.04)
			p.Transparency = 1
			p.CFrame = limb.CFrame * offset
			p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.Anchored = false, false, false, true, false
			local decal = Instance.new("Decal")
			decal.Texture = DummySkins.TARGET
			decal.Face = Enum.NormalId.Front
			decal.Parent = p
			local w = Instance.new("WeldConstraint")
			w.Part0 = limb
			w.Part1 = p
			w.Parent = p
			p.Parent = folder
		end
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			-- (V10, owner: "the yellow-black logo hangs a little off the body, shots do not show through it": on the
			-- round head, inside its box, and just behind the bullet holes, BulletHoles.SKIN_FIT 0.86.)
			local hx = head.Size.X / 2 * 0.8
			mark("Head", CFrame.new(-hx, 0.05, 0) * CFrame.Angles(0, math.rad(90), 0), math.min(head.Size.Y, head.Size.Z) * 0.62)
			mark("Head", CFrame.new(hx, 0.05, 0) * CFrame.Angles(0, math.rad(-90), 0), math.min(head.Size.Y, head.Size.Z) * 0.62)
		end
		local chest = model:FindFirstChild("UpperTorso")
		if chest and chest:IsA("BasePart") then
			mark("UpperTorso", CFrame.new(chest.Size.X * 0.22, chest.Size.Y * 0.12, -(chest.Size.Z / 2 * 0.8)), chest.Size.Y * 0.32) -- (V10: on the chest, behind the holes)
		end
	end
	folder.Parent = model
	local hadHoles: { [string]: boolean } = {}
	local xrays: { [string]: { from: number, till: number } } = {}
	local firstLook = true
	local showHurt: () -> ()
	function showHurt()
		if folder.Parent ~= model then
			return
		end
		-- (23 Nov 2026, owner: the purple stays until it is awake again, also while it lies dead and comes round.)
		local vital = model:GetAttribute("Vital")
		if (vital == "Dead" or vital == "Unconscious") and (model:GetAttribute("Wounds") or "") == "" then
			return
		end
		local wrap: { [string]: string }
		local shots: { [string]: number }
		tint, wrap, shots = hurtOf(model)
		-- (24 Nov 2026, first aid: a place that is well again has no holes either.)
		local body = false
		for _, w in Anatomy.parseWounds(model:GetAttribute("Wounds")) do
			local side, rest = string.match(w.zone.id, "^(%u%l+)(%u.*)$")
			body = body or not ((side == "Left" or side == "Right") and rest ~= nil and BRUISE_AT[rest] ~= nil)
		end
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") then
				local limb = skins[d] ~= nil and d.Name ~= "UpperTorso" and d.Name ~= "LowerTorso"
				local hurt = if limb then (shots[d.Name] or 0) > 0 else body
				if hadHoles[d.Name] and not hurt and vital == "Alive" then
					for _, hole in d:GetChildren() do
						if hole.Name == "BulletHole" then
							hole:Destroy()
						end
					end
				end
				hadHoles[d.Name] = hurt
			end
		end
		for _, d in model:GetChildren() do
			local skin = if d:IsA("BasePart") then skins[d] else nil
			if skin and d:IsA("BasePart") then
				skin.Color = shade(d.Color, tint[d.Name])
				local n = shots[d.Name] or 0
				-- (24 Nov 2026, owner: after three hits the x-ray shows for 3 s and goes again, until three more hits.)
				local x = xrays[d.Name]
				if not x then
					x = { from = if firstLook then n else 0, till = 0 }
					xrays[d.Name] = x
				end
				x.from = math.min(x.from, n) -- (it was helped: counted anew)
				if x.till == 0 and n - x.from >= XRAY_SHOTS then
					x.till = os.clock() + XRAY_TIME
					local name = d.Name
					task.delay(XRAY_TIME, function()
						local count = 0
						for _, w in Anatomy.parseWounds(model:GetAttribute("Wounds")) do
							local side, rest = string.match(w.zone.id, "^(%u%l+)(%u.*)$")
							local piece = rest and BRUISE_AT[rest]
							if piece and side .. piece == name then
								count += 1
							end
						end
						x.from, x.till = count, 0
						showHurt()
					end)
				end
				local clear = x.till > 0 and n > 0
				skin.Transparency = if clear then XRAY_CLEAR else 0
				if clear then
					skin.Color = skin.Color:Lerp(XRAY_TINT, XRAY_BLUE)
				end
				local was = skin:GetAttribute("Xray")
				local now = if clear then math.min(n, 14) else nil
				-- (The holes on the skin fade, however many, so the bone stays in sight.)
				if clear then
					task.delay(0.2, function()
						if x.till == 0 then
							return
						end
						for _, hole in d:GetChildren() do
							if hole.Name == "BulletHole" then
								local art = hole:FindFirstChildOfClass("Decal")
								if art and art:GetAttribute("XrayWas") == nil then
									art:SetAttribute("XrayWas", art.Transparency)
									art.Transparency = 0.86
								end
							end
						end
					end)
				end
				if was ~= nil and now == nil then
					for _, hole in d:GetChildren() do
						local art = if hole.Name == "BulletHole" then hole:FindFirstChildOfClass("Decal") else nil
						local old = art and art:GetAttribute("XrayWas")
						if art and type(old) == "number" then
							art.Transparency = old
							art:SetAttribute("XrayWas", nil)
						end
					end
				end
				if was ~= now then
					skin:SetAttribute("Xray", now)
					local limb, key = d, string.gsub(string.gsub(d.Name, "^Left", ""), "^Right", "")
					-- (A moment later: the round's own hole is there by then.)
					task.delay(if clear then 0.15 else 0, function()
						if folder.Parent ~= model or skin:GetAttribute("Xray") ~= now then
							return
						end
						for _, b in folder:GetChildren() do
							if b.Name == "XrayBone" and b:GetAttribute("Of") == limb.Name then
								b:Destroy()
							end
						end
						if clear then
							xrayBone(limb, skin, folder, key, n)
						end
					end)
				end
			end
		end
		firstLook = false
		local sign = ""
		for _, name in { "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg" } do
			if wrap[name] then
				sign ..= name
			end
		end
		if folder:GetAttribute("Wraps") == sign then
			return
		end
		folder:SetAttribute("Wraps", sign)
		for _, b in folder:GetChildren() do
			if b.Name == "Bandage" then
				b:Destroy()
			end
		end
		for name in wrap do
			local limb = model:FindFirstChild(name)
			if limb and limb:IsA("BasePart") then
				bandage(skins[limb] or limb, folder)
			end
		end
	end
	model:GetAttributeChangedSignal("Wounds"):Connect(showHurt)
	model:GetAttributeChangedSignal("Vital"):Connect(showHurt)
	showHurt()
	-- (V6-5: a body inside a lab creature (the plant, the egg, the washer, the vacuum) is hidden on
	-- every screen through its skins too: the server sets MachineHidden on the model.)
	local function machineHide()
		local hidden = model:GetAttribute("MachineHidden") == true
		for _, s in folder:GetChildren() do
			if s:IsA("BasePart") then
				s.LocalTransparencyModifier = if hidden then 1 else 0
			end
			-- (0.37.19, owner: "the yellow and black marks on the head come up before the ragdoll": the crash-test
			-- marks are decals on see-through parts, which the modifier does not hide; they go with the body.)
			for _, d in s:GetDescendants() do
				if d:IsA("Decal") then
					d.Transparency = if hidden then 1 else 0
				end
			end
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and not skins[d] and not d:IsDescendantOf(folder) and d.Name ~= "HumanoidRootPart" then
				d.LocalTransparencyModifier = if hidden then 1 else 0
			end
			-- (0.37.6, owner: "the face goes up before the ragdoll": the face is a SurfaceGui, which the modifier
			-- does not hide; it goes with the body.)
			if d:IsA("SurfaceGui") then
				d.Enabled = not hidden
			end
		end
	end
	model:GetAttributeChangedSignal("MachineHidden"):Connect(machineHide)
	if model:GetAttribute("MachineHidden") == true then
		machineHide() -- (dressed while already inside a machine: hidden at once)
	end
	-- (A body that goes for good takes its entries with it: the table never keeps dead limbs.)
	model.Destroying:Once(function()
		for _, d in model:GetChildren() do
			if d:IsA("BasePart") then
				skins[d] = nil
			end
		end
	end)
end

local followed: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function follow(model: Instance)
	-- (Once each: a lab hidden and shown again brings its dummies back through ChildAdded.)
	if not model:IsA("Model") or followed[model] then
		return
	end
	followed[model] = true
	local function update()
		if model:GetAttribute("Mannequin") == true then
			dress(model)
		else
			strip(model)
		end
	end
	model:GetAttributeChangedSignal("Mannequin"):Connect(update)
	-- (The limbs arrive with the model; a beat later is enough for all of them.)
	task.defer(update)
end

function DummySkins.start()
	template = ReplicatedStorage:FindFirstChild("DummySkin2")
	shaped = template ~= nil
	if not template then
		template = ReplicatedStorage:WaitForChild("DummySkin", 15)
	end
	if not template then
		return -- (no template in the place: the block bodies stay as they are)
	end
	local function watch(folder: Instance)
		folder.ChildAdded:Connect(follow)
		for _, m in folder:GetChildren() do
			follow(m)
		end
	end
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		watch(dummies)
	end
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Dummies" then
			watch(child)
		end
	end)
end

return DummySkins
