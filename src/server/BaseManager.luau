-- BaseManager: owns every base plot and every brainrot standing on one.
-- It hands a plot to each player (NPC rivals keep the rest stocked), carries a bought brainrot
-- above the player's head, places it on a free pad when they reach home, and handles pads,
-- upgrades, selling, the base lock and what happens when a brainrot is grabbed, returned or lost.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local Builder = require(script.Parent.BrainrotBuilder)
local Economy = require(script.Parent.Economy)

local BaseManager = {}

-- filled in by the server script before any player joins:
--   notify(player, payload) shows a popup, onRivalRobbed(player, plot, rank) sends revenge, onBaseLocked(plot) zaps thieves
BaseManager.hooks = {}

local plots = {}
local worldFolder: Folder
local plotOfPlayer = {} -- [Player] = plot
local carried = {} -- [Player] = { entry, mutation, level, model }

local CLAIM_ORDER = { 2, 6, 3, 7, 1, 5, 4, 8 }
local RIVAL_NAMES = { "GrannyGrindset", "SigmaToaster99", "CaptainRizzbeard", "xX_NoodleKing_Xx", "MoldyMogul", "BeanTycoon42", "LordOfSocks", "DJ_Pigeonhands" }
local RIVAL_STOCK = {
	{ "noodlino", "toasty", "cactopus", "sockpuppeto", "conehead" },
	{ "toasty", "sockpuppeto", "bananaphone", "noodlino" },
	{ "sockpuppeto", "cactopus", "noodlino", "toasty", "fridgezilla", "conehead" },
	{ "conehead", "noodlino", "toasty", "spinnerino", "bananaphone" },
	{ "bananaphone", "toasty", "cactopus", "noodlino", "discopigeon", "sockpuppeto" },
	{ "noodlino", "conehead", "sockpuppeto", "fridgezilla" },
	{ "cactopus", "toasty", "bananaphone", "kaboomba", "noodlino" },
	{ "sockpuppeto", "noodlino", "spinnerino", "toasty", "conehead" },
}

local rarityColor

-- Places a carried brainrot on the first free pad of the player's base: from now on it earns money.
function BaseManager.placeCarriedOnPad(player: Player): boolean
	local load = carried[player]
	local plot = plotOfPlayer[player]
	if not load or not plot then
		return false
	end
	local pad = BaseManager.freePadOf(plot)
	if not pad then
		return false
	end
	carried[player] = nil
	load.model:Destroy()
	player:SetAttribute("Carrying", "")
	local record = BaseManager.addBrainrotToPad(plot, pad, load.entry, load.mutation, load.level)
	Economy.markDiscovered(player, load.entry.id)
	BaseManager.hooks.notify(player, {
		kind = "placed",
		title = load.entry.name .. " is home!",
		body = "+$" .. Catalog.formatCash(record.income * Economy.multiplierOf(player)) .. "/s  •  " .. load.entry.quip,
		color = rarityColor(load.entry),
	})
	return true
end

function rarityColor(entry): Color3
	return Catalog.Rarities[entry.rarity].color
end

-- Total $/s of a base: grabbed brainrots earn nothing until they are back on their pad.
function BaseManager.incomeOfBase(plot): number
	local total = 0
	for _, record in plot.creatures do
		if not record.grabbed then
			total += record.income
		end
	end
	return total
end

function BaseManager.freePadOf(plot)
	for n = 1, plot.unlockedPads do
		if not plot.pads[n].record then
			return plot.pads[n]
		end
	end
	return nil
end

