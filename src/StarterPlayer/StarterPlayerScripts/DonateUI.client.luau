-- Donate button (top right, under the other menu buttons, only while the difficulty menu is open).
-- Opens a small panel with three Robux amounts. Donations give thanks and a Supporter flag, nothing else.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local compact = UserInputService.TouchEnabled

local AMOUNTS = {
	{ robux = 25, productId = 3735366362 },
	{ robux = 100, productId = 3735366426 },
	{ robux = 500, productId = 3735366440 },
}

local gui = Instance.new("ScreenGui")
gui.Name = "DonateUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 18
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

local open = button(gui, "Donate", Color3.fromRGB(215, 70, 110), 150, 38)
open.AnchorPoint = Vector2.new(1, 0)
open.Position = UDim2.new(1, -12, 0, 284)
open.Visible = false

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
panel.Size = UDim2.new(0.9, 0, 0, 290)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
panel.BorderSizePixel = 0
panel.ZIndex = 6
panel.Parent = dim
corner(panel, 14)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(420, 290)
limit.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 44)
title.Position = UDim2.fromOffset(0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 120, 150)
title.Text = "Support the game"
title.ZIndex = 7
title.Parent = panel

local blurb = Instance.new("TextLabel")
blurb.Position = UDim2.fromOffset(20, 56)
blurb.Size = UDim2.new(1, -40, 0, 56)
blurb.BackgroundTransparency = 1
blurb.TextWrapped = true
blurb.Font = Enum.Font.Gotham
blurb.TextSize = 15
blurb.TextColor3 = Color3.fromRGB(205, 205, 220)
blurb.Text = "Donations help me make more updates. You get a big thank-you and the Supporter title. No gameplay advantage."
blurb.ZIndex = 7
blurb.Parent = panel

local row = Instance.new("Frame")
row.Position = UDim2.fromOffset(20, 124)
row.Size = UDim2.new(1, -40, 0, 56)
row.BackgroundTransparency = 1
row.ZIndex = 7
row.Parent = panel
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = row

for _, a in ipairs(AMOUNTS) do
	local b = button(row, a.robux .. " Robux", Color3.fromRGB(215, 70, 110), 100, 56)
	b.TextSize = 17
	b.ZIndex = 8
	b.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, a.productId)
	end)
end

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(20, 192)
status.Size = UDim2.new(1, -40, 0, 28)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextSize = 16
status.TextColor3 = Color3.fromRGB(255, 215, 80)
status.Text = ""
status.ZIndex = 7
status.Parent = panel

local close = button(panel, "Close", Color3.fromRGB(70, 70, 90), 120, 40)
close.AnchorPoint = Vector2.new(0.5, 1)
close.Position = UDim2.new(0.5, 0, 1, -14)
close.ZIndex = 8

local function refresh()
	status.Text = player:GetAttribute("Supporter") and "You are a Supporter - thank you!" or ""
end
player:GetAttributeChangedSignal("Supporter"):Connect(refresh)
refresh()

open.Activated:Connect(function() refresh() dim.Visible = true end)
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
