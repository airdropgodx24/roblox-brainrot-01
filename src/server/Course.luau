-- Course.luau
-- Brainrot Obby Rush: twelve neon stages built along +Z.
-- Course.build(brainrots) clears any old course, builds a fresh
-- "ObbyCourse" folder in the Workspace and returns a world table
-- with checkpoints, kill bricks, animated pieces, the brainrot
-- characters hidden beside the middle stages and a gold podium.

local Course = {}
local STAGE_COUNT = 12
local STAGE_SPACING = 58
local STAGE_RISE = 2
local PALETTE = {
	Color3.fromRGB(255, 64, 120), Color3.fromRGB(255, 145, 40),
	Color3.fromRGB(255, 225, 60), Color3.fromRGB(90, 230, 110),
	Color3.fromRGB(40, 210, 190), Color3.fromRGB(50, 160, 255),
	Color3.fromRGB(110, 95, 255), Color3.fromRGB(185, 80, 255),
	Color3.fromRGB(255, 80, 210), Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(120, 255, 150), Color3.fromRGB(255, 205, 45),
}
local DARK = Color3.fromRGB(22, 22, 32)
local LAVA_RED = Color3.fromRGB(255, 35, 35)
local GOLD = Color3.fromRGB(255, 190, 35)
local WHITE = Color3.fromRGB(245, 245, 255)

local function newPart(parent, name, size, cframe, colour, material)
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = colour
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.Anchored = true
	piece.CanCollide = true
	piece.CanQuery = true
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Parent = parent
	return piece
end

local function newWedge(parent, name, size, cframe, colour, material)
	local piece = Instance.new("WedgePart")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = colour
	piece.Material = material or Enum.Material.SmoothPlastic
	piece.Anchored = true
	piece.CanCollide = true
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Parent = parent
	return piece
end

local function newTruss(parent, name, size, cframe, colour)
	local piece = Instance.new("TrussPart")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cframe
	piece.Color = colour
	piece.Material = Enum.Material.Metal
	piece.Anchored = true
	piece.CanCollide = true
	piece.Parent = parent
	return piece
end

local function glowStrip(parent, name, size, cframe, colour)
	local strip = newPart(parent, name, size, cframe, colour, Enum.Material.Neon)
	strip.CanCollide = false
	return strip
end

