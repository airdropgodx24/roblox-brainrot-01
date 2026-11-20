-- Course.luau
-- Brainrot Obby Rush: procedural builder for a twelve stage neon obby.
-- The single public entry point is Course.build(brainrots). It assembles
-- the whole course under a fresh Folder in Workspace, wires up every
-- checkpoint, hazard, mover and collectible character, and hands back a
-- world table describing everything the server runtime needs to animate
-- and respawn against.

local Course = {}

-- ---------------------------------------------------------------------------
-- Palette and layout constants
-- ---------------------------------------------------------------------------

local STAGE_COUNT = 12
local STAGE_SPACING = 58
local STAGE_RISE = 2.5
local COURSE_ORIGIN = Vector3.new(0, 6, 0)

local STAGE_COLORS = {
	Color3.fromRGB(255, 64, 120),
	Color3.fromRGB(255, 145, 0),
	Color3.fromRGB(255, 235, 59),
	Color3.fromRGB(105, 255, 120),
	Color3.fromRGB(0, 230, 170),
	Color3.fromRGB(0, 195, 255),
	Color3.fromRGB(70, 120, 255),
	Color3.fromRGB(165, 90, 255),
	Color3.fromRGB(255, 80, 220),
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(120, 255, 235),
	Color3.fromRGB(255, 205, 40),
}

local KILL_COLOR = Color3.fromRGB(255, 30, 30)
local CHECKPOINT_COLOR = Color3.fromRGB(120, 255, 140)
local GOLD_COLOR = Color3.fromRGB(255, 190, 30)
local DARK_TRIM = Color3.fromRGB(24, 24, 34)

-- ---------------------------------------------------------------------------
-- Course.build
-- ---------------------------------------------------------------------------

