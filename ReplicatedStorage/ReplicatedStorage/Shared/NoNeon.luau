--!strict
-- V9-NOW 18 (owner, 21 Nov 2026: "remove all the neon glow in the lab and on the maps, it looks like AI slop"):
-- one pass, on the server for the built world and on each screen for what that screen builds, that turns every
-- Neon part bigger than KEEP_SIZE into a matte part (SmoothPlastic, a calmer shade of its colour) and caps the
-- brightness of world screens (SurfaceGui Brightness <= 1, so no bloom halo). Kept glowing:
--   * short-lived effects: a new Neon part is only looked at after SETTLE s, and a flash, a blast, a beam or a
--     tracer is gone by then;
--   * tiny status LEDs (no side over KEEP_SIZE);
--   * the lava's own heat and anything whose ancestor carries the attribute KeepGlow;
--   * what players and dummies wear or hold (characters, tools), the camera's own things (viewmodel).
-- Pure enough to test: NoNeon.shouldDull(part) and NoNeon.dull(part).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NoNeon = {}

NoNeon.KEEP_SIZE = 0.5 -- studs: a part with no side over this may glow (an LED)
NoNeon.SETTLE = 3 -- s a new Neon part must stay before it is dulled (effects are gone by then)
NoNeon.CALM = 0.18 -- share of grey mixed into the colour (calmer, matte)
NoNeon.KEEP_NAMES = { "Lava", "Muzzle", "Flash", "Blast", "Boom", "Explosion", "Spark", "Tracer", "Beam", "Laser", "Bolt", "Fire", "Ember", "Nuke", "Shock", "Trail" }

local GREY = Color3.fromRGB(70, 72, 78)
local dulled = 0

local function keptByName(name: string): boolean
	for _, word in NoNeon.KEEP_NAMES do
		if string.find(name, word, 1, true) then
			return true
		end
	end
	return false
end

-- Whether this part should lose its glow.
function NoNeon.shouldDull(part: Instance): boolean
	if not part:IsA("BasePart") or part.Material ~= Enum.Material.Neon then
		return false
	end
	local s = part.Size
	if math.max(s.X, s.Y, s.Z) <= NoNeon.KEEP_SIZE then
		return false
	end
	if keptByName(part.Name) then
		return false
	end
	local node: Instance? = part
	while node and node ~= Workspace do
		if node:GetAttribute("KeepGlow") == true or node:IsA("Tool") or node:IsA("Camera") or keptByName(node.Name) then
			return false
		end
		if node:IsA("Model") and (node:FindFirstChildOfClass("Humanoid") or Players:GetPlayerFromCharacter(node)) then
			return false
		end
		node = node.Parent
	end
	return node == Workspace
end

-- Takes the glow off one part: matte plastic, a calmer shade of its colour.
function NoNeon.dull(part: BasePart)
	part.Material = Enum.Material.SmoothPlastic
	part.Color = part.Color:Lerp(GREY, NoNeon.CALM)
	part.Reflectance = 0
	part:SetAttribute("Dulled", true)
	dulled += 1
end

local function screen(gui: Instance)
	if gui:IsA("SurfaceGui") and gui.Brightness > 1 then
		gui.Brightness = 1
	end
end

local function look(d: Instance)
	if NoNeon.shouldDull(d) then
		NoNeon.dull(d :: BasePart)
	elseif d:IsA("SurfaceGui") then
		screen(d)
	end
end

-- Tests: how many parts this copy has dulled.
function NoNeon.count(): number
	return dulled
end

local started = false
-- Dulls the world now (after `delay` s) and every Neon part added later that stays SETTLE s.
function NoNeon.start(delay: number?)
	if started then
		return
	end
	started = true
	task.delay(delay or 0, function()
		local all = Workspace:GetDescendants()
		for i, d in all do
			look(d)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)
	Workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			if d.Material == Enum.Material.Neon then
				task.delay(NoNeon.SETTLE, function()
					if d.Parent and NoNeon.shouldDull(d) then
						NoNeon.dull(d)
					end
				end)
			end
		elseif d:IsA("SurfaceGui") then
			task.defer(screen, d)
		end
	end)
end

return NoNeon
