local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local event = ReplicatedStorage:WaitForChild("WeaponEvent")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local templates = ServerStorage:WaitForChild("WeaponScripts")
local resetBind = ServerStorage:WaitForChild("WeaponReset")

local states = {} -- [player] = { owned = {id = true}, level = {id = n} }

local function stateOf(player)
	local st = states[player]
	if not st then
		st = { owned = {}, level = {}, mag = {} }
		states[player] = st
	end
	for _, w in ipairs(WeaponData.list) do
		if w.price == 0 then
			st.owned[w.id] = true
			st.level[w.id] = st.level[w.id] or 0
		end
	end
	return st
end

local function toast(player, text)
	shop:FireClient(player, "Toast", text)
end

local function coinsOf(player)
	local stats = player:FindFirstChild("PlayerData")
	return stats and stats:FindFirstChild("Coins")
end

------------------------------------------------------------
-- What each weapon looks like (built from simple parts)
------------------------------------------------------------
local function addPart(tool, name, size, color, material, offset)
	local handle = tool.Handle
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.Massless = true
	p.CFrame = handle.CFrame * CFrame.new(offset)
	p.Parent = tool
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = p
	w.Parent = p
	return p
end

local function makeHandle(tool, size, color, material)
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.Size = size
	h.Color = color
	h.Material = material
	h.CanCollide = false
	h.Parent = tool
	return h
end

local function addMuzzle(tool, size, color, offset)
	local glow = addPart(tool, "BarrelGlow", size, color, Enum.Material.Neon, offset)
	local light = Instance.new("PointLight")
	light.Name = "MuzzleFlash"
	light.Color = color
	light.Range = 14
	light.Brightness = 4
	light.Enabled = false
	light.Parent = glow
end

local LOOKS = {}

-- Melee weapons: the blade/head extends toward the handle's +Z end
LOOKS.Sword = function(tool)
	makeHandle(tool, Vector3.new(0.5, 0.5, 4), Color3.fromRGB(200, 200, 215), Enum.Material.Metal)
end
LOOKS.Katana = function(tool)
	makeHandle(tool, Vector3.new(0.3, 0.35, 4.8), Color3.fromRGB(225, 225, 240), Enum.Material.Metal)
	addPart(tool, "Wrap", Vector3.new(0.42, 0.45, 1.4), Color3.fromRGB(140, 30, 40), Enum.Material.Fabric, Vector3.new(0, 0, -1.7))
	addPart(tool, "Guard", Vector3.new(1.1, 0.2, 0.25), Color3.fromRGB(240, 190, 60), Enum.Material.Metal, Vector3.new(0, 0, -0.9))
