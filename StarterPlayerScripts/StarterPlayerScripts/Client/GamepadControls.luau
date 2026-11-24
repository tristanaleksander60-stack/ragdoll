--!strict
-- Phase 0 (19 Nov 2026): the whole game on a gamepad (Xbox, PlayStation, a pad on a PC). The
-- buttons and what they do are in Shared\PadMap (pure, tested by T53_Gamepad); this binds them with
-- ContextActionService and routes each to the module a mouse or a finger already uses:
--   fire      TouchShoot.fire (the centre of the screen, the touch SHOOT path, aim help included);
--             automatic guns keep firing at their own pace while R2 is held
--   aim       GunFeel's zoom while L2 is held
--   slots     PokeController.cycle; LB / RB in WEAPONS: ToolCatalog.stepTab
--   WEAPONS   PokeController.openCatalog / ToolCatalog.toggle
--   grab      GrabController.padGrab (dummies, and players in the plaza: PlayerGrabClient)
--   ragdoll   PlayerBody.toggle (being held: jump = A wriggles, as on a keyboard)
--   view      player -> first person -> lab view (right stick orbits, left pans: LabCamera) -> player
--   SPECTATE (owner)  LB / RB next, B stop
--   MENU / SHOP  the kit's windows; inside a window A selects and B closes (LihFolkUIController)
-- Roblox's automatic Select-to-UI mode is turned off: every HUD launcher is in MENU on a pad
-- (HudMenu shows the phone-only entries to a pad too), so Select is free for the view.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PadMap = require(Shared:WaitForChild("PadMap"))
local Toys = require(Shared:WaitForChild("Toys"))
local Shop = require(Shared:WaitForChild("Shop"))
local Controller = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUIController"))

local Client = script.Parent
local PokeController = require(Client:WaitForChild("PokeController"))
local GrabController = require(Client:WaitForChild("GrabController"))
local PlayerBody = require(Client:WaitForChild("PlayerBody"))
local LabCamera = require(Client:WaitForChild("LabCamera"))
local FirstPerson = require(Client:WaitForChild("FirstPerson"))
local ToolCatalog = require(Client:WaitForChild("ToolCatalog"))
local TouchShoot = require(Client:WaitForChild("TouchShoot"))
local ViewMode = require(Client:WaitForChild("ViewMode"))
local ReplayController = require(Client:WaitForChild("ReplayController"))
local Spectate = require(Client:WaitForChild("Spectate"))

local GamepadControls = {}

local player = Players.LocalPlayer
local firing = false
local usedPad = false

-- Whether the last input was a gamepad (hints show pad buttons then).
function GamepadControls.active(): boolean
	return PadMap.isPad(UserInputService:GetLastInputType())
end

-- A PlayStation pad (its buttons are named differently).
function GamepadControls.playstation(): boolean
	local ok, name = pcall(function()
		return UserInputService:GetStringForKeyCode(Enum.KeyCode.ButtonA)
	end)
	return ok and type(name) == "string" and string.find(string.lower(name), "cross", 1, true) ~= nil
end

-- A hint's button: "RT" / "R2" etc.
function GamepadControls.glyph(name: string): string
	return PadMap.glyph(name, GamepadControls.playstation())
end

-- Whether a pad was used this visit (SessionClient reports it).
function GamepadControls.used(): boolean
	return usedPad
end

local function fireLoop()
	if firing then
		return
	end
	firing = true
	task.spawn(function()
		while firing do
			if ReplayController.isPlaying() or not PokeController.active() then
				break
			end
			local toy = Toys.byId[PokeController.getSelected()]
			if PokeController.getSelected() == "Grab" then
				GrabController.padGrab()
				break
			end
			TouchShoot.fire()
			if not toy or not (toy.auto == true or toy.id == "Chainsaw") then
				break -- (one round a press: pistols, specials, thrown things)
			end
			local cooldown = toy.cooldown
			if player:GetAttribute("ZeroDelay") == true then
				cooldown = math.min(cooldown, Shop.ZERO_DELAY)
			end
			task.wait(math.max(cooldown, 0.045) + 0.005)
		end
		firing = false
	end)
end

local function cycleView()
	if ReplayController.isPlaying() then
		return
	end
	if ViewMode.isLab() then
		LabCamera.toggleView() -- back to the player view
	elseif FirstPerson.isOn() then
		FirstPerson.set(false)
		-- (V9-0w: right after the first shot's glide, Select is "switch back": to the player view,
		-- not on to the lab view.)
		local justTaught = false
		pcall(function()
			justTaught = (require(Client:WaitForChild("FirstShotFP")) :: any).takeSwitchBack()
		end)
		if not justTaught then
			LabCamera.toggleView()
		end
	else
		FirstPerson.set(true, true)
	end
end

GamepadControls.actions = {
	busy = function(): boolean
		return Controller.getCurrent() ~= nil
	end,
	fire = function(down: boolean)
		if down then
			fireLoop()
		else
			firing = false
		end
	end,
	aim = function(down: boolean)
		local GunFeel = require(Client:WaitForChild("GunFeel")) :: any
		GunFeel.setZoomToggle(down)
	end,
	slot = function(step: number)
		if Spectate.isWatching() then
			Spectate.next() -- (the owner's SPECTATE bar: LB / RB = NEXT)
			return
		end
		PokeController.cycle(step)
	end,
	tab = function(step: number): boolean
		return ToolCatalog.stepTab(step)
	end,
	weapons = function()
		if ToolCatalog.isOpen() then
			ToolCatalog.toggle()
		else
			PokeController.openCatalog()
		end
	end,
	grab = function()
		GrabController.padGrab()
	end,
	ragdoll = function()
		if Spectate.isWatching() then
			Spectate.stop() -- (B = STOP while spectating)
		elseif not ViewMode.isLab() then
			PlayerBody.toggle()
		end
	end,
	view = cycleView,
	menu = function()
		Controller.toggle("Menu")
	end,
	shop = function()
		Controller.toggle("Events")
	end,
} :: PadMap.Actions

local function onAction(name: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	return PadMap.handle(GamepadControls.actions, name, state, input and input.KeyCode)
end

function GamepadControls.start()
	-- Select picks our view, not Roblox's UI cursor (MENU holds every launcher on a pad).
	GuiService.AutoSelectGuiEnabled = false
	for _, binding in PadMap.BINDINGS do
		ContextActionService:BindActionAtPriority(binding.action, onAction, false, PadMap.PRIORITY, table.unpack(binding.keys))
	end
	local function note(kind: Enum.UserInputType)
		if PadMap.isPad(kind) then
			usedPad = true
		end
	end
	note(UserInputService:GetLastInputType())
	UserInputService.LastInputTypeChanged:Connect(note)
end

return GamepadControls
