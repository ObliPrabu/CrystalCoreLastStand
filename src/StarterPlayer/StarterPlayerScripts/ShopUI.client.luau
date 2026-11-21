local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("ShopUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ShopUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
local compact = UserInputService.TouchEnabled or viewport.X < 1000

------------------------------------------------------------
-- Stats panel: health + coins (top-left)
------------------------------------------------------------
local stats = Instance.new("Frame")
stats.Name = "Stats"
stats.AnchorPoint = Vector2.new(0, 0)
stats.Position = UDim2.new(0, 12, 0, compact and 54 or 12)
stats.Size = UDim2.fromOffset(200, 64)
stats.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
stats.BackgroundTransparency = 0.2
stats.BorderSizePixel = 0
stats.Parent = gui
Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 10)

local coinLabel = Instance.new("TextLabel")
coinLabel.Position = UDim2.fromOffset(44, 4)
coinLabel.Size = UDim2.new(1, -54, 0, 26)
coinLabel.BackgroundTransparency = 1
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 22
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
coinLabel.Text = "0"
coinLabel.Parent = stats

-- the coin symbol
local coinIcon = Instance.new("Frame")
coinIcon.Position = UDim2.fromOffset(10, 4)
coinIcon.Size = UDim2.fromOffset(26, 26)
coinIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
coinIcon.BorderSizePixel = 0
coinIcon.Parent = stats
Instance.new("UICorner", coinIcon).CornerRadius = UDim.new(1, 0)
local coinRing = Instance.new("UIStroke")
coinRing.Color = Color3.fromRGB(190, 130, 20)
coinRing.Thickness = 2.5
coinRing.Parent = coinIcon
local coinMark = Instance.new("TextLabel")
coinMark.Size = UDim2.fromScale(1, 1)
coinMark.BackgroundTransparency = 1
coinMark.Font = Enum.Font.GothamBold
coinMark.TextSize = 16
coinMark.TextColor3 = Color3.fromRGB(150, 95, 10)
coinMark.Text = "$"
coinMark.Parent = coinIcon

local barBack = Instance.new("Frame")
barBack.Position = UDim2.fromOffset(10, 34)
barBack.Size = UDim2.new(1, -20, 0, 22)
barBack.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
barBack.BorderSizePixel = 0
barBack.Parent = stats
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 6)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(1, 1)
barFill.BackgroundColor3 = Color3.fromRGB(70, 200, 90)
barFill.BorderSizePixel = 0
barFill.Parent = barBack
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.fromScale(1, 1)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 14
hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.TextStrokeTransparency = 0.5
hpText.Text = "100 / 100"
hpText.ZIndex = 3
hpText.Parent = barBack

