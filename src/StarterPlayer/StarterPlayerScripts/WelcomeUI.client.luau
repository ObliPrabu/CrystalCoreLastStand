-- First-time tutorial, the daily reward popup, and two buttons ("How to play", "Daily reward")
-- that appear in the corner while the difficulty menu is open.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local daily = ReplicatedStorage:WaitForChild("DailyEvent")

local compact = UserInputService.TouchEnabled
local panelMax = compact and 400 or 460

local gui = Instance.new("ScreenGui")
gui.Name = "WelcomeUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = playerGui

local GOLD = Color3.fromRGB(255, 205, 70)
local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 10) c.Parent = obj end

local function label(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = font or Enum.Font.GothamBold
	l.TextWrapped = true
	l.Parent = parent
	return l
end

local function button(parent, text, color, w, h)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, h)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = compact and 16 or 18
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 10)
	return b
end

-- full-screen dim + centered panel
local function makePanel(height)
	local dim = Instance.new("TextButton")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.92, 0, 0, height)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	panel.BorderSizePixel = 0
	panel.Parent = dim
	corner(panel, 14)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(panelMax, math.huge)
	limit.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 200, 240)
	stroke.Thickness = 2
	stroke.Parent = panel
	return dim, panel
end

------------------------------------------------------------
-- Tutorial
------------------------------------------------------------
local PAGES = {
	{ "Defend the Crystal Core!",
		"Zombies walk to the glowing Core and smash it. If the Core's health reaches 0 the round is over.\n\nSurvive 30 waves to win!" },
	{ "Fight back",
		"Pick a weapon on the hotbar at the bottom (press 1, 2, 3 or tap it), then click or tap to attack.\n\nGuns: press R to reload. Green AMMO crates around the map refill your ammo." },
	{ "Coins and the shop",
		"Every kill earns coins for everyone. Spend them on Turrets that shoot for you, Upgrades, repairing the Core, and new weapons in the ARMORY.\n\nCoins reset each round." },
	{ "Tips",
		"A big BOSS arrives every 5th wave.\n\nStay near the Core and build turrets early.\n\nBring friends - you win together!" },
}

local tutDim, tutPanel = makePanel(compact and 270 or 300)
local tutTitle = label(tutPanel, "", compact and 22 or 26, GOLD, Enum.Font.GothamBlack)
tutTitle.Position = UDim2.fromOffset(16, 12)
tutTitle.Size = UDim2.new(1, -32, 0, 34)
local tutBody = label(tutPanel, "", compact and 15 or 18, Color3.fromRGB(225, 230, 240), Enum.Font.Gotham)
tutBody.Position = UDim2.fromOffset(16, 54)
tutBody.Size = UDim2.new(1, -32, 1, compact and -122 or -134)
tutBody.TextXAlignment = Enum.TextXAlignment.Left
tutBody.TextYAlignment = Enum.TextYAlignment.Top
local tutDots = label(tutPanel, "", 20, Color3.fromRGB(150, 160, 180))
tutDots.AnchorPoint = Vector2.new(0, 1)
tutDots.Position = UDim2.new(0, 16, 1, -16)
tutDots.Size = UDim2.fromOffset(90, 30)
local tutSkip = button(tutPanel, "Skip", Color3.fromRGB(70, 75, 95), 70, 40)
tutSkip.AnchorPoint = Vector2.new(1, 1)
tutSkip.Position = UDim2.new(1, -150, 1, -12)
local tutNext = button(tutPanel, "Next", Color3.fromRGB(60, 160, 80), 126, 40)
tutNext.AnchorPoint = Vector2.new(1, 1)
tutNext.Position = UDim2.new(1, -12, 1, -12)

local tutPage = 1
local tutMark = false -- true on the very first run: tell the server it was seen
local onTutorialClosed

