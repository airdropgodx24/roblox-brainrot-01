-- Brainrots.luau
-- Brainrot Obby Rush: the ten collectible goofballs.
-- Each one is a chunky blocky buddy built from plain Parts,
-- with its own loud colours and one signature accessory.
-- Layout (local studs, feet at y = 0):
--   legs 0 to 0.9, body 0.9 to 3.3, head 3.3 to 4.7.

local Brainrots = {}

Brainrots.names = {
	"Captain Noodle Noggin",
	"Pickle Wizard Deluxe",
	"Dizzy Banana Baron",
	"Sir Wobbles The Third",
	"Turbo Marshmallow Mutt",
	"Grandma Laser Socks",
	"Bongo Biscuit Bandit",
	"Professor Puddle Jump",
	"Waffle Rocket Rooster",
	"Disco Turnip Trouble",
}

local PALETTES = {
	{ body = Color3.fromRGB(255, 92, 92), head = Color3.fromRGB(255, 205, 120), accent = Color3.fromRGB(255, 235, 59) },
	{ body = Color3.fromRGB(88, 214, 99), head = Color3.fromRGB(190, 255, 170), accent = Color3.fromRGB(34, 139, 60) },
	{ body = Color3.fromRGB(255, 214, 64), head = Color3.fromRGB(255, 240, 170), accent = Color3.fromRGB(255, 140, 0) },
	{ body = Color3.fromRGB(120, 170, 255), head = Color3.fromRGB(200, 225, 255), accent = Color3.fromRGB(70, 90, 255) },
	{ body = Color3.fromRGB(250, 250, 250), head = Color3.fromRGB(255, 190, 220), accent = Color3.fromRGB(255, 105, 180) },
	{ body = Color3.fromRGB(180, 120, 255), head = Color3.fromRGB(230, 205, 255), accent = Color3.fromRGB(120, 60, 220) },
	{ body = Color3.fromRGB(255, 150, 60), head = Color3.fromRGB(255, 215, 160), accent = Color3.fromRGB(200, 80, 20) },
	{ body = Color3.fromRGB(70, 210, 220), head = Color3.fromRGB(185, 245, 250), accent = Color3.fromRGB(20, 130, 160) },
	{ body = Color3.fromRGB(235, 90, 160), head = Color3.fromRGB(255, 200, 225), accent = Color3.fromRGB(160, 30, 100) },
	{ body = Color3.fromRGB(150, 230, 120), head = Color3.fromRGB(220, 255, 200), accent = Color3.fromRGB(240, 80, 80) },
}

