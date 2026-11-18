-- BazaarWorld: builds the 3D map of BRAINROT BAZAAR out of parts when the server starts:
-- the plaza, the conveyor lane with the Brainrot-O-Matic and the Recycler, eight walled base
-- plots with pads, gates, awnings and shields, the thief hideout, signs, lamps, palms and tents.
-- One job: geometry. It returns a description of the map that the other modules play on.

local World = {}

local V = Vector3.new
local rgb = Color3.fromRGB

World.GROUND_Y = 0.4 -- top of the plaza floor
World.BELT_Y = 1.6 -- top of the conveyor belt
World.BELT_START_X = -84
World.BELT_END_X = 86
World.BELT_HALF_WIDTH = 5
World.PLOT_XS = { -60, -20, 20, 60 }
World.PLOT_Z = 42
World.HIDEOUT_DOOR = V(106, 0.4, 0)

local buildPlazaGround, buildConveyorLane, buildThiefHideout, buildSignsAndScenery, buildBasePlot

-- Builds the whole bazaar under Workspace.Bazaar and returns the plots the game is played on.
function World.buildBazaarWorld()
	local folder = Instance.new("Folder")
	folder.Name = "Bazaar"

	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = folder
	buildPlazaGround(scenery)
	buildConveyorLane(scenery)
	buildThiefHideout(scenery)
	buildSignsAndScenery(scenery)

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = "Plots"
	plotFolder.Parent = folder
	local plots = {}
	for index = 1, 8 do
		plots[index] = buildBasePlot(plotFolder, index)
	end

	for _, name in { "Conveyor", "Strays", "Thieves", "Carried" } do
		local sub = Instance.new("Folder")
		sub.Name = name
		sub.Parent = folder
	end

	folder.Parent = workspace
	return { folder = folder, plots = plots }
end

local PLOT_COLORS = {
	rgb(255, 92, 92), rgb(255, 170, 40), rgb(80, 200, 120), rgb(60, 170, 255),
	rgb(190, 100, 255), rgb(255, 110, 190), rgb(60, 210, 210), rgb(240, 220, 60),
}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- An upright cylinder: diameter, height.
local function pillar(parent: Instance, name: string, diameter: number, height: number, position: Vector3, color: Color3, material: Enum.Material?): Part
	return part(parent, name, V(height, diameter, diameter), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

-- Text on the front (and optionally the back) face of a board part.
local function paintSign(board: Part, text: string, textColor: Color3, bothSides: boolean?): TextLabel
	local first
	for _, face in bothSides and { Enum.NormalId.Front, Enum.NormalId.Back } or { Enum.NormalId.Front } do
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Sign" .. face.Name
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = textColor
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = rgb(20, 16, 30)
		label.Text = text
		label.Parent = gui
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0.04, 0)
		pad.PaddingRight = UDim.new(0.04, 0)
		pad.PaddingTop = UDim.new(0.06, 0)
		pad.PaddingBottom = UDim.new(0.06, 0)
		pad.Parent = label
		first = first or label
	end
	return first
end

local function buildPalm(parent: Instance, position: Vector3)
	pillar(parent, "PalmTrunk", 1.6, 14, position + V(0, 7, 0), rgb(150, 110, 70), Enum.Material.Wood)
	for i = 0, 4 do
		local angle = math.rad(i * 72)
		local leaf = part(parent, "PalmLeaf", V(2.4, 0.4, 8), CFrame.new(position + V(0, 14, 0)) * CFrame.Angles(0, angle, 0) * CFrame.new(0, -0.6, -4) * CFrame.Angles(math.rad(-18), 0, 0), rgb(60, 180, 90), Enum.Material.Grass)
		leaf.CanCollide = false
	end
	local nut = part(parent, "Coconut", V(1.4, 1.4, 1.4), CFrame.new(position + V(0.6, 13.2, 0.4)), rgb(110, 70, 40), nil, Enum.PartType.Ball)
	nut.CanCollide = false
end

