--!strict
-- "Favorite / like the game" (round 4, the owner): a friendly ask. A favourite is one tap in the game
-- (Roblox's own prompt); a like has no in-game prompt, so it says where it is. It gives nothing:
-- Roblox does not allow rewards for liking (the launch gift, LaunchGift on the server, goes to
-- everyone whatever they do). Shown once a visit after SHOW_AFTER s of play (not in the first
-- minute, a replay or while building), and always one tap away in MENU ("FAVORITE").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AvatarEditorService = game:GetService("AvatarEditorService")

local UI = ReplicatedStorage:WaitForChild("LihFolkUI")
local C = require(UI:WaitForChild("LihFolkUIComponents"))
local Controller = require(UI:WaitForChild("LihFolkUIController"))
local Theme = require(UI:WaitForChild("LihFolkUITheme"))

local PokeController = require(script.Parent:WaitForChild("PokeController"))
local Toast = require(script.Parent:WaitForChild("Toast"))
local Notify = require(script.Parent:WaitForChild("Notify")) :: any -- V6-1
local ReplayController = require(script.Parent:WaitForChild("ReplayController"))

local LikePrompt = {}

LikePrompt.SHOW_AFTER = 6 * 60 -- s of play in a visit before it asks once by itself
LikePrompt.WINDOW = Vector2.new(460, 380)

local player = Players.LocalPlayer

-- (The owner, 10 Nov: without leaving the game.) FAVORITE opens Roblox's own favourite prompt right
-- here (AvatarEditorService:PromptSetFavorite with the place: a game is an asset). A thumbs up has
-- no such prompt (Roblox offers none to games), so the window only says where it is.
local favorited = false
local function closeLike()
	if Controller.getCurrent() == "Like" then
		Controller.toggle("Like")
	end
end
local function favorite()
	local ok = pcall(function()
		AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
	if not ok then
		Toast.show("Tap \u{2B50} Favorite on the game's page next time. Thanks!")
		closeLike()
	end
end

local function build()
	local window = C.Window({ name = "Like", title = "Favorite Untitled Ragdoll?", theme = "rebirth", icon = "star", size = LikePrompt.WINDOW })
	C.Text("title", "\u{2B50} Having fun?", { scaled = true, size = UDim2.new(1, 0, 0, 34), layoutOrder = 1, parent = window.body })
	C.Text("body", "Favorite the game to find it fast and hear about new weapons, places and events first. One tap, right here.", { autoY = true, wrap = true, layoutOrder = 2, parent = window.body })
	local fav = C.Button({
		text = "\u{2B50} FAVORITE",
		role = "go",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 3,
		parent = window.body,
		onActivated = favorite,
	})
	C.Text("caption", "\u{1F44D} Liking it? A thumbs up on the game's page (under Play) helps a lot too.", { autoY = true, wrap = true, color = Theme.Palette.textMid, layoutOrder = 4, parent = window.body })
	C.Button({
		text = "NOT NOW",
		role = "neutral",
		size = UDim2.new(1, 0, 0, Theme.Size.buttonH),
		layoutOrder = 5,
		parent = window.body,
		onActivated = function()
			closeLike()
		end,
	})
	window.defaultSelection = fav.hit
	Controller.register(window)
	AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result: Enum.AvatarPromptResult)
		if result == Enum.AvatarPromptResult.Success then
			favorited = true
			closeLike()
			Toast.show("\u{2B50} Thanks for the favorite!")
		end
	end)
end

-- Tests: whether a favourite went through this visit.
function LikePrompt.favorited(): boolean
	return favorited
end
-- Round 5 (the owner: more likes and favourites without being too much): it asks right after a
-- high point of the visit, when players are happiest (a BULLSEYE, a cleared NPC Chase, a combo of
-- WOW_COMBO), at most once a visit and never before MIN_PLAYED s of play; with no high point, after
-- SHOW_AFTER s as before. Still no reward of any kind (Roblox rules).
LikePrompt.SHOW_AFTER = 8 * 60
LikePrompt.MIN_PLAYED = 3 * 60
LikePrompt.WOW_COMBO = 10
LikePrompt.WOW_DELAY = 2.5 -- s after the moment (its own toast first)

function LikePrompt.start()
	build()
	local asked = false
	local played = 0
	local function ask()
		if asked or favorited then
			return
		end
		asked = true
		task.spawn(function()
			-- (Never on top of the first minute, a replay, the build drawer or another window.)
			while PokeController.firstMinute() or ReplayController.isPlaying() or player:GetAttribute("Building") == true or Controller.getCurrent() ~= nil do
				task.wait(1)
			end
			-- (V6-1: through the notification centre: one big pop-up at a time.)
			-- (It waits its turn, and again while another window is up: never dropped.)
			while true do
				Notify.waitBig("Like")
				if favorited then
					Notify.releaseBig("Like")
					return
				end
				-- (Calm again after the wait: no window, replay, build drawer or first minute.)
				if Controller.getCurrent() == nil and not PokeController.firstMinute() and not ReplayController.isPlaying() and player:GetAttribute("Building") ~= true then
					Controller.open("Like")
					break
				end
				Notify.releaseBig("Like")
				task.wait(2)
			end
		end)
	end
	local function wow()
		Notify.goodMoment() -- (V6-1: a good moment may ask for Roblox notifications, once, late)
		if not asked and played >= LikePrompt.MIN_PLAYED then
			task.delay(LikePrompt.WOW_DELAY, ask)
		end
	end
	local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
	Net.event(Net.Names.Progress).OnClientEvent:Connect(function(kind: unknown, data: unknown)
		if kind == "Notice" and type(data) == "string" and (string.find(data, "BULLSEYE") or string.find(data, "CHASE CLEARED")) then
			wow()
		elseif kind == "Combo" and type(data) == "table" and type((data :: any).count) == "number" and (data :: any).count >= LikePrompt.WOW_COMBO then
			wow()
		end
	end)
	task.spawn(function()
		while played < LikePrompt.SHOW_AFTER do
			task.wait(5)
			if player:GetAttribute("OnboardingReady") == true then
				played += 5
			end
		end
		ask()
	end)
end

return LikePrompt
