-- ThiefAI: the threat. On a timer a THIEF WAVE pours out of the hideout: each snatcher runs to
-- a base, grabs its highest-earning brainrot and legs it back to the hideout. Touch a snatcher
-- to bonk it (the loot pops back onto its pad and you earn a bounty), or lock the base to zap
-- them. Rob a rival's base and a revenge raid comes for yours.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local World = require(script.Parent.BazaarWorld)
local Economy = require(script.Parent.Economy)
local BaseManager = require(script.Parent.BaseManager)

local ThiefAI = {}

local CALM_SECONDS = 50
local FIRST_CALM_SECONDS = 35
local WARN_SECONDS = 8
local RAID_MAX_SECONDS = 40
local BONK_RADIUS = 5.5
local RUN_SPEED = 21
local LOOT_SPEED = 13.5

local thiefFolder: Folder
local thieves = {} -- { model, root, plot, path, leg, state, loot, speed, phase, position }
local waveNumber = 0

local rgb = Color3.fromRGB
local RED = rgb(255, 70, 70)

-- The snatcher reaches a pad, lifts the base's best brainrot and turns to run.
local function stealBestBrainrot(thief)
	local record = BaseManager.bestBrainrotOf(thief.plot)
	if not record then
		return false
	end
	thief.loot = record
	BaseManager.grabBrainrot(record, thief.root)
	local owner = thief.plot.owner
	if owner then
		BaseManager.hooks.notify(owner, {
			kind = "stolen",
			title = "THIEF ALERT!",
			body = record.entry.name .. " was grabbed. Bonk the thief before it reaches the hideout!",
			color = RED,
		})
	end
	return true
end

local function bodyPart(model: Model, root: BasePart, size: Vector3, offset: CFrame, color: Color3, ball: boolean?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CFrame = offset
	if ball then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	end
	p.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	return p
end

-- A masked raccoon bandit with a beanie, a striped shirt, a loot sack and a red warning label.
local function buildSnatcherModel(): Model
	local model = Instance.new("Model")
	model.Name = "Snatcher"
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CFrame = CFrame.new(0, 0.5, 0)
	root.Parent = model
	model.PrimaryPart = root

	local fur, dark, white = rgb(120, 122, 138), rgb(34, 32, 44), rgb(245, 245, 245)
	bodyPart(model, root, Vector3.new(2.6, 3.0, 2.3), CFrame.new(0, 2.4, 0), dark, true)
	bodyPart(model, root, Vector3.new(2.7, 0.45, 2.4), CFrame.new(0, 2.0, 0), white, true)
	bodyPart(model, root, Vector3.new(2.7, 0.45, 2.4), CFrame.new(0, 2.8, 0), white, true)
	bodyPart(model, root, Vector3.new(2.6, 2.4, 2.4), CFrame.new(0, 4.6, 0), fur, true)
	bodyPart(model, root, Vector3.new(2.7, 0.8, 2.5), CFrame.new(0, 4.8, -0.05), dark, true) -- the mask
	bodyPart(model, root, Vector3.new(2.3, 1.3, 2.3), CFrame.new(0, 5.6, 0), dark, true) -- beanie
	bodyPart(model, root, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 6.3, 0), RED, true, Enum.Material.Neon)
	for _, side in { -1, 1 } do
		bodyPart(model, root, Vector3.new(0.65, 0.7, 0.4), CFrame.new(side * 0.55, 4.85, -1.2), white, true)
		bodyPart(model, root, Vector3.new(0.3, 0.35, 0.3), CFrame.new(side * 0.5, 4.8, -1.38), dark, true)
		bodyPart(model, root, Vector3.new(0.7, 0.9, 0.5), CFrame.new(side * 0.9, 5.9, 0), fur, true) -- ears
		bodyPart(model, root, Vector3.new(0.7, 1.3, 0.7), CFrame.new(side * 0.6, 0.65, 0), dark)
		bodyPart(model, root, Vector3.new(0.6, 1.8, 0.6), CFrame.new(side * 1.5, 2.8, -0.5) * CFrame.Angles(math.rad(-50), 0, 0), fur)
	end
	bodyPart(model, root, Vector3.new(0.7, 0.5, 0.6), CFrame.new(0, 4.3, -1.25), dark, true) -- nose
	bodyPart(model, root, Vector3.new(2.4, 2.6, 2.2), CFrame.new(0, 3.0, 1.7), rgb(196, 160, 100), true, Enum.Material.Fabric) -- loot sack
	for ring = 0, 2 do
		bodyPart(model, root, Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 1.2 + ring * 0.4, 1.4 + ring * 0.8 + 1.2), ring % 2 == 0 and fur or dark, true) -- striped tail
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(11, 3.6)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 8.6, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 320
	gui.DistanceLowerLimit = 50
	gui.DistanceUpperLimit = 84
	gui.Parent = root
	for index, text in { "THIEF!", "TOUCH TO BONK" } do
		local line = Instance.new("TextLabel")
		line.Size = UDim2.fromScale(1, index == 1 and 0.6 or 0.4)
		line.Position = UDim2.fromScale(0, index == 1 and 0 or 0.6)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.FredokaOne
		line.TextScaled = true
		line.TextColor3 = index == 1 and RED or rgb(255, 255, 255)
		line.TextStrokeTransparency = 0
		line.Text = text
		line.Parent = gui
	end
	return model
