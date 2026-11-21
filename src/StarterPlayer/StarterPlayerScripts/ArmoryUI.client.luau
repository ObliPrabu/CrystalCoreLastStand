local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local event = ReplicatedStorage:WaitForChild("WeaponEvent")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local camera = Workspace.CurrentCamera
local compact = UserInputService.TouchEnabled or (camera and camera.ViewportSize.X < 1000)

local old = playerGui:FindFirstChild("ArmoryUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "ArmoryUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 7
gui.Parent = playerGui

local toggle = Instance.new("TextButton")
toggle.Position = UDim2.new(0, 12, 0, compact and 168 or 518)
toggle.Size = UDim2.fromOffset(120, 36)
toggle.BackgroundColor3 = Color3.fromRGB(200, 120, 30)
toggle.BorderSizePixel = 0
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 16
toggle.Text = "ARMORY"
toggle.Parent = gui
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(compact and 360 or 440, compact and 310 or 470)
panel.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 10
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(12, 6)
title.Size = UDim2.new(1, -150, 0, 32)
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "ARMORY"
title.ZIndex = 11
title.Parent = panel

local coinLabel = Instance.new("TextLabel")
coinLabel.AnchorPoint = Vector2.new(1, 0)
coinLabel.Position = UDim2.new(1, -50, 0, 6)
coinLabel.Size = UDim2.fromOffset(110, 32)
coinLabel.BackgroundTransparency = 1
coinLabel.TextXAlignment = Enum.TextXAlignment.Right
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 18
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
coinLabel.Text = "Coins: 0"
coinLabel.ZIndex = 11
coinLabel.Visible = false
coinLabel.Parent = panel

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0)
close.Position = UDim2.new(1, -10, 0, 8)
close.Size = UDim2.fromOffset(30, 30)
close.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
close.BorderSizePixel = 0
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.Text = "X"
close.ZIndex = 11
close.Parent = panel
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(10, 46)
scroll.Size = UDim2.new(1, -20, 1, -56)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ZIndex = 11
scroll.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local lastRows = {}
local rowButtons = {} -- [id] = { button = , cost = }

local function coins()
	local ls = player:FindFirstChild("PlayerData")
	local c = ls and ls:FindFirstChild("Coins")
	return c and c.Value or 0
end

local function recolor()
	coinLabel.Text = "Coins: " .. coins()
	for _, info in pairs(rowButtons) do
		if info.cost then
			info.button.BackgroundColor3 = coins() >= info.cost and info.color or Color3.fromRGB(70, 70, 85)
		end
	end
end

