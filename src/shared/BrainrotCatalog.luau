-- BrainrotCatalog: the one shared list of every brainrot in BRAINROT BAZAAR.
-- Each entry has a name, a rarity tier, a price, a cash-per-second income and a "look"
-- (primitive parts the server's BrainrotBuilder turns into a 3D creature with a face).
-- Server and client both read this module, so prices and labels can never disagree.

local Catalog = {}

export type Look = { [number]: { any } }
export type Brainrot = {
	id: string,
	name: string,
	rarity: string,
	price: number,
	income: number,
	quip: string,
	height: number,
	parts: Look,
	face: { y: number, z: number, gap: number, size: number, mouth: string },
	legs: { h: number, spread: number, color: Color3, shoe: Color3 }?,
}

local rgb = Color3.fromRGB

-- The rarity ladder, lowest to highest. weight = how often the conveyor rolls the tier.
Catalog.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
Catalog.Rarities = {
	Common = { rank = 1, weight = 46, color = rgb(196, 204, 214), beam = false },
	Rare = { rank = 2, weight = 28, color = rgb(64, 162, 255), beam = false },
	Epic = { rank = 3, weight = 15, color = rgb(184, 92, 255), beam = true },
	Legendary = { rank = 4, weight = 8, color = rgb(255, 198, 40), beam = true },
	Mythic = { rank = 5, weight = 3, color = rgb(255, 64, 120), beam = true },
}

-- Mutations multiply income (and price). Rolled when a brainrot drops onto the conveyor.
Catalog.Mutations = {
	{ id = "Golden", mult = 2, chance = 0.10, color = rgb(255, 204, 48) },
	{ id = "Radioactive", mult = 3, chance = 0.06, color = rgb(120, 255, 60) },
	{ id = "Rainbow", mult = 5, chance = 0.03, color = rgb(255, 110, 220) },
}

Catalog.MaxLevel = 5
Catalog.StartingCash = 60
Catalog.StartingPads = 3
Catalog.PadPrices = { 0, 0, 0, 300, 1500, 8000, 40000, 200000 } -- price of pad n
Catalog.RebirthBaseCost = 50000
Catalog.LockSeconds = 10
Catalog.LockCooldown = 30

-- part row = { shape, size, position, color, material?, rotationDegrees?, transparency? }
-- shapes: "Ball" (ellipsoid), "Block", "Cyl" (upright cylinder: size = diameter, height, diameter), "Wedge"
-- positions are studs from the creature's feet; the creature faces -Z.
local V = Vector3.new
local Neon = Enum.Material.Neon
local Foil = Enum.Material.Foil
local Glass = Enum.Material.Glass

Catalog.List = {
	-- COMMON -----------------------------------------------------------------------------------
	{
		id = "noodlino",
		name = "Noodlino Wigglini",
		rarity = "Common",
		price = 25,
		income = 1,
		quip = "Al dente and it knows it.",
		height = 5.4,
		parts = {
			{ "Ball", V(3.6, 1.3, 3.6), V(0, 0.65, 0), rgb(250, 214, 96) },
			{ "Ball", V(3.0, 1.3, 3.0), V(0.2, 1.6, 0), rgb(246, 204, 84) },
			{ "Ball", V(2.4, 1.3, 2.4), V(-0.1, 2.5, 0), rgb(250, 214, 96) },
			{ "Ball", V(2.5, 2.5, 2.5), V(0, 4.0, 0), rgb(150, 72, 48) },
			{ "Ball", V(1.0, 0.3, 0.6), V(0.3, 5.3, 0), rgb(70, 190, 80) },
			{ "Cyl", V(0.35, 1.6, 0.35), V(1.9, 1.6, 0), rgb(250, 214, 96), nil, V(0, 0, -50) },
			{ "Cyl", V(0.35, 1.6, 0.35), V(-1.9, 1.6, 0), rgb(250, 214, 96), nil, V(0, 0, 50) },
		},
		face = { y = 4.1, z = -1.2, gap = 0.5, size = 0.7, mouth = "smile" },
	},
	{
		id = "toasty",
		name = "Toasty Loafer",
		rarity = "Common",
		price = 100,
		income = 3,
		quip = "Slightly burnt. Emotionally too.",
		height = 5.6,
		parts = {
			{ "Block", V(3.6, 3.8, 0.9), V(0, 3.2, 0.1), rgb(150, 92, 44) },
			{ "Block", V(3.0, 3.2, 1.0), V(0, 3.2, -0.05), rgb(244, 208, 140) },
			{ "Ball", V(1.6, 1.0, 1.0), V(-0.9, 5.2, 0), rgb(150, 92, 44) },
			{ "Ball", V(1.6, 1.0, 1.0), V(0.9, 5.2, 0), rgb(150, 92, 44) },
			{ "Block", V(1.1, 0.35, 0.5), V(0.6, 4.3, -0.6), rgb(255, 232, 90), nil, V(0, 0, 14) },
		},
		face = { y = 3.3, z = -0.6, gap = 0.6, size = 0.75, mouth = "o" },
		legs = { h = 1.3, spread = 0.8, color = rgb(244, 208, 140), shoe = rgb(230, 60, 60) },
	},
	{
		id = "sockpuppeto",
		name = "Sockpuppeto Stinko",
		rarity = "Common",
		price = 250,
		income = 6,
		quip = "Lost its twin in the dryer. Still looking.",
		height = 5.6,
		parts = {
			{ "Block", V(2.0, 3.6, 2.0), V(0, 3.0, 0.4), rgb(240, 240, 235) },
			{ "Block", V(2.0, 1.6, 3.6), V(0, 0.8, -0.4), rgb(240, 240, 235) },
			{ "Ball", V(2.1, 1.7, 1.6), V(0, 0.8, -2.1), rgb(226, 62, 70) },
			{ "Block", V(2.15, 0.5, 2.15), V(0, 4.3, 0.4), rgb(226, 62, 70) },
			{ "Block", V(2.15, 0.3, 2.15), V(0, 3.6, 0.4), rgb(60, 120, 220) },
			{ "Ball", V(0.9, 0.9, 0.9), V(1.7, 4.6, 0), rgb(150, 220, 70), Neon, nil, 0.45 },
			{ "Ball", V(0.6, 0.6, 0.6), V(-1.6, 5.2, 0.3), rgb(150, 220, 70), Neon, nil, 0.45 },
		},
		face = { y = 3.0, z = -0.6, gap = 0.5, size = 0.7, mouth = "teeth" },
	},
	-- RARE -------------------------------------------------------------------------------------
	{
		id = "cactopus",
		name = "Cactopus Pricklini",
		rarity = "Rare",
		price = 800,
		income = 15,
		quip = "Eight hugs. Zero survivors.",
		height = 6.0,
		parts = {
			{ "Ball", V(3.4, 3.8, 3.4), V(0, 3.6, 0), rgb(70, 176, 86) },
			{ "Cyl", V(0.9, 2.6, 0.9), V(1.5, 1.2, 1.0), rgb(60, 156, 76), nil, V(20, 0, -24) },
			{ "Cyl", V(0.9, 2.6, 0.9), V(-1.5, 1.2, 1.0), rgb(60, 156, 76), nil, V(20, 0, 24) },
			{ "Cyl", V(0.9, 2.6, 0.9), V(1.5, 1.2, -1.0), rgb(60, 156, 76), nil, V(-20, 0, -24) },
			{ "Cyl", V(0.9, 2.6, 0.9), V(-1.5, 1.2, -1.0), rgb(60, 156, 76), nil, V(-20, 0, 24) },
			{ "Ball", V(1.3, 0.7, 1.3), V(0, 5.6, 0), rgb(255, 120, 190) },
			{ "Ball", V(0.6, 0.6, 0.6), V(0, 5.9, 0), rgb(255, 222, 80) },
			{ "Cyl", V(0.8, 1.5, 0.8), V(2.1, 4.0, 0), rgb(70, 176, 86), nil, V(0, 0, -30) },
			{ "Cyl", V(0.8, 1.5, 0.8), V(-2.1, 4.0, 0), rgb(70, 176, 86), nil, V(0, 0, 30) },
		},
		face = { y = 3.8, z = -1.65, gap = 0.6, size = 0.8, mouth = "smile" },
	},
	{
		id = "conehead",
		name = "Conehead Honko",
		rarity = "Rare",
		price = 2000,
		income = 30,
		quip = "Directs traffic. Into walls.",
		height = 6.2,
		parts = {
			{ "Block", V(4.0, 0.5, 4.0), V(0, 1.3, 0), rgb(255, 120, 30) },
			{ "Cyl", V(3.2, 1.5, 3.2), V(0, 2.2, 0), rgb(255, 120, 30) },
			{ "Cyl", V(2.5, 1.2, 2.5), V(0, 3.5, 0), rgb(245, 245, 245) },
			{ "Cyl", V(1.8, 1.2, 1.8), V(0, 4.7, 0), rgb(255, 120, 30) },
			{ "Cyl", V(1.0, 0.9, 1.0), V(0, 5.7, 0), rgb(255, 120, 30) },
			{ "Wedge", V(1.2, 0.6, 1.5), V(0, 3.1, -1.9), rgb(255, 205, 60), nil, V(0, 180, 0) },
		},
		face = { y = 3.7, z = -1.2, gap = 0.5, size = 0.7, mouth = "none" },
		legs = { h = 1.1, spread = 0.9, color = rgb(255, 170, 50), shoe = rgb(255, 170, 50) },
	},
	{
		id = "bananaphone",
		name = "Bananaphone Ringo",
		rarity = "Rare",
		price = 4500,
		income = 55,
		quip = "Ring ring. It's for you. It's always for you.",
		height = 6.4,
		parts = {
			{ "Block", V(1.7, 2.0, 1.5), V(0.5, 2.1, 0), rgb(255, 222, 60), nil, V(0, 0, 24) },
			{ "Block", V(1.8, 2.0, 1.6), V(0, 3.6, 0), rgb(255, 222, 60) },
			{ "Block", V(1.7, 2.0, 1.5), V(0.5, 5.1, 0), rgb(255, 222, 60), nil, V(0, 0, -24) },
			{ "Block", V(0.8, 0.7, 0.8), V(1.1, 6.1, 0), rgb(110, 76, 40), nil, V(0, 0, -24) },
			{ "Block", V(0.8, 0.6, 0.8), V(1.1, 1.1, 0), rgb(110, 76, 40), nil, V(0, 0, 24) },
			{ "Cyl", V(0.2, 1.6, 0.2), V(-0.7, 5.6, 0), rgb(60, 60, 70) },
			{ "Ball", V(0.5, 0.5, 0.5), V(-0.7, 6.5, 0), rgb(255, 60, 60), Neon },
			{ "Block", V(1.0, 1.2, 0.2), V(0, 2.4, -0.85), rgb(60, 60, 70) },
		},
		face = { y = 4.0, z = -0.85, gap = 0.42, size = 0.6, mouth = "smile" },
		legs = { h = 1.0, spread = 0.6, color = rgb(255, 222, 60), shoe = rgb(70, 110, 230) },
	},
	-- EPIC -------------------------------------------------------------------------------------
	{
		id = "fridgezilla",
		name = "Fridgezilla Chillaroni",
		rarity = "Epic",
		price = 12000,
		income = 120,
		quip = "Ate the city. Kept the leftovers.",
		height = 7.4,
		parts = {
			{ "Block", V(3.4, 5.2, 2.8), V(0, 3.9, 0), rgb(214, 238, 244) },
			{ "Block", V(3.5, 0.2, 2.9), V(0, 4.9, 0), rgb(120, 150, 165) },
			{ "Block", V(0.3, 1.2, 0.4), V(1.2, 5.7, -1.5), rgb(120, 130, 140) },
			{ "Block", V(0.3, 1.8, 0.4), V(1.2, 3.6, -1.5), rgb(120, 130, 140) },
			{ "Wedge", V(1.2, 1.2, 1.2), V(0, 7.0, -0.8), rgb(80, 200, 100) },
			{ "Wedge", V(1.2, 1.4, 1.2), V(0, 7.1, 0.4), rgb(80, 200, 100) },
			{ "Block", V(1.6, 1.4, 2.4), V(0, 2.2, 2.4), rgb(80, 200, 100), nil, V(18, 0, 0) },
			{ "Block", V(1.0, 0.9, 2.0), V(0, 1.5, 4.2), rgb(80, 200, 100), nil, V(24, 0, 0) },
			{ "Block", V(0.7, 0.5, 1.4), V(1.9, 3.8, -0.9), rgb(80, 200, 100) },
			{ "Block", V(0.7, 0.5, 1.4), V(-1.9, 3.8, -0.9), rgb(80, 200, 100) },
		},
		face = { y = 5.9, z = -1.45, gap = 0.6, size = 0.75, mouth = "teeth" },
		legs = { h = 1.3, spread = 1.0, color = rgb(80, 200, 100), shoe = rgb(60, 160, 80) },
	},
	{
		id = "spinnerino",
		name = "Washa Spinnerino",
		rarity = "Epic",
		price = 28000,
		income = 220,
		quip = "Permanently on spin cycle. Send help.",
		height = 6.6,
		parts = {
			{ "Block", V(3.8, 3.8, 3.2), V(0, 3.2, 0), rgb(246, 246, 250) },
			{ "Block", V(3.9, 0.7, 3.3), V(0, 4.9, 0), rgb(90, 200, 230) },
			{ "Cyl", V(2.4, 0.4, 2.4), V(0, 2.9, -1.6), rgb(60, 70, 90), nil, V(90, 0, 0) },
			{ "Cyl", V(1.9, 0.5, 1.9), V(0, 2.9, -1.65), rgb(110, 210, 255), Glass, V(90, 0, 0), 0.25 },
			{ "Ball", V(0.9, 0.9, 0.9), V(-0.8, 5.9, 0.2), rgb(200, 240, 255), Glass, nil, 0.35 },
			{ "Ball", V(1.3, 1.3, 1.3), V(0.5, 6.2, -0.2), rgb(200, 240, 255), Glass, nil, 0.35 },
			{ "Ball", V(0.6, 0.6, 0.6), V(1.5, 5.7, 0.5), rgb(200, 240, 255), Glass, nil, 0.35 },
			{ "Ball", V(0.4, 0.4, 0.4), V(1.4, 4.9, -1.7), rgb(255, 80, 80), Neon },
		},
		face = { y = 4.9, z = -1.7, gap = 0.6, size = 0.7, mouth = "none" },
		legs = { h = 1.3, spread = 1.1, color = rgb(200, 200, 210), shoe = rgb(255, 150, 40) },
	},
	{
		id = "discopigeon",
		name = "Disco Pigeon Groovini",
		rarity = "Epic",
		price = 60000,
		income = 400,
		quip = "Coo-coo. Unts unts unts.",
		height = 6.8,
		parts = {
			{ "Ball", V(3.2, 3.0, 3.6), V(0, 2.7, 0.2), rgb(140, 150, 170) },
			{ "Ball", V(2.5, 2.5, 2.5), V(0, 5.0, -0.5), rgb(220, 226, 240), Foil },
			{ "Wedge", V(0.7, 0.5, 1.2), V(0, 4.7, -2.0), rgb(255, 160, 40), nil, V(0, 180, 0) },
			{ "Block", V(0.5, 2.0, 2.4), V(1.8, 2.9, 0.4), rgb(110, 120, 140), nil, V(0, 0, -18) },
			{ "Block", V(0.5, 2.0, 2.4), V(-1.8, 2.9, 0.4), rgb(110, 120, 140), nil, V(0, 0, 18) },
			{ "Block", V(1.6, 0.4, 2.0), V(0, 2.4, 2.6), rgb(110, 120, 140), nil, V(-25, 0, 0) },
			{ "Ball", V(0.5, 0.5, 0.5), V(1.2, 6.4, -0.3), rgb(255, 70, 200), Neon },
			{ "Ball", V(0.5, 0.5, 0.5), V(-1.2, 6.4, -0.3), rgb(60, 220, 255), Neon },
			{ "Ball", V(0.5, 0.5, 0.5), V(0, 6.7, 0.3), rgb(255, 230, 60), Neon },
		},
		face = { y = 5.3, z = -1.65, gap = 0.55, size = 0.7, mouth = "none" },
		legs = { h = 1.3, spread = 0.7, color = rgb(255, 160, 40), shoe = rgb(255, 160, 40) },
	},
	-- LEGENDARY --------------------------------------------------------------------------------
	{
		id = "kaboomba",
		name = "Llamacano Kaboomba",
		rarity = "Legendary",
		price = 160000,
		income = 900,
		quip = "Spits lava. Apologises never.",
		height = 8.0,
		parts = {
			{ "Block", V(2.8, 2.4, 4.6), V(0, 3.2, 0.4), rgb(250, 244, 230) },
			{ "Block", V(1.4, 3.2, 1.4), V(0, 5.2, -1.6), rgb(250, 244, 230) },
			{ "Ball", V(1.9, 1.7, 2.3), V(0, 6.9, -1.9), rgb(250, 244, 230) },
			{ "Block", V(0.4, 0.9, 0.4), V(0.6, 7.9, -1.5), rgb(250, 244, 230) },
			{ "Block", V(0.4, 0.9, 0.4), V(-0.6, 7.9, -1.5), rgb(250, 244, 230) },
			{ "Cyl", V(3.0, 1.0, 3.0), V(0, 4.9, 1.0), rgb(110, 70, 50) },
			{ "Cyl", V(2.2, 1.0, 2.2), V(0, 5.9, 1.0), rgb(96, 60, 44) },
			{ "Cyl", V(1.5, 0.8, 1.5), V(0, 6.8, 1.0), rgb(84, 52, 40) },
			{ "Ball", V(1.3, 1.0, 1.3), V(0, 7.4, 1.0), rgb(255, 110, 20), Neon },
			{ "Ball", V(0.6, 0.6, 0.6), V(0.5, 8.3, 1.1), rgb(255, 190, 40), Neon },
			{ "Cyl", V(0.7, 2.0, 0.7), V(0.9, 1.0, -1.2), rgb(236, 226, 206) },
			{ "Cyl", V(0.7, 2.0, 0.7), V(-0.9, 1.0, -1.2), rgb(236, 226, 206) },
			{ "Cyl", V(0.7, 2.0, 0.7), V(0.9, 1.0, 2.0), rgb(236, 226, 206) },
			{ "Cyl", V(0.7, 2.0, 0.7), V(-0.9, 1.0, 2.0), rgb(236, 226, 206) },
		},
		face = { y = 7.0, z = -3.0, gap = 0.5, size = 0.65, mouth = "teeth" },
	},
	{
		id = "moolander",
		name = "UFO Cow Moolander",
		rarity = "Legendary",
		price = 400000,
		income = 1800,
		quip = "Abducts itself for the content.",
		height = 7.2,
		parts = {
			{ "Ball", V(6.0, 1.6, 6.0), V(0, 2.6, 0), rgb(150, 160, 180), Foil },
			{ "Ball", V(4.0, 4.2, 4.0), V(0, 4.0, 0), rgb(140, 230, 255), Glass, nil, 0.55 },
			{ "Ball", V(2.5, 2.3, 2.5), V(0, 4.3, 0), rgb(250, 250, 250) },
			{ "Ball", V(1.0, 0.9, 0.5), V(0.6, 4.9, 1.0), rgb(40, 40, 46) },
			{ "Ball", V(1.5, 1.0, 0.9), V(0, 3.8, -1.2), rgb(255, 170, 190) },
			{ "Cyl", V(0.3, 0.8, 0.3), V(0.9, 5.6, 0), rgb(240, 230, 200), nil, V(0, 0, -24) },
			{ "Cyl", V(0.3, 0.8, 0.3), V(-0.9, 5.6, 0), rgb(240, 230, 200), nil, V(0, 0, 24) },
			{ "Ball", V(0.7, 0.7, 0.7), V(3.0, 2.5, 0), rgb(110, 255, 90), Neon },
			{ "Ball", V(0.7, 0.7, 0.7), V(-3.0, 2.5, 0), rgb(110, 255, 90), Neon },
			{ "Ball", V(0.7, 0.7, 0.7), V(0, 2.5, -3.0), rgb(255, 80, 200), Neon },
			{ "Ball", V(0.7, 0.7, 0.7), V(0, 2.5, 3.0), rgb(255, 80, 200), Neon },
			{ "Cyl", V(2.6, 1.8, 2.6), V(0, 1.0, 0), rgb(120, 255, 200), Neon, nil, 0.7 },
		},
		face = { y = 4.7, z = -1.2, gap = 0.5, size = 0.65, mouth = "none" },
	},
	-- MYTHIC -----------------------------------------------------------------------------------
	{
		id = "knittoria",
		name = "Galaxy Granny Knittoria",
		rarity = "Mythic",
		price = 1500000,
		income = 5000,
		quip = "Knits black holes. Calls them 'cosy'.",
		height = 7.6,
		parts = {
			{ "Ball", V(4.4, 2.2, 4.4), V(0, 1.1, 0), rgb(70, 40, 150) },
			{ "Ball", V(3.4, 3.2, 3.4), V(0, 2.9, 0), rgb(96, 56, 190) },
			{ "Ball", V(2.5, 2.5, 2.5), V(0, 5.3, 0), rgb(214, 190, 255) },
			{ "Ball", V(2.7, 1.5, 2.7), V(0, 6.1, 0.3), rgb(230, 232, 240) },
			{ "Ball", V(1.3, 1.3, 1.3), V(0, 7.2, 0.4), rgb(230, 232, 240) },
			{ "Block", V(1.9, 0.5, 0.15), V(0, 5.5, -1.25), rgb(40, 30, 60) },
			{ "Ball", V(1.3, 1.3, 1.3), V(1.9, 3.0, -1.4), rgb(255, 70, 190), Neon },
			{ "Cyl", V(0.15, 2.4, 0.15), V(1.6, 3.6, -1.4), rgb(240, 240, 250), nil, V(0, 0, 40) },
			{ "Cyl", V(0.15, 2.4, 0.15), V(2.2, 3.6, -1.4), rgb(240, 240, 250), nil, V(0, 0, -40) },
			{ "Ball", V(0.5, 0.5, 0.5), V(-2.6, 5.4, 0), rgb(255, 240, 120), Neon },
			{ "Ball", V(0.4, 0.4, 0.4), V(2.4, 6.6, 0.6), rgb(120, 220, 255), Neon },
			{ "Ball", V(0.35, 0.35, 0.35), V(-1.8, 7.3, -0.6), rgb(255, 150, 240), Neon },
		},
		face = { y = 5.4, z = -1.2, gap = 0.5, size = 0.6, mouth = "smile" },
	},
	{
		id = "goudalord",
		name = "Goudalord the Cheese Emperor",
		rarity = "Mythic",
		price = 4000000,
		income = 12000,
		quip = "Rules with an iron rind.",
		height = 8.0,
		parts = {
			{ "Wedge", V(4.2, 3.8, 4.6), V(0, 3.4, 0), rgb(255, 204, 50), nil, V(0, 180, 0) },
			{ "Block", V(4.2, 0.5, 4.6), V(0, 1.4, 0), rgb(240, 170, 40) },
			{ "Ball", V(0.9, 0.9, 0.5), V(1.2, 2.6, -2.2), rgb(214, 150, 30) },
			{ "Ball", V(0.6, 0.6, 0.5), V(-1.4, 3.6, -2.2), rgb(214, 150, 30) },
			{ "Cyl", V(2.0, 0.6, 2.0), V(0, 5.6, -1.7), rgb(255, 215, 70), Foil },
			{ "Wedge", V(0.5, 0.9, 0.5), V(0.7, 6.3, -1.7), rgb(255, 215, 70), Foil },
			{ "Wedge", V(0.5, 0.9, 0.5), V(-0.7, 6.3, -1.7), rgb(255, 215, 70), Foil },
			{ "Wedge", V(0.5, 0.9, 0.5), V(0, 6.3, -2.4), rgb(255, 215, 70), Foil },
			{ "Ball", V(0.5, 0.5, 0.5), V(0, 5.6, -2.7), rgb(255, 50, 80), Neon },
			{ "Block", V(4.6, 4.4, 0.3), V(0, 3.2, 2.5), rgb(200, 30, 60), nil, V(-10, 0, 0) },
			{ "Cyl", V(0.3, 4.6, 0.3), V(2.9, 3.4, -1.2), rgb(255, 215, 70), Foil },
			{ "Ball", V(0.9, 0.9, 0.9), V(2.9, 5.9, -1.2), rgb(120, 255, 240), Neon },
		},
		face = { y = 4.2, z = -2.35, gap = 0.6, size = 0.75, mouth = "teeth" },
		legs = { h = 1.2, spread = 1.0, color = rgb(255, 204, 50), shoe = rgb(150, 40, 200) },
	},
}

Catalog.ById = {}
Catalog.ByRarity = {}
for _, entry in Catalog.List do
	Catalog.ById[entry.id] = entry
	Catalog.ByRarity[entry.rarity] = Catalog.ByRarity[entry.rarity] or {}
	table.insert(Catalog.ByRarity[entry.rarity], entry)
end

-- Income of one owned brainrot: base rate x mutation x level bonus (each level adds +50%).
function Catalog.incomePerSecond(entry, mutationId: string?, level: number): number
	local mult = 1
	for _, mutation in Catalog.Mutations do
		if mutation.id == mutationId then
			mult = mutation.mult
		end
	end
	return math.floor(entry.income * mult * (1 + 0.5 * (level - 1)) + 0.5)
end

function Catalog.priceOf(entry, mutationId: string?): number
	return Catalog.incomePerSecond(entry, mutationId, 1) / entry.income * entry.price
end

function Catalog.upgradeCost(entry, level: number): number
	return math.floor(entry.price * 0.6 * level)
end

function Catalog.rebirthCost(rebirths: number): number
	return Catalog.RebirthBaseCost * 5 ^ rebirths
end

-- 1234567 -> "1.23M": every money label in the game (HUD, pads, billboards) goes through here.
function Catalog.formatCash(amount: number): string
	local units = { "", "K", "M", "B", "T" }
	local value, unit = math.floor(amount), 1
	if value < 1000 then
		return tostring(value)
	end
	local scaled = value
	while scaled >= 1000 and unit < #units do
		scaled /= 1000
		unit += 1
	end
	local text = string.format(scaled >= 100 and "%.0f" or scaled >= 10 and "%.1f" or "%.2f", scaled)
	text = text:gsub("(%.%d-)0+$", "%1"):gsub("%.$", "")
	return text .. units[unit]
end

return Catalog
