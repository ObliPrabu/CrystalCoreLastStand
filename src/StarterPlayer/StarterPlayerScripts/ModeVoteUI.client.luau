-- Vote panel shown for a few seconds before a round when 2+ players are in the server: Co-op or Versus.
-- Versus = the most zombie kills wins. The server (WaveManager) runs the vote and counts it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local compact = UserInputService.TouchEnabled
local event = ReplicatedStorage:WaitForChild("ModeEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "ModeVoteUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Enabled = false
gui.Parent = playerGui

local function corner(obj, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = obj end

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, compact and 40 or 90)
panel.Size = UDim2.new(0.92, 0, 0, 210)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 14)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(460, 210)
limit.Parent = panel

local function label(text, size, color, y, h)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(16, y)
	l.Size = UDim2.new(1, -32, 0, h)
	l.Font = Enum.Font.GothamBold
	l.TextSize = size
	l.TextColor3 = color
	l.TextWrapped = true
	l.Text = text
	l.Parent = panel
	return l
end

local title = label("How do you want to play?", 22, Color3.fromRGB(255, 215, 80), 10, 30)
local info = label("Co-op: beat the waves together.\nVersus: most zombie kills wins (hitting players does nothing).", 13, Color3.fromRGB(190, 190, 210), 42, 44)

local function choiceButton(text, color, x)
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(x, x == 0 and 16 or 4, 0, 94)
	b.Size = UDim2.new(0.5, -20, 0, 54)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 17
	b.Text = text
	b.Parent = panel
	corner(b, 10)
	return b
end
local coopBtn = choiceButton("Co-op (0)", Color3.fromRGB(60, 150, 90), 0)
local versusBtn = choiceButton("Versus (0)", Color3.fromRGB(200, 90, 60), 0.5)
local status = label("", 14, Color3.fromRGB(170, 175, 195), 160, 40)

local picked, endsAt = nil, 0
local function tally(coop, versus)
	coopBtn.Text = ("Co-op (%d)"):format(coop)
	versusBtn.Text = ("Versus (%d)"):format(versus)
end

coopBtn.Activated:Connect(function() picked = "Coop" event:FireServer("Vote", "Coop") status.Text = "You voted Co-op" end)
versusBtn.Activated:Connect(function() picked = "Versus" event:FireServer("Vote", "Versus") status.Text = "You voted Versus" end)

event.OnClientEvent:Connect(function(action, a, b, c)
	if action == "VoteStart" then
		picked = nil
		tally(0, 0)
		status.Text = "Vote now!"
		endsAt = os.clock() + a
		gui.Enabled = true
		task.spawn(function()
			while gui.Enabled and os.clock() < endsAt do
				if not picked then status.Text = ("Vote now! %d s"):format(math.ceil(endsAt - os.clock())) end
				task.wait(0.25)
			end
		end)
	elseif action == "Tally" then
		tally(a, b)
	elseif action == "VoteEnd" then
		tally(b, c)
		status.Text = a == "Versus" and "Versus wins the vote!" or "Co-op wins the vote!"
		task.delay(2, function() gui.Enabled = false end)
	end
end)
