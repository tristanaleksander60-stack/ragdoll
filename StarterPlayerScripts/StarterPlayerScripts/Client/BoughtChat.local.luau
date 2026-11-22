--!strict
-- BoughtChat (V11 B7, owner 22 Nov 2026: "Robux purchases shown in chat on every server"). Server PurchaseChat
-- fires Remotes.BoughtChat (name, item, price) for a purchase on any server; it is written in chat as a gold
-- system line: "Name bought X for R$N".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = remotes:WaitForChild("BoughtChat", 60)
if not (remote and remote:IsA("RemoteEvent")) then
	return
end

local function escape(s: string): string
	return (string.gsub(string.gsub(string.gsub(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

remote.OnClientEvent:Connect(function(name: string, item: string, price: number)
	if type(name) ~= "string" or type(item) ~= "string" or type(price) ~= "number" then
		return
	end
	local line = string.format('<font color="#FFD24A"><b>%s</b> bought <b>%s</b> for R$%d!</font>', escape(name), escape(item), price)
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		local system = channels and channels:FindFirstChild("RBXSystem")
		if system and system:IsA("TextChannel") then
			system:DisplaySystemMessage(line)
		end
	end)
end)
