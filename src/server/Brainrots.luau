-- Brainrots.luau
-- Brainrot Obby Rush -- collectible character factory
--
-- This ModuleScript knows how to build ten silly blocky brainrot
-- creatures out of plain Parts. Every creature shares the same
-- friendly proportions (chunky body, big head, two eyes) but gets
-- its own bright colour scheme and its own signature accessory,
-- so players can tell them apart from across the course.
--
-- Public surface:
--   Brainrots.names            -> array of ten display names
--   Brainrots.spawn(parent, cframe, index) -> Model
--
-- The returned model is named "Brainrot" .. index, has its body
-- set as PrimaryPart, and carries a ParticleEmitter called
-- "CollectBurst" inside that PrimaryPart. The server script
-- fires that emitter when a player collects the character.

local Brainrots = {}

-- Ten original brainrot names, in collection order.
Brainrots.names = {
	"Bloopo the Cube Gremlin",
	"Zigzag Zorp",
	"Noodle Noggin Ned",
	"Captain Crumbletop",
	"Wobble Wombat Bot",
	"Sir Bouncealot Junior",
	"Pudding Pixel Pixie",
	"Turbo Tater Tot",
	"Glitter Gloop Gnome",
	"Moonbeam Muddle Mop",
}

-- One bright colour scheme per character.
-- body: main torso colour, head: head colour,
-- accent: accessory / detail colour, legs: foot colour.
local PALETTES = {
	{ body = Color3.fromRGB(255, 92, 92), head = Color3.fromRGB(255, 178, 120), accent = Color3.fromRGB(255, 214, 64), legs = Color3.fromRGB(84, 60, 140) },
	{ body = Color3.fromRGB(64, 196, 255), head = Color3.fromRGB(170, 235, 255), accent = Color3.fromRGB(255, 105, 180), legs = Color3.fromRGB(30, 90, 160) },
	{ body = Color3.fromRGB(120, 230, 120), head = Color3.fromRGB(220, 255, 170), accent = Color3.fromRGB(255, 140, 40), legs = Color3.fromRGB(40, 120, 70) },
	{ body = Color3.fromRGB(255, 200, 40), head = Color3.fromRGB(255, 235, 160), accent = Color3.fromRGB(200, 60, 200), legs = Color3.fromRGB(120, 70, 20) },
	{ body = Color3.fromRGB(180, 110, 255), head = Color3.fromRGB(230, 200, 255), accent = Color3.fromRGB(60, 230, 200), legs = Color3.fromRGB(80, 40, 140) },
	{ body = Color3.fromRGB(255, 130, 200), head = Color3.fromRGB(255, 205, 235), accent = Color3.fromRGB(255, 220, 0), legs = Color3.fromRGB(150, 50, 110) },
	{ body = Color3.fromRGB(60, 220, 210), head = Color3.fromRGB(180, 255, 245), accent = Color3.fromRGB(255, 120, 120), legs = Color3.fromRGB(20, 110, 110) },
	{ body = Color3.fromRGB(255, 160, 60), head = Color3.fromRGB(255, 215, 150), accent = Color3.fromRGB(80, 160, 255), legs = Color3.fromRGB(140, 80, 20) },
	{ body = Color3.fromRGB(140, 255, 170), head = Color3.fromRGB(210, 255, 220), accent = Color3.fromRGB(255, 80, 160), legs = Color3.fromRGB(50, 130, 80) },
	{ body = Color3.fromRGB(120, 140, 255), head = Color3.fromRGB(200, 210, 255), accent = Color3.fromRGB(255, 240, 120), legs = Color3.fromRGB(50, 60, 150) },
}

