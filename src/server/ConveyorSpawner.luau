-- ConveyorSpawner: the supply side of the bazaar. The Brainrot-O-Matic drops a random brainrot
-- (weighted by rarity, sometimes mutated) onto the moving conveyor; players buy one as it rides
-- past and carry it home. Unsold ones fall into the Recycler. Free common strays also wander
-- the plaza and can be caught by hand.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local World = require(script.Parent.BazaarWorld)
local Builder = require(script.Parent.BrainrotBuilder)
local Economy = require(script.Parent.Economy)
local BaseManager = require(script.Parent.BaseManager)

local Spawner = {}

local BELT_SPEED = 7 -- studs a second
local DROP_EVERY = 2.6 -- seconds between brainrots
local STRAY_COUNT = 6

local conveyorFolder: Folder
local strayFolder: Folder
local riding = {} -- brainrots on the belt: { model, entry, mutation, price, x, phase }
local strays = {} -- wandering free commons: { model, entry, position, target, side, pauseUntil, phase }

-- A player pays the price and walks off with the brainrot above their head.
function Spawner.buyBrainrotFromConveyor(player: Player, item)
	if not table.find(riding, item) then
		return
	end
	if not BaseManager.plotOf(player) then
		return
	end
	if BaseManager.isCarrying(player) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Hands full!", body = "Carry your brainrot home first", color = Color3.fromRGB(255, 90, 90) })
		return
	end
	if not Economy.trySpend(player, item.price) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Not enough cash", body = item.entry.name .. " costs $" .. Catalog.formatCash(item.price), color = Color3.fromRGB(255, 90, 90) })
		return
	end
	if not BaseManager.giveCarriedBrainrot(player, item.entry, item.mutation, 1) then
		Economy.addCash(player, item.price)
		return
	end
	table.remove(riding, table.find(riding, item))
	item.model:Destroy()
	BaseManager.hooks.notify(player, {
		kind = "bought",
		title = "Bought " .. (item.mutation and item.mutation .. " " or "") .. item.entry.name .. "!",
		body = string.upper(item.entry.rarity) .. "  •  Carry it to your base to start earning",
		color = Catalog.Rarities[item.entry.rarity].color,
	})
end

