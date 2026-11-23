-- Target marker: while you hold a gun, a red ring and an outline show the enemy closest to where you are
-- aiming (your mouse, or your last tap on a phone), with its health under the ring. It is only a hint:
-- it never aims or fires for you.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local MAX_PIXELS = 220     -- how far from your aim point an enemy can be and still get picked
local MAX_STUDS = 320
local RED = Color3.fromRGB(255, 60, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "TargetMarker"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 7
gui.Parent = playerGui

local ring = Instance.new("Frame")
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Size = UDim2.fromOffset(62, 62)
ring.BackgroundTransparency = 1
ring.Visible = false
ring.Parent = gui
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(1, 0)
round.Parent = ring
local stroke = Instance.new("UIStroke")
stroke.Color = RED
stroke.Thickness = 4
stroke.Parent = ring
local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.fromScale(0.5, 0.5)
dot.Size = UDim2.fromOffset(10, 10)
dot.BackgroundColor3 = RED
dot.BorderSizePixel = 0
dot.Parent = ring
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local hpBack = Instance.new("Frame")
hpBack.AnchorPoint = Vector2.new(0.5, 0)
hpBack.Position = UDim2.new(0.5, 0, 1, 6)
hpBack.Size = UDim2.fromOffset(56, 7)
hpBack.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
hpBack.BorderSizePixel = 0
hpBack.Parent = ring
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = RED
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBack

local outline = Instance.new("Highlight")
outline.Name = "TargetOutline"
outline.FillTransparency = 1
outline.OutlineColor = RED
outline.OutlineTransparency = 0
outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
outline.Enabled = false

local function holdingGun()
	local char = player.Character
	local tool = char and char:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("IsGun") == true
end

local function aimPoint()
	local p = UserInputService:GetMouseLocation()
	if p.X <= 1 and p.Y <= 1 then -- phone before the first tap: use the middle of the screen
		return camera.ViewportSize / 2
	end
	return p
end

local folders = {}
local function refreshFolders()
	folders = {}
	for _, name in ipairs({ "Enemies", "PracticeDummies" }) do
		local f = Workspace:FindFirstChild(name)
		if f then table.insert(folders, f) end
	end
end
refreshFolders()
local lastRefresh = 0

local currentTarget
local function clearTarget()
	currentTarget = nil
	ring.Visible = false
	outline.Enabled = false
	outline.Parent = nil
end

RunService.RenderStepped:Connect(function()
	camera = Workspace.CurrentCamera
	if not camera or not holdingGun() then
		if currentTarget or ring.Visible then clearTarget() end
		return
	end
	if os.clock() - lastRefresh > 2 then
		lastRefresh = os.clock()
		refreshFolders()
	end

	local char = player.Character
	local myRoot = char and char:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local aim = aimPoint()

	local best, bestDist, bestScreen
	for _, folder in ipairs(folders) do
		for _, enemy in ipairs(folder:GetChildren()) do
			local hum = enemy:FindFirstChildOfClass("Humanoid")
			local root = enemy:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 and (root.Position - myRoot.Position).Magnitude <= MAX_STUDS then
				local v, onScreen = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 1.2, 0))
				if onScreen then
					local d = (Vector2.new(v.X, v.Y) - aim).Magnitude
					if d < MAX_PIXELS and (not bestDist or d < bestDist) then
						best, bestDist, bestScreen = enemy, d, Vector2.new(v.X, v.Y)
					end
				end
			end
		end
	end

	if not best then
		if currentTarget or ring.Visible then clearTarget() end
		return
	end

	if best ~= currentTarget then
		currentTarget = best
		outline.Parent = best
		outline.Adornee = best
		outline.Enabled = true
	end
	ring.Visible = true
	ring.Position = UDim2.fromOffset(bestScreen.X, bestScreen.Y)
	local hum = best:FindFirstChildOfClass("Humanoid")
	if hum then
		hpFill.Size = UDim2.fromScale(math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1), 1)
	end
end)
