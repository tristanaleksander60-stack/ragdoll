--!strict
-- V9-0g: this screen's notice state for NoticeRules: when you last fired or swung (every tool use:
-- PokeController.onUsedAlso; your own shots: FeelBus "Shot"), whether this is a phone, and the
-- "Notices" setting. Toast, Banner, Notify and ProgressUI ask it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NoticeRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NoticeRules")) :: any

local NoticeState = {}

local lastUse = -math.huge
local choice = 1 -- (Settings "Notices"; 1 = AUTO)
local started = false

function NoticeState.used()
	lastUse = os.clock()
end

function NoticeState.lastUse(): number
	return lastUse
end

function NoticeState.setChoice(n: number)
	choice = n
end

-- A phone: the short side of the screen 500 px or less (the same test as HudSlots).
function NoticeState.phone(): boolean
	local camera = Workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	return math.min(v.X, v.Y) <= 500
end

function NoticeState.portrait(): boolean
	local camera = Workspace.CurrentCamera
	local v = if camera then camera.ViewportSize else Vector2.new(1000, 1000)
	return v.Y > v.X
end

function NoticeState.mode(): string
	return NoticeRules.mode(choice, NoticeState.phone())
end

function NoticeState.compact(): boolean
	return NoticeState.mode() ~= "normal"
end

-- The largest compact notice on a screen of `size` (width, height, text px).
function NoticeState.smallBox(size: Vector2): (number, number, number)
	return NoticeRules.smallBox(size, NoticeState.portrait())
end

function NoticeState.busy(): boolean
	return NoticeRules.busy(os.clock(), lastUse)
end

-- Whether an unsolicited notice of `kind` may show now.
function NoticeState.allow(kind: string): boolean
	return NoticeRules.allow(kind, NoticeState.mode() :: any, NoticeState.busy())
end

function NoticeState.start()
	if started then
		return
	end
	started = true
	local Client = script.Parent
	pcall(function()
		table.insert((require(Client:WaitForChild("PokeController", 5)) :: any).onUsedAlso, function()
			NoticeState.used()
		end)
	end)
	pcall(function()
		(require(Client:WaitForChild("FeelBus", 5)) :: any).on("Shot", function(data: any)
			if type(data) == "table" and data.own then
				NoticeState.used()
			end
		end)
	end)
end

return NoticeState
