local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local event = ReplicatedStorage:WaitForChild("CarpetEvent")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SPEED = 60
local MAX_HEIGHT = 180
local MIN_HEIGHT = 4

local camera = Workspace.CurrentCamera
local compact = UserInputService.TouchEnabled or (camera and camera.ViewportSize.X < 1000)

local old = playerGui:FindFirstChild("CarpetUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "CarpetUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(0, 0)
btn.Position = UDim2.new(0, 12, 0, compact and 126 or 404)
btn.Size = UDim2.fromOffset(120, 36)
btn.BackgroundColor3 = Color3.fromRGB(150, 40, 160)
btn.BorderSizePixel = 0
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Text = compact and "CARPET" or "CARPET (C)"
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.Activated:Connect(function()
	event:FireServer("Toggle")
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.C then
		event:FireServer("Toggle")
	end
end)

-- steering uses the same thumbstick / WASD input as walking
local controls
local function getControls()
	if controls then return controls end
	local ok, module = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	end)
	if ok and module then
		controls = module:GetControls()
	end
	return controls
end

local function currentCarpet()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if seat and seat.Name == "MagicCarpet" then
		return seat
	end
end

RunService.Heartbeat:Connect(function()
	local seat = currentCarpet()
	if not seat then return end
	local lv = seat:FindFirstChild("CarpetVelocity")
	local ao = seat:FindFirstChild("CarpetOrientation")
	if not lv or not ao then return end

	local cam = Workspace.CurrentCamera
	local move = player:GetAttribute("CarpetTestMove") -- test hook; nil in normal play
	if typeof(move) ~= "Vector3" then
		local c = getControls()
		move = c and c:GetMoveVector() or Vector3.zero
	end

	-- push toward where the camera points (look up and push forward to climb)
	local target = Vector3.zero
	local flat = Vector3.new(move.X, 0, move.Z)
	if flat.Magnitude > 0.05 then
		target = cam.CFrame:VectorToWorldSpace(flat).Unit * SPEED * math.min(flat.Magnitude, 1)
	end

	-- stay inside the arena and between the ground and the sky limit
	local pos = seat.Position
	if pos.Y > MAX_HEIGHT and target.Y > 0 then target = Vector3.new(target.X, 0, target.Z) end
	if pos.Y < MIN_HEIGHT and target.Y < 0 then target = Vector3.new(target.X, 0, target.Z) end
	local floor = Workspace:FindFirstChild("ArenaFloor")
	if floor then
		local half = floor.Size.X / 2 - 12
		local rel = pos - floor.Position
		if math.abs(rel.X) > half and (target.X * rel.X) > 0 then target = Vector3.new(0, target.Y, target.Z) end
		if math.abs(rel.Z) > half and (target.Z * rel.Z) > 0 then target = Vector3.new(target.X, target.Y, 0) end
	end

	lv.VectorVelocity = lv.VectorVelocity:Lerp(target, 0.15)

	local h = Vector3.new(lv.VectorVelocity.X, 0, lv.VectorVelocity.Z)
	if h.Magnitude > 2 then
		ao.CFrame = CFrame.lookAt(pos, pos + h)
	end
end)
