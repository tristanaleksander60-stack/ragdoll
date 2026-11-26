--!strict
-- (session v848, owner: "udskift lavaen med boxing ring"): the lab's hazard pit built as a BOXING
-- RING instead of a lava pool. Same contract as Server/Systems/LavaPit:
--   * takes the existing LavaPool BasePart (the trigger and LaunchVelocity source) and `floorY`;
--   * replaces the visible lava with the V3Assets.BoxingRing model, placed so its canvas sits at the
--     pool's height — stepping on the ring still throws the ragdoll up (buildLava's throwOnTouch);
--   * no glowing beds, no embers, no bubbling sound, no warning picture: the ring itself is the sign;
--   * the pool part turns invisible (same trick LavaPit uses); CanTouch stays on so the throw keeps
--     firing when a body lands on the canvas.
-- The slot name "LavaPool" is kept so Experiments (`kind = "Hazard"`), MachineNames (`Lava = "LAVA"`),
-- PathPlan (points named "Lava"/"West") and Playground's throwOnTouch keep working: the surface and
-- the launch stay a HAZARD, we just changed the picture from LAVA to a BOXING RING. Saves and card
-- progress are not touched.

local BoxingPit = {}

local RING_ASSET = "BoxingRing" -- (V3Assets key; already canonicalized: anchored, no collide/touch/query, PrimaryPart = RingBase)

-- Dresses the hazard pit as a boxing ring round the existing `pool` trigger part.
-- `floorY` is the top of the lab floor (same y that LavaPit's rocks and scorch sit on).
-- Returns the folder it parented under `pool.Parent`, named "BoxingPit".
function BoxingPit.dress(pool: BasePart, floorY: number): Folder
	local into = Instance.new("Folder")
	into.Name = "BoxingPit"

	local c = pool.Position
	local w, d = pool.Size.X, pool.Size.Z

	-- Hide the pool: the ring IS the visible surface. Keep the trigger alive.
	pool.Transparency = 1

	local V3Assets = require(script.Parent:WaitForChild("V3Assets")) :: any
	if not V3Assets.has(RING_ASSET) then
		-- Fall back: a plain dark platform at the pool's footprint. The hazard still works.
		local pad = Instance.new("Part")
		pad.Name = "RingFallback"
		pad.Size = Vector3.new(w, 0.4, d)
		pad.CFrame = CFrame.new(c.X, floorY + 0.2, c.Z)
		pad.Anchored = true
		pad.CanCollide = false
		pad.CanQuery = false
		pad.CanTouch = false
		pad.Color = Color3.fromRGB(40, 32, 30)
		pad.Material = Enum.Material.Fabric
		pad.Parent = into
		into.Parent = pool.Parent
		return into
	end

	-- The ring model is 25.7 wide; the pool is 21 wide. Scale down so the canvas fits the pool's
	-- footprint (so the throwOnTouch area matches what the eye sees). V3Assets.place uses `size`
	-- (largest side target) to scale, not a direct ratio.
	local target = math.max(w, d) * 1.05 -- (1.05: a hair larger so the ropes sit outside the trigger)

	-- V3Assets.place puts the pivot at `at`. In practice the BoxingRing's pivot is set near its base
	-- but the model's bounding-box extends below its pivot (the RingBase mesh sinks its own origin).
	-- Place first, then correct Y so the bbox bottom lands on floorY.
	local ring = V3Assets.place(RING_ASSET, into, CFrame.new(c.X, floorY, c.Z), { size = target, collide = false, name = "BoxingRing" })
	if ring then
		local bbox, bsz = ring:GetBoundingBox()
		local bbottom = bbox.Position.Y - bsz.Y / 2
		local lift = floorY + 0.02 - bbottom -- (+0.02: sit a hair above the floor)
		if math.abs(lift) > 0.01 then
			ring:PivotTo(ring:GetPivot() + Vector3.new(0, lift, 0))
		end
	end
	if ring then
		-- (session v850, owner: "man skal bare kunne hoppe en anelse højere"): the canvas is the one part
		-- that stays solid and touchable so a boxer can walk on it, and the gentle jump boost (below) can
		-- read "the player is on the ring". Everything else (ropes, posts, corner pads) stays non-solid
		-- so the player can walk through.
		local canvas: BasePart? = nil
		for _, p in ring:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = true
				if p.Name == "RingCanvas" or p.Name == "RingBase" then
					canvas = canvas or p
					p.CanCollide = true
					p.CanTouch = true
					p.CanQuery = true
				else
					p.CanCollide = false
					p.CanTouch = false
					p.CanQuery = false
				end
			end
		end
		-- The jump boost: while someone stands on the ring, their Humanoid.JumpPower is a little higher
		-- than normal. Default JumpPower is 50; here it's 80 (a visible springier hop, no launch).
		-- (session v850 round 2): Touched did not fire reliably for a standing avatar (resting contact).
		-- A short region-check loop is cheaper than per-frame raycasts and always catches a stander.
		if canvas then
			local Players = game:GetService("Players")
			local BOOST = 80
			local CHECK = 0.3 -- s between checks; a jump that leaves the ring restores Power within a frame
			local boosted: { [Humanoid]: number } = {} -- original JumpPower per Humanoid
			task.spawn(function()
				while canvas.Parent do
					task.wait(CHECK)
					local c, s = canvas.Position, canvas.Size
					local hx, hz, hy = s.X / 2 + 1, s.Z / 2 + 1, s.Y / 2 + 4 -- (a little pad over the canvas top)
					for _, player in Players:GetPlayers() do
						local char = player.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if hum and root then
							local p = root.Position
							local on = math.abs(p.X - c.X) <= hx and math.abs(p.Z - c.Z) <= hz and p.Y >= c.Y and p.Y - c.Y <= hy
							if on and not boosted[hum] then
								boosted[hum] = hum.JumpPower
								hum.UseJumpPower = true
								hum.JumpPower = BOOST
							elseif not on and boosted[hum] then
								hum.JumpPower = boosted[hum]
								boosted[hum] = nil
							end
						end
					end
				end
			end)
		end
	end

	into.Parent = pool.Parent
	return into
end

return BoxingPit
