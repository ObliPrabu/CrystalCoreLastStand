-- Adds an "Endless" button to the difficulty menu. Endless has no wave goal: you pick how many minutes
-- to survive (1-60) and a difficulty, and try to clear as many waves as you can before the Core falls
-- or the time runs out. (Endless runs give no Win and no Robux skips, so they can't be farmed.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage:WaitForChild("DifficultyEvent")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local gui = playerGui:WaitForChild("DifficultyMenu")
local frame = gui:WaitForChild("Frame")

-- make room for a fourth button in the existing list
for _, c in ipairs(frame:GetChildren()) do
	if c:IsA("TextButton") then c.Size = UDim2.fromOffset(320, 50) end
	if c:IsA("TextLabel") then c.Size = UDim2.fromOffset(340, 60) c.TextSize = 22 end
end
local layout = frame:FindFirstChildOfClass("UIListLayout")
if layout then layout.Padding = UDim.new(0, 8) end

local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o end

local function makeButton(parent, text, color, w, h, x, y)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, h)
	b.Position = UDim2.fromOffset(x, y)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 8)
	return b
end

local function makeLabel(parent, text, size, y, font, color)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromOffset(340, size + 6)
	l.Position = UDim2.fromOffset(20, y)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.Font = font or Enum.Font.GothamBold
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Parent = parent
	return l
end

-- the main menu's new button
local endlessBtn = Instance.new("TextButton")
endlessBtn.LayoutOrder = 4
endlessBtn.Size = UDim2.fromOffset(320, 50)
endlessBtn.BackgroundColor3 = Color3.fromRGB(125, 70, 190)
endlessBtn.BorderSizePixel = 0
endlessBtn.Text = "Endless\nPick your own time, 1 to 60 minutes"
endlessBtn.TextColor3 = Color3.new(1, 1, 1)
endlessBtn.Font = Enum.Font.GothamBold
endlessBtn.TextSize = 18
endlessBtn.Parent = frame
corner(endlessBtn, 10)

-- the Endless setup panel
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(380, 330)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
corner(panel, 14)

makeLabel(panel, "ENDLESS", 24, 10)
makeLabel(panel, "How long do you want to survive?", 14, 42, Enum.Font.Gotham, Color3.fromRGB(190, 195, 210))
local minutes = 15
local shown = makeLabel(panel, "15 min", 34, 66, Enum.Font.GothamBlack, Color3.fromRGB(255, 215, 90))

local function setMinutes(m)
	minutes = math.clamp(m, 1, 60)
	shown.Text = minutes .. (minutes == 1 and " min" or " min")
end

local steps = { { "-5", -5 }, { "-1", -1 }, { "+1", 1 }, { "+5", 5 } }
for i, st in ipairs(steps) do
	local b = makeButton(panel, st[1], Color3.fromRGB(60, 65, 90), 76, 38, 20 + (i - 1) * 84, 112)
	b.Activated:Connect(function() setMinutes(minutes + st[2]) end)
end
for i, m in ipairs({ 1, 5, 15, 30, 60 }) do
	local b = makeButton(panel, tostring(m), Color3.fromRGB(80, 60, 130), 60, 34, 20 + (i - 1) * 68, 158)
	b.Activated:Connect(function() setMinutes(m) end)
end

makeLabel(panel, "Pick a difficulty to start:", 14, 198, Enum.Font.Gotham, Color3.fromRGB(190, 195, 210))
local diffs = { { "Easy", Color3.fromRGB(60, 160, 80) }, { "Hard", Color3.fromRGB(210, 140, 40) }, { "Impossible", Color3.fromRGB(190, 45, 45) } }
for i, d in ipairs(diffs) do
	local b = makeButton(panel, d[1], d[2], 104, 42, 20 + (i - 1) * 112, 224)
	b.Activated:Connect(function() event:FireServer("Endless", d[1], minutes) end)
end

local back = makeButton(panel, "Back", Color3.fromRGB(70, 75, 95), 120, 34, 130, 284)

endlessBtn.Activated:Connect(function()
	frame.Visible = false
	panel.Visible = true
end)
back.Activated:Connect(function()
	panel.Visible = false
	frame.Visible = true
end)

-- every time the menu opens again, start on the main page
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if gui.Enabled then
		panel.Visible = false
		frame.Visible = true
	end
end)
