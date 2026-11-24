-- Daily challenges: 3 new goals every day (UTC), the same for every player. Progress is saved per player,
-- the coin reward is paid the moment a goal is done (or at the start of the next round if no round is running).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local store = DataStoreService:GetDataStore("CrystalChallenges_v1")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local core = Workspace:WaitForChild("Core")

local event = Instance.new("RemoteEvent")
event.Name = "ChallengeEvent"
event.Parent = ReplicatedStorage

-- kind -> { text, tiers = { {target, reward}, ... } }; progress rules are in the handlers below
local KINDS = {
	kills = { text = "Defeat %d enemies", tiers = { { 40, 50 }, { 70, 90 }, { 110, 140 } } },
	wave = { text = "Reach wave %d in one round", tiers = { { 5, 60 }, { 8, 100 }, { 12, 160 } } },
	endwave = { text = "Reach wave %d in an Endless run", tiers = { { 4, 70 }, { 7, 110 }, { 10, 160 } } },
	win = { text = "Win a round", tiers = { { 1, 150 } } },
}
local ORDER = { "kills", "wave", "endwave", "win" }

local function today()
	return math.floor(os.time() / 86400) + (Workspace:GetAttribute("DebugDayOffset") or 0)
end

-- the day's three challenges, identical on every server
local function challengesFor(day)
	local rng = Random.new(day * 7919 + 13)
	local pool = table.clone(ORDER)
	local list = {}
	for _ = 1, 3 do
		local kind = table.remove(pool, rng:NextInteger(1, #pool))
		local tiers = KINDS[kind].tiers
		local t = tiers[rng:NextInteger(1, #tiers)]
		table.insert(list, { kind = kind, target = t[1], reward = t[2], text = KINDS[kind].text:format(t[1]) })
	end
	return list
end

local sessions = {} -- [player] = { data, loaded, memoryOnly, list, dirty, saveDirty }

local function roundRunning()
	return (core:GetAttribute("Health") or 0) > 0
end
local function toast(player, text)
	shop:FireClient(player, "Toast", text)
end
local function giveCoins(player, amount)
	local stats = player:FindFirstChild("PlayerData")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then coins.Value += amount end
end

local function fresh(day)
	return { day = day, prog = { 0, 0, 0 }, done = { false, false, false }, bank = 0 }
end

local function validate(saved, day)
	local d = fresh(day)
	if type(saved) == "table" then
		if type(saved.bank) == "number" then d.bank = saved.bank end
		if saved.day == day and type(saved.prog) == "table" and type(saved.done) == "table" then
			for i = 1, 3 do
				d.prog[i] = tonumber(saved.prog[i]) or 0
				d.done[i] = saved.done[i] == true
			end
		end
	end
	return d
end

local function save(player)
	local s = sessions[player]
	if not s or not s.loaded or s.memoryOnly then return end
	s.saveDirty = false
	local ok, err = pcall(function() store:SetAsync("c_" .. player.UserId, s.data) end)
	if not ok then warn("Challenges: save failed for " .. player.Name .. ": " .. tostring(err)) end
end

local function send(player)
	local s = sessions[player]
	if not s or not s.ready then return end
	s.dirty = false
	local rows = {}
	for i, c in ipairs(s.list) do
		rows[i] = { text = c.text, target = c.target, reward = c.reward, progress = math.min(s.data.prog[i], c.target), done = s.data.done[i] }
	end
	event:FireClient(player, "State", rows)
end

-- make sure the saved day matches today (a long session can cross midnight)
local function rollDay(player, s)
	local day = today()
	if s.data.day ~= day then
		s.data = validate({ bank = s.data.bank }, day)
		s.list = challengesFor(day)
		s.dirty, s.saveDirty = true, true
	end
end

local function progress(player, kind, amount, absolute)
	local s = sessions[player]
	if not s or not s.ready then return end
	rollDay(player, s)
	for i, c in ipairs(s.list) do
		if c.kind == kind and not s.data.done[i] then
			local v = absolute and math.max(s.data.prog[i], amount) or (s.data.prog[i] + amount)
			if v ~= s.data.prog[i] then
				s.data.prog[i] = v
				s.dirty, s.saveDirty = true, true
			end
			if v >= c.target then
				s.data.done[i] = true
				if roundRunning() then
					giveCoins(player, c.reward)
					toast(player, ("Daily challenge done: +%d coins!"):format(c.reward))
				else
					s.data.bank += c.reward
					toast(player, ("Daily challenge done: +%d coins at the start of your next round!"):format(c.reward))
				end
				save(player)
			end
		end
	end
end

local function setup(player)
	local s = { data = fresh(today()), loaded = false, ready = false, list = challengesFor(today()) }
	sessions[player] = s
	local saved, ok = nil, false
	for attempt = 1, 3 do
		local got, result = pcall(function() return store:GetAsync("c_" .. player.UserId) end)
		if got then saved, ok = result, true break end
		if RunService:IsStudio() then break end -- Studio blocks DataStores: play in memory only
		task.wait(1.5 * attempt)
	end
	if not player.Parent then return end
	s.memoryOnly = (not ok) and RunService:IsStudio()
	s.loaded = ok or s.memoryOnly
	s.data = validate(saved, today())
	s.list = challengesFor(s.data.day)
	s.ready = true

	local board = player:WaitForChild("leaderstats", 15)
	local kills = board and board:WaitForChild("Kills", 5)
	local wins = board and board:WaitForChild("Wins", 5)
	if kills then
		local last = kills.Value
		kills.Changed:Connect(function(v)
			if v > last then progress(player, "kills", v - last) end
			last = v
		end)
	end
	if wins then
		local last = wins.Value
		wins.Changed:Connect(function(v)
			if v > last then progress(player, "win", v - last) end
			last = v
		end)
	end
	send(player)
end

event.OnServerEvent:Connect(function(player, action)
	if action == "Request" then send(player) end
end)

-- the wave number is published by WaveManager
Workspace:GetAttributeChangedSignal("Wave"):Connect(function()
	local w = Workspace:GetAttribute("Wave") or 0
	if w <= 0 then return end
	local endless = Workspace:GetAttribute("Endless") == true
	for _, player in ipairs(Players:GetPlayers()) do
		progress(player, endless and "endwave" or "wave", w, true)
	end
end)

-- banked reward coins are paid when a round starts (core health goes from 0 to full)
local prevHealth = core:GetAttribute("Health") or 0
core:GetAttributeChangedSignal("Health"):Connect(function()
	local h = core:GetAttribute("Health") or 0
	if prevHealth <= 0 and h > 0 then
		for player, s in pairs(sessions) do
			if s.ready and s.data.bank > 0 then
				local amount = s.data.bank
				s.data.bank = 0
				s.saveDirty = true
				giveCoins(player, amount)
				toast(player, ("+%d bonus coins from daily challenges!"):format(amount))
			end
		end
	end
	prevHealth = h
end)

Players.PlayerAdded:Connect(function(p) task.spawn(setup, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(setup, p) end
Players.PlayerRemoving:Connect(function(p)
	save(p)
	sessions[p] = nil
end)

task.spawn(function()
	local n = 0
	while true do
		task.wait(1)
		n += 1
		for player, s in pairs(sessions) do
			if s.ready and s.data.day ~= today() then rollDay(player, s) end
			if s.dirty then send(player) end
			if n % 60 == 0 and s.saveDirty then save(player) end
		end
	end
end)

game:BindToClose(function()
	for player in pairs(sessions) do save(player) end
end)