local function showPage()
	local p = PAGES[tutPage]
	tutTitle.Text = p[1]
	tutBody.Text = p[2]
	tutNext.Text = (tutPage == #PAGES) and "Let's go!" or "Next"
	tutSkip.Visible = tutPage < #PAGES
	tutDots.Text = string.rep("● ", tutPage) .. string.rep("○ ", #PAGES - tutPage)
end

local function closeTutorial()
	tutDim.Visible = false
	if tutMark then
		tutMark = false
		daily:FireServer("TutorialDone")
	end
	if onTutorialClosed then
		local f = onTutorialClosed
		onTutorialClosed = nil
		f()
	end
end

local function openTutorial(first)
	tutPage = 1
	tutMark = first
	showPage()
	tutDim.Visible = true
end

tutNext.Activated:Connect(function()
	if tutPage >= #PAGES then closeTutorial() else tutPage += 1 showPage() end
end)
tutSkip.Activated:Connect(closeTutorial)

------------------------------------------------------------
-- Daily reward
------------------------------------------------------------
local state -- last "State" from the server

local dayDim, dayPanel = makePanel(compact and 290 or 320)
local dayTitle = label(dayPanel, "DAILY REWARD", compact and 22 or 26, GOLD, Enum.Font.GothamBlack)
dayTitle.Position = UDim2.fromOffset(16, 10)
dayTitle.Size = UDim2.new(1, -32, 0, 32)
local daySub = label(dayPanel, "", compact and 14 or 16, Color3.fromRGB(210, 215, 230), Enum.Font.Gotham)
daySub.Position = UDim2.fromOffset(16, 44)
daySub.Size = UDim2.new(1, -32, 0, 40)

local tiles = {}
local row = Instance.new("Frame")
row.BackgroundTransparency = 1
row.Position = UDim2.fromOffset(12, 90)
row.Size = UDim2.new(1, -24, 0, compact and 80 or 92)
row.Parent = dayPanel
local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.Padding = UDim.new(0, 4)
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.Parent = row
for i = 1, 7 do
	local t = Instance.new("Frame")
	t.Size = UDim2.new(1 / 7, -4, 1, 0)
	t.BorderSizePixel = 0
	t.Parent = row
	corner(t, 8)
	local dl = label(t, "Day " .. i, compact and 11 or 13, Color3.new(1, 1, 1))
	dl.Size = UDim2.new(1, 0, 0, 20)
	dl.Position = UDim2.fromOffset(0, 4)
	local rl = label(t, "", compact and 15 or 18, GOLD, Enum.Font.GothamBlack)
	rl.Position = UDim2.fromScale(0, 0.38)
	rl.Size = UDim2.new(1, 0, 0, 24)
	local cl = label(t, "coins", compact and 10 or 12, Color3.fromRGB(220, 225, 235), Enum.Font.Gotham)
	cl.Position = UDim2.fromScale(0, 0.7)
	cl.Size = UDim2.new(1, 0, 0, 16)
	tiles[i] = { frame = t, reward = rl, coins = cl }
end

local dayFooter = label(dayPanel, "", compact and 12 or 14, Color3.fromRGB(150, 160, 180), Enum.Font.Gotham)
dayFooter.AnchorPoint = Vector2.new(0, 1)
dayFooter.Position = UDim2.new(0, 16, 1, -62)
dayFooter.Size = UDim2.new(1, -32, 0, 20)
local claimBtn = button(dayPanel, "CLAIM", Color3.fromRGB(60, 170, 90), 170, 42)
claimBtn.AnchorPoint = Vector2.new(0.5, 1)
claimBtn.Position = UDim2.new(0.5, 0, 1, -12)

local function refreshDaily()
	if not state then return end
	for i, t in ipairs(tiles) do
		t.reward.Text = tostring(state.rewards[i])
		local done = (i < state.day) or (i == state.day and not state.canClaim)
		local today = (i == state.day and state.canClaim)
		t.frame.BackgroundColor3 = today and Color3.fromRGB(140, 110, 20)
			or (done and Color3.fromRGB(35, 95, 55) or Color3.fromRGB(45, 48, 66))
		t.coins.Text = done and "taken" or "coins"
	end
	if state.canClaim then
		daySub.Text = ("Day %d reward is ready! Come back every day for a bigger prize."):format(state.day)
		claimBtn.Text = ("CLAIM +%d"):format(state.rewards[state.day])
		claimBtn.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
	else
		daySub.Text = "You already claimed today. Come back tomorrow!"
		claimBtn.Text = "CLOSE"
		claimBtn.BackgroundColor3 = Color3.fromRGB(70, 75, 95)
	end
	dayFooter.Text = ("Wins %d   |   Best wave %d   |   Total kills %d"):format(state.wins or 0, state.bestWave or 0, state.kills or 0)
end

local dailyBtn -- the corner button, defined below
local function updateDot()
	if dailyBtn then
		dailyBtn.Text = (state and state.canClaim) and "Daily reward  (!)" or "Daily reward"
	end
end

local function openDaily()
	if not state then
		daily:FireServer("Request")
		return
	end
	refreshDaily()
	dayDim.Visible = true
end

claimBtn.Activated:Connect(function()
	if state and state.canClaim and state.loaded then
		daily:FireServer("Claim")
	else
		dayDim.Visible = false
	end
end)
dayDim.Activated:Connect(function() end) -- swallow clicks on the dim background

------------------------------------------------------------
-- Corner buttons (only while the difficulty menu is open)
------------------------------------------------------------
local helpBtn = button(gui, "How to play", Color3.fromRGB(60, 120, 200), 150, 38)
helpBtn.AnchorPoint = Vector2.new(0, 1)
helpBtn.Position = UDim2.new(0, 12, 1, -58)
helpBtn.Visible = false
helpBtn.ZIndex = 0 -- stays behind the popups
dailyBtn = button(gui, "Daily reward", Color3.fromRGB(200, 150, 40), 150, 38)
dailyBtn.AnchorPoint = Vector2.new(0, 1)
dailyBtn.Position = UDim2.new(0, 12, 1, -12)
dailyBtn.Visible = false
dailyBtn.ZIndex = 0

helpBtn.Activated:Connect(function() openTutorial(false) end)
dailyBtn.Activated:Connect(openDaily)

task.spawn(function()
	local menu = playerGui:WaitForChild("DifficultyMenu")
	local function sync()
		helpBtn.Visible = menu.Enabled
		dailyBtn.Visible = menu.Enabled
	end
	menu:GetPropertyChangedSignal("Enabled"):Connect(sync)
	sync()
end)

------------------------------------------------------------
-- Server messages
------------------------------------------------------------
local firstState = true
daily.OnClientEvent:Connect(function(kind, data)
	if kind == "State" then
		state = data
		updateDot()
		if dayDim.Visible then refreshDaily() end
		if firstState then
			firstState = false
			if not data.tutorialDone and data.loaded then
				onTutorialClosed = function()
					if state.canClaim then openDaily() end
				end
				openTutorial(true)
			elseif data.canClaim and data.loaded then
				openDaily()
			end
		end
	elseif kind == "Claimed" then
		daySub.Text = ("+%d coins claimed! See you tomorrow."):format(data)
	end
end)

daily:FireServer("Request")
