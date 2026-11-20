--!strict
-- Instant Replay: records dummies and props near the camera at 30 Hz (client only) and plays a
-- short window back in slow motion from a low orbiting camera, on anchored local clones.
-- Physics cannot be slowed down on Roblox, so replay = playback of recorded CFrames.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Keybinds = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Keybinds"))
local KitStyle = require(script.Parent:WaitForChild("KitStyle"))
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme"))
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ShareCode = require(Shared:WaitForChild("ShareCode"))
local Toys = require(Shared:WaitForChild("Toys"))

local ReplayController = {}

-- (V8-1.7, phone diet: 15 a second on a touch screen without keys; 30 elsewhere.)
local UIS_ = game:GetService("UserInputService")
local RECORD_HZ = if UIS_.TouchEnabled and not UIS_.KeyboardEnabled then 15 else 30
local KEEP_SECONDS = 8
local RANGE = 120 -- studs from the camera
local SPEED = 0.3 -- playback speed
local BEFORE = 0.3 -- seconds of footage before the event
local AFTER = 1.7 -- seconds after it

type Frame = { t: number, cfs: { [BasePart]: CFrame } }

local CaptureService = game:GetService("CaptureService")

local frames: { Frame } = {}
local recording = false
local templates: { [Instance]: Instance } = setmetatable({}, { __mode = "k" }) :: any
local lastSample = 0
local playing = false
local skipRequested = false

-- Called by others: replay started / finished (to hide and show their UI).
ReplayController.onStateChanged = nil :: ((playing: boolean) -> ())?
-- Phase 1 (X-ray replay): the toy in hand (set by Main: PokeController.getSelected) and who hears
-- the replay's score (ExperimentCard.scored: a friend's code beaten).
ReplayController.currentToy = nil :: (() -> string)?
ReplayController.onScore = nil :: ((score: number) -> ())?
ReplayController.lastCode = nil :: string?

-- The bodies' limbs that get a bone in the X-ray look.
local BONES: { [string]: boolean } = {
	Head = true, UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, RightUpperArm = true, RightLowerArm = true,
	LeftUpperLeg = true, LeftLowerLeg = true, RightUpperLeg = true, RightLowerLeg = true,
}
local XRAY_SKIN = Color3.fromRGB(120, 200, 255)

-- Phase 1: see-through bodies with a white bone in each limb (copies only; the world is untouched).
local function xray(map: { [BasePart]: BasePart }, folder: Instance)
	for _, copy in map do
		if BONES[copy.Name] then
			copy.Color = XRAY_SKIN
			copy.Material = Enum.Material.Glass
			copy.Transparency = 0.6
			for _, d in copy:GetDescendants() do
				if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") then
					d:Destroy()
				end
			end
			if copy:IsA("MeshPart") then
				copy.TextureID = ""
			end
			local bone = Instance.new("Part")
			bone.Name = "XrayBone"
			bone.Shape = Enum.PartType.Cylinder
			local long = math.max(copy.Size.X, copy.Size.Y, copy.Size.Z)
			bone.Size = Vector3.new(long * 0.8, 0.22, 0.22)
			bone.CFrame = copy.CFrame * CFrame.Angles(0, 0, math.rad(90))
			bone.Color = Color3.new(1, 1, 1)
			bone.Material = Enum.Material.Neon
			bone.CanCollide = false
			bone.CanQuery = false
			bone.CanTouch = false
			bone.Massless = true
			bone.CastShadow = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = copy
			weld.Part1 = bone
			weld.Parent = bone
			bone.Parent = folder
		end
	end
end

local function sources(): { Instance }
	local list = {}
	local dummies = Workspace:FindFirstChild("Dummies")
	if dummies then
		for _, m in dummies:GetChildren() do
			table.insert(list, m)
		end
	end
	local props = Workspace:FindFirstChild("Props")
	if props then
		for _, p in props:GetChildren() do
			table.insert(list, p)
		end
	end
	return list
end