end

-- Sends one snatcher from the hideout toward a base.
function ThiefAI.sendThiefToBase(plot)
	local model = buildSnatcherModel()
	model:ScaleTo(1.25) -- big enough to spot from across the plaza
	local door = World.HIDEOUT_DOOR
	local laneZ = plot.side * 15
	local thief = {
		model = model,
		root = model.PrimaryPart,
		plot = plot,
		position = door,
		path = { Vector3.new(98, World.GROUND_Y, laneZ), Vector3.new(plot.gate.X, World.GROUND_Y, laneZ), plot.gate },
		leg = 1,
		state = "approach",
		loot = nil,
		speed = RUN_SPEED + math.min(waveNumber, 6),
		phase = math.random() * 6,
	}
	model:PivotTo(CFrame.new(door))
	model.Parent = thiefFolder
	table.insert(thieves, thief)
	return thief
end

-- Bonked by a player or zapped by a shield: drop the loot, fly off spinning, vanish.
local function knockOutThief(thief, bonkedBy: Player?)
	if thief.state == "out" then
		return
	end
	local loot = thief.loot
	thief.loot = nil
	thief.state = "out"
	thief.outAt = os.clock()
	if loot then
		BaseManager.returnBrainrotToPad(loot)
	end
	local label = thief.root:FindFirstChild("Label")
	if label then
		label:Destroy()
	end
	if bonkedBy then
		local bounty = 20 + 15 * waveNumber
		Economy.addCash(bonkedBy, bounty)
		BaseManager.hooks.notify(bonkedBy, {
			kind = "bonk",
			title = "BONK! +$" .. Catalog.formatCash(bounty),
			body = loot and (loot.entry.name .. " is safe on its pad") or "One less snatcher in the bazaar",
			color = rgb(120, 255, 140),
		})
	end
end

-- When a base locks, every thief inside it or already carrying its brainrot gets zapped.
function ThiefAI.zapThievesAt(plot)
	for _, thief in thieves do
		if thief.plot == plot and (thief.loot or BaseManager.isInsideBase(plot, thief.position)) then
			knockOutThief(thief, nil)
		end
	end
end

local function reachedWaypoint(thief)
	if thief.state == "approach" then
		if thief.leg < #thief.path then
			thief.leg += 1
			return
		end
		-- at the gate: a locked base bounces the thief, an open one gets robbed
		if BaseManager.isLocked(thief.plot) then
			knockOutThief(thief, nil)
			return
		end
		local target = BaseManager.bestBrainrotOf(thief.plot)
		if not target then
			thief.state = "flee"
			thief.leg = #thief.path - 1
			return
		end
		thief.state = "sneak"
		thief.sneakTo = (target.pad.cf * CFrame.new(0, 0, -3.6)).Position
	elseif thief.state == "sneak" then
		stealBestBrainrot(thief)
		thief.state = "flee"
		thief.speed = thief.loot and LOOT_SPEED or RUN_SPEED
		thief.leg = #thief.path
	elseif thief.state == "flee" then
		thief.leg -= 1
		if thief.leg < 0 then
			-- back in the hideout: the loot is gone for good
			local loot = thief.loot
			if loot then
				thief.loot = nil
				local owner = thief.plot.owner
				BaseManager.loseBrainrot(loot)
				if owner then
					BaseManager.hooks.notify(owner, { kind = "stolen", title = "STOLEN!", body = loot.entry.name .. " is gone: -$" .. Catalog.formatCash(loot.income) .. "/s. Guard your base next wave!", color = RED })
				end
			end
			thief.state = "gone"
		end
	end
end

local function waypointOf(thief): Vector3
	if thief.state == "sneak" then
		return thief.sneakTo
	elseif thief.state == "flee" and thief.leg == 0 then
		return World.HIDEOUT_DOOR
	end
	return thief.path[thief.leg]
