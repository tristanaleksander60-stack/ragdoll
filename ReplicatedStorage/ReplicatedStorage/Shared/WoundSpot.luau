--!strict
-- Where a round (or a blow) really lands on a body (round 3, M2 fix 2): a straight line from the
-- hitter's head to the point they named. The same answer on the server (the wound, the text, the
-- body's reaction) and on the owner's own screen (its instant reaction to its own dummies), so the
-- body never falls from "Left upper arm" or stands after "Stomach".
--
-- Other bodies on the way (dummies, people) are looked past: in lab view the camera aims over them.
-- When the line meets the body, the part and point it meets are taken; when nothing is met (the body
-- moved since the client saw it), the named point stands (it is already held to the part). When
-- something solid stands in between (a wall, a build), the named point stands too, but guarded: no
-- wound there kills or bleeds out fast (VitalsService), so a shot through a wall never picks the
-- brain or the heart.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local WoundSpot = {}

WoundSpot.MAX_LOOK_PAST = 5 -- bodies and see-through things (round 4, M10: 5, up from 3)
WoundSpot.SEE_THROUGH = 0.95 -- transparency from which a part never guards a body

-- Round 4, M10: what never counts as a wall (looked past like a body): a part you can (almost) see
-- through, a placed toy or a gadget (Props), or a piece the hitter built themselves (BuildService:
-- Piece and Owner). The camera aims past these where the avatar's head does not.
local function seeThrough(hit: Instance, userId: number?): boolean
	if hit:IsA("BasePart") and hit.Transparency >= WoundSpot.SEE_THROUGH then
		return true
	end
	local props = Workspace:FindFirstChild("Props")
	if props and hit:IsDescendantOf(props) then
		return true
	end
	local at: Instance? = hit
	while at and at ~= Workspace do
		if at:GetAttribute("Gadget") == true then
			return true
		end
		if userId and at:GetAttribute("Piece") ~= nil and at:GetAttribute("Owner") == userId then
			return true
		end
		at = at.Parent
	end
	return false
end

function WoundSpot.find(character: Model?, model: Model, part: BasePart, position: Vector3): (BasePart, Vector3, boolean)
	local head = character and character:FindFirstChild("Head")
	if not character or not head or not head:IsA("BasePart") then
		return part, position, false
	end
	local from = head.Position
	local offset = position - from
	if offset.Magnitude < 1 then
		return part, position, false
	end
	local skip: { Instance } = { character }
	local shooter = Players:GetPlayerFromCharacter(character)
	local userId = if shooter then shooter.UserId else nil
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	for _ = 1, WoundSpot.MAX_LOOK_PAST + 1 do
		params.FilterDescendantsInstances = skip
		local hit = Workspace:Raycast(from, offset.Unit * (offset.Magnitude + 1.5), params)
		if not hit then
			return part, position, false
		end
		if hit.Instance:IsDescendantOf(model) then
			local met = hit.Instance
			if met:IsA("BasePart") and met.Parent == model and met.Name ~= "Stump" and met.Name ~= "HumanoidRootPart" then
				return met, hit.Position, false
			end
			return part, position, false
		end
		-- Another body on the way: look past it.
		local other = hit.Instance:FindFirstAncestorOfClass("Model")
		while other and not other:FindFirstChildOfClass("Humanoid") and other.Parent and other.Parent:IsA("Model") do
			other = other.Parent :: Model
		end
		if other and other:FindFirstChildOfClass("Humanoid") then
			table.insert(skip, other)
		elseif seeThrough(hit.Instance, userId) then
			table.insert(skip, hit.Instance)
		else
			return part, position, true
		end
	end
	return part, position, true
end

return WoundSpot