function Course.build(brainrots)
	local workspace = game:GetService("Workspace")

	local stale = workspace:FindFirstChild("ObbyCourse")
	if stale then
		stale:Destroy()
	end

	local courseFolder = Instance.new("Folder")
	courseFolder.Name = "ObbyCourse"
	courseFolder.Parent = workspace

	local world = {
		folder = courseFolder,
		killParts = {},
		checkpoints = {},
		stageRespawn = {},
		animated = {},
		characters = {},
		confettiEmitters = {},
		spawnCFrame = nil,
		podium = nil,
		podiumRespawn = nil,
	}

	-- -----------------------------------------------------------------------
	-- Small construction helpers (closures over world and courseFolder)
	-- -----------------------------------------------------------------------

	local function makePart(parent, name, size, cframe, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cframe
		part.Color = color
		part.Material = material or Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = true
		part.CanQuery = true
		part.CanTouch = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = parent
		return part
	end

	local function makeBlock(parent, name, size, position, color, material)
		return makePart(parent, name, size, CFrame.new(position), color, material)
	end

	local function makeKill(parent, name, size, cframe)
		local part = makePart(parent, name, size, cframe, KILL_COLOR, Enum.Material.Neon)
		part:SetAttribute("KillBrick", true)
		table.insert(world.killParts, part)
		return part
	end

	local function makeTrim(parent, name, size, position, color)
		local trim = makeBlock(parent, name, size, position, color or DARK_TRIM, Enum.Material.SmoothPlastic)
		trim.CanCollide = false
		return trim
	end

	local function registerMover(part, axis, dist, speed, phase)
		table.insert(world.animated, {
			kind = "move",
			part = part,
			basePos = part.Position,
			axis = axis,
			dist = dist,
			speed = speed,
			phase = phase,
			rot = part.CFrame - part.Position,
		})
	end

	local function registerSpinner(part, pivot, speed, phase)
		table.insert(world.animated, {
			kind = "spinner",
			part = part,
			pivot = pivot,
			speed = speed,
			phase = phase,
		})
	end

	local function stageBase(index)
		local z = COURSE_ORIGIN.Z + (index - 1) * STAGE_SPACING
		local y = COURSE_ORIGIN.Y + (index - 1) * STAGE_RISE
		return Vector3.new(COURSE_ORIGIN.X, y, z)
	end

	-- -----------------------------------------------------------------------
	-- Checkpoint pads: one glowing pad at the head of every stage
	-- -----------------------------------------------------------------------

	local function buildCheckpoint(index, base, color)
		local folder = Instance.new("Folder")
		folder.Name = "Stage" .. index
		folder.Parent = courseFolder

		local deck = makeBlock(
			folder,
			"StartDeck",
			Vector3.new(16, 1, 16),
			base + Vector3.new(0, -0.5, 0),
			color,
			Enum.Material.Neon
		)
		deck:SetAttribute("StageIndex", index)

		makeTrim(folder, "DeckTrim", Vector3.new(17, 0.35, 17), base + Vector3.new(0, -1.05, 0))

		local padPos = base + Vector3.new(0, 0.3, 0)
		local pad = makePart(
			folder,
			"Checkpoint" .. index,
			Vector3.new(7, 0.6, 7),
			CFrame.new(padPos),
			CHECKPOINT_COLOR,
			Enum.Material.Neon
		)
		pad.CanCollide = false
		pad:SetAttribute("CheckpointIndex", index)

		local light = Instance.new("PointLight")
		light.Color = CHECKPOINT_COLOR
		light.Brightness = 1.6
		light.Range = 14
		light.Parent = pad

		world.checkpoints[index] = pad
		world.stageRespawn[index] = CFrame.new(base + Vector3.new(0, 3.2, 0))
		return folder
	end

	-- -----------------------------------------------------------------------
	-- Per-stage gimmicks. Each receives its stage folder, base position and
	-- colour, and fills the stretch of +Z ahead of the start deck.
	-- -----------------------------------------------------------------------

	local gimmicks = {}

	-- Stage 1: plain hops across floating pads of shrinking gaps.
	gimmicks[1] = function(folder, base, color)
		local z = base.Z + 13
		for step = 1, 5 do
			local pos = Vector3.new(((step % 2) * 2 - 1) * 2.5, base.Y + step * 0.4, z + step * 6.5)
			makeBlock(folder, "HopPad" .. step, Vector3.new(6, 1, 6), pos, color, Enum.Material.Neon)
		end
	end

	-- Stage 2: two long narrow beams with a rest block in the middle.
	gimmicks[2] = function(folder, base, color)
		makeBlock(folder, "BeamA", Vector3.new(1.6, 0.8, 17), base + Vector3.new(-3, 0.4, 17), color, Enum.Material.Neon)
		makeBlock(folder, "RestBlock", Vector3.new(6, 1, 6), base + Vector3.new(0, 0.2, 27), color, Enum.Material.Neon)
		makeBlock(folder, "BeamB", Vector3.new(1.6, 0.8, 17), base + Vector3.new(3, 0.4, 37), color, Enum.Material.Neon)
	end

	-- Stage 3: a staircase that climbs, plateaus, then drops back down.
	gimmicks[3] = function(folder, base, color)
		for step = 1, 7 do
			local pos = base + Vector3.new(0, step * 0.9, 11 + step * 3.4)
			makeBlock(folder, "Stair" .. step, Vector3.new(9, 1, 3.6), pos, color, Enum.Material.Neon)
		end
		makeBlock(folder, "StairTop", Vector3.new(10, 1, 8), base + Vector3.new(0, 7.2, 38), color, Enum.Material.Neon)
		for step = 1, 3 do
			local pos = base + Vector3.new(0, 7.2 - step * 1.8, 43 + step * 3.2)
			makeBlock(folder, "StairDown" .. step, Vector3.new(8, 1, 3.4), pos, color, Enum.Material.Neon)
		end
	end

	-- Stage 4: a lava sheet with a dotted path of safe blocks over it.
	gimmicks[4] = function(folder, base, color)
		local lavaCf = CFrame.new(base + Vector3.new(0, -0.4, 27))
		makeKill(folder, "LavaFloor", Vector3.new(20, 0.8, 42), lavaCf)
		local offsets = { -6, 4, -3, 6, 0, -5, 3 }
		for step, xOff in ipairs(offsets) do
			local pos = base + Vector3.new(xOff, 0.7, 10 + step * 5.6)
			makeBlock(folder, "SafeBlock" .. step, Vector3.new(4.4, 1, 4.4), pos, color, Enum.Material.Neon)
		end
	end

	-- Stage 5: moving platforms ferrying the player along and across.
	gimmicks[5] = function(folder, base, color)
		makeBlock(folder, "LaunchPad", Vector3.new(8, 1, 6), base + Vector3.new(0, 0, 12), color, Enum.Material.Neon)
		local ferryA = makeBlock(folder, "FerryA", Vector3.new(6, 1, 6), base + Vector3.new(0, 0.6, 22), color, Enum.Material.Neon)
		registerMover(ferryA, Vector3.new(1, 0, 0), 6, 0.9, 0)
		local ferryB = makeBlock(folder, "FerryB", Vector3.new(6, 1, 6), base + Vector3.new(0, 1.2, 34), color, Enum.Material.Neon)
		registerMover(ferryB, Vector3.new(0, 0, 1), 5, 1.15, math.pi / 2)
		makeBlock(folder, "LandingPad", Vector3.new(8, 1, 6), base + Vector3.new(0, 1.4, 46), color, Enum.Material.Neon)
	end

	-- Stage 6: spinning kill bars sweeping a wide circular arena deck.
	gimmicks[6] = function(folder, base, color)
		local arenaPos = base + Vector3.new(0, 0, 27)
		makeBlock(folder, "ArenaDeck", Vector3.new(22, 1, 34), arenaPos + Vector3.new(0, -0.5, 0), color, Enum.Material.Neon)
		for barIndex = 1, 2 do
			local pivot = arenaPos + Vector3.new(0, 1.6, -8 + barIndex * 13)
			local hub = makeBlock(folder, "SpinnerHub" .. barIndex, Vector3.new(2.4, 2.4, 2.4), pivot, DARK_TRIM, Enum.Material.Metal)
			hub.Shape = Enum.PartType.Cylinder
			local bar = makePart(
				folder,
				"SpinnerBar" .. barIndex,
				Vector3.new(19, 0.9, 1.1),
				CFrame.new(pivot),
				KILL_COLOR,
				Enum.Material.Neon
			)
			bar.CanCollide = false
			bar:SetAttribute("KillBrick", true)
			table.insert(world.killParts, bar)
			registerSpinner(bar, pivot, 1.4 + barIndex * 0.35, barIndex * 1.7)
		end
	end

	-- Stage 7: zigzag planks alternating left and right.
	gimmicks[7] = function(folder, base, color)
		for step = 1, 6 do
			local side = (step % 2 == 0) and 1 or -1
			local cf = CFrame.new(base + Vector3.new(side * 5.5, step * 0.35, 10 + step * 6.4))
				* CFrame.Angles(0, math.rad(side * 24), 0)
			makePart(folder, "ZigPlank" .. step, Vector3.new(11, 0.9, 3.2), cf, color, Enum.Material.Neon)
		end
	end

	-- Stage 8: wall hops between tall panels with small ledges.
	gimmicks[8] = function(folder, base, color)
		for step = 1, 4 do
			local side = (step % 2 == 0) and 1 or -1
			local wallPos = base + Vector3.new(side * 6, 3.4, 11 + step * 8.5)
			makeBlock(folder, "HopWall" .. step, Vector3.new(1.4, 7.5, 6), wallPos, color, Enum.Material.Neon)
			local ledgePos = base + Vector3.new(side * 4.2, 1.1 + step * 0.5, 11 + step * 8.5)
			makeBlock(folder, "HopLedge" .. step, Vector3.new(3.4, 0.9, 5), ledgePos, color, Enum.Material.Neon)
		end
		makeBlock(folder, "WallExit", Vector3.new(9, 1, 7), base + Vector3.new(0, 3.4, 48), color, Enum.Material.Neon)
	end

	-- Stage 9: steps that shrink as they climb.
	gimmicks[9] = function(folder, base, color)
		for step = 1, 7 do
			local width = 9 - step * 0.95
			local pos = base + Vector3.new(0, step * 0.85, 10 + step * 5.4)
			makeBlock(folder, "ShrinkStep" .. step, Vector3.new(width, 1, 4.6), pos, color, Enum.Material.Neon)
		end
		makeBlock(folder, "ShrinkTop", Vector3.new(8, 1, 7), base + Vector3.new(0, 6.8, 50), color, Enum.Material.Neon)
	end

	-- Stage 10: a truss climb up a framed tower, then a drop to the exit.
	gimmicks[10] = function(folder, base, color)
		local towerBase = base + Vector3.new(0, 0, 20)
		for corner = 1, 4 do
			local xOff = (corner <= 2) and -4.5 or 4.5
			local zOff = (corner % 2 == 0) and -4.5 or 4.5
			makeBlock(folder, "TowerPost" .. corner, Vector3.new(1.2, 17, 1.2), towerBase + Vector3.new(xOff, 8.5, zOff), DARK_TRIM, Enum.Material.Metal)
		end
		local truss = Instance.new("TrussPart")
		truss.Name = "ClimbTruss"
		truss.Size = Vector3.new(2, 17, 2)
		truss.CFrame = CFrame.new(towerBase + Vector3.new(0, 8.5, 0))
		truss.Color = color
		truss.Material = Enum.Material.Neon
		truss.Anchored = true
		truss.Parent = folder
		makeBlock(folder, "TowerTop", Vector3.new(12, 1, 12), towerBase + Vector3.new(0, 17.4, 0), color, Enum.Material.Neon)
		makeBlock(folder, "TowerExit", Vector3.new(8, 1, 6), base + Vector3.new(0, 4, 46), color, Enum.Material.Neon)
	end

	-- Stage 11: angled speed ramps linked by short flat run-ups.
	gimmicks[11] = function(folder, base, color)
		for rampIndex = 1, 3 do
			local rampZ = 10 + rampIndex * 12
			makeBlock(folder, "RunUp" .. rampIndex, Vector3.new(9, 1, 6), base + Vector3.new(0, rampIndex * 0.6, rampZ), color, Enum.Material.Neon)
			local wedge = Instance.new("WedgePart")
			wedge.Name = "SpeedRamp" .. rampIndex
			wedge.Size = Vector3.new(9, 3.2, 7)
			wedge.CFrame = CFrame.new(base + Vector3.new(0, rampIndex * 0.6 + 1.4, rampZ + 6))
				* CFrame.Angles(0, math.rad(180), 0)
			wedge.Color = color
			wedge.Material = Enum.Material.Neon
			wedge.Anchored = true
			wedge.TopSurface = Enum.SurfaceType.Smooth
			wedge.BottomSurface = Enum.SurfaceType.Smooth
			wedge.Parent = folder
			local stripe = makeBlock(
				folder,
				"RampStripe" .. rampIndex,
				Vector3.new(9.2, 0.3, 1),
				base + Vector3.new(0, rampIndex * 0.6 + 0.6, rampZ + 2.6),
				Color3.fromRGB(255, 255, 255),
				Enum.Material.Neon
			)
			stripe.CanCollide = false
		end
	end

	-- Stage 12: the final ascent, a switchback climb high above the course.
	gimmicks[12] = function(folder, base, color)
		for step = 1, 9 do
			local side = (step % 2 == 0) and 1 or -1
			local pos = base + Vector3.new(side * 3.5, step * 1.5, 9 + step * 4.6)
			makeBlock(folder, "AscentStep" .. step, Vector3.new(7.5, 1, 4.8), pos, color, Enum.Material.Neon)
		end
		local crownPos = base + Vector3.new(0, 15.5, 54)
		makeBlock(folder, "CrownDeck", Vector3.new(14, 1.2, 12), crownPos, color, Enum.Material.Neon)
		makeTrim(folder, "CrownTrim", Vector3.new(15, 0.4, 13), crownPos + Vector3.new(0, -0.85, 0), GOLD_COLOR)
	end

	-- -----------------------------------------------------------------------
	-- Assemble every stage, then tuck a brainrot alcove beside stages 2..11
	-- -----------------------------------------------------------------------

	for index = 1, STAGE_COUNT do
		local base = stageBase(index)
		local color = STAGE_COLORS[index]
		local folder = buildCheckpoint(index, base, color)
		gimmicks[index](folder, base, color)

		if index >= 2 and index <= 11 then
			local charIndex = index - 1
			local sideSign = (charIndex % 2 == 0) and 1 or -1
			local alcovePos = base + Vector3.new(sideSign * 17, 0, 24)
			makeBlock(
				folder,
				"AlcoveFloor" .. charIndex,
				Vector3.new(11, 1, 11),
				alcovePos + Vector3.new(0, -0.5, 0),
				color,
				Enum.Material.Neon
			)
			makeBlock(
				folder,
				"AlcoveBridge" .. charIndex,
				Vector3.new(9, 0.8, 3),
				base + Vector3.new(sideSign * 9.5, -0.1, 24),
				color,
				Enum.Material.Neon
			)
			local alcoveCFrame = CFrame.new(alcovePos + Vector3.new(0, 1.2, 0))
				* CFrame.Angles(0, math.rad(sideSign * -90), 0)
			local model = brainrots.spawn(courseFolder, alcoveCFrame, charIndex)
			if model then
				world.characters[charIndex] = model
				table.insert(world.animated, {
					kind = "char",
					model = model,
					basePivot = alcoveCFrame,
					phase = charIndex * 0.9,
				})
			end
		end
	end

	world.spawnCFrame = world.stageRespawn[1]

	-- -----------------------------------------------------------------------
	-- Finish podium: a gold platform past the crown deck with confetti posts
	-- -----------------------------------------------------------------------

	local lastBase = stageBase(STAGE_COUNT)
	local podiumPos = lastBase + Vector3.new(0, 16.6, 70)

	local podium = makeBlock(courseFolder, "Podium", Vector3.new(13, 1.6, 13), podiumPos, GOLD_COLOR, Enum.Material.Neon)
	podium.Shape = Enum.PartType.Cylinder
	podium.CFrame = CFrame.new(podiumPos) * CFrame.Angles(0, 0, math.rad(90))
	podium:SetAttribute("Podium", true)
	world.podium = podium
	world.podiumRespawn = CFrame.new(podiumPos + Vector3.new(0, 3.4, 0))

	makeBlock(courseFolder, "PodiumStep", Vector3.new(8, 1, 5), podiumPos + Vector3.new(0, -1.6, -9), GOLD_COLOR, Enum.Material.Neon)

	for postIndex = 1, 4 do
		local angle = (postIndex - 1) * (math.pi / 2) + math.pi / 4
		local postPos = podiumPos + Vector3.new(math.cos(angle) * 7.6, 2.6, math.sin(angle) * 7.6)
		local post = makeBlock(courseFolder, "PodiumPost" .. postIndex, Vector3.new(0.9, 5.4, 0.9), postPos, GOLD_COLOR, Enum.Material.Metal)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Confetti"
		emitter.Texture = "rbxassetid://241594314"
		emitter.Color = ColorSequence.new(STAGE_COLORS[postIndex * 3 - 2], STAGE_COLORS[postIndex * 3])
		emitter.Rate = 26
		emitter.Lifetime = NumberRange.new(1.4, 2.4)
		emitter.Speed = NumberRange.new(9, 15)
		emitter.SpreadAngle = Vector2.new(38, 38)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-180, 180)
		emitter.Size = NumberSequence.new(0.55)
		emitter.Parent = post
		table.insert(world.confettiEmitters, emitter)
	end

	return world
end

return Course
