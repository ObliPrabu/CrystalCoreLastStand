-- Practice Arena buttons: a "Practice Arena" button in the corner while the difficulty menu is open, and, once
-- you are inside, a bar to spawn training dummies, clear them or leave.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local event = ReplicatedStorage:WaitForChild("PracticeEvent")
local compact = UserInputService.TouchEnabled

local gui = Instance.new("ScreenGui")
gui.Name = "PracticeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 19 -- under the tutorial / daily popups (20)
gui.Parent = playerGui

local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = obj end

local function button(parent, text, color, w, h)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = compact and 14 or 16
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 8)
	return b
end

-- corner button (shown with the difficulty menu)
local enterBtn = button(gui, "Practice Arena", Color3.fromRGB(40, 140, 140), 150, 38)
enterBtn.AnchorPoint = Vector2.new(0, 1)
enterBtn.Position = UDim2.new(0, 12, 1, -150)
enterBtn.Visible = false
enterBtn.Activated:Connect(function() event:FireServer("Enter") end)

-- the bar shown while practicing
local bar = Instance.new("ScrollingFrame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -96)
bar.Size = UDim2.new(0.92, 0, 0, 52)
bar.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
bar.BackgroundTransparency = 0.15
bar.BorderSizePixel = 0
bar.ScrollBarThickness = 0
bar.ScrollingDirection = Enum.ScrollingDirection.X
bar.CanvasSize = UDim2.fromOffset(0, 0)
bar.AutomaticCanvasSize = Enum.AutomaticSize.X
bar.Visible = false
bar.Parent = gui
corner(bar, 10)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(720, 52)
limit.Parent = bar
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
pad.Parent = bar
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 6)
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar

local order = 0
local function add(text, color, w, fn)
	order += 1
	local b = button(bar, text, color, w, 38)
	b.LayoutOrder = order
	b.Activated:Connect(fn)
end
for _, kind in ipairs({ "Zombie", "Runner", "Tank", "Exploder", "Spitter", "Boss" }) do
	add(kind, Color3.fromRGB(60, 90, 160), 86, function() event:FireServer("Spawn", kind) end)
end
add("Clear", Color3.fromRGB(110, 90, 40), 70, function() event:FireServer("Clear") end)
add("EXIT", Color3.fromRGB(180, 60, 60), 70, function() event:FireServer("Exit") end)

------------------------------------------------------------
-- keep the difficulty menu out of the way while practicing
------------------------------------------------------------
local function inRound()
	return (Workspace:GetAttribute("TimeLeft") or -1) >= 0
end

local function refresh()
	local practicing = player:GetAttribute("InPractice") == true
	bar.Visible = practicing
	local menu = playerGui:FindFirstChild("DifficultyMenu")
	if practicing then
		enterBtn.Visible = false
		if menu then menu.Enabled = false end
	elseif menu then
		enterBtn.Visible = menu.Enabled
		-- back from practice with no round running: show the menu again
		if not inRound() and not menu.Enabled and player:GetAttribute("WasPracticing") then
			menu.Enabled = true
		end
		player:SetAttribute("WasPracticing", nil)
	end
end

player:GetAttributeChangedSignal("InPractice"):Connect(function()
	if player:GetAttribute("InPractice") then player:SetAttribute("WasPracticing", true) end
	refresh()
end)

task.spawn(function()
	local menu = playerGui:WaitForChild("DifficultyMenu")
	menu:GetPropertyChangedSignal("Enabled"):Connect(function()
		if player:GetAttribute("InPractice") and menu.Enabled then
			menu.Enabled = false -- a round ended while you practice: do not cover the screen
		else
			enterBtn.Visible = menu.Enabled
		end
	end)
	refresh()
end)