-- Rolls which brainrot comes out next: a rarity by weight, then a creature of it, then maybe a mutation.
function Spawner.rollBrainrot()
	local total = 0
	for _, name in Catalog.RarityOrder do
		total += Catalog.Rarities[name].weight
	end
	local roll = math.random() * total
	local rarityName = Catalog.RarityOrder[1]
	for _, name in Catalog.RarityOrder do
		roll -= Catalog.Rarities[name].weight
		if roll <= 0 then
			rarityName = name
			break
		end
	end
	local pool = Catalog.ByRarity[rarityName]
	local entry = pool[math.random(#pool)]
	local mutation
	local chance = math.random()
	for _, option in Catalog.Mutations do
		chance -= option.chance
		if chance <= 0 then
			mutation = option.id
			break
		end
	end
	return entry, mutation
end

local function beltCFrame(x: number, phase: number): CFrame
	local wobble = math.sin(os.clock() * 3 + phase) * 0.07
	return CFrame.new(x, World.BELT_Y, 0) * CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(0, wobble * 2, wobble)
end

-- Builds a brainrot at the machine's mouth (or anywhere along the belt when pre-filling it).
function Spawner.dropBrainrotOnConveyor(atX: number?)
	local entry, mutation = Spawner.rollBrainrot()
	local price = Catalog.priceOf(entry, mutation)
	local model = Builder.buildBrainrotModel(entry, mutation)
	Builder.setBrainrotLabel(model, { mutation = mutation, income = Catalog.incomePerSecond(entry, mutation, 1), price = price })
	local item = { model = model, entry = entry, mutation = mutation, price = price, x = atX or World.BELT_START_X, phase = math.random() * 6 }
	model:PivotTo(beltCFrame(item.x, item.phase))
	model.Parent = conveyorFolder
	local prompt = Builder.addPrompt(model, "Buy", "Buy", entry.name .. "  $" .. Catalog.formatCash(price), 0, Enum.KeyCode.E)
	prompt.Triggered:Connect(function(who)
		Spawner.buyBrainrotFromConveyor(who, item)
	end)
	table.insert(riding, item)
end

-- Every frame: slide each brainrot along the belt; the Recycler eats what reaches the end.
local function moveConveyor(dt: number)
	for index = #riding, 1, -1 do
		local item = riding[index]
		item.x += BELT_SPEED * dt
		if item.x >= World.BELT_END_X then
			table.remove(riding, index)
			item.model:Destroy()
		else
			item.model.PrimaryPart.CFrame = beltCFrame(item.x, item.phase) * CFrame.new(0, 0.5, 0)
		end
	end
end

local function randomPlazaPoint(side: number): Vector3
	return Vector3.new(math.random(-76, 78), World.GROUND_Y, side * math.random(9, 21))
end

-- A free common brainrot that hops around the plaza until somebody catches it.
function Spawner.spawnWanderingStray()
	local pool = Catalog.ByRarity.Common
	local entry = pool[math.random(#pool)]
	local side = math.random() < 0.5 and -1 or 1
	local model = Builder.buildBrainrotModel(entry, nil)
	Builder.setBrainrotLabel(model, { income = entry.income, tag = "STRAY - FREE!" })
	local stray = { model = model, entry = entry, side = side, position = randomPlazaPoint(side), target = randomPlazaPoint(side), pauseUntil = 0, phase = math.random() * 6 }
	model:PivotTo(CFrame.new(stray.position))
	model.Parent = strayFolder
	local prompt = Builder.addPrompt(model, "Catch", "Catch", "Stray " .. entry.name .. " (free)", 0.5, Enum.KeyCode.E)
	prompt.Triggered:Connect(function(who)
		Spawner.catchStray(who, stray)
	end)
	table.insert(strays, stray)
end

function Spawner.catchStray(player: Player, stray)
	local at = table.find(strays, stray)
	if not at then
		return
	end
	if not BaseManager.giveCarriedBrainrot(player, stray.entry, nil, 1) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Hands full!", body = "Carry your brainrot home first", color = Color3.fromRGB(255, 90, 90) })
		return
	end
	table.remove(strays, at)
	stray.model:Destroy()
	BaseManager.hooks.notify(player, { kind = "bought", title = "Caught a stray " .. stray.entry.name .. "!", body = "Free brainrot. Carry it home!", color = Catalog.Rarities.Common.color })
	task.delay(12, Spawner.spawnWanderingStray)
end

local function moveStrays(dt: number)
	local now = os.clock()
	for _, stray in strays do
		if now >= stray.pauseUntil then
			local offset = stray.target - stray.position
			if offset.Magnitude < 1 then
				stray.pauseUntil = now + math.random(1, 3)
				stray.target = randomPlazaPoint(stray.side)
			else
				stray.position += offset.Unit * math.min(5 * dt, offset.Magnitude)
				local hop = math.abs(math.sin(now * 7 + stray.phase)) * 0.9
				stray.model.PrimaryPart.CFrame = CFrame.lookAt(stray.position, stray.position + offset.Unit) * CFrame.new(0, 0.5 + hop, 0)
			end
		end
	end
end

-- Starts the belt, pre-fills it so the bazaar is busy from the first second, and releases the strays.
function Spawner.start(world)
	conveyorFolder = world.folder.Conveyor
	strayFolder = world.folder.Strays
	for x = World.BELT_START_X + 14, World.BELT_END_X - 10, BELT_SPEED * DROP_EVERY do
		Spawner.dropBrainrotOnConveyor(x)
	end
	for _ = 1, STRAY_COUNT do
		Spawner.spawnWanderingStray()
	end
	RunService.Heartbeat:Connect(function(dt)
		moveConveyor(dt)
		moveStrays(dt)
	end)
	task.spawn(function()
		while true do
			task.wait(DROP_EVERY)
			Spawner.dropBrainrotOnConveyor()
		end
	end)
end

return Spawner
