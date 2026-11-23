--!strict
-- V6-3: director mode for filming TikToks (the owner films this screen with a phone, so it all
-- reads in 9:16). Owner only (player attribute IsOwner from AdminService; every server action is
-- checked there again). Config.DIRECTOR.
--   F8          director mode on/off: every game UI hidden, the director panel and a 9:16 frame
--   H           REC: the panel and frame lines hide, the sides go black (film the middle)
--   cameras     FREE (WASD/QE fly, hold the right mouse button to look, wheel = speed), ORBIT and
--               FOLLOW the picked body (click a dummy or a player to pick it), DRONE (top down),
--               FIRST (your own eyes), PATH (2-6 points: P adds the view, ENTER plays it)
--   lens        FOV -/+, depth of field, shake on/off
--   time        1x / 0.5x / 0.25x / 0.1x / FREEZE on this screen (SlowMotion bubbles round the view)
--   actions     spawn a row / ring / tower, launch the picked dummy, start an event, reset all,
--               replay the last 10 s with this camera
--   presets     1-5 load a shot (camera, lens, time), Shift+1-5 saves it (kept for every server)
--   one-tap     CANNON, CAR ROW, SPIDER, GORILLA, TOWER THROW, MEGA BOMB: set up, framed, played

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config")) :: any
local Net = require(Shared:WaitForChild("Net"))
local Events = require(Shared:WaitForChild("Events")) :: any

local Client = script.Parent

local Director = {}

Director.KEY = Enum.KeyCode.F8
Director.HIDE_KEY = Enum.KeyCode.H
Director.PATH_MAX = 6
Director.PATH_TIME = 6 -- s a camera path takes
Director.SPEEDS = { 8, 20, 45, 90 } -- studs/s free-fly (the wheel steps)
Director.TIMES = { { "1x", 1 }, { "0.5x", 0.5 }, { "0.25x", 0.25 }, { "0.1x", 0.1 }, { "FREEZE", 0.01 } }
Director.SHOTS = { { "CANNON", "Cannon" }, { "CAR ROW", "CarRow" }, { "SPIDER", "Spider" }, { "GORILLA", "Gorilla" }, { "TOWER", "Tower" }, { "MEGA BOMB", "MegaBomb" } }
Director.ASPECT = 9 / 16

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local on = false
local rec = false
local frameOn = true
local mode = "Free"
local target: Model? = nil
local speedIndex = 2
local fov = 70
local dofOn = false
local shakeOn = false
local slow = 1
local camCF = CFrame.new()
local yaw, pitch = 0, 0
local orbitAngle = 0
local path: { CFrame } = {}
local pathStart: number? = nil
local presets: { any } = {}
local eventIndex = 1
local hiddenGuis: { [ScreenGui]: boolean } = {} -- (each gui: was it on when first seen)
local hiddenBoards: { [BillboardGui]: boolean } = {} -- (the same for the signs)
local gui: ScreenGui? = nil
local panel: Frame? = nil
local bars: { Frame } = {}
local border: Frame? = nil
local status: TextLabel? = nil
local dof: DepthOfFieldEffect? = nil
local savedType: Enum.CameraType = Enum.CameraType.Custom
local remote: RemoteEvent? = nil
local savedFov = 70
local savedMouse: Enum.MouseBehavior = Enum.MouseBehavior.Default
local presetsIn = false -- (the stored presets have arrived from the server)
local boardSweep = 0
local pokeOff = false -- (director mode keeps the weapons off)
local pokeWas = true
local Poke: any = nil -- (PokeController, required at start)
local Slow: any = nil -- (SlowMotion, required at start)
local sweepBoards: () -> ()
local readMove: () -> Vector3

local function send(kind: string, arg: any?)
	if remote then
		remote:FireServer(kind, arg)
	end
end

local function isOwner(): boolean
	return player:GetAttribute("IsOwner") == true
end

local function rootPos(m: Model?): Vector3?
	if not m or not m.Parent then
		return nil
	end
	local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
	return if r and r:IsA("BasePart") then r.Position else m:GetPivot().Position
end

