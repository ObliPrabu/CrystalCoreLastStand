local tool = script.Parent
local fire = tool:WaitForChild("Fire")
local reloadRemote = tool:WaitForChild("Reload")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local baseGrip = tool.Grip
local holding = false
local firing = false

local function attr(name, default)
	local v = tool:GetAttribute(name)
	if v == nil then return default end
	return v
end

-- Ammo HUD (tap it on a phone, or press R, to reload)
local hudName = "AmmoHUD_" .. tool.Name
local oldHud = playerGui:FindFirstChild(hudName)
if oldHud then oldHud:Destroy() end
local hud = Instance.new("ScreenGui")
hud.Name = hudName
hud.ResetOnSpawn = false
hud.Enabled = false
hud.DisplayOrder = 6
hud.Parent = playerGui

local ammoBtn = Instance.new("TextButton")
ammoBtn.AnchorPoint = Vector2.new(0.5, 1)
ammoBtn.Position = UDim2.new(0.5, 0, 1, -100)
ammoBtn.Size = UDim2.fromOffset(260, 42)
ammoBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ammoBtn.BackgroundTransparency = 0.15
ammoBtn.BorderSizePixel = 0
ammoBtn.TextColor3 = Color3.new(1, 1, 1)
ammoBtn.Font = Enum.Font.GothamBold
ammoBtn.TextSize = 17
ammoBtn.Parent = hud
Instance.new("UICorner", ammoBtn).CornerRadius = UDim.new(0, 8)

local function ammo() return tool:GetAttribute("Ammo") or 0 end
local function reserve() return tool:GetAttribute("Reserve") or 0 end

local function refresh()
	if tool:GetAttribute("Reloading") then
		ammoBtn.Text = tool.Name .. ": RELOADING..."
		ammoBtn.TextColor3 = Color3.fromRGB(255, 210, 90)
	elseif ammo() <= 0 and reserve() <= 0 then
		ammoBtn.Text = "NO AMMO - find a crate!"
		ammoBtn.TextColor3 = Color3.fromRGB(255, 110, 100)
	else
		local hint = UserInputService.TouchEnabled and "tap to reload" or "R to reload"
		ammoBtn.Text = ("%s  %d / %d  (%s)"):format(tool.Name, ammo(), reserve(), hint)
		ammoBtn.TextColor3 = ammo() <= math.max(1, math.floor(attr("MagSize", 12) * 0.25)) and Color3.fromRGB(255, 160, 100) or Color3.new(1, 1, 1)
	end
end

ammoBtn.Activated:Connect(function()
	reloadRemote:FireServer()
end)

-- recoil animation: the gun kicks back and tilts up, then settles
local function recoil()
	local kick = baseGrip * CFrame.new(0, 0, 0.45) * CFrame.Angles(math.rad(attr("Recoil", 14)), 0, 0)
	local out = TweenService:Create(tool, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = kick })
	local back = TweenService:Create(tool, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = baseGrip })
	out:Play()
	out.Completed:Once(function()
		back:Play()
	end)
end

-- reload animation: the gun dips down and tilts while reloading
tool:GetAttributeChangedSignal("Reloading"):Connect(function()
	refresh()
	if tool:GetAttribute("Reloading") then
		local down = baseGrip * CFrame.new(0, 0.6, 0.3) * CFrame.Angles(math.rad(-55), 0, math.rad(25))
		TweenService:Create(tool, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = down }):Play()
	else
		TweenService:Create(tool, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Grip = baseGrip }):Play()
	end
end)
tool:GetAttributeChangedSignal("Ammo"):Connect(refresh)
tool:GetAttributeChangedSignal("Reserve"):Connect(refresh)

tool.Equipped:Connect(function()
	hud.Enabled = true
	refresh()
end)

tool.Activated:Connect(function()
	holding = true
	if firing then return end
	firing = true
	while holding and tool.Parent == player.Character do
		if tool:GetAttribute("Reloading") then
			-- wait for the reload to finish
		elseif ammo() > 0 then
			fire:FireServer(mouse.Hit.Position)
			recoil()
		else
			reloadRemote:FireServer()
		end
		task.wait(attr("FireRate", 0.25))
	end
	firing = false
end)

tool.Deactivated:Connect(function()
	holding = false
end)

tool.Unequipped:Connect(function()
	holding = false
	hud.Enabled = false
	tool.Grip = baseGrip
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.R and tool.Parent == player.Character then
		reloadRemote:FireServer()
	end
end)
