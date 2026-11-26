--!strict
-- F67 (owner: "Fiks trappen så man kan bruge den indendørs også"; Config.TOWER_STAIRS_V2): inside the tower (the invisible
-- "TowerInside" volume, LabOwnerMap) a player's camera uses Invisicam, so steps and floors in the way turn see-through and
-- the camera is never squeezed against them; outside it goes back to Zoom. Only the server may set
-- Player.DevCameraOcclusionMode, so this runs here, 4 times a second.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerCam = {}

local function insideAny(at: Vector3): boolean
	for _, v in CollectionService:GetTagged("TowerInside") do
		if v:IsA("BasePart") then
			local l = v.CFrame:PointToObjectSpace(at)
			local h = v.Size / 2
			if math.abs(l.X) < h.X and math.abs(l.Y) < h.Y and math.abs(l.Z) < h.Z then
				return true
			end
		end
	end
	return false
end

function TowerCam.start()
	local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any
	if not Config.TOWER_STAIRS_V2 then
		return
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, p in Players:GetPlayers() do
				local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				local want = if root and root:IsA("BasePart") and insideAny(root.Position)
					then Enum.DevCameraOcclusionMode.Invisicam
					else Enum.DevCameraOcclusionMode.Zoom
				if p.DevCameraOcclusionMode ~= want then
					p.DevCameraOcclusionMode = want
				end
			end
		end
	end)
end

return TowerCam
