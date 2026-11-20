--!strict
-- V9-0t (owner, 21 Nov 2026: "add codes we can advertise in the description"): the CODES window. One
-- text box, REDEEM, and a result line: the reward (with confetti) or why not (invalid, used, expired,
-- too many tries). Opened from MENU (More) and from SHOP's "Have a code?". The server decides it all
-- (EconomyService.redeem over the Economy remote, Shared/Codes); this only asks and shows the answer.
-- A reply that arrives while the window is shut (the EXPERIMENTS window's old box) is a toast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Toast = require(script.Parent:WaitForChild("Toast"))

local CodesWindow = {}

CodesWindow.WINDOW = "Codes"
CodesWindow.SIZE = Vector2.new(460, 340)
CodesWindow.WAIT = 1.2 -- s REDEEM rests after a tap (the server answers in that time)

local GOOD = Color3.fromRGB(80, 220, 120)
local BAD = Color3.fromRGB(255, 120, 100)

local window: any = nil
local input: any = nil
local redeemButton: any = nil
local result: TextLabel? = nil
local waiting = false

-- A short burst of confetti over the window body (pictures only).
local function confetti(into: GuiObject)
	local colours = { Color3.fromRGB(255, 201, 60), Color3.fromRGB(255, 120, 60), Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 230, 120), Color3.fromRGB(240, 110, 200) }
	for i = 1, 26 do
		local bit = Instance.new("Frame")
		bit.Name = "Confetti"
		bit.BorderSizePixel = 0
		bit.BackgroundColor3 = colours[(i % #colours) + 1]
		bit.Size = UDim2.fromOffset(7, 11)
		bit.AnchorPoint = Vector2.new(0.5, 0.5)
		bit.Position = UDim2.fromScale(0.5, 0.62)
		bit.Rotation = math.random(0, 360)
		bit.ZIndex = 20
		bit.Parent = into
		local dx = (math.random() - 0.5) * 0.9
		local up = 0.25 + math.random() * 0.35
		local t1 = TweenService:Create(bit, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5 + dx * 0.6, 0.62 - up),
			Rotation = bit.Rotation + math.random(-180, 180),
		})
		t1:Play()
		t1.Completed:Connect(function()
			local t2 = TweenService:Create(bit, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromScale(0.5 + dx, 1.05),
				BackgroundTransparency = 1,
			})
			t2:Play()
			t2.Completed:Connect(function()
				bit:Destroy()
			end)
		end)
	end
end

local function show(ok: boolean, text: string)
	local line = result
	if window and Controller.isOpen(CodesWindow.WINDOW) and line then
		line.Text = (if ok then "\u{2714} " else "") .. text
		line.TextColor3 = if ok then GOOD else BAD
		if ok then
			C.playSound("purchase")
			confetti(window.body)
			if input then
				input.clear()
			end
		else
			C.playSound("error")
			if input then
				input.shake()
			end
		end
	else
		Toast.show(if ok then "Code! " .. text else text, if ok then GOOD else BAD)
	end
end

local function send()
	if waiting or not input then
		return
	end
	local text = input.getText()
	if #text < 3 then
		if result then
			result.Text = "Type a code first"
			result.TextColor3 = BAD
		end
		return
	end
	waiting = true
	if redeemButton then
		redeemButton.setEnabled(false)
	end
	Net.event(Net.Names.Economy):FireServer("Redeem", string.sub(text, 1, 40))
	task.delay(CodesWindow.WAIT, function()
		waiting = false
		if redeemButton then
			redeemButton.setEnabled(true)
		end
	end)
end

function CodesWindow.open()
	Controller.open(CodesWindow.WINDOW)
end

function CodesWindow.start()
	window = C.Window({ name = CodesWindow.WINDOW, title = "Codes", theme = "shop", icon = "gift", size = CodesWindow.SIZE, scroll = false })
	C.Text("body", "Got a code from our game page? Type it here.", {
		color = Theme.Palette.textHi,
		wrap = true,
		size = UDim2.new(1, 0, 0, 30),
		layoutOrder = 1,
		parent = window.body,
	})
	input = C.TextInput({
		name = "CodeBox",
		placeholder = "Type a code",
		maxLength = 24,
		layoutOrder = 2,
		parent = window.body,
		onSubmit = function()
			send()
		end,
	})
	redeemButton = C.Button({
		name = "Redeem",
		text = "REDEEM",
		role = "premium",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 3,
		parent = window.body,
		onActivated = send,
	})
	result = C.Text("body", "", {
		name = "Result",
		wrap = true,
		size = UDim2.new(1, 0, 0, 30),
		layoutOrder = 4,
		parent = window.body,
	})
	window.defaultSelection = redeemButton.hit
	Controller.register(window)
	Controller.onChanged(function(name: string, open: boolean)
		if name == CodesWindow.WINDOW and open and result then
			result.Text = ""
		end
	end)
	Net.event(Net.Names.Economy).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "Code" and type(data) == "table" then
			local d = data :: any
			show(d.ok == true, if type(d.text) == "string" then d.text else "")
		end
	end)
end

return CodesWindow