end
LOOKS.Axe = function(tool)
	makeHandle(tool, Vector3.new(0.4, 0.4, 4), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	addPart(tool, "AxeHead", Vector3.new(1.7, 0.35, 1.4), Color3.fromRGB(170, 175, 190), Enum.Material.Metal, Vector3.new(0.8, 0, 1.5))
	addPart(tool, "AxeSpike", Vector3.new(0.3, 0.3, 0.9), Color3.fromRGB(170, 175, 190), Enum.Material.Metal, Vector3.new(-0.4, 0, 1.5))
end
LOOKS.Hammer = function(tool)
	makeHandle(tool, Vector3.new(0.45, 0.45, 4.2), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	addPart(tool, "HammerHead", Vector3.new(1.3, 1.3, 2.2), Color3.fromRGB(110, 115, 130), Enum.Material.Metal, Vector3.new(0, 0, 1.9))
end

-- Guns: the muzzle (BarrelGlow) is at the handle's -Z end
LOOKS.Blaster = function(tool)
	makeHandle(tool, Vector3.new(0.6, 0.9, 2), Color3.fromRGB(45, 45, 55), Enum.Material.Metal)
	addMuzzle(tool, Vector3.new(0.3, 0.3, 0.4), Color3.fromRGB(255, 200, 40), Vector3.new(0, 0.1, -1.1))
end
LOOKS.Rapid = function(tool)
	makeHandle(tool, Vector3.new(0.5, 0.8, 2.2), Color3.fromRGB(40, 70, 110), Enum.Material.Metal)
	addPart(tool, "Magazine", Vector3.new(0.4, 1.0, 0.5), Color3.fromRGB(30, 30, 40), Enum.Material.Metal, Vector3.new(0, -0.8, 0.1))
	addMuzzle(tool, Vector3.new(0.3, 0.3, 0.4), Color3.fromRGB(80, 220, 255), Vector3.new(0, 0.1, -1.2))
end
LOOKS.Scatter = function(tool)
	makeHandle(tool, Vector3.new(0.7, 0.8, 2.8), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
	addPart(tool, "Pipe", Vector3.new(0.6, 0.6, 1.2), Color3.fromRGB(40, 40, 50), Enum.Material.Metal, Vector3.new(0, 0.1, -1.8))
	addMuzzle(tool, Vector3.new(0.45, 0.45, 0.3), Color3.fromRGB(255, 140, 40), Vector3.new(0, 0.1, -2.55))
end
LOOKS.Longshot = function(tool)
	makeHandle(tool, Vector3.new(0.45, 0.6, 3.6), Color3.fromRGB(40, 80, 50), Enum.Material.Metal)
	addPart(tool, "Scope", Vector3.new(0.35, 0.35, 1.2), Color3.fromRGB(15, 15, 20), Enum.Material.Metal, Vector3.new(0, 0.5, -0.3))
	addMuzzle(tool, Vector3.new(0.25, 0.25, 0.4), Color3.fromRGB(255, 70, 70), Vector3.new(0, 0.1, -2.0))
end

-- plain looks used when a weapon in WeaponData has no LOOKS entry yet
LOOKS._defaultMelee = function(tool)
	makeHandle(tool, Vector3.new(0.5, 0.5, 3.5), Color3.fromRGB(170, 170, 185), Enum.Material.Metal)
end
LOOKS._defaultGun = function(tool)
	makeHandle(tool, Vector3.new(0.6, 0.9, 2), Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
	addMuzzle(tool, Vector3.new(0.3, 0.3, 0.4), Color3.fromRGB(255, 255, 255), Vector3.new(0, 0.1, -1.1))
end

local function buildTool(w, level, magLevel)
	local tool = Instance.new("Tool")
	tool.Name = w.name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = w.desc
	tool:SetAttribute("WeaponId", w.id)
	tool:SetAttribute("Level", level)
	tool:SetAttribute("Damage", w.damage)
	tool:SetAttribute("IsGun", w.kind == "gun")
	for k, v in pairs(w.stats) do
		tool:SetAttribute(k, v)
	end
	magLevel = magLevel or 0
	tool:SetAttribute("MagLevel", magLevel)
	if w.kind == "gun" then
		tool:SetAttribute("MagSize", WeaponData.magSizeAt(w, magLevel))
	end

	local look = LOOKS[w.id]
	if not look then
		warn("No look defined for weapon " .. tostring(w.id) .. ", using a plain one")
		look = (w.kind == "gun") and LOOKS._defaultGun or LOOKS._defaultMelee
	end
	look(tool)

	if w.kind == "melee" then
		tool.Grip = CFrame.new(0, 0, -1.5) * CFrame.Angles(math.rad(90), 0, 0)
		templates.MeleeServer:Clone().Parent = tool
	else
		local fire = Instance.new("RemoteEvent")
		fire.Name = "Fire"
		fire.Parent = tool
		local reload = Instance.new("RemoteEvent")
		reload.Name = "Reload"
		reload.Parent = tool
		templates.GunServer:Clone().Parent = tool
		templates.GunClient:Clone().Parent = tool
	end
	return tool
end

------------------------------------------------------------
-- Giving weapons, buying, upgrading
------------------------------------------------------------
local function findTool(player, id)
	for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("WeaponId") == id then
					return t
				end
			end
		end
	end
end

local function giveAll(player)
	local st = stateOf(player)
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")

	local function clear(container)
		if not container then return end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") and t:GetAttribute("WeaponId") then
				t:Destroy()
			end
		end
	end
	clear(backpack)
	clear(player.Character)
	local practice = player:GetAttribute("InPractice") == true -- the Practice Arena gives every weapon

	-- starter weapons first (slots 1 and 2), then everything you bought
	for pass = 1, 2 do
		for _, w in ipairs(WeaponData.list) do
			if (st.owned[w.id] or practice) and ((pass == 1) == (w.price == 0)) then
				local ok, err = pcall(function()
					buildTool(w, st.level[w.id] or 0, st.mag[w.id] or 0).Parent = backpack
				end)
				if not ok then
					warn("Could not give weapon " .. tostring(w.id) .. ": " .. tostring(err))
				end
			end
		end
	end
end

local function sendList(player)
	local st = stateOf(player)
	local rows = {}
	for _, w in ipairs(WeaponData.list) do
		local owned = st.owned[w.id] == true
		local level = st.level[w.id] or 0
		table.insert(rows, {
			id = w.id,
			name = w.name,
			kind = w.kind,
			desc = w.desc,
			price = w.price,
			owned = owned,
			level = level,
			maxLevel = WeaponData.MAX_LEVEL,
			upgradeCost = level < WeaponData.MAX_LEVEL and WeaponData.upgradeCost(w, level) or 0,
			damage = WeaponData.damageAt(w, level),
			nextDamage = level < WeaponData.MAX_LEVEL and WeaponData.damageAt(w, level + 1) or nil,
			pellets = w.stats.Pellets,
			magLevel = st.mag[w.id] or 0,
			maxMagLevel = WeaponData.MAX_MAG_LEVEL,
			magSize = w.kind == "gun" and WeaponData.magSizeAt(w, st.mag[w.id] or 0) or nil,
			nextMagSize = (w.kind == "gun" and (st.mag[w.id] or 0) < WeaponData.MAX_MAG_LEVEL) and WeaponData.magSizeAt(w, (st.mag[w.id] or 0) + 1) or nil,
			magCost = (w.kind == "gun" and (st.mag[w.id] or 0) < WeaponData.MAX_MAG_LEVEL) and WeaponData.magCost(w, st.mag[w.id] or 0) or 0,
		})
	end
	event:FireClient(player, "List", rows)
end

event.OnServerEvent:Connect(function(player, action, id)
	if action == "Sync" then
		sendList(player)
		return
	end
	if action ~= "Buy" and action ~= "Upgrade" and action ~= "UpgradeMag" then return end

	-- the Armory is closed between rounds (coins are wiped at the next round start)
	local roundCore = workspace:FindFirstChild("Core")
	if roundCore and (roundCore:GetAttribute("Health") or 0) <= 0 then
		toast(player, "No round is running right now")
		sendList(player)
		return
	end

	local w = WeaponData.byId[id]
	local coins = coinsOf(player)
	if not w or not coins then return end
	local st = stateOf(player)

	if action == "UpgradeMag" then
		local mag = st.mag[id] or 0
		if w.kind ~= "gun" then
			toast(player, "Only guns have magazines")
		elseif not st.owned[id] then
			toast(player, "Buy the " .. w.name .. " first")
		elseif mag >= WeaponData.MAX_MAG_LEVEL then
			toast(player, w.name .. " magazine is already maxed")
		else
			local cost = WeaponData.magCost(w, mag)
			if coins.Value < cost then
				toast(player, "Need " .. cost .. " coins for a bigger magazine")
			else
				coins.Value -= cost
				st.mag[id] = mag + 1
				local newSize = WeaponData.magSizeAt(w, mag + 1)
				local tool = findTool(player, id)
				if tool then
					local oldSize = tool:GetAttribute("MagSize") or newSize
					tool:SetAttribute("MagLevel", mag + 1)
					tool:SetAttribute("MagSize", newSize)
					-- the extra rounds come loaded
					local ammo = tool:GetAttribute("Ammo") or 0
					tool:SetAttribute("Ammo", math.min(newSize, ammo + (newSize - oldSize)))
				end
				toast(player, w.name .. " magazine is now " .. newSize .. " rounds!")
			end
		end
	elseif action == "Buy" then
		if w.price == 0 or st.owned[id] then
			toast(player, "You already own the " .. w.name)
		elseif coins.Value < w.price then
			toast(player, "Need " .. w.price .. " coins for the " .. w.name)
		else
			coins.Value -= w.price
			st.owned[id] = true
			st.level[id] = 0
			local backpack = player:FindFirstChildOfClass("Backpack")
			local built = true
			if backpack then
				built = pcall(function()
					buildTool(w, 0).Parent = backpack
				end)
			end
			if built then
				toast(player, "Bought the " .. w.name .. "! Check your hotbar")
			else
				coins.Value += w.price -- refund
				st.owned[id] = nil
				toast(player, "Could not give the " .. w.name .. " - you were not charged")
			end
		end
	else -- Upgrade
		if not st.owned[id] then
			toast(player, "Buy the " .. w.name .. " first")
		else
			local level = st.level[id] or 0
			if level >= WeaponData.MAX_LEVEL then
				toast(player, w.name .. " is already maxed")
			else
				local cost = WeaponData.upgradeCost(w, level)
				if coins.Value < cost then
					toast(player, "Need " .. cost .. " coins to upgrade")
				else
					coins.Value -= cost
					st.level[id] = level + 1
					local tool = findTool(player, id)
					if tool then
						tool:SetAttribute("Level", level + 1)
					end
					toast(player, w.name .. " upgraded to Level " .. (level + 1) .. "!")
				end
			end
		end
	end
	sendList(player)
end)

-- fresh start each round: forget bought weapons and levels
resetBind.Event:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		states[player] = nil
		giveAll(player)
		sendList(player)
	end
end)

local function onPlayer(player)
	player:GetAttributeChangedSignal("InPractice"):Connect(function()
		giveAll(player)
	end)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		giveAll(player)
	end)
	if player.Character then
		task.spawn(function()
			task.wait(0.2)
			giveAll(player)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)
