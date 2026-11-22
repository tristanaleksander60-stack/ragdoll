--!strict
-- Zombies (22 Nov 2026, owner: "every 3rd one you kill stays green when it comes back and goes for you like a
-- zombie, hitting you until you die if you do not kill it; killed again it just wakes up normal. Make it clear
-- it is attacking, not just a random green ragdoll"). VitalsService decides who rises (every EVERY-th lab kill)
-- and calls rise / clear. A zombie keeps the dead green, wears a red outline and a ZOMBIE tag over its head,
-- walks at its lab's player (a player command's Home, CommandedBy -1, so the lab's roaming leaves it alone),
-- never flees (Personality Brave), and every HIT_GAP s in reach it hits: HIT_DAMAGE off their health and a
-- shove, with a thud. It stops (back to normal) when its player dies or leaves.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Zombies = {}

Zombies.EVERY = 3
Zombies.REACH = 4.5 -- studs: close enough to hit
Zombies.HIT_GAP = 1.1 -- s between two hits
Zombies.HIT_DAMAGE = 18
Zombies.SHOVE = 28 -- studs/s
Zombies.TAG = "Zombie"

local RED = Color3.fromRGB(220, 30, 30)
local nextHit: { [Model]: number } = {}
local running = false

local function lazy(name: string): any
	return require(script.Parent:WaitForChild(name)) :: any
end

local function marks(model: Model, on: boolean)
	local old = model:FindFirstChild("ZombieOutline")
	if old then
		old:Destroy()
	end
	local head = model:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("ZombieTag")
	if tag then
		tag:Destroy()
	end
	if not on then
		return
	end
	local h = Instance.new("Highlight")
	h.Name = "ZombieOutline"
	h.FillTransparency = 1
	h.OutlineColor = RED
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	if head and head:IsA("BasePart") then
		local b = Instance.new("BillboardGui")
		b.Name = "ZombieTag"
		b.Size = UDim2.fromOffset(120, 30)
		b.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
		b.AlwaysOnTop = true
		b.MaxDistance = 80
		b.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json")
		t.TextScaled = true
		t.TextColor3 = RED
		t.TextStrokeTransparency = 0.2
		t.Text = "\u{1F9DF} ZOMBIE"
		t.Parent = b
		b.Parent = head
	end
end

-- Back to a normal dummy (killed as a zombie, or its player gone).
function Zombies.clear(model: Model)
	if model:GetAttribute("Zombie") ~= true then
		return
	end
	model:SetAttribute("Zombie", nil)
	model:SetAttribute("ZombieTarget", nil)
	if model:GetAttribute("CommandedBy") == -1 then
		model:SetAttribute("CommandedBy", nil)
	end
	local was = model:GetAttribute("ZombieWas")
	model:SetAttribute("Personality", if type(was) == "string" then was else "Brave")
	model:SetAttribute("ZombieWas", nil)
	CollectionService:RemoveTag(model, Zombies.TAG)
	nextHit[model] = nil
	marks(model, false)
end

local function step()
	local now = os.clock()
	for _, inst in CollectionService:GetTagged(Zombies.TAG) do
		local model = inst :: Model
		if not model.Parent then
			continue
		end
		local target = Players:GetPlayerByUserId((model:GetAttribute("ZombieTarget") :: number?) or 0)
		local character = target and target.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not target or not target.Parent or (humanoid and humanoid.Health <= 0) then
			-- (Its player left, or it got them: it is an ordinary dummy again, its own colours back.)
			Zombies.clear(model)
			pcall(function()
				lazy("VitalsService").paintNormal(model)
			end)
			continue
		end
		if not (root and root:IsA("BasePart") and humanoid) then
			continue
		end
		if model:GetAttribute("Vital") == "Dead" then
			continue
		end
		local pelvis = model:FindFirstChild("LowerTorso")
		if not (pelvis and pelvis:IsA("BasePart")) then
			continue
		end
		-- Walk at them.
		model:SetAttribute("Home", root.Position)
		model:SetAttribute("HomeLook", root.Position)
		-- In reach and standing: a hit.
		local gap = root.Position - pelvis.Position
		local flat = Vector3.new(gap.X, 0, gap.Z)
		if flat.Magnitude <= Zombies.REACH and model:GetAttribute("RagdollState") == "Standing" and now >= (nextHit[model] or 0) then
			nextHit[model] = now + Zombies.HIT_GAP
			humanoid:TakeDamage(Zombies.HIT_DAMAGE)
			local dir = if flat.Magnitude > 0.01 then flat.Unit else Vector3.zAxis
			root.AssemblyLinearVelocity += dir * Zombies.SHOVE + Vector3.new(0, 12, 0)
			pcall(function()
				lazy("FxService").hit(root.Position, 60, "Punch")
			end)
		end
	end
end

-- `model` (a lab dummy just coming round) rises as a zombie after its lab's player.
function Zombies.rise(model: Model, targetUserId: number)
	model:SetAttribute("ZombieWas", model:GetAttribute("Personality"))
	model:SetAttribute("Personality", "Brave")
	model:SetAttribute("Zombie", true)
	model:SetAttribute("ZombieTarget", targetUserId)
	model:SetAttribute("CommandedBy", -1)
	CollectionService:AddTag(model, Zombies.TAG)
	marks(model, true)
	if not running then
		running = true
		task.spawn(function()
			while true do
				task.wait(0.25)
				local ok, err = pcall(step)
				if not ok then
					warn("[Zombies] " .. tostring(err))
				end
			end
		end)
	end
	local _ = Workspace
end

return Zombies