-- Small helper: make one anchored Part with the bits every
-- block in a brainrot needs, then let the caller position it.
local function makePart(name, size, colour, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = colour
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- Place a part relative to a root CFrame and parent it.
local function place(model, part, rootCFrame, offset, rotation)
	local cf = rootCFrame * CFrame.new(offset)
	if rotation then
		cf = cf * rotation
	end
	part.CFrame = cf
	part.Parent = model
	return part
end

-- Build the signature accessory for a given index.
--  1 cone hat      2 antenna       3 wings        4 crown
--  5 propeller     6 halo          7 horns        8 mohawk
--  9 glasses      10 rocket pack
local function addAccessory(model, index, rootCFrame, palette)
	local accent = palette.accent

	if index == 1 then
		-- Cone hat: a cheerful party cone on the head.
		local cone = makePart("ConeHat", Vector3.new(1.1, 1.4, 1.1), accent)
		cone.Shape = Enum.PartType.Cylinder
		place(model, cone, rootCFrame, Vector3.new(0, 3.55, 0), CFrame.Angles(0, 0, math.rad(180)))
		local tip = makePart("ConeTip", Vector3.new(0.35, 0.35, 0.35), Color3.fromRGB(255, 255, 255))
		tip.Shape = Enum.PartType.Ball
		place(model, tip, rootCFrame, Vector3.new(0, 4.3, 0))
	elseif index == 2 then
		-- Antenna: a thin stalk with a glowing ball on top.
		local stalk = makePart("AntennaStalk", Vector3.new(0.16, 1.1, 0.16), Color3.fromRGB(60, 60, 70))
		place(model, stalk, rootCFrame, Vector3.new(0, 3.7, 0))
		local ball = makePart("AntennaBall", Vector3.new(0.55, 0.55, 0.55), accent, Enum.Material.Neon)
		ball.Shape = Enum.PartType.Ball
		place(model, ball, rootCFrame, Vector3.new(0, 4.35, 0))
	elseif index == 3 then
		-- Wings: two flat panels angled out from the back.
		local left = makePart("WingLeft", Vector3.new(1.5, 0.9, 0.14), accent)
		place(model, left, rootCFrame, Vector3.new(-1.35, 2.0, 0.45), CFrame.Angles(0, math.rad(-25), math.rad(15)))
		local right = makePart("WingRight", Vector3.new(1.5, 0.9, 0.14), accent)
		place(model, right, rootCFrame, Vector3.new(1.35, 2.0, 0.45), CFrame.Angles(0, math.rad(25), math.rad(-15)))
	elseif index == 4 then
		-- Crown: a gold band with three chunky points.
		local band = makePart("CrownBand", Vector3.new(1.5, 0.4, 1.5), accent, Enum.Material.Metal)
		place(model, band, rootCFrame, Vector3.new(0, 3.35, 0))
		for i = -1, 1 do
			local spike = makePart("CrownSpike" .. tostring(i + 2), Vector3.new(0.32, 0.55, 0.32), accent, Enum.Material.Metal)
			place(model, spike, rootCFrame, Vector3.new(i * 0.5, 3.8, 0))
		end
	elseif index == 5 then
		-- Propeller: a mast plus two blades, beanie-copter style.
		local mast = makePart("PropMast", Vector3.new(0.18, 0.7, 0.18), Color3.fromRGB(70, 70, 80))
		place(model, mast, rootCFrame, Vector3.new(0, 3.55, 0))
		local bladeA = makePart("PropBladeA", Vector3.new(2.0, 0.12, 0.4), accent)
		place(model, bladeA, rootCFrame, Vector3.new(0, 3.95, 0))
		local bladeB = makePart("PropBladeB", Vector3.new(0.4, 0.12, 2.0), accent)
		place(model, bladeB, rootCFrame, Vector3.new(0, 3.95, 0))
	elseif index == 6 then
		-- Halo: a flat neon ring floating above the head.
		local halo = makePart("Halo", Vector3.new(1.4, 0.16, 1.4), accent, Enum.Material.Neon)
		halo.Shape = Enum.PartType.Cylinder
		place(model, halo, rootCFrame, Vector3.new(0, 4.0, 0))
		local inner = makePart("HaloGlow", Vector3.new(0.5, 0.5, 0.5), Color3.fromRGB(255, 255, 220), Enum.Material.Neon)
		inner.Shape = Enum.PartType.Ball
		place(model, inner, rootCFrame, Vector3.new(0, 3.55, 0))
	elseif index == 7 then
		-- Horns: two angled blocks, one per side of the head.
		local left = makePart("HornLeft", Vector3.new(0.35, 0.9, 0.35), accent)
		place(model, left, rootCFrame, Vector3.new(-0.85, 3.55, 0), CFrame.Angles(0, 0, math.rad(30)))
		local right = makePart("HornRight", Vector3.new(0.35, 0.9, 0.35), accent)
		place(model, right, rootCFrame, Vector3.new(0.85, 3.55, 0), CFrame.Angles(0, 0, math.rad(-30)))
	elseif index == 8 then
		-- Mohawk: a row of thin fins running front to back.
		for i = 0, 3 do
			local fin = makePart("MohawkFin" .. tostring(i + 1), Vector3.new(0.18, 0.8, 0.5), accent)
			local z = -0.6 + (i * 0.4)
			place(model, fin, rootCFrame, Vector3.new(0, 3.6, z))
		end
	elseif index == 9 then
		-- Glasses: two dark frames joined by a bridge.
		local frameL = makePart("GlassLeft", Vector3.new(0.62, 0.62, 0.1), Color3.fromRGB(25, 25, 35), Enum.Material.Glass)
		place(model, frameL, rootCFrame, Vector3.new(-0.38, 2.85, -0.56))
		local frameR = makePart("GlassRight", Vector3.new(0.62, 0.62, 0.1), Color3.fromRGB(25, 25, 35), Enum.Material.Glass)
		place(model, frameR, rootCFrame, Vector3.new(0.38, 2.85, -0.56))
		local bridge = makePart("GlassBridge", Vector3.new(0.3, 0.1, 0.1), accent)
		place(model, bridge, rootCFrame, Vector3.new(0, 2.9, -0.56))
	elseif index == 10 then
		-- Rocket pack: two tanks on the back with neon nozzles.
		local tankL = makePart("RocketLeft", Vector3.new(0.55, 1.4, 0.55), accent, Enum.Material.Metal)
		place(model, tankL, rootCFrame, Vector3.new(-0.5, 1.9, 0.65))
		local tankR = makePart("RocketRight", Vector3.new(0.55, 1.4, 0.55), accent, Enum.Material.Metal)
		place(model, tankR, rootCFrame, Vector3.new(0.5, 1.9, 0.65))
		local flameL = makePart("RocketFlameLeft", Vector3.new(0.35, 0.5, 0.35), Color3.fromRGB(255, 170, 40), Enum.Material.Neon)
		place(model, flameL, rootCFrame, Vector3.new(-0.5, 1.0, 0.65))
		local flameR = makePart("RocketFlameRight", Vector3.new(0.35, 0.5, 0.35), Color3.fromRGB(255, 170, 40), Enum.Material.Neon)
		place(model, flameR, rootCFrame, Vector3.new(0.5, 1.0, 0.65))
	end
end

-- Build one brainrot character and drop it into the world.
-- parent: where the model should live (usually a Folder)
-- cframe: where its feet should stand, facing course direction
-- index:  1..10, picks the name, palette and accessory
function Brainrots.spawn(parent, cframe, index)
	local palette = PALETTES[index] or PALETTES[1]
	local displayName = Brainrots.names[index] or ("Brainrot " .. tostring(index))

	local model = Instance.new("Model")
	model.Name = "Brainrot" .. tostring(index)
	model:SetAttribute("BrainrotIndex", index)
	model:SetAttribute("DisplayName", displayName)

	-- Feet first, so the character stands planted on its pad.
	local footL = makePart("FootLeft", Vector3.new(0.55, 0.35, 0.8), palette.legs)
	place(model, footL, cframe, Vector3.new(-0.4, 0.18, 0))
	local footR = makePart("FootRight", Vector3.new(0.55, 0.35, 0.8), palette.legs)
	place(model, footR, cframe, Vector3.new(0.4, 0.18, 0))

	-- Chunky body: the PrimaryPart, and the touch target.
	local body = makePart("Body", Vector3.new(1.7, 1.6, 1.0), palette.body)
	place(model, body, cframe, Vector3.new(0, 1.15, 0))

	-- A lighter belly panel gives the body a toy-like front.
	local belly = makePart("Belly", Vector3.new(1.1, 1.0, 0.12), Color3.fromRGB(255, 250, 235))
	place(model, belly, cframe, Vector3.new(0, 1.1, -0.52))

	-- Stubby arms stuck out at friendly angles.
	local armL = makePart("ArmLeft", Vector3.new(0.4, 1.0, 0.4), palette.body)
	place(model, armL, cframe, Vector3.new(-1.1, 1.35, 0), CFrame.Angles(0, 0, math.rad(20)))
	local armR = makePart("ArmRight", Vector3.new(0.4, 1.0, 0.4), palette.body)
	place(model, armR, cframe, Vector3.new(1.1, 1.35, 0), CFrame.Angles(0, 0, math.rad(-20)))

	-- Big square head sitting on top of the body.
	local head = makePart("Head", Vector3.new(1.6, 1.3, 1.1), palette.head)
	place(model, head, cframe, Vector3.new(0, 2.6, 0))

	-- Two eyes: white blocks with smaller dark pupils, on the
	-- front face (negative Z is the way the model faces).
	for _, side in ipairs({ -1, 1 }) do
		local label = (side < 0) and "Left" or "Right"
		local white = makePart("Eye" .. label, Vector3.new(0.42, 0.5, 0.1), Color3.fromRGB(255, 255, 255))
		place(model, white, cframe, Vector3.new(side * 0.38, 2.8, -0.56))
		local pupil = makePart("Pupil" .. label, Vector3.new(0.2, 0.26, 0.06), Color3.fromRGB(20, 20, 30))
		place(model, pupil, cframe, Vector3.new(side * 0.38, 2.78, -0.63))
	end

	-- A simple smiling mouth made from one thin dark block.
	local mouth = makePart("Mouth", Vector3.new(0.6, 0.12, 0.06), Color3.fromRGB(90, 40, 50))
	place(model, mouth, cframe, Vector3.new(0, 2.25, -0.57))

	-- Rosy cheeks, because every brainrot is glad to be found.
	for _, side in ipairs({ -1, 1 }) do
		local label = (side < 0) and "Left" or "Right"
		local cheek = makePart("Cheek" .. label, Vector3.new(0.28, 0.2, 0.06), Color3.fromRGB(255, 140, 160))
		place(model, cheek, cframe, Vector3.new(side * 0.62, 2.4, -0.57))
	end

	-- The signature accessory finishes the silhouette.
	addAccessory(model, index, cframe, palette)

	-- Collection burst: configured but quiet (Rate 0). The
	-- server emits 30 particles from it on collection.
	local burst = Instance.new("ParticleEmitter")
	burst.Name = "CollectBurst"
	burst.Texture = "rbxassetid://241594419"
	burst.Color = ColorSequence.new(palette.accent, Color3.fromRGB(255, 255, 255))
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	burst.Lifetime = NumberRange.new(0.45, 0.8)
	burst.Speed = NumberRange.new(7, 13)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.Enabled = true
	burst.Parent = body

	model.PrimaryPart = body
	model:PivotTo(cframe)
	model.Parent = parent

	return model
end

return Brainrots
