local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local function attr(name, default)
	local v = tool:GetAttribute(name)
	if v == nil then return default end
	return v
end

local baseGrip = tool.Grip
local lastHit = {}
local swinging = false

-- Blade pose measured from the normal hold:
--   z sweeps it left (-) / right (+), x tips it back (-) / forward and down (+)
local function pose(zDeg, xDeg)
	return baseGrip * CFrame.Angles(math.rad(xDeg), 0, math.rad(zDeg))
end

local function tweenGrip(target, duration, style, direction)
	local t = TweenService:Create(tool, TweenInfo.new(duration, style, direction), { Grip = target })
	t:Play()
	return t
end

local function hitCheck(char, duration)
	local owner = Players:GetPlayerFromCharacter(char)
	local dmg = attr("Damage", 25)
		* (1 + 0.2 * attr("Level", 0))
		* (1 + 0.25 * (owner and owner:GetAttribute("DmgLevel") or 0))
		* (owner and owner:GetAttribute("DamageBoost") or 1) -- red power-up
	local box = Vector3.new(attr("HitX", 5), attr("HitY", 5), attr("HitZ", 7))

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}

	local t0 = os.clock()
	while os.clock() - t0 < duration do
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then break end
		local center = root.CFrame * CFrame.new(0, 0, -(box.Z / 2) - 0.5)
		local parts = workspace:GetPartBoundsInBox(center, box, params)
		for _, p in ipairs(parts) do
			local model = p:FindFirstAncestorOfClass("Model")
			local hum = model and model:FindFirstChildOfClass("Humanoid")
			-- players can only be hit in Versus, or admin on admin (never yourself); hitting a player never counts as a kill
			local victim = model and Players:GetPlayerFromCharacter(model)
			if hum and hum.Health > 0 and not lastHit[model] and (not victim or (victim ~= owner and (workspace:GetAttribute("Mode") == "Versus" or (owner and owner:GetAttribute("IsAdmin") and victim:GetAttribute("IsAdmin"))))) then
				lastHit[model] = true
				if not victim then hum:SetAttribute("LastAttacker", owner and owner.UserId or 0) end
				hum:TakeDamage(dmg)
			end
		end
		task.wait()
	end
end

tool.Activated:Connect(function()
	if swinging then return end
	local char = tool.Parent
	if not char or not char:FindFirstChildOfClass("Humanoid") then return end

	local windup = attr("Windup", 0.16)
	local slash = attr("Slash", 0.18)
	local recover = attr("Recover", 0.22)

	swinging = true
	table.clear(lastHit)

	task.spawn(function()
		-- 1) wind-up
		tweenGrip(pose(attr("StartZ", -55), attr("StartX", -35)), windup, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Wait()

		-- 2) the cut: the hit box is live while the weapon moves
		task.spawn(hitCheck, char, slash + 0.12)
		tweenGrip(pose(attr("EndZ", 85), attr("EndX", 60)), slash, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Wait()

		-- 3) recover
		tweenGrip(baseGrip, recover, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Wait()
		tool.Grip = baseGrip

		task.wait(math.max(0, attr("Cooldown", 0.65) - (windup + slash + recover)))
		swinging = false
	end)
end)

-- never leave the weapon twisted if it is put away mid-swing
tool.Unequipped:Connect(function()
	tool.Grip = baseGrip
end)