-- Repaints pads, the gate sign and the owner's HUD numbers after anything on the base changed.
function BaseManager.refreshBase(plot)
	local owner: Player? = plot.owner
	for n, pad in plot.pads do
		local unlocked = n <= plot.unlockedPads
		pad.part.Color = unlocked and plot.color or Color3.fromRGB(60, 56, 80)
		pad.part.Material = Enum.Material.SmoothPlastic
		local buyPrompt = pad.part:FindFirstChild("BuyPad")
		if buyPrompt then
			buyPrompt:Destroy()
		end
		if unlocked then
			pad.tag.Text = ""
		elseif n == plot.unlockedPads + 1 and owner then
			pad.tag.Text = "NEW PAD $" .. Catalog.formatCash(Catalog.PadPrices[n])
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "BuyPad"
			prompt.ActionText = "Unlock pad"
			prompt.ObjectText = "$" .. Catalog.formatCash(Catalog.PadPrices[n])
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = pad.part
			prompt.Triggered:Connect(function(who)
				if who == plot.owner then
					BaseManager.unlockNextPad(who)
				end
			end)
		else
			pad.tag.Text = "LOCKED"
		end
	end
	local income = BaseManager.incomeOfBase(plot)
	local ownerName = owner and owner.DisplayName or plot.rivalName
	local shownIncome = income * (owner and Economy.multiplierOf(owner) or 1)
	plot.ownerLabel.Text = string.upper(ownerName) .. "'S BASE\n$" .. Catalog.formatCash(shownIncome) .. "/s"
	for _, gui in plot.ownerBoard:GetChildren() do
		if gui:IsA("SurfaceGui") then
			gui.Text.Text = plot.ownerLabel.Text
			gui.Text.TextColor3 = owner and Color3.fromRGB(255, 236, 130) or Color3.fromRGB(255, 255, 255)
		end
	end
	if owner then
		Economy.setBaseIncome(owner, income)
		owner:SetAttribute("Brainrots", #plot.creatures)
		owner:SetAttribute("Pads", plot.unlockedPads)
	end
end

local function relabel(record)
	local owner = record.plot.owner
	Builder.setBrainrotLabel(record.model, {
		mutation = record.mutation,
		income = record.income * (owner and Economy.multiplierOf(owner) or 1),
		level = record.level,
	})
end

-- Prompts on a brainrot that stands on a pad: the owner upgrades or sells, anyone can rob a rival.
local function addPadPrompts(record)
	local plot = record.plot
	Builder.clearPrompts(record.model)
	if plot.owner then
		if record.level < Catalog.MaxLevel then
			local upgrade = Builder.addPrompt(record.model, "Upgrade", "Upgrade to Lv " .. (record.level + 1), "$" .. Catalog.formatCash(Catalog.upgradeCost(record.entry, record.level)), 0.3, Enum.KeyCode.E)
			upgrade.Triggered:Connect(function(who)
				if who == plot.owner then
					BaseManager.upgradeBrainrot(who, record)
				end
			end)
		end
		local sell = Builder.addPrompt(record.model, "Sell", "Sell", "+$" .. Catalog.formatCash(Catalog.priceOf(record.entry, record.mutation) * 0.5), 1.2, Enum.KeyCode.R, -80)
		sell.Triggered:Connect(function(who)
			if who == plot.owner then
				BaseManager.sellBrainrot(who, record)
			end
		end)
	else
		local rank = Catalog.Rarities[record.entry.rarity].rank
		local steal = Builder.addPrompt(record.model, "Steal", "Steal", record.entry.name, 0.8 + rank * 0.6, Enum.KeyCode.E)
		steal.Triggered:Connect(function(who)
			BaseManager.stealFromRival(who, record)
		end)
	end
end

-- Stands a brainrot on a pad of a base and starts counting its income.
function BaseManager.addBrainrotToPad(plot, pad, entry, mutation: string?, level: number)
	local model = Builder.buildBrainrotModel(entry, mutation)
	model:PivotTo(pad.cf)
	model.Parent = plot.brainrotFolder
	local record = {
		entry = entry,
		mutation = mutation,
		level = level,
		income = Catalog.incomePerSecond(entry, mutation, level),
		model = model,
		plot = plot,
		pad = pad,
		grabbed = false,
	}
	pad.record = record
	table.insert(plot.creatures, record)
	relabel(record)
	addPadPrompts(record)
	BaseManager.refreshBase(plot)
	return record
end

local function removeRecord(record)
	local plot = record.plot
	local at = table.find(plot.creatures, record)
	if at then
		table.remove(plot.creatures, at)
	end
	if record.pad.record == record then
		record.pad.record = nil
	end
	record.model:Destroy()
	BaseManager.refreshBase(plot)
end

-- Spend cash to raise a brainrot's level: +50% of its base income per level, up to MaxLevel.
function BaseManager.upgradeBrainrot(player: Player, record)
	if record.grabbed or record.level >= Catalog.MaxLevel then
		return
	end
	local cost = Catalog.upgradeCost(record.entry, record.level)
	if not Economy.trySpend(player, cost) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Not enough cash", body = "Upgrade costs $" .. Catalog.formatCash(cost), color = Color3.fromRGB(255, 90, 90) })
		return
	end
	record.level += 1
	record.income = Catalog.incomePerSecond(record.entry, record.mutation, record.level)
	record.model:ScaleTo(1 + 0.07 * (record.level - 1)) -- upgraded brainrots visibly grow
	relabel(record)
	addPadPrompts(record)
	BaseManager.refreshBase(record.plot)
	BaseManager.hooks.notify(player, { kind = "upgrade", title = record.entry.name .. " is now Lv " .. record.level, body = "Now earning $" .. Catalog.formatCash(record.income * Economy.multiplierOf(player)) .. "/s", color = rarityColor(record.entry) })
end

function BaseManager.sellBrainrot(player: Player, record)
	if record.grabbed or not table.find(record.plot.creatures, record) then
		return
	end
	local refund = math.floor(Catalog.priceOf(record.entry, record.mutation) * 0.5)
	removeRecord(record)
	Economy.addCash(player, refund)
	BaseManager.hooks.notify(player, { kind = "sold", title = "Sold " .. record.entry.name, body = "+$" .. Catalog.formatCash(refund), color = Color3.fromRGB(120, 255, 140) })
end

-- Buy the next pad: more pads, more brainrots earning at once.
function BaseManager.unlockNextPad(player: Player)
	local plot = plotOfPlayer[player]
	if not plot or plot.unlockedPads >= #plot.pads then
		return
	end
	local cost = Catalog.PadPrices[plot.unlockedPads + 1]
	if not Economy.trySpend(player, cost) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Not enough cash", body = "This pad costs $" .. Catalog.formatCash(cost), color = Color3.fromRGB(255, 90, 90) })
		return
	end
	plot.unlockedPads += 1
	BaseManager.refreshBase(plot)
	BaseManager.hooks.notify(player, { kind = "upgrade", title = "Pad " .. plot.unlockedPads .. " unlocked!", body = "Room for one more brainrot", color = plot.color })
end

-- Puts a freshly bought, caught or stolen brainrot above the player's head. Run home!
function BaseManager.giveCarriedBrainrot(player: Player, entry, mutation: string?, level: number): boolean
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if carried[player] or not rootPart or not plotOfPlayer[player] then
		return false
	end
	local model = Builder.buildBrainrotModel(entry, mutation, Builder.CARRIED_SIZE)
	Builder.setBrainrotLabel(model, { mutation = mutation, income = Catalog.incomePerSecond(entry, mutation, level), tag = "RUN HOME!" })
	model:PivotTo(rootPart.CFrame * CFrame.new(0, 2.9, 0))
	local root = model.PrimaryPart
	root.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = root
	weld.Parent = root
	model.Parent = worldFolder.Carried
	carried[player] = { entry = entry, mutation = mutation, level = level, model = model }
	player:SetAttribute("Carrying", entry.name)
	return true
end

function BaseManager.isCarrying(player: Player): boolean
	return carried[player] ~= nil
end

function BaseManager.dropCarried(player: Player)
	local load = carried[player]
	if load then
		carried[player] = nil
		load.model:Destroy()
		player:SetAttribute("Carrying", "")
	end
end

-- Robbing an NPC rival's base: free loot, but the rival sends a revenge raid after you.
function BaseManager.stealFromRival(player: Player, record)
	local plot = record.plot
	if plot.owner or record.grabbed or not table.find(plot.creatures, record) then
		return
	end
	if not BaseManager.giveCarriedBrainrot(player, record.entry, record.mutation, 1) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Hands full!", body = "Take your brainrot home first", color = Color3.fromRGB(255, 90, 90) })
		return
	end
	local pad = record.pad
	removeRecord(record)
	BaseManager.restockRivalLater(plot, pad)
	BaseManager.hooks.notify(player, { kind = "steal", title = "You stole " .. record.entry.name .. "!", body = plot.rivalName .. " is sending a REVENGE RAID. Run home!", color = rarityColor(record.entry) })
	BaseManager.hooks.onRivalRobbed(player, plot, Catalog.Rarities[record.entry.rarity].rank)
end

-- An emptied rival pad gets a new common or rare brainrot after a while, so rival bases stay stocked.
function BaseManager.restockRivalLater(plot, pad)
	task.delay(40, function()
		if not plot.owner and not pad.record and pad.index <= plot.unlockedPads then
			local pool = Catalog.ByRarity[math.random() < 0.65 and "Common" or "Rare"]
			BaseManager.addBrainrotToPad(plot, pad, pool[math.random(#pool)], nil, 1)
		end
	end)
end

local function stockRivalBase(plot)
	plot.unlockedPads = 6
	for n, id in RIVAL_STOCK[plot.index] do
		local mutation = (n == 2 and plot.index % 2 == 0) and "Golden" or (n == 3 and plot.index % 3 == 0) and "Radioactive" or nil
		BaseManager.addBrainrotToPad(plot, plot.pads[n], Catalog.ById[id], mutation, 1)
	end
	BaseManager.refreshBase(plot)
end

local function clearBase(plot)
	for _, record in table.clone(plot.creatures) do
		removeRecord(record)
	end
end

function BaseManager.isInsideBase(plot, position: Vector3): boolean
	local at = plot.origin:PointToObjectSpace(position)
	return math.abs(at.X) < 17 and math.abs(at.Z) < 16.5
end

function BaseManager.isLocked(plot): boolean
	return workspace:GetServerTimeNow() < plot.lockUntil
end

local function showShield(plot, on: boolean)
	plot.shield.Transparency = on and 0.72 or 1
	for _, bar in plot.bars do
		bar.Transparency = on and 0 or 1
	end
	plot.lockButton.Color = on and Color3.fromRGB(80, 230, 255) or Color3.fromRGB(255, 50, 60)
end

-- LOCK BASE: a shield drops for a few seconds, thieves bounce off and drop their loot. Has a cooldown,
-- and only works while you stand in your own base, so you have to dash home to use it.
function BaseManager.tryLockBase(player: Player): boolean
	local plot = plotOfPlayer[player]
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not rootPart then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now < plot.lockReadyAt then
		return false
	end
	if not BaseManager.isInsideBase(plot, rootPart.Position) then
		BaseManager.hooks.notify(player, { kind = "error", title = "Get home first!", body = "You can only lock the base from inside it", color = Color3.fromRGB(255, 90, 90) })
		return false
	end
	plot.lockUntil = now + Catalog.LockSeconds
	plot.lockReadyAt = now + Catalog.LockCooldown
	player:SetAttribute("LockUntil", plot.lockUntil)
	player:SetAttribute("LockReadyAt", plot.lockReadyAt)
	showShield(plot, true)
	task.delay(Catalog.LockSeconds, function()
		if workspace:GetServerTimeNow() >= plot.lockUntil - 0.1 then
			showShield(plot, false)
		end
	end)
	BaseManager.hooks.onBaseLocked(plot)
	BaseManager.hooks.notify(player, { kind = "lock", title = "BASE LOCKED!", body = "Thieves bounce off for " .. Catalog.LockSeconds .. " seconds", color = Color3.fromRGB(80, 230, 255) })
	return true
end

-- The most valuable brainrot on a base that no thief is holding yet: what a thief goes for.
function BaseManager.bestBrainrotOf(plot)
	local best
	for _, record in plot.creatures do
		if not record.grabbed and (not best or record.income > best.income) then
			best = record
		end
	end
	return best
end

-- A thief lifts the brainrot off its pad. It stops earning until it is returned.
function BaseManager.grabBrainrot(record, carrier: BasePart)
	record.grabbed = true
	Builder.clearPrompts(record.model)
	local root = record.model.PrimaryPart
	record.model:PivotTo(carrier.CFrame * CFrame.new(0, 7.4, 0.6))
	root.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Name = "ThiefGrip"
	weld.Part0 = carrier
	weld.Part1 = root
	weld.Parent = root
	Builder.setBrainrotLabel(record.model, { mutation = record.mutation, income = record.income, tag = "HELP! STOLEN!" })
	BaseManager.refreshBase(record.plot)
end

-- The thief got bonked or zapped: the brainrot pops back onto its pad and earns again.
function BaseManager.returnBrainrotToPad(record)
	if not record.grabbed then
		return
	end
	record.grabbed = false
	local root = record.model.PrimaryPart
	local grip = root:FindFirstChild("ThiefGrip")
	if grip then
		grip:Destroy()
	end
	root.Anchored = true
	record.model:PivotTo(record.pad.cf)
	relabel(record)
	addPadPrompts(record)
	BaseManager.refreshBase(record.plot)
end

-- The thief reached the hideout: the brainrot is gone for good.
function BaseManager.loseBrainrot(record)
	local plot, pad = record.plot, record.pad
	removeRecord(record)
	if not plot.owner then
		BaseManager.restockRivalLater(plot, pad)
	end
end

-- Rebirth wipes the base's brainrots (pads stay); the multiplier makes the climb back faster.
function BaseManager.wipeForRebirth(player: Player)
	local plot = plotOfPlayer[player]
	if plot then
		clearBase(plot)
		BaseManager.refreshBase(plot)
	end
end

function BaseManager.plotOf(player: Player)
	return plotOfPlayer[player]
end

function BaseManager.allPlots()
	return plots
end

-- Where a player (re)spawns: just inside their own gate, looking at their pads.
function BaseManager.spawnPointOf(player: Player): CFrame?
	local plot = plotOfPlayer[player]
	return plot and plot.origin * CFrame.new(0, 3.5, -11) * CFrame.Angles(0, math.rad(180), 0) or nil
end

-- Gives the joining player the next free plot (evicting the NPC rival that kept it warm).
function BaseManager.claimPlotFor(player: Player)
	for _, index in CLAIM_ORDER do
		local plot = plots[index]
		if not plot.owner then
			clearBase(plot)
			plot.owner = player
			plot.unlockedPads = Catalog.StartingPads
			plot.lockUntil, plot.lockReadyAt = 0, 0
			plotOfPlayer[player] = plot
			player:SetAttribute("PlotIndex", index)
			player:SetAttribute("LockUntil", 0)
			player:SetAttribute("LockReadyAt", 0)
			player:SetAttribute("Carrying", "")
			plot.folder:SetAttribute("Owner", player.Name)
			BaseManager.refreshBase(plot)
			return plot
		end
	end
	return nil
end

function BaseManager.releasePlot(player: Player)
	BaseManager.dropCarried(player)
	local plot = plotOfPlayer[player]
	if plot then
		plotOfPlayer[player] = nil
		plot.owner = nil
		plot.folder:SetAttribute("Owner", nil)
		clearBase(plot)
		showShield(plot, false)
		stockRivalBase(plot)
	end
end

-- Every fifth of a second: any player carrying a brainrot who steps into their base places it.
function BaseManager.watchCarriersReachHome()
	local lastFullNotice = {}
	while true do
		task.wait(0.2)
		for player, load in carried do
			local plot = plotOfPlayer[player]
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if plot and rootPart and BaseManager.isInsideBase(plot, rootPart.Position) then
				if not BaseManager.placeCarriedOnPad(player) and os.clock() - (lastFullNotice[player] or 0) > 4 then
					lastFullNotice[player] = os.clock()
					BaseManager.hooks.notify(player, { kind = "error", title = "No free pad!", body = "Unlock a pad or sell a brainrot (hold R)", color = Color3.fromRGB(255, 90, 90) })
				end
			elseif not rootPart then
				BaseManager.dropCarried(player)
			end
		end
	end
end

function BaseManager.init(world)
	worldFolder = world.folder
	for index, built in world.plots do
		local plot = built
		plot.owner = nil
		plot.rivalName = RIVAL_NAMES[index]
		plot.creatures = {}
		plot.unlockedPads = 6
		plot.lockUntil, plot.lockReadyAt = 0, 0
		plots[index] = plot
		local lockPrompt = Instance.new("ProximityPrompt")
		lockPrompt.ActionText = "LOCK BASE"
		lockPrompt.ObjectText = "Big red button"
		lockPrompt.KeyboardKeyCode = Enum.KeyCode.F
		lockPrompt.MaxActivationDistance = 9
		lockPrompt.RequiresLineOfSight = false
		lockPrompt.Parent = plot.lockButton
		lockPrompt.Triggered:Connect(function(who)
			if who == plot.owner then
				BaseManager.tryLockBase(who)
			end
		end)
		stockRivalBase(plot)
	end
	Players.PlayerRemoving:Connect(BaseManager.releasePlot)
end

return BaseManager
