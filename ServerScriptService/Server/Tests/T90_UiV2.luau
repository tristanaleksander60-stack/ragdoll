--!strict
-- UI v2 (Config.UI_V2): the look's data, checked without a screen.
--   * rarity rises with the ladder and every weapon has one, with a word
--   * the weapon cards' stats are on 1..10 and the best of every shelf fills its bar (the GUNS
--     shelf no longer shows slivers: AUDIT §7)
--   * the kit's tokens: text that draws 14 px at the touch floor, press squish 0.92, readable role
--     faces, rarity colours that stand out on the navy card
--   * every icon the v2 HUD and MENU name is in the drawn set (DrawnIcons)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Toys = require(ReplicatedStorage.Shared.Toys)
local UiRarity = require(ReplicatedStorage.Shared.UiRarity)
local DrawnIcons = require(ReplicatedStorage.Shared.DrawnIcons)
local Theme = require(ReplicatedStorage.LihFolkUI.LihFolkUITheme)

local function luminance(c: Color3): number
	local function lin(v: number): number
		return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end
local function contrast(a: Color3, b: Color3): number
	local x, y = luminance(a), luminance(b)
	return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

-- The icon names KitStyle.HUD_ICONS and HudMenu.ICONS use (client modules: listed here).
local V2_ICONS = {
	"eye", "tool_Shove", "sandbox", "tool_Launch", "tool_Grab", "tool_Kick", "tool_Blaster", "camera",
	"tool_Slowmo", "heart", "tool_Shockwave", "star", "map", "gift", "crown", "friends", "settings", "keys",
	"toolbox", "tool_Punch", "tool_TNT", "event_MegaBomb",
}

return {
	name = "T90_UiV2",
	timeout = 3,
	run = function(): string?
		-- Rarity: never falls as the rung rises; starters are common; every label is a word.
		local ordered = table.clone(Toys.list)
		table.sort(ordered, function(a, b)
			return a.unlockAt < b.unlockAt
		end)
		local last = 0
		local seen: { [string]: boolean } = {}
		for _, toy in ordered do
			local r = UiRarity.of(toy)
			assert(r.rank >= last, toy.id .. " is rarer than a weapon above it on the ladder")
			assert(#r.label >= 4, "a rarity without a word")
			last = r.rank
			seen[r.key] = true
		end
		for _, id in Toys.defaultLoadout do
			assert(UiRarity.of(Toys.byId[id]).key == "Common", id .. " (a starter) is not common")
		end
		local kinds = 0
		for _ in seen do
			kinds += 1
		end
		assert(kinds >= 4, "the ladder shows fewer than 4 rarities")

		-- Stats: 1..10 (0 only for none of it); the best of each shelf is 10.
		local top: { [string]: number } = {}
		for _, toy in Toys.list do
			local s = UiRarity.stats(toy)
			local values: { [string]: number } = { power = s.power, speed = s.speed, chaos = s.chaos }
			for name, v in values do
				assert(v >= 0 and v <= UiRarity.SCALE and v == math.floor(v), toy.id .. " " .. name .. " off the scale")
			end
			top[toy.category] = math.max(top[toy.category] or 0, s.power)
		end
		for category, best in top do
			assert(best == UiRarity.SCALE, category .. ": its best weapon does not fill the POWER bar")
		end
		local guns, readable = 0, 0
		for _, toy in Toys.list do
			if toy.category == "Guns" then
				guns += 1
				if UiRarity.stats(toy).power >= 3 then
					readable += 1
				end
			end
		end
		assert(readable * 2 >= guns, "most guns still draw a sliver of POWER")

		if Config.UI_V2 then
			assert(Theme.V2 == true, "Config.UI_V2 is on but the kit did not take the v2 tokens")
			local floorScale = Theme.Size.touchDrawnMin / Theme.Size.touchMin
			assert(Theme.MinTextSize * floorScale >= 14, "the fitted text floor draws under 14 px on a phone")
			for name, spec in Theme.Text do
				assert(spec.size * floorScale >= 14, "text style " .. name .. " draws under 14 px on a phone")
			end
			-- (V5 UI_CLEAN: a gentler press, 0.96; V2 alone: 0.92.)
			local squish = if (Theme :: any).Clean then 0.96 else 0.92
			assert(math.abs(Theme.Motion.pressScale - squish) < 1e-6, "the press squish is not " .. squish)
			for name, role in Theme.Roles do
				local need = if role.textStroke then 3 else 4.5
				assert(contrast(role.text, role.bottom) >= need, "role " .. name .. ": its text does not read on its face")
			end
			for _, r in UiRarity.LIST do
				assert(contrast(r.color, Theme.Palette.duskRaised) >= 3, r.label .. " does not stand out on the card")
			end
			assert(contrast(Theme.Palette.textHi, Theme.Palette.dusk) >= 7, "titles do not read on the canvas")
			assert(contrast(Theme.Palette.textLow, Theme.Palette.dusk) >= 4.5, "captions do not read on the canvas")
		end
		for _, name in V2_ICONS do
			assert((DrawnIcons.ASSETS :: any)[name], "the v2 look names an icon that is not drawn: " .. name)
		end
		return string.format("%d weapons: %d rarities, stats on 1..%d, %d/%d guns read; tokens %s", #Toys.list, kinds, UiRarity.SCALE, readable, guns, if Config.UI_V2 then "v2" else "v1")
	end,
}
