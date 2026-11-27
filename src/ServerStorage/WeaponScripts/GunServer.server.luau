local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local barrel = tool:WaitForChild("BarrelGlow")
local fire = tool:WaitForChild("Fire")
local reload = tool:WaitForChild("Reload")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local function attr(name, default)
	local v = tool:GetAttribute(name)
	if v == nil then return default end
	return v
end

local function magSize()
	return attr("MagSize", 12)
end
local lastShot = {}

tool:SetAttribute("Ammo", magSize())
tool:SetAttribute("Reserve", attr("StartReserve", 36))
tool:SetAttribute("Reloading", false)

local reloadToken = 0
local function startReload()
	if tool:GetAttribute("Reloading") then return end
	if (tool:GetAttribute("Ammo") or 0) >= magSize() then return end
	if (tool:GetAttribute("Reserve") or 0) <= 0 then return end

	tool:SetAttribute("Reloading", true)
	reloadToken += 1
	local token = reloadToken
	task.delay(attr("ReloadTime", 1.4), function()
		if token ~= reloadToken then return end -- cancelled (put the gun away)
		local ammo = tool:GetAttribute("Ammo") or 0
		local reserve = tool:GetAttribute("Reserve") or 0
		local take = math.min(magSize() - ammo, reserve)
		tool:SetAttribute("Ammo", ammo + take)
		tool:SetAttribute("Reserve", reserve - take)
		tool:SetAttribute("Reloading", false)
	end)
end

tool.Unequipped:Connect(function()
	reloadToken += 1
	tool:SetAttribute("Reloading", false)
end)

reload.OnServerEvent:Connect(function(player)
	if tool.Parent == player.Character then
		startReload()
	end
end)

fire.OnServerEvent:Connect(function(player, targetPos)
	if typeof(targetPos) ~= "Vector3" then return end
	local char = player.Character
	if not char or tool.Parent ~= char then return end

	local now = os.clock()
	if lastShot[player] and now - lastShot[player] < attr("FireRate", 0.25) * 0.9 then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	if tool:GetAttribute("Reloading") then return end
	local ammo = tool:GetAttribute("Ammo") or 0
	if ammo <= 0 then
		startReload()
		return
	end
	local origin = barrel.Position
	if (targetPos - origin).Magnitude < 0.1 then return end -- nothing to shoot at: do not spend a bullet

	lastShot[player] = now
	tool:SetAttribute("Ammo", ammo - 1)
	if ammo - 1 <= 0 then
		startReload() -- auto-reload when the magazine runs dry
	end

	local ignore = { char }
	for _, name in ipairs({ "Core", "AmmoCrates", "Turrets", "Decor" }) do
		local o = workspace:FindFirstChild(name)
		if o then table.insert(ignore, o) end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore

	-- damage: this weapon's upgrade level x the global shop upgrade
	local dmg = attr("Damage", 20)
		* (1 + 0.2 * attr("Level", 0))
		* (1 + 0.25 * (player:GetAttribute("DmgLevel") or 0))
		* (player:GetAttribute("DamageBoost") or 1) -- red power-up
	local pellets = attr("Pellets", 1)
	local spread = math.rad(attr("Spread", 0))
	local range = attr("Range", 250)
	local aim = CFrame.lookAt(origin, targetPos)

	for _ = 1, pellets do
		local dirCF = aim
		if spread > 0 then
			dirCF = aim * CFrame.Angles((math.random() - 0.5) * 2 * spread, (math.random() - 0.5) * 2 * spread, 0)
		end
		local dir = dirCF.LookVector * range
		local result = workspace:Raycast(origin, dir, params)
		local endPos = result and result.Position or (origin + dir)

		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			local targetHum = model and model:FindFirstChildOfClass("Humanoid")
			-- players can only be hit in Versus, or admin on admin (never yourself); hitting a player never counts as a kill
			local victim = model and Players:GetPlayerFromCharacter(model)
			if targetHum and targetHum.Health > 0 and (not victim or (victim ~= player and (workspace:GetAttribute("Mode") == "Versus" or (player:GetAttribute("IsAdmin") and victim:GetAttribute("IsAdmin"))))) then
				if not victim then targetHum:SetAttribute("LastAttacker", player.UserId) end
				targetHum:TakeDamage(dmg)
			end
		end

		-- bullet tracer
		local dist = (endPos - origin).Magnitude
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CanTouch = false
		beam.Material = Enum.Material.Neon
		beam.Color = barrel.Color
		beam.Size = Vector3.new(0.12, 0.12, dist)
		beam.CFrame = CFrame.lookAt(origin, endPos) * CFrame.new(0, 0, -dist / 2)
		beam.Parent = workspace
		Debris:AddItem(beam, 0.07)
	end

	-- muzzle flash
	local flash = barrel:FindFirstChild("MuzzleFlash")
	if flash then
		flash.Enabled = true
		task.delay(0.05, function() flash.Enabled = false end)
	end
end)
