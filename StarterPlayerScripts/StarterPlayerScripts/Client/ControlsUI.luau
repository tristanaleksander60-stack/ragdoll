--!strict
-- The Controls window (phase L, K key or the MENU): every keyboard shortcut in the game, grouped
-- (PLAY, WINDOWS, BUILD), each with its key on a button. Tap a key to change it: the button says
-- PRESS A KEY, the next key you press is the new one (Esc or 6 s cancels, nothing else fires
-- meanwhile). A key Roblox needs (Esc, Tab, chat, walking, jump, camera) is refused and said so; a
-- key another action has swaps the two, and the toast says which. RESET ALL puts every key back.
-- Changes are kept with your profile (only the ones you changed; the server checks them).
-- On a phone or tablet without a keyboard the window says every control is a button there.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Keybinds = require(Shared:WaitForChild("Keybinds"))

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local Theme = require(UI:WaitForChild("LihFolkUITheme"))
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))

local Toast = require(script.Parent:WaitForChild("Toast"))

local ControlsUI = {}

local CAPTURE_TIMEOUT = 6
local ROW_H = 52
local KEY_W = 128

local remote: RemoteEvent? = nil
local keyButtons: { [string]: any } = {}
local waitingFor: string? = nil
local waitToken = 0
local saveToken = 0

local function redraw()
	for id, button in keyButtons do
		if id == waitingFor then
			button.setText("PRESS A KEY")
			button.setRole("premium")
		else
			button.setText(Keybinds.labelOf(id))
			button.setRole(if Keybinds.byId[id].default == Keybinds.key(id).Name then "neutral" else "info")
		end
	end
end

local changedHere = false -- the player changed a key this visit: a late load does not undo it
local sendToken = 0
local SEND_AFTER = 0.4 -- s: a quick run of changes is one message (the last layout), never dropped
local function save()
	changedHere = true
	-- (Sent a moment after the last change: the server's request budget is shared with other
	-- messages, and only the final layout matters.)
	sendToken += 1
	local token = sendToken
	task.delay(SEND_AFTER, function()
		local r = remote
		if r and token == sendToken then
			r:FireServer("Keys", Keybinds.diff())
		end
	end)
end

local function stopWaiting()
	waitingFor = nil
	waitToken += 1
	-- (A frame later: the key that ended the wait must not also run a shortcut.)
	task.defer(function()
		Keybinds.capturing = false
	end)
	redraw()
end

local function startWaiting(id: string)
	if not UserInputService.KeyboardEnabled then
		Toast.show("Plug in a keyboard to change keys")
		return
	end
	waitingFor = id
	Keybinds.capturing = true
	waitToken += 1
	local token = waitToken
	redraw()
	task.delay(CAPTURE_TIMEOUT, function()
		if token == waitToken and waitingFor then
			stopWaiting()
		end
	end)
end

local function onKey(input: InputObject)
	local id = waitingFor
	if not id or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	local name = input.KeyCode.Name
	if name == "Escape" then
		stopWaiting()
		return
	end
	if Keybinds.isReserved(name) then
		Toast.show(Keybinds.label(name) .. " belongs to Roblox. Pick another key")
		return -- (still waiting)
	end
	if not Keybinds.isAllowed(name) then
		Toast.show("That key can't be used. Pick a letter, a number or F1-F8")
		return
	end
	local ok, swapped, why = Keybinds.set(id, name)
	stopWaiting()
	if ok then
		if swapped then
			-- (Short: two keys and what they do now.)
			Toast.show(string.format("Swapped: %s %s, %s %s", Keybinds.labelOf(id), Keybinds.shortLabel(id), Keybinds.labelOf(swapped), Keybinds.shortLabel(swapped)))
		end
		save()
	elseif why == "clash" then
		Toast.show(Keybinds.label(name) .. " would clash with another key. Pick another one")
	end
end

