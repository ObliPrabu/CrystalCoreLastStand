-- Saves progress between visits (Wins, lifetime kills, best wave, daily-reward streak, tutorial flag, hats)
-- and runs the daily reward. Coins and weapons are NOT saved: they are wiped every round by design.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local store = DataStoreService:GetDataStore("CrystalCoreSave_v1")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local core = Workspace:WaitForChild("Core")
local AchievementData = require(ReplicatedStorage:WaitForChild("AchievementData"))

-- Achievements fires this with (player, id); we save it and show the pop-up
local unlockEvent = Instance.new("BindableEvent")
unlockEvent.Name = "AchievementUnlock"
unlockEvent.Parent = ServerStorage

local daily = Instance.new("RemoteEvent")
daily.Name = "DailyEvent"
daily.Parent = ReplicatedStorage

-- Coins given on day 1..7 of the streak (then it starts over). They are added at the start of your next
-- round (or right away if a round is already running).
local REWARDS = { 50, 100, 150, 200, 300, 400, 750 }

local function today()
	-- test hook: Workspace attribute DebugDayOffset pretends it is N days later
	return math.floor(os.time() / 86400) + (Workspace:GetAttribute("DebugDayOffset") or 0)
end

local DEFAULT = { wins = 0, kills = 0, bestWave = 0, streak = 0, lastDay = 0, bonus = 0, tutorialDone = false, achievements = {}, endlessBest = 0, endlessMinutes = 0, hats = "", hat = "", supporter = false }

local sessions = {} -- [player] = { data = {...}, loaded = bool }

local function roundRunning()
	return (core:GetAttribute("Health") or 0) > 0
end

local function toast(player, text)
	shop:FireClient(player, "Toast", text)
end

local function copyDefaults(saved)
	local d = table.clone(DEFAULT)
	if type(saved) == "table" then
		for k, default in pairs(DEFAULT) do
			if type(saved[k]) == type(default) then d[k] = saved[k] end
		end
	end
	if type(d.achievements) ~= "table" or d.achievements == DEFAULT.achievements then d.achievements = {} end
	return d
end

local function load(player)
	for attempt = 1, 4 do
		local ok, result = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok then return true, copyDefaults(result) end
		warn("DataManager: load failed for " .. player.Name .. " (try " .. attempt .. "): " .. tostring(result))
		if RunService:IsStudio() then return false, copyDefaults(nil) end -- Studio blocks DataStores by default: do not wait
		task.wait(1.5 * attempt)
	end
	return false, copyDefaults(nil)
end

local function syncFromGame(player, s)
	local board = player:FindFirstChild("leaderstats")
	local wins = board and board:FindFirstChild("Wins")
	if wins then s.data.wins = wins.Value end
	s.data.bestWave = math.max(s.data.bestWave, player:GetAttribute("BestWave") or 0)
	local eb = player:GetAttribute("EndlessBest") or 0
	if eb > s.data.endlessBest then
		s.data.endlessBest = eb
		s.data.endlessMinutes = player:GetAttribute("EndlessMinutes") or s.data.endlessMinutes
	end
	-- hats (bought and worn through the Hats script, which keeps them in these attributes)
	if player:GetAttribute("DataLoaded") then
		s.data.hats = player:GetAttribute("OwnedHats") or s.data.hats
		s.data.hat = player:GetAttribute("EquippedHat") or s.data.hat
		if player:GetAttribute("Supporter") then s.data.supporter = true end
	end
end

local function save(player)
	local s = sessions[player]
	if not s or not s.loaded or s.memoryOnly then return end -- never overwrite good data when the load failed
	syncFromGame(player, s)
	local ok, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, s.data)
	end)
	if not ok then warn("DataManager: save failed for " .. player.Name .. ": " .. tostring(err)) end
end

local function canClaim(s)
	return s.data.lastDay ~= today()
end

