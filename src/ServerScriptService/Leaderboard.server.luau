-- World leaderboard: the best Endless runs of everyone who has ever played, shown on a board near the spawn.
-- Stored in an OrderedDataStore: score = waves * 1000 + (61 - minutes), so more waves wins and, on equal
-- waves, the shorter time limit wins. In Studio (DataStore API access off) it falls back to memory only.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TOP = 10
local REFRESH = 60

local ordered = DataStoreService:GetOrderedDataStore("EndlessBoard_v1")
local memory = {} -- [userId] = score; used when the DataStore is unavailable (Studio)
local useMemory = false

local function encode(waves, minutes)
	return waves * 1000 + (61 - math.clamp(minutes, 1, 60))
end
local function decode(score)
	return math.floor(score / 1000), 61 - (score % 1000)
end

local function submit(userId, score)
	if not useMemory then
		local ok, err = pcall(function()
			ordered:UpdateAsync(tostring(userId), function(old)
				if old and old >= score then return nil end -- keep the better run
				return score
			end)
		end)
		if ok then return end
		if not RunService:IsStudio() then
			warn("Leaderboard: submit failed: " .. tostring(err))
			return
		end
		useMemory = true
	end
	if (memory[userId] or 0) < score then memory[userId] = score end
end

local function fetchTop()
	if not useMemory then
		local ok, pages = pcall(function() return ordered:GetSortedAsync(false, TOP) end)
		if ok then
			local ok2, items = pcall(function() return pages:GetCurrentPage() end)
			if ok2 then
				local rows = {}
				for _, item in ipairs(items) do
					table.insert(rows, { userId = tonumber(item.key), score = item.value })
				end
				return rows
			end
		end
		if not RunService:IsStudio() then return nil end -- live: keep showing the old board
		useMemory = true
	end
	local rows = {}
	for userId, score in pairs(memory) do table.insert(rows, { userId = userId, score = score }) end
	table.sort(rows, function(a, b) return a.score > b.score end)
	while #rows > TOP do table.remove(rows) end
	return rows
end

local names = {}
local function nameOf(userId)
	if names[userId] then return names[userId] end
	local p = Players:GetPlayerByUserId(userId)
	if p then names[userId] = p.Name return p.Name end
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	if ok then names[userId] = name return name end
	return "Player " .. userId
end

------------------------------------------------------------
-- the physical board (at the end of the spawn, facing the player)
------------------------------------------------------------
local board = Instance.new("Part")
board.Name = "WorldLeaderboard"
board.Anchored = true
board.Size = Vector3.new(24, 16, 1)
board.Position = Vector3.new(64, 9.5, 170)
board.Color = Color3.fromRGB(20, 22, 34)
board.Material = Enum.Material.SmoothPlastic
board.Parent = Workspace

for _, x in ipairs({ -10, 10 }) do -- two posts
	local post = Instance.new("Part")
	post.Name = "BoardPost"
	post.Anchored = true
	post.Size = Vector3.new(1.2, 3, 1)
	post.Position = Vector3.new(64 + x, 2.5, 170)
	post.Color = Color3.fromRGB(70, 70, 85)
	post.Material = Enum.Material.Metal
	post.Parent = board
end

local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Back -- the +Z side, toward the spawn
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
gui.CanvasSize = Vector2.new(800, 560) -- scales with the board
gui.LightInfluence = 0
gui.Parent = board

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 90)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 54
title.TextColor3 = Color3.fromRGB(255, 205, 70)
title.Text = "WORLD ENDLESS TOP 10"
title.Parent = gui

local sub = Instance.new("TextLabel")
sub.Position = UDim2.fromOffset(0, 80)
sub.Size = UDim2.new(1, 0, 0, 36)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 26
sub.TextColor3 = Color3.fromRGB(170, 175, 195)
sub.Text = "waves cleared in Endless mode"
sub.Parent = gui

local rowLabels = {}
local COLORS = { Color3.fromRGB(255, 215, 70), Color3.fromRGB(215, 220, 230), Color3.fromRGB(215, 150, 90) }
for i = 1, TOP do
	local l = Instance.new("TextLabel")
	l.Position = UDim2.fromOffset(30, 124 + (i - 1) * 42)
	l.Size = UDim2.new(1, -60, 0, 40)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.GothamBold
	l.TextSize = 32
	l.TextColor3 = COLORS[i] or Color3.new(1, 1, 1)
	l.Text = ""
	l.Parent = gui
	rowLabels[i] = l
end

local function refresh()
	local rows = fetchTop()
	if not rows then return end
	for i = 1, TOP do
		local r = rows[i]
		if r then
			local waves, minutes = decode(r.score)
			rowLabels[i].Text = ("%d.  %s  -  %d waves (%d min)"):format(i, nameOf(r.userId), waves, minutes)
		else
			rowLabels[i].Text = i == 1 and "Be the first! Play Endless mode" or ""
		end
	end
end

------------------------------------------------------------
-- submit runs
------------------------------------------------------------
local function trySubmit(player)
	local waves = player:GetAttribute("EndlessBest") or 0
	if waves <= 0 or not player:GetAttribute("DataLoaded") then return end
	local score = encode(waves, player:GetAttribute("EndlessMinutes") or 60)
	if player:GetAttribute("BoardScore") == score then return end
	player:SetAttribute("BoardScore", score)
	submit(player.UserId, score)
	task.delay(1, refresh)
end

local function onPlayer(player)
	player:GetAttributeChangedSignal("EndlessBest"):Connect(function() trySubmit(player) end)
	player:GetAttributeChangedSignal("DataLoaded"):Connect(function() trySubmit(player) end)
	trySubmit(player)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do onPlayer(p) end

task.spawn(function()
	while true do
		refresh()
		task.wait(REFRESH)
	end
end)
