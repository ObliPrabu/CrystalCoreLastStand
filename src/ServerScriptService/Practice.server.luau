-- Practice Arena: a separate platform far away from the real arena, so it never interferes with a round.
-- You walk in through a doorway next to the spawn; it is closed (red barrier) while a real round is running.
-- You get EVERY weapon there (WeaponManager reads the player attribute InPractice) and can spawn training dummies.
-- Nothing counts: no coins, kills, wins or achievements. Dummies live in Workspace.PracticeDummies, not in
-- Workspace.Enemies, so WaveManager, PowerUps and Achievements never see them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ORIGIN = Vector3.new(2000, 0, 0)  -- the platform is centred here
local SIZE = 160
local MAX_DUMMIES = 10
local DUMMY_HEALTH = 5000
local HEAL_AFTER = 3                    -- seconds without damage before a dummy heals fully

local template = ServerStorage:WaitForChild("Enemy")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local core = Workspace:WaitForChild("Core")

local event = Instance.new("RemoteEvent")
event.Name = "PracticeEvent"
event.Parent = ReplicatedStorage

local KINDS = {
	Zombie = { color = Color3.fromRGB(80, 140, 70), scale = 1 },
	Runner = { color = Color3.fromRGB(235, 140, 40), scale = 0.85 },
	Tank = { color = Color3.fromRGB(120, 50, 50), scale = 1.4 },
	Exploder = { color = Color3.fromRGB(255, 90, 40), scale = 0.9 },
	Spitter = { color = Color3.fromRGB(70, 200, 160), scale = 0.95 },
	Boss = { color = Color3.fromRGB(130, 60, 190), scale = 2.3 },
}

------------------------------------------------------------
-- The platform
------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "Practice"
folder.Parent = Workspace

local floor = Instance.new("Part")
floor.Name = "PracticeFloor"
floor.Anchored = true
floor.Size = Vector3.new(SIZE, 2, SIZE)
floor.Position = ORIGIN                -- top surface at y = 1, like the real arena
floor.Color = Color3.fromRGB(150, 170, 205)
floor.Material = Enum.Material.SmoothPlastic
floor.Parent = folder

for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do   -- invisible walls so nobody falls off
	local wall = Instance.new("Part")
	wall.Anchored = true
	wall.Transparency = 1
	wall.Size = d[1] ~= 0 and Vector3.new(2, 60, SIZE) or Vector3.new(SIZE, 60, 2)
	wall.Position = ORIGIN + Vector3.new(d[1] * SIZE / 2, 30, d[2] * SIZE / 2)
	wall.Parent = folder
end

-- the night lighting is dark, so hang a few lamps over the platform
for _, spot in ipairs({ { 0, 0 }, { 50, 50 }, { -50, 50 }, { 50, -50 }, { -50, -50 } }) do
	local lamp = Instance.new("Part")
	lamp.Anchored = true
	lamp.CanCollide = false
	lamp.Transparency = 1
	lamp.Size = Vector3.new(1, 1, 1)
	lamp.Position = ORIGIN + Vector3.new(spot[1], 26, spot[2])
	lamp.Parent = folder
	local light = Instance.new("PointLight")
	light.Range = 90
	light.Brightness = 4
	light.Color = Color3.fromRGB(255, 245, 225)
	light.Parent = lamp
end

local sign = Instance.new("Part")
sign.Name = "PracticeSign"
sign.Anchored = true
sign.CanCollide = false
sign.Transparency = 1
sign.Size = Vector3.new(1, 1, 1)
sign.Position = ORIGIN + Vector3.new(0, 22, -60)
sign.Parent = folder
local gui = Instance.new("BillboardGui")
gui.Size = UDim2.fromOffset(420, 70)
gui.AlwaysOnTop = false
gui.MaxDistance = 400
gui.Parent = sign
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.TextScaled = true
text.Font = Enum.Font.GothamBlack
text.TextColor3 = Color3.fromRGB(255, 220, 90)
text.TextStrokeTransparency = 0.2
text.Text = "PRACTICE ARENA - nothing counts here"
text.Parent = gui

