--!strict
-- Round 5, phase 2: the magazine on this screen (Shared/Ammo, counted the same way the server does).
--   "12 / 17" beside the crosshair (the mouse on a computer, the middle on a touch screen) and on
--   the gun's slab; a ring that fills while it reloads
--   empty: it reloads by itself, with the gun's own reload sound (SoundManifest.GUNS reload)
--   R (Keybinds "Reload") or tapping the counter on a touch screen: reload early (the server too)
-- PokeController asks canFire before a shot and calls spent after one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Ammo = require(Shared:WaitForChild("Ammo"))
local Net = require(Shared:WaitForChild("Net"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))
local Toys = require(Shared:WaitForChild("Toys"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Controller = require(UI:WaitForChild("LihFolkUIController")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local Client = script.Parent
local FxController = require(Client:WaitForChild("FxController"))
local ViewMode = require(Client:WaitForChild("ViewMode"))

local AmmoClient = {}

-- Set by PokeController (the picked tool) and its slabs (where a slab's counter goes).
AmmoClient.getSelected = nil :: (() -> string)?
AmmoClient.slabOf = nil :: ((id: string) -> GuiObject?)?

local player = Players.LocalPlayer
local book: Ammo.Book = {}
local gui: ScreenGui? = nil
local counter: TextButton? = nil
local ring: Frame? = nil
local ringGradient: UIGradient? = nil
local slabLabels: { [string]: TextLabel } = {}
local wasReloading: { [string]: boolean } = {}

function AmmoClient.canFire(toyId: string): boolean
	local left = Ammo.left(book, toyId, os.clock())
	return left == nil or (left > 0 and Ammo.reloading(book, toyId, os.clock()) == nil)
end

local function startedReload(toyId: string)
	local spec = Ammo.spec(toyId)
	if spec then
		wasReloading[toyId] = true
		FxController.reload(toyId, spec.reload)
	end
end

-- Told of every round fired (the first-person viewmodel's kick and flash).
AmmoClient.onSpent = {} :: { (toyId: string) -> () }

-- A round fired (after the shot went to the server).
function AmmoClient.spent(toyId: string)
	for _, fn in AmmoClient.onSpent do
		task.spawn(fn, toyId)
	end
	if Ammo.take(book, toyId, os.clock()) and Ammo.reloading(book, toyId, os.clock()) ~= nil then
		startedReload(toyId) -- (the last round: it reloads by itself)
	end
end

function AmmoClient.reload(toyId: string?)
	local id = toyId or (AmmoClient.getSelected and AmmoClient.getSelected())
	if not id or not Ammo.spec(id) then
		return
	end
	if Ammo.reload(book, id, os.clock()) then
		Net.event(Net.Names.Ammo):FireServer("Reload", id)
		startedReload(id)
	end
end

-- What the counter says for a gun (nil: no magazine).
function AmmoClient.text(toyId: string): string?
	local spec = Ammo.spec(toyId)
	if not spec then
		return nil
	end
	if Ammo.reloading(book, toyId, os.clock()) then
		return "RELOAD"
	end
	return string.format("%d / %d", Ammo.left(book, toyId, os.clock()) or 0, spec.mag)
end

-- Tests: the client's book.
function AmmoClient.bookForTest(): Ammo.Book
	return book
end

local function build()
	local g = Instance.new("ScreenGui")
	g.Name = "Ammo"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 8
	local c = Instance.new("TextButton")
	c.Name = "Counter"
	c.AutoButtonColor = false
	c.BackgroundTransparency = 1
	c.Size = UDim2.fromOffset(92, 24)
	c.AnchorPoint = Vector2.new(0, 0.5)
	c.FontFace = Theme.Fonts.display
	c.TextScaled = true
	c.TextColor3 = Color3.new(1, 1, 1)
	c.TextXAlignment = Enum.TextXAlignment.Left
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(10, 10, 14)
	s.Parent = c
	c.Activated:Connect(function()
		AmmoClient.reload(nil)
	end)
	c.Parent = g
	-- The reload ring: a circle's outline filled clockwise by its gradient's transparency.
	local r = Instance.new("Frame")
	r.Name = "Ring"
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Size = UDim2.fromOffset(30, 30)
	r.BackgroundTransparency = 1
	r.Visible = false
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0.5, 0)
	rc.Parent = r
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(255, 214, 74)
	stroke.Parent = r
	local grad = Instance.new("UIGradient")
	grad.Rotation = -90
	grad.Parent = stroke
	r.Parent = g
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	counter = c
	ring = r
	ringGradient = grad
end

local function slabLabel(id: string): TextLabel?
	local get = AmmoClient.slabOf
	local slab = get and get(id)
	if not slab then
		return nil
	end
	local l = slabLabels[id]
	if l and l.Parent == slab then
		return l
	end
	local made = Instance.new("TextLabel")
	made.Name = "AmmoCount"
	made.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	made.BackgroundTransparency = 0.05
	made.AnchorPoint = Vector2.zero -- (24 Nov 2026, owner: it lay over the name: on the slot's top edge now)
	made.Position = UDim2.fromOffset(0, -9)
	made.Size = UDim2.fromOffset(38, 14)
	made.FontFace = Theme.Fonts.body
	made.TextScaled = true
	made.TextColor3 = Color3.fromRGB(255, 230, 160)
	made.ZIndex = 30
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = made
	made.Parent = slab
	slabLabels[id] = made
	return made
end

local function frame()
	local c, r, grad = counter, ring, ringGradient
	if not c or not r or not grad then
		return
	end
	local id = AmmoClient.getSelected and AmmoClient.getSelected() or ""
	local toy = Toys.byId[id]
	local text = if toy and toy.gun then AmmoClient.text(id) else nil
	-- (UI audit 21 Nov 2026: not over an open window; the count belongs to aiming.)
	-- (0.37.3, owner: "the shots left by the crosshair take room for nothing": only the empty-magazine word
	-- shows there now; the reload ring still fills while it reloads, and the slab keeps the count.)
	c.Visible = text == "RELOAD" and Controller.getCurrent() == nil
	local now = os.clock()
	-- (A reload that ran out: the magazine is full again, said once.)
	for gunId in wasReloading do
		if Ammo.reloading(book, gunId, now) == nil then
			wasReloading[gunId] = nil
		end
	end
	if not text then
		r.Visible = false
		return
	end
	local camera = workspace.CurrentCamera
	-- (The middle on a touch screen and with the mouse locked, as in first person.)
	local centred = ViewMode.isTouch() or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
	local at = if centred and camera then camera.ViewportSize / 2 else UserInputService:GetMouseLocation()
	c.Position = UDim2.fromOffset(at.X + 26, at.Y + 20)
	c.Text = text :: string
	local spec = Ammo.spec(id)
	local left = Ammo.left(book, id, now) or 0
	c.TextColor3 = if text == "RELOAD" then Color3.fromRGB(255, 214, 74)
		elseif spec and left <= math.max(1, math.floor(spec.mag * 0.2)) then Color3.fromRGB(255, 90, 80)
		else Color3.new(1, 1, 1)
	local progress = Ammo.reloading(book, id, now)
	r.Visible = progress ~= nil
	if progress then
		r.Position = UDim2.fromOffset(at.X, at.Y)
		local p = math.clamp(progress, 0.001, 0.999)
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(p, 0),
			NumberSequenceKeypoint.new(math.min(p + 0.001, 1), 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
	-- (UI audit 21 Nov 2026: on a touch screen the slot is narrow and the count covered the weapon's
	-- name; the count by the crosshair in the middle says it there.)
	local label = slabLabel(id)
	if label then
		label.Text = text :: string
		label.Visible = not ViewMode.isTouch()
	end
end

function AmmoClient.start()
	build()
	RunService.RenderStepped:Connect(frame)
	UserInputService.InputBegan:Connect(function(input, processed)
		if Keybinds.live(processed) and input.UserInputType == Enum.UserInputType.Keyboard and Keybinds.is("Reload", input.KeyCode) then
			AmmoClient.reload(nil)
		end
	end)
	-- A new life: every magazine full again (as on the server, which keeps its count per visit:
	-- a refused round only ever means a short wait).
	player.CharacterAdded:Connect(function()
		table.clear(book)
		table.clear(wasReloading)
	end)
end

function AmmoClient.guiForTest(): ScreenGui?
	return gui
end

return AmmoClient