local function say(text: string)
	if status then
		status.Text = text
	end
end

------------------------------------------------------------------------------------------------
-- The panel (a plain, small owner tool on the left; hidden while recording)

local function makeButton(parent: Instance, text: string, w: number, fn: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 30)
	b.BackgroundColor3 = Color3.fromRGB(38, 42, 52)
	b.TextColor3 = Color3.fromRGB(235, 238, 245)
	b.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	b.TextSize = 14
	b.Text = text
	b.AutoButtonColor = true
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	b.Parent = parent
	b.Activated:Connect(fn)
	return b
end

local function row(parent: Instance, order: number): Frame
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.LayoutOrder = order
	local l = Instance.new("UIGridLayout")
	l.CellSize = UDim2.fromOffset(82, 30)
	l.CellPadding = UDim2.fromOffset(4, 4)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = f
	f.Parent = parent
	return f
end

local function title(parent: Instance, text: string, order: number)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 18)
	t.Text = text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = Color3.fromRGB(255, 196, 70)
	t.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	t.TextSize = 13
	t.LayoutOrder = order
	t.Parent = parent
end

local function drawFrame()
	local g = gui
	if not g then
		return
	end
	local size = g.AbsoluteSize
	local w = math.floor(size.Y * Director.ASPECT)
	local side = math.max(0, (size.X - w) / 2)
	bars[1].Size = UDim2.fromOffset(side, size.Y)
	bars[1].Position = UDim2.fromOffset(0, 0)
	bars[2].Size = UDim2.fromOffset(side, size.Y)
	bars[2].Position = UDim2.fromOffset(side + w, 0)
	for _, b in bars do
		b.Visible = frameOn or rec
		b.BackgroundTransparency = if rec then 0 else 0.55
	end
	if border then
		border.Size = UDim2.fromOffset(w, size.Y)
		border.Position = UDim2.fromOffset(side, 0)
		border.Visible = frameOn and not rec
	end
	if panel then
		panel.Visible = not rec
	end
end


