local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local core = Workspace:WaitForChild("Core")
local enemyTemplate = ServerStorage:WaitForChild("Enemy")
local event = ReplicatedStorage:WaitForChild("DifficultyEvent")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")

local ATTACK_RANGE = 12            -- distance from core center where enemies hit the core
local ATTACK_COOLDOWN = 1
local PLAYER_ATTACK_COOLDOWN = 1.2
local AGGRO_RANGE = 35             -- enemies chase you if you get this close
local FIRST_WAVE_DELAY = 5
local MAX_ENEMIES_PER_WAVE = 40
local BOSS_EVERY = 5
local LOW_CORE_FRACTION = 0.3      -- alarm sounds below this much core health

-- Sound effects (free Creator Store audio)
local SOUNDS = {
	growl = "rbxassetid://2772396665",
	growlFast = "rbxassetid://92357564819100",
	roar = "rbxassetid://127855700916139",
	coreHit = "rbxassetid://9113263647",
	hurt = "rbxassetid://127259476108630",
	coreBreak = "rbxassetid://106283491044010",
	alarm = "rbxassetid://9125933460",
}

local function makeSound(parent, id, volume, maxDistance, looped)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = maxDistance or 100
	s.Looped = looped or false
	s.Parent = parent
	return s
end

-- Difficulty settings (tweak these numbers!)
local DIFFICULTIES = {
	Easy = {
		coreHealth = 300, enemyDamage = 1, playerDamage = 5,
		hpBase = 20, hpPerWave = 6,
		speedBase = 8, speedMax = 14,
		countBase = 2, countPerWave = 1,
		reward = 15, betweenWaves = 12,
		timeLimit = 2100,           -- safety limit (35 min): long enough to clear 30 waves
		goalWaves = 30,           -- clear this many waves to win            -- survive this many seconds to win
	},
	Hard = {
		coreHealth = 150, enemyDamage = 3, playerDamage = 10,
		hpBase = 40, hpPerWave = 12,
		speedBase = 11, speedMax = 18,
		countBase = 4, countPerWave = 2,
		reward = 10, betweenWaves = 8,
		timeLimit = 2400,
		goalWaves = 30,
	},
	Impossible = {
		coreHealth = 60, enemyDamage = 6, playerDamage = 18,
		hpBase = 80, hpPerWave = 25,
		speedBase = 14, speedMax = 22,
		countBase = 6, countPerWave = 3,
		reward = 8, betweenWaves = 5,
		timeLimit = 2400,
		goalWaves = 30,
	},
}

-- Enemy types (multipliers on top of the difficulty numbers)
local ENEMY_TYPES = {
	Zombie = { name = "Zombie", color = Color3.fromRGB(80, 140, 70), scale = 1, hp = 1, speed = 1, dmg = 1, reward = 1, pitch = 1, fast = false },
	Runner = { name = "Runner", color = Color3.fromRGB(235, 140, 40), scale = 0.85, hp = 0.5, speed = 1.6, dmg = 1, reward = 1.3, pitch = 1.1, fast = true },
	Tank = { name = "Tank", color = Color3.fromRGB(120, 50, 50), scale = 1.4, hp = 3, speed = 0.65, dmg = 2, reward = 3, pitch = 0.75, fast = false },
	Exploder = { name = "Exploder", color = Color3.fromRGB(255, 90, 40), scale = 0.9, hp = 0.6, speed = 1.5, dmg = 1, reward = 2, pitch = 1.25, fast = true, exploder = true },
	Spitter = { name = "Spitter", color = Color3.fromRGB(70, 200, 160), scale = 0.95, hp = 0.7, speed = 0.9, dmg = 1, reward = 2.5, pitch = 0.9, fast = false, ranged = true },
	Boss = { name = "BOSS", color = Color3.fromRGB(130, 60, 190), scale = 2.3, hp = 12, speed = 0.7, dmg = 4, reward = 25, pitch = 0.6, fast = false },
}

