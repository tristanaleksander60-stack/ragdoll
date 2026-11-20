--!strict
-- V9-0i (owner, 21 Nov 2026: "make the whole shop 3D, interactive and beautiful"): what the SHOP's
-- 3D cards are built from is on every screen. ReplicatedStorage.ShopModels holds a clean copy of each
-- prop the showcases name (anchored, nothing colliding, no scripts, sounds or prompts), within a part
-- budget; every weapon a showcase fans out exists in N7Assets.Weapons; every showcase key is sold;
-- the 3D budget per device (Config.UI_3D_LIVE) holds a few turning at once, the low end none. (The
-- client side, cards with prices, the detail view opening and closing, is ShopV9.selfCheck: the
-- DevShopCheck hook in Studio.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopArt = require(Shared:WaitForChild("ShopArt")) :: any
local Config = require(Shared:WaitForChild("Config")) :: any
local TestLib = require(script.Parent:WaitForChild("Lib"):WaitForChild("TestLib")) :: any

local BUDGET = 700 -- parts in all the replicated showcase props

return {
	name = "T165_Shop3D",
	timeout = 20,
	run = function(): string?
		assert(TestLib.waitFor(function()
			return ReplicatedStorage:FindFirstChild("ShopModels") ~= nil
		end, 10), "no ReplicatedStorage.ShopModels")
		local folder = (ReplicatedStorage :: any).ShopModels :: Folder
		local source = ServerStorage:FindFirstChild("V3Assets")
		local parts, models = 0, 0
		for _, role in ShopArt.MODELS do
			local has = source and source:FindFirstChild(role) ~= nil
			local copy = folder:FindFirstChild(role)
			if has then
				assert(copy, "the showcase prop " .. role .. " was not copied for the screens")
			end
			if copy then
				models += 1
				for _, d in copy:GetDescendants() do
					assert(not (d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("ClickDetector")), role .. " carries a " .. d.ClassName)
					if d:IsA("BasePart") then
						parts += 1
						assert(d.Anchored and not d.CanCollide, role .. " has a loose or colliding part")
					end
				end
			end
		end
		assert(parts <= BUDGET, string.format("the showcase props are %d parts (budget %d)", parts, BUDGET))
		local weapons = (ReplicatedStorage :: any).N7Assets.Weapons
		local items = {}
		for _, item in ShopArt.items() do
			items[item.key] = true
		end
		local shows = 0
		for key, spec in ShopArt.SHOW do
			assert(items[key], "a showcase for " .. key .. ", which is not sold")
			for _, id in spec.weapons or {} do
				assert(weapons:FindFirstChild(id), key .. "'s showcase names the weapon " .. id .. ", which has no model")
			end
			if spec.model then
				assert(table.find(ShopArt.MODELS, spec.model), key .. "'s showcase prop " .. spec.model .. " is not copied")
			end
			shows += 1
		end
		local live = Config.UI_3D_LIVE
		assert(Config.SHOP_V9 == true and live and live.low <= 2 and live.high <= 8, "the 3D budget per device is off")
		return string.format("%d showcases (%d props, %d parts, budget %d); weapons all have models; 3D at once: low %d, mid %d, high %d", shows, models, parts, BUDGET, live.low, live.mid, live.high)
	end,
}
