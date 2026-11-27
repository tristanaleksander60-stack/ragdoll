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
-- Row 6 (Config.INJURY_V2; BODY_V2 4b): STAGES per piece, counted from its hits: 1 bruised (1-2 hits, a light lavender),
-- 2 hurt (3-4, a stronger violet), 3 badly hurt (5+, deep violet); the bandage is a gauze wrap with offset ridges, a
-- taped loose end and, at stage 3, a violet seep spot; a head hit twice gets a head wrap.
local INJURY_V2 = (require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any).INJURY_V2 == true
local GAUZE = Color3.fromRGB(235, 232, 222)
local GAUZE_DARK = Color3.fromRGB(221, 217, 205)
local function shade(color: Color3, hurt: number?): Color3
	if not hurt or hurt <= 0 then
		return color
	end
	if INJURY_V2 then
		if hurt >= 3 then
			return color:Lerp(BRUISE_BAD, 0.92)
		elseif hurt >= 2 then
			return color:Lerp(BRUISE, 0.9)
		end
		return color:Lerp(BRUISE, 0.45)
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
						if INJURY_V2 then
							tint[side .. piece] = if n >= 5 then 3 elseif n >= 3 then 2 else 1
						else
							tint[side .. piece] = if (flow[side .. piece] or 0) >= BAD_AT then 2 else 1
						end
					end
				end
				if (count[side .. limb[2]] or 0) >= 2 then
					wrap[side .. limb[2]] = if INJURY_V2 then tostring(tint[side .. worst] or 1) else worst
				end
			end
		end
	end
	if INJURY_V2 then
		local head = 0
		for _, w in Anatomy.parseWounds(model:GetAttribute("Wounds")) do
			if w.zone.id == "Brain" or w.zone.id == "Jaw" then
				head += 1
			end
		end
		if head >= 2 then
			wrap.Head = if head >= 5 then "3" elseif head >= 3 then "2" else "1"
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
local function bandage(limb: BasePart, folder: Instance, stage: number?)
	if INJURY_V2 then
		local function stick(r: BasePart)
			r.Material = Enum.Material.Fabric
			r.CanCollide, r.CanQuery, r.CanTouch, r.Massless, r.Anchored, r.CastShadow = false, false, false, true, false, false
			local w = Instance.new("WeldConstraint")
			w.Part0 = limb
			w.Part1 = r
			w.Parent = r
			r.Parent = folder
		end
		local head = limb.Name == "Head"
		local wide = math.max(limb.Size.X, limb.Size.Z) * (if head then 1.06 else 1.18)
		local thick = limb.Size.Y * (if head then 0.2 else 0.14)
		local y0 = if head then 0.18 else 0.4
		-- three overlapping gauze rings, each a little offset and tilted (wrap ridges)
		for i = 0, 2 do
			local r = Instance.new("Part")
			r.Name = "Bandage"
			r.Shape = Enum.PartType.Cylinder
			r.Size = Vector3.new(thick, wide * (1 - i * 0.012), wide * (1 - i * 0.012))
			r.Color = if i % 2 == 0 then GAUZE else GAUZE_DARK
			r.CFrame = limb.CFrame * CFrame.new(0, limb.Size.Y * (y0 - i * thick / limb.Size.Y * 0.72), 0)
				* CFrame.Angles(math.rad(if i == 1 then 4 else -3), 0, math.rad(90 + (if i % 2 == 0 then 5 else -6)))
			stick(r)
		end
		-- the loose end with a strip of tape
		local tail = Instance.new("Part")
		tail.Name = "Bandage"
		tail.Size = Vector3.new(0.05, thick * 1.3, thick * 0.9)
		tail.Color = GAUZE
		tail.CFrame = limb.CFrame * CFrame.new(wide / 2 + 0.02, limb.Size.Y * (y0 - 0.1) - thick * 0.5, 0) * CFrame.Angles(0, 0, math.rad(-12))
		stick(tail)
		local tape = Instance.new("Part")
		tape.Name = "Bandage"
		tape.Size = Vector3.new(0.06, thick * 0.35, thick * 0.95)
		tape.Color = Color3.fromRGB(246, 244, 238)
		tape.CFrame = tail.CFrame * CFrame.new(0.005, thick * 0.35, 0)
		stick(tape)
		-- stage 3: a violet seep spot on the front of the wrap
		if (stage or 0) >= 3 then
			local seep = Instance.new("Part")
			seep.Name = "Bandage"
			seep.Shape = Enum.PartType.Cylinder
			seep.Size = Vector3.new(0.04, thick * 0.9, thick * 0.75)
			seep.Color = Color3.fromRGB(122, 60, 190)
			seep.CFrame = limb.CFrame * CFrame.new(0, limb.Size.Y * (y0 - 0.06), -wide / 2 - 0.01) * CFrame.Angles(0, math.rad(90), 0)
			stick(seep)
		end
		return
	end
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
-- BODY_V2 1 (owner, 26 Nov 2026: X-ray 10/10): the X-RAY toggle (Client/XRayToggle) shows every near body in X-ray, whole
-- skeleton, until it is switched off; the nearest XRAY_ALL_MAX only (phones fewer), within XRAY_ALL_REACH studs.
local xrayAll: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local refreshers: { [Model]: () -> () } = setmetatable({}, { __mode = "k" }) :: any
local XRAY_ALL_REACH = 80
local XRAY_ALL_MAX = if XRAY_PHONE then 6 else 16
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
	-- F59 (owner: "Gør så man kan se skud på knoglen i maven/ryggen"; Config.XRAY_TORSO): the torso gets a real cartoon
	-- skeleton instead of one straight bone, built in the limb's own frame (front = -Z): in the chest the spine (7
	-- vertebrae at the back), the sternum, 6 curved ribs a side, 2 shoulder blades and 2 collarbones; in the belly the
	-- lower spine and the pelvis. Every bullet hole on the piece puts a slug on the bone the round would reach first
	-- (a rib or the sternum from the front, the spine or a shoulder blade from the back, the ribs from the side, the
	-- pelvis or the lower spine in the belly; a heavy round goes on to the spine), nose pointing the way it travelled,
	-- with crack lines by force.
	local torsoCfg = (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any)
	if (key == "UpperTorso" or key == "LowerTorso") and torsoCfg.XRAY_TORSO then
		local sz = limb.Size
		local W, Hh, D = sz.X, sz.Y, sz.Z
		local function at(cf: CFrame): CFrame
			return skin.CFrame:ToObjectSpace(limb.CFrame * cf)
		end
		local function knob(s: Vector3, p: Vector3, colour: Color3?): Part
			return bit(Enum.PartType.Block, s, at(CFrame.new(p)), colour or BONE, true)
		end
		local function rod(a: Vector3, b: Vector3, r: number, colour: Color3?): Part
			local len = (b - a).Magnitude
			return bit(Enum.PartType.Cylinder, Vector3.new(len + r * 0.6, r, r), at(CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)), colour or BONE)
		end
		local spineZ = if key == "UpperTorso" then D * 0.26 else D * 0.2
		if key == "UpperTorso" then
			for k = 0, 6 do
				local y = Hh * (0.46 - k * 0.153)
				knob(Vector3.new(W * 0.11, Hh * 0.1, D * 0.15), Vector3.new(0, y, spineZ), if k % 2 == 0 then BONE else BONE_END)
			end
			knob(Vector3.new(W * 0.09, Hh * 0.5, D * 0.07), Vector3.new(0, Hh * 0.1, -D * 0.36)) -- (the sternum)
			local r = math.min(D * 0.07, Hh * 0.05)
			for side = -1, 1, 2 do
				for i = 0, 5 do
					local y = Hh * (0.3 - i * 0.12)
					local drop = Hh * 0.05 -- (ribs slope down towards the front)
					local p1 = Vector3.new(side * W * 0.06, y, spineZ)
					local p2 = Vector3.new(side * W * 0.34, y - drop * 0.2, D * 0.2)
					local p3 = Vector3.new(side * W * 0.43, y - drop * 0.5, -D * 0.06)
					local w4 = if i < 4 then 0.07 else 0.2 -- (the low ribs stop short of the sternum)
					local p4 = Vector3.new(side * W * w4, y - drop, -D * 0.33)
					rod(p1, p2, r)
					rod(p2, p3, r)
					rod(p3, p4, r * 0.9, if i < 4 then BONE else BONE_END)
				end
				-- the shoulder blade and the collarbone
				knob(Vector3.new(W * 0.24, Hh * 0.38, D * 0.05), Vector3.new(side * W * 0.26, Hh * 0.2, D * 0.41), BONE_END)
				rod(Vector3.new(side * W * 0.06, Hh * 0.38, -D * 0.32), Vector3.new(side * W * 0.45, Hh * 0.44, -D * 0.02), r * 1.1)
			end
		else
			for k = 0, 3 do
				knob(Vector3.new(W * 0.12, Hh * 0.2, D * 0.17), Vector3.new(0, Hh * (0.4 - k * 0.22), spineZ), if k % 2 == 0 then BONE else BONE_END)
			end
			for side = -1, 1, 2 do
				knob(Vector3.new(W * 0.3, Hh * 0.6, D * 0.5), Vector3.new(side * W * 0.27, -Hh * 0.05, D * 0.02)) -- (the hip wing)
			end
			knob(Vector3.new(W * 0.2, Hh * 0.55, D * 0.13), Vector3.new(0, -Hh * 0.15, D * 0.3), BONE_END) -- (the sacrum)
			knob(Vector3.new(W * 0.42, Hh * 0.16, D * 0.1), Vector3.new(0, -Hh * 0.35, -D * 0.3), BONE_END) -- (the front of the pelvis)
		end
		-- the slugs, on the bone the round reaches first
		local slugs = 0
		for _, hole in limb:GetChildren() do
			if hole.Name == "BulletHole" and hole:IsA("BasePart") and slugs < 15 then
				slugs += 1
				local l = limb.CFrame:PointToObjectSpace(hole.Position)
				local scale = hole:GetAttribute("Scale")
				local force = if type(scale) == "number" then scale else 1
				local y = math.clamp(l.Y, -Hh * 0.45, Hh * 0.45)
				local spot: Vector3
				if math.abs(l.X) > W * 0.38 and math.abs(l.X) / W > math.abs(l.Z) / D then
					spot = Vector3.new(math.sign(l.X) * W * 0.41, y, l.Z * 0.3) -- (from the side: the ribs or the hip wing)
				elseif l.Z < 0 then -- (from the front)
					if force >= 1.6 then
						spot = Vector3.new(0, y, spineZ - D * 0.06) -- (a heavy round goes on to the spine)
					elseif key == "UpperTorso" and math.abs(l.X) < W * 0.1 then
						spot = Vector3.new(l.X, math.max(y, -Hh * 0.12), -D * 0.37) -- (the sternum)
					elseif key == "UpperTorso" then
						spot = Vector3.new(math.clamp(l.X, -W * 0.42, W * 0.42), y, -D * 0.27) -- (a rib)
					else
						spot = Vector3.new(math.clamp(l.X * 0.8, -W * 0.34, W * 0.34), y, -D * 0.16) -- (the pelvis)
					end
				else -- (from the back)
					if math.abs(l.X) < W * 0.12 then
						spot = Vector3.new(l.X * 0.5, y, spineZ + D * 0.05) -- (the spine)
					elseif key == "UpperTorso" and l.Y > -Hh * 0.05 then
						spot = Vector3.new(math.clamp(l.X, -W * 0.36, W * 0.36), y, D * 0.39) -- (a shoulder blade)
					else
						spot = Vector3.new(math.clamp(l.X, -W * 0.4, W * 0.4), y, D * 0.22) -- (a rib or the hip wing)
					end
				end
				local dir = Vector3.new(-l.X, 0, -l.Z)
				dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, 1)
				local rs = if XRAY_PHONE then 0.2 else 0.15
				local slug = bit(Enum.PartType.Cylinder, Vector3.new(rs * 2.2, rs, rs), at(CFrame.lookAt(spot, spot + dir) * CFrame.Angles(0, math.rad(90), 0)), Color3.fromRGB(196, 172, 112))
				slug.Material = Enum.Material.Metal
				slug.Name = "XraySlug"
				if force >= 1.35 then
					local crack = Color3.fromRGB(70, 60, 54)
					local t = math.min(W, D) * 0.12
					bit(Enum.PartType.Block, Vector3.new(t * 2.4, t * 0.16, t * 0.5), at(CFrame.new(spot) * CFrame.Angles(0, 0, math.rad(20))), crack)
					if force >= 1.6 then
						bit(Enum.PartType.Block, Vector3.new(t * 2, t * 0.16, t * 0.5), at(CFrame.new(spot) * CFrame.Angles(0, 0, math.rad(-35))), crack)
					end
				end
			end
		end
		return
	end
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
	-- (BODY_V2 0, gore off: the bone stays whole in X-ray; a break comes with BODY_V2 1b.)
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).GORE == false then
		table.clear(marks)
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
	-- (F4, owner 26 Nov 2026: "hver eneste kugle i knoglerne med xray", Config.XRAY_SLUGS): every round that hit this limb
	-- sits in the bone as a small grey-gold slug at the exact height and side it went in (its BulletHole), at most
	-- SLUG_MAX a limb; a heavy round (hole Scale 1.35+, the sniper and the big guns) also leaves a dark crack line across
	-- the bone right there, a very heavy one (1.6+) a clean snap (two lines, the piece between knocked aside). Inside the
	-- X-ray shell only; they go with the holes (a full heal clears both).
	if (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).XRAY_SLUGS then
		local slugs = 0
		local xs: { number } = if key == "LowerArm" then { -thick * 0.62, thick * 0.62 } elseif key == "LowerLeg" then { -thick * 0.32, thick * 0.92 } else { 0 }
		for _, hole in limb:GetChildren() do
			if hole.Name == "BulletHole" and hole:IsA("BasePart") and slugs < 15 then
				slugs += 1
				local l = skin.CFrame:PointToObjectSpace(hole.Position)
				local y = math.clamp(l.Y, -len * 0.46, len * 0.46)
				local bx = xs[1]
				for _, x in xs do
					if math.abs(x - l.X) < math.abs(bx - l.X) then
						bx = x
					end
				end
				if key == "Hand" or key == "Foot" then
					bx = math.clamp(l.X, -thick * 1.4, thick * 1.4)
				end
				local r = if XRAY_PHONE then 0.2 else 0.15
				local slug = bit(Enum.PartType.Ball, Vector3.one * r, CFrame.new(bx + math.sign(l.X) * thick * 0.25, y, math.sign(l.Z) * thick * 0.2), Color3.fromRGB(196, 172, 112))
				slug.Material = Enum.Material.Metal
				slug.Name = "XraySlug"
				local scale = hole:GetAttribute("Scale")
				local force = if type(scale) == "number" then scale else 1
				if force >= 1.35 then
					local crack = Color3.fromRGB(70, 60, 54)
					bit(Enum.PartType.Block, Vector3.new(thick * 1.5, thick * 0.12, thick * 1.3), CFrame.new(bx, y, 0) * CFrame.Angles(0, 0, math.rad(14)), crack)
					if force >= 1.6 then
						bit(Enum.PartType.Block, Vector3.new(thick * 1.5, thick * 0.12, thick * 1.3), CFrame.new(bx + thick * 0.12, y + thick * 0.5, 0) * CFrame.Angles(0, 0, math.rad(-10)), crack)
					end
				end
			end
		end
	end
	-- D12 (DAMAGE_12.md 1, Config.BONES_V2): the bone's STAGE from the server's bone model (BoneStages) drawn on it:
	-- HAIRLINE a thin crack line, CRACKED a zig-zag crack with a little gap, BROKEN snapped (a dark gap across it),
	-- SHATTERED a wider gap with chips spread inside the shell. Never outside the X-ray.
	local model = limb.Parent
	local stages = if model then model:GetAttribute("BoneStages") else nil
	local stage = if type(stages) == "string" then tonumber(string.match(stages, limb.Name .. ":(%d)")) else nil
	if stage and stage > 0 and not (key == "UpperTorso" or key == "LowerTorso") then
		local crack = Color3.fromRGB(54, 44, 40)
		local w = thick * 1.25
		local y0 = len * 0.08
		if stage == 1 then
			bit(Enum.PartType.Block, Vector3.new(w, thick * 0.07, w), CFrame.new(0, y0, 0) * CFrame.Angles(0, 0, math.rad(18)), crack)
		else
			for k = -1, 1 do
				bit(Enum.PartType.Block, Vector3.new(w * 0.55, thick * 0.1, w), CFrame.new(k * w * 0.3, y0 + (if k == 0 then thick * 0.18 else 0), 0) * CFrame.Angles(0, 0, math.rad(if k == 0 then -32 else 32)), crack)
			end
			if stage >= 3 then
				bit(Enum.PartType.Block, Vector3.new(w * 1.1, thick * (if stage == 4 then 0.55 else 0.3), w * 1.1), CFrame.new(0, y0 - thick * 0.3, 0), MARROW)
			end
			if stage == 4 then
				for _ = 1, 4 do
					local c = thick * rng:NextNumber(0.18, 0.3)
					bit(Enum.PartType.Block, Vector3.new(c, c * 1.3, c), CFrame.new(rng:NextNumber(-0.9, 0.9) * thick, y0 + rng:NextNumber(-1.2, 0.8) * thick, rng:NextNumber(-0.9, 0.9) * thick) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), 0), BONE_END)
				end
			end
		end
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
					-- (24 Nov 2026, owner: the elbow sat half inside the upper arm: the two blocks overlap round the joint, and
					-- the skins more so. Each now ends a little past the elbow itself.)
					local elbow = if key == "UpperArm" or key == "LowerArm" then d:FindFirstChild(string.sub(d.Name, 1, #d.Name - #key) .. "ElbowRigAttachment") else nil
					if elbow and elbow:IsA("Attachment") then
						local half = skin.Size.Y / 2
						local lap = skin.Size.X * 0.28
						local top = if key == "UpperArm" then half else elbow.Position.Y + lap
						local low = if key == "UpperArm" then elbow.Position.Y - lap else -half
						if top - low > 0.2 then
							skin.Size = Vector3.new(skin.Size.X, top - low, skin.Size.Z)
							skin.CFrame = d.CFrame * CFrame.new(inward, (top + low) / 2, 0)
						end
					end
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
				-- (F74 STRETCH_LONG: the server makes a limb long (its part grows on Y, attribute StretchK); the skin grows with it,
				-- from where it sat at the dressing, so the long limb shows)
				do
					local k0 = (d:GetAttribute("StretchK") :: number?) or 1
					local size0, off0 = skin.Size, d.CFrame:ToObjectSpace(skin.CFrame)
					local grow = d:GetAttributeChangedSignal("StretchK"):Connect(function()
						local k = ((d:GetAttribute("StretchK") :: number?) or 1) / k0
						if not skin.Parent then
							return
						end
						weld.Enabled = false
						skin.Size = Vector3.new(size0.X, size0.Y * k, size0.Z)
						skin.CFrame = d.CFrame * CFrame.new(off0.X, off0.Y * k, off0.Z) * off0.Rotation
						weld.Enabled = true
					end)
					skin.Destroying:Once(function()
						grow:Disconnect()
					end)
				end
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
				if (d.Name == "UpperTorso" or d.Name == "LowerTorso") and (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).XRAY_TORSO then
					-- (F59: the torso's wounds are not counted per piece: its bullet holes are)
					n = 0
					for _, h in d:GetChildren() do
						if h.Name == "BulletHole" then
							n += 1
						end
					end
				end
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
				local clear = (x.till > 0 and n > 0) or xrayAll[model] == true
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
		for _, name in { "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg", "Head" } do
			if wrap[name] then
				sign ..= name .. (if INJURY_V2 then tostring(wrap[name]) else "")
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
		for name, how in wrap do
			local limb = model:FindFirstChild(name)
			if limb and limb:IsA("BasePart") then
				bandage(skins[limb] or limb, folder, if INJURY_V2 then tonumber(how) else nil)
			end
		end
	end
	refreshers[model] = showHurt
	-- (D12: a bone's stage rose: the X-ray bones are drawn again with the new crack, and the bone flashes white)
	local lastStages = tostring(model:GetAttribute("BoneStages") or "")
	model:GetAttributeChangedSignal("BoneStages"):Connect(function()
		local now = tostring(model:GetAttribute("BoneStages") or "")
		local risen: { [string]: boolean } = {}
		for name, s in string.gmatch(now, "(%w+):(%d)") do
			local before = tonumber(string.match(lastStages, name .. ":(%d)")) or 0
			if (tonumber(s) or 0) > before then
				risen[name] = true
			end
		end
		lastStages = now
		local skins = model:FindFirstChild("Skins")
		if not skins then
			return
		end
		for _, s in skins:GetDescendants() do
			if s:GetAttribute("Xray") ~= nil then
				s:SetAttribute("Xray", nil)
			end
		end
		showHurt()
		task.delay(0.3, function()
			local lit: { [BasePart]: Color3 } = {}
			for _, b in skins:GetDescendants() do
				if b:IsA("BasePart") and b.Name == "XrayBone" and risen[tostring(b:GetAttribute("Of"))] then
					lit[b] = b.Color
					b.Color = Color3.new(1, 1, 1)
				end
			end
			task.delay(0.18, function()
				for b, c in lit do
					if b.Parent then
						b.Color = c
					end
				end
			end)
		end)
	end)
	model:GetAttributeChangedSignal("Wounds"):Connect(showHurt)
	model:GetAttributeChangedSignal("Vital"):Connect(showHurt)
	-- (F59: a hole landing on or leaving the torso redraws its X-ray)
	for _, name in { "UpperTorso", "LowerTorso" } do
		local t = model:FindFirstChild(name)
		if t then
			local function changed(c: Instance)
				if c.Name == "BulletHole" then
					task.delay(0.05, showHurt)
				end
			end
			t.ChildAdded:Connect(changed)
			t.ChildRemoved:Connect(changed)
		end
	end
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

-- The X-RAY toggle: on = the nearest bodies in X-ray (looked at again every second), off = back to normal.
local xrayOn = false
function DummySkins.setXray(on: boolean)
	if on == xrayOn then
		return
	end
	xrayOn = on
	if not on then
		for model in xrayAll do
			xrayAll[model] = nil
			local fn = refreshers[model]
			if fn and model.Parent then
				pcall(fn)
			end
		end
		return
	end
	task.spawn(function()
		while xrayOn do
			local camera = Workspace.CurrentCamera
			local eye = if camera then camera.CFrame.Position else Vector3.zero
			local list: { { model: Model, d: number } } = {}
			for model in refreshers do
				local pelvis = model.Parent and model:FindFirstChild("LowerTorso")
				if pelvis and pelvis:IsA("BasePart") then
					local d = (pelvis.Position - eye).Magnitude
					if d <= XRAY_ALL_REACH then
						table.insert(list, { model = model, d = d })
					end
				end
			end
			table.sort(list, function(a, b)
				return a.d < b.d
			end)
			local want: { [Model]: boolean } = {}
			for i = 1, math.min(#list, XRAY_ALL_MAX) do
				want[list[i].model] = true
			end
			for model, fn in refreshers do
				local should = want[model] == true
				if (xrayAll[model] == true) ~= should then
					xrayAll[model] = if should then true else nil
					if model.Parent then
						pcall(fn)
					end
				end
			end
			task.wait(1)
		end
	end)
end
function DummySkins.xrayIsOn(): boolean
	return xrayOn
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