local function buildLamp(parent: Instance, position: Vector3, color: Color3)
	pillar(parent, "LampPost", 0.6, 11, position + V(0, 5.5, 0), rgb(50, 50, 66), Enum.Material.Metal)
	local bulb = part(parent, "LampBulb", V(2.2, 2.2, 2.2), CFrame.new(position + V(0, 11.6, 0)), color, Enum.Material.Neon, Enum.PartType.Ball)
	bulb.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 22
	light.Brightness = 1.2
	light.Parent = bulb
	-- a balloon tied to every lamp: the bazaar is having a great day
	local balloon = part(parent, "Balloon", V(2.6, 3.2, 2.6), CFrame.new(position + V(1.6, 16.5, 0.8)), Color3.fromHSV((position.X * 0.013 + position.Z * 0.02) % 1, 0.7, 1), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	balloon.CanCollide = false
	local cord = part(parent, "BalloonString", V(0.12, 4, 0.12), CFrame.new(position + V(1.2, 13.4, 0.6)) * CFrame.Angles(0, 0, math.rad(-12)), rgb(240, 240, 240))
	cord.CanCollide = false
end

-- A striped market tent selling nothing useful.
local function buildTent(parent: Instance, position: Vector3, facing: number, color: Color3, wares: string)
	local base = CFrame.new(position) * CFrame.Angles(0, facing, 0)
	for _, corner in { V(-5, 0, -3.5), V(5, 0, -3.5), V(-5, 0, 3.5), V(5, 0, 3.5) } do
		pillar(parent, "TentPole", 0.5, 8, (base * CFrame.new(corner + V(0, 4, 0))).Position, rgb(245, 240, 225), Enum.Material.Wood)
	end
	for stripe = 0, 4 do
		local stripeColor = stripe % 2 == 0 and color or rgb(250, 248, 240)
		local roof = part(parent, "TentRoof", V(2.2, 0.4, 8.4), base * CFrame.new(-4.4 + stripe * 2.2, 8.4, 0), stripeColor, Enum.Material.Fabric)
		roof.CanCollide = false
	end
	part(parent, "TentCounter", V(10, 2.6, 1.4), base * CFrame.new(0, 1.3, -3), rgb(170, 120, 70), Enum.Material.WoodPlanks)
	local board = part(parent, "TentSign", V(9, 1.8, 0.3), base * CFrame.new(0, 9.6, -4.2), rgb(40, 34, 60))
	board.CanCollide = false
	paintSign(board, wares, rgb(255, 236, 130))
	for i = 1, 3 do
		local crate = part(parent, "Crate", V(1.8, 1.8, 1.8), base * CFrame.new(-6.5, 0.9 + (i == 3 and 1.8 or 0), i == 2 and 1.9 or 0) * CFrame.Angles(0, i * 0.4, 0), rgb(196, 150, 90), Enum.Material.WoodPlanks)
		crate.CanCollide = true
	end
end

-- The plaza floor, the grass, and the checkered walkways beside the conveyor.
function buildPlazaGround(parent: Instance)
	part(parent, "PlazaFloor", V(250, 0.4, 126), CFrame.new(10, 0.2, 0), rgb(240, 214, 160), Enum.Material.Sand)
	for side = -1, 1, 2 do
		for i = 0, 21 do
			local tile = part(parent, "WalkTile", V(8, 0.1, 8), CFrame.new(-84 + i * 8, 0.42, side * 12), i % 2 == 0 and rgb(255, 244, 214) or rgb(255, 196, 150), Enum.Material.SmoothPlastic)
			tile.CanCollide = false
			local tile2 = part(parent, "WalkTile", V(8, 0.1, 8), CFrame.new(-84 + i * 8, 0.42, side * 20), i % 2 == 1 and rgb(255, 244, 214) or rgb(255, 196, 150), Enum.Material.SmoothPlastic)
			tile2.CanCollide = false
		end
	end
end

-- The conveyor lane: belt, rails, the Brainrot-O-Matic that drops creatures and the Recycler that eats them.
function buildConveyorLane(parent: Instance)
	local length = World.BELT_END_X - World.BELT_START_X + 8
	local centerX = (World.BELT_END_X + World.BELT_START_X) / 2
	local belt = part(parent, "ConveyorBelt", V(length, 1.2, World.BELT_HALF_WIDTH * 2), CFrame.new(centerX, World.BELT_Y - 0.6, 0), rgb(44, 46, 62), Enum.Material.DiamondPlate)
	belt.AssemblyLinearVelocity = V(7, 0, 0)
	for side = -1, 1, 2 do
		part(parent, "BeltRail", V(length, 0.7, 0.7), CFrame.new(centerX, World.BELT_Y + 0.1, side * (World.BELT_HALF_WIDTH + 0.35)), rgb(255, 206, 40), Enum.Material.Neon).CanCollide = false
		for i = 0, 10 do
			pillar(parent, "BeltLeg", 0.8, 1.2, V(World.BELT_START_X + i * 17, 0.8, side * (World.BELT_HALF_WIDTH + 0.35)), rgb(30, 30, 40), Enum.Material.Metal)
		end
	end

	-- Brainrot-O-Matic: the machine every brainrot falls out of.
	local machineX = World.BELT_START_X - 10
	part(parent, "BrainrotOMatic", V(16, 16, 18), CFrame.new(machineX, 8.4, 0), rgb(130, 70, 220), Enum.Material.SmoothPlastic)
	part(parent, "MachineTrim", V(16.6, 1.2, 18.6), CFrame.new(machineX, 16.6, 0), rgb(255, 206, 40), Enum.Material.Neon)
	part(parent, "MachineMouth", V(0.6, 7, 9), CFrame.new(machineX + 8, 5.2, 0), rgb(16, 12, 26)).CanCollide = false
	pillar(parent, "MachineChimney", 3, 8, V(machineX - 3, 21, -4), rgb(90, 50, 160))
	pillar(parent, "MachineChimney", 2.2, 6, V(machineX - 3, 20, 4), rgb(90, 50, 160))
	local brain = part(parent, "MachineBrain", V(7, 5.5, 7), CFrame.new(machineX + 2, 20.4, 0), rgb(255, 130, 190), Enum.Material.Neon, Enum.PartType.Ball)
	brain.CanCollide = false
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate = 5
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Speed = NumberRange.new(3, 5)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color = ColorSequence.new(rgb(255, 170, 230))
	smoke.Parent = brain
	local machineSign = part(parent, "MachineSign", V(17, 4.4, 0.4), CFrame.new(machineX + 8.3, 12.4, 0) * CFrame.Angles(0, math.rad(-90), 0), rgb(30, 22, 50))
	machineSign.CanCollide = false
	paintSign(machineSign, "BRAINROT-O-MATIC", rgb(255, 226, 90))

	-- Recycler: unsold brainrots ride into it at the far end.
	local recyclerX = World.BELT_END_X + 8
	part(parent, "Recycler", V(10, 10, 14), CFrame.new(recyclerX, 5.4, 0), rgb(226, 62, 70))
	part(parent, "RecyclerMouth", V(0.6, 6, 9), CFrame.new(recyclerX - 5, 4.6, 0), rgb(16, 12, 26)).CanCollide = false
	for i = -3, 3 do
		local tooth = Instance.new("WedgePart")
		tooth.Name = "RecyclerTooth"
		tooth.Anchored = true
		tooth.CanCollide = false
		tooth.Size = V(1.1, 1.6, 1.1)
		tooth.Color = rgb(250, 250, 250)
		tooth.CFrame = CFrame.new(recyclerX - 5.4, 7, i * 1.25) * CFrame.Angles(math.rad(180), math.rad(90), 0)
		tooth.Parent = parent
	end
	local recyclerSign = part(parent, "RecyclerSign", V(13, 3, 0.4), CFrame.new(recyclerX - 5.3, 12.4, 0) * CFrame.Angles(0, math.rad(90), 0), rgb(30, 22, 50))
	recyclerSign.CanCollide = false
	paintSign(recyclerSign, "RECYCLER  (too slow!)", rgb(255, 120, 120))
end

-- The cave the snatchers run out of, and run back to with your brainrot.
function buildThiefHideout(parent: Instance)
	local x = World.HIDEOUT_DOOR.X + 14
	local rock = part(parent, "HideoutRock", V(34, 30, 40), CFrame.new(x + 4, 2, 0), rgb(74, 70, 92), Enum.Material.Slate)
	rock.CanCollide = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = rock
	local door = part(parent, "HideoutDoor", V(1, 10, 10), CFrame.new(x - 11.6, 5, 0), rgb(10, 8, 16))
	door.CanCollide = false
	for side = -1, 1, 2 do
		pillar(parent, "HideoutTorch", 0.7, 7, V(x - 12.4, 3.5, side * 7), rgb(90, 60, 40), Enum.Material.Wood)
		local flame = part(parent, "TorchFlame", V(1.6, 2.2, 1.6), CFrame.new(x - 12.4, 7.8, side * 7), rgb(255, 130, 30), Enum.Material.Neon, Enum.PartType.Ball)
		flame.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = rgb(255, 130, 30)
		light.Range = 20
		light.Parent = flame
	end
	local sign = part(parent, "HideoutSign", V(16, 3.6, 0.4), CFrame.new(x - 12.2, 13.4, 0) * CFrame.Angles(0, math.rad(90), 0), rgb(30, 10, 14))
	sign.CanCollide = false
	paintSign(sign, "THIEF HIDEOUT", rgb(255, 70, 70))
end

-- The giant welcome arch and the scenery around the plots.
function buildSignsAndScenery(parent: Instance)
	for side = -1, 1, 2 do
		pillar(parent, "ArchPillar", 3.4, 30, V(-72, 15, side * 23), rgb(255, 92, 140))
		part(parent, "ArchCap", V(5, 2, 5), CFrame.new(-72, 30.6, side * 23), rgb(255, 206, 40), Enum.Material.Neon).CanCollide = false
	end
	local arch = part(parent, "WelcomeArch", V(50, 9, 1.4), CFrame.new(-72, 26, 0) * CFrame.Angles(0, math.rad(-90), 0), rgb(48, 30, 96))
	arch.CanCollide = false
	paintSign(arch, "BRAINROT BAZAAR", rgb(255, 226, 90), true)

	for _, x in { -40, 0, 40, 80 } do
		for side = -1, 1, 2 do
			buildLamp(parent, V(x, World.GROUND_Y, side * 24.6), Color3.fromHSV((x + 80) / 200, 0.6, 1))
		end
	end
	for side = -1, 1, 2 do
		for i = 0, 5 do
			buildPalm(parent, V(-88 + i * 38, World.GROUND_Y, side * (66 + (i % 2) * 5)))
		end
	end
	buildTent(parent, V(-104, World.GROUND_Y, 34), math.rad(-90), rgb(255, 92, 92), "SOCKS (LEFT ONLY)")
	buildTent(parent, V(-104, World.GROUND_Y, -34), math.rad(-90), rgb(60, 170, 255), "PRE-CHEWED GUM")
	buildTent(parent, V(92, World.GROUND_Y, 40), math.rad(90), rgb(80, 200, 120), "ANTI-THIEF SPRAY")
	buildTent(parent, V(92, World.GROUND_Y, -40), math.rad(90), rgb(255, 170, 40), "SIGMA LEMONADE")

	-- rolling hills and a few fat clouds so the horizon is not a flat line
	for i = 0, 13 do
		local angle = i / 14 * math.pi * 2
		local radius = 230 + (i % 3) * 30
		local hill = part(parent, "Hill", V(150 + (i % 4) * 30, 70 + (i % 5) * 16, 150), CFrame.new(math.cos(angle) * radius + 10, -6, math.sin(angle) * radius), Color3.fromHSV(0.3 + (i % 3) * 0.03, 0.55, 0.62 + (i % 2) * 0.08), Enum.Material.Grass)
		hill.CanCollide = false
		local dome = Instance.new("SpecialMesh")
		dome.MeshType = Enum.MeshType.Sphere
		dome.Parent = hill
	end
	for i = 0, 8 do
		local cloudAt = V(-160 + i * 44, 86 + (i % 3) * 14, (i % 2 == 0 and -1 or 1) * (90 + (i % 4) * 28))
		for puff = -1, 1 do
			local cloud = part(parent, "Cloud", V(30 - math.abs(puff) * 8, 13 - math.abs(puff) * 3, 20), CFrame.new(cloudAt + V(puff * 15, 0, puff * 3)), rgb(255, 255, 255))
			cloud.CanCollide = false
			cloud.CastShadow = false
			local fluff = Instance.new("SpecialMesh")
			fluff.MeshType = Enum.MeshType.Sphere
			fluff.Parent = cloud
		end
	end
end

-- One walled base plot: floor, walls, gate with the owner sign, eight pads, a striped awning,
-- the big red lock button and the (hidden until locked) shield with laser bars over the gate.
function buildBasePlot(parent: Instance, index: number)
	local side = index <= 4 and 1 or -1
	local x = World.PLOT_XS[(index - 1) % 4 + 1]
	local center = V(x, World.GROUND_Y, side * World.PLOT_Z)
	-- local -Z looks at the conveyor lane, local +Z is the back wall
	local origin = CFrame.lookAt(center, center - V(0, 0, side))
	local color = PLOT_COLORS[index]
	local dark = color:Lerp(rgb(20, 16, 30), 0.45)

	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder:SetAttribute("PlotIndex", index)
	folder.Parent = parent

	local floor = part(folder, "BaseFloor", V(34, 0.6, 32), origin * CFrame.new(0, 0.3, 0), color:Lerp(rgb(255, 250, 240), 0.62), Enum.Material.SmoothPlastic)
	part(folder, "BackWall", V(34, 4.4, 1), origin * CFrame.new(0, 2.2, 16.5), color)
	part(folder, "SideWall", V(1, 4.4, 34), origin * CFrame.new(17.5, 2.2, 0), color)
	part(folder, "SideWall", V(1, 4.4, 34), origin * CFrame.new(-17.5, 2.2, 0), color)
	part(folder, "FrontWall", V(10, 4.4, 1), origin * CFrame.new(12.5, 2.2, -16.5), color)
	part(folder, "FrontWall", V(10, 4.4, 1), origin * CFrame.new(-12.5, 2.2, -16.5), color)
	for _, px in { -7, 7 } do
		part(folder, "GatePost", V(2, 6.4, 2), origin * CFrame.new(px, 3.2, -16.5), dark)
		part(folder, "GateLantern", V(1.6, 1.6, 1.6), origin * CFrame.new(px, 7.2, -16.5), color, Enum.Material.Neon, Enum.PartType.Ball).CanCollide = false
	end
	-- the owner's sign stands behind the awning so it never hides the brainrots from the lane
	for _, px in { -9, 9 } do
		part(folder, "SignPost", V(0.8, 12, 0.8), origin * CFrame.new(px, 6, 17.4), dark)
	end
	local board = part(folder, "OwnerSign", V(22, 5.6, 0.8), origin * CFrame.new(0, 13.4, 17.4), rgb(30, 22, 50))
	board.CanCollide = false
	local ownerLabel = paintSign(board, "FOR RENT", rgb(255, 255, 255), true)

	-- striped awning over the back wall
	for stripe = 0, 7 do
		local awning = part(folder, "Awning", V(4.25, 0.4, 6), origin * CFrame.new(-14.9 + stripe * 4.25, 7.2, 14) * CFrame.Angles(math.rad(-14), 0, 0), stripe % 2 == 0 and color or rgb(250, 248, 240), Enum.Material.Fabric)
		awning.CanCollide = false
	end
	for _, px in { -16.4, 16.4 } do
		part(folder, "AwningPole", V(0.6, 7.6, 0.6), origin * CFrame.new(px, 3.8, 11.4), rgb(245, 240, 225), Enum.Material.Wood)
	end

	local pads = {}
	for n = 1, 8 do
		local col = (n - 1) % 4
		local row = math.floor((n - 1) / 4)
		local padCf = origin * CFrame.new(-12 + col * 8, 0.6, -5 + row * 12)
		local pad = part(folder, "Pad" .. n, V(0.4, 6.4, 6.4), padCf * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(60, 56, 80), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		pad:SetAttribute("PadIndex", n)
		local tag = Instance.new("BillboardGui")
		tag.Name = "PadTag"
		tag.Size = UDim2.fromScale(6, 2.2)
		tag.StudsOffsetWorldSpace = V(0, 2.4, 0)
		tag.LightInfluence = 0
		tag.MaxDistance = 110
		tag.DistanceLowerLimit = 36
		tag.Parent = pad
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = rgb(255, 255, 255)
		text.TextStrokeTransparency = 0
		text.Text = ""
		text.Parent = tag
		pads[n] = { index = n, part = pad, cf = padCf * CFrame.new(0, 0.4, 0), tag = text }
	end

	-- lock button on a pedestal just inside the gate
	part(folder, "LockPedestal", V(2.4, 2.6, 2.4), origin * CFrame.new(11, 1.9, -12.5), rgb(60, 56, 80))
	local lockButton = pillar(folder, "LockButton", 2, 0.7, (origin * CFrame.new(11, 3.5, -12.5)).Position, rgb(255, 50, 60), Enum.Material.Neon)

	local shield = part(folder, "LockShield", V(36.4, 13, 34.4), origin * CFrame.new(0, 6.5, 0), rgb(80, 220, 255), Enum.Material.Neon)
	shield.Transparency = 1
	shield.CanCollide = false
	shield.CanQuery = false
	shield.CastShadow = false
	local bars = {}
	for i = 1, 4 do
		local bar = part(folder, "GateLaser", V(12, 0.5, 0.5), origin * CFrame.new(0, 0.4 + i * 1.7, -16.5), rgb(80, 230, 255), Enum.Material.Neon)
		bar.Transparency = 1
		bar.CanCollide = false
		bar.CastShadow = false
		bars[i] = bar
	end

	local brainrots = Instance.new("Folder")
	brainrots.Name = "Brainrots"
	brainrots.Parent = folder

	return {
		index = index,
		side = side,
		origin = origin,
		color = color,
		folder = folder,
		brainrotFolder = brainrots,
		floor = floor,
		pads = pads,
		ownerLabel = ownerLabel,
		ownerBoard = board,
		lockButton = lockButton,
		shield = shield,
		bars = bars,
		gate = (origin * CFrame.new(0, 0, -19)).Position,
	}
end

return World
