local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local event = ReplicatedStorage:WaitForChild("DifficultyEvent")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "DifficultyMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromOffset(380, 330)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 12)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = frame

local title = Instance.new("TextLabel")
title.LayoutOrder = 0
title.Size = UDim2.fromOffset(340, 76)
title.BackgroundTransparency = 1
title.Text = "CRYSTAL CORE: LAST STAND\nChoose your difficulty"
title.TextWrapped = true
title.RichText = false
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.Parent = frame

local options = {
	{ "Easy", Color3.fromRGB(60, 160, 80), "Relaxed - tough core, weak enemies" },
	{ "Hard", Color3.fromRGB(210, 140, 40), "Bigger waves, stronger enemies" },
	{ "Impossible", Color3.fromRGB(190, 45, 45), "Fragile core, brutal waves" },
}

for i, opt in ipairs(options) do
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = i
	btn.Size = UDim2.fromOffset(320, 62)
	btn.BackgroundColor3 = opt[2]
	btn.BorderSizePixel = 0
	btn.Text = opt[1] .. "\n" .. opt[3]
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.AutoButtonColor = true
	btn.Parent = frame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

	btn.Activated:Connect(function()
		event:FireServer(opt[1])
	end)
end

event.OnClientEvent:Connect(function(action)
	if action == "ShowMenu" then
		gui.Enabled = true
	elseif action == "Hide" then
		gui.Enabled = false
	end
end)

-- Ask the server whether a difficulty still needs to be picked
event:FireServer("Ready")
