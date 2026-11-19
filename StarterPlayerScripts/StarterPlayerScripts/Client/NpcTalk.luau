--!strict
-- v4 B4: the talk panel. Press E on an NPC (the server's Talk prompt) and this small card opens
-- over the tool bar: FOLLOW ME, STAY HERE, ATTACK…, BYE. ATTACK asks who (the nearest others) and
-- with what (your unlocked weapons, the ones on your bar first). The server (NpcCommand) checks
-- every choice; a refusal shows as a toast.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Toys = require(Shared:WaitForChild("Toys"))
local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents")) :: any
local Theme = require(UI:WaitForChild("LihFolkUITheme")) :: any

local Client = script.Parent
local Toast = require(Client:WaitForChild("Toast"))

local NpcTalk = {}

local player = Players.LocalPlayer
local remote: RemoteEvent
local gui: ScreenGui
local card: Frame
local list: Frame
local title: TextLabel

local BUTTON_W, BUTTON_H = 260, 44

local function clear()
	for _, c in list:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
end

local function close()
	gui.Enabled = false
	clear()
end

local function button(text: string, role: string, order: number, onActivated: () -> ())
	C.Button({ text = text, role = role, size = UDim2.fromOffset(BUTTON_W, BUTTON_H), layoutOrder = order, parent = list, onActivated = onActivated })
end

local function open(data: any)
	if type(data) ~= "table" or typeof(data.npc) ~= "Instance" then
		return
	end
	local npc = data.npc :: Instance
	clear()
	title.Text = string.upper(tostring(data.name or "Dummy"))
	gui.Enabled = true
	local function send(action: string, target: Instance?, toyId: string?)
		remote:FireServer(action, npc, target, toyId)
		close()
	end
	button("FOLLOW ME", "go", 1, function()
		send("Follow")
	end)
	button("STAY HERE", "neutral", 2, function()
		send("Stay")
	end)
	local targets = if type(data.targets) == "table" then data.targets else {}
	local weapons = if type(data.weapons) == "table" then data.weapons else {}
	if #targets > 0 and #weapons > 0 then
		button("ATTACK…", "danger", 3, function()
			-- Who?
			clear()
			title.Text = "ATTACK WHO?"
			for i, t in targets do
				if i > 4 then
					break
				end
				button(string.upper(tostring(t.name)), "neutral", i, function()
					-- With what? (your bar's weapons first)
					clear()
					title.Text = "WITH WHAT?"
					local shown = 0
					for _, id in weapons do
						local toy = Toys.byId[id]
						if toy and shown < 5 then
							shown += 1
							button(string.upper(toy.short or toy.label), "danger", shown, function()
								send("Attack", t.model, id)
							end)
						end
					end
					button("BACK", "neutral", 9, close)
				end)
			end
			button("BACK", "neutral", 9, close)
		end)
	end
	button("BYE", "neutral", 4, function()
		send("Bye")
	end)
end

function NpcTalk.start()
	remote = Net.event(Net.Names.NpcCommand)
	gui = Instance.new("ScreenGui")
	gui.Name = "NpcTalk"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- (the kit's buttons layer by siblings)
	gui.Enabled = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.55)
	card.Size = UDim2.fromOffset(BUTTON_W + 28, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.Palette.dusk or Color3.fromRGB(24, 28, 44)
	card.BackgroundTransparency = 0.05
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = card
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = card
	title = Instance.new("TextLabel")
	title.Name = "Title"
	title.LayoutOrder = 0
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromOffset(BUTTON_W, 26)
	title.FontFace = Theme.Fonts.display
	title.TextSize = 22
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = card
	list = Instance.new("Frame")
	list.Name = "List"
	list.LayoutOrder = 1
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromOffset(BUTTON_W, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list
	list.Parent = card
	-- (Short screens: the card shrinks to fit; its tallest page is about 330 px.)
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local function fit()
		local cam = workspace.CurrentCamera
		local h = if cam then cam.ViewportSize.Y else 720
		scale.Scale = math.clamp((h - 40) / 360, 0.6, 1)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
	card.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	remote.OnClientEvent:Connect(function(kind: string, data: any)
		if kind == "Open" then
			open(data)
		elseif kind == "Refused" and type(data) == "table" and type(data.text) == "string" then
			Toast.show(data.text, Color3.fromRGB(255, 140, 110))
		elseif kind == "Done" and type(data) == "table" then
			local words = { Follow = "Following you!", Stay = "Staying here.", Attack = "On it!", Bye = "Bye!" }
			local w = words[tostring(data.action)]
			if w then
				Toast.show(w)
			end
		end
	end)
	-- Escape or walking away closes it.
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and gui.Enabled and input.KeyCode == Enum.KeyCode.Escape then
			close()
		end
	end)
end

return NpcTalk
