--!strict
-- F74 STRETCH LONG (owner: "den skal bare ikke trække dem af, bare strække dem ... 1 ben er så langt som det er blevet strukket
-- - det går væk igen efter 30 sek"; Config.STRETCH_LONG; docs/FIXES_26NOV.md F74): make a limb long like rubber, on the
-- server (the sizes replicate, every player sees it).
--   * grow the limb's upper and lower part on their long axis (Y for R15 limbs); the hand or foot keeps its size;
--   * keep the joints joined: every Attachment on a grown part has its Y scaled the same way (BallSockets and
--     AnimationConstraints hang on them), always from the ORIGINAL values stored once per part (nothing creeps);
--   * keep the weight: the density is divided by the factor (the same mass: the body does not tip or sink);
--   * steps of at least 0.04, so the solver never jolts.
-- Stretch.factorOf(model, limb) reads the current factor; Stretch.reset(model) puts everything back.

local Stretch = {}

Stretch.MAX = 3.2
Stretch.STEP = 0.04

local PARTS: { [string]: { string } } = {
	LeftArm = { "LeftUpperArm", "LeftLowerArm" }, RightArm = { "RightUpperArm", "RightLowerArm" },
	LeftLeg = { "LeftUpperLeg", "LeftLowerLeg" }, RightLeg = { "RightUpperLeg", "RightLowerLeg" },
}
Stretch.PARTS = PARTS

type Orig = { size: Vector3, density: number, props: PhysicalProperties?, atts: { [Attachment]: Vector3 } }
local orig: { [BasePart]: Orig } = setmetatable({}, { __mode = "k" }) :: any

local function remember(p: BasePart): Orig
	local o = orig[p]
	if o then
		return o
	end
	local atts: { [Attachment]: Vector3 } = {}
	for _, c in p:GetChildren() do
		if c:IsA("Attachment") then
			atts[c] = c.Position
		end
	end
	local cpp = p.CustomPhysicalProperties
	local density = if cpp then cpp.Density else PhysicalProperties.new(p.Material).Density
	o = { size = p.Size, density = density, props = cpp, atts = atts }
	orig[p] = o
	return o
end

local function apply(p: BasePart, k: number)
	local o = remember(p)
	p.Size = Vector3.new(o.size.X, o.size.Y * k, o.size.Z)
	for a, pos in o.atts do
		if a.Parent == p then
			a.Position = Vector3.new(pos.X, pos.Y * k, pos.Z)
		end
	end
	local base = o.props
	if k <= 1.001 then
		p.CustomPhysicalProperties = base -- (back to what it had, nil included)
	elseif base then
		p.CustomPhysicalProperties = PhysicalProperties.new(base.Density / k, base.Friction, base.Elasticity, base.FrictionWeight, base.ElasticityWeight)
	else
		p.CustomPhysicalProperties = PhysicalProperties.new(o.density / k, 0.5, 0.2)
	end
	p:SetAttribute("StretchK", if k > 1.001 then k else nil)
end

-- The limb's factor now (1 = normal).
function Stretch.factorOf(model: Model, limb: string): number
	local names = PARTS[limb]
	local p = names and model:FindFirstChild(names[1])
	local k = p and p:GetAttribute("StretchK")
	return if type(k) == "number" then k else 1
end

-- Set a limb's length factor (1 .. MAX). Returns the factor it has after the call (unchanged when the step is too small).
function Stretch.setLimb(model: Model, limb: string, factor: number): number
	local names = PARTS[limb]
	if not names then
		return 1
	end
	local k = math.clamp(factor, 1, Stretch.MAX)
	local now = Stretch.factorOf(model, limb)
	if math.abs(k - now) < Stretch.STEP and not (k == 1 and now ~= 1) then
		return now
	end
	for _, n in names do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			apply(p, k)
		end
	end
	model:SetAttribute("Stretched", if k > 1.001 or Stretch.anyLong(model, limb) then true else nil)
	return k
end

-- Is any OTHER limb of the body still long?
function Stretch.anyLong(model: Model, except: string?): boolean
	for limb in PARTS do
		if limb ~= except and Stretch.factorOf(model, limb) > 1.001 then
			return true
		end
	end
	return false
end

-- Every limb back to normal at once (a pooled ragdoll is always reset before reuse).
function Stretch.reset(model: Model)
	for limb in PARTS do
		if Stretch.factorOf(model, limb) ~= 1 then
			Stretch.setLimb(model, limb, 1)
		end
	end
	model:SetAttribute("Stretched", nil)
end

return Stretch
