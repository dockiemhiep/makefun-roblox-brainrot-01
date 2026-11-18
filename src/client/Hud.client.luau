-- Hud: the ScreenGui over the 3D bazaar. It only displays state the server replicates
-- (Player attributes for cash / income / lock / rebirth, Workspace attributes for the thief
-- wave) and sends two requests: LockBase and Rebirth. No game rules live on the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local HudKit = require(script.Parent:WaitForChild("HudKit"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionRemote = remotes:WaitForChild("Action")
local noticeRemote = remotes:WaitForChild("Notice")

local player = Players.LocalPlayer
local C = HudKit.Colors

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local screen = Instance.new("ScreenGui")
screen.Name = "BazaarHud"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")

-- Everything is laid out for 1280x720 and scaled as one piece to the real viewport.
local canvas = Instance.new("Frame")
canvas.Name = "Canvas"
canvas.BackgroundTransparency = 1
canvas.Parent = screen
local canvasScale = Instance.new("UIScale")
canvasScale.Parent = canvas
canvas.AnchorPoint = Vector2.new(0.5, 0.5)
canvas.Position = UDim2.fromScale(0.5, 0.5)
local function fitCanvasToViewport()
	local viewport = workspace.CurrentCamera.ViewportSize
	local width, height = viewport.X, viewport.Y
	-- Photo framing: with Workspace.PhotoFrame16x9 set, the HUD keeps to a centred 16:9 frame of a
	-- taller window, so a screenshot cropped to 16:9 still shows the whole interface.
	if workspace:GetAttribute("PhotoFrame16x9") and width / height < 16 / 9 then
		height = width * 9 / 16
	end
	local scale = math.clamp(math.min(width / 1280, height / 720), 0.45, 2)
	canvasScale.Scale = scale
	canvas.Size = UDim2.fromOffset(width / scale, height / scale)
end
fitCanvasToViewport()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitCanvasToViewport)
workspace:GetAttributeChangedSignal("PhotoFrame16x9"):Connect(fitCanvasToViewport)

local function commas(amount: number): string
	if amount >= 10000000 then
		return Catalog.formatCash(amount)
	end
	local text = tostring(math.floor(amount))
	local out = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- TOP CENTRE: the cash counter, income a second under it, then the collection chips. ------------
local cashPanel = HudKit.panel(canvas, "CashPanel", UDim2.fromOffset(380, 112), UDim2.new(0.5, 0, 0, 12), Vector2.new(0.5, 0))
local coin = HudKit.panel(cashPanel, "Coin", UDim2.fromOffset(72, 72), UDim2.new(0, 18, 0.5, 0), Vector2.new(0, 0.5), C.gold, 36)
HudKit.label(coin, "Sign", "$", 50, C.text)
local cashLabel = HudKit.label(cashPanel, "Cash", "$0", 54, C.text, UDim2.new(1, -112, 0, 60), UDim2.fromOffset(100, 6), Enum.TextXAlignment.Left)
local incomeLabel = HudKit.label(cashPanel, "Income", "+$0/s", 28, C.money, UDim2.new(1, -112, 0, 32), UDim2.fromOffset(102, 68), Enum.TextXAlignment.Left)

local chipRow = Instance.new("Frame")
chipRow.Name = "Chips"
chipRow.BackgroundTransparency = 1
chipRow.Size = UDim2.fromOffset(560, 34)
chipRow.Position = UDim2.new(0.5, 0, 0, 134)
chipRow.AnchorPoint = Vector2.new(0.5, 0)
chipRow.Parent = canvas
local chipLayout = Instance.new("UIListLayout")
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
chipLayout.Padding = UDim.new(0, 10)
chipLayout.Parent = chipRow
local function makeChip(name: string, width: number, color: Color3): TextLabel
	local chip = HudKit.panel(chipRow, name, UDim2.fromOffset(width, 34), UDim2.new(), nil, nil, 17)
	chip.Edge.Thickness = 2
	return HudKit.label(chip, "Text", "", 19, color)
end
local brainrotChip = makeChip("BrainrotChip", 170, C.text)
local collectionChip = makeChip("CollectionChip", 190, C.gold)
local rebirthChip = makeChip("RebirthChip", 150, C.rebirth)

-- THIEF WAVE banner: a quiet countdown that turns into a big red warning. --------------------------
-- While calm it is a small clock in the top-right corner; the warning and the raid take centre stage.
local wavePanel = HudKit.panel(canvas, "WaveBanner", UDim2.fromOffset(300, 46), UDim2.new(1, -14, 0, 12), Vector2.new(1, 0), nil, 20)
local waveLabel = HudKit.label(wavePanel, "Text", "", 22, C.text)

-- BOTTOM BAR: Lock Base and Rebirth. -----------------------------------------------------------------
local lockKit = HudKit.bigButton(canvas, "LockBaseButton", "LOCK BASE", C.lock, UDim2.new(0.5, -135, 1, -16))
local rebirthKit = HudKit.bigButton(canvas, "RebirthButton", "REBIRTH", C.rebirth, UDim2.new(0.5, 135, 1, -16))
local carryPanel = HudKit.panel(canvas, "CarryBanner", UDim2.fromOffset(660, 46), UDim2.new(0.5, 0, 1, -104), Vector2.new(0.5, 1), C.gold, 23)
local carryLabel = HudKit.label(carryPanel, "Text", "", 24, C.text)
carryPanel.Visible = false

-- LEFT: the rarity ladder with how many of each tier you have discovered. -------------------------
local ladder = HudKit.panel(canvas, "RarityLadder", UDim2.fromOffset(196, 206), UDim2.new(0, 14, 0.5, -20), Vector2.new(0, 0.5))
HudKit.label(ladder, "Title", "BRAINDEX", 22, C.gold, UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 8))
local ladderRows = {}
for index, rarityName in Catalog.RarityOrder do
	local y = 8 + index * 31
	HudKit.label(ladder, rarityName, string.upper(rarityName), 20, Catalog.Rarities[rarityName].color, UDim2.new(0, 120, 0, 26), UDim2.fromOffset(14, y), Enum.TextXAlignment.Left)
	ladderRows[rarityName] = HudKit.label(ladder, rarityName .. "Count", "0/0", 20, C.text, UDim2.new(0, 50, 0, 26), UDim2.new(1, -64, 0, y), Enum.TextXAlignment.Right)
