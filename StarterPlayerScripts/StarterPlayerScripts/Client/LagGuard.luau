--!strict
-- OVERVIEW 0.1 part A (owner: "alt lagger lige nu"; docs/RAGDOLL_DIRECTOR.md; Config.LAG_GUARD): cheap render on this
-- screen, measured first (v1143, the new map: 105 lights with 56 casting shadows, 443 SurfaceGuis with no distance
-- limit, 27 billboards, ~2000 trees):
--   * LIGHTS: no light casts shadows; a light further than LIGHT_RANGE studs from the camera is off (its own Enabled is
--     remembered and given back when it comes near).
--   * SIGNS: every SurfaceGui and map billboard without a distance limit gets one (GUI_RANGE; the spawn title further).
--   * TREES on phones and tablets: the leaf canopies cast no shadow.
-- Nothing here changes the server or other players.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local LagGuard = {}

LagGuard.LIGHT_RANGE = 140
LagGuard.GUI_RANGE = 150
LagGuard.TITLE_RANGE = 350

local lights: { [Light]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- (its own Enabled)
local PHONE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function onAdded(d: Instance)
	if d:IsA("Light") then
		lights[d] = d.Enabled
		d.Shadows = false
	elseif d:IsA("SurfaceGui") then
		if d.MaxDistance == 0 then
			local part = d.Parent
			local title = part and part.Name == "Letter3D" and part:FindFirstAncestor("Spawn11") ~= nil
			d.MaxDistance = if title then LagGuard.TITLE_RANGE else LagGuard.GUI_RANGE
		end
	elseif d:IsA("BillboardGui") then
		-- (only the map's own billboards: a ragdoll's or a player's bubble keeps its own rules)
		if d.MaxDistance > 1e6 and not d:FindFirstAncestor("Dummies") and not d:IsDescendantOf(Players) then
			local model = d:FindFirstAncestorOfClass("Model")
			if not (model and Players:GetPlayerFromCharacter(model)) then
				d.MaxDistance = LagGuard.GUI_RANGE
			end
		end
	elseif PHONE and d:IsA("BasePart") and string.find(d.Name, "Canopy") then
		d.CastShadow = false
	end
end

function LagGuard.start()
	if not Config.LAG_GUARD then
		return
	end
	for _, d in Workspace:GetDescendants() do
		onAdded(d)
	end
	Workspace.DescendantAdded:Connect(onAdded)
	task.spawn(function()
		while true do
			task.wait(1)
			local camera = Workspace.CurrentCamera
			if camera then
				local eye = camera.CFrame.Position
				for light, own in lights do
					local holder = light.Parent
					local at: Vector3? = if holder and holder:IsA("BasePart") then holder.Position elseif holder and holder:IsA("Attachment") then holder.WorldPosition else nil
					if not light.Parent then
						lights[light] = nil
					elseif at then
						local want = own and (at - eye).Magnitude < LagGuard.LIGHT_RANGE
						if light.Enabled ~= want then
							light.Enabled = want
						end
					end
				end
			end
		end
	end)
end

return LagGuard
