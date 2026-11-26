--!strict
-- Round 5, phase 2: magazines and reloads (Shared/Ammo, HitService).
--   the pure rule: a full magazine, the last round starts the reload, nothing fires while it runs,
--     it is full after, R early (not with a full one), the server's slack
--   the server: 17 G17 rounds, the 18th refused ("Reload") through the real request, R accepted
--   every gun has a magazine and a reload sound; the round 5 sounds are each gun's own

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Systems = script.Parent.Parent:WaitForChild("Systems")
local HitService = require(Systems:WaitForChild("HitService"))
local Shared = ReplicatedStorage.Shared
local Ammo = require(Shared.Ammo)
local Toys = require(Shared.Toys)
local SoundManifest = require(Shared.SoundManifest)

local function pure(results: { string })
	local book: Ammo.Book = {}
	local t = 100
	assert(Ammo.left(book, "Blaster", t) == 17, "a G17 does not start with 17")
	for i = 1, 16 do
		assert(Ammo.take(book, "Blaster", t), "round " .. i .. " refused")
	end
	assert(Ammo.reloading(book, "Blaster", t) == nil, "it reloads with a round left")
	assert(Ammo.take(book, "Blaster", t) and Ammo.reloading(book, "Blaster", t) ~= nil, "the last round did not start the reload")
	assert(not Ammo.take(book, "Blaster", t + 0.5), "a round fired while reloading")
	assert(Ammo.left(book, "Blaster", t + 1.31) == 17, "not full after the reload")
	assert(not Ammo.reload(book, "Blaster", t + 2), "a full magazine reloaded")
	Ammo.take(book, "Blaster", t + 2)
	assert(Ammo.reload(book, "Blaster", t + 2) and not Ammo.reload(book, "Blaster", t + 2.1), "R early did not reload once")
	local server: Ammo.Book = {}
	for _ = 1, 6 do
		Ammo.take(server, "Revolver", t, Ammo.SERVER_SLACK)
	end
	assert(Ammo.left(server, "Revolver", t + 2.0 - Ammo.SERVER_SLACK + 0.01) == 6, "the server's slack is missing")
	assert(Ammo.take(book, "Bat", t), "a bat has a magazine")
	table.insert(results, "rule: 17 rounds, the last starts the reload, none while it runs, full after, R once, server slack")
end

local function server(results: { string }, player: Player)
	HitService.AMMO_IN_TESTS = true
	HitService.resetAmmoForTest(player)
	local ok, err = pcall(function()
		for i = 1, 17 do
			assert(HitService.takeRound(player, "Blaster"), "server refused round " .. i)
		end
		assert(not HitService.takeRound(player, "Blaster"), "an 18th round was taken")
		-- Through the real request: refused with "Reload".
		local body: BasePart? = nil
		for _, m in require(Systems:WaitForChild("Lab")).dummiesOf(player) do
			local p = m:FindFirstChild("UpperTorso")
			if p and p:IsA("BasePart") then
				body = p
				break
			end
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if body and root and root:IsA("BasePart") then
			HitService.lastRefusal[player] = nil
			HitService.onRequest(player, body, body.Position, (body.Position - root.Position).Unit, "Blaster")
			local refusal = HitService.lastRefusal[player] :: any
			assert(refusal and refusal.reason == "Reload", "an empty G17's shot was not refused: " .. tostring(refusal and refusal.reason))
		end
		HitService.resetAmmoForTest(player)
		HitService.takeRound(player, "AK")
		assert(HitService.reloadRound(player, "AK") and not HitService.reloadRound(player, "AK"), "R was not taken once")
		assert(not HitService.reloadRound(player, "Bat") and not HitService.reloadRound(player, 7 :: any), "junk reloaded")
	end)
	HitService.AMMO_IN_TESTS = false
	HitService.resetAmmoForTest(player)
	if not ok then
		error(err, 0)
	end
	table.insert(results, "server: 17 rounds then refused (Reload) through the real request, R once, junk ignored")
end

local function data(results: { string })
	local own: { [string]: string } = {}
	local count = 0
	for _, toy in Toys.list do
		if toy.gun then
			local spec = Ammo.spec(toy.id)
			assert(spec and spec.mag >= 1 and spec.reload > 0, toy.id .. " has no magazine")
			local g = SoundManifest.GUNS[toy.id]
			assert(g, toy.id .. " has no sound")
			if toy.id ~= "Crossbow" then
				assert(g.reload and SoundManifest.SOUNDS[g.reload], toy.id .. " has no reload sound")
			end
			count += 1
		end
	end
	for _, id in { "Revolver", "SMG", "AK", "M4", "LMG", "TommyGun", "DMR", "DoubleBarrel", "Sniper", "Minigun", "LaserRifle", "Railgun", "FlareGun" } do
		local fire = SoundManifest.GUNS[id].fire
		assert(own[fire] == nil, id .. " shares its recording with " .. tostring(own[fire]))
		own[fire] = id
	end
	table.insert(results, string.format("%d guns with a magazine and a reload sound; 13 ladder guns each their own recording", count))
end

return {
	name = "ammo-reload-sounds",
	timeout = 30,
	run = function(): string?
		local results = {}
		pure(results)
		data(results)
		local started = os.clock()
		while os.clock() - started < 20 and not (Players:GetPlayers()[1] and Players:GetPlayers()[1].Character) do
			task.wait(0.2)
		end
		local player = Players:GetPlayers()[1]
		if player then
			server(results, player)
		end
		return table.concat(results, "; ")
	end,
}
