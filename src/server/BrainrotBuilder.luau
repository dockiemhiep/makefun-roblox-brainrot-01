-- BrainrotBuilder: turns a BrainrotCatalog entry into a 3D creature made of primitive parts,
-- with googly eyes, a mouth, legs, a rarity beam and a floating name / rarity / $-per-second label.
-- One job: build and relabel creature models. It knows nothing about who owns them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.BrainrotCatalog)

local Builder = {}
Builder.SCALE = 1.4

local BLACK = Color3.fromRGB(24, 22, 30)
local WHITE = Color3.fromRGB(255, 255, 255)

local addPart, addFace, addLegs, applyMutation, addRarityBeam, makeLabelLine

-- Builds the creature at the origin, feet on y = 0, facing -Z. The caller pivots and parents it.
function Builder.buildBrainrotModel(entry, mutationId: string?): Model
	local model = Instance.new("Model")
	model.Name = entry.id
	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Rarity", entry.rarity)
	model:SetAttribute("Mutation", mutationId or "")

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Massless = true
	root.CFrame = CFrame.new(0, 0.5, 0)
	root.PivotOffset = CFrame.new(0, -0.5, 0) -- the model pivots at its feet
	root.Parent = model
	model.PrimaryPart = root

	for _, row in entry.parts do
		local rotation = row[6]
		local cf = CFrame.new(row[3])
		if rotation then
			cf = cf * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
		end
		addPart(model, root, row[1], row[2], cf, row[4], row[5], row[7]).Name = "Body"
	end
	if entry.legs then
		addLegs(model, root, entry.legs)
	end
	addFace(model, root, entry.face)
	if mutationId then
		applyMutation(model, mutationId)
	end

	local rarity = Catalog.Rarities[entry.rarity]
	if rarity.beam then
		addRarityBeam(model, root, rarity.color, entry.height)
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromScale(15, 6.4)
	gui.StudsOffsetWorldSpace = Vector3.new(0, entry.height * Builder.SCALE + 3.4, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 320
	gui.DistanceLowerLimit = 42 -- labels stop growing when you stand next to the creature
	gui.DistanceUpperLimit = 130 -- and stop shrinking across the bazaar, so they stay readable
	gui.Parent = root
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui
	makeLabelLine(gui, "Rarity", 1, 0.2, Enum.Font.GothamBlack)
	makeLabelLine(gui, "BrainrotName", 2, 0.3, Enum.Font.FredokaOne)
	makeLabelLine(gui, "Money", 3, 0.3, Enum.Font.FredokaOne).TextColor3 = Color3.fromRGB(96, 255, 120)
	makeLabelLine(gui, "Extra", 4, 0.2, Enum.Font.GothamBlack).TextColor3 = Color3.fromRGB(255, 226, 90)

	local promptPoint = Instance.new("Attachment")
	promptPoint.Name = "PromptPoint"
	promptPoint.Position = Vector3.new(0, entry.height * Builder.SCALE * 0.5, 0)
	promptPoint.Parent = root

	Builder.setBrainrotLabel(model, { mutation = mutationId, income = Catalog.incomePerSecond(entry, mutationId, 1), level = 1 })
	return model
end

local function weldToRoot(root: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

function addPart(model: Model, root: BasePart, shape: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	-- every creature is built SCALE times the catalog's numbers so it reads from across the bazaar
	size *= Builder.SCALE
	cf = CFrame.new(cf.Position * Builder.SCALE) * cf.Rotation
	local part: BasePart
	if shape == "Wedge" then
		part = Instance.new("WedgePart")
		part.Size = size
	else
		local block = Instance.new("Part")
		if shape == "Cyl" then
			block.Shape = Enum.PartType.Cylinder
			block.Size = Vector3.new(size.Y, size.X, size.Z)
			cf = cf * CFrame.Angles(0, 0, math.rad(90))
		else
			block.Size = size
			if shape == "Ball" then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = block
			end
		end
		part = block
	end
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CastShadow = (transparency or 0) < 0.3
	part.Parent = model
	weldToRoot(root, part)
	return part
end

-- Two googly eyes and a mouth on the creature's front (-Z) at the height the catalog names.
function addFace(model: Model, root: BasePart, face)
	local s = face.size
	for _, side in { -1, 1 } do
		addPart(model, root, "Ball", Vector3.new(s, s * 1.15, s * 0.5), CFrame.new(side * face.gap, face.y, face.z), WHITE)
		addPart(model, root, "Ball", Vector3.new(s * 0.5, s * 0.55, s * 0.3), CFrame.new(side * face.gap + side * -0.06, face.y - 0.05, face.z - s * 0.2), BLACK)
	end
	local mouthY = face.y - s * 1.1
	if face.mouth == "smile" then
		addPart(model, root, "Ball", Vector3.new(s * 1.3, s * 0.45, s * 0.3), CFrame.new(0, mouthY, face.z - 0.02), BLACK)
	elseif face.mouth == "o" then
		addPart(model, root, "Ball", Vector3.new(s * 0.7, s * 0.8, s * 0.3), CFrame.new(0, mouthY, face.z - 0.02), BLACK)
	elseif face.mouth == "teeth" then
		addPart(model, root, "Block", Vector3.new(s * 1.6, s * 0.6, s * 0.2), CFrame.new(0, mouthY, face.z - 0.02), BLACK)
		addPart(model, root, "Block", Vector3.new(s * 1.3, s * 0.25, s * 0.22), CFrame.new(0, mouthY + s * 0.14, face.z - 0.04), WHITE)
	end
end

function addLegs(model: Model, root: BasePart, legs)
	for _, side in { -1, 1 } do
		addPart(model, root, "Cyl", Vector3.new(0.5, legs.h, 0.5), CFrame.new(side * legs.spread, legs.h / 2 + 0.2, 0), legs.color)
		addPart(model, root, "Block", Vector3.new(1.0, 0.5, 1.5), CFrame.new(side * legs.spread, 0.25, -0.3), legs.shoe)
	end
end

-- Golden / Radioactive / Rainbow recolour the whole body (eyes and mouths stay readable).
function applyMutation(model: Model, mutationId: string)
	local index = 0
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Body" then
			index += 1
			if mutationId == "Golden" then
				part.Color = Color3.fromRGB(255, 200, 40):Lerp(part.Color, 0.15)
				part.Material = Enum.Material.Foil
			elseif mutationId == "Radioactive" then
				part.Color = Color3.fromRGB(110, 255, 50):Lerp(part.Color, 0.25)
				part.Material = Enum.Material.Neon
			elseif mutationId == "Rainbow" then
				part.Color = Color3.fromHSV((index * 0.13) % 1, 0.75, 1)
				part.Material = Enum.Material.Neon
			end
		end
	end
end

function addRarityBeam(model: Model, root: BasePart, color: Color3, height: number)
	local beam = addPart(model, root, "Cyl", Vector3.new(0.6, 30, 0.6), CFrame.new(0, height + 17, 0), color, Enum.Material.Neon, 0.6)
	beam.Name = "RarityBeam"
	beam.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 16
	light.Brightness = 1.6
	light.Parent = root
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(color)
	sparkle.LightEmission = 1
	sparkle.Rate = 6
	sparkle.Lifetime = NumberRange.new(1, 1.8)
	sparkle.Speed = NumberRange.new(2, 4)
	sparkle.SpreadAngle = Vector2.new(40, 40)
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Parent = root
end

function makeLabelLine(parent: Instance, name: string, order: number, heightScale: number, font: Enum.Font): TextLabel
	local line = Instance.new("TextLabel")
	line.Name = name
	line.LayoutOrder = order
	line.BackgroundTransparency = 1
	line.Size = UDim2.fromScale(1, heightScale)
	line.Font = font
	line.TextScaled = true
	line.TextColor3 = WHITE
	line.TextStrokeTransparency = 0
	line.TextStrokeColor3 = BLACK
	line.Text = ""
	line.Parent = parent
	return line
end

-- Rewrites the floating label: rarity (+ mutation), name, money a second, and a price or level line.
function Builder.setBrainrotLabel(model: Model, info: { mutation: string?, income: number, level: number?, price: number?, tag: string? })
	local entry = Catalog.ById[model:GetAttribute("BrainrotId")]
	local rarity = Catalog.Rarities[entry.rarity]
	local gui = model.PrimaryPart:FindFirstChild("Label")
	if not gui then
		return
	end
	local tier = string.upper(entry.rarity)
	if info.mutation then
		tier = string.upper(info.mutation) .. " " .. tier
	end
	gui.Rarity.Text = tier
	gui.Rarity.TextColor3 = rarity.color
	gui.BrainrotName.Text = entry.name
	gui.Money.Text = "$" .. Catalog.formatCash(info.income) .. "/s"
	local extra = ""
	if info.price then
		extra = "BUY $" .. Catalog.formatCash(info.price)
	elseif info.tag then
		extra = info.tag
	elseif info.level then
		extra = "LVL " .. info.level .. string.rep("★", info.level)
	end
	gui.Extra.Text = extra
	model:SetAttribute("Income", info.income)
end

-- A proximity prompt on the creature (Buy / Catch / Steal / Upgrade / Sell).
function Builder.addPrompt(model: Model, name: string, action: string, object: string, hold: number, key: Enum.KeyCode?, offsetY: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold
	prompt.KeyboardKeyCode = key or Enum.KeyCode.E
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, offsetY or 0)
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.Parent = model.PrimaryPart.PromptPoint
	return prompt
end

function Builder.clearPrompts(model: Model)
	for _, child in model.PrimaryPart.PromptPoint:GetChildren() do
		child:Destroy()
	end
end

return Builder
