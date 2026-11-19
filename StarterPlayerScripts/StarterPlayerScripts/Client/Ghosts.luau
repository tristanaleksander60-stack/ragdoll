--!strict
-- Other players' moving things pass through your body. Your body is simulated on your own client, so
-- this client alone decides what it collides with: a dummy someone else just sent flying, and the
-- moving parts of someone else's machine, are put in the "Ghost" collision group here (it collides
-- with everything except player bodies). Nobody can shove, pin or keep you down with their dummies
-- or machines. Your own throws and machines, and dummies just standing about, stay solid.
--
-- Loose props are handled on the server already (Props: LabProps never touch player bodies).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Dummies = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Dummies"))

local GHOST = "Ghost"
local CHECK = 0.25 -- s between checks for blame running out (it turns on at once: see watchDummy)
local BLAME_ATTRIBUTES = { HitBy = true, HitAt = true, LocalHitBy = true, LocalHitAt = true }

local Ghosts = {}

local me = Players.LocalPlayer.UserId
local original: { [BasePart]: string } = {} -- the group a part had before it became a ghost

local function ghost(part: BasePart, on: boolean)
	if on then
		if original[part] == nil then
			original[part] = part.CollisionGroup
			part.CollisionGroup = GHOST
		end
	elseif original[part] ~= nil then
		part.CollisionGroup = original[part]
		original[part] = nil
	end
end

local function ghostModel(model: Instance, on: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			ghost(d, on)
		end
	end
end

-- A dummy is a ghost to you while someone else is behind its flight.
local function sentByOther(model: Model): boolean
	local who, at = Dummies.blame(model)
	return who ~= 0 and who ~= me and Workspace:GetServerTimeNow() - at < Dummies.BLAME_TIME
end

-- Parts of someone else's build: ghosts while they move (a frozen build is just walls and floors).
local function watchBuildPart(part: Instance, folder: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local owner = folder:GetAttribute("Owner")
	if owner == me then
		return
	end
	local function update()
		ghost(part, not part.Anchored)
	end
	part:GetPropertyChangedSignal("Anchored"):Connect(update)
	update()
end

function Ghosts.start()
	task.spawn(function()
		local builds = Workspace:WaitForChild("Builds")
		local function watchFolder(folder: Instance)
			if not folder:IsA("Folder") then
				return
			end
			folder.DescendantAdded:Connect(function(d)
				watchBuildPart(d, folder)
			end)
			for _, d in folder:GetDescendants() do
				watchBuildPart(d, folder)
			end
		end
		builds.ChildAdded:Connect(watchFolder)
		for _, folder in builds:GetChildren() do
			watchFolder(folder)
		end
	end)
	task.spawn(function()
		local dummies = Workspace:WaitForChild("Dummies")
		local ghosted: { [Model]: boolean } = {}
		local function refresh(model: Model)
			local on = sentByOther(model)
			if on ~= (ghosted[model] == true) then
				ghosted[model] = on or nil
				ghostModel(model, on)
			end
		end
		-- The moment someone else is blamed for a dummy it is a ghost here (no window in which a
		-- dummy just launched next to you is still solid); the loop below only ends it.
		local function watchDummy(model: Instance)
			if model:IsA("Model") then
				model.AttributeChanged:Connect(function(name)
					if BLAME_ATTRIBUTES[name] then
						refresh(model)
					end
				end)
				refresh(model)
			end
		end
		dummies.ChildAdded:Connect(watchDummy)
		for _, model in dummies:GetChildren() do
			watchDummy(model)
		end
		while true do
			for model in ghosted do
				if model.Parent then
					refresh(model)
				end
			end
			for model in ghosted do
				if not model.Parent then
					ghosted[model] = nil
				end
			end
			for part in original do
				if not part.Parent then
					original[part] = nil
				end
			end
			task.wait(CHECK)
		end
	end)
end

return Ghosts