local function pickType(w)
	local r = math.random()
	if w >= 3 and r < 0.10 then return ENEMY_TYPES.Tank end
	if w >= 4 and r < 0.22 then return ENEMY_TYPES.Exploder end
	if w >= 6 and r < 0.32 then return ENEMY_TYPES.Spitter end
	if w >= 2 and r < 0.55 then return ENEMY_TYPES.Runner end
	return ENEMY_TYPES.Zombie
end

local function pickSpawn()
	local list = {}
	for _, c in ipairs(Workspace:GetChildren()) do
		if c:IsA("BasePart") and c.Name:sub(1, 10) == "SpawnPoint" then
			table.insert(list, c)
		end
	end
	return list[math.random(math.max(1, #list))]
end

local enemyFolder = Instance.new("Folder")
enemyFolder.Name = "Enemies"
enemyFolder.Parent = Workspace

-- Coins
Players.PlayerAdded:Connect(function(player)
	local stats = Instance.new("Folder")
	stats.Name = "PlayerData"
	stats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = stats
	player:SetAttribute("DmgLevel", 0)

	-- the Roblox leaderboard shows kills
	local board = Instance.new("Folder")
	board.Name = "leaderstats"
	board.Parent = player
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Parent = board
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = board
end)

-- Core sounds
local coreHitSound = makeSound(core, SOUNDS.coreHit, 1, 300)
local alarmSound = makeSound(core, SOUNDS.alarm, 0.35, 350, false)
local breakSound = makeSound(core, SOUNDS.coreBreak, 1, 500)

-- Health label above the core
local gui = Instance.new("BillboardGui")
gui.Size = UDim2.fromOffset(260, 50)
gui.StudsOffset = Vector3.new(0, core.Size.Y / 2 + 3, 0)
gui.AlwaysOnTop = true
gui.Parent = core

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0
label.Parent = gui

local waveNum = 0
local alive = 0
local gameOver = false
local won = false
local selectedDiff = nil
local diff = nil
local roundId = 0
local endless = false      -- Endless mode: no wave goal, the chosen time is the run
local endlessMinutes = 0
local timeBonus = 0   -- extra seconds added by the admin panel
local adminBind = ServerStorage:WaitForChild("AdminCommand")

local function updateLabel()
	if endless then
		label.Text = ("Core HP: %d | Wave %d | Endless%s"):format(
			core:GetAttribute("Health") or 0, waveNum, selectedDiff and (" | " .. selectedDiff) or "")
		return
	end
	label.Text = ("Core HP: %d | Wave %d/%d%s"):format(
		core:GetAttribute("Health") or 0,
		waveNum,
		diff and diff.goalWaves or 0,
		selectedDiff and (" | " .. selectedDiff) or ""
	)
end

local alarmOn = false
task.spawn(function()
	while true do
		if alarmOn and not gameOver and selectedDiff then
			alarmSound:Play()
		end
		task.wait(1.2)
	end
end)

local function updateAlarm()
	local hp = core:GetAttribute("Health") or 0
	local maxHp = core:GetAttribute("MaxHealth") or 1
	local low = selectedDiff ~= nil and not gameOver and hp > 0 and hp <= maxHp * LOW_CORE_FRACTION
	alarmOn = low
end

core:GetAttributeChangedSignal("Health"):Connect(function()
	if selectedDiff and not gameOver then
		updateLabel()
	end
	updateAlarm()
end)

local function damageCore(amount)
	local hp = math.max((core:GetAttribute("Health") or 0) - amount, 0)
	core:SetAttribute("Health", hp)
	coreHitSound.PlaybackSpeed = 0.9 + math.random() * 0.25
	coreHitSound:Play()
	updateLabel()
	if hp <= 0 and not gameOver then
		gameOver = true
		won = false
		alarmSound:Stop()
		breakSound:Play()
	end
end

local function toast(text)
	shop:FireAllClients("Toast", text)
end

-- Skip requests from the shop (skip waves, or the whole run)
local skipNow = false
local skipExtraWaves = 0
local skipBind = ServerStorage:WaitForChild("SkipRequest")
skipBind.Event:Connect(function(kind, amount)
	if not selectedDiff or gameOver or not diff then return end
	if kind == "all" then
		won = true
		gameOver = true
		toast("Skipped the entire " .. selectedDiff .. " run!")
	elseif kind == "waves" then
		skipNow = true
		skipExtraWaves += math.max(0, (amount or 1) - 1)
	end
end)

-- Difficulty menu communication
event.OnServerEvent:Connect(function(player, action, arg1, arg2)
	if action == "Ready" then
		if not selectedDiff then
			event:FireClient(player, "ShowMenu")
		end
	elseif type(action) == "string" and DIFFICULTIES[action] and not selectedDiff then
		selectedDiff = action
		Workspace:SetAttribute("Difficulty", action) -- read by Achievements
		event:FireAllClients("Hide", action)
	elseif action == "Endless" and not selectedDiff and DIFFICULTIES[tostring(arg1)] and tonumber(arg2) then
		-- Endless: a difficulty plus a time you choose, 1 to 60 minutes
		endless = true
		endlessMinutes = math.clamp(math.floor(tonumber(arg2)), 1, 60)
		selectedDiff = tostring(arg1)
		Workspace:SetAttribute("Difficulty", selectedDiff)
		Workspace:SetAttribute("Endless", true) -- read by ShopManager (no skips)
		event:FireAllClients("Hide", selectedDiff)
	end
end)

local function nearestPlayer(pos)
	local bestPlayer, bestDist, bestHum, bestRoot
	for _, pl in ipairs(Players:GetPlayers()) do
		local ch = pl.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 then
			local d = (hrp.Position - pos).Magnitude
			if not bestDist or d < bestDist then
				bestPlayer, bestDist, bestHum, bestRoot = pl, d, hum, hrp
			end
		end
	end
	return bestPlayer, bestDist, bestHum, bestRoot
end

local RANGED_RANGE = 32      -- spitters stop this far from their target and shoot
local RANGED_COOLDOWN = 3

-- Spitter: a green blob flies to where you were standing, then does its damage if you are still there
local function spit(fromRoot, targetPos, onHit)
	local blob = Instance.new("Part")
	blob.Shape = Enum.PartType.Ball
	blob.Size = Vector3.new(1.6, 1.6, 1.6)
	blob.Color = Color3.fromRGB(120, 255, 90)
	blob.Material = Enum.Material.Neon
	blob.Anchored, blob.CanCollide, blob.CanQuery, blob.CanTouch = true, false, false, false
	blob.Position = fromRoot.Position + Vector3.new(0, 2, 0)
	blob.Parent = Workspace
	local tween = TweenService:Create(blob, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Position = targetPos + Vector3.new(0, 2, 0) })
	tween.Completed:Connect(function()
		blob:Destroy()
		if not gameOver then onHit() end
	end)
	tween:Play()
end

-- Exploder: blows up next to you or the core, then is gone (no coins for a suicide)
local function explode(root, humanoid, radius, playerDmg, coreDmg)
	local pos = root.Position
	local fx = Instance.new("Explosion")
	fx.Position = pos
	fx.BlastRadius = radius
	fx.BlastPressure = 0
	fx.DestroyJointRadiusPercent = 0
	fx.Parent = Workspace
	for _, pl in ipairs(Players:GetPlayers()) do
		local ch = pl.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 and (hrp.Position - pos).Magnitude <= radius then
			hum:TakeDamage(playerDmg)
		end
	end
	if (pos - core.Position).Magnitude <= radius + 8 then
		damageCore(coreDmg)
	end
	humanoid:SetAttribute("NoReward", true)
	humanoid.Health = 0
end

local function spawnEnemy(kind)
	local spawnPoint = pickSpawn()
	if not spawnPoint then return end

	local enemy = enemyTemplate:Clone()
	enemy.Name = "ZombieEnemy"

	local humanoid = enemy:WaitForChild("Humanoid")
	local root = enemy:WaitForChild("HumanoidRootPart")

	-- look
	local bc = enemy:FindFirstChildOfClass("BodyColors")
	if bc then
		bc.HeadColor3 = kind.color
		bc.TorsoColor3 = kind.color
		bc.LeftArmColor3 = kind.color
		bc.RightArmColor3 = kind.color
		bc.LeftLegColor3 = kind.color
		bc.RightLegColor3 = kind.color
	end
	for _, p in ipairs(enemy:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Color = kind.color
		end
	end
	enemy:ScaleTo(kind.scale)
	humanoid.DisplayName = kind.name

	-- stats
	local hp = math.max(1, math.floor((diff.hpBase + waveNum * diff.hpPerWave) * kind.hp))
	humanoid.MaxHealth = hp
	humanoid.Health = hp
	humanoid.WalkSpeed = math.min(diff.speedBase + waveNum, diff.speedMax) * kind.speed
	local coreDamage = math.max(1, math.floor(diff.enemyDamage * kind.dmg + 0.5))
	local playerDamage = math.min(40, math.max(1, math.floor(diff.playerDamage * kind.dmg + 0.5)))
	local reward = math.max(1, math.floor(diff.reward * kind.reward))
	local meleeRange = 5 + kind.scale * 1.5

	enemy:PivotTo(spawnPoint.CFrame * CFrame.new(math.random(-8, 8), 4, math.random(-8, 8)))
	enemy.Parent = enemyFolder
	alive += 1

	-- sounds: growling as they come for the core
	local growl = makeSound(root, kind.fast and SOUNDS.growlFast or SOUNDS.growl, 0.55, 120)
	growl.PlaybackSpeed = kind.pitch
	if kind == ENEMY_TYPES.Boss then
		makeSound(root, SOUNDS.roar, 0.8, 450):Play()
	end

	humanoid.Died:Connect(function()
		alive -= 1
		-- no coins if the enemy fell out of the world
		if root.Position.Y < -20 then
			enemy:Destroy()
			return
		end
		local killerId = humanoid:GetAttribute("LastAttacker")
		if killerId then
			local killer = Players:GetPlayerByUserId(killerId)
			local board = killer and killer:FindFirstChild("leaderstats")
			local kills = board and board:FindFirstChild("Kills")
			if kills then kills.Value += 1 end
		end
		for _, player in Players:GetPlayers() do
			local stats = player:FindFirstChild("PlayerData")
			local coins = stats and stats:FindFirstChild("Coins")
			if coins and not humanoid:GetAttribute("NoReward") then
				coins.Value += reward * ((player:GetAttribute("DoubleUntil") or 0) > Workspace:GetServerTimeNow() and 2 or 1)
			end
		end
		task.wait(2)
		enemy:Destroy()
	end)

	-- Enemy brain: chase you if you are close, otherwise walk to the core and hit it
	task.spawn(function()
		local lastCoreAttack = 0
		local lastPlayerAttack = 0
		local lastRanged = 0
		local nextGrowl = os.clock() + 1 + math.random() * 2
		while humanoid.Health > 0 and enemy.Parent and not gameOver do
			local now = os.clock()
			if now >= nextGrowl then
				growl:Play()
				nextGrowl = now + 3 + math.random() * 3
			end

			local pl, pd, phum, proot = nearestPlayer(root.Position)
			if pl and pd <= AGGRO_RANGE then
				if kind.ranged and pd <= RANGED_RANGE then
					humanoid:MoveTo(root.Position)
					if now - lastRanged >= RANGED_COOLDOWN then
						lastRanged = now
						local aim = proot.Position
						spit(root, aim, function()
							if phum.Health > 0 and (proot.Position - aim).Magnitude < 7 then
								phum:TakeDamage(playerDamage) -- you can dodge it by moving
							end
						end)
					end
				elseif pd <= meleeRange then
					if kind.exploder then
						explode(root, humanoid, 12, playerDamage * 2, coreDamage * 3)
						break
					end
					if now - lastPlayerAttack >= PLAYER_ATTACK_COOLDOWN then
						lastPlayerAttack = now
						phum:TakeDamage(playerDamage)
						local hurt = makeSound(proot, SOUNDS.hurt, 0.9, 80)
						hurt:Play()
						Debris:AddItem(hurt, 1.5)
					end
				else
					humanoid:MoveTo(proot.Position)
				end
			else
				local distance = (root.Position - core.Position).Magnitude
				if kind.ranged and distance <= RANGED_RANGE then
					humanoid:MoveTo(root.Position)
					if now - lastRanged >= RANGED_COOLDOWN then
						lastRanged = now
						spit(root, core.Position, function() damageCore(coreDamage) end)
					end
				elseif distance <= ATTACK_RANGE + kind.scale * 2 then
					if kind.exploder then
						explode(root, humanoid, 12, playerDamage * 2, coreDamage * 3)
						break
					end
					if now - lastCoreAttack >= ATTACK_COOLDOWN then
						lastCoreAttack = now
						damageCore(coreDamage)
					end
				else
					humanoid:MoveTo(core.Position)
				end
			end
			task.wait(0.25)
		end
	end)
end

-- Admin panel commands
adminBind.Event:Connect(function(cmd, arg)
	if not diff or not selectedDiff or gameOver then return end
	if cmd == "spawn" and ENEMY_TYPES[arg] then
		spawnEnemy(ENEMY_TYPES[arg])
	elseif cmd == "addTime" then
		timeBonus += tonumber(arg) or 60
	elseif cmd == "endRound" then
		won = false
		gameOver = true
	end
end)

local function resetAmmo(player)
	local function fix(container)
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("IsGun") then
					t:SetAttribute("Ammo", t:GetAttribute("MagSize") or 12)
					t:SetAttribute("Reserve", t:GetAttribute("StartReserve") or 36)
					t:SetAttribute("Reloading", false)
				end
			end
		end
	end
	fix(player.Character)
	fix(player:FindFirstChild("Backpack"))
end

local function waitUnlessOver(seconds)
	local t = 0
	while t < seconds and not gameOver and not skipNow do
		task.wait(1)
		t += 1
	end
end

-- Countdown: survive until it hits zero to win
local function startTimer(limit, id)
	task.spawn(function()
		timeBonus = 0
		local endsAt = os.clock() + limit
		while roundId == id and not gameOver do
			local left = math.max(0, math.ceil(endsAt + timeBonus - os.clock()))
			Workspace:SetAttribute("TimeLeft", left)
			if left <= 0 then
				won = true
				gameOver = true
				break
			end
			task.wait(0.5)
		end
	end)
end

-- Main game loop
while true do
	roundId += 1
	selectedDiff = nil
	endless = false
	Workspace:SetAttribute("Endless", nil)
	diff = nil
	gameOver = false
	won = false
	skipNow = false
	skipExtraWaves = 0
	waveNum = 0
	alive = 0
	Workspace:SetAttribute("TimeLeft", -1)
	alarmSound:Stop()
	enemyFolder:ClearAllChildren()
	core:SetAttribute("Health", 0)
	label.Text = "Choose a difficulty!"

	-- fresh start: remove turrets, reset upgrades, coins and ammo
	local turrets = Workspace:FindFirstChild("Turrets")
	if turrets then turrets:ClearAllChildren() end
	for _, pl in Players:GetPlayers() do
		pl:SetAttribute("DmgLevel", 0)
		local st = pl:FindFirstChild("PlayerData")
		local c = st and st:FindFirstChild("Coins")
		if c then c.Value = 0 end
		local board = pl:FindFirstChild("leaderstats")
		local k = board and board:FindFirstChild("Kills")
		if k then k.Value = 0 end
		resetAmmo(pl)
	end
	ServerStorage:WaitForChild("WeaponReset"):Fire()

	event:FireAllClients("ShowMenu")

	while not selectedDiff do
		task.wait(0.25)
	end

	diff = DIFFICULTIES[selectedDiff]
	if endless then
		diff = table.clone(diff)
		diff.goalWaves = math.huge
		diff.timeLimit = endlessMinutes * 60
	end
	core:SetAttribute("MaxHealth", diff.coreHealth)
	core:SetAttribute("Health", diff.coreHealth)
	waveNum = (Workspace:GetAttribute("DebugStartWave") or 1) - 1
	updateLabel()
	if endless then
		toast("ENDLESS " .. selectedDiff .. " - survive " .. endlessMinutes .. " min. How many waves can you clear?")
	else
		toast(selectedDiff .. " mode - reach wave " .. diff.goalWaves .. " within " .. math.floor(diff.timeLimit / 60) .. " minutes!")
	end
	startTimer(Workspace:GetAttribute("DebugTimeLimit") or diff.timeLimit, roundId)
	waitUnlessOver(FIRST_WAVE_DELAY)

	while not gameOver do
		waveNum += 1
		updateLabel()
		local isBossWave = waveNum % BOSS_EVERY == 0
		toast(isBossWave and ("WAVE " .. waveNum .. " - BOSS INCOMING!") or ("Wave " .. waveNum))
		print(selectedDiff, "- wave", waveNum, "starting")

		local count = math.min(diff.countBase + waveNum * diff.countPerWave, MAX_ENEMIES_PER_WAVE)
		for _ = 1, count do
			if gameOver or skipNow then break end
			spawnEnemy(pickType(waveNum))
			task.wait(1)
		end
		if isBossWave and not gameOver and not skipNow then
			spawnEnemy(ENEMY_TYPES.Boss)
		end

		while alive > 0 and not gameOver and not skipNow do
			task.wait(0.5)
		end

		if skipNow and not gameOver then
			-- a skip was bought: clear the field and jump ahead
			skipNow = false
			enemyFolder:ClearAllChildren()
			alive = 0
			waveNum += skipExtraWaves
			skipExtraWaves = 0
			if waveNum >= diff.goalWaves then
				waveNum = diff.goalWaves
				won = true
				gameOver = true
			else
				toast("Skipped ahead! Next up: wave " .. (waveNum + 1))
			end
		elseif not gameOver then
			toast("Wave " .. waveNum .. " cleared!")
			if waveNum >= diff.goalWaves then
				won = true
				gameOver = true
			else
				waitUnlessOver(diff.betweenWaves)
			end
		end
	end

	-- round over
	local reached = (won and not endless) and waveNum or math.max(0, waveNum - 1)
	for _, pl in Players:GetPlayers() do
		if endless then
			-- Endless has its own saved record (and its own world leaderboard); it never touches BestWave or Wins
			if reached > (pl:GetAttribute("EndlessBest") or 0) then
				pl:SetAttribute("EndlessMinutes", endlessMinutes)
				pl:SetAttribute("EndlessBest", reached)
			end
		elseif reached > (pl:GetAttribute("BestWave") or 0) then
			pl:SetAttribute("BestWave", reached) -- saved by DataManager
		end
	end
	enemyFolder:ClearAllChildren()
	alarmSound:Stop()
	core:SetAttribute("Health", 0) -- closes the shop until the next round starts
	Workspace:SetAttribute("TimeLeft", -1)
	if endless then
		label.Text = ("ENDLESS over (%s, %d min) - you cleared %d waves"):format(selectedDiff, endlessMinutes, reached)
		toast((won and "TIME'S UP! " or "GAME OVER - ") .. "you cleared " .. reached .. " waves in Endless")
	elseif won then
		label.Text = ("VICTORY! You survived %d waves"):format(waveNum)
		toast("VICTORY! The Crystal Core is safe!")
		for _, pl in Players:GetPlayers() do
			local board = pl:FindFirstChild("leaderstats")
			local w = board and board:FindFirstChild("Wins")
			if w then w.Value += 1 end
		end
	else
		label.Text = ("GAME OVER (%s) - you survived %d waves"):format(selectedDiff, math.max(0, waveNum - 1))
		toast("GAME OVER - you survived " .. math.max(0, waveNum - 1) .. " waves")
	end
	task.wait(8)
end