local function makePart(parent, name, size, offset, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.CanQuery = false
	if shape then
		part.Shape = shape
	end
	part.Parent = parent
	return part
end

local function makeWedge(parent, name, size, offset, color, rotation)
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(offset) * (rotation or CFrame.new())
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	return part
end

local function noTouch(part)
	part.CanTouch = false
	return part
end

local function addConeHat(model, accent)
	local cone = Instance.new("Part")
	cone.Name = "ConeHat"
	cone.Shape = Enum.PartType.Cylinder
	cone.Size = Vector3.new(1.6, 1.5, 1.6)
	cone.CFrame = CFrame.new(0, 5.3, 0)
	cone.Color = accent
	cone.Material = Enum.Material.Neon
	cone.Anchored = true
	cone.CanCollide = false
	cone.CanTouch = false
	cone.Parent = model
	noTouch(makePart(model, "ConeStripe", Vector3.new(1.65, 0.25, 1.65), Vector3.new(0, 4.85, 0), Color3.new(1, 1, 1), Enum.PartType.Cylinder))
end

local function addAntenna(model, accent)
	noTouch(makePart(model, "AntennaStick", Vector3.new(0.14, 1.1, 0.14), Vector3.new(0, 5.2, 0), Color3.fromRGB(60, 60, 60)))
	noTouch(makePart(model, "AntennaBall", Vector3.new(0.55, 0.55, 0.55), Vector3.new(0, 5.9, 0), accent, Enum.PartType.Ball))
end

local function addWings(model, accent)
	local left = makeWedge(model, "LeftWing", Vector3.new(0.25, 1.1, 1.7), Vector3.new(-1.35, 2.6, 0.4), accent, CFrame.Angles(0, math.rad(90), 0))
	left.Material = Enum.Material.Neon
	local right = makeWedge(model, "RightWing", Vector3.new(0.25, 1.1, 1.7), Vector3.new(1.35, 2.6, 0.4), accent, CFrame.Angles(0, math.rad(-90), 0))
	right.Material = Enum.Material.Neon
end

local function addCrown(model, accent)
	noTouch(makePart(model, "CrownBand", Vector3.new(1.5, 0.45, 1.5), Vector3.new(0, 4.9, 0), accent))
	for i = -1, 1 do
		noTouch(makePart(model, "CrownSpike" .. tostring(i + 2), Vector3.new(0.35, 0.6, 0.35), Vector3.new(i * 0.5, 5.4, 0), accent))
	end
	noTouch(makePart(model, "CrownGem", Vector3.new(0.4, 0.4, 0.15), Vector3.new(0, 4.9, -0.8), Color3.fromRGB(255, 60, 120), Enum.PartType.Ball))
end

local function addPropeller(model, accent)
	noTouch(makePart(model, "PropStick", Vector3.new(0.14, 0.6, 0.14), Vector3.new(0, 5.0, 0), Color3.fromRGB(60, 60, 60)))
	noTouch(makePart(model, "PropBladeA", Vector3.new(1.9, 0.14, 0.4), Vector3.new(0, 5.35, 0), accent))
	noTouch(makePart(model, "PropBladeB", Vector3.new(0.4, 0.14, 1.9), Vector3.new(0, 5.35, 0), accent))
	noTouch(makePart(model, "PropHub", Vector3.new(0.4, 0.3, 0.4), Vector3.new(0, 5.35, 0), Color3.fromRGB(40, 40, 40), Enum.PartType.Ball))
end

local function addHalo(model, accent)
	local halo = Instance.new("Part")
	halo.Name = "Halo"
	halo.Shape = Enum.PartType.Cylinder
	halo.Size = Vector3.new(0.18, 1.7, 1.7)
	halo.CFrame = CFrame.new(0, 5.45, 0) * CFrame.Angles(math.rad(90), 0, 0)
	halo.Color = Color3.fromRGB(255, 235, 120)
	halo.Material = Enum.Material.Neon
	halo.Anchored = true
	halo.CanCollide = false
	halo.CanTouch = false
	halo.Parent = model
end

local function addHorns(model, accent)
	makeWedge(model, "LeftHorn", Vector3.new(0.45, 0.9, 0.45), Vector3.new(-0.75, 5.0, 0), accent, CFrame.Angles(0, 0, math.rad(25)))
	makeWedge(model, "RightHorn", Vector3.new(0.45, 0.9, 0.45), Vector3.new(0.75, 5.0, 0), accent, CFrame.Angles(0, 0, math.rad(-25)))
end

local function addMohawk(model, accent)
	for i = -2, 2 do
		local height = 0.75 - math.abs(i) * 0.12
		noTouch(makePart(model, "MohawkFin" .. tostring(i + 3), Vector3.new(0.22, height, 0.55), Vector3.new(0, 4.7 + height / 2, i * 0.32), accent))
	end
end

local function addGlasses(model, accent)
	noTouch(makePart(model, "LensLeft", Vector3.new(0.55, 0.55, 0.1), Vector3.new(-0.38, 4.15, -0.88), accent))
	noTouch(makePart(model, "LensRight", Vector3.new(0.55, 0.55, 0.1), Vector3.new(0.38, 4.15, -0.88), accent))
	noTouch(makePart(model, "LensBridge", Vector3.new(0.3, 0.1, 0.1), Vector3.new(0, 4.2, -0.88), Color3.fromRGB(30, 30, 30)))
	noTouch(makePart(model, "PupilLeft", Vector3.new(0.2, 0.2, 0.06), Vector3.new(-0.38, 4.15, -0.95), Color3.new(1, 1, 1), Enum.PartType.Ball))
	noTouch(makePart(model, "PupilRight", Vector3.new(0.2, 0.2, 0.06), Vector3.new(0.38, 4.15, -0.95), Color3.new(1, 1, 1), Enum.PartType.Ball))
end

local function addRocketPack(model, accent)
	noTouch(makePart(model, "RocketTankLeft", Vector3.new(0.55, 1.5, 0.55), Vector3.new(-0.55, 2.3, 0.95), accent, Enum.PartType.Cylinder))
	noTouch(makePart(model, "RocketTankRight", Vector3.new(0.55, 1.5, 0.55), Vector3.new(0.55, 2.3, 0.95), accent, Enum.PartType.Cylinder))
	local flameA = noTouch(makePart(model, "RocketFlameA", Vector3.new(0.4, 0.7, 0.4), Vector3.new(-0.55, 1.3, 0.95), Color3.fromRGB(255, 170, 40), Enum.PartType.Ball))
	flameA.Material = Enum.Material.Neon
	local flameB = noTouch(makePart(model, "RocketFlameB", Vector3.new(0.4, 0.7, 0.4), Vector3.new(0.55, 1.3, 0.95), Color3.fromRGB(255, 170, 40), Enum.PartType.Ball))
	flameB.Material = Enum.Material.Neon
end

local ACCESSORY_BUILDERS = {
	addConeHat,
	addAntenna,
	addWings,
	addCrown,
	addPropeller,
	addHalo,
	addHorns,
	addMohawk,
	addGlasses,
	addRocketPack,
}

function Brainrots.spawn(parent, cframe, index)
	local palette = PALETTES[((index - 1) % #PALETTES) + 1]
	local model = Instance.new("Model")
	model.Name = "Brainrot" .. tostring(index)

	local body = makePart(model, "Body", Vector3.new(2, 2.4, 1.4), Vector3.new(0, 2.1, 0), palette.body)
	local head = makePart(model, "Head", Vector3.new(1.7, 1.4, 1.7), Vector3.new(0, 4.0, 0), palette.head)

	noTouch(makePart(model, "Belly", Vector3.new(1.4, 1.5, 0.2), Vector3.new(0, 2.0, -0.75), Color3.new(1, 1, 1)))
	noTouch(makePart(model, "ArmLeft", Vector3.new(0.55, 1.6, 0.55), Vector3.new(-1.3, 2.3, 0), palette.body))
	noTouch(makePart(model, "ArmRight", Vector3.new(0.55, 1.6, 0.55), Vector3.new(1.3, 2.3, 0), palette.body))
	noTouch(makePart(model, "LegLeft", Vector3.new(0.7, 0.9, 0.7), Vector3.new(-0.5, 0.45, 0), palette.accent))
	noTouch(makePart(model, "LegRight", Vector3.new(0.7, 0.9, 0.7), Vector3.new(0.5, 0.45, 0), palette.accent))

	local eyeColor = Color3.fromRGB(25, 25, 35)
	noTouch(makePart(model, "EyeLeft", Vector3.new(0.28, 0.38, 0.1), Vector3.new(-0.38, 4.15, -0.87), eyeColor, Enum.PartType.Ball))
	noTouch(makePart(model, "EyeRight", Vector3.new(0.28, 0.38, 0.1), Vector3.new(0.38, 4.15, -0.87), eyeColor, Enum.PartType.Ball))
	noTouch(makePart(model, "Smile", Vector3.new(0.7, 0.14, 0.08), Vector3.new(0, 3.75, -0.87), eyeColor))
	noTouch(makePart(model, "CheekLeft", Vector3.new(0.3, 0.2, 0.06), Vector3.new(-0.65, 3.9, -0.87), Color3.fromRGB(255, 140, 170), Enum.PartType.Ball))
	noTouch(makePart(model, "CheekRight", Vector3.new(0.3, 0.2, 0.06), Vector3.new(0.65, 3.9, -0.87), Color3.fromRGB(255, 140, 170), Enum.PartType.Ball))

	local builder = ACCESSORY_BUILDERS[((index - 1) % #ACCESSORY_BUILDERS) + 1]
	if builder then
		builder(model, palette.accent)
	end

	local burst = Instance.new("ParticleEmitter")
	burst.Name = "CollectBurst"
	burst.Texture = "rbxassetid://241594419"
	burst.Color = ColorSequence.new(palette.accent, Color3.new(1, 1, 1))
	burst.Lifetime = NumberRange.new(0.4, 0.8)
	burst.Speed = NumberRange.new(8, 14)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.Enabled = false
	burst.Parent = body

	local label = Instance.new("BillboardGui")
	label.Name = "NameLabel"
	label.Size = UDim2.fromOffset(220, 50)
	label.StudsOffset = Vector3.new(0, 1.8, 0)
	label.AlwaysOnTop = true
	label.Adornee = head
	label.Parent = model

	local text = Instance.new("TextLabel")
	text.Name = "NameText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = Brainrots.names[((index - 1) % #Brainrots.names) + 1] or ("Brainrot " .. tostring(index))
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.2
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.Parent = label

	model.PrimaryPart = body
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

return Brainrots
