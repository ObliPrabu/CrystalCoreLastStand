-- Daily challenges: a button (top right, only while the difficulty menu is open) that opens today's 3 goals
-- with progress bars. The server sends the list over ChallengeEvent whenever something changes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local compact = UserInputService.TouchEnabled
local event = ReplicatedStorage:WaitForChild("ChallengeEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "ChallengesUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 18
gui.Parent = playerGui

local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = obj end

local function label(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 7
	l.Parent = parent
	return l
end

local open = Instance.new("TextButton")
open.Size = UDim2.fromOffset(150, 38)
open.AnchorPoint = Vector2.new(1, 0)
open.Position = UDim2.new(1, -12, 0, 330)
open.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
open.BorderSizePixel = 0
open.Text = "Daily Challenges"
open.TextColor3 = Color3.new(1, 1, 1)
open.Font = Enum.Font.GothamBold
open.TextSize = compact and 13 or 15
open.Visible = false
open.Parent = gui
corner(open, 8)

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.BorderSizePixel = 0
dim.Visible = false
dim.Active = true
dim.ZIndex = 5
dim.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.92, 0, 0, 340)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
panel.BorderSizePixel = 0
panel.ZIndex = 6
panel.Parent = dim
corner(panel, 14)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(460, 340)
limit.Parent = panel

local title = label(panel, "Daily Challenges", 24, Color3.fromRGB(110, 190, 255), Enum.Font.GothamBlack)
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.fromOffset(20, 10)

local sub = label(panel, "New goals every day. Coins are paid when you finish one.", 13, Color3.fromRGB(170, 175, 195), Enum.Font.Gotham)
sub.Size = UDim2.new(1, -40, 0, 20)
sub.Position = UDim2.fromOffset(20, 48)

local rows = {}
for i = 1, 3 do
	local r = Instance.new("Frame")
	r.Position = UDim2.fromOffset(20, 78 + (i - 1) * 74)
	r.Size = UDim2.new(1, -40, 0, 66)
	r.BackgroundColor3 = Color3.fromRGB(38, 38, 56)
	r.BorderSizePixel = 0
	r.ZIndex = 7
	r.Parent = panel
	corner(r, 10)
	local text = label(r, "", compact and 14 or 16, Color3.new(1, 1, 1))
	text.Position = UDim2.fromOffset(12, 6)
	text.Size = UDim2.new(1, -100, 0, 24)
	text.TextTruncate = Enum.TextTruncate.AtEnd
	local reward = label(r, "", 15, Color3.fromRGB(255, 215, 80))
	reward.AnchorPoint = Vector2.new(1, 0)
	reward.Position = UDim2.new(1, -12, 0, 6)
	reward.Size = UDim2.fromOffset(84, 24)
	reward.TextXAlignment = Enum.TextXAlignment.Right
	local back = Instance.new("Frame")
	back.Position = UDim2.new(0, 12, 1, -26)
	back.Size = UDim2.new(1, -24, 0, 16)
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	back.BorderSizePixel = 0
	back.ZIndex = 8
	back.Parent = r
	corner(back, 8)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
	fill.BorderSizePixel = 0
	fill.ZIndex = 9
	fill.Parent = back
	corner(fill, 8)
	local count = label(back, "", 12, Color3.new(1, 1, 1))
	count.Size = UDim2.fromScale(1, 1)
	count.TextXAlignment = Enum.TextXAlignment.Center
	count.ZIndex = 10
	rows[i] = { text = text, reward = reward, fill = fill, count = count }
end

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(120, 40)
close.AnchorPoint = Vector2.new(0.5, 1)
close.Position = UDim2.new(0.5, 0, 1, -12)
close.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
close.BorderSizePixel = 0
close.Text = "Close"
close.TextColor3 = Color3.new(1, 1, 1)
close.Font = Enum.Font.GothamBold
close.TextSize = 16
close.ZIndex = 8
close.Parent = panel
corner(close, 8)

event.OnClientEvent:Connect(function(action, list)
	if action ~= "State" then return end
	for i, r in ipairs(rows) do
		local c = list[i]
		if c then
			r.text.Text = c.text
			r.reward.Text = "+" .. c.reward
			r.fill.Size = UDim2.fromScale(math.clamp(c.progress / c.target, 0, 1), 1)
			r.fill.BackgroundColor3 = c.done and Color3.fromRGB(80, 200, 110) or Color3.fromRGB(80, 170, 255)
			r.count.Text = c.done and "DONE" or (c.progress .. " / " .. c.target)
		end
	end
end)

open.Activated:Connect(function()
	event:FireServer("Request")
	dim.Visible = true
end)
close.Activated:Connect(function() dim.Visible = false end)

task.spawn(function()
	local menu = playerGui:WaitForChild("DifficultyMenu")
	local function sync()
		open.Visible = menu.Enabled
		if not menu.Enabled then dim.Visible = false end
	end
	menu:GetPropertyChangedSignal("Enabled"):Connect(sync)
	sync()
end)
event:FireServer("Request")
