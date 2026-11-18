-- BRAINROT BAZAAR server entry. Builds the world, then wires the modules together:
--   BazaarWorld (map) -> BaseManager (plots + brainrots) -> ConveyorSpawner (supply) -> ThiefAI (threat),
--   with Economy as the only keeper of cash. The client sends two requests (LockBase, Rebirth)
--   and receives popups; everything else it reads from replicated attributes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)
local World = require(script.BazaarWorld)
local Economy = require(script.Economy)
local BaseManager = require(script.BaseManager)
local ConveyorSpawner = require(script.ConveyorSpawner)
local ThiefAI = require(script.ThiefAI)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Action"
actionRemote.Parent = remotes
local noticeRemote = Instance.new("RemoteEvent")
noticeRemote.Name = "Notice"
noticeRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

-- Rebirth: cash and brainrots reset, the income multiplier goes up by one for good.
local function rebirthPlayer(player: Player)
	local cost = Catalog.rebirthCost(player:GetAttribute("Rebirths") or 0)
	if not Economy.tryRebirth(player) then
		noticeRemote:FireClient(player, { kind = "error", title = "Not enough cash", body = "Rebirth costs $" .. Catalog.formatCash(cost), color = Color3.fromRGB(255, 90, 90) })
		return
	end
	BaseManager.dropCarried(player)
	BaseManager.wipeForRebirth(player)
	noticeRemote:FireClient(player, {
		kind = "rebirth",
		title = "REBIRTH! Income x" .. Economy.multiplierOf(player),
		body = "Everything you earn is multiplied forever. Rebuild the bazaar!",
		color = Color3.fromRGB(200, 120, 255),
	})
end

local function handleClientAction(player: Player, action: unknown)
	if not Economy.has(player) then
		return
	end
	if action == "LockBase" then
		BaseManager.tryLockBase(player)
	elseif action == "Rebirth" then
		rebirthPlayer(player)
	end
end

local function sendCharacterHome(player: Player, character: Model)
	local spawnAt = BaseManager.spawnPointOf(player)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if spawnAt and humanoid and rootPart then
		humanoid.WalkSpeed = 22
		task.wait()
		character:PivotTo(spawnAt)
	end
	if humanoid then
		humanoid.Died:Connect(function()
			BaseManager.dropCarried(player)
		end)
	end
end

local function welcomePlayer(player: Player)
	Economy.createProfile(player)
	local plot = BaseManager.claimPlotFor(player)
	if not plot then
		noticeRemote:FireClient(player, { kind = "error", title = "The bazaar is full", body = "Every base is taken. You can still bonk thieves for cash!", color = Color3.fromRGB(255, 90, 90) })
	end
	player.CharacterAdded:Connect(function(character)
		sendCharacterHome(player, character)
	end)
	if player.Character then
		task.spawn(sendCharacterHome, player, player.Character)
	end
	task.delay(3, function()
		if player.Parent then
			noticeRemote:FireClient(player, { kind = "tip", title = "Welcome to BRAINROT BAZAAR!", body = "Buy a brainrot off the conveyor (E) and carry it to your base", color = Color3.fromRGB(255, 226, 90) })
		end
	end)
end

local world = World.buildBazaarWorld()
BaseManager.hooks.notify = function(player: Player, payload)
	noticeRemote:FireClient(player, payload)
end
BaseManager.hooks.onRivalRobbed = function(player: Player, _plot, rank: number)
	ThiefAI.sendRevengeRaid(player, rank)
end
BaseManager.hooks.onBaseLocked = ThiefAI.zapThievesAt
BaseManager.init(world)
ConveyorSpawner.start(world)
ThiefAI.start(world)

actionRemote.OnServerEvent:Connect(handleClientAction)
Players.PlayerAdded:Connect(welcomePlayer)
for _, player in Players:GetPlayers() do
	task.spawn(welcomePlayer, player)
end
task.spawn(Economy.payIncomeEverySecond)
task.spawn(BaseManager.watchCarriersReachHome)

-- Studio-only test hook (never exists in a live server): lets a play test grant cash to check late-game states.
if RunService:IsStudio() then
	local debugHook = Instance.new("BindableEvent")
	debugHook.Name = "BazaarDebug"
	debugHook.Event:Connect(function(command: string, player: Player, value: any)
		if command == "cash" then
			Economy.addCash(player, value)
		elseif command == "give" then
			BaseManager.giveCarriedBrainrot(player, Catalog.ById[value], nil, 1)
		elseif command == "thief" then
			local plot = BaseManager.plotOf(player)
			if plot then
				ThiefAI.sendThiefToBase(plot)
			end
		end
	end)
	debugHook.Parent = ServerStorage
end