local dummies = Instance.new("Folder")
dummies.Name = "PracticeDummies"
dummies.Parent = Workspace

------------------------------------------------------------
-- Dummies
------------------------------------------------------------
local function clearDummies()
	dummies:ClearAllChildren()
end

local function spawnDummy(kindName)
	local kind = KINDS[kindName]
	if not kind then return end
	if #dummies:GetChildren() >= MAX_DUMMIES then
		dummies:GetChildren()[1]:Destroy() -- remove the oldest
	end

	local dummy = template:Clone()
	dummy.Name = "Dummy" .. kindName
	local hum = dummy:WaitForChild("Humanoid")
	local root = dummy:WaitForChild("HumanoidRootPart")
	for _, p in ipairs(dummy:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = kind.color end
		if p:IsA("BodyColors") then
			p.HeadColor3, p.TorsoColor3, p.LeftArmColor3 = kind.color, kind.color, kind.color
			p.RightArmColor3, p.LeftLegColor3, p.RightLegColor3 = kind.color, kind.color, kind.color
		end
	end
	dummy:ScaleTo(kind.scale)
	hum.DisplayName = "Dummy " .. kindName       -- not "BOSS": no boss banner or boss music for a dummy
	hum.MaxHealth, hum.Health = DUMMY_HEALTH, DUMMY_HEALTH
	hum.WalkSpeed = 0

	local x = math.random(-55, 55)
	local z = math.random(-45, 15)
	dummy:PivotTo(CFrame.new(ORIGIN + Vector3.new(x, 4, z)) * CFrame.Angles(0, math.pi, 0)) -- faces the players
	root.Anchored = true
	dummy.Parent = dummies

	-- heal back to full a few seconds after the last hit, so you can keep testing
	local lastHit = 0
	local last = hum.Health
	hum.HealthChanged:Connect(function(h)
		if h < last then lastHit = os.clock() end
		last = h
	end)
	task.spawn(function()
		while dummy.Parent and hum.Health > 0 do
			if hum.Health < hum.MaxHealth and os.clock() - lastHit > HEAL_AFTER then
				hum.Health = hum.MaxHealth
			end
			task.wait(0.5)
		end
	end)
	hum.Died:Connect(function()
		task.wait(1)
		if dummy.Parent then dummy:Destroy() end
	end)
end

------------------------------------------------------------
-- Entering and leaving
------------------------------------------------------------
local function teleport(player, cf)
	local char = player.Character
	if char then char:PivotTo(cf) end
end

local function enter(player)
	if player:GetAttribute("InPractice") then return end
	if (core:GetAttribute("Health") or 0) > 0 then -- a real round is running: the doorway is closed
		shop:FireClient(player, "Toast", "The Practice Arena is closed while a round is running")
		return
	end
	player:SetAttribute("InPractice", true)              -- WeaponManager gives every weapon
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = hum.MaxHealth end
	teleport(player, CFrame.new(ORIGIN + Vector3.new(math.random(-8, 8), 4, 55)))
	if #dummies:GetChildren() == 0 then
		spawnDummy("Zombie")
	end
end

local function leave(player)
	if not player:GetAttribute("InPractice") then return end
	player:SetAttribute("InPractice", nil)
	local spawn = Workspace:FindFirstChild("PlayerSpawn")
	local pos = spawn and spawn.Position or Vector3.new(0, 5, 40)
	teleport(player, CFrame.new(pos + Vector3.new(0, 5, 0)))
	-- last one out clears the dummies
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("InPractice") then return end
	end
	clearDummies()
end

event.OnServerEvent:Connect(function(player, action, arg)
	if action == "Exit" then
		leave(player)
	elseif action == "Spawn" and player:GetAttribute("InPractice") and type(arg) == "string" then
		spawnDummy(arg)
	elseif action == "Clear" and player:GetAttribute("InPractice") then
		clearDummies()
	end
end)


------------------------------------------------------------
-- The doors you walk through
-- The entrance stands in the real arena a few steps from where you spawn. While a round is running a red
-- barrier fills the doorway (solid, so you cannot walk in) and the server also refuses to let anyone in.
------------------------------------------------------------
local ENTRANCE = Vector3.new(30, 1, 175)           -- real arena (floor top is y = 1)
local EXIT_DOOR = ORIGIN + Vector3.new(0, 1, 70)   -- inside the practice platform

local function makeDoor(center, title, subtitle, color, withBarrier)
	local model = Instance.new("Folder")
	model.Name = "Door_" .. title
	model.Parent = folder

	local function part(size, offset, props)
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.Position = center + offset
		p.Color = color
		p.Material = Enum.Material.Neon
		for k, v in pairs(props or {}) do p[k] = v end
		p.Parent = model
		return p
	end
	part(Vector3.new(3, 14, 3), Vector3.new(-7.5, 7, 0))
	part(Vector3.new(3, 14, 3), Vector3.new(7.5, 7, 0))
	local beam = part(Vector3.new(18, 3, 3), Vector3.new(0, 15.5, 0))
	part(Vector3.new(12, 0.3, 6), Vector3.new(0, 0.15, 0), { CanCollide = false, Transparency = 0.4 }) -- glowing mat

	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(280, 64)
	sign.StudsOffset = Vector3.new(0, 4, 0)
	sign.MaxDistance = 260
	sign.Parent = beam
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.TextScaled = true
	signText.Font = Enum.Font.GothamBlack
	signText.TextColor3 = color
	signText.TextStrokeTransparency = 0.2
	signText.Text = title .. "\n" .. subtitle
	signText.Parent = sign

	-- the thing that sends you through, one step behind the barrier
	local trigger = part(Vector3.new(12, 12, 2), Vector3.new(0, 6, -2.5), { CanCollide = false, Transparency = 1 })

	local barrier, closedSign
	if withBarrier then
		barrier = part(Vector3.new(12, 12, 1), Vector3.new(0, 6, 0), { Color = Color3.fromRGB(235, 50, 50), Transparency = 1, CanCollide = false })
		closedSign = Instance.new("BillboardGui")
		closedSign.Size = UDim2.fromOffset(260, 70)
		closedSign.MaxDistance = 200
		closedSign.Enabled = false
		closedSign.Parent = barrier
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextStrokeTransparency = 0
		t.Text = "CLOSED\nround in progress"
		t.Parent = closedSign
	end
	return trigger, barrier, closedSign
end

local entranceTrigger, barrier, closedSign = makeDoor(ENTRANCE, "PRACTICE ARENA", "walk in to train", Color3.fromRGB(60, 200, 220), true)
local exitTrigger = makeDoor(EXIT_DOOR, "EXIT", "walk out to go back", Color3.fromRGB(255, 170, 50), false)

local function roundRunning()
	return (core:GetAttribute("Health") or 0) > 0
end

local function updateBarrier()
	local closed = roundRunning()
	barrier.CanCollide = closed
	barrier.Transparency = closed and 0.35 or 1
	closedSign.Enabled = closed
end
core:GetAttributeChangedSignal("Health"):Connect(updateBarrier)
updateBarrier()

local touchedAt = {}
local function onTouch(fn)
	return function(hit)
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if not player then return end
		if os.clock() - (touchedAt[player] or 0) < 2 then return end
		touchedAt[player] = os.clock()
		fn(player)
	end
end
entranceTrigger.Touched:Connect(onTouch(enter))
exitTrigger.Touched:Connect(onTouch(leave))
Players.PlayerRemoving:Connect(function(p) touchedAt[p] = nil end)

-- dying / respawning puts you back in the normal game
local function onPlayer(player)
	player.CharacterAdded:Connect(function()
		if player:GetAttribute("InPractice") then
			player:SetAttribute("InPractice", nil)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		for _, p in ipairs(Players:GetPlayers()) do
			if p:GetAttribute("InPractice") then return end
		end
		clearDummies()
	end)
end)