end

-- RIGHT: popups, coloured by rarity (or red for thieves). ----------------------------------------
local toastColumn = Instance.new("Frame")
toastColumn.Name = "Toasts"
toastColumn.BackgroundTransparency = 1
toastColumn.Size = UDim2.fromOffset(360, 400)
toastColumn.Position = UDim2.new(1, -14, 0, 70)
toastColumn.AnchorPoint = Vector2.new(1, 0)
toastColumn.Parent = canvas
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 10)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastColumn
local toastOrder = 0

-- Shows a popup: bought / placed / stolen / bonk / upgrade, in the colour the server sends.
local function showPopup(payload)
	toastOrder += 1
	local color: Color3 = payload.color or C.text
	local toast = HudKit.panel(toastColumn, "Toast", UDim2.fromOffset(360, 92), UDim2.new(), nil, color:Lerp(C.ink, 0.72), 16)
	toast.LayoutOrder = toastOrder
	toast.Edge.Color = color
	toast.Edge.Transparency = 0
	local title = HudKit.label(toast, "Title", payload.title or "", 23, color, UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 8), Enum.TextXAlignment.Left)
	title.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 23
	limit.MinTextSize = 14
	limit.Parent = title
	local body = HudKit.label(toast, "Body", payload.body or "", 17, C.text, UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, 40), Enum.TextXAlignment.Left)
	body.TextWrapped = true
	body.TextTruncate = Enum.TextTruncate.None
	body.TextYAlignment = Enum.TextYAlignment.Top
	local toasts = {}
	for _, child in toastColumn:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for index = 1, #toasts - 4 do
		toasts[index]:Destroy()
	end
	task.delay(payload.kind == "stolen" and 6 or 4.5, function()
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

-- Counts the cash label up or down toward the real value so money visibly ticks.
local shownCash = 0
local function tickCashCounter(dt: number)
	local target = player:GetAttribute("Cash") or 0
	if math.abs(target - shownCash) < 1 then
		shownCash = target
	else
		shownCash += (target - shownCash) * math.min(1, dt * 8)
	end
	cashLabel.Text = "$" .. commas(shownCash + 0.5)
end

local function refreshCollection()
	local income = player:GetAttribute("Income") or 0
	incomeLabel.Text = "+$" .. commas(income) .. " / sec"
	brainrotChip.Text = "BRAINROTS " .. (player:GetAttribute("Brainrots") or 0) .. "/" .. (player:GetAttribute("Pads") or Catalog.StartingPads)
	local found = {}
	local foundCount = 0
	for id in string.gmatch(player:GetAttribute("Discovered") or "", "[^,]+") do
		local entry = Catalog.ById[id]
		if entry then
			found[entry.rarity] = (found[entry.rarity] or 0) + 1
			foundCount += 1
		end
	end
	collectionChip.Text = "COLLECTED " .. foundCount .. "/" .. #Catalog.List
	for rarityName, label in ladderRows do
		label.Text = (found[rarityName] or 0) .. "/" .. #Catalog.ByRarity[rarityName]
	end
	rebirthChip.Text = "INCOME x" .. (1 + (player:GetAttribute("Rebirths") or 0))
	local carrying = player:GetAttribute("Carrying") or ""
	carryPanel.Visible = carrying ~= ""
	carryLabel.Text = "RUN HOME with " .. carrying .. "!"
end

-- The wave banner: countdown while calm, big red "INCOMING" in the warning, "BONK THEM" in the raid.
local function refreshWaveBanner(now: number)
	local phase = workspace:GetAttribute("WavePhase") or "calm"
	local left = math.max(0, math.ceil((workspace:GetAttribute("WaveEndsAt") or now) - now))
	if phase == "warn" then
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * 10)
		wavePanel.AnchorPoint = Vector2.new(0.5, 0)
		wavePanel.Position = UDim2.new(0.5, 0, 0, 180)
		wavePanel.Size = UDim2.fromOffset(600, 64)
		wavePanel.BackgroundColor3 = C.danger:Lerp(C.ink, 0.25 + 0.3 * pulse)
		waveLabel.TextSize = 34
		waveLabel.Text = "THIEF WAVE INCOMING!  " .. left
	elseif phase == "raid" then
		wavePanel.AnchorPoint = Vector2.new(0.5, 0)
		wavePanel.Position = UDim2.new(0.5, 0, 0, 180)
		wavePanel.Size = UDim2.fromOffset(600, 54)
		wavePanel.BackgroundColor3 = C.danger:Lerp(C.ink, 0.35)
		waveLabel.TextSize = 27
		waveLabel.Text = "WAVE " .. (workspace:GetAttribute("WaveNumber") or 1) .. ": THIEVES ARE IN!  BONK THEM!"
	else
		wavePanel.AnchorPoint = Vector2.new(1, 0)
		wavePanel.Position = UDim2.new(1, -14, 0, 12)
		wavePanel.Size = UDim2.fromOffset(300, 46)
		wavePanel.BackgroundColor3 = C.panel
		waveLabel.TextSize = 23
		waveLabel.Text = string.format("THIEF WAVE IN  %d:%02d", left // 60, left % 60)
	end
end

local function refreshButtons(now: number)
	local lockUntil = player:GetAttribute("LockUntil") or 0
	local readyAt = player:GetAttribute("LockReadyAt") or 0
	if now < lockUntil then
		HudKit.setButton(lockKit, string.format("SHIELD UP  %ds", math.ceil(lockUntil - now)), (lockUntil - now) / Catalog.LockSeconds, true)
	elseif now < readyAt then
		HudKit.setButton(lockKit, string.format("RECHARGING  %ds", math.ceil(readyAt - now)), 1 - (readyAt - now) / (Catalog.LockCooldown - Catalog.LockSeconds), false)
	else
		HudKit.setButton(lockKit, "READY  [F]  at your base", 1, true)
	end
	local cost = player:GetAttribute("RebirthCost") or Catalog.RebirthBaseCost
	local cash = player:GetAttribute("Cash") or 0
	local nextMultiplier = 2 + (player:GetAttribute("Rebirths") or 0)
	HudKit.setButton(rebirthKit, "$" .. Catalog.formatCash(cost) .. "  for  x" .. nextMultiplier .. " income", cash / cost, cash >= cost)
end

local function requestLockBase()
	actionRemote:FireServer("LockBase")
end

lockKit.button.Activated:Connect(requestLockBase)
rebirthKit.button.Activated:Connect(function()
	actionRemote:FireServer("Rebirth")
end)
ContextActionService:BindAction("BazaarLockBase", function(_, state)
	if state == Enum.UserInputState.Begin then
		requestLockBase()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.F)

noticeRemote.OnClientEvent:Connect(showPopup)
for _, attribute in { "Income", "Brainrots", "Pads", "Discovered", "Rebirths", "Carrying" } do
	player:GetAttributeChangedSignal(attribute):Connect(refreshCollection)
end
refreshCollection()

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	tickCashCounter(dt)
	refreshWaveBanner(now)
	refreshButtons(now)
end)

-- A small bounce on the cash panel whenever money arrives.
player:GetAttributeChangedSignal("Cash"):Connect(function()
	coin.Size = UDim2.fromOffset(80, 80)
	TweenService:Create(coin, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(72, 72) }):Play()
end)
