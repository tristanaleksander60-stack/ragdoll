--!strict
-- V9-0e / Phase M (owner, 21 Nov 2026: "much nicer portals and a sign with the maps where you choose"):
--   * the player's lab has the Map Board and the gold PLACES portal, both in the spawn camera's view:
--     the board at 1920x1080 and on an upright 414x896 phone, the portal at 1920x1080 (the angle from a
--     camera 12 studs behind the spawn against half the screen's field of view);
--   * the gates' colours match their kind: PLACES gold, SINGLEPLAYER blue, MULTIPLAYER green;
--   * every open-air map has its own board (My lab first) and portal by the arrival;
--   * the board counts the players in each place;
--   * every place on the board travels, and back home;
--   * travel is refused while seated or holding a body.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Places = require(Shared:WaitForChild("Places")) :: any
local Systems = script.Parent.Parent:WaitForChild("Systems")

-- Seen from a camera CAMERA_BACK studs behind the spawn, at what angle (degrees) off the view's middle.
local CAMERA_BACK = 12
local function offAxis(spawn: Vector3, facing: Vector3, at: Vector3): number
	local camera = spawn - facing * CAMERA_BACK
	local d = Vector3.new(at.X - camera.X, 0, at.Z - camera.Z)
	return math.deg(math.acos(math.clamp(d.Unit:Dot(facing), -1, 1)))
end
-- Half the horizontal field of view on a screen (Roblox's vertical field of view: 70 degrees).
local function halfWidth(w: number, h: number): number
	return math.deg(math.atan(math.tan(math.rad(35)) * w / h))
end

local function runeColor(gate: Instance): Color3?
	for _, p in gate:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Rune" then
			return p.Color
		end
	end
	return nil
end

return {
	name = "T159_PlacesPortal",
	timeout = 90,
	run = function(): string?
		if not Config.MAP_BOARD then
			return "skipped (MAP_BOARD off)"
		end
		local MapBoard = require(Systems:WaitForChild("MapBoard")) :: any
		local Lab = require(Systems:WaitForChild("Lab")) :: any
		local WorldMaps = require(Systems:WaitForChild("WorldMaps")) :: any
		local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any
		TestLib.waitFor(function()
			local p = Players:GetPlayers()[1]
			return p ~= nil and p.Character ~= nil and Lab.plotIndex(p) ~= nil
		end, 20)
		local p = Players:GetPlayers()[1]
		if not p or not p.Character then
			return "skipped (no player with a lab)"
		end
		local results = {}
		-- In the spawn's view.
		local lab = Workspace.Playground:FindFirstChild("Lab" .. Lab.plotIndex(p))
		local place = lab and lab:FindFirstChild("MapPlace")
		local board = place and place:FindFirstChild("MapBoard")
		local gate = place and place:FindFirstChild("GatePlaces")
		-- (V9-NOW: MAP_PORTAL off = the board is the one map place; no gold portal anywhere.)
		local portal = Config.MAP_PORTAL == true
		assert(board, "the lab has no Map Board")
		assert(if portal then gate ~= nil else gate == nil, if portal then "the lab has no PLACES portal" else "the gold PLACES portal is still in the lab")
		local spawn = Lab.originFor(p)
		local facing = Lab.SPAWN_FACING
		local boardOff = offAxis(spawn, facing, (board :: Model):GetPivot().Position)
		local gateOff = if gate then offAxis(spawn, facing, (gate :: Model):GetPivot().Position) else 0
		-- (Fix round 1: the whole board, both edges, on an upright phone; not just its middle.)
		local bcf = (board :: Model):GetPivot()
		local half = MapBoard.SCREEN.X / 2
		for _, edge in { bcf.Position + bcf.RightVector * half, bcf.Position - bcf.RightVector * half } do
			local off = offAxis(spawn, facing, edge)
			assert(off < halfWidth(414, 896), string.format("an edge of the board is %.0f deg off the spawn view (upright phone half view %.0f)", off, halfWidth(414, 896)))
		end
		assert(boardOff < halfWidth(1920, 1080), string.format("the board is %.0f deg off the spawn view", boardOff))
		assert(not gate or gateOff < halfWidth(1920, 1080), string.format("the PLACES portal is %.0f deg off the spawn view (1920x1080 half view %.0f)", gateOff, halfWidth(1920, 1080)))
		local boardDistance = ((board :: Model):GetPivot().Position - spawn) * Vector3.new(1, 0, 1)
		assert(boardDistance.Magnitude > 18 and boardDistance.Magnitude < 30, string.format("the board is %.0f studs from the spawn (want 20-25)", boardDistance.Magnitude))
		table.insert(results, string.format("board %.0f deg off the view at %.0f studs, portal %.0f deg (phone half view %.0f, PC %.0f)", boardOff, boardDistance.Magnitude, gateOff, halfWidth(414, 896), halfWidth(1920, 1080)))
		-- Colours by kind.
		assert(not gate or runeColor(gate :: Model) == MapBoard.COLORS.Places, "the PLACES portal is not gold")
		for name, kind in { PortalSolo = "Solo", PortalMulti = "Multi" } do
			local g = lab:FindFirstChild(name)
			assert(g and g:GetAttribute("GateKind") == kind and runeColor(g) == MapBoard.COLORS[kind], name .. " is not in its ring colour")
		end
		table.insert(results, "PLACES gold, SINGLEPLAYER blue, MULTIPLAYER green")
		-- Every map's copy.
		local maps = 0
		for _, pl in Places.list do
			if pl.outdoor then
				local built = Workspace:FindFirstChild("Places") and (Workspace :: any).Places:FindFirstChild(pl.id)
				local copy = built and built:FindFirstChild("MapPlace")
				local copyBoard = copy and copy:FindFirstChild("MapBoard")
				local screen = copyBoard and copyBoard:FindFirstChild("Screen")
				assert(screen and screen:GetAttribute("Home") == true and (copy:FindFirstChild("GatePlaces") ~= nil) == portal, pl.id .. " has no board with My lab first, or its portal is wrong")
				maps += 1
			end
		end
		table.insert(results, maps .. " maps with their own board and portal")
		-- The counts.
		local screens = CollectionService:GetTagged("MapBoardScreen")
		assert(#screens >= 1 + maps, #screens .. " boards")
		-- Every place travels, and back home.
		local character = p.Character :: Model
		local home = character:GetPivot()
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		local ok, err = pcall(function()
			local went = {}
			for _, pl in Places.list do
				if pl.id ~= "Lab" then
					task.wait(Places.TRAVEL_GAP + 0.05)
					local done, why = WorldMaps.travel(p, pl.id)
					assert(done and p:GetAttribute("Place") == pl.id, pl.id .. " did not travel: " .. tostring(why))
					table.insert(went, pl.id)
					-- (The board counts the traveller there.)
					if #went == 1 then
						assert(TestLib.waitFor(function()
							return lab.MapPlace.MapBoard.Screen:GetAttribute("Count_" .. pl.id) == 1
						end, MapBoard.COUNT_EVERY + 2), "the board does not count the player in " .. pl.id)
					end
				end
			end
			task.wait(Places.TRAVEL_GAP + 0.05)
			local back = WorldMaps.travel(p, "Lab")
			assert(back and p:GetAttribute("Place") == "Lab", "the trip home failed")
			table.insert(results, "travelled to " .. table.concat(went, ", ") .. " and home; the board counted the player")
			-- (The maps visited go back to sleep now, as if left a while ago: later tests expect them empty.)
			pcall(function()
				local CrowdService = require(Systems:WaitForChild("CrowdService")) :: any
				for _, id in went do
					CrowdService.emptyForTest(id)
				end
			end)
			-- Refused while seated or holding a body.
			task.wait(Places.TRAVEL_GAP + 0.05)
			local seat = Instance.new("Seat")
			seat.Anchored = true
			seat.Size = Vector3.new(2, 1, 2)
			seat.CFrame = character:GetPivot() * CFrame.new(0, -2, 0)
			seat.Parent = Workspace
			seat:Sit(humanoid)
			TestLib.waitFor(function()
				return humanoid.SeatPart ~= nil
			end, 2)
			local why = WorldMaps.refusal(p, "Island")
			seat:Destroy()
			humanoid.Sit = false
			assert(why ~= nil, "travel was allowed from a seat")
			TestLib.waitFor(function()
				return humanoid.SeatPart == nil
			end, 3)
			task.wait(0.3)
			local dummy = (require(Systems:WaitForChild("DummyFactory")) :: any).spawn(character:GetPivot().Position + Vector3.new(6, 0, 0), character:GetPivot().Position, p)
			dummy:SetAttribute("SimulatedBy", p.UserId)
			dummy:SetAttribute("Held", true)
			local whyHeld = WorldMaps.refusal(p, "Island")
			dummy:Destroy()
			assert(whyHeld == "Let go first", "travel was allowed holding a body: " .. tostring(whyHeld))
			table.insert(results, "refused from a seat (" .. tostring(why) .. ") and holding a body")
			-- (Fix round 1) Stepping into the gold portal: standing in it DWELL s opens the maps; a loose
			-- body in it opens nothing.
			if not gate then
				table.insert(results, "no gold portal (MAP_PORTAL off): the board is the one map place")
				return
			end
			local swirl = (gate :: Model):WaitForChild("Swirl") :: BasePart
			assert(swirl and not swirl.CanTouch, "the PLACES swirl still takes touches")
			local joinedWas = p:GetAttribute("V8JoinedAt")
			p:SetAttribute("V8JoinedAt", workspace:GetServerTimeNow() - 600) -- (past a newcomer's quiet start)
			local stand = swirl.CFrame * CFrame.new(0, 0, 0)
			character:PivotTo(CFrame.new(stand.Position.X, stand.Position.Y - 2, stand.Position.Z))
			local root = character:WaitForChild("HumanoidRootPart") :: BasePart
			root.Anchored = true
			task.wait(0.2)
			assert(MapBoard.insideSwirl(swirl, root.Position), "standing in the swirl does not count as in it")
			character:SetAttribute("BodyLoose", true)
			local opened0 = MapBoard.lastOpenForTest(p)
			for _ = 1, 6 do
				MapBoard.pollForTest()
				task.wait(MapBoard.POLL)
			end
			assert(MapBoard.lastOpenForTest(p) == opened0, "a loose body in the portal opened the maps")
			character:SetAttribute("BodyLoose", nil)
			for _ = 1, 6 do
				MapBoard.pollForTest()
				task.wait(MapBoard.POLL)
			end
			root.Anchored = false
			p:SetAttribute("V8JoinedAt", joinedWas)
			assert(MapBoard.lastOpenForTest(p) ~= opened0, "standing in the portal did not open the maps")
			table.insert(results, "stepping in opens the maps after " .. MapBoard.DWELL .. " s; a loose body does not")
		end)
		character:PivotTo(home)
		assert(ok, err)
		return table.concat(results, "; ")
	end,
}
