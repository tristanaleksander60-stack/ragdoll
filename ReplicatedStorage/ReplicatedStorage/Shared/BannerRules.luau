--!strict
-- 21 Nov 2026 (the owner: "make the messages that pop up, like SURPRISE, much nicer"): which lines
-- are big moments that get the centre banner (Client/Banner) instead of a toast, and how each one
-- looks. Pure: the client and the tests read it.
--   title  the big word (2 words at most), sub  the line under it, color  the ribbon's colour,
--   icon   a drawn icon name (LihFolkUIIcons/DrawnIcons) or "", emoji  shown when the icon is not
--   there, priority  1..4 (4 jumps the queue).

local BannerRules = {}

export type Spec = { title: string, sub: string, color: Color3, icon: string, emoji: string, priority: number }

-- Vault (UI Motion Language and Timing; Centre-Screen Announcements): enter 0.18-0.30 s, exit about
-- 0.6-0.75 of it, a hold of 2-4 s, a short queue that speeds up when it backs up.
BannerRules.ENTER = 0.26
BannerRules.EXIT = 0.16
BannerRules.HOLD = 2.6
BannerRules.HOLD_BUSY = 1.4 -- (when more than two wait)
BannerRules.QUEUE_MAX = 4
BannerRules.STALE = 6 -- s a banner may wait before it is no longer worth showing
BannerRules.Y = 0.3 -- its middle, as a share of the screen's height (under the top bar and the goal line)

local PURPLE = Color3.fromRGB(150, 70, 255)
local RED = Color3.fromRGB(235, 60, 60)
local ORANGE = Color3.fromRGB(255, 120, 30)
local GREEN = Color3.fromRGB(40, 190, 90)
local BLUE = Color3.fromRGB(40, 140, 255)

-- Emoji and spaces at the front of a line go (the banner draws its own picture).
local function clean(text: string): string
	local s = text
	-- (Strip leading non-letters: emoji bytes are above 127, spaces and symbols below A.)
	local i = 1
	while i <= #s do
		local b = string.byte(s, i)
		if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or (b >= 48 and b <= 57) then
			break
		end
		i += 1
	end
	return string.sub(s, i)
end

local function upper(s: string): string
	return (string.upper(s))
end

-- The banner for a line, or nil (a toast as before).
function BannerRules.of(text: string): Spec?
	if type(text) ~= "string" or #text == 0 or #text > 120 then
		return nil
	end
	local s = clean(text)
	local rest = string.match(s, "^SURPRISE!%s*(.+)$")
	if rest then
		return { title = "SURPRISE!", sub = upper(rest), color = PURPLE, icon = "star", emoji = "\u{2B50}", priority = 3 }
	end
	if string.find(s, "^BULLSEYE!") then
		return { title = "BULLSEYE!", sub = "RIGHT ON TARGET", color = RED, icon = "", emoji = "\u{1F3AF}", priority = 3 }
	end
	if string.find(s, "^GOD MODE!") then
		return { title = "GOD MODE!", sub = "CREATE LIFE", color = Color3.fromRGB(240, 180, 30), icon = "god", emoji = "\u{2728}", priority = 3 }
	end
	local cleared = string.match(s, "^CHASE CLEARED!%s*(.*)$")
	if cleared then
		return { title = "CHASE CLEARED!", sub = if cleared ~= "" then upper(cleared) else "YOU WON", color = GREEN, icon = "crown", emoji = "\u{1F451}", priority = 3 }
	end
	if string.find(s, "^NPC CHASE!") or string.find(s, "^THEY'RE COMING!") then
		return { title = "CHASE!", sub = "KNOCK THEM DOWN", color = ORANGE, icon = "", emoji = "\u{26A0}\u{FE0F}", priority = 4 }
	end
	if string.find(s, "^KNOCKED OUT!") then
		return { title = "KNOCKED OUT!", sub = "BACK IN A SECOND", color = BLUE, icon = "", emoji = "\u{1F4AB}", priority = 2 }
	end
	return nil
end

return BannerRules
