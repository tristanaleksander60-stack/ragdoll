--!strict
-- How hits look (vault: "Gore Policy and Kid-Friendly Hit Feedback"). The game decides the ceiling,
-- each player may choose less. The maturity label must cover the ceiling, never the default.
--
--   Stylised       stars, sparks and dust only; no red
--   CartoonBlood   lots of bright, flat cartoon blood: drops that fly and fall, comic splats on the
--                  floor that pop and are gone within 3 s. Unrealistic blood: fits the Mild label
--   Blood          realistic blood (needs Moderate; not built, reserved for that decision)

local HitFxConfig = {}

export type Style = "Stylised" | "CartoonBlood" | "Blood"

-- The most this game shows. Lowering it is one constant.
HitFxConfig.MaxStyle = "CartoonBlood" :: Style

-- The player's own choice (attribute "HitFxStyle" on the Player), within the ceiling. Unset: the
-- ceiling (cartoon blood is a reason people play ragdoll games).
function HitFxConfig.effectiveStyle(preference: unknown): Style
	local max = HitFxConfig.MaxStyle
	if max == "Stylised" or preference == "Stylised" then
		return "Stylised"
	end
	if preference == "CartoonBlood" or max == "CartoonBlood" then
		return "CartoonBlood"
	end
	return max
end

return HitFxConfig