local function partsOf(root: Instance): { BasePart }
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function record(now: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local origin = camera.CFrame.Position
	local cfs: { [BasePart]: CFrame } = {}
	for _, src in sources() do
		local probe: BasePart? = if src:IsA("BasePart") then src else (src:FindFirstChildWhichIsA("BasePart", true))
		if probe and (probe.Position - origin).Magnitude < RANGE then
			if not templates[src] then
				local ok, copy = pcall(function()
					return src:Clone()
				end)
				if ok and copy then
					templates[src] = copy
				end
			end
			for _, part in partsOf(src) do
				cfs[part] = part.CFrame
			end
		end
	end
	table.insert(frames, { t = now, cfs = cfs })
	while #frames > 0 and now - frames[1].t > KEEP_SECONDS do
		table.remove(frames, 1)
	end
end

-- Builds anchored, non-colliding copies and a map from original part to copy part.
local function buildActors(window: { Frame }, folder: Folder): { [BasePart]: BasePart }
	local map: { [BasePart]: BasePart } = {}
	local seen: { [Instance]: boolean } = {}
	for _, frame in window do
		for part in frame.cfs do
			local src: Instance = part
			-- Walk up to the recorded source (dummy model or prop root).
			while src.Parent and src.Parent.Name ~= "Dummies" and src.Parent.Name ~= "Props" do
				src = src.Parent
			end
			if not seen[src] then
				seen[src] = true
				local template = templates[src]
				if template then
					local copy = template:Clone()
					local originals = partsOf(src)
					local copies = partsOf(copy)
					for _, c in copies do
						c.Anchored = true
						c.CanCollide = false
						c.CanQuery = false
						c.CanTouch = false
					end
					for _, d in copy:GetDescendants() do
						if d:IsA("Constraint") or d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Fire") then
							d:Destroy()
						end
					end
					-- Match by full name path inside the source.
					local byName: { [string]: BasePart } = {}
					for _, c in copies do
						byName[c:GetFullName():sub(#copy:GetFullName() + 1)] = c
					end
					for _, o in originals do
						local key = o:GetFullName():sub(#src:GetFullName() + 1)
						local c = byName[key]
						if c then
							map[o] = c
						end
					end
					copy.Parent = folder
				end
			end
		end
	end
	return map
end

local function hideOriginals(map: { [BasePart]: BasePart }, hidden: boolean)
	for original in map do
		if original.Parent then
			original.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function sampleAt(window: { Frame }, t: number): (Frame, Frame, number)
	for i = 1, #window - 1 do
		local a, b = window[i], window[i + 1]
		if t >= a.t and t <= b.t then
			return a, b, (t - a.t) / math.max(b.t - a.t, 1e-3)
		end
	end
	local last = window[#window]
	return last, last, 0
end

local function letterbox(): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = "ReplayOverlay"
	g.IgnoreGuiInset = true
	g.DisplayOrder = 30
	for _, top in { true, false } do
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.new(1, 0, 0.11, 0)
		bar.Position = if top then UDim2.fromScale(0, 0) else UDim2.fromScale(0, 0.89)
		bar.Parent = g
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 24, 0.025, 0)
	label.Size = UDim2.fromOffset(360, 36)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	label.TextSize = 24
	label.TextColor3 = Color3.fromRGB(255, 214, 70)
	label.Text = if Config.XRAY_REPLAY then "X-RAY REPLAY  0.3x" else "INSTANT REPLAY  0.3x"
	if KitStyle.V2 then
		-- (UI v2: the display face with an ink outline, fitted to its box: never cut on a phone.)
		label.FontFace = Theme.Fonts.display
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Theme.Palette.ink
		KitStyle.fit(label, 26)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
	label.Parent = g
	local skip = Instance.new("TextButton")
	skip.Name = "Skip"
	skip.AnchorPoint = Vector2.new(1, 0.5)
	skip.Position = UDim2.new(1, -24, 0.945, 0)
	skip.Size = UDim2.fromOffset(110, 44)
	skip.Text = "Skip"
	skip.BackgroundColor3 = KitStyle.SLAB -- (dark glass: the HUD's plain button)
	KitStyle.button(skip)
	skip.Parent = g
	skip.Activated:Connect(function()
		skipRequested = true
	end)


	-- Record the replay as a Roblox video capture (max 30 s; UI is never in the clip).
	local rec = skip:Clone()
	rec.Name = "Record"
	rec.Position = UDim2.new(1, -150, 0.945, 0)
	rec.Size = UDim2.fromOffset(150, 44)
	rec.BackgroundColor3 = Color3.fromRGB(235, 70, 70)
	rec.TextColor3 = Color3.new(1, 1, 1)
	rec.Text = if Config.XRAY_REPLAY then "CLIP IT" else "Record clip"
	if KitStyle.V2 then
		-- (A clone carries the press marker but not its connections: wired again, with its icon.)
		rec:SetAttribute("KitPress", nil)
		KitStyle.button(rec)
		rec.BackgroundColor3 = Theme.role("danger").bottom
		KitStyle.icon(rec, "camera")
	end
	rec.Parent = g
	rec.Activated:Connect(function()
		if recording then
			return
		end
		recording = true
		rec.Text = "Recording..."
		rec.Active = false
		-- The call may yield for the whole capture, so it runs on its own thread.
		task.spawn(function()
			local ok = pcall(function()
				-- (V8-0.9: the callback gets (result, capture); the capture was read from the first
				-- argument, so the save prompt got the result and never showed.)
				CaptureService:StartVideoCaptureAsync(function(_result: any, capture: any)
					if capture == nil then
						return
					end
					pcall(function()
						CaptureService:PromptSaveCapturesToGallery({ capture }, function() end)
					end)
				end)
			end)
			if not ok then
				recording = false
				if rec.Parent then
					rec.Text = "Not available"
				end
			end
		end)
	end)
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return g
end

-- Plays the recorded window around eventTime (os.clock() at the event). Yields until done.
function ReplayController.play(eventTime: number): boolean
	if playing then
		return false
	end
	local window: { Frame } = {}
	for _, f in frames do
		if f.t >= eventTime - BEFORE and f.t <= eventTime + AFTER then
			table.insert(window, f)
		end
	end
	if #window < 4 then
		return false
	end
	playing = true
	skipRequested = false
	local onState = ReplayController.onStateChanged
	if onState then
		onState(true)
	end

	local folder = Instance.new("Folder")
	folder.Name = "ReplayActors"
	folder.Parent = Workspace
	local map = buildActors(window, folder)
	hideOriginals(map, true)
	if Config.XRAY_REPLAY then
		xray(map, folder)
	end

	-- Subject: the copy that travels furthest in the window.
	local subject: BasePart? = nil
	local best = -1
	local first, last = window[1], window[#window]
	for original, copy in map do
		if copy.Name == "LowerTorso" or copy.Name == "BowlingBall" or copy.Name == "Anvil" then
			local a, b = first.cfs[original], last.cfs[original]
			if a and b then
				local d = (a.Position - b.Position).Magnitude
				if d > best then
					best = d
					subject = copy
				end
			end
		end
	end

	local camera = Workspace.CurrentCamera
	local oldType = camera.CameraType
	local oldCFrame = camera.CFrame
	camera.CameraType = Enum.CameraType.Scriptable
	local overlay = letterbox()
	-- Phase 1: the hit's score ("CRACK! +140") and its SHARE CODE (toy + score) for a friend.
	if Config.XRAY_REPLAY then
		local rise, travel = 0, 0
		local subjectOriginal: BasePart? = nil
		for original, copy in map do
			if copy == subject then
				subjectOriginal = original
			end
		end
		if subjectOriginal then
			local a = first.cfs[subjectOriginal]
			for _, f in window do
				local cf = f.cfs[subjectOriginal]
				if a and cf then
					rise = math.max(rise, cf.Position.Y - a.Position.Y)
					travel = math.max(travel, (cf.Position - a.Position).Magnitude)
				end
			end
		end
		local score, word = ShareCode.scoreOf(travel, rise)
		local toyFn = ReplayController.currentToy
		local toyIndex = table.find(Toys.list, Toys.byId[if toyFn then toyFn() else "Blaster"] or Toys.byId.Blaster) or 1
		local code = ShareCode.encode(toyIndex, score)
		ReplayController.lastCode = code
		local pop = Instance.new("TextLabel")
		pop.Name = "Score"
		pop.BackgroundTransparency = 1
		pop.AnchorPoint = Vector2.new(0.5, 0.5)
		pop.Position = UDim2.fromScale(0.5, 0.3)
		pop.Size = UDim2.fromScale(0.8, 0.12)
		pop.TextScaled = true
		pop.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
		pop.TextColor3 = Color3.fromRGB(255, 214, 70)
		pop.TextStrokeTransparency = 0
		pop.Text = string.format("%s +%d", word, score)
		pop.Parent = overlay
		if KitStyle.V2 then
			-- (UI v2: the display face, a pop, and the score counting up to its value.)
			pop.FontFace = Theme.Fonts.display
			pop.TextStrokeColor3 = Theme.Palette.ink
			KitStyle.fit(pop, 72, 24)
			pop.Text = word .. " +0"
			KitStyle.countUp(pop, 0, function(n: number): string
				return string.format("%s +%d", word, n)
			end)
			KitStyle.countUp(pop, score, function(n: number): string
				return string.format("%s +%d", word, n)
			end)
		end
		local codeLabel = Instance.new("TextLabel")
		codeLabel.Name = "Code"
		codeLabel.BackgroundTransparency = 1
		codeLabel.Position = UDim2.new(0, 24, 0.025, 38) -- (under the title: the buttons own the bottom bar)
		codeLabel.Size = UDim2.fromOffset(260, 28)
		codeLabel.TextXAlignment = Enum.TextXAlignment.Left
		codeLabel.FontFace = pop.FontFace
		codeLabel.TextSize = 20
		codeLabel.TextColor3 = Color3.new(1, 1, 1)
		codeLabel.Text = "SHARE CODE  " .. code
		if KitStyle.V2 then
			-- (A dark pill, so the code reads over any scene.)
			codeLabel.BackgroundTransparency = 0.25
			codeLabel.BackgroundColor3 = Theme.Palette.dusk
			codeLabel.FontFace = Theme.Fonts.display
			local pill = Instance.new("UICorner")
			pill.CornerRadius = UDim.new(0.5, 0)
			pill.Parent = codeLabel
			KitStyle.fit(codeLabel, 20)
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 12)
			pad.PaddingRight = UDim.new(0, 12)
			pad.Parent = codeLabel
		end
		codeLabel.Parent = overlay
		local onScore = ReplayController.onScore
		if onScore then
			task.spawn(onScore, score)
		end
	end

	local t0 = window[1].t
	local duration = window[#window].t - t0
	local clock = 0
	local angle = math.rad(35)
	local focus: Vector3? = nil
	while clock < duration and not skipRequested do
		local dt = RunService.RenderStepped:Wait()
		clock += dt * SPEED
		angle += dt * 0.35
		local a, b, alpha = sampleAt(window, t0 + clock)
		for original, copy in map do
			local ca, cb = a.cfs[original], b.cfs[original]
			if ca and cb then
				copy.CFrame = ca:Lerp(cb, alpha)
			elseif ca then
				copy.CFrame = ca
			end
		end
		if subject then
			local target = subject.Position
			focus = if focus then focus:Lerp(target, math.min(1, dt * 6)) else target
			local f = focus :: Vector3
			local eye = f + Vector3.new(math.sin(angle) * 13, 2.2, math.cos(angle) * 13)
			camera.CFrame = CFrame.lookAt(eye, f + Vector3.new(0, 1, 0))
		end
	end

	-- Put everything back.
	if recording then
		recording = false
		pcall(function()
			CaptureService:StopVideoCapture()
		end)
	end
	hideOriginals(map, false)
	folder:Destroy()
	overlay:Destroy()
	camera.CameraType = oldType
	camera.CFrame = oldCFrame
	playing = false
	if onState then
		onState(false)
	end
	return not skipRequested
end

function ReplayController.isPlaying(): boolean
	return playing
end

function ReplayController.start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if playing and Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("ReplaySkip", input.KeyCode) then
			skipRequested = true
		end
	end)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if not playing and now - lastSample >= 1 / RECORD_HZ then
			lastSample = now
			record(now)
		end
	end)
end

-- Debug and tests: number of frames and recorded parts in the newest frame.
function ReplayController.stats(): (number, number)
	local n = 0
	local newest = frames[#frames]
	if newest then
		for _ in newest.cfs do
			n += 1
		end
	end
	return #frames, n
end

return ReplayController
