local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local core = Workspace:WaitForChild("Core")
local enemies = Workspace:WaitForChild("Enemies")

local MAX_TURRETS = 8
local TURRET_RANGE = 55
local TURRET_DAMAGE = 10
local TURRET_INTERVAL = 0.8
local MAX_LEVEL = 5
local REPAIR_COST = 40
local REPAIR_AMOUNT = 60
local FLOOR_TOP = 1

local turretFolder = Workspace:FindFirstChild("Turrets")
if not turretFolder then
	turretFolder = Instance.new("Folder")
	turretFolder.Name = "Turrets"
	turretFolder.Parent = Workspace
end

local function coinsOf(player)
	local st = player:FindFirstChild("PlayerData")
	return st and st:FindFirstChild("Coins")
end

local function toast(player, text)
	shop:FireClient(player, "Toast", text)
end

local function turretCost()
	return 60 + 40 * #turretFolder:GetChildren()
end

local function upgradeCost(player)
	return 80 + 60 * (player:GetAttribute("DmgLevel") or 0)
end

local function freeSlot()
	local used = {}
	for _, t in ipairs(turretFolder:GetChildren()) do
		used[t:GetAttribute("Slot")] = true
	end
	for i = 1, MAX_TURRETS do
		if not used[i] then return i end
	end
	return nil
end

local function buildTurret(slot, ownerId)
	local angle = math.rad((slot - 1) * 45)
	local center = core.Position + Vector3.new(math.cos(angle) * 18, 0, math.sin(angle) * 18)

	local model = Instance.new("Model")
	model.Name = "Turret"
	model:SetAttribute("Slot", slot)
	model:SetAttribute("OwnerId", ownerId or 0)

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.Size = Vector3.new(3.5, 2, 3.5)
	base.Position = Vector3.new(center.X, FLOOR_TOP + 1, center.Z)
	base.Color = Color3.fromRGB(60, 60, 70)
	base.Material = Enum.Material.Metal
	base.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.Size = Vector3.new(2.2, 1.4, 2.6)
	head.Position = Vector3.new(center.X, FLOOR_TOP + 2.7, center.Z)
	head.Color = Color3.fromRGB(70, 200, 255)
	head.Material = Enum.Material.Neon
	head.Parent = model

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Anchored = true
	barrel.CanCollide = false
	barrel.Size = Vector3.new(0.6, 0.6, 2.2)
	barrel.Color = Color3.fromRGB(40, 40, 50)
	barrel.Material = Enum.Material.Metal
	barrel.CFrame = head.CFrame * CFrame.new(0, 0, -2.4)
	barrel.Parent = model

	model.PrimaryPart = head
	model.Parent = turretFolder
end

-- Turret brain: every interval each turret shoots the nearest enemy in range
task.spawn(function()
	while true do
		task.wait(TURRET_INTERVAL)
		for _, t in ipairs(turretFolder:GetChildren()) do
			local head = t:FindFirstChild("Head")
			local barrel = t:FindFirstChild("Barrel")
			if head and barrel then
				local best, bestDist = nil, TURRET_RANGE
				for _, e in ipairs(enemies:GetChildren()) do
					local r = e:FindFirstChild("HumanoidRootPart")
					local h = e:FindFirstChildOfClass("Humanoid")
					if r and h and h.Health > 0 then
						local d = (r.Position - head.Position).Magnitude
						if d < bestDist then best, bestDist = e, d end
					end
				end
				if best then
					local tp = best.HumanoidRootPart.Position
					head.CFrame = CFrame.lookAt(head.Position, Vector3.new(tp.X, head.Position.Y, tp.Z))
					barrel.CFrame = head.CFrame * CFrame.new(0, 0, -2.4)
					best.Humanoid:SetAttribute("LastAttacker", t:GetAttribute("OwnerId") or 0)
					best.Humanoid:TakeDamage(TURRET_DAMAGE)

					local origin = barrel.Position
					local dist = (tp - origin).Magnitude
					local beam = Instance.new("Part")
					beam.Anchored = true
					beam.CanCollide = false
					beam.CanQuery = false
					beam.CanTouch = false
					beam.Material = Enum.Material.Neon
					beam.Color = Color3.fromRGB(90, 220, 255)
					beam.Size = Vector3.new(0.2, 0.2, dist)
					beam.CFrame = CFrame.lookAt(origin, tp) * CFrame.new(0, 0, -dist / 2)
					beam.Parent = Workspace
					Debris:AddItem(beam, 0.07)
				end
			end
		end
	end
end)

shop.OnServerEvent:Connect(function(player, action)
	if (core:GetAttribute("Health") or 0) <= 0 then
		toast(player, "Pick a difficulty first!")
		return
	end
	local coins = coinsOf(player)
	if not coins then return end

	if action == "Turret" then
		local slot = freeSlot()
		if not slot then toast(player, "Max turrets built!") return end
		local cost = turretCost()
		if coins.Value < cost then toast(player, "Need " .. cost .. " coins for a turret") return end
		coins.Value -= cost
		buildTurret(slot, player.UserId)
		toast(player, "Turret built!")
	elseif action == "Upgrade" then
		local level = player:GetAttribute("DmgLevel") or 0
		if level >= MAX_LEVEL then toast(player, "Weapons are maxed out!") return end
		local cost = upgradeCost(player)
		if coins.Value < cost then toast(player, "Need " .. cost .. " coins to upgrade") return end
		coins.Value -= cost
		player:SetAttribute("DmgLevel", level + 1)
		toast(player, "Weapon damage +25%! (Level " .. (level + 1) .. ")")
	elseif action == "Repair" then
		local hp = core:GetAttribute("Health") or 0
		local maxHp = core:GetAttribute("MaxHealth") or hp
		if hp >= maxHp then toast(player, "Core is already at full health") return end
		if coins.Value < REPAIR_COST then toast(player, "Need " .. REPAIR_COST .. " coins to repair") return end
		coins.Value -= REPAIR_COST
		core:SetAttribute("Health", math.min(maxHp, hp + REPAIR_AMOUNT))
		toast(player, "Core repaired +" .. REPAIR_AMOUNT)
	end
end)

