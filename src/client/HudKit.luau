-- HudKit: the HUD's one visual system. Every panel, label, pill and button on screen is made
-- here, so they all share the same font, corner radius, stroke and colours.

local HudKit = {}

HudKit.Font = Enum.Font.FredokaOne
HudKit.Colors = {
	panel = Color3.fromRGB(34, 26, 58),
	panelEdge = Color3.fromRGB(255, 255, 255),
	ink = Color3.fromRGB(20, 14, 34),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(196, 188, 224),
	money = Color3.fromRGB(104, 255, 128),
	gold = Color3.fromRGB(255, 214, 64),
	danger = Color3.fromRGB(255, 72, 72),
	lock = Color3.fromRGB(64, 200, 255),
	rebirth = Color3.fromRGB(190, 110, 255),
}

-- A chunky rounded panel with a thick outline.
function HudKit.panel(parent: Instance, name: string, size: UDim2, position: UDim2, anchor: Vector2?, color: Color3?, radius: number?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.zero
	frame.BackgroundColor3 = color or HudKit.Colors.panel
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 18)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Edge"
	stroke.Thickness = 3
	stroke.Color = HudKit.Colors.panelEdge
	stroke.Transparency = 0.15
	stroke.Parent = frame
	return frame
end

-- Outlined text at a fixed design size (the whole HUD is scaled together by one UIScale).
function HudKit.label(parent: Instance, name: string, text: string, textSize: number, color: Color3?, size: UDim2?, position: UDim2?, alignX: Enum.TextXAlignment?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size or UDim2.fromScale(1, 1)
	label.Position = position or UDim2.new()
	label.Font = HudKit.Font
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or HudKit.Colors.text
	label.TextXAlignment = alignX or Enum.TextXAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = math.clamp(textSize / 14, 1.5, 3.5)
	stroke.Color = HudKit.Colors.ink
	stroke.Parent = label
	return label
end

-- A big press-me button: coloured face, title, a status line and a progress fill along the bottom.
function HudKit.bigButton(parent: Instance, name: string, title: string, color: Color3, position: UDim2)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = ""
	button.AutoButtonColor = true
	button.Size = UDim2.fromOffset(250, 76)
	button.Position = position
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.ClipsDescendants = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = HudKit.Colors.panelEdge
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BackgroundTransparency = 0.45
	fill.BorderSizePixel = 0
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.new(0, 0, 0, 10)
	fill.Parent = button
	local titleLabel = HudKit.label(button, "Title", title, 30, nil, UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 6))
	local status = HudKit.label(button, "Status", "", 19, nil, UDim2.new(1, -12, 0, 22), UDim2.fromOffset(6, 40))
	return { button = button, title = titleLabel, status = status, fill = fill, color = color }
end

function HudKit.setButton(kit, status: string, progress: number, enabled: boolean)
	kit.status.Text = status
	kit.fill.Size = UDim2.new(math.clamp(progress, 0, 1), 0, 0, 10)
	kit.button.BackgroundColor3 = enabled and kit.color or kit.color:Lerp(HudKit.Colors.ink, 0.55)
end

return HudKit
