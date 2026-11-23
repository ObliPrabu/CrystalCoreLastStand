-- Hats: buy once with round coins, owned forever. Ownership lives in two player attributes that
-- DataManager loads and saves: OwnedHats ("Cap,Crown") and EquippedHat ("Crown" or "").
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HatData = require(ReplicatedStorage:WaitForChild("HatData"))
local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local core = Workspace:WaitForChild("Core")

local event = Instance.new("RemoteEvent")
event.Name = "HatEvent"
event.Parent = ReplicatedStorage

local function toast(player, text) shop:FireClient(player, "Toast", text) end

local function ownedSet(player)
	local set = {}
	for id in string.gmatch(player:GetAttribute("OwnedHats") or "", "[^,]+") do
		if HatData.byId[id] then set[id] = true end
	end
	return set
end

local function saveOwned(player, set)
	local ids = {}
	for _, h in ipairs(HatData.list) do
		if set[h.id] then table.insert(ids, h.id) end
	end
	player:SetAttribute("OwnedHats", table.concat(ids, ","))
end

local function sendList(player)
	local owned = ownedSet(player)
	local worn = player:GetAttribute("EquippedHat") or ""
	local rows = {}
	for _, h in ipairs(HatData.list) do
		table.insert(rows, { id = h.id, name = h.name, desc = h.desc, price = h.price,
			owned = owned[h.id] == true, equipped = worn == h.id })
	end
	event:FireClient(player, "List", rows)
end

-- build the hat on the character's head
local function removeHat(char)
	local old = char:FindFirstChild("CCHat")
	if old then old:Destroy() end
end

local function applyHat(player)
	local char = player.Character
	if not char then return end
	removeHat(char)
	local id = player:GetAttribute("EquippedHat") or ""
	local hat = HatData.byId[id]
	if not hat or not ownedSet(player)[id] then return end
	local head = char:FindFirstChild("Head")
	if not head then return end

	local s = head.Size.X / 2 -- hats are designed for a 2-stud head
	local top = head.Size.Y / 2
	local model = Instance.new("Model")
	model.Name = "CCHat"
	for _, p in ipairs(hat.parts) do
		local part = Instance.new("Part")
		part.Size = p.size * s
		part.Color = p.color
		part.Material = p.material or Enum.Material.SmoothPlastic
		part.Transparency = p.trans or 0
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.Massless = true
		part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		local offset = CFrame.new(Vector3.new(p.pos.X * s, top + p.pos.Y * s, p.pos.Z * s))
		if p.shape == "cyl" then
			part.Shape = Enum.PartType.Cylinder
			offset = offset * CFrame.Angles(0, 0, math.pi / 2) -- cylinders lie along X: stand them up
		end
		part.CFrame = head.CFrame * offset
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = head, part
		weld.Parent = part
	end
	model.Parent = char
end

event.OnServerEvent:Connect(function(player, action, id)
	if action == "Sync" then
		sendList(player)
		return
	end
	if typeof(id) ~= "string" and action ~= "Unequip" then return end
	local owned = ownedSet(player)

	if action == "Buy" then
		local hat = HatData.byId[id]
		if not hat or owned[id] then return end
		if (core:GetAttribute("Health") or 0) <= 0 then
			toast(player, "No round is running right now")
			return sendList(player)
		end
		local data = player:FindFirstChild("PlayerData")
		local coins = data and data:FindFirstChild("Coins")
		if not coins then return end
		if coins.Value < hat.price then
			toast(player, ("Not enough coins for the %s (%d)"):format(hat.name, hat.price))
			return sendList(player)
		end
		coins.Value -= hat.price
		owned[id] = true
		saveOwned(player, owned)
		player:SetAttribute("EquippedHat", id)
		toast(player, hat.name .. " is yours - forever!")
	elseif action == "Equip" then
		if not owned[id] then return end
		player:SetAttribute("EquippedHat", id)
	elseif action == "Unequip" then
		player:SetAttribute("EquippedHat", "")
	else
		return
	end
	sendList(player)
end)

local function onPlayer(player)
	player:GetAttributeChangedSignal("EquippedHat"):Connect(function() applyHat(player) end)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("Head", 5)
		task.wait(0.2)
		applyHat(player)
	end)
	if player.Character then task.defer(applyHat, player) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
