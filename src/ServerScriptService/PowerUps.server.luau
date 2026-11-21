-- Power-ups: enemies sometimes drop a glowing orb. Walk into it to pick it up.
--   SPEED   - run 40% faster for 12 seconds
--   SHIELD  - a force field blocks damage for 8 seconds
--   x2 COINS - kills give double coins for 20 seconds
--   REPAIR  - the Core heals 15% of its health
--   x2 DAMAGE (red) - your guns and melee weapons do double damage for 15 seconds; a second one while it
--     is still active doubles again (x4 is the maximum)
-- Bosses always drop one. Orbs disappear after 20 seconds and when a round ends.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local enemies = Workspace:WaitForChild("Enemies")
local core = Workspace:WaitForChild("Core")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")

local DROP_CHANCE = 0.08
local ORB_LIFETIME = 20
local FLOOR_TOP = 1

local folder = Instance.new("Folder")
folder.Name = "PowerUps"
folder.Parent = Workspace

local KINDS = {
	{ id = "Speed", text = "SPEED", color = Color3.fromRGB(80, 200, 255) },
	{ id = "Shield", text = "SHIELD", color = Color3.fromRGB(255, 225, 90) },
	{ id = "Double", text = "x2 COINS", color = Color3.fromRGB(255, 170, 40) },
	{ id = "Repair", text = "REPAIR", color = Color3.fromRGB(90, 255, 130) },
	{ id = "Damage", text = "x2 DAMAGE", color = Color3.fromRGB(255, 60, 60) },
}

local function toast(player, text)
	shop:FireClient(player, "Toast", text)
end

local function apply(player, kind)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if kind.id == "Speed" then
		if not hum or hum.Health <= 0 then return false end
		local token = (hum:GetAttribute("SpeedToken") or 0) + 1
		hum:SetAttribute("SpeedToken", token)
		if not hum:GetAttribute("BaseSpeed") then hum:SetAttribute("BaseSpeed", hum.WalkSpeed) end
		hum.WalkSpeed = hum:GetAttribute("BaseSpeed") * 1.4
		task.delay(12, function()
			if hum.Parent and hum:GetAttribute("SpeedToken") == token then
				hum.WalkSpeed = hum:GetAttribute("BaseSpeed") or 16
				hum:SetAttribute("BaseSpeed", nil)
			end
		end)
		toast(player, "SPEED boost! (12 seconds)")
	elseif kind.id == "Shield" then
		if not char or not hum or hum.Health <= 0 then return false end
		local ff = Instance.new("ForceField")
		ff.Parent = char
		Debris:AddItem(ff, 8)
		toast(player, "SHIELD! You cannot be hurt for 8 seconds")
	elseif kind.id == "Double" then
		player:SetAttribute("DoubleUntil", Workspace:GetServerTimeNow() + 20) -- read by WaveManager
		toast(player, "DOUBLE COINS for 20 seconds!")
	elseif kind.id == "Damage" then
		local boost = math.min(4, (player:GetAttribute("DamageBoost") or 1) * 2) -- read by GunServer / MeleeServer
		player:SetAttribute("DamageBoost", boost)
		local token = (player:GetAttribute("DamageToken") or 0) + 1
		player:SetAttribute("DamageToken", token)
		task.delay(15, function()
			if player.Parent and player:GetAttribute("DamageToken") == token then
				player:SetAttribute("DamageBoost", nil)
			end
		end)
		toast(player, boost >= 4 and "DAMAGE x4! (15 seconds, the maximum)" or "DOUBLE DAMAGE! (15 seconds)")
	elseif kind.id == "Repair" then
		local maxHp = core:GetAttribute("MaxHealth") or 0
		local hp = core:GetAttribute("Health") or 0
		if hp <= 0 or maxHp <= 0 then return false end
		core:SetAttribute("Health", math.min(maxHp, hp + math.ceil(maxHp * 0.15)))
		toast(player, "The Core was repaired!")
	end
	return true
end

local function drop(position, kind)
	local orb = Instance.new("Part")
	orb.Name = "PowerUp"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(2.6, 2.6, 2.6)
	orb.Anchored = true
	orb.CanCollide = false
	orb.Color = kind.color
	orb.Material = Enum.Material.Neon
	orb.Position = Vector3.new(position.X, FLOOR_TOP + 2.5, position.Z)
	orb.Parent = folder

	local light = Instance.new("PointLight")
	light.Color = kind.color
	light.Range = 16
	light.Brightness = 2
	light.Parent = orb

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 28)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 150
	gui.Parent = orb
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = kind.color
	text.TextStrokeTransparency = 0.3
	text.Text = kind.text
	text.Parent = gui

	local taken = false
	orb.Touched:Connect(function(hit)
		if taken then return end
		local model = hit:FindFirstAncestorOfClass("Model")
		local player = model and Players:GetPlayerFromCharacter(model)
		if not player then return end
		if apply(player, kind) then
			taken = true
			orb:Destroy()
		end
	end)
	Debris:AddItem(orb, ORB_LIFETIME)
end

local function watch(enemy)
	local hum = enemy:WaitForChild("Humanoid", 5)
	local root = enemy:WaitForChild("HumanoidRootPart", 5)
	if not hum or not root then return end
	hum.Died:Connect(function()
		if hum:GetAttribute("NoReward") or root.Position.Y < -20 then return end
		if hum.DisplayName == "BOSS" or math.random() < DROP_CHANCE then
			drop(root.Position, KINDS[math.random(#KINDS)])
		end
	end)
end

enemies.ChildAdded:Connect(function(e) task.spawn(watch, e) end)

-- round over: clear leftover orbs
core:GetAttributeChangedSignal("Health"):Connect(function()
	if (core:GetAttribute("Health") or 0) <= 0 then folder:ClearAllChildren() end
end)
