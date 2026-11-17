-- Brainrots.luau
-- Builds the 10 collectible "brainrot" characters entirely from parts.
-- Each character is an anchored Model standing on a base CFrame (feet at the
-- base position, facing +Z). The Body part is the PrimaryPart and carries the
-- CollectBurst particle emitter; the server connects Touched on the Body.

local Brainrots = {}

Brainrots.COUNT = 10

local DESIGNS = {
	{ name = "Tung Tung Jr.", body = Color3.fromRGB(166, 110, 58), head = Color3.fromRGB(196, 144, 88), kind = "propeller" },
	{ name = "Capuchino Kid", body = Color3.fromRGB(245, 245, 240), head = Color3.fromRGB(240, 235, 225), kind = "cup" },
	{ name = "Bananini Bob", body = Color3.fromRGB(255, 220, 60), head = Color3.fromRGB(255, 230, 110), kind = "banana" },
	{ name = "Sharky Sneaks", body = Color3.fromRGB(70, 140, 255), head = Color3.fromRGB(110, 170, 255), kind = "shark", shades = true },
	{ name = "Cacto Carl", body = Color3.fromRGB(50, 180, 80), head = Color3.fromRGB(70, 200, 100), kind = "cactus" },
	{ name = "Pizzarino Pete", body = Color3.fromRGB(240, 190, 90), head = Color3.fromRGB(245, 205, 110), kind = "pizza" },
	{ name = "Robo Rizzler", body = Color3.fromRGB(160, 165, 175), head = Color3.fromRGB(185, 190, 200), kind = "robot", shades = true, metal = true },
	{ name = "Froggie Fresh", body = Color3.fromRGB(90, 220, 110), head = Color3.fromRGB(120, 235, 140), kind = "frog" },
	{ name = "Donut Diva", body = Color3.fromRGB(190, 140, 255), head = Color3.fromRGB(245, 205, 160), kind = "donut", shades = true },
	{ name = "Cone Head Ned", body = Color3.fromRGB(255, 150, 60), head = Color3.fromRGB(245, 205, 160), kind = "cone" },
}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(15, 15, 20)