local function build()
	local window = C.Window({ name = "Controls", title = "Controls", theme = "settings", icon = "keys" })
	local note = C.Text("body", "", { autoY = true, layoutOrder = 0, color = Theme.Palette.textMid, parent = window.body })
	local function updateNote()
		note.Text = if UserInputService.KeyboardEnabled
			then "Tap a key to change it. Esc cancels."
			else "On a phone or tablet every control is a button on the screen. Keys work with a keyboard."
	end
	updateNote()
	UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(updateNote)
	-- At the bottom, and twice to be sure (it undoes every change).
	local armed = 0
	local resetButton: any
	resetButton = C.Button({
		text = "RESET ALL KEYS",
		role = "danger",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 10000,
		parent = window.body,
		onActivated = function()
			if os.clock() - armed > 3 then
				armed = os.clock()
				resetButton.setText("TAP AGAIN TO RESET")
				task.delay(3, function()
					if os.clock() - armed >= 3 then
						resetButton.setText("RESET ALL KEYS")
					end
				end)
				return
			end
			armed = 0
			resetButton.setText("RESET ALL KEYS")
			Keybinds.reset()
			save()
			Toast.show("Every key is back to the start")
		end,
	})
	local order = 2
	local group = ""
	for _, action in Keybinds.ACTIONS do
		if action.group ~= group then
			group = action.group
			order += 1
			C.SectionHeader(group, "settings", order, window.body)
			if group == "PLAY" then
				-- Round 4, M10: sprint, held, on a key that cannot be changed (Shift is never a shortcut).
				order += 1
				local fixed = Instance.new("Frame")
				fixed.Name = "Key_Sprint"
				fixed.BackgroundTransparency = 1
				fixed.Size = UDim2.new(1, 0, 0, ROW_H)
				fixed.LayoutOrder = order
				C.Text("body", "Sprint (hold)", {
					align = Enum.TextXAlignment.Left,
					size = UDim2.new(1, -(KEY_W + Theme.Space.sm), 1, 0),
					parent = fixed,
				})
				local key = C.Text("body", "SHIFT", {
					align = Enum.TextXAlignment.Center,
					size = UDim2.fromOffset(KEY_W, ROW_H - 6),
					color = Theme.Palette.textMid,
					parent = fixed,
				})
				key.AnchorPoint = Vector2.new(1, 0.5)
				key.Position = UDim2.new(1, 0, 0.5, 0)
				fixed.Parent = window.body
			end
		end
		order += 1
		local row = Instance.new("Frame")
		row.Name = "Key_" .. action.id
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, ROW_H)
		row.LayoutOrder = order
		row.Parent = window.body
		C.Text("body", action.label, {
			align = Enum.TextXAlignment.Left,
			size = UDim2.new(1, -(KEY_W + Theme.Space.sm), 1, 0),
			parent = row,
		})
		local id = action.id
		keyButtons[id] = C.Button({
			text = "",
			role = "neutral",
			size = UDim2.fromOffset(KEY_W, ROW_H - 6),
			position = UDim2.new(1, 0, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			depth = 4,
			parent = row,
			onActivated = function()
				if waitingFor == id then
					stopWaiting()
				else
					startWaiting(id)
				end
			end,
		})
	end
	window.defaultSelection = keyButtons.Ragdoll and keyButtons.Ragdoll.hit
	Controller.register(window)
	Controller.onChanged(function(name, isOpen)
		if name == "Controls" and not isOpen and waitingFor then
			stopWaiting()
		end
	end)
	redraw()
end

function ControlsUI.start()
	build()
	Keybinds.onChanged(redraw)
	remote = Net.event(Net.Names.Progress)
	;(remote :: RemoteEvent).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "Keys" and not changedHere then
			Keybinds.apply(data) -- (the keys you changed, kept with your profile; a change made here first wins)
		end
	end)
	-- The capture sees every key (even ones a text box or the kit took); shortcuts check capturing.
	UserInputService.InputBegan:Connect(function(input, processed)
		if waitingFor then
			onKey(input)
			return
		end
		if not Keybinds.live(processed) or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		-- The windows that have no key of their own elsewhere.
		if Keybinds.is("Controls", input.KeyCode) then
			Controller.toggle("Controls")
		elseif Keybinds.is("Eggs", input.KeyCode) then
			Controller.toggle("Eggs")
		elseif Keybinds.is("Shop", input.KeyCode) then
			Controller.toggle("Events")
		elseif Keybinds.is("GodWindow", input.KeyCode) then -- (owner, 21 Nov 2026: keys for every window)
			Controller.toggle("God")
		elseif Keybinds.is("LabWindow", input.KeyCode) then
			Controller.toggle("Lab")
		elseif Keybinds.is("MenuWindow", input.KeyCode) then
			Controller.toggle("Menu")
		end
	end)
end

return ControlsUI
