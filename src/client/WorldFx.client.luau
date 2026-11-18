-- WorldFx: client-only eye candy in the 3D world. Moving chevrons on the conveyor belt,
-- "+$" pops rising off your earning brainrots every second, and a glowing guide beam that
-- points from you to your base while you carry a brainrot. Purely visual: no game state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local player = Players.LocalPlayer
local bazaar = workspace:WaitForChild("Bazaar")

local BELT_START_X, BELT_END_X, BELT_Y, BELT_SPEED = -86, 88, 1.6, 7
local STRIPE_GAP = 6

-- Yellow arrows sliding along the belt so it reads as moving.
local function animateConveyorChevrons()
	local stripes = {}
	local folder = Instance.new("Folder")
	folder.Name = "BeltChevrons"
	folder.Parent = bazaar
	for index = 0, math.floor((BELT_END_X - BELT_START_X) / STRIPE_GAP) - 1 do
		local pair = {}
		for _, side in { -1, 1 } do
			local stripe = Instance.new("Part")
			stripe.Name = "Chevron"
			stripe.Anchored = true
			stripe.CanCollide = false
			stripe.CanQuery = false
			stripe.CanTouch = false
			stripe.CastShadow = false
			stripe.Size = Vector3.new(0.9, 0.08, 5.4)
			stripe.Color = Color3.fromRGB(255, 206, 40)
			stripe.Material = Enum.Material.Neon
			stripe.Parent = folder
			table.insert(pair, { part = stripe, side = side })
		end
		stripes[index] = pair
	end
	RunService.RenderStepped:Connect(function()
		local shift = (os.clock() * BELT_SPEED) % STRIPE_GAP
		for index, pair in stripes do
			local x = BELT_START_X + index * STRIPE_GAP + shift
			for _, stripe in pair do
				stripe.part.CFrame = CFrame.new(x, BELT_Y + 0.03, stripe.side * 1.9) * CFrame.Angles(0, math.rad(stripe.side * 50), 0)
			end
		end
	end)
end

-- "+$12" floating up from each brainrot on your base, once a second: money ticking at its rate.
local function popCashOverMyBrainrots()
	while true do
		task.wait(1)
		local plotIndex = player:GetAttribute("PlotIndex")
		local plot = plotIndex and bazaar.Plots:FindFirstChild("Plot" .. plotIndex)
		if plot then
			for _, brainrot in plot.Brainrots:GetChildren() do
				local root = brainrot.PrimaryPart
				local income = brainrot:GetAttribute("Income")
				if root and income and root.Anchored then
					local pop = Instance.new("BillboardGui")
					pop.Name = "CashPop"
					pop.Size = UDim2.fromScale(7, 2.2)
					pop.StudsOffsetWorldSpace = Vector3.new(0, 4, -2)
					pop.AlwaysOnTop = true
					pop.LightInfluence = 0
					pop.Adornee = root
					pop.Parent = root
					local text = Instance.new("TextLabel")
					text.Size = UDim2.fromScale(1, 1)
					text.BackgroundTransparency = 1
					text.Font = Enum.Font.FredokaOne
					text.TextScaled = true
					text.TextColor3 = Color3.fromRGB(104, 255, 128)
					text.TextStrokeTransparency = 0
					text.Text = "+$" .. Catalog.formatCash(income)
					text.Parent = pop
					TweenService:Create(pop, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = Vector3.new(0, 8.5, -2) }):Play()
					TweenService:Create(text, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
					task.delay(0.95, pop.Destroy, pop)
				end
			end
		end
	end
end

-- A beam from the player to their own base while they carry a brainrot: the dash home.
local function guideCarrierHome()
	local beam = Instance.new("Beam")
	beam.Name = "HomeBeam"
	beam.Width0 = 1.4
	beam.Width1 = 1.4
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 226, 90))
	beam.Transparency = NumberSequence.new(0.25)
	beam.Segments = 1
	beam.Enabled = false
	beam.Parent = bazaar
	local homeAnchor = Instance.new("Attachment")
	homeAnchor.Name = "HomeAnchor"
	local function refresh()
		local carrying = (player:GetAttribute("Carrying") or "") ~= ""
		local plotIndex = player:GetAttribute("PlotIndex")
		local plot = plotIndex and bazaar.Plots:FindFirstChild("Plot" .. plotIndex)
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local feet = rootPart and rootPart:FindFirstChild("RootAttachment")
		if carrying and plot and feet then
			homeAnchor.Parent = plot.BaseFloor
			homeAnchor.Position = Vector3.new(0, 1.5, 0)
			beam.Attachment0 = feet
			beam.Attachment1 = homeAnchor
			beam.Enabled = true
		else
			beam.Enabled = false
		end
	end
	player:GetAttributeChangedSignal("Carrying"):Connect(refresh)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		refresh()
	end)
end

animateConveyorChevrons()
guideCarrierHome()
task.spawn(popCashOverMyBrainrots)
