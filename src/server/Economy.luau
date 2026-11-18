-- Economy: the single place every player's money lives. Cash, rebirths and the discovered
-- collection are kept in one profile table per player and mirrored to Player attributes,
-- which is all the client HUD ever reads. Nothing else in the game writes cash directly.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)

local Economy = {}

local profiles = {} -- [Player] = { cash, rebirths, income, discovered = { [id] = true } }

local publish

-- Pays every player their brainrots' income once a second: money ticking up at its rate.
function Economy.payIncomeEverySecond()
	while true do
		task.wait(1)
		for player, profile in profiles do
			if profile.income > 0 then
				profile.cash += profile.income * Economy.multiplierOf(player)
				profile.earned += profile.income * Economy.multiplierOf(player)
				publish(player)
			end
		end
	end
end

function publish(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	player:SetAttribute("Cash", profile.cash)
	player:SetAttribute("Income", profile.income * Economy.multiplierOf(player))
	player:SetAttribute("Rebirths", profile.rebirths)
	player:SetAttribute("RebirthCost", Catalog.rebirthCost(profile.rebirths))
end

function Economy.createProfile(player: Player)
	profiles[player] = { cash = Catalog.StartingCash, rebirths = 0, income = 0, earned = 0, discovered = {}, discoveredCount = 0 }
	player:SetAttribute("Discovered", "")
	publish(player)
end

function Economy.removeProfile(player: Player)
	profiles[player] = nil
end

function Economy.has(player: Player): boolean
	return profiles[player] ~= nil
end

function Economy.cashOf(player: Player): number
	return profiles[player] and profiles[player].cash or 0
end

-- Each rebirth adds +1x to all income, forever.
function Economy.multiplierOf(player: Player): number
	return 1 + (profiles[player] and profiles[player].rebirths or 0)
end

function Economy.addCash(player: Player, amount: number)
	local profile = profiles[player]
	if profile then
		profile.cash += amount
		publish(player)
	end
end

-- Takes the money only if the player can afford it. Every purchase in the game goes through here.
function Economy.trySpend(player: Player, cost: number): boolean
	local profile = profiles[player]
	if not profile or profile.cash < cost then
		return false
	end
	profile.cash -= cost
	publish(player)
	return true
end

-- BaseManager reports the base's total $/s whenever a brainrot is placed, upgraded, sold or stolen.
function Economy.setBaseIncome(player: Player, perSecond: number)
	local profile = profiles[player]
	if profile then
		profile.income = perSecond
		publish(player)
	end
end

-- Remembers each kind of brainrot the player has ever owned (the collection count on the HUD).
function Economy.markDiscovered(player: Player, brainrotId: string)
	local profile = profiles[player]
	if profile and not profile.discovered[brainrotId] then
		profile.discovered[brainrotId] = true
		profile.discoveredCount += 1
		local ids = {}
		for id in profile.discovered do
			table.insert(ids, id)
		end
		table.sort(ids)
		player:SetAttribute("Discovered", table.concat(ids, ","))
	end
end

-- Rebirth: pay the cost, lose your cash, keep a permanent +1x income multiplier.
function Economy.tryRebirth(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.cash < Catalog.rebirthCost(profile.rebirths) then
		return false
	end
	profile.rebirths += 1
	profile.cash = Catalog.StartingCash
	publish(player)
	return true
end

Players.PlayerRemoving:Connect(Economy.removeProfile)

return Economy
