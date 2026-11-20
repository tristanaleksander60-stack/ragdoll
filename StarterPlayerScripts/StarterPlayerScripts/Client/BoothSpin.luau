--!strict
-- V6-7: the showcase booths' items turn slowly on their pedestals (MapShopService tags them
-- BoothSpin). On this screen only: nothing on the network; only booths near the camera turn.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BoothSpin = {}

BoothSpin.SPEED = 0.6 -- rad/s
BoothSpin.REACH = 120 -- studs: farther booths stand still

type Spin = { model: Model, base: CFrame, angle: number }
local spins: { [Model]: Spin } = {}

local function add(m: Instance)
	if m:IsA("Model") and not spins[m] then
		spins[m] = { model = m, base = m:GetPivot(), angle = 0 }
	end
end

function BoothSpin.start()
	for _, m in CollectionService:GetTagged("BoothSpin") do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal("BoothSpin"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("BoothSpin"):Connect(function(m)
		spins[m :: Model] = nil
	end)
	RunService.RenderStepped:Connect(function(dt)
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local at = cam.CFrame.Position
		for m, s in spins do
			if not m.Parent then
				spins[m] = nil
			elseif (s.base.Position - at).Magnitude < BoothSpin.REACH then
				s.angle += dt * BoothSpin.SPEED
				m:PivotTo(s.base * CFrame.Angles(0, s.angle, 0))
			end
		end
	end)
end

return BoothSpin