local function setHealth(h, maxH)
	maxH = math.max(maxH, 1)
	local frac = math.clamp(h / maxH, 0, 1)
	barFill.Size = UDim2.fromScale(frac, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(220 * (1 - frac) + 60, 200 * frac + 30, 60)
	hpText.Text = ("%d / %d"):format(math.ceil(h), math.ceil(maxH))
end

local healthConn
local function watchCharacter(char)
	if healthConn then healthConn:Disconnect() end
	local hum = char:WaitForChild("Humanoid")
	setHealth(hum.Health, hum.MaxHealth)
	healthConn = hum.HealthChanged:Connect(function(h)
		setHealth(h, hum.MaxHealth)
	end)
end
if player.Character then task.spawn(watchCharacter, player.Character) end
player.CharacterAdded:Connect(watchCharacter)

task.spawn(function()
	local leaderstats = player:WaitForChild("PlayerData")
	local coins = leaderstats:WaitForChild("Coins")
	coinLabel.Text = tostring(coins.Value)
	coins.Changed:Connect(function(v)
		coinLabel.Text = tostring(v)
	end)
end)

------------------------------------------------------------
-- Survival timer (top-center)
------------------------------------------------------------
local timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.Position = UDim2.new(0.5, 0, 0, 8)
timerLabel.Size = UDim2.fromOffset(210, 36)
timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
timerLabel.BackgroundTransparency = 0.2
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 22
timerLabel.Visible = false
timerLabel.Parent = gui
Instance.new("UICorner", timerLabel).CornerRadius = UDim.new(0, 8)

local function updateTimer()
	local t = Workspace:GetAttribute("TimeLeft")
	if t and t >= 0 then
		timerLabel.Visible = true
		timerLabel.Text = ("Survive  %d:%02d"):format(math.floor(t / 60), t % 60)
		timerLabel.TextColor3 = t <= 30 and Color3.fromRGB(255, 120, 100) or Color3.new(1, 1, 1)
	else
		timerLabel.Visible = false
	end
end
Workspace:GetAttributeChangedSignal("TimeLeft"):Connect(updateTimer)
updateTimer()

------------------------------------------------------------
-- Shop panel
------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.fromOffset(230, 292)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Center
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = panel

local title = Instance.new("TextLabel")
title.LayoutOrder = 0
title.Size = UDim2.fromOffset(210, 28)
title.BackgroundTransparency = 1
title.Text = "SHOP"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = panel

local function makeButton(order, color, action, firstText)
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(210, 50)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.TextWrapped = true
	b.TextScaled = true
	b.Text = firstText
	b.Parent = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 15
	limit.MinTextSize = 8
	limit.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = b
	b.Activated:Connect(function()
		shop:FireServer(action)
	end)
	return b
end

local turretBtn = makeButton(1, Color3.fromRGB(40, 130, 200), "Turret", "Turret")
local upgradeBtn = makeButton(2, Color3.fromRGB(190, 120, 30), "Upgrade", "Upgrade")
local repairBtn = makeButton(3, Color3.fromRGB(50, 160, 90), "Repair", "Repair")
local skipBtn = makeButton(4, Color3.fromRGB(150, 70, 190), "SkipMenu", "Skip Waves")

-- Skip menu (opens in the middle of the screen)
local skipFrame = Instance.new("Frame")
skipFrame.Name = "SkipMenu"
skipFrame.AnchorPoint = Vector2.new(0.5, 0.5)
skipFrame.Position = UDim2.fromScale(0.5, 0.5)
skipFrame.Size = UDim2.fromOffset(compact and 290 or 330, 330)
skipFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
skipFrame.BorderSizePixel = 0
skipFrame.Visible = false
skipFrame.ZIndex = 20
skipFrame.Parent = gui
Instance.new("UICorner", skipFrame).CornerRadius = UDim.new(0, 12)

local skipLayout = Instance.new("UIListLayout")
skipLayout.Padding = UDim.new(0, 6)
skipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
skipLayout.VerticalAlignment = Enum.VerticalAlignment.Center
skipLayout.SortOrder = Enum.SortOrder.LayoutOrder
skipLayout.Parent = skipFrame

local skipTitle = Instance.new("TextLabel")
skipTitle.LayoutOrder = 0
skipTitle.Size = UDim2.new(1, -20, 0, 28)
skipTitle.BackgroundTransparency = 1
skipTitle.Text = "SKIP AHEAD"
skipTitle.TextColor3 = Color3.new(1, 1, 1)
skipTitle.Font = Enum.Font.GothamBold
skipTitle.TextSize = 22
skipTitle.ZIndex = 21
skipTitle.Parent = skipFrame

local skipButtons = {}
local function rebuildSkip(list)
	for _, b in ipairs(skipButtons) do b:Destroy() end
	skipButtons = {}
	for i, item in ipairs(list) do
		local b = Instance.new("TextButton")
		b.LayoutOrder = i
		b.Size = UDim2.new(1, -24, 0, 40)
		b.BackgroundColor3 = item.id == "SkipAll" and Color3.fromRGB(190, 60, 60) or Color3.fromRGB(150, 70, 190)
		b.BorderSizePixel = 0
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.GothamBold
		b.TextWrapped = true
		b.TextScaled = true
		b.Text = item.label .. "\n" .. item.price
		b.ZIndex = 21
		b.Parent = skipFrame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		local lim = Instance.new("UITextSizeConstraint")
		lim.MaxTextSize = 16
		lim.MinTextSize = 8
		lim.Parent = b
		b.Activated:Connect(function()
			shop:FireServer("Skip", item.id)
			skipFrame.Visible = false
		end)
		table.insert(skipButtons, b)
	end
end

local skipClose = Instance.new("TextButton")
skipClose.LayoutOrder = 99
skipClose.Size = UDim2.new(1, -24, 0, 34)
skipClose.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
skipClose.BorderSizePixel = 0
skipClose.TextColor3 = Color3.new(1, 1, 1)
skipClose.Font = Enum.Font.GothamBold
skipClose.TextSize = 16
skipClose.Text = "Close"
skipClose.ZIndex = 21
skipClose.Parent = skipFrame
Instance.new("UICorner", skipClose).CornerRadius = UDim.new(0, 8)
skipClose.Activated:Connect(function()
	skipFrame.Visible = false
end)

skipBtn.Activated:Connect(function()
	skipFrame.Visible = not skipFrame.Visible
	if skipFrame.Visible then
		shop:FireServer("SkipSync")
	end
end)

-- Toggle button + layout (phones: top-right, small, closed by default)
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(110, 36)
toggle.BackgroundColor3 = Color3.fromRGB(40, 130, 200)
toggle.BorderSizePixel = 0
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 18
toggle.Parent = gui
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

if compact then
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 86)
	panel.Visible = false
	local scale = Instance.new("UIScale")
	scale.Scale = 0.65
	scale.Parent = panel
	toggle.AnchorPoint = Vector2.new(1, 0)
	toggle.Position = UDim2.new(1, -12, 0, 44)
