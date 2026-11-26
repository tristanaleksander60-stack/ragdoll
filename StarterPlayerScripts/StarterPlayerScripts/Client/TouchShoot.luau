--!strict
-- Round 5, phase 00: shooting on a touch screen, like a mobile shooter. While a gun is picked in
-- the walk view on a touch screen:
--   * a clear crosshair in the middle of the screen (where SHOOT fires)
--   * a big round SHOOT button by the jump button (HudSlots "Shoot"); hold it to keep firing at the
--     gun's own pace. It fires through PokeController (the same remotes and checks as a tap, and
--     the same aim help: a body near the crosshair is hit)
--   * until the first shot of the visit (at most HAND_FOR s): a hand over the nearest dummy, "TAP A
--     DUMMY!" (your greeter first)
-- Tapping a dummy still works as before. Nothing here on a computer or a console.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Toys = require(Shared:WaitForChild("Toys"))
local Shop = require(Shared:WaitForChild("Shop"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local HudSlots = require(Client:WaitForChild("HudSlots"))
local KitStyle = require(Client:WaitForChild("KitStyle"))
local FirstPerson = require(Client:WaitForChild("FirstPerson")) :: any
local AmmoClient = require(Client:WaitForChild("AmmoClient"))
local SessionClient = require(Client:WaitForChild("SessionClient"))
-- V9-NOW crosshair-sync: FeelV2 owns the recoil angles; we read them so the on-screen
-- crosshair tracks exactly where the pitched/yawed camera's centre ray points, keeping
-- the icon pixel-perfect against the raycast across every screen size and aspect ratio.
local FeelV2 = require(Client:WaitForChild("FeelV2"))

local TouchShoot = {}

TouchShoot.HAND_FOR = 0 -- (23 Nov 2026, owner: no "TAP A DUMMY!" on phones; it was 45) s: the "tap a dummy" hand shows at most this long into a visit
local SHOOT_RED = Color3.fromRGB(230, 50, 50)

local player = Players.LocalPlayer
local buttonGui: ScreenGui? = nil
local button: TextButton? = nil
local centreGui: ScreenGui? = nil
local hand: TextLabel? = nil
local holding = false
local charging = false
local shownKind = "gun"

local zoomSlot = "Zoom" -- the box the ZOOM / AIM button has now
local function gunPicked(): Toys.Toy?
	local toy = Toys.byId[PokeController.getSelected()]
	if toy and toy.gun then
		return toy
	end
	return nil
end

-- (23 Nov 2026, owner: learn from what the big ragdoll games do on phones. Theirs: ONE big button under the right thumb
-- that says what the tool in your hand does, and a small RELOAD with the count beside it.) Every tool but Grab (a tap
-- grabs) and the talk wand has it; tapping a ragdoll still works as before.
local ACTION: { [string]: { word: string, color: Color3 } } = {
	gun = { word = "SHOOT", color = SHOOT_RED },
	hit = { word = "HIT", color = Color3.fromRGB(235, 120, 30) },
	place = { word = "PLACE", color = Color3.fromRGB(46, 140, 220) },
	boom = { word = "BOOM!", color = SHOOT_RED },
	dummy = { word = "USE", color = Color3.fromRGB(46, 140, 220) },
}
local function actionPicked(): (Toys.Toy?, string)
	local toy = Toys.byId[PokeController.getSelected()]
	if not toy or toy.kind == "grab" or toy.id == "Wand" then
		return nil, ""
	end
	if toy.gun then
		return toy, "gun"
	elseif toy.id == "C4" and ((player:GetAttribute("C4Armed") :: number?) or 0) > 0 then
		return toy, "boom"
	end
	return toy, toy.kind
end

-- Whether the action button shows now.
function TouchShoot.wanted(): boolean
	return ViewMode.isTouch() and not ViewMode.isLab() and PokeController.active() and not PokeController.handIsEmpty() and actionPicked() ~= nil and player.Character ~= nil
end

-- Phase 0: a gamepad fires at the centre too (R2: GamepadControls), so it gets the crosshair
-- (not the SHOOT button) whenever its last input was the pad and a gun is picked.
function TouchShoot.padCross(): boolean
	return string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
		and not ViewMode.isLab()
		and PokeController.active()
		and gunPicked() ~= nil
end

-- V9-NOW crosshair-sync: the aim pixel is the viewport centre plus the current recoil offset
-- (FeelV2.recoilPixelOffset, shared with PokeController's mouse path and Crosshair so all three
-- always agree). Visual crosshair and the raycast both read this, so the icon on the screen and
-- the bullet direction cannot drift apart (even mid-recoil, on a phone with a notch, or on a
-- landscape/portrait swap: camera.ViewportSize already respects the renderable area).
local function aimPixel(camera: Camera): Vector2
	return camera.ViewportSize / 2 + FeelV2.recoilPixelOffset(camera)
end

local function centre(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then aimPixel(camera) else Vector2.zero
end

-- One shot at the crosshair: at a body if one is there (or near it), otherwise into the world.
-- The pixel used here is the same pixel the visual crosshair sits on, so the raycast through
-- camera:ViewportPointToRay inside PokeController lines up exactly with the icon the player sees.
local centreUntil = 0
function TouchShoot.fire(): boolean
	centreUntil = os.clock() + 0.45
	if FirstPerson.isOn() then
		(require(Client:WaitForChild("Viewmodel")) :: any).swing()
	end
	local at = centre()
	return PokeController.pressAt(at) or PokeController.tapAt(at)
end

-- Tests / external callers: where the touch/pad crosshair is right now, in viewport pixels.
function TouchShoot.aimPixel(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then aimPixel(camera) else Vector2.zero
end

local function holdFire()
	if holding then
		return
	end
	holding = true
	task.spawn(function()
		while holding and TouchShoot.wanted() do
			local toy, kind = actionPicked()
			TouchShoot.fire()
			if kind ~= "gun" and kind ~= "hit" then
				break -- (one press places one)
			end
			local cooldown = if toy then toy.cooldown else 0.2
			if player:GetAttribute("ZeroDelay") == true then
				cooldown = math.min(cooldown, Shop.ZERO_DELAY)
			end
			task.wait(math.max(cooldown, 0.04) + 0.01)
		end
		holding = false
	end)
end

local function build()
	local gui = Instance.new("ScreenGui")
	gui.Name = "TouchShoot"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- (HudSlots' frame)
	gui.DisplayOrder = 6
	gui.Enabled = false
	local b = Instance.new("TextButton")
	b.Name = "Shoot"
	b.Text = "SHOOT"
	b.FontFace = Theme.Fonts.display
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = SHOOT_RED
	b.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(10, 10, 14)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	if Theme.Premium then
		-- (24 Nov 2026: a light rim round the colour: a trigger, not a sticker.)
		stroke.Thickness = 3
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.25
		b.BackgroundTransparency = 0.06
		b.AutoButtonColor = false
	end
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.14, 0)
	pad.PaddingRight = UDim.new(0.14, 0)
	pad.PaddingTop = UDim.new(0.3, 0)
	pad.PaddingBottom = UDim.new(0.3, 0)
	pad.Parent = b
	b.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
			if PokeController.beginCharge() then
				charging = true
			else
				holdFire()
			end
			TweenService:Create(b, TweenInfo.new(0.06), { BackgroundColor3 = Color3.fromRGB(255, 110, 90) }):Play()
		end
	end)
	b.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch or kind == Enum.UserInputType.MouseButton1 then
			holding = false
			if charging then
				charging = false
				centreUntil = os.clock() + 0.45
				PokeController.endCharge(centre())
			end
			TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = (ACTION[select(2, actionPicked())] or ACTION.gun).color }):Play()
		end
	end)
	b.Parent = gui
	button = b
	if KitStyle.V2 then
		-- (UI v2: the drawn blaster over the word, the kit's light-from-above face, the press squish.)
		local shade = Instance.new("UIGradient")
		shade.Rotation = 90
		shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 215))
		shade.Parent = b
		KitStyle.fit(b, 22)
		KitStyle.icon(b, KitStyle.HUD_ICONS.Shoot, "top")
		KitStyle.press(b, "") -- (no click per shot: the gun is the sound)
	end
	-- Round 5: ZOOM over SHOOT while a scoped gun (Sniper, DMR) is picked: a toggle (GunFeel).
	local z = Instance.new("TextButton")
	z.Name = "Zoom"
	z.Text = "ZOOM"
	z.TextScaled = true
	z.FontFace = Theme.Fonts.display
	z.TextColor3 = Color3.new(1, 1, 1)
	z.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
	z.AnchorPoint = Vector2.new(0.5, 1)
	z.Position = UDim2.new(0.5, 0, 0, -8)
	z.Size = UDim2.new(1, 0, 0, 34)
	z.Visible = false
	local zc = Instance.new("UICorner")
	zc.CornerRadius = UDim.new(0, 10)
	zc.Parent = z
	local zs = Instance.new("UIStroke")
	zs.Thickness = 2
	zs.Color = Color3.fromRGB(10, 10, 14)
	zs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	zs.Parent = z
	if Theme.Premium then
		zs.Thickness = 1.5
		zs.Color = Theme.Hud.edge
		zs.Transparency = 0.75
		zc.CornerRadius = UDim.new(0, Theme.Hud.radius)
		z.BackgroundTransparency = 0.1
		z.BackgroundColor3 = Theme.Hud.face
	end
	z.Activated:Connect(function()
		local GunFeel = require(Client:WaitForChild("GunFeel")) :: any
		local on = not GunFeel.zoomed()
		GunFeel.setZoomToggle(on)
	end)
	if KitStyle.V2 then
		KitStyle.fit(z, 20)
		KitStyle.press(z)
	end
	local rl = z:Clone()
	rl.Name = "Reload"
	rl.Text = ""
	rl.BackgroundColor3 = Color3.fromRGB(34, 38, 46)
	if Theme.Premium then
		rl.BackgroundColor3 = Theme.Hud.face
		rl:SetAttribute("KitPress", nil) -- (the attribute came with the clone, its connections did not)
		KitStyle.press(rl)
	end
	rl.Visible = false
	rl.Activated:Connect(function()
		AmmoClient.reload(nil)
	end)
	rl.Parent = gui
	z.Parent = gui -- (its own box over SHOOT, not inside SHOOT's padding: review fix)
	buttonGui = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	HudSlots.watch(function()
		local ctx = HudSlots.context(true, false)
		HudSlots.apply(b, "Shoot", ctx)
		local zoom = gui:FindFirstChild("Zoom")
		if zoom and zoom:IsA("GuiObject") then
			HudSlots.apply(zoom, zoomSlot, ctx)
		end
		HudSlots.apply(rl, "Reload", ctx)
	end)

	-- The crosshair in the middle (its own layer, which ignores the insets: the camera's centre ray).
	-- V9-NOW crosshair-sync: ScreenInsets = None and IgnoreGuiInset = true together guarantee the
	-- ScreenGui's AbsoluteSize equals camera.ViewportSize, so a pixel offset here maps 1:1 to a
	-- viewport pixel (no safe-area shrink on a notched phone, no top-bar bite). The holder's
	-- Position is written every frame from aimPixel() so the icon sits exactly where the raycast
	-- begins, including through recoil, camera rotation, jumps and aspect ratio changes.
	local c = Instance.new("ScreenGui")
	c.Name = "TouchCrosshair"
	c.ResetOnSpawn = false
	c.IgnoreGuiInset = true
	c.ScreenInsets = Enum.ScreenInsets.None
	c.DisplayOrder = 6
	c.Enabled = false
	local holder = Instance.new("Frame")
	holder.Name = "Cross"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5) -- (overwritten every frame: aimPixel())
	holder.Size = UDim2.fromOffset(44, 44)
	holder.BackgroundTransparency = 1
	holder.Parent = c
	for _, spec in { { 0.5, 0, 3, 13 }, { 0.5, 1, 3, 13 }, { 0, 0.5, 13, 3 }, { 1, 0.5, 13, 3 } } do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(spec[1], spec[2])
		line.Position = UDim2.fromScale(spec[1], spec[2])
		line.Size = UDim2.fromOffset(spec[3], spec[4])
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BorderSizePixel = 0
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(10, 10, 14)
		s.Thickness = 1.5
		s.Parent = line
		line.Parent = holder
	end
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(5, 5)
	dot.BackgroundColor3 = SHOOT_RED
	dot.BorderSizePixel = 0
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0.5, 0)
	dc.Parent = dot
	dot.Parent = holder
	-- The hand over a dummy, until the first shot.
	local h = Instance.new("TextLabel")
	h.Name = "TapHand"
	h.AnchorPoint = Vector2.new(0.5, 1)
	h.Size = UDim2.fromOffset(190, 64)
	h.BackgroundTransparency = 1
	h.FontFace = Theme.Fonts.display
	h.TextScaled = true
	h.TextColor3 = Color3.fromRGB(255, 230, 90)
	h.Text = "TAP A DUMMY!\n\u{1F447}"
	h.Visible = false
	local hs = Instance.new("UIStroke")
	hs.Thickness = 3
	hs.Color = Color3.fromRGB(20, 10, 0)
	hs.Parent = h
	h.Parent = c
	hand = h
	centreGui = c
	c.Parent = player:WaitForChild("PlayerGui")
