-- Course.luau
-- Builds the whole "Brainrot Obby Rush" world at runtime: start plaza, 12
-- checkpoint stages, 10 collectible brainrots (via the Brainrots module) and
-- the finish podium. Stages are authored in a local frame (x = right,
-- y = top-surface height, z = forward) and chained together with yaw turns
-- and height gains so the course climbs and snakes through the sky.
--
-- Returns a table:
--   checkpoints[i]  checkpoint pad Part for stage i (attribute "Checkpoint")
--   stageRespawn[i] CFrame to respawn at for stage i
--   spawnCFrame     initial spawn on the plaza
--   podium          finish Part (attribute "Podium")
--   podiumRespawn   CFrame on the podium
--   killParts       Parts that kill on touch (lava, spinner bars)
--   characters      map of brainrot index -> Model
--   animated        entries for the server animation loop:
--                     {kind="spinner", part, pivot, speed, phase}
--                     {kind="move", part, basePos, rot, axis, dist, speed, phase}
--                     {kind="char", model, basePivot, phase}
--   confettiEmitters  ParticleEmitters fired on a win

local Course = {}

local START_HEIGHT = 20
local WHITE = Color3.fromRGB(255, 255, 255)

-- Element kinds: plat (static platform), lava (kill floor), move (sliding
-- platform), spinner (rotating kill bar on a platform), stairs (solid steps),
-- char (brainrot collectible standing at x/y/z, y = surface it stands on).
local STAGES = {
	{
		name = "First Steps", yaw = 0, length = 55, exitY = 0,
		color = Color3.fromRGB(255, 85, 170),
		elements = {
			{ t = "plat", x = 0, y = 0, z = 10, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 0, z = 19, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 0, z = 28, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 0, z = 37, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 0, z = 46, w = 7, d = 7 },
			{ t = "plat", x = 10, y = 0, z = 28, w = 6, d = 6 },
			{ t = "char", idx = 1, x = 10, y = 0, z = 28 },
		},
	},
	{
		name = "Beam Walk", yaw = 0, length = 60, exitY = 2,
		color = Color3.fromRGB(85, 225, 255),
		elements = {
			{ t = "plat", x = 0, y = 0, z = 10, w = 3, d = 11 },
			{ t = "plat", x = 0, y = 1, z = 21, w = 3, d = 11 },
			{ t = "plat", x = -3, y = 1, z = 32, w = 3.5, d = 10 },
			{ t = "plat", x = 3, y = 2, z = 43, w = 3.5, d = 10 },
			{ t = "plat", x = 0, y = 2, z = 53, w = 8, d = 8 },
			{ t = "plat", x = 9, y = 1, z = 21, w = 6, d = 6 },
			{ t = "char", idx = 2, x = 9, y = 1, z = 21 },
		},
	},
	{
		name = "Lava Leaps", yaw = 20, length = 58, exitY = 2,
		color = Color3.fromRGB(255, 140, 0),
		elements = {
			{ t = "lava", x = 0, y = -0.8, z = 29, w = 18, d = 48 },
			{ t = "plat", x = 0, y = 0, z = 10, w = 6, d = 6 },
			{ t = "plat", x = 0, y = 0.5, z = 20, w = 6, d = 6 },
			{ t = "plat", x = 0, y = 1, z = 30, w = 6, d = 6 },
			{ t = "plat", x = 0, y = 1.5, z = 40, w = 6, d = 6 },
			{ t = "plat", x = 0, y = 2, z = 50, w = 7, d = 7 },
			{ t = "plat", x = -10, y = 1, z = 30, w = 6, d = 6 },
			{ t = "char", idx = 3, x = -10, y = 1, z = 30 },
		},
	},
	{
		name = "Stairway to Brainrot", yaw = 90, length = 64, exitY = 4,
		color = Color3.fromRGB(150, 255, 70),
		elements = {
			{ t = "stairs", x = 0, z = 8, w = 8, steps = 6, rise = 1.2, run = 4 },
			{ t = "plat", x = 0, y = 7, z = 38, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 5.5, z = 47, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 4, z = 56, w = 8, d = 8 },
			{ t = "char", idx = 4, x = 0, y = 7, z = 38 },
		},
	},
	{
		name = "Spinner Alley", yaw = 90, length = 62, exitY = 4,
		color = Color3.fromRGB(175, 85, 255),
		elements = {
			{ t = "plat", x = 0, y = 0, z = 10, w = 9, d = 9 },
			{ t = "spinner", x = 0, y = 0, z = 10, len = 13, speed = 1.0 },
			{ t = "plat", x = 0, y = 1, z = 22, w = 8, d = 8 },
			{ t = "plat", x = 0, y = 2, z = 33, w = 9, d = 9 },
			{ t = "spinner", x = 0, y = 2, z = 33, len = 13, speed = -1.3 },
			{ t = "plat", x = 0, y = 3, z = 45, w = 8, d = 8 },
			{ t = "plat", x = 0, y = 4, z = 55, w = 8, d = 8 },
			{ t = "plat", x = 10, y = 2, z = 33, w = 6, d = 6 },
			{ t = "char", idx = 5, x = 10, y = 2, z = 33 },
		},
	},
	{
		name = "Movers", yaw = 55, length = 64, exitY = 6,
		color = Color3.fromRGB(255, 215, 0),
		elements = {
			{ t = "plat", x = 0, y = 0, z = 9, w = 8, d = 8 },
			{ t = "move", x = 0, y = 1, z = 20, w = 7, d = 7, axis = "z", dist = 8, speed = 0.55 },
			{ t = "plat", x = 0, y = 3, z = 33, w = 8, d = 8 },
			{ t = "move", x = 0, y = 4, z = 45, w = 7, d = 7, axis = "x", dist = 10, speed = 0.7 },
			{ t = "plat", x = 0, y = 6, z = 57, w = 8, d = 8 },
			{ t = "plat", x = -10, y = 3, z = 33, w = 6, d = 6 },
			{ t = "char", idx = 6, x = -10, y = 3, z = 33 },
		},
	},
	{
		name = "Zigzag Sky", yaw = 0, length = 60, exitY = 6,
		color = Color3.fromRGB(0, 210, 170),
		elements = {
			{ t = "plat", x = -5, y = 1, z = 10, w = 7, d = 7 },
			{ t = "plat", x = 5, y = 2, z = 20, w = 7, d = 7 },
			{ t = "plat", x = -5, y = 3, z = 30, w = 7, d = 7 },
			{ t = "plat", x = 5, y = 4, z = 40, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 5, z = 49, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 6, z = 55, w = 8, d = 8 },
			{ t = "plat", x = 13, y = 2, z = 20, w = 6, d = 6 },
			{ t = "char", idx = 7, x = 13, y = 2, z = 20 },
		},
	},
	{
		name = "Wall Hop", yaw = -40, length = 58, exitY = 8,
		color = Color3.fromRGB(255, 70, 70),
		elements = {
			{ t = "plat", x = -4, y = 1, z = 10, w = 6, d = 6 },
			{ t = "plat", x = 4, y = 2.5, z = 19, w = 6, d = 6 },
			{ t = "plat", x = -4, y = 4, z = 28, w = 6, d = 6 },
			{ t = "plat", x = 4, y = 5.5, z = 37, w = 6, d = 6 },
			{ t = "plat", x = -2, y = 7, z = 46, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 8, z = 53, w = 8, d = 8 },
			{ t = "plat", x = -12, y = 4, z = 28, w = 6, d = 6 },
			{ t = "char", idx = 8, x = -12, y = 4, z = 28 },
		},
	},
	{
		name = "Spinner Gauntlet", yaw = -90, length = 62, exitY = 8,
		color = Color3.fromRGB(255, 0, 190),
		elements = {
			{ t = "plat", x = 0, y = 1, z = 10, w = 9, d = 9 },
			{ t = "spinner", x = 0, y = 1, z = 10, len = 13, speed = 1.4 },
			{ t = "plat", x = 0, y = 3, z = 22, w = 8, d = 8 },
			{ t = "plat", x = 0, y = 5, z = 34, w = 9, d = 9 },
			{ t = "spinner", x = 0, y = 5, z = 34, len = 13, speed = -1.6 },
			{ t = "plat", x = 0, y = 7, z = 46, w = 8, d = 8 },
			{ t = "plat", x = 0, y = 8, z = 56, w = 8, d = 8 },
			{ t = "plat", x = 10, y = 5, z = 34, w = 6, d = 6 },
			{ t = "char", idx = 9, x = 10, y = 5, z = 34 },
		},
	},
	{
		name = "Lava River", yaw = -90, length = 60, exitY = 10,
		color = Color3.fromRGB(255, 95, 0),
		elements = {
			{ t = "lava", x = 0, y = -0.8, z = 30, w = 20, d = 50 },
			{ t = "plat", x = 0, y = 2, z = 10, w = 6, d = 6 },
			{ t = "plat", x = 3, y = 4, z = 20, w = 6, d = 6 },
			{ t = "plat", x = -3, y = 6, z = 30, w = 6, d = 6 },
			{ t = "plat", x = 3, y = 8, z = 40, w = 6, d = 6 },
			{ t = "plat", x = 0, y = 10, z = 52, w = 8, d = 8 },
			{ t = "plat", x = -11, y = 6, z = 30, w = 6, d = 6 },
			{ t = "char", idx = 10, x = -11, y = 6, z = 30 },
		},
	},
	{
		name = "Sky Beams", yaw = -140, length = 60, exitY = 11,
		color = Color3.fromRGB(80, 180, 255),
		elements = {
			{ t = "plat", x = 0, y = 2, z = 10, w = 3, d = 12 },
			{ t = "plat", x = 0, y = 4, z = 23, w = 3, d = 12 },
			{ t = "plat", x = -3, y = 6, z = 35, w = 3.5, d = 10 },
			{ t = "plat", x = 3, y = 8, z = 46, w = 3.5, d = 10 },
			{ t = "plat", x = 0, y = 11, z = 55, w = 8, d = 8 },
		},
	},
	{
		name = "Final Climb", yaw = 180, length = 66, exitY = 13,
		color = Color3.fromRGB(255, 200, 40),
		elements = {
			{ t = "stairs", x = 0, z = 8, w = 8, steps = 5, rise = 1.4, run = 4 },
			{ t = "plat", x = 0, y = 9, z = 35, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 11, z = 44, w = 7, d = 7 },
			{ t = "plat", x = 0, y = 13, z = 52, w = 8, d = 8 },
		},
	},
}

