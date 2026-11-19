--!strict
-- Store video (trailer), the SERVER half. Studio only, in Play (solo), never live.
-- Run it with the Studio MCP's run_code on the SERVER while TrailerCam.luau runs on the CLIENT.
-- It directs ~30 s of real gameplay in your own lab and on two maps. Each shot sets
-- Workspace "TrailerShot" (1..8) and "TrailerFocus" (where the camera should look) for the camera.
-- Nothing is saved; the lab resets after.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Systems = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Systems")
local Lab = require(Systems.Lab)
local EventService = require(Systems.EventService)
local DummyControl = require(Systems.DummyControl)
local SandboxService = require(Systems.SandboxService)
local WorldMaps = require(Systems.WorldMaps)

local player = Players:GetPlayers()[1]
assert(player, "Press Play first (solo)")
local origin = Lab.originFor(player)
local function at(x: number, y: number, z: number): Vector3
	return origin + Vector3.new(x, y, z)
end
local function shot(n: number, focus: Vector3)
	Workspace:SetAttribute("TrailerFocus", focus)
	Workspace:SetAttribute("TrailerShot", n)
end
local function dummies(): { Model }
	return Lab.dummiesOf(player)
end
local function fling(model: Model, velocity: Vector3)
	local pelvis = model:FindFirstChild("LowerTorso")
	if pelvis and pelvis:IsA("BasePart") then
		local mass = (model:GetAttribute("Mass") :: number?) or 10
		DummyControl.hit(model, pelvis, velocity * mass, pelvis.Position)
	end
end

Workspace:SetAttribute("Trailer", true)
-- 1. Wide orbit over the lab (4 s).
shot(1, at(0, 0, -10))
task.wait(4)
-- 2. The human cannon: two dummies fly over the lab onto the bullseye (4 s).
shot(2, at(48, 4, 6))
for i, d in dummies() do
	if i <= 2 then
		task.delay(0.4 * i, fling, d, Vector3.new(-40, 95, -20))
	end
end
task.wait(4)
-- 3. The car into the row of dummies (4 s).
shot(3, at(10, 2, -20))
local okCar, VehicleService = pcall(function()
	return require(Systems.VehicleService) :: any
end)
if okCar then
	for _, car in VehicleService.carsForTest() do
		if (car.origin - origin).Magnitude < 1 and car.kind == "Car" then
			local body = car.body
			local target = at(0, 0, -20)
			local start = os.clock()
			while os.clock() - start < 2.6 do
				local flat = Vector3.new(target.X - body.Position.X, 0, target.Z - body.Position.Z)
				if flat.Magnitude > 1 then
					body.CFrame = CFrame.lookAt(body.Position, body.Position + flat)
					body.AssemblyLinearVelocity = flat.Unit * 55 + Vector3.new(0, body.AssemblyLinearVelocity.Y, 0)
				end
				task.wait()
			end
			break
		end
	end
end
task.wait(1.2)
-- 4. Gorilla Rampage (5 s).
shot(4, at(0, 6, 40))
EventService.trigger("GorillaRampage", player.DisplayName, "Test", true, nil, player.UserId)
task.wait(5)
-- 5. Slow-mo over the lab with a blast in it (4 s).
shot(5, at(0, 3, -20))
SandboxService.run(player, "SlowMo")
task.wait(0.3)
for _, d in dummies() do
	fling(d, Vector3.new(math.random(-30, 30), 70, math.random(-30, 30)))
end
task.wait(3.7)
-- 6. Tornado (4 s).
shot(6, at(0, 10, -10))
EventService.trigger("Tornado", player.DisplayName, "Test", true, nil, player.UserId)
task.wait(4)
-- 7. Fly over Downtown, 8. the Island (4 s each).
for i, id in { "City", "Island" } do
	local ok = WorldMaps.travel(player, id)
	local arrival = WorldMaps.arrival(id, player)
	if ok and arrival then
		shot(6 + i, arrival.Position + Vector3.new(0, 4, -60))
		task.wait(4)
	end
end
-- Back home; the camera lets go.
WorldMaps.travel(player, "Lab")
Workspace:SetAttribute("TrailerShot", 0)
Workspace:SetAttribute("Trailer", nil)
print("[Trailer] done: stop the recording")