end

-- Every frame: run each thief along its path and check whether a player touched it.
local function moveThieves(dt: number)
	local now = os.clock()
	for index = #thieves, 1, -1 do
		local thief = thieves[index]
		if thief.state == "out" then
			local t = now - thief.outAt
			thief.root.CFrame = CFrame.new(thief.position + Vector3.new(0, 0.5 + t * 26, 0)) * CFrame.Angles(t * 14, t * 9, 0)
			if t > 0.8 then
				thief.state = "gone"
			end
		elseif thief.state ~= "gone" then
			local goal = waypointOf(thief)
			local offset = goal - thief.position
			local step = thief.speed * dt
			if offset.Magnitude <= step then
				thief.position = goal
				reachedWaypoint(thief)
			else
				thief.position += offset.Unit * step
				local bob = math.abs(math.sin(now * 11 + thief.phase)) * 0.6
				local flat = Vector3.new(offset.X, 0, offset.Z)
				if flat.Magnitude > 0.01 then
					thief.root.CFrame = CFrame.lookAt(thief.position, thief.position + flat.Unit) * CFrame.new(0, 0.5 + bob, 0) * CFrame.Angles(math.rad(-10), 0, 0)
				end
			end
			if thief.state ~= "out" and thief.state ~= "gone" then
				for _, player in Players:GetPlayers() do
					local character = player.Character
					local rootPart = character and character:FindFirstChild("HumanoidRootPart")
					if rootPart and ((rootPart.Position - thief.position) * Vector3.new(1, 0, 1)).Magnitude < BONK_RADIUS then
						knockOutThief(thief, player)
						break
					end
				end
			end
		end
		if thief.state == "gone" then
			table.remove(thieves, index)
			thief.model:Destroy()
		end
	end
end

-- Robbing a rival has a price: they send snatchers straight at the robber's base.
function ThiefAI.sendRevengeRaid(player: Player, count: number)
	task.delay(4, function()
		local plot = BaseManager.plotOf(player)
		if not plot then
			return
		end
		for _ = 1, math.clamp(count, 1, 3) do
			ThiefAI.sendThiefToBase(plot)
			task.wait(1.4)
		end
	end)
end

local function randomRivalPlot()
	local rivals = {}
	for _, plot in BaseManager.allPlots() do
		if not plot.owner and #plot.creatures > 0 then
			table.insert(rivals, plot)
		end
	end
	return #rivals > 0 and rivals[math.random(#rivals)] or nil
end

local function setWavePhase(phase: string, seconds: number)
	workspace:SetAttribute("WavePhase", phase)
	workspace:SetAttribute("WaveEndsAt", workspace:GetServerTimeNow() + seconds)
	workspace:SetAttribute("WaveNumber", waveNumber)
end

-- The wave clock: calm (lone thieves pester the rivals) -> "THIEF WAVE INCOMING" -> the raid.
function ThiefAI.runThiefWaves()
	local calm = FIRST_CALM_SECONDS
	while true do
		setWavePhase("calm", calm)
		local calmEnds = os.clock() + calm
		while os.clock() < calmEnds do
			task.wait(math.min(14, math.max(0.5, calmEnds - os.clock())))
			local rival = randomRivalPlot()
			if rival and os.clock() < calmEnds - 4 then
				ThiefAI.sendThiefToBase(rival)
			end
		end
		calm = CALM_SECONDS

		setWavePhase("warn", WARN_SECONDS)
		task.wait(WARN_SECONDS)

		waveNumber += 1
		setWavePhase("raid", RAID_MAX_SECONDS)
		local perBase = math.min(1 + math.floor(waveNumber / 2), 4)
		for round = 1, perBase do
			for _, player in Players:GetPlayers() do
				local plot = BaseManager.plotOf(player)
				-- thieves leave a brand-new base alone until it holds at least two brainrots
				if plot and #plot.creatures >= 2 then
					ThiefAI.sendThiefToBase(plot)
				end
			end
			if round <= 2 then
				local rival = randomRivalPlot()
				if rival then
					ThiefAI.sendThiefToBase(rival)
				end
			end
			task.wait(1.6)
		end
		local raidEnds = os.clock() + RAID_MAX_SECONDS
		while #thieves > 0 and os.clock() < raidEnds do
			task.wait(0.5)
		end
	end
end

function ThiefAI.start(world)
	thiefFolder = world.folder.Thieves
	RunService.Heartbeat:Connect(moveThieves)
	task.spawn(ThiefAI.runThiefWaves)
end

return ThiefAI
