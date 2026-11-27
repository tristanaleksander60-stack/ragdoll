--!strict
-- C10 part 2 (docs/CONTROLS_10.md 7; Config.CONTROLS_DRESS): the machines' old part-built controls move onto the ONE
-- kit (Shared/Controls). For each control below, a kit BUTTON, LEVER or DIAL is built on the ground beside it (the old
-- floor button or lever pole is hidden; a machine body stays as it is and gets its control in front of it, toward the
-- spawn) and the machine's OWN prompt moves onto it (renamed ControlPrompt, the custom big-icon style): what the
-- machine does on a press does not change, only how it looks and feels (Client/ControlsFX: instant press feedback,
-- states). The bowling lever, the stretcher's panels and the Lab Controls button keep their own controls for now.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ControlsDress = {}

type Dress = { kind: string, icon: string, hide: boolean }
ControlsDress.LIST = {
	GyroButton = { kind = "Button", icon = "\u{1F300}", hide = true },
	ShredderButton = { kind = "Button", icon = "\u{2699}", hide = true },
	TRexLever = { kind = "Lever", icon = "\u{1F996}", hide = true },
	TeslaBase = { kind = "Button", icon = "\u{26A1}", hide = false },
	FanMouth = { kind = "Dial", icon = "\u{1F4A8}", hide = false },
	SweeperPost = { kind = "Dial", icon = "\u{1F504}", hide = false },
	WasherGlass = { kind = "Dial", icon = "\u{1F9FA}", hide = false },
} :: { [string]: Dress }

local function labOrigin(of: Instance): Vector3?
	local lab = of:FindFirstAncestor("Playground")
	local node: Instance? = of
	while node and node.Parent ~= lab do
		node = node.Parent
	end
	local grass = node and node:FindFirstChild("OwnerGrass", true)
	if grass and grass:IsA("BasePart") then
		return grass.Position
	end
	return nil
end

local function dress(part: BasePart, prompt: ProximityPrompt, d: Dress)
	if part:GetAttribute("Dressed") then
		return
	end
	part:SetAttribute("Dressed", true)
	local Controls = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Controls")) :: any
	local at = part.Position
	local face = Vector3.zAxis
	if not d.hide then
		-- beside the machine, toward the lab's middle (where the players come from)
		local o = labOrigin(part)
		local toward = if o then Vector3.new(o.X - at.X, 0, o.Z - at.Z) else Vector3.zAxis
		toward = if toward.Magnitude > 0.1 then toward.Unit else Vector3.zAxis
		at += toward * (math.max(part.Size.X, part.Size.Z) / 2 + 3)
		face = -toward
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex: { Instance } = { part }
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		table.insert(ex, dummies)
	end
	params.FilterDescendantsInstances = ex
	local hit = Workspace:Raycast(at + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), params)
	local ground = if hit then hit.Position.Y else at.Y - part.Size.Y / 2
	local cf = CFrame.lookAt(Vector3.new(at.X, ground, at.Z), Vector3.new(at.X, ground, at.Z) - face)
	local model = Controls.build(d.kind, cf, { machine = prompt.ObjectText, action = prompt.ActionText, icon = d.icon, parent = part.Parent })
	-- the machine's own prompt moves onto the kit (its Triggered stays wired to the machine)
	local own = model:FindFirstChild("ControlPrompt", true)
	local base = model.PrimaryPart
	if own and base then
		own:Destroy()
		prompt.Name = "ControlPrompt"
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 10)
		prompt.RequiresLineOfSight = false
		prompt.Parent = base
	end
	if d.hide then
		part.Transparency = 1
		part.CanCollide = false
		for _, c in part:GetDescendants() do
			if c:IsA("SurfaceGui") or c:IsA("BillboardGui") then
				c.Enabled = false
			elseif c:IsA("Decal") then
				c.Transparency = 1
			end
		end
	end
end

function ControlsDress.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not (Config.CONTROLS_DRESS and Config.CONTROLS_V2) then
		return
	end
	task.spawn(function()
		for _ = 1, 40 do -- (the labs are built in the first minutes; a rebuilt lab is dressed again)
			local root = Workspace:FindFirstChild("Playground")
			if root then
				for _, pp in root:GetDescendants() do
					if pp:IsA("ProximityPrompt") and pp.Name ~= "ControlPrompt" then
						local p = pp.Parent
						local d = p and ControlsDress.LIST[p.Name]
						if d and p and p:IsA("BasePart") then
							pcall(dress, p, pp, d)
						end
					end
				end
			end
			task.wait(6)
		end
	end)
end

return ControlsDress
