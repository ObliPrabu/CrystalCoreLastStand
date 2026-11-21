-- Map themes: every new round picks a different look (lighting, fog colour and the arena floor).
-- Gameplay is identical in every theme. Test hook: Workspace attribute DebugTheme = "Frozen" / "Ember" / "Night".
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local core = Workspace:WaitForChild("Core")
local floor = Workspace:WaitForChild("ArenaFloor")
local shop = ReplicatedStorage:WaitForChild("ShopEvent")
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- the look the game already has is the "Night" theme
local THEMES = {
	Night = {
		label = "Night Fields",
		clock = Lighting.ClockTime, ambient = Lighting.Ambient, outdoor = Lighting.OutdoorAmbient,
		floorColor = floor.Color, floorMaterial = floor.Material,
		atmo = atmosphere and atmosphere.Color,
	},
	Frozen = {
		label = "Frozen Fields",
		clock = 21, ambient = rgb(120, 150, 190), outdoor = rgb(130, 160, 205),
		floorColor = rgb(215, 232, 248), floorMaterial = Enum.Material.Snow,
		atmo = rgb(185, 215, 245),
	},
	Ember = {
		label = "Ember Dusk",
		clock = 18, ambient = rgb(120, 72, 56), outdoor = rgb(150, 85, 62),
		floorColor = rgb(112, 70, 55), floorMaterial = Enum.Material.Ground,
		atmo = rgb(255, 165, 115),
	},
}
local ORDER = { "Night", "Frozen", "Ember" }

local current = "Night"
local function apply(name)
	local t = THEMES[name]
	if not t then return end
	current = name
	Lighting.ClockTime = t.clock
	Lighting.Ambient = t.ambient
	Lighting.OutdoorAmbient = t.outdoor
	floor.Color = t.floorColor
	floor.Material = t.floorMaterial
	if atmosphere and t.atmo then atmosphere.Color = t.atmo end
end

local prev = core:GetAttribute("Health") or 0
core:GetAttributeChangedSignal("Health"):Connect(function()
	local h = core:GetAttribute("Health") or 0
	if prev <= 0 and h > 0 then -- a round just started
		local forced = Workspace:GetAttribute("DebugTheme")
		local pick = forced
		if not pick then
			repeat pick = ORDER[math.random(#ORDER)] until pick ~= current
		end
		apply(pick)
		task.delay(3.2, function() shop:FireAllClients("Toast", "Map: " .. THEMES[pick].label) end) -- after the difficulty toast
	end
	prev = h
end)