local function buildGui()
	local g = Instance.new("ScreenGui")
	g.Name = "Director"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 200
	g.Enabled = false
	for i = 1, 2 do
		local b = Instance.new("Frame")
		b.Name = "Bar" .. i
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderSizePixel = 0
		b.Parent = g
		bars[i] = b
	end
	local bd = Instance.new("Frame")
	bd.Name = "SafeFrame"
	bd.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.4
	stroke.Thickness = 2
	stroke.Parent = bd
	bd.Parent = g
	border = bd
	local p = Instance.new("ScrollingFrame")
	p.Name = "Panel"
	p.Position = UDim2.fromOffset(10, 10)
	p.Size = UDim2.new(0, 268, 1, -20)
	p.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
	p.BackgroundTransparency = 0.1
	p.BorderSizePixel = 0
	p.ScrollBarThickness = 4
	p.AutomaticCanvasSize = Enum.AutomaticSize.Y
	p.CanvasSize = UDim2.new()
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 10)
	pc.Parent = p
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = p
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 5)
	list.Parent = p
	local o = 0
	local function n(): number
		o += 1
		return o
	end
	local st = Instance.new("TextLabel")
	st.BackgroundTransparency = 1
	st.Size = UDim2.new(1, 0, 0, 34)
	st.TextWrapped = true
	st.TextXAlignment = Enum.TextXAlignment.Left
	st.TextColor3 = Color3.fromRGB(190, 200, 215)
	st.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
	st.TextSize = 12
	st.Text = "DIRECTOR  F8 off, H rec. Click a body to pick it."
	st.LayoutOrder = n()
	st.Parent = p
	status = st
	title(p, "CAMERA", n())
	local cams = row(p, n())
	for _, m in { "Free", "Orbit", "Follow", "Drone", "First", "Path" } do
		makeButton(cams, string.upper(m), 82, function()
			Director.setMode(m)
		end)
	end
	title(p, "PATH (P adds the view, ENTER plays)", n())
	local pr = row(p, n())
	makeButton(pr, "ADD", 82, function()
		Director.addPoint()
	end)
	makeButton(pr, "CLEAR", 82, function()
		path = {}
		say("Path cleared")
	end)
	makeButton(pr, "PLAY", 82, function()
		Director.playPath()
	end)
	title(p, "LENS", n())
	local lens = row(p, n())
	makeButton(lens, "FOV -", 82, function()
		fov = math.clamp(fov - 10, 20, 110)
		say("FOV " .. fov)
	end)
	makeButton(lens, "FOV +", 82, function()
		fov = math.clamp(fov + 10, 20, 110)
		say("FOV " .. fov)
	end)
	makeButton(lens, "DOF", 82, function()
		dofOn = not dofOn
		say("Depth of field " .. (if dofOn then "on" else "off"))
	end)
	makeButton(lens, "SHAKE", 82, function()
		shakeOn = not shakeOn
		say("Shake " .. (if shakeOn then "on" else "off"))
	end)
	makeButton(lens, "9:16", 82, function()
		frameOn = not frameOn
		drawFrame()
	end)
	title(p, "TIME (this screen)", n())
	local tm = row(p, n())
	for _, t in Director.TIMES do
		makeButton(tm, t[1], 82, function()
			Director.setSlow(t[2])
		end)
	end
	title(p, "ACTIONS", n())
	local ac = row(p, n())
	makeButton(ac, "ROW x5", 82, function()
		send("Spawn", { count = 5, shape = "Row" })
	end)
	makeButton(ac, "RING x10", 82, function()
		send("Spawn", { count = 10, shape = "Ring" })
	end)
	makeButton(ac, "TOWER x5", 82, function()
		send("Spawn", { count = 5, shape = "Tower" })
	end)
	makeButton(ac, "LAUNCH", 82, function()
		if target and target.Parent and target.Parent == Workspace:FindFirstChild("Dummies") then
			send("LaunchDummy", target)
		else
			say("Pick a dummy first (click it)")
		end
	end)
	local evButton: TextButton
	evButton = makeButton(ac, "EVENT >", 82, function()
		local e = Events.list[eventIndex]
		if e then
			send("Event", e.id)
			say("Event: " .. e.name)
		end
		eventIndex = eventIndex % #Events.list + 1
		local nx = Events.list[eventIndex]
		evButton.Text = if nx then string.upper(string.sub(nx.name, 1, 9)) else "EVENT"
	end)
	makeButton(ac, "RESET ALL", 82, function()
		send("ClearDummies")
		task.delay(0.6, function()
			send("ReviveAll")
		end)
		Director.setSlow(1)
		say("Reset")
	end)
	--[[ (no replays)
	makeButton(ac, "REPLAY 2s", 82, function() -- (the X-ray replay keeps the last 2 s round a moment)
		local ok, Replay = pcall(function()
			return require(Client:WaitForChild("ReplayController")) :: any
		end)
		if ok then
			task.spawn(Replay.play, os.clock() - 1.7)
		end
	end)
	]]
	title(p, "ONE-TAP SHOTS", n())
	local sh = row(p, n())
	for _, s in Director.SHOTS do
		makeButton(sh, s[1], 82, function()
			Director.shot(s[2])
		end)
	end
	title(p, "PRESETS (1-5 load, Shift+1-5 save)", n())
	local ps = row(p, n())
	for i = 1, 5 do
		makeButton(ps, "LOAD " .. i, 82, function()
			Director.loadPreset(i)
		end)
	end
	p.Parent = g
	panel = p
	g:GetPropertyChangedSignal("AbsoluteSize"):Connect(drawFrame)
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
end

------------------------------------------------------------------------------------------------
-- Cameras

function Director.setMode(m: string)
	mode = m
	pathStart = nil
	if m == "Free" then
		local look = camCF.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(math.clamp(look.Y, -1, 1))
	end
	if (m == "Orbit" or m == "Follow") and not target then
		say("Pick a body first (click it), then " .. string.upper(m))
	else
		say("Camera: " .. string.upper(m))
	end
end

