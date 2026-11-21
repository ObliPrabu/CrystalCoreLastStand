local WeaponData = {}

WeaponData.MAX_LEVEL = 5
WeaponData.LEVEL_BONUS = 0.2   -- +20% damage per upgrade level (per weapon)

-- kind = "melee" or "gun". price 0 = everyone starts with it.
-- stats are copied onto the Tool as attributes and read by the shared weapon scripts.
WeaponData.list = {
	-- MELEE
	{ id = "Sword", name = "Sword", kind = "melee", price = 0, damage = 25, desc = "Balanced starter blade",
	  stats = { Cooldown = 0.65, Windup = 0.16, Slash = 0.18, Recover = 0.22, StartZ = -55, StartX = -35, EndZ = 85, EndX = 60, HitX = 8, HitY = 6, HitZ = 7 } },
	{ id = "Katana", name = "Katana", kind = "melee", price = 350, damage = 18, desc = "Lightning-fast slashes",
	  stats = { Cooldown = 0.38, Windup = 0.07, Slash = 0.10, Recover = 0.12, StartZ = -50, StartX = -25, EndZ = 80, EndX = 50, HitX = 6, HitY = 6, HitZ = 7 } },
	{ id = "Axe", name = "Battle Axe", kind = "melee", price = 500, damage = 45, desc = "Heavy hits with a wide swing",
	  stats = { Cooldown = 0.95, Windup = 0.22, Slash = 0.24, Recover = 0.30, StartZ = -65, StartX = -40, EndZ = 90, EndX = 65, HitX = 10, HitY = 6, HitZ = 8 } },
	{ id = "Hammer", name = "War Hammer", kind = "melee", price = 900, damage = 90, desc = "Crushing overhead slam",
	  stats = { Cooldown = 1.40, Windup = 0.30, Slash = 0.20, Recover = 0.40, StartZ = 0, StartX = -75, EndZ = 0, EndX = 75, HitX = 11, HitY = 7, HitZ = 9 } },

	-- GUNS
	{ id = "Blaster", name = "Blaster", kind = "gun", price = 0, damage = 20, desc = "Reliable starter gun",
	  stats = { MagSize = 12, StartReserve = 36, MaxReserve = 120, CrateAmmo = 24, FireRate = 0.25, ReloadTime = 1.4, Range = 250, Pellets = 1, Spread = 0, Recoil = 14 } },
	{ id = "Rapid", name = "Rapid Blaster", kind = "gun", price = 400, damage = 8, desc = "Sprays bullets, very fast",
	  stats = { MagSize = 30, StartReserve = 90, MaxReserve = 300, CrateAmmo = 60, FireRate = 0.09, ReloadTime = 1.8, Range = 220, Pellets = 1, Spread = 1.5, Recoil = 6 } },
	{ id = "Scatter", name = "Scatter Gun", kind = "gun", price = 600, damage = 11, desc = "6 pellets, deadly up close",
	  stats = { MagSize = 6, StartReserve = 24, MaxReserve = 72, CrateAmmo = 12, FireRate = 0.80, ReloadTime = 2.2, Range = 80, Pellets = 6, Spread = 7, Recoil = 22 } },
	{ id = "Longshot", name = "Longshot", kind = "gun", price = 900, damage = 80, desc = "One huge shot, huge range",
	  stats = { MagSize = 4, StartReserve = 12, MaxReserve = 36, CrateAmmo = 8, FireRate = 1.00, ReloadTime = 2.5, Range = 600, Pellets = 1, Spread = 0, Recoil = 18 } },
}

WeaponData.byId = {}
for _, w in ipairs(WeaponData.list) do
	WeaponData.byId[w.id] = w
end

-- starter weapons cost 80 coins per level; bought weapons cost 35% of their price per level
function WeaponData.upgradeCost(w, level)
	local base = w.price > 0 and w.price * 0.35 or 80
	return math.floor(base * (level + 1))
end

function WeaponData.damageAt(w, level)
	return math.floor(w.damage * (1 + WeaponData.LEVEL_BONUS * level) + 0.5)
end

WeaponData.MAX_MAG_LEVEL = 5
WeaponData.MAG_BONUS = 0.25   -- +25% of the base magazine per level

function WeaponData.magSizeAt(w, level)
	return math.floor(w.stats.MagSize * (1 + WeaponData.MAG_BONUS * level) + 0.5)
end

-- starter guns cost 60 coins per level; bought guns cost 25% of their price per level
function WeaponData.magCost(w, level)
	local base = w.price > 0 and w.price * 0.25 or 60
	return math.floor(base * (level + 1))
end

return WeaponData
