-- Background music: a calm track in the menu, an upbeat one during a round, and a punchier one while a
-- BOSS is alive. Tracks cross-fade. Free Creator Store audio (publisher: DistrokidOfficial).
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local VOLUME = 0.22 -- kept low so the fight sounds stay clear

local TRACKS = {
	menu = { id = 140195397978848, name = "Moonlit Meadow Whisper" },
	round = { id = 83665515258345, name = "Cyberpunk Gamer" },
	boss = { id = 131724560853622, name = "Bash Encounter" },
}

local sounds = {}
for key, t in pairs(TRACKS) do
	local s = Instance.new("Sound")
	s.Name = "Music_" .. key
	s.SoundId = "rbxassetid://" .. t.id
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	sounds[key] = s
end

local current
local function play(key)
	if current == key then return end
	current = key
	for k, s in pairs(sounds) do
		if k == key then
			if not s.IsPlaying then s:Play() end
			TweenService:Create(s, TweenInfo.new(1.5), { Volume = VOLUME }):Play()
		else
			local tw = TweenService:Create(s, TweenInfo.new(1.5), { Volume = 0 })
			tw:Play()
			tw.Completed:Connect(function()
				if current ~= k and s.Volume <= 0.01 then s:Pause() end
			end)
		end
	end
end

local function bossAlive()
	local enemies = Workspace:FindFirstChild("Enemies")
	if not enemies then return false end
	for _, e in ipairs(enemies:GetChildren()) do
		local hum = e:FindFirstChildOfClass("Humanoid")
		if hum and hum.DisplayName == "BOSS" and hum.Health > 0 then return true end
	end
	return false
end

-- decide every half second which track fits (TimeLeft is -1 while the menu is open)
while true do
	local inRound = (Workspace:GetAttribute("TimeLeft") or -1) >= 0
	if not inRound then
		play("menu")
	elseif bossAlive() then
		play("boss")
	else
		play("round")
	end
	task.wait(0.5)
end