-- which day of the 7-day row is being offered now (or was claimed today)
local function dayIndex(s)
	local streak = s.data.streak
	if canClaim(s) then
		streak = (s.data.lastDay == today() - 1) and (streak + 1) or 1
	end
	return ((math.max(streak, 1) - 1) % #REWARDS) + 1
end

local function sendState(player)
	local s = sessions[player]
	if not s then return end
	syncFromGame(player, s)
	daily:FireClient(player, "State", {
		canClaim = canClaim(s),
		day = dayIndex(s),
		rewards = REWARDS,
		streak = (canClaim(s) and s.data.lastDay ~= today() - 1) and 0 or s.data.streak,
		tutorialDone = s.data.tutorialDone,
		bestWave = s.data.bestWave,
		wins = s.data.wins,
		kills = s.data.kills,
		achievements = s.data.achievements,
		loaded = s.loaded,
	})
end

local function giveCoins(player, amount)
	local stats = player:FindFirstChild("PlayerData")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then coins.Value += amount end
end

local function setup(player)
	local s = { data = copyDefaults(nil), loaded = false, ready = false }
	sessions[player] = s

	local ok, data = load(player)
	if not player.Parent then return end
	-- In Studio (API access off) the game runs in memory only so the screens can be tested.
	-- In the live game a failed load stays "not loaded" and nothing is saved or claimed.
	s.memoryOnly = (not ok) and RunService:IsStudio()
	s.data, s.loaded, s.ready = data, ok or s.memoryOnly, true
	if not ok and not s.memoryOnly then
		toast(player, "Could not load your saved progress - playing without saving")
	end

	local board = player:WaitForChild("leaderstats", 15)
	local wins = board and board:WaitForChild("Wins", 5)
	local kills = board and board:WaitForChild("Kills", 5)
	if wins then wins.Value = s.data.wins end
	player:SetAttribute("BestWave", s.data.bestWave)
	player:SetAttribute("EndlessBest", s.data.endlessBest)
	player:SetAttribute("EndlessMinutes", s.data.endlessMinutes)
	player:SetAttribute("OwnedHats", s.data.hats)
	player:SetAttribute("EquippedHat", s.data.hat)
	if s.data.supporter then player:SetAttribute("Supporter", true) end
	player:GetAttributeChangedSignal("Supporter"):Connect(function() -- a donation: save at once
		if player:GetAttribute("DataLoaded") then save(player) end
	end)
	player:GetAttributeChangedSignal("OwnedHats"):Connect(function() -- a new hat: save at once
		if player:GetAttribute("DataLoaded") then save(player) end
	end)
	if board then
		-- a third leaderboard column with your saved best wave
		local bestVal = Instance.new("IntValue")
		bestVal.Name = "Best Wave"
		bestVal.Value = s.data.bestWave
		bestVal.Parent = board
		player:GetAttributeChangedSignal("BestWave"):Connect(function()
			bestVal.Value = player:GetAttribute("BestWave") or bestVal.Value
		end)
	end
	if kills then
		local last = kills.Value
		player:SetAttribute("TotalKills", s.data.kills) -- read by Badges
		kills.Changed:Connect(function(v)
			if v > last then
				s.data.kills += v - last
				player:SetAttribute("TotalKills", s.data.kills)
			end
			last = v
		end)
	end
	player:SetAttribute("DataLoaded", true)
	sendState(player)
end

daily.OnServerEvent:Connect(function(player, action)
	local s = sessions[player]
	if not s or not s.ready then return end -- the client asks again via the state we send after loading
	if not s.loaded and action == "Claim" then return end
	if action == "Request" then
		sendState(player)
	elseif action == "TutorialDone" then
		s.data.tutorialDone = true
		save(player)
	elseif action == "Claim" then
		if not canClaim(s) then return end
		local idx = dayIndex(s)
		local reward = REWARDS[idx]
		s.data.streak = (s.data.lastDay == today() - 1) and (s.data.streak + 1) or 1
		s.data.lastDay = today()
		if roundRunning() then
			giveCoins(player, reward)
			toast(player, ("Daily reward: +%d coins!"):format(reward))
		else
			s.data.bonus += reward
			toast(player, ("Daily reward: +%d coins at the start of your next round!"):format(reward))
		end
		save(player)
		sendState(player)
		daily:FireClient(player, "Claimed", reward)
	end
end)

-- banked daily coins are paid out when a round starts (the core goes from 0 health to full)
local prevHealth = core:GetAttribute("Health") or 0
core:GetAttributeChangedSignal("Health"):Connect(function()
	local h = core:GetAttribute("Health") or 0
	if prevHealth <= 0 and h > 0 then
		for player, s in pairs(sessions) do
			if s.data.bonus > 0 then
				local amount = s.data.bonus
				s.data.bonus = 0
				giveCoins(player, amount)
				toast(player, ("+%d bonus coins from your daily reward!"):format(amount))
			end
		end
	end
	prevHealth = h
end)

unlockEvent.Event:Connect(function(player, id)
	local s = sessions[player]
	if not s or not s.ready or not AchievementData.byId[id] or s.data.achievements[id] then return end
	s.data.achievements[id] = true
	daily:FireClient(player, "Achievement", id)
	sendState(player)
	save(player)
end)

Players.PlayerAdded:Connect(function(player) task.spawn(setup, player) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(setup, p) end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	sessions[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(90)
		for player in pairs(sessions) do save(player) end
	end
end)

game:BindToClose(function()
	for player in pairs(sessions) do save(player) end
end)
