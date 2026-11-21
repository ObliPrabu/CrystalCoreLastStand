local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local event = ReplicatedStorage:WaitForChild("CarpetEvent")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")

-- The "Magic Carpet" game pass (300 Robux), created in Creator Hub / Open Cloud.
local GAME_PASS_ID = 2093111016

-- While true, the game owner (and Studio) can ride for free instead of paying Robux.
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

-- The client steers the carpet at 60 studs/second. A cheater can ask for any speed, so the server
-- also measures it and removes the carpet if it is clearly too fast.
local MAX_CARPET_SPEED = 110

local carpets = {}   -- [player] = the carpet seat they are using
local ownsCache = {} -- [player] = true once we know they own the pass

local function isOwner(player)
	return RunService:IsStudio() or player.UserId == game.CreatorId
end

local function toast(player, text)
	shop:FireClient(player, "Toast", text)
end

local function ownsCarpet(player)
	if OWNER_TESTS_FREE and isOwner(player) then return true end
	if ownsCache[player] then return true end
	if isSubscriber(player) then return true end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
	end)
	if ok and owns then
		ownsCache[player] = true
		return true
	end
	return false
end

local function removeCarpet(player)
	local carpet = carpets[player]
	carpets[player] = nil
	if carpet then
		carpet:Destroy()
	end
end

local function addTrim(seat, size, offset, color)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Metal
	p.CanCollide = false
	p.Massless = true
	p.CFrame = seat.CFrame * CFrame.new(offset)
	p.Parent = seat
	local w = Instance.new("WeldConstraint")
	w.Part0 = seat
	w.Part1 = p
	w.Parent = p
end

local function summon(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root then return end

	local seat = Instance.new("Seat")
	seat.Name = "MagicCarpet"
	seat.Size = Vector3.new(7, 0.6, 9)
	seat.Color = Color3.fromRGB(150, 40, 160)
	seat.Material = Enum.Material.Fabric
	seat.CFrame = CFrame.new(root.Position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(root.Orientation.Y), 0)

	local gold = Color3.fromRGB(240, 190, 60)
	addTrim(seat, Vector3.new(7.2, 0.7, 0.5), Vector3.new(0, 0, -4.5), gold)
	addTrim(seat, Vector3.new(7.2, 0.7, 0.5), Vector3.new(0, 0, 4.5), gold)
	addTrim(seat, Vector3.new(0.5, 0.7, 9), Vector3.new(-3.5, 0, 0), gold)
	addTrim(seat, Vector3.new(0.5, 0.7, 9), Vector3.new(3.5, 0, 0), gold)

	-- the client drives these two to steer
	local att = Instance.new("Attachment")
	att.Name = "CarpetAttachment"
	att.Parent = seat

	local lv = Instance.new("LinearVelocity")
	lv.Name = "CarpetVelocity"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = 1e7
	lv.VectorVelocity = Vector3.zero
	lv.Parent = seat

	local ao = Instance.new("AlignOrientation")
	ao.Name = "CarpetOrientation"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = false
	ao.Responsiveness = 25
	ao.MaxTorque = 1e7
	ao.CFrame = seat.CFrame
	ao.Parent = seat

	seat.Parent = Workspace
	pcall(function() seat:SetNetworkOwner(player) end)
	carpets[player] = seat

	-- server-side speed check
	task.spawn(function()
		local lastPos, lastTime = seat.Position, os.clock()
		while carpets[player] == seat and seat.Parent do
			task.wait(0.25)
			local now, pos = os.clock(), seat.Position
			local speed = (pos - lastPos).Magnitude / math.max(now - lastTime, 0.01)
			lastPos, lastTime = pos, now
			if speed > MAX_CARPET_SPEED then
				removeCarpet(player)
				toast(player, "Carpet removed - too fast")
				break
			end
		end
	end)

	-- clean up when you hop off, die, or the seat never got used
	local wasSeated = false
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant then
			wasSeated = true
		elseif wasSeated then
			task.delay(0.4, function()
				if carpets[player] == seat then removeCarpet(player) end
			end)
		end
	end)
	seat:Sit(hum)
	wasSeated = wasSeated or seat.Occupant ~= nil

	hum.Died:Connect(function()
		if carpets[player] == seat then removeCarpet(player) end
	end)
	task.delay(4, function()
		if carpets[player] == seat and not wasSeated and seat.Occupant == nil then removeCarpet(player) end
	end)
end

event.OnServerEvent:Connect(function(player, action)
	if action ~= "Toggle" then return end
	if carpets[player] then
		removeCarpet(player)
		return
	end
	if ownsCarpet(player) then
		summon(player)
		toast(player, "Magic Carpet! Jump to hop off.")
	else
		MarketplaceService:PromptGamePassPurchase(player, GAME_PASS_ID)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if passId == GAME_PASS_ID and wasPurchased then
		ownsCache[player] = true
		toast(player, "Magic Carpet unlocked! Press C or tap CARPET.")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeCarpet(player)
	ownsCache[player] = nil
end)