else
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.new(0, 12, 0, 100)
	panel.Visible = true
	-- on a computer the shop is always open, so no toggle button is needed
	toggle.Visible = false
end
toggle.Text = panel.Visible and "CLOSE" or "SHOP"
toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	toggle.Text = panel.Visible and "CLOSE" or "SHOP"
end)

------------------------------------------------------------
-- Toast message (top of screen)
------------------------------------------------------------
local toastLabel = Instance.new("TextLabel")
toastLabel.AnchorPoint = Vector2.new(0.5, 0)
toastLabel.Position = UDim2.new(0.5, 0, 0, 52)
toastLabel.Size = UDim2.fromOffset(520, 44)
toastLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
toastLabel.BackgroundTransparency = 0.2
toastLabel.TextColor3 = Color3.new(1, 1, 1)
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 20
toastLabel.TextWrapped = true
toastLabel.Text = ""
toastLabel.Visible = false
toastLabel.Parent = gui
Instance.new("UICorner", toastLabel).CornerRadius = UDim.new(0, 10)
if compact then
	toastLabel.Size = UDim2.fromOffset(340, 40)
	toastLabel.TextSize = 16
end

local toastId = 0
local function showToast(text)
	toastId += 1
	local id = toastId
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(2.6, function()
		if toastId == id then
			toastLabel.Visible = false
		end
	end)
end

shop.OnClientEvent:Connect(function(kind, ...)
	if kind == "SkipList" then
		rebuildSkip((...))
	elseif kind == "Toast" then
		showToast((...))
	elseif kind == "Costs" then
		local tCost, tCount, tMax, uCost, uLevel, uMax, rCost = ...
		turretBtn.Text = ("Turret\n%d coins  [%d/%d]"):format(tCost, tCount, tMax)
		if uLevel >= uMax then
			upgradeBtn.Text = ("Upgrade MAXED\nLevel %d"):format(uLevel)
		else
			upgradeBtn.Text = ("Upgrade\n%d coins  Lv %d/%d"):format(uCost, uLevel, uMax)
		end
		repairBtn.Text = ("Repair Core\n%d coins"):format(rCost)
	end
end)