function Director.addPoint()
	if #path >= Director.PATH_MAX then
		table.remove(path, 1)
	end
	table.insert(path, camCF)
	say(string.format("Path point %d/%d", #path, Director.PATH_MAX))
end

function Director.playPath()
	if #path < 2 then
		say("A path needs 2 points (P adds the view)")
		return
	end
	mode = "Path"
	pathStart = os.clock()
	say("Playing the path")
end

-- Catmull-Rom through the path's positions, looks blended, eased in and out.
local function pathAt(t: number): CFrame
	local n = #path
	local e = t * t * (3 - 2 * t)
	local f = e * (n - 1)
	local i = math.clamp(math.floor(f) + 1, 1, n - 1)
	local u = f - (i - 1)
	local p0 = path[math.max(1, i - 1)].Position
	local p1 = path[i].Position
	local p2 = path[i + 1].Position
	local p3 = path[math.min(n, i + 2)].Position
	local pos = 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u * u * u)
	local rot = path[i].Rotation:Lerp(path[i + 1].Rotation, u)
	return CFrame.new(pos) * rot
end

local looking = false

local function step(dt: number)
	if not on then
		return
	end
	local speed = Director.SPEEDS[speedIndex]
	local focus: Vector3? = rootPos(target)
	if mode == "Free" then
		local rot = CFrame.fromOrientation(pitch, yaw, 0)
		camCF = CFrame.new(camCF.Position + rot:VectorToWorldSpace(readMove()) * speed * dt) * rot
	elseif mode == "Orbit" and focus then
		orbitAngle += dt * 0.35
		local at = focus + Vector3.new(math.cos(orbitAngle) * 22, 7, math.sin(orbitAngle) * 22)
		camCF = CFrame.lookAt(at, focus)
	elseif mode == "Follow" and focus then
		local want = CFrame.lookAt(focus + Vector3.new(0, 8, 18), focus)
		camCF = camCF:Lerp(want, math.clamp(dt * 3, 0, 1))
	elseif mode == "Drone" then
		local c = focus or (camCF.Position - Vector3.new(0, camCF.Position.Y, 0))
		camCF = camCF:Lerp(CFrame.lookAt(c + Vector3.new(0, 70, 0.01), c), math.clamp(dt * 2, 0, 1))
	elseif mode == "First" then
		local head = player.Character and player.Character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			camCF = head.CFrame * CFrame.new(0, 0.2, -0.6)
		end
	elseif mode == "Path" and pathStart and #path >= 2 then
		local t = math.clamp((os.clock() - pathStart) / Director.PATH_TIME, 0, 1)
		camCF = pathAt(t)
		if t >= 1 then
			pathStart = nil
			say("Path done")
		end
	end
	-- (Some HUD pieces switch themselves back on every frame: kept off while directing.)
	-- (Review fix: each gui's own state is noted the first time it is seen and put back exactly so
	-- on the way out; a gui the game switched off meanwhile is never forced back on.)
	local pg = player:FindFirstChild("PlayerGui")
	for _, g in if pg then pg:GetChildren() else {} do
		if g:IsA("ScreenGui") and g ~= gui then
			if hiddenGuis[g] == nil then
				hiddenGuis[g] = g.Enabled
			end
			if g.Enabled then
				g.Enabled = false
			end
		end
	end
	-- (New signs in the world, a new body's tag, a guest's bubble: hidden as they come, once a second.)
	boardSweep += dt
	if boardSweep > 1 then
		boardSweep = 0
		sweepBoards()
	end
	-- (Anything that switched the weapons back on (a replay ending) is switched off again.)
	if pokeOff and Poke and Poke.isEnabled() then
		Poke.setEnabled(false)
	end
	local cf = camCF
	if shakeOn then
		local k = os.clock() * 7
		cf = cf * CFrame.Angles(math.noise(k, 1) * 0.012, math.noise(k, 2) * 0.012, math.noise(k, 3) * 0.006)
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cf
	camera.FieldOfView = fov
	local d = dof
	if d then
		d.Enabled = dofOn
		if dofOn then
			d.FocusDistance = if focus then (focus - cf.Position).Magnitude else 25
			d.InFocusRadius = 8
			d.FarIntensity = 0.6
			d.NearIntensity = 0.4
		end
	end
	-- (Slow time on this screen: one lasting bubble that follows what the camera looks at.)
	if slow < 1 and Slow then
		Slow.SCALE = slow
		Slow.director(focus or (cf.Position + cf.LookVector * 30), 90)
	end
end

function Director.setSlow(s: number)
	slow = s
	if Slow then
		if s < 1 then
			Slow.SCALE = s
		else
			Slow.director(nil) -- (gone at once: "normal" is normal)
			Slow.SCALE = (Config.SLOWMO_SCALE :: number?) or 0.25
		end
	end
	say(if s >= 1 then "Time: normal" elseif s <= 0.02 then "Time: FROZEN" else "Time: " .. s .. "x")
end

------------------------------------------------------------------------------------------------
-- Presets and one-tap shots

local function cfToList(cf: CFrame): { number }
	return { cf:GetComponents() }
end

-- (Review fix: one slot at a time, merged on the server, and only once the stored ones have
-- arrived: a save never wipes the other four.)
function Director.savePreset(i: number)
	if not presetsIn then
		send("DirectorGet")
		say("Presets are still loading: try again in a moment")
		return
	end
	local p = { c = cfToList(camCF), fov = fov, slow = math.max(0.05, slow) }
	presets[i] = p
	send("DirectorSave", { slot = i, preset = p })
	say("Preset " .. i .. " saved")
end

function Director.loadPreset(i: number)
	local p = presets[i]
	if type(p) ~= "table" then
		say("Preset " .. i .. " is empty (Shift+" .. i .. " saves the view)")
		return
	end
	camCF = CFrame.new(table.unpack(p.c))
	fov = p.fov
	Director.setMode("Free")
	Director.setSlow(p.slow)
	say("Preset " .. i)
end

-- Where each one-tap shot puts the camera, from the point the server set it up at.
local SHOT_VIEW: { [string]: (Vector3, Vector3?) -> (CFrame, string, number) } = {
	Cannon = function(at, to)
		-- (Behind the cannon and a little to the side, looking up the flight: the arc fills 9:16.)
		if to then
			local flat = Vector3.new(to.X - at.X, 0, to.Z - at.Z)
			local dir = if flat.Magnitude > 1 then flat.Unit else Vector3.new(1, 0, 0)
			local side = dir:Cross(Vector3.yAxis)
			local mid = at:Lerp(to, 0.5) + Vector3.new(0, 22, 0)
			return CFrame.lookAt(at - dir * 20 + side * 9 + Vector3.new(0, 9, 0), mid), "Free", 0.5
		end
		return CFrame.lookAt(at + Vector3.new(-26, 8, 18), at + Vector3.new(30, 18, 0)), "Free", 0.5
	end,
	CarRow = function(at, to)
		if to then
			local dir = Vector3.new(to.X - at.X, 0, to.Z - at.Z).Unit
			local side = dir:Cross(Vector3.yAxis)
			-- (Low at the end of the row, looking back along it toward the car coming.)
			return CFrame.lookAt(at + side * 18 + dir * 6 + Vector3.new(0, 3, 0), at - dir * 30), "Free", 0.5
		end
		return CFrame.lookAt(at + Vector3.new(16, 3, 10), at), "Free", 0.5
	end,
	Spider = function(at)
		return CFrame.lookAt(at + Vector3.new(0, 10, 24), at + Vector3.new(0, 6, 0)), "Free", 1
	end,
	Gorilla = function(at)
		return CFrame.lookAt(at + Vector3.new(30, 14, 30), at), "Free", 1
	end,
	Tower = function(at, to)
		if to then
			local dir = Vector3.new(to.X - at.X, 0, to.Z - at.Z).Unit
			local side = dir:Cross(Vector3.yAxis)
			-- (From the side, framing the drop from the top down to where they land.)
			return CFrame.lookAt(at + side * 34 + dir * 12 - Vector3.new(0, 16, 0), at + dir * 14 - Vector3.new(0, 16, 0)), "Free", 0.5
		end
		return CFrame.lookAt(at + Vector3.new(22, -18, 30), at), "Free", 0.5
	end,
	MegaBomb = function(at)
		return CFrame.lookAt(at + Vector3.new(0, 30, 60), at), "Free", 1
	end,
}

function Director.shot(id: string)
	send("Shot", id)
	say("Setting up: " .. id)
end

local function onFocus(data: any)
	local id = data.shot
	local at = data.at
	local view = SHOT_VIEW[id]
	if not view or typeof(at) ~= "Vector3" then
		return
	end
	local cf, m, s = view(at, if typeof(data.to) == "Vector3" then data.to else nil)
	camCF = cf
	Director.setMode(m)
	Director.setSlow(1)
	-- (The big moment plays slowed a beat after it starts.)
	if s < 1 then
		task.delay(0.8, function()
			if on then
				Director.setSlow(s)
			end
		end)
	end
	if id == "MegaBomb" then
		task.delay(2.5, function()
			if on then
				Director.setSlow(0.25)
			end
		end)
	end
	say("Shot: " .. id .. " (RESET ALL clears it)")
end

------------------------------------------------------------------------------------------------
-- On and off

sweepBoards = function()
	for _, d in Workspace:GetDescendants() do
		if d:IsA("BillboardGui") and hiddenBoards[d] == nil then
			hiddenBoards[d] = d.Enabled
			d.Enabled = false
		end
	end
	local pg = player:FindFirstChild("PlayerGui")
	for _, d in if pg then pg:GetDescendants() else {} do
		if d:IsA("BillboardGui") and hiddenBoards[d] == nil then
			hiddenBoards[d] = d.Enabled
			d.Enabled = false
		end
	end
end

local function hideGameUi(hide: boolean)
	if hide then
		hiddenGuis = {}
		hiddenBoards = {}
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, false)
		sweepBoards() -- (the signs in the world too: a clean shot shows the bodies, not labels)
	else
		-- (Every gui and sign back exactly as it was when first seen: never forced on.)
		for g, was in hiddenGuis do
			if g.Parent then
				g.Enabled = was
			end
		end
		hiddenGuis = {}
		for d, was in hiddenBoards do
			if d.Parent then
				d.Enabled = was
			end
		end
		hiddenBoards = {}
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, true)
	end