local function render(rows)
	lastRows = rows
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	rowButtons = {}

	local order = 0
	local lastKind
	for _, r in ipairs(rows) do
		if r.kind ~= lastKind then
			lastKind = r.kind
			order += 1
			local h = Instance.new("TextLabel")
			h.LayoutOrder = order
			h.Size = UDim2.new(1, -8, 0, 22)
			h.BackgroundTransparency = 1
			h.TextXAlignment = Enum.TextXAlignment.Left
			h.Font = Enum.Font.GothamBold
			h.TextSize = 13
			h.TextColor3 = Color3.fromRGB(150, 150, 170)
			h.Text = r.kind == "melee" and "MELEE WEAPONS" or "GUNS"
			h.ZIndex = 12
			h.Parent = scroll
		end

		order += 1
		local row = Instance.new("Frame")
		row.LayoutOrder = order
		row.Size = UDim2.new(1, -8, 0, r.kind == "gun" and 112 or 84)
		row.BackgroundColor3 = r.owned and Color3.fromRGB(38, 52, 44) or Color3.fromRGB(40, 40, 56)
		row.BorderSizePixel = 0
		row.ZIndex = 12
		row.Parent = scroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromOffset(8, 4)
		name.Size = UDim2.new(1, -130, 0, 22)
		name.BackgroundTransparency = 1
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Font = Enum.Font.GothamBold
		name.TextSize = 16
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = r.name .. (r.owned and ("   Lv " .. r.level .. "/" .. r.maxLevel) or "")
		name.ZIndex = 13
		name.Parent = row

		local dmgText = r.pellets and r.pellets > 1 and (r.damage .. " x" .. r.pellets) or tostring(r.damage)
		local stats = Instance.new("TextLabel")
		stats.Position = UDim2.fromOffset(8, 28)
		stats.Size = UDim2.new(1, -130, 0, 18)
		stats.BackgroundTransparency = 1
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.Font = Enum.Font.Gotham
		stats.TextSize = 13
		stats.TextColor3 = Color3.fromRGB(255, 215, 130)
		stats.Text = "Damage " .. dmgText .. (r.nextDamage and r.owned and ("  ->  " .. r.nextDamage) or "")
		stats.ZIndex = 13
		stats.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.fromOffset(8, 48)
		desc.Size = UDim2.new(1, -130, 0, r.kind == "gun" and 56 or 30)
		desc.BackgroundTransparency = 1
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextWrapped = true
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 12
		desc.TextColor3 = Color3.fromRGB(170, 170, 190)
		desc.Text = r.desc
		if r.kind == "gun" and r.owned and r.magSize then
			desc.Text = r.desc .. "\nMagazine: " .. r.magSize .. (r.nextMagSize and (" -> " .. r.nextMagSize) or " (max)")
		end
		desc.ZIndex = 13
		desc.Parent = row

		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, -8, 0.5, 0)
		b.Size = UDim2.fromOffset(110, 56)
		b.BorderSizePixel = 0
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.TextWrapped = true
		b.ZIndex = 13
		b.Parent = row
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		local lim = Instance.new("UITextSizeConstraint")
		lim.MaxTextSize = 15
		lim.MinTextSize = 8
		lim.Parent = b

		local color, cost
		if not r.owned then
			color = Color3.fromRGB(60, 140, 210)
			cost = r.price
			b.Text = "BUY\n" .. r.price .. " coins"
			b.Activated:Connect(function() event:FireServer("Buy", r.id) end)
		elseif r.level < r.maxLevel then
			color = Color3.fromRGB(190, 120, 30)
			cost = r.upgradeCost
			b.Text = "UPGRADE\n" .. r.upgradeCost .. " coins"
			b.Activated:Connect(function() event:FireServer("Upgrade", r.id) end)
		else
			color = Color3.fromRGB(60, 120, 70)
			b.Text = "MAX LEVEL"
		end
		b.BackgroundColor3 = color
		rowButtons[r.id] = { button = b, cost = cost, color = color }

		if r.kind == "gun" then
			-- two buttons for guns: damage upgrade on top, bigger magazine below
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -8, 0, 8)
			b.Size = UDim2.fromOffset(110, 44)

			local m = Instance.new("TextButton")
			m.AnchorPoint = Vector2.new(1, 0)
			m.Position = UDim2.new(1, -8, 0, 60)
			m.Size = UDim2.fromOffset(110, 44)
			m.BorderSizePixel = 0
			m.TextColor3 = Color3.new(1, 1, 1)
			m.Font = Enum.Font.GothamBold
			m.TextScaled = true
			m.TextWrapped = true
			m.ZIndex = 13
			m.Parent = row
			Instance.new("UICorner", m).CornerRadius = UDim.new(0, 8)
			local mlim = Instance.new("UITextSizeConstraint")
			mlim.MaxTextSize = 15
			mlim.MinTextSize = 8
			mlim.Parent = m

			local mcolor, mcost = Color3.fromRGB(110, 70, 190), nil
			if not r.owned then
				m.Text = "BIGGER MAG\nbuy gun first"
				m.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
			elseif r.magLevel < r.maxMagLevel then
				mcost = r.magCost
				m.Text = "BIGGER MAG\n" .. r.magCost .. " coins"
				m.BackgroundColor3 = mcolor
				m.Activated:Connect(function() event:FireServer("UpgradeMag", r.id) end)
			else
				m.Text = "MAG MAXED"
				m.BackgroundColor3 = Color3.fromRGB(60, 120, 70)
			end
			rowButtons[r.id .. "_mag"] = { button = m, cost = mcost, color = mcolor }
		end
	end
	recolor()
end

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		event:FireServer("Sync")
		recolor()
	end
end)
close.Activated:Connect(function()
	panel.Visible = false
end)

event.OnClientEvent:Connect(function(kind, rows)
	if kind == "List" then
		render(rows)
	end
end)

task.spawn(function()
	local ls = player:WaitForChild("PlayerData")
	local c = ls:WaitForChild("Coins")
	c.Changed:Connect(recolor)
	recolor()
end)