function Course.build(brainrots)
	local existing = workspace:FindFirstChild("ObbyCourse")
	if existing then
		existing:Destroy()
	end
	local courseFolder = Instance.new("Folder")
	courseFolder.Name = "ObbyCourse"
	courseFolder.Parent = workspace
	local world = {}
	world.folder = courseFolder
	world.killParts = {}
	world.checkpoints = {}
	world.stageRespawn = {}
	world.animated = {}
	world.characters = {}
	world.confettiEmitters = {}
	world.spawnCFrame = nil
	world.podium = nil
	world.podiumRespawn = nil

	local function killBrick(parent, name, size, cframe)
		local brick = newPart(parent, name, size, cframe, LAVA_RED, Enum.Material.Neon)
		table.insert(world.killParts, brick)
		return brick
	end
	local function platform(parent, name, size, cframe, colour)
		return newPart(parent, name, size, cframe, colour, Enum.Material.SmoothPlastic)
	end
	local function neonPlatform(parent, name, size, cframe, colour)
		return newPart(parent, name, size, cframe, colour, Enum.Material.Neon)
	end

	local function addCheckpoint(stageFolder, index, centre)
		local colour = PALETTE[index]
		local padCFrame = CFrame.new(centre + Vector3.new(0, 0.8, 0))
		local pad = newPart(stageFolder, "Checkpoint" .. index, Vector3.new(8, 0.6, 8), padCFrame, colour, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Name = "CheckpointGlow"
		light.Color = colour
		light.Brightness = 2
		light.Range = 14
		light.Parent = pad
		table.insert(world.checkpoints, pad)
		world.stageRespawn[index] = CFrame.new(centre + Vector3.new(0, 4.5, 0))
		return pad
	end

	local function addDeck(stageFolder, index, origin)
		local colour = PALETTE[index]
		local deck = platform(stageFolder, "StartDeck", Vector3.new(16, 1.2, 16), CFrame.new(origin), DARK)
		glowStrip(stageFolder, "DeckEdgeFront", Vector3.new(16, 0.35, 0.6), CFrame.new(origin + Vector3.new(0, 0.75, 7.8)), colour)
		glowStrip(stageFolder, "DeckEdgeBack", Vector3.new(16, 0.35, 0.6), CFrame.new(origin + Vector3.new(0, 0.75, -7.8)), colour)
		glowStrip(stageFolder, "DeckEdgeLeft", Vector3.new(0.6, 0.35, 16), CFrame.new(origin + Vector3.new(-7.8, 0.75, 0)), colour)
		glowStrip(stageFolder, "DeckEdgeRight", Vector3.new(0.6, 0.35, 16), CFrame.new(origin + Vector3.new(7.8, 0.75, 0)), colour)
		return deck
	end

	local function stageOrigin(index)
		return Vector3.new(0, (index - 1) * STAGE_RISE, (index - 1) * STAGE_SPACING)
	end

	local builders = {}
	builders[1] = function(stageFolder, colour, origin)
		-- Simple jumps: five floating pads, each a little higher.
		for step = 1, 5 do
			local at = origin + Vector3.new(0, step * 0.7, 10 + step * 7)
			neonPlatform(stageFolder, "JumpPad" .. step, Vector3.new(7, 1, 7), CFrame.new(at), colour)
		end
	end
	builders[2] = function(stageFolder, colour, origin)
		-- Narrow beams zig-zagging toward a small rest platform.
		for beam = 1, 3 do
			local x = (beam % 2 == 0) and 3 or -3
			local at = origin + Vector3.new(x, beam * 0.6, 12 + beam * 12)
			platform(stageFolder, "NarrowBeam" .. beam, Vector3.new(2.2, 1, 13), CFrame.new(at), colour)
		end
		local rest = origin + Vector3.new(0, 2.2, 50)
		platform(stageFolder, "BeamRest", Vector3.new(8, 1, 8), CFrame.new(rest), colour)
	end
	builders[3] = function(stageFolder, colour, origin)
		-- A straight staircase that narrows as it climbs.
		for step = 1, 8 do
			local at = origin + Vector3.new(0, step * 1.1, 10 + step * 5)
			local size = Vector3.new(10 - step * 0.5, 1, 4.5)
			platform(stageFolder, "Stair" .. step, size, CFrame.new(at), colour)
		end
	end
	builders[4] = function(stageFolder, colour, origin)
		-- Lava floor below, safe blocks hopping across it.
		local lavaAt = origin + Vector3.new(0, -1.5, 30)
		killBrick(stageFolder, "LavaFloor", Vector3.new(22, 1, 42), CFrame.new(lavaAt))
		for block = 1, 6 do
			local x = ((block % 3) - 1) * 6
			local at = origin + Vector3.new(x, 0.6, 13 + block * 6.5)
			platform(stageFolder, "SafeBlock" .. block, Vector3.new(5.5, 1.2, 5.5), CFrame.new(at), colour)
		end
	end
	builders[5] = function(stageFolder, colour, origin)
		-- Moving platforms sliding sideways over the gap.
		for lane = 1, 3 do
			local base = origin + Vector3.new(0, 1 + lane * 0.8, 14 + lane * 13)
			local mover = neonPlatform(stageFolder, "MovingPlatform" .. lane, Vector3.new(8, 1, 8), CFrame.new(base), colour)
			table.insert(world.animated, {
				kind = "move", part = mover, basePos = base,
				axis = Vector3.new(1, 0, 0), dist = 9,
				speed = 0.7 + lane * 0.22, phase = lane * 1.7, rot = 0,
			})
		end
	end
	builders[6] = function(stageFolder, colour, origin)
		-- Spinner kill bars sweeping a dark runway.
		local runwayAt = origin + Vector3.new(0, 0.5, 30)
		platform(stageFolder, "SpinnerRunway", Vector3.new(9, 1, 44), CFrame.new(runwayAt), DARK)
		for n = 1, 3 do
			local centre = origin + Vector3.new(0, 2.4, 16 + n * 11)
			local hub = newPart(stageFolder, "SpinnerHub" .. n, Vector3.new(1.6, 1.6, 1.6), CFrame.new(centre), colour, Enum.Material.Neon)
			hub.CanCollide = false
			local bar = killBrick(stageFolder, "SpinnerBar" .. n, Vector3.new(17, 0.8, 0.8), CFrame.new(centre))
			table.insert(world.animated, {
				kind = "spinner", part = bar, pivot = CFrame.new(centre),
				speed = 1.1 + n * 0.35, phase = n * 2.1,
			})
		end
	end
	builders[7] = function(stageFolder, colour, origin)
		-- Zigzag planks, each yawed toward the next landing.
		for plank = 1, 7 do
			local side = (plank % 2 == 0) and 5.5 or -5.5
			local yaw = math.rad((plank % 2 == 0) and 18 or -18)
			local at = origin + Vector3.new(side, plank * 0.5, 10 + plank * 6)
			local cf = CFrame.new(at) * CFrame.Angles(0, yaw, 0)
			platform(stageFolder, "ZigzagPlank" .. plank, Vector3.new(9, 1, 5), cf, colour)
		end
	end
	builders[8] = function(stageFolder, colour, origin)
		-- Wall hops: tall walls with ledges on alternating sides.
		for hop = 1, 4 do
			local side = (hop % 2 == 0) and 6 or -6
			local z = 12 + hop * 10
			local wallAt = origin + Vector3.new(side, 5, z)
			newPart(stageFolder, "HopWall" .. hop, Vector3.new(1.2, 11, 9), CFrame.new(wallAt), DARK, Enum.Material.SmoothPlastic)
			local ledgeAt = origin + Vector3.new(-side, 2 + hop * 1.4, z)
			platform(stageFolder, "HopLedge" .. hop, Vector3.new(5, 1, 5), CFrame.new(ledgeAt), colour)
		end
	end
	builders[9] = function(stageFolder, colour, origin)
		-- Shrinking steps: every landing smaller than the last.
		for step = 1, 7 do
			local width = math.max(9 - step * 0.95, 2.4)
			local at = origin + Vector3.new(0, step * 0.9, 10 + step * 6)
			neonPlatform(stageFolder, "ShrinkingStep" .. step, Vector3.new(width, 1, 5.5), CFrame.new(at), colour)
		end
	end
	builders[10] = function(stageFolder, colour, origin)
		-- Truss climb up to a high exit platform.
		local baseAt = origin + Vector3.new(0, 0.5, 14)
		platform(stageFolder, "TrussBase", Vector3.new(10, 1, 10), CFrame.new(baseAt), colour)
		local trussAt = origin + Vector3.new(0, 13.5, 22)
		newTruss(stageFolder, "ClimbTruss", Vector3.new(2, 26, 2), CFrame.new(trussAt), colour)
		local topAt = origin + Vector3.new(0, 27, 34)
		platform(stageFolder, "TrussTop", Vector3.new(11, 1, 11), CFrame.new(topAt), colour)
		local exitAt = origin + Vector3.new(0, 27, 46)
		platform(stageFolder, "TrussExit", Vector3.new(8, 1, 14), CFrame.new(exitAt), DARK)
	end
	builders[11] = function(stageFolder, colour, origin)
		-- Speed ramps: glowing wedges with a bright launch pad.
		for ramp = 1, 3 do
			local z = 12 + ramp * 13
			local rampAt = origin + Vector3.new(0, 1 + ramp * 0.7, z)
			local rampCf = CFrame.new(rampAt) * CFrame.Angles(0, math.rad(180), 0)
			newWedge(stageFolder, "SpeedRamp" .. ramp, Vector3.new(11, 3.5, 11), rampCf, colour, Enum.Material.Neon)
			local padAt = origin + Vector3.new(0, 0.6 + ramp * 0.7, z - 6)
			local pad = newPart(stageFolder, "SpeedPad" .. ramp, Vector3.new(11, 0.5, 3), CFrame.new(padAt), WHITE, Enum.Material.Neon)
			pad.CanCollide = false
		end
	end
	builders[12] = function(stageFolder, colour, origin)
		-- Final ascent: a rising spiral of pads to a summit deck.
		for step = 1, 9 do
			local angle = math.rad(step * 38)
			local x = math.cos(angle) * 7
			local at = origin + Vector3.new(x, step * 1.8, 12 + step * 4.6)
			neonPlatform(stageFolder, "AscentStep" .. step, Vector3.new(6.5, 1, 6.5), CFrame.new(at), colour)
		end
		local summitAt = origin + Vector3.new(0, 17.5, 52)
		platform(stageFolder, "SummitDeck", Vector3.new(14, 1.2, 12), CFrame.new(summitAt), DARK)
	end

	for index = 1, STAGE_COUNT do
		local origin = stageOrigin(index)
		local stageFolder = Instance.new("Folder")
		stageFolder.Name = "Stage" .. index
		stageFolder.Parent = courseFolder
		addDeck(stageFolder, index, origin)
		addCheckpoint(stageFolder, index, origin)
		builders[index](stageFolder, PALETTE[index], origin)
		-- A pair of glowing sign posts marks the entrance to the
		-- stage, coloured to match it, so runners can read at a
		-- glance which stretch of the course they are entering.
		for side = -1, 1, 2 do
			local postAt = origin + Vector3.new(side * 9.5, 3, -6)
			local post = newPart(
				stageFolder,
				"StageSignPost",
				Vector3.new(0.7, 6, 0.7),
				CFrame.new(postAt),
				PALETTE[index],
				Enum.Material.Neon
			)
			post.CanCollide = false
			local capAt = origin + Vector3.new(side * 9.5, 6.4, -6)
			local cap = newPart(
				stageFolder,
				"StageSignCap",
				Vector3.new(1.6, 0.8, 1.6),
				CFrame.new(capAt),
				WHITE,
				Enum.Material.Neon
			)
			cap.CanCollide = false
		end
	end
	world.spawnCFrame = world.stageRespawn[1]

	-- Alcoves beside stages 2 to 11 hold the ten brainrots.
	if brainrots and brainrots.spawn then
		for slot = 1, 10 do
			local stageIndex = slot + 1
			local origin = stageOrigin(stageIndex)
			local centre = origin + Vector3.new(24, 1, 26)
			local alcove = Instance.new("Folder")
			alcove.Name = "Alcove" .. slot
			alcove.Parent = courseFolder
			local floorAt = centre - Vector3.new(0, 1, 0)
			platform(alcove, "AlcoveFloor", Vector3.new(12, 1, 12), CFrame.new(floorAt), PALETTE[stageIndex])
			local trimAt = centre + Vector3.new(0, 0.2, -5.8)
			glowStrip(alcove, "AlcoveTrim", Vector3.new(12, 0.4, 0.6), CFrame.new(trimAt), PALETTE[stageIndex])
			local alcoveCFrame = CFrame.new(centre + Vector3.new(0, 1.2, 0))
			local model = brainrots.spawn(courseFolder, alcoveCFrame, slot)
			world.characters[slot] = model
			if model then
				local basePivot = alcoveCFrame
				if typeof(model) == "Instance" and model:IsA("Model") then
					basePivot = model:GetPivot()
				end
				table.insert(world.animated, {
					kind = "char", model = model,
					basePivot = basePivot, phase = slot * 0.85,
				})
			end
		end
	end

	-- Gold podium past the summit, with confetti on its posts.
	local podiumCentre = stageOrigin(STAGE_COUNT) + Vector3.new(0, 19, 78)
	local podium = newPart(courseFolder, "GoldPodium", Vector3.new(18, 2, 18), CFrame.new(podiumCentre), GOLD, Enum.Material.Metal)
	world.podium = podium
	world.podiumRespawn = CFrame.new(podiumCentre + Vector3.new(0, 5, 0))
	for corner = 1, 4 do
		local x = (corner % 2 == 0) and 7.5 or -7.5
		local z = (corner <= 2) and 7.5 or -7.5
		local postAt = podiumCentre + Vector3.new(x, 4.5, z)
		local post = newPart(courseFolder, "PodiumPost" .. corner, Vector3.new(1.2, 7, 1.2), CFrame.new(postAt), GOLD, Enum.Material.Neon)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Confetti"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(PALETTE[corner * 3], WHITE)
		emitter.Lifetime = NumberRange.new(1.2, 2.4)
		emitter.Rate = 28
		emitter.Speed = NumberRange.new(6, 11)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.Parent = post
		table.insert(world.confettiEmitters, emitter)
	end
	local crownAt = podiumCentre + Vector3.new(0, 2.2, 0)
	newPart(courseFolder, "PodiumCrown", Vector3.new(7, 1, 7), CFrame.new(crownAt), GOLD, Enum.Material.Neon)
	return world
end

return Course
