-- Awards badges. Badges have to be created in the Creator Dashboard (creating one can cost Robux); paste each
-- badge's id below. An id of 0 means "not created yet" and that badge is simply skipped.
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")
local Workspace = game:GetService("Workspace")

local BADGES = {
	FirstWin = 0,        -- win your first round
	BeatImpossible = 0,  -- win a round on Impossible
	Kills100 = 0,        -- 100 kills in total (saved)
	BossSlayer = 0,      -- land the killing blow on a BOSS
	Wave20 = 0,          -- reach wave 20 in a round (saved best wave)
}

local awarded = {} -- [userId .. key] = true, so a badge is only requested once per visit

local function award(player, key)
	local id = BADGES[key]
	if not id or id == 0 or not player.Parent then return end
	local mark = player.UserId .. key
	if awarded[mark] then return end
	awarded[mark] = true
	task.spawn(function()
		local ok, err = pcall(function()
			if not BadgeService:UserHasBadgeAsync(player.UserId, id) then
				BadgeService:AwardBadge(player.UserId, id)
			end
		end)
		if not ok then warn("Badges: could not award " .. key .. ": " .. tostring(err)) end
	end)
end

local function track(player)
	local board = player:WaitForChild("leaderstats", 20)
	local wins = board and board:WaitForChild("Wins", 5)
	if wins then
		local last = wins.Value
		wins.Changed:Connect(function(v)
			if v > last then
				award(player, "FirstWin")
				if Workspace:GetAttribute("Difficulty") == "Impossible" then award(player, "BeatImpossible") end
			end
			last = v
		end)
	end
	player:GetAttributeChangedSignal("TotalKills"):Connect(function()
		if (player:GetAttribute("TotalKills") or 0) >= 100 then award(player, "Kills100") end
	end)
	player:GetAttributeChangedSignal("BestWave"):Connect(function()
		if (player:GetAttribute("BestWave") or 0) >= 20 then award(player, "Wave20") end
	end)
end

Players.PlayerAdded:Connect(function(p) task.spawn(track, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(track, p) end

-- boss kills: the player named in LastAttacker gets the badge
local enemies = Workspace:WaitForChild("Enemies")
enemies.ChildAdded:Connect(function(enemy)
	local hum = enemy:WaitForChild("Humanoid", 5)
	if not hum or hum.DisplayName ~= "BOSS" then return end
	hum.Died:Connect(function()
		local killerId = hum:GetAttribute("LastAttacker")
		local killer = killerId and Players:GetPlayerByUserId(killerId)
		if killer then award(killer, "BossSlayer") end
	end)
end)