end

-- The fly keys only stop the character walking; where the camera goes is read from the keys that
-- are down each frame (a key held while turning on, or lost on alt-tab, never drifts).
local function sinkMove(_: string, _state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	return Enum.ContextActionResult.Sink
end
local FLY = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1), [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0), [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
	[Enum.KeyCode.E] = Vector3.new(0, 1, 0), [Enum.KeyCode.Q] = Vector3.new(0, -1, 0),
}
readMove = function(): Vector3
	if UserInputService:GetFocusedTextBox() then
		return Vector3.zero
	end
	local v = Vector3.zero
	for k, dir in FLY do
		if UserInputService:IsKeyDown(k) then
			v += dir
		end
	end
	return v
end

function Director.toggle(want: boolean?)
	local next = if want == nil then not on else want
	if next == on then
		return
	end
	if next and not isOwner() then
		return
	end
	on = next
	local g = gui
	if not g then
		return
	end
	if on then
		-- (A Scriptable camera now (a replay, a cut scene) comes back as the normal one.)
		savedType = if camera.CameraType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else camera.CameraType
		savedFov = camera.FieldOfView
		savedMouse = UserInputService.MouseBehavior
		camCF = camera.CFrame
		fov = camera.FieldOfView
		Director.setMode("Free")
		rec = false
		hideGameUi(true)
		g.Enabled = true
		drawFrame()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- (the panel must be clickable)
		ContextActionService:BindActionAtPriority("DirectorMove", sinkMove, false, Enum.ContextActionPriority.High.Value + 50, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)
		pokeWas = if Poke then Poke.isEnabled() else true
		pokeOff = true
		if Poke then
			Poke.setEnabled(false)
		end
		local d = Instance.new("DepthOfFieldEffect")
		d.Name = "DirectorDOF"
		d.Enabled = false
		d.Parent = Lighting
		dof = d
		RunService:BindToRenderStep("Director", Enum.RenderPriority.Last.Value + 60, step)
		send("DirectorGet")
	else
		RunService:UnbindFromRenderStep("Director")
		ContextActionService:UnbindAction("DirectorMove")
		if dof then
			dof:Destroy()
			dof = nil
		end
		Director.setSlow(1)
		g.Enabled = false
		hideGameUi(false)
		camera.CameraType = savedType
		camera.FieldOfView = savedFov
		UserInputService.MouseBehavior = savedMouse
		pokeOff = false
		if Poke and pokeWas then
			Poke.setEnabled(true) -- (only if it was on before: build mode and onboarding keep theirs)
		end
	end