local function makePart(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function makeSign(parent, cframe, width, height, titleText, subText, bgColor)
	local board = makePart(parent, "Sign", Vector3.new(width, height, 0.6), cframe, bgColor, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.6, 0)
	title.Position = UDim2.new(0, 0, 0.05, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = WHITE
	title.TextStrokeTransparency = 0.45
	title.Text = titleText
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, 0, 0.3, 0)
	sub.Position = UDim2.new(0, 0, 0.66, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(255, 240, 180)
	sub.TextStrokeTransparency = 0.5
	sub.Text = subText
	sub.Parent = gui
	return board
end

local function makePadLabel(pad, text)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PadLabel"
	gui.Size = UDim2.fromOffset(190, 46)
	gui.StudsOffset = Vector3.new(0, 3.6, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = WHITE
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	gui.Parent = pad
end

function Course.build(brainrots)
	local folder = Instance.new("Folder")
	folder.Name = "Course"
	folder.Parent = workspace

	local charFolder = Instance.new("Folder")
	charFolder.Name = "Brainrots"
	charFolder.Parent = workspace

	local result = {
		checkpoints = {},
		stageRespawn = {},
		killParts = {},
		characters = {},
		animated = {},
		confettiEmitters = {},
	}

	-- Chain the stage frames together.
	local frames = {}
	local pos = Vector3.new(0, START_HEIGHT, 0)
	for i, def in ipairs(STAGES) do
		local frame = CFrame.new(pos) * CFrame.Angles(0, math.rad(def.yaw), 0)
		frames[i] = frame
		pos = (frame * CFrame.new(0, def.exitY, def.length)).Position
	end
	local lastDef = STAGES[#STAGES]
	local podiumFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(lastDef.yaw), 0)

	-- Start plaza under stage 1, with the big title sign.
	local frame1 = frames[1]
	makePart(folder, "Plaza", Vector3.new(26, 1, 26), frame1 * CFrame.new(0, -0.56, -2),
		STAGES[1].color:Lerp(Color3.fromRGB(0, 0, 0), 0.15), Enum.Material.SmoothPlastic)
	makePart(folder, "SignPostL", Vector3.new(0.8, 7.5, 0.8), frame1 * CFrame.new(-9, 3.75, 6),
		Color3.fromRGB(40, 40, 55), Enum.Material.SmoothPlastic)
	makePart(folder, "SignPostR", Vector3.new(0.8, 7.5, 0.8), frame1 * CFrame.new(9, 3.75, 6),
		Color3.fromRGB(40, 40, 55), Enum.Material.SmoothPlastic)
	makeSign(folder, frame1 * CFrame.new(0, 7.5, 6) * CFrame.Angles(0, math.pi, 0), 22, 7,
		"BRAINROT OBBY RUSH", "Collect all 10 brainrots - Reach the podium!",
		Color3.fromRGB(30, 20, 60))

	result.spawnCFrame = frame1 * CFrame.new(0, 3.5, -6) * CFrame.Angles(0, math.pi, 0)

	-- Stages.
	for i, def in ipairs(STAGES) do
		local frame = frames[i]
		local stageFolder = Instance.new("Folder")
		stageFolder.Name = "Stage" .. i
		stageFolder.Parent = folder

		-- Checkpoint pad at the stage origin (top a hair above stage level 0).
		local pad = makePart(stageFolder, "Checkpoint" .. i, Vector3.new(10, 1, 10),
			frame * CFrame.new(0, -0.45, 0), def.color:Lerp(WHITE, 0.3), Enum.Material.Neon)
		pad:SetAttribute("Checkpoint", i)
		makePadLabel(pad, "STAGE " .. i)
		result.checkpoints[i] = pad
		result.stageRespawn[i] = frame * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, math.pi, 0)

		local platCount = 0
		for j, e in ipairs(def.elements) do
			if e.t == "plat" then
				platCount += 1
				local shade = def.color:Lerp(WHITE, (platCount % 3) * 0.1)
				makePart(stageFolder, "Platform", Vector3.new(e.w, 1, e.d),
					frame * CFrame.new(e.x, e.y - 0.5, e.z), shade, Enum.Material.SmoothPlastic)
			elseif e.t == "lava" then
				local lava = makePart(stageFolder, "Lava", Vector3.new(e.w, 1, e.d),
					frame * CFrame.new(e.x, e.y - 0.5, e.z),
					Color3.fromRGB(255, 55, 0), Enum.Material.Neon)
				lava:SetAttribute("Kill", true)
				table.insert(result.killParts, lava)
			elseif e.t == "move" then
				local p = makePart(stageFolder, "MovingPlatform", Vector3.new(e.w, 1, e.d),
					frame * CFrame.new(e.x, e.y - 0.5, e.z),
					def.color:Lerp(WHITE, 0.25), Enum.Material.SmoothPlastic)
				local axisLocal = e.axis == "x" and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1)
				table.insert(result.animated, {
					kind = "move",
					part = p,
					basePos = p.CFrame.Position,
					rot = p.CFrame - p.CFrame.Position,
					axis = frame:VectorToWorldSpace(axisLocal),
					dist = e.dist,
					speed = e.speed,
					phase = j * 1.3,
				})
			elseif e.t == "spinner" then
				local pivot = frame:PointToWorldSpace(Vector3.new(e.x, e.y + 1.1, e.z))
				local hub = makePart(stageFolder, "SpinnerHub", Vector3.new(1.8, 1.8, 1.8),
					CFrame.new(pivot), Color3.fromRGB(35, 35, 45), Enum.Material.SmoothPlastic)
				hub.Shape = Enum.PartType.Ball
				hub.CanCollide = false
				local bar = makePart(stageFolder, "SpinnerBar", Vector3.new(e.len, 1.1, 1.1),
					CFrame.new(pivot), Color3.fromRGB(255, 40, 40), Enum.Material.SmoothPlastic)
				bar.CanCollide = false
				bar:SetAttribute("Kill", true)
				table.insert(result.killParts, bar)
				table.insert(result.animated, {
					kind = "spinner",
					part = bar,
					pivot = pivot,
					speed = e.speed,
					phase = j * 0.9,
				})
			elseif e.t == "stairs" then
				for s = 0, e.steps - 1 do
					local topY = e.rise * (s + 1)
					makePart(stageFolder, "Step", Vector3.new(e.w, topY, e.run),
						frame * CFrame.new(e.x, topY / 2, e.z + e.run * s + e.run / 2),
						def.color:Lerp(WHITE, (s % 3) * 0.08), Enum.Material.SmoothPlastic)
				end
			elseif e.t == "char" then
				local base = frame * CFrame.new(e.x, e.y, e.z)
				local model = brainrots.build(e.idx, base)
				model.Parent = charFolder
				result.characters[e.idx] = model
				table.insert(result.animated, {
					kind = "char",
					model = model,
					basePivot = model.WorldPivot,
					phase = e.idx * 0.7,
				})
			end
		end
	end

	-- Finish podium.
	local podiumFolder = Instance.new("Folder")
	podiumFolder.Name = "Podium"
	podiumFolder.Parent = folder

	makePart(podiumFolder, "PodiumGlow", Vector3.new(17.5, 0.5, 17.5),
		podiumFrame * CFrame.new(0, -0.95, 0), Color3.fromRGB(200, 150, 20), Enum.Material.Neon)
	local podium = makePart(podiumFolder, "Podium", Vector3.new(16, 1, 16),
		podiumFrame * CFrame.new(0, -0.45, 0), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
	podium:SetAttribute("Podium", true)
	makePadLabel(podium, "FINISH")
	result.podium = podium
	result.podiumRespawn = podiumFrame * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, math.pi, 0)

	makePart(podiumFolder, "SignPostL", Vector3.new(0.8, 6.5, 0.8), podiumFrame * CFrame.new(-7.5, 3.25, 6),
		Color3.fromRGB(40, 40, 55), Enum.Material.SmoothPlastic)
	makePart(podiumFolder, "SignPostR", Vector3.new(0.8, 6.5, 0.8), podiumFrame * CFrame.new(7.5, 3.25, 6),
		Color3.fromRGB(40, 40, 55), Enum.Material.SmoothPlastic)
	makeSign(podiumFolder, podiumFrame * CFrame.new(0, 6.5, 6) * CFrame.Angles(0, math.pi, 0), 17, 5.5,
		"FINISH!", "You made it to the podium!", Color3.fromRGB(60, 40, 0))

	-- Confetti cannons (invisible part above the podium with two emitters).
	local cannon = makePart(podiumFolder, "ConfettiCannon", Vector3.new(1, 1, 1),
		podiumFrame * CFrame.new(0, 5, 0), WHITE, Enum.Material.SmoothPlastic)
	cannon.Transparency = 1
	cannon.CanCollide = false
	cannon.CanTouch = false
	cannon.CanQuery = false
	local rainbow = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 140, 255)),
	})
	for k = 1, 2 do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Confetti" .. k
		emitter.Color = rainbow
		emitter.Lifetime = NumberRange.new(1.2, 2.2)
		emitter.Speed = NumberRange.new(15, 24)
		emitter.Acceleration = Vector3.new(0, -22, 0)
		emitter.SpreadAngle = Vector2.new(65, 65)
		emitter.Rate = 0
		emitter.LightEmission = 0.5
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		emitter.Parent = cannon
		table.insert(result.confettiEmitters, emitter)
	end

	return result
end

return Course