-- Builds character `index` (1..10) standing at baseCFrame. Returns the Model
-- (not yet parented).
function Brainrots.build(index, baseCFrame)
	local design = DESIGNS[index]
	local model = Instance.new("Model")
	model.Name = "Brainrot" .. index

	local baseMaterial = design.metal and Enum.Material.Metal or Enum.Material.SmoothPlastic

	local function add(name, size, localCf, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = baseCFrame * localCf
		p.Color = color
		p.Material = material or baseMaterial
		if shape then
			p.Shape = shape
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function cyl(name, height, diameter, localCf, color, material)
		-- Cylinder parts run along X; rotate so the height stands along Y.
		return add(name, Vector3.new(height, diameter, diameter),
			localCf * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
	end

	local function ball(name, diameter, localCf, color, material)
		return add(name, Vector3.new(diameter, diameter, diameter), localCf, color, material, Enum.PartType.Ball)
	end

	-- Body ------------------------------------------------------------------
	local body
	if design.kind == "cup" then
		body = cyl("Body", 3, 2.6, CFrame.new(0, 1.5, 0), design.body)
	else
		body = add("Body", Vector3.new(2.4, 3, 1.6), CFrame.new(0, 1.5, 0), design.body)
	end
	body.CanTouch = true

	-- Collect burst particles, fired by the server when someone collects it.
	local burst = Instance.new("ParticleEmitter")
	burst.Name = "CollectBurst"
	burst.Color = ColorSequence.new(WHITE, design.body)
	burst.Lifetime = NumberRange.new(0.5, 1.1)
	burst.Speed = NumberRange.new(5, 9)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.LightEmission = 0.6
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	burst.Parent = body

	-- Head / face ------------------------------------------------------------
	local head = nil
	local labelParent = nil
	local labelOffsetY = 2.6

	local function eyes(y, z, pupilZ)
		ball("EyeL", 0.55, CFrame.new(-0.48, y, z), WHITE, Enum.Material.SmoothPlastic)
		ball("EyeR", 0.55, CFrame.new(0.48, y, z), WHITE, Enum.Material.SmoothPlastic)
		ball("PupilL", 0.27, CFrame.new(-0.48, y + 0.02, pupilZ), BLACK, Enum.Material.SmoothPlastic)
		ball("PupilR", 0.27, CFrame.new(0.48, y + 0.02, pupilZ), BLACK, Enum.Material.SmoothPlastic)
	end

	local function sunglasses(y, z)
		add("Shades", Vector3.new(1.9, 0.5, 0.16), CFrame.new(0, y, z), BLACK, Enum.Material.SmoothPlastic)
	end

	if design.kind == "cup" then
		-- The cup is the body; coffee surface on top, face on the cup front.
		cyl("Coffee", 0.5, 2.3, CFrame.new(0, 3.0, 0), Color3.fromRGB(110, 70, 40))
		add("Straw", Vector3.new(0.35, 2.2, 0.35),
			CFrame.new(0.7, 3.9, 0) * CFrame.Angles(0, 0, -0.35),
			Color3.fromRGB(255, 60, 60), Enum.Material.SmoothPlastic)
		eyes(2.1, 1.14, 1.34)
		labelParent = body
		labelOffsetY = 4.1
	elseif design.kind == "pizza" then
		-- The head is a pizza: crust disc with a cheese disc and pepperoni.
		cyl("Crust", 0.35, 3.25, CFrame.new(0, 3.6, 0), Color3.fromRGB(210, 150, 80))
		head = cyl("Head", 0.55, 2.9, CFrame.new(0, 3.75, 0), Color3.fromRGB(255, 205, 80))
		cyl("Pepperoni1", 0.18, 0.6, CFrame.new(0.7, 4.08, 0.4), Color3.fromRGB(200, 50, 45))
		cyl("Pepperoni2", 0.18, 0.6, CFrame.new(-0.6, 4.08, -0.5), Color3.fromRGB(200, 50, 45))
		cyl("Pepperoni3", 0.18, 0.6, CFrame.new(0.05, 4.08, 0.85), Color3.fromRGB(200, 50, 45))
		eyes(1.9, 0.72, 0.94)
		labelParent = head
		labelOffsetY = 1.7
	else
		head = add("Head", Vector3.new(2, 1.8, 2), CFrame.new(0, 3.9, 0), design.head)
		labelParent = head
		if design.kind == "frog" then
			-- Stalk eyes on top of the head.
			cyl("StalkL", 0.85, 0.3, CFrame.new(-0.55, 5.1, 0), design.body)
			cyl("StalkR", 0.85, 0.3, CFrame.new(0.55, 5.1, 0), design.body)
			ball("EyeBallL", 0.9, CFrame.new(-0.55, 5.75, 0), WHITE, Enum.Material.SmoothPlastic)
			ball("EyeBallR", 0.9, CFrame.new(0.55, 5.75, 0), WHITE, Enum.Material.SmoothPlastic)
			ball("PupilL", 0.42, CFrame.new(-0.55, 5.8, 0.32), BLACK, Enum.Material.SmoothPlastic)
			ball("PupilR", 0.42, CFrame.new(0.55, 5.8, 0.32), BLACK, Enum.Material.SmoothPlastic)
		elseif design.shades then
			sunglasses(4.12, 1.03)
		else
			eyes(4.1, 0.86, 1.08)
		end
	end

	-- Silly accessory per character ------------------------------------------
	local kind = design.kind
	if kind == "propeller" then
		cyl("Cap", 0.35, 2.4, CFrame.new(0, 4.95, 0), Color3.fromRGB(255, 60, 60))
		add("BladeX", Vector3.new(3.0, 0.18, 0.55), CFrame.new(0, 5.3, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
		add("BladeZ", Vector3.new(0.55, 0.18, 3.0), CFrame.new(0, 5.3, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
		ball("Hub", 0.55, CFrame.new(0, 5.3, 0), Color3.fromRGB(60, 120, 255), Enum.Material.SmoothPlastic)
	elseif kind == "banana" then
		add("PeelL", Vector3.new(0.55, 1.7, 0.16), CFrame.new(-0.62, 5.35, 0) * CFrame.Angles(0, 0, 0.55), Color3.fromRGB(255, 235, 130), Enum.Material.SmoothPlastic)
		add("PeelR", Vector3.new(0.55, 1.7, 0.16), CFrame.new(0.62, 5.35, 0) * CFrame.Angles(0, 0, -0.55), Color3.fromRGB(255, 235, 130), Enum.Material.SmoothPlastic)
		add("PeelB", Vector3.new(0.55, 1.7, 0.16), CFrame.new(0, 5.35, -0.62) * CFrame.Angles(-0.55, 0, 0), Color3.fromRGB(255, 235, 130), Enum.Material.SmoothPlastic)
		add("Stem", Vector3.new(0.35, 0.8, 0.35), CFrame.new(0, 5.25, 0), Color3.fromRGB(120, 80, 40), Enum.Material.SmoothPlastic)
	elseif kind == "shark" then
		add("Fin", Vector3.new(0.35, 1.6, 1.9), CFrame.new(0, 5.35, -0.2) * CFrame.Angles(-0.5, 0, 0), Color3.fromRGB(50, 110, 220), Enum.Material.SmoothPlastic)
		add("ShoeL", Vector3.new(0.95, 0.5, 1.9), CFrame.new(-0.62, 0.25, 0.25), Color3.fromRGB(255, 50, 50), Enum.Material.SmoothPlastic)
		add("ShoeR", Vector3.new(0.95, 0.5, 1.9), CFrame.new(0.62, 0.25, 0.25), Color3.fromRGB(255, 50, 50), Enum.Material.SmoothPlastic)
	elseif kind == "cactus" then
		add("ArmL", Vector3.new(0.55, 1.7, 0.55), CFrame.new(-1.5, 2.5, 0), design.body)
		add("ArmR", Vector3.new(0.55, 1.7, 0.55), CFrame.new(1.5, 2.5, 0), design.body)
		add("ArmLinkL", Vector3.new(0.6, 0.55, 0.55), CFrame.new(-1.25, 1.75, 0), design.body)
		add("ArmLinkR", Vector3.new(0.6, 0.55, 0.55), CFrame.new(1.25, 1.75, 0), design.body)
		add("SpikeL1", Vector3.new(0.55, 0.16, 0.16), CFrame.new(-1.3, 1.0, 0), WHITE, Enum.Material.SmoothPlastic)
		add("SpikeR1", Vector3.new(0.55, 0.16, 0.16), CFrame.new(1.3, 1.0, 0), WHITE, Enum.Material.SmoothPlastic)
		add("SpikeF1", Vector3.new(0.16, 0.16, 0.55), CFrame.new(0, 1.6, 0.85), WHITE, Enum.Material.SmoothPlastic)
		ball("Flower", 0.75, CFrame.new(0.4, 5.05, 0.3), Color3.fromRGB(255, 120, 200), Enum.Material.SmoothPlastic)
		ball("FlowerCenter", 0.5, CFrame.new(-0.35, 5.0, -0.25), Color3.fromRGB(255, 220, 60), Enum.Material.SmoothPlastic)
	elseif kind == "robot" then
		cyl("Antenna", 1.1, 0.16, CFrame.new(0, 5.3, 0), Color3.fromRGB(120, 125, 135))
		ball("AntennaTip", 0.55, CFrame.new(0, 6.05, 0), Color3.fromRGB(0, 255, 255), Enum.Material.Neon)
		add("ChestLight", Vector3.new(0.85, 0.85, 0.14), CFrame.new(0, 1.7, 0.83), Color3.fromRGB(0, 255, 255), Enum.Material.Neon)
	elseif kind == "donut" then
		cyl("DonutHat", 0.7, 2.6, CFrame.new(0, 5.0, 0), Color3.fromRGB(255, 130, 190))
		cyl("DonutHole", 0.74, 1.05, CFrame.new(0, 5.0, 0), design.head)
		local sprinkleColors = {
			Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 255, 120), Color3.fromRGB(60, 160, 255),
			Color3.fromRGB(255, 255, 120), Color3.fromRGB(200, 120, 255),
		}
		local sprinkleSpots = {
			{ 0.8, 0.3, 0.4 }, { -0.7, -0.5, 1.1 }, { 0.2, 0.9, 2.2 },
			{ -0.9, 0.6, 2.8 }, { 0.55, -0.85, 1.7 },
		}
		for i, spot in ipairs(sprinkleSpots) do
			add("Sprinkle" .. i, Vector3.new(0.34, 0.12, 0.12),
				CFrame.new(spot[1], 5.38, spot[2]) * CFrame.Angles(0, spot[3], 0),
				sprinkleColors[i], Enum.Material.SmoothPlastic)
		end
		ball("Cherry", 0.55, CFrame.new(0.85, 5.5, 0.55), Color3.fromRGB(230, 30, 50), Enum.Material.SmoothPlastic)
	elseif kind == "cone" then
		cyl("Cone1", 0.75, 2.3, CFrame.new(0, 5.15, 0), Color3.fromRGB(255, 120, 0))
		cyl("ConeStripe", 0.3, 2.34, CFrame.new(0, 5.15, 0), WHITE)
		cyl("Cone2", 0.7, 1.5, CFrame.new(0, 5.85, 0), Color3.fromRGB(255, 120, 0))
		cyl("Cone3", 0.65, 0.8, CFrame.new(0, 6.5, 0), Color3.fromRGB(255, 120, 0))
		labelOffsetY = 3.4
	end

	-- Name label --------------------------------------------------------------
	local label = Instance.new("BillboardGui")
	label.Name = "NameLabel"
	label.Size = UDim2.fromOffset(220, 54)
	label.StudsOffset = Vector3.new(0, labelOffsetY, 0)
	label.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextColor3 = WHITE
	text.TextStrokeTransparency = 0.35
	text.Text = design.name
	text.Parent = label
	label.Parent = labelParent

	model.PrimaryPart = body
	model.WorldPivot = baseCFrame * CFrame.new(0, 1.5, 0)
	return model
end

function Brainrots.nameOf(index)
	local design = DESIGNS[index]
	if design then
		return design.name
	end
	return "Brainrot " .. index
end

return Brainrots
