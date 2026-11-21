-- The list of achievements, shared by the server (Achievements, DataManager) and the client (WelcomeUI).
local list = {
	{ id = "FirstWin", title = "First Victory", desc = "Win a round" },
	{ id = "Wins10", title = "Defender of the Core", desc = "Win 10 rounds" },
	{ id = "BeatImpossible", title = "Impossible!", desc = "Win a round on Impossible" },
	{ id = "Kills100", title = "Zombie Hunter", desc = "Get 100 kills in total" },
	{ id = "Kills1000", title = "Zombie Slayer", desc = "Get 1000 kills in total" },
	{ id = "BossSlayer", title = "Boss Slayer", desc = "Land the last hit on a BOSS" },
	{ id = "Wave20", title = "Veteran", desc = "Reach wave 20 in a round" },
}

local byId = {}
for _, a in ipairs(list) do byId[a.id] = a end

return { list = list, byId = byId }
