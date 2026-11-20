--!strict
-- Who may use the admin menu (owner order, 21 Nov 2026): the owner, and the players the owner made
-- admin. The owner gives and takes it in the admin menu (PLAYERS: MAKE ADMIN / REMOVE ADMIN); nobody
-- else can. Admins get every admin tool, but never against the owner or another admin (kick, bring,
-- go to). The owner alone keeps the director (F8), the owner's party and managing admins.
-- The list lives in DataStore Admins_v1 (key "list": { [userId]: name }), read again every REFRESH s
-- so every server follows within a minute; changes go through UpdateAsync. Studio keeps it in memory
-- (never the live store). A play-as-newcomer visit (TestAccount) is never an admin.
-- Player attribute IsAdmin (true / nil) tells the client to show the menu; every action is still
-- checked here.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Owner = require(script.Parent:WaitForChild("Owner"))

local Admins = {}

Admins.REFRESH = 60 -- s between reads of the shared list
Admins.MAX = 20 -- admins at most

local STORE, KEY = "Admins_v1", "list"
local list: { [string]: string } = {} -- tostring(userId) -> name
local store: DataStore? = nil

local function testVisit(player: Player): boolean
	return (require(script.Parent:WaitForChild("TestAccount")) :: any).is(player)
end

-- The owner, or on the list (never a play-as-newcomer visit).
function Admins.isAdmin(player: Player): boolean
	if Owner.isOwner(player) then
		return true
	end
	if testVisit(player) then
		return false
	end
	return list[tostring(player.UserId)] ~= nil
end

-- Whether this userId is on the list (the owner is not on it: the owner is always admin).
function Admins.listed(userId: number): boolean
	return list[tostring(userId)] ~= nil
end

-- The list for the owner's menu: { { id, name } } sorted by name.
function Admins.entries(): { { id: number, name: string } }
	local out = {}
	for id, name in list do
		local n = tonumber(id)
		if n then
			table.insert(out, { id = n, name = name })
		end
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

local function clean(value: unknown): { [string]: string }
	local out: { [string]: string } = {}
	if type(value) ~= "table" then
		return out
	end
	local n = 0
	for id, name in value :: any do
		if type(id) == "string" and tonumber(id) and type(name) == "string" and n < Admins.MAX then
			out[id] = string.sub(name, 1, 40)
			n += 1
		end
	end
	return out
end

-- Marks every player here as admin or not (the client shows or hides the menu by it).
local function applyAll()
	for _, p in Players:GetPlayers() do
		p:SetAttribute("IsAdmin", if Admins.isAdmin(p) then true else nil)
	end
end

local function read()
	local ds = store
	if not ds then
		return
	end
	local ok, value = pcall(function()
		return ds:GetAsync(KEY)
	end)
	if ok then
		list = clean(value)
		applyAll()
	end
end

-- The owner gives (on = true) or takes admin. Returns ok and a line for the menu.
function Admins.set(by: Player, userId: number, name: string, on: boolean): (boolean, string)
	if not Owner.isOwner(by) then
		return false, "Only the owner can give admin"
	end
	if type(userId) ~= "number" or userId <= 0 or userId ~= math.floor(userId) then
		return false, "Pick a player first"
	end
	if userId == by.UserId then
		return false, "You are the owner: always admin"
	end
	local key = tostring(userId)
	local ds = store
	if ds then
		local refused: string? = nil
		local ok = pcall(function()
			ds:UpdateAsync(KEY, function(old: unknown)
				local cur = clean(old)
				if on then
					local n = 0
					for _ in cur do
						n += 1
					end
					if not cur[key] and n >= Admins.MAX then
						refused = string.format("At most %d admins", Admins.MAX)
						return nil -- (no change)
					end
					cur[key] = string.sub(name, 1, 40)
				else
					cur[key] = nil
				end
				list = cur
				return cur
			end)
		end)
		if refused then
			return false, refused :: string
		end
		if not ok then
			return false, "Could not save it now. Try again"
		end
	else
		if on then
			list[key] = string.sub(name, 1, 40)
		else
			list[key] = nil
		end
	end
	applyAll()
	return true, if on then name .. " is an admin now" else name .. " is no longer an admin"
end

-- Tests: start from an empty list, or put one id on it (memory only: never the live store).
function Admins.resetForTest()
	if store == nil then
		table.clear(list)
		applyAll()
	end
end
function Admins.setForTest(userId: number, on: boolean)
	if store == nil then
		list[tostring(userId)] = if on then "Test" else nil
		applyAll()
	end
end

function Admins.start()
	if not RunService:IsStudio() then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(STORE)
		end)
		if ok then
			store = result
		end
	end
	read()
	applyAll()
	Players.PlayerAdded:Connect(function(p)
		p:SetAttribute("IsAdmin", if Admins.isAdmin(p) then true else nil)
	end)
	task.spawn(function()
		while true do
			task.wait(Admins.REFRESH)
			read()
		end
	end)
end

return Admins
