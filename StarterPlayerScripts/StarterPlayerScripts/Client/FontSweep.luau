--!strict
-- FontSweep (AUDIT 33, Config.FONT_SWEEP): one house font. About 28 older screens still set FredokaOne, Gotham or
-- SourceSans by hand. Every text that appears in the PlayerGui with one of those gets the kit's BuilderSans instead:
-- FredokaOne (the old headline font) -> Theme.Fonts.display, Gotham and SourceSans -> Theme.Fonts.body.
-- The screens keep their code; only the look is made one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")) :: any

local FontSweep = {}

function FontSweep.start()
	if not Config.FONT_SWEEP then
		return
	end
	task.spawn(function()
		local Theme = require(ReplicatedStorage:WaitForChild("LihFolkUI"):WaitForChild("LihFolkUITheme")) :: any
		local display: Font = Theme.Fonts.display
		local body: Font = Theme.Fonts.body
		local function fix(o: Instance)
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				local t = o :: any
				local family = t.FontFace.Family
				if string.find(family, "FredokaOne", 1, true) then
					t.FontFace = display
				elseif string.find(family, "Gotham", 1, true) or string.find(family, "SourceSans", 1, true) then
					t.FontFace = Font.new(body.Family, t.FontFace.Weight, t.FontFace.Style)
				end
			end
		end
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		pg.DescendantAdded:Connect(function(o)
			task.defer(fix, o)
		end)
		for _, o in pg:GetDescendants() do
			fix(o)
		end
	end)
end

return FontSweep