end

-- The dummy the hand points at: your greeter if it is here, else the nearest one on screen.
local function handTarget(camera: Camera): Vector2?
	local dummies = Workspace:FindFirstChild("Dummies")
	if not dummies then
		return nil
	end
	local best: Vector2? = nil
	local bestScore = math.huge
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, model in dummies:GetChildren() do
		local head = model:FindFirstChild("Head")
		if head and head:IsA("BasePart") and model:GetAttribute("Vital") ~= "Dead" then
			local p, on = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
			if on and p.Z > 0 then
				local score = if root and root:IsA("BasePart") then (head.Position - root.Position).Magnitude else p.Z
				if model:GetAttribute("Greeter") == player.UserId then
					score -= 1000
				end
				if score < bestScore then
					best, bestScore = Vector2.new(p.X, p.Y), score
				end
			end
		end
	end
	return best
end

function TouchShoot.start()
	build()
	RunService.RenderStepped:Connect(function()
		local want = TouchShoot.wanted()
		local bg, cg = buttonGui, centreGui
		if bg and bg.Enabled ~= want then
			bg.Enabled = want
			if not want then
				holding = false
			end
		end
		-- lihfolk-ignore: findfirstchild-chain (nil-checked on the next line)
		local zoom = bg and bg:FindFirstChild("Zoom") :: GuiObject?
		if zoom then
			local toy = gunPicked()
			-- (24 Nov 2026: every gun can be aimed in first person; the two with a scope in the player view too.)
			local GunFeel = require(Client:WaitForChild("GunFeel")) :: any
			local scope = toy ~= nil and (toy.id == "Sniper" or toy.id == "DMR")
			zoom.Visible = want and toy ~= nil and GunFeel.aimOf(toy.id) ~= nil
			local slotName = if scope then "Zoom" else "Aim"
			if slotName ~= zoomSlot then
				zoomSlot = slotName
				HudSlots.apply(zoom, slotName, HudSlots.context(true, false))
				;(zoom :: TextButton).Text = if scope then "ZOOM" else "AIM"
			end
			local lit = if Theme.Premium then (if GunFeel.zoomed() then Color3.fromRGB(201, 80, 26) else Theme.Hud.face) elseif GunFeel.zoomed() then Color3.fromRGB(40, 150, 80) else Color3.fromRGB(40, 60, 90)
			if zoom.BackgroundColor3 ~= lit then
				zoom.BackgroundColor3 = lit
			end
		end
		local b = button
		if want and b then
			local _, kind = actionPicked()
			local look = ACTION[kind] or ACTION.gun
			if shownKind ~= kind then
				shownKind = kind
				b.Text = look.word
				b.BackgroundColor3 = look.color
			end
			-- lihfolk-ignore: findfirstchild-chain (nil-checked on the next line)
			local rl = bg and bg:FindFirstChild("Reload") :: TextButton?
			if rl then
				local toy = gunPicked()
				local text = if toy then AmmoClient.text(toy.id) else nil
				-- (F6: on a phone RELOAD shows only when the clip is low or empty.)
				local low = true
				if text and (require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any).PHONE_CLEAN and text ~= "RELOAD" then
					local a, b = string.match(text, "(%d+)%s*/%s*(%d+)")
					if a and b then
						low = tonumber(a) :: number <= math.max(1, math.floor((tonumber(b) :: number) * 0.3))
					end
				end
				rl.Visible = text ~= nil and low
				local word = if text == "RELOAD" then "..." elseif text then "RELOAD" .. string.char(10) .. text else ""
				if rl.Text ~= word then
					rl.Text = word
				end
			end
		end
		local h = hand
		local camera = Workspace.CurrentCamera
		local handShown = false
		if h and camera then
			local show = ViewMode.isTouch() and PokeController.active() and not SessionClient.hasShot() and time() < TouchShoot.HAND_FOR
			local at = if show then handTarget(camera) else nil
			if at then
				local bob = math.sin(os.clock() * 6) * 6
				h.Position = UDim2.fromOffset(at.X, at.Y - 8 + bob)
				handShown = true
			end
			if h.Visible ~= handShown then
				h.Visible = handShown
			end
		end
		if cg then
			-- lihfolk-ignore: findfirstchild-chain (the result is nil-checked on the next line)
			local cross = cg:FindFirstChild("Cross") :: GuiObject?
			-- (V10 phase 1, owner: "the phone crosshair not in the middle of the screen, only where you shoot": on a
			-- touch screen it shows a moment after SHOOT fires there, and all the time only in first person.)
			local centred = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or FirstPerson.isOn()
			local crossOn = want --[[ 24 Nov 2026, owner: always while the button aims at the middle ]] or TouchShoot.padCross()
			if cross and cross.Visible ~= crossOn then
				cross.Visible = crossOn
			end
			-- V9-NOW crosshair-sync: pin the icon to the viewport pixel the raycast uses, every
			-- frame. Recoil pitch/yaw flow through FeelV2.recoilAngles -> aimPixel; TouchShoot.fire
			-- also reads aimPixel so the shot ray and the icon never drift.
			if cross and crossOn and camera then
				local pxl = aimPixel(camera)
				-- (23 Nov 2026, owner: in first person the crosshair is the middle of the screen, whatever the phone's shape.)
				cross.Position = if FirstPerson.isOn() then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(pxl.X, pxl.Y)
			end
			local on = crossOn or handShown -- (the hand lives in the crosshair's layer)
			if cg.Enabled ~= on then
				cg.Enabled = on
			end
		end
	end)
end

-- Tests / LayoutCheck: the button (nil before start).
function TouchShoot.buttonForTest(): TextButton?
	return button
end

return TouchShoot
