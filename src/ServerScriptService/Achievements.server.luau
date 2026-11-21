-- Detects when a player earns an achievement and tells DataManager (which saves it and shows the pop-up).
-- Needs no Robux and no badges. The list itself is in ReplicatedStorage.AchievementData.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local unlock = ServerStorage:WaitForChild("AchievementUnlock")
local fired = {} -- [player] = { [id] = true }, so each one is only reported once per visit

local function give(player, id)
	fired[player] = fired[player] or {}
	if fired[player][id] then return end
	fired[player][id] = true
	unlock:Fire(player, id)
end

-- everything that can be decided from saved numbers
local function check(player)
	local board = player:FindFirstChild("leaderstats")
	local wins = board and board:FindFirstChild("Wins")
	if wins then
		if wins.Value >= 1 then give(player, "FirstWin") end
		if wins.Value >= 10 then give(player, "Wins10") end
	end
	local kills = player:GetAttribute("TotalKills") or 0
	if kills >= 100 then give(player, "Kills100") end
	if kills >= 1000 then give(player, "Kills1000") end
	if (player:GetAttribute("BestWave") or 0) >= 20 then give(player, "Wave20") end
end

local function track(player)
	local board = player:WaitForChild("leaderstats", 20)
	local wins = board and board:WaitForChild("Wins", 5)
	if wins then
		local last = wins.Value
		wins.Changed:Connect(function(v)
			if v > last and Workspace:GetAttribute("Difficulty") == "Impossible" then
				give(player, "BeatImpossible")
			end
			last = v
			check(player)
		end)
	end
	player:GetAttributeChangedSignal("TotalKills"):Connect(function() check(player) end)
	player:GetAttributeChangedSignal("BestWave"):Connect(function() check(player) end)
	check(player)
end

Players.PlayerAdded:Connect(function(p) task.spawn(track, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(track, p) end
Players.PlayerRemoving:Connect(function(p) fired[p] = nil end)

-- boss kills: the player named in LastAttacker gets it
local enemies = Workspace:WaitForChild("Enemies")
enemies.ChildAdded:Connect(function(enemy)
	local hum = enemy:WaitForChild("Humanoid", 5)
	if not hum or hum.DisplayName ~= "BOSS" then return end
	hum.Died:Connect(function()
		local killerId = hum:GetAttribute("LastAttacker")
		local killer = killerId and Players:GetPlayerByUserId(killerId)
		if killer then give(killer, "BossSlayer") end
	end)
end)