-- keep every player's shop prices up to date
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			shop:FireClient(
				player, "Costs",
				turretCost(), #turretFolder:GetChildren(), MAX_TURRETS,
				upgradeCost(player), player:GetAttribute("DmgLevel") or 0, MAX_LEVEL,
				REPAIR_COST
			)
		end
	end
end)


------------------------------------------------------------
-- SKIP ITEMS
-- productId = 0 means "not set up yet". Make a Developer Product for each one in
-- Creator Hub, then paste its ID here (and the Robux price in `robux` for display).
-- Until then: free for the game owner (and in Studio) for testing, "Coming soon" for everyone else.
------------------------------------------------------------
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local skipBind = ServerStorage:WaitForChild("SkipRequest")

local SKIP_ITEMS = {
	{ id = "Skip1",   label = "Skip Wave",       desc = "Skip the current wave",             kind = "waves", amount = 1,  productId = 3734006865, robux = 49 },
	{ id = "Skip5",   label = "Skip 5 Waves",    desc = "Jump ahead 5 waves",                kind = "waves", amount = 5,  productId = 3734006903, robux = 49 },
	{ id = "Skip10",  label = "Skip 10 Waves",   desc = "Jump ahead 10 waves",               kind = "waves", amount = 10, productId = 3734006909, robux = 98 },
	{ id = "Skip15",  label = "Skip 15 Waves",   desc = "Jump ahead 15 waves",               kind = "waves", amount = 15, productId = 3734006917, robux = 147 },
	{ id = "SkipAll", label = "Skip Entire Run", desc = "Win this difficulty instantly",    kind = "all",   amount = 0,  productId = 3734006925, robux = 249 },
}

-- While true, the game owner (and Studio) get skips for free instead of paying Robux.
-- Set to false to test the real purchase flow.
local OWNER_TESTS_FREE = true

-- ALL-ACCESS monthly subscription (create it in Creator Hub > Monetization > Subscriptions).
-- Paste its id here; while it is "" the subscription features stay switched off.
local SUBSCRIPTION_ID = "EXP-7148503343955051007"

local function isSubscriber(player)
	if SUBSCRIPTION_ID == "" then return false end
	local ok, status = pcall(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(player, SUBSCRIPTION_ID)
	end)
	return ok and status ~= nil and status.IsSubscribed == true
end

local function isOwner(player)
	return RunService:IsStudio() or player.UserId == game.CreatorId
end

local function priceText(item, player)
	local cost = item.robux and (item.robux .. " Robux") or "Robux"
	if OWNER_TESTS_FREE and isOwner(player) then
		return cost .. " (free for you)"
	end
	if item.productId > 0 then
		return cost
	end
	return cost .. " - coming soon"
end

local function itemList(player)
	local list = {}
	for _, it in ipairs(SKIP_ITEMS) do
		table.insert(list, { id = it.id, label = it.label, desc = it.desc, price = isSubscriber(player) and "Included (All-Access)" or priceText(it, player) })
	end
	if SUBSCRIPTION_ID ~= "" and not isSubscriber(player) then
		table.insert(list, { id = "Subscribe", label = "ALL-ACCESS (monthly)", desc = "Carpet + every skip", price = "300 Robux / month" })
	end
	return list
end

local function grantSkip(player, item)
	skipBind:Fire(item.kind, item.amount)
	toast(player, item.label .. "!")
end

shop.OnServerEvent:Connect(function(player, action, itemId)
	if action == "SkipSync" then
		shop:FireClient(player, "SkipList", itemList(player))
		return
	end
	if action ~= "Skip" then return end
	if (core:GetAttribute("Health") or 0) <= 0 then return end

	if itemId == "Subscribe" then
		if SUBSCRIPTION_ID ~= "" and not isSubscriber(player) then
			MarketplaceService:PromptSubscriptionPurchase(player, SUBSCRIPTION_ID)
		end
		return
	end

	local item
	for _, it in ipairs(SKIP_ITEMS) do
		if it.id == itemId then item = it end
	end
	if not item then return end

	if (OWNER_TESTS_FREE and isOwner(player)) or isSubscriber(player) then
		grantSkip(player, item)
	elseif item.productId > 0 then
		MarketplaceService:PromptProductPurchase(player, item.productId)
	else
		toast(player, "Not for sale yet!")
	end
end)

-- real purchases (only used once productIds are filled in)
local receiptStore
pcall(function() receiptStore = DataStoreService:GetDataStore("SkipReceipts") end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local item
	for _, it in ipairs(SKIP_ITEMS) do
		if it.productId > 0 and it.productId == receiptInfo.ProductId then item = it end
	end
	if not item then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local key = tostring(receiptInfo.PurchaseId)
	local already = false
	if receiptStore then
		local ok, seen = pcall(function() return receiptStore:GetAsync(key) end)
		if ok and seen then already = true end
	end
	if not already then
		grantSkip(player, item)
		if receiptStore then
			pcall(function() receiptStore:SetAsync(key, true) end)
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
