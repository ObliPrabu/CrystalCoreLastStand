local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local core = Workspace:WaitForChild("Core")

local RESPAWN_SECONDS = 25
local FLOOR_TOP = 1

local folder = Workspace:FindFirstChild("AmmoCrates")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "AmmoCrates"
	folder.Parent = Workspace
end

-- three rings of crates around the core: near, middle and far
local rings = {
	{ radius = 70, count = 6, offset = 20 },
	{ radius = 160, count = 8, offset = 10 },
	{ radius = 260, count = 8, offset = 30 },
}

local function makeCrate(position)
	local crate = Instance.new("Part")
	crate.Name = "AmmoCrate"
	crate.Anchored = true
	crate.CanCollide = false
	crate.Size = Vector3.new(3, 2.2, 2.2)
	crate.Position = position + Vector3.new(0, FLOOR_TOP + 1.1, 0)
	crate.Color = Color3.fromRGB(70, 230, 110)
	crate.Material = Enum.Material.Neon
	crate:SetAttribute("Ready", true)
	crate.Parent = folder

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(70, 230, 110)
	light.Range = 14
	light.Brightness = 2
	light.Parent = crate

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(110, 30)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 140
	gui.Parent = crate
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.fromRGB(190, 255, 200)
	text.TextStrokeTransparency = 0.3
	text.Text = "AMMO"
	text.Parent = gui

	local function setActive(active)
		crate:SetAttribute("Ready", active)
		crate.Transparency = active and 0 or 1
		light.Enabled = active
		gui.Enabled = active
	end

	crate.Touched:Connect(function(hit)
		if not crate:GetAttribute("Ready") then return end
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if not player then return end

		-- refill every gun the player owns, each by its own crate amount
		local filled = 0
		local backpack = player:FindFirstChildOfClass("Backpack")
		for _, container in ipairs({ model, backpack }) do
			if container then
				for _, t in ipairs(container:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("IsGun") then
						local reserve = t:GetAttribute("Reserve") or 0
						local maxReserve = t:GetAttribute("MaxReserve") or 120
						if reserve < maxReserve then
							t:SetAttribute("Reserve", math.min(maxReserve, reserve + (t:GetAttribute("CrateAmmo") or 24)))
							filled += 1
						end
					end
				end
			end
		end
		if filled == 0 then return end
		shop:FireClient(player, "Toast", "+ammo")
		setActive(false)
		task.delay(RESPAWN_SECONDS, function()
			setActive(true)
		end)
	end)
end

for _, ring in ipairs(rings) do
	for i = 0, ring.count - 1 do
		local angle = math.rad(ring.offset + i * 360 / ring.count)
		local pos = core.Position + Vector3.new(math.cos(angle) * ring.radius, 0, math.sin(angle) * ring.radius)
		makeCrate(Vector3.new(pos.X, 0, pos.Z))
	end
end