end

function Director.isOn(): boolean
	return on
end

local function pick(at: Vector2)
	local ray = camera:ViewportPointToRay(at.X, at.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {}
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	local m = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	while m and m.Parent and m.Parent ~= Workspace and m.Parent ~= Workspace:FindFirstChild("Dummies") do
		local up = m.Parent:FindFirstAncestorOfClass("Model")
		if not up then
			break
		end
		m = up
	end
	if m and m:FindFirstChildOfClass("Humanoid") then
		target = m
		say("Picked: " .. m.Name .. " (ORBIT / FOLLOW / LAUNCH)")
	end
end

function Director.start()
	if not Config.DIRECTOR then
		return
	end
	remote = Net.event(Net.Names.Admin)
	buildGui()
	Poke = require(Client:WaitForChild("PokeController")) :: any
	local okSlow, sm = pcall(function()
		return require(Client:WaitForChild("SlowMotion")) :: any
	end)
	Slow = if okSlow then sm else nil
	;(remote :: RemoteEvent).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "DirectorFocus" and type(data) == "table" then
			onFocus(data)
		elseif kind == "Notice" and on and type(data) == "string" then
			say(data) -- (a refusal shows on the panel: the toasts are hidden while directing)
		elseif kind == "DirectorPresets" and type(data) == "table" then
			presets = {}
			for i = 1, 5 do
				local p = (data :: any)[i]
				presets[i] = if type(p) == "table" then p else false
			end
			presetsIn = true
		end
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if input.KeyCode == Director.KEY then
			Director.toggle()
			return
		end
		if not on or processed or UserInputService:GetFocusedTextBox() then -- (typing in chat never directs)
			return
		end
		if input.KeyCode == Director.HIDE_KEY then
			rec = not rec
			drawFrame()
		elseif input.KeyCode == Enum.KeyCode.P then
			Director.addPoint()
		elseif input.KeyCode == Enum.KeyCode.Return then
			Director.playPath()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = true
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			pick(Vector2.new(input.Position.X, input.Position.Y))
		else
			local nums = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
			local i = table.find(nums, input.KeyCode)
			if i then
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					Director.savePreset(i)
				else
					Director.loadPreset(i)
				end
			end
		end
	end)
	-- (Studio only: "DevDirector" toggles it, "DevDirectorRec" the REC view, for the captures.)
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DevDirector"):Connect(function()
			Director.toggle(player:GetAttribute("DevDirector") == true)
		end)
		player:GetAttributeChangedSignal("DevShot"):Connect(function()
			local s = player:GetAttribute("DevShot")
			if type(s) == "string" and s ~= "" then
				Director.shot(s)
			end
		end)
		player:GetAttributeChangedSignal("DevDirectorRec"):Connect(function()
			rec = player:GetAttribute("DevDirectorRec") == true
			drawFrame()
		end)
	end
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and looking then
			looking = false
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject, processed: boolean)
		if not on or processed or UserInputService:GetFocusedTextBox() then -- (typing in chat never directs)
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement and looking and mode == "Free" then
			yaw -= input.Delta.X * 0.004
			pitch = math.clamp(pitch - input.Delta.Y * 0.004, -1.45, 1.45)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			speedIndex = math.clamp(speedIndex + (if input.Position.Z > 0 then 1 else -1), 1, #Director.SPEEDS)
			say("Fly speed " .. Director.SPEEDS[speedIndex])
		end
	end)
end


return Director
