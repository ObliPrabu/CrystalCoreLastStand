-- Cosmetic hats, bought once with round coins and owned forever (saved by DataManager).
-- Each hat is a few parts. Sizes and positions are for a 2-stud-wide head and are scaled to the real head.
-- pos is the part's centre relative to the top-centre of the head (-Z is the front). shape: "block" (default) or
-- "cyl" (an upright cylinder, size = height, width, width).
local HatData = {}

local function v(x, y, z) return Vector3.new(x, y, z) end
local function c(r, g, b) return Color3.fromRGB(r, g, b) end

HatData.list = {
	{ id = "Cap", name = "Red Cap", price = 100, desc = "A sporty cap",
	  parts = {
		{ size = v(2.1, 0.6, 1.2), pos = v(0, 0.25, 0), color = c(205, 45, 45) },
		{ size = v(1.4, 0.12, 0.9), pos = v(0, 0.05, -0.95), color = c(150, 30, 30) },
	  } },
	{ id = "Party", name = "Party Hat", price = 150, desc = "Every round is a party",
	  parts = {
		{ size = v(1.3, 0.4, 1.3), pos = v(0, 0.2, 0), color = c(255, 90, 170) },
		{ size = v(0.95, 0.4, 0.95), pos = v(0, 0.6, 0), color = c(90, 200, 255) },
		{ size = v(0.6, 0.4, 0.6), pos = v(0, 1.0, 0), color = c(255, 225, 80) },
		{ size = v(0.3, 0.3, 0.3), pos = v(0, 1.35, 0), color = c(255, 255, 255), material = Enum.Material.Neon },
	  } },
	{ id = "Cat", name = "Cat Ears", price = 200, desc = "Purr-fect",
	  parts = {
		{ size = v(0.5, 0.6, 0.35), pos = v(-0.6, 0.3, 0), color = c(60, 60, 70) },
		{ size = v(0.5, 0.6, 0.35), pos = v(0.6, 0.3, 0), color = c(60, 60, 70) },
		{ size = v(0.28, 0.35, 0.37), pos = v(-0.6, 0.22, 0), color = c(255, 150, 190) },
		{ size = v(0.28, 0.35, 0.37), pos = v(0.6, 0.22, 0), color = c(255, 150, 190) },
	  } },
	{ id = "Top", name = "Top Hat", price = 250, desc = "Very fancy zombie fighter",
	  parts = {
		{ shape = "cyl", size = v(0.15, 2.3, 2.3), pos = v(0, 0.07, 0), color = c(25, 25, 30) },
		{ shape = "cyl", size = v(1.2, 1.5, 1.5), pos = v(0, 0.7, 0), color = c(25, 25, 30) },
		{ shape = "cyl", size = v(0.3, 1.55, 1.55), pos = v(0, 0.35, 0), color = c(190, 40, 50) },
	  } },
	{ id = "Cowboy", name = "Cowboy Hat", price = 300, desc = "Yeehaw!",
	  parts = {
		{ shape = "cyl", size = v(0.12, 3.2, 3.2), pos = v(0, 0.06, 0), color = c(150, 100, 55) },
		{ shape = "cyl", size = v(0.75, 1.7, 1.7), pos = v(0, 0.45, 0), color = c(135, 88, 48) },
		{ shape = "cyl", size = v(0.18, 1.75, 1.75), pos = v(0, 0.2, 0), color = c(70, 45, 25) },
	  } },
	{ id = "Wizard", name = "Wizard Hat", price = 400, desc = "Magic, but mostly looks",
	  parts = {
		{ shape = "cyl", size = v(0.12, 2.8, 2.8), pos = v(0, 0.06, 0), color = c(80, 50, 160) },
		{ size = v(1.5, 0.5, 1.5), pos = v(0, 0.35, 0), color = c(95, 60, 185) },
		{ size = v(1.1, 0.5, 1.1), pos = v(0, 0.85, 0), color = c(95, 60, 185) },
		{ size = v(0.7, 0.5, 0.7), pos = v(0, 1.35, 0), color = c(95, 60, 185) },
		{ size = v(0.35, 0.5, 0.35), pos = v(0, 1.85, 0), color = c(95, 60, 185) },
		{ size = v(0.4, 0.4, 0.4), pos = v(0, 2.25, 0), color = c(255, 225, 80), material = Enum.Material.Neon },
	  } },
	{ id = "Crown", name = "Golden Crown", price = 500, desc = "For the Core's true defender",
	  parts = {
		{ size = v(2.1, 0.5, 1.2), pos = v(0, 0.2, 0), color = c(255, 200, 40), material = Enum.Material.Metal },
		{ size = v(0.4, 0.6, 0.4), pos = v(-0.85, 0.75, -0.4), color = c(255, 200, 40), material = Enum.Material.Metal },
		{ size = v(0.4, 0.6, 0.4), pos = v(0.85, 0.75, -0.4), color = c(255, 200, 40), material = Enum.Material.Metal },
		{ size = v(0.4, 0.6, 0.4), pos = v(-0.85, 0.75, 0.4), color = c(255, 200, 40), material = Enum.Material.Metal },
		{ size = v(0.4, 0.6, 0.4), pos = v(0.85, 0.75, 0.4), color = c(255, 200, 40), material = Enum.Material.Metal },
		{ size = v(0.45, 0.7, 0.4), pos = v(0, 0.8, -0.4), color = c(255, 200, 40), material = Enum.Material.Metal },
		{ size = v(0.3, 0.3, 0.2), pos = v(0, 0.25, -0.62), color = c(255, 60, 90), material = Enum.Material.Neon },
	  } },
	{ id = "Halo", name = "Halo", price = 600, desc = "Floats above your head",
	  parts = {
		{ shape = "cyl", size = v(0.12, 1.9, 1.9), pos = v(0, 1.0, 0), color = c(255, 240, 130), material = Enum.Material.Neon, trans = 0.25 },
	  } },
}

HatData.byId = {}
for _, h in ipairs(HatData.list) do HatData.byId[h.id] = h end

return HatData
