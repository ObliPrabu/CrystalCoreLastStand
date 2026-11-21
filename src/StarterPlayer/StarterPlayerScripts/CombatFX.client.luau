-- Makes fighting feel better: floating damage numbers, a white flash when an enemy is hit,
-- a BOSS warning banner with screen shake, and a red flash + small shake when you get hurt.
-- Everything here is local to your screen; it never changes damage or gameplay.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local enemies = Workspace:WaitForChild("Enemies")
local compact = UserInputService.TouchEnabled

local gui = Instance.new("ScreenGui")
gui.Name = "CombatFX"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6
gui.Parent = playerGui

------------------------------------------------------------
-- Screen shake (moves the camera a little through Humanoid.CameraOffset)
------------------------------------------------------------
local shakeTime, shakeDuration, shakeMagnitude = 0, 0, 0

local function shake(magnitude, duration)
	if magnitude * 1 >= shakeMagnitude * (1 - shakeTime / math.max(shakeDuration, 0.01)) then
		shakeMagnitude, shakeDuration, shakeTime = magnitude, duration, 0
	end
end

RunService.RenderStepped:Connect(function(dt)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if shakeTime < shakeDuration then
		shakeTime += dt
		local k = math.max(0, 1 - shakeTime / shakeDuration)
		hum.CameraOffset = Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * 2 * shakeMagnitude * k
	elseif hum.CameraOffset ~= Vector3.zero then
		hum.CameraOffset = Vector3.zero
	end
end)

------------------------------------------------------------
-- Damage numbers + hit flash on enemies
------------------------------------------------------------
local function popNumber(adornee, amount, killed)
	local rounded = math.max(1, math.floor(amount + 0.5))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 44)
	bb.StudsOffset = Vector3.new((math.random() - 0.5) * 2.5, 2.5, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 160
	bb.Parent = adornee -- removed together with the enemy

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = killed and (rounded .. "!") or tostring(rounded)
	label.TextColor3 = killed and Color3.fromRGB(255, 120, 90)
		or (rounded >= 40 and Color3.fromRGB(255, 170, 50))
		or (rounded >= 18 and Color3.fromRGB(255, 235, 110))
		or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(30, 20, 20)
	label.Parent = bb
	local size = math.clamp(0.55 + rounded / 90, 0.55, 1.1) * (killed and 1.25 or 1)
	label.Size = UDim2.fromScale(size, size)
	label.Position = UDim2.fromScale((1 - size) / 2, (1 - size) / 2)

	TweenService:Create(bb, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ StudsOffset = bb.StudsOffset + Vector3.new(0, 4, 0) }):Play()
	task.delay(0.35, function()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	Debris:AddItem(bb, 0.9)
end

local function flash(enemy)
	local h = enemy:FindFirstChild("HitFlash")
	if not h then
		h = Instance.new("Highlight")
		h.Name = "HitFlash"
		h.FillColor = Color3.new(1, 1, 1)
		h.FillTransparency = 1
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = enemy
	end
	h.FillTransparency = 0.3
	TweenService:Create(h, TweenInfo.new(0.18), { FillTransparency = 1 }):Play()
end

------------------------------------------------------------
-- BOSS banner
------------------------------------------------------------
local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.28)
banner.Size = UDim2.fromOffset(compact and 300 or 520, compact and 54 or 84)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.Text = "!! BOSS !!"
banner.TextColor3 = Color3.fromRGB(255, 80, 80)
banner.TextStrokeTransparency = 0
banner.TextStrokeColor3 = Color3.fromRGB(40, 0, 0)
banner.Visible = false
banner.Parent = gui

local bannerId = 0
local function showBoss()
	bannerId += 1
	local id = bannerId
	banner.Visible = true
	banner.TextTransparency, banner.TextStrokeTransparency = 0, 0
	banner.Rotation = -4
	local base = banner.Size
	banner.Size = UDim2.new(base.X.Scale, base.X.Offset * 1.6, base.Y.Scale, base.Y.Offset * 1.6)
	TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = base, Rotation = 0 }):Play()
	shake(0.9, 1.2)
	task.delay(2.2, function()
		if bannerId ~= id then return end
		local t = TweenService:Create(banner, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 })
		t:Play()
		t.Completed:Connect(function()
			if bannerId == id then banner.Visible = false end
		end)
	end)
end

------------------------------------------------------------
-- Watch every enemy
------------------------------------------------------------
local function watch(enemy)
	local hum = enemy:WaitForChild("Humanoid", 5)
	if not hum then return end
	if hum.DisplayName == "BOSS" then showBoss() end
	local last = hum.Health
	hum.HealthChanged:Connect(function(health)
		local lost = last - health
		last = health
		if lost < 0.5 then return end
		local part = enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart")
		if part then popNumber(part, lost, health <= 0) end
		flash(enemy)
	end)
end

local function watchFolder(folder)
	folder.ChildAdded:Connect(function(e) task.spawn(watch, e) end)
	for _, e in ipairs(folder:GetChildren()) do task.spawn(watch, e) end
end
watchFolder(enemies)
task.spawn(function() -- the Practice Arena dummies get damage numbers too
	local dummies = Workspace:WaitForChild("PracticeDummies", 30)
	if dummies then watchFolder(dummies) end
end)

------------------------------------------------------------
-- You got hurt: red flash + small shake
------------------------------------------------------------
local hurt = Instance.new("Frame")
hurt.Size = UDim2.fromScale(1, 1)
hurt.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
hurt.BackgroundTransparency = 1
hurt.BorderSizePixel = 0
hurt.Parent = gui

local function watchCharacter(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	local last = hum.Health
	hum.HealthChanged:Connect(function(health)
		local lost = last - health
		last = health
		if lost < 1 then return end
		hurt.BackgroundTransparency = 0.7
		TweenService:Create(hurt, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
		shake(math.clamp(lost / 40, 0.15, 0.6), 0.25)
	end)
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then task.spawn(watchCharacter, player.Character) end
