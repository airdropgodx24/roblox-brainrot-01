-- init.server.luau
-- Brainrot Obby Rush -- main server script
--
-- Builds the neon obby course, spawns the ten collectible
-- brainrots, and runs the whole game loop on the server:
-- checkpoints, respawns, kill bricks, collections, the podium
-- win, leaderstats, animation and fall protection.
--
-- Layout expected from Course.build(Brainrots):
--   checkpoints      12 pads, in stage order
--   stageRespawn     12 CFrames, one per checkpoint
--   spawnCFrame      where a fresh player starts
--   podium           the finish platform
--   podiumRespawn    respawn CFrame for the podium
--   killParts        parts that reset the character
--   characters       the 10 brainrot models
--   confettiEmitters emitters fired on a win
--   animated         spinner / move / char animation entries

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Brainrots = require(script:WaitForChild("Brainrots"))
local Course = require(script:WaitForChild("Course"))

-- ----------------------------------------------------------------
-- Cheerful sky: bright mid-afternoon light, soft fog, warm air.
-- ----------------------------------------------------------------
Lighting.ClockTime = 14
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(170, 160, 220)
Lighting.OutdoorAmbient = Color3.fromRGB(190, 200, 255)
Lighting.FogEnd = 100000
Lighting.FogStart = 90000
Lighting.GlobalShadows = true

-- The default grey baseplate clashes with the neon course, so
-- repaint it a deep purple when it is sitting in Workspace.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Color = Color3.fromRGB(43, 24, 84)
	baseplate.Material = Enum.Material.SmoothPlastic
end

-- ----------------------------------------------------------------
-- Remote events the client HUD listens to.
-- ----------------------------------------------------------------
local function getOrCreateRemote(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = ReplicatedStorage
	return remote
end

local collectEvent = getOrCreateRemote("BrainrotCollect")
local winEvent = getOrCreateRemote("BrainrotWin")

-- ----------------------------------------------------------------
-- Build the world: course, checkpoints, brainrots, podium.
-- ----------------------------------------------------------------
local world = Course.build(Brainrots)

local checkpoints = world.checkpoints
local stageRespawn = world.stageRespawn
local spawnCFrame = world.spawnCFrame
local podium = world.podium
local podiumRespawn = world.podiumRespawn
local killParts = world.killParts
local characters = world.characters
local confettiEmitters = world.confettiEmitters
local animated = world.animated

-- ----------------------------------------------------------------
-- Per-player progress.
-- ----------------------------------------------------------------
local playerData = {}

local function makeLeaderstats(player, data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = 0
	stageValue.Parent = folder

	local brainrotValue = Instance.new("IntValue")
	brainrotValue.Name = "Brainrots"
	brainrotValue.Value = 0
	brainrotValue.Parent = folder

	local timeValue = Instance.new("IntValue")
	timeValue.Name = "Time"
	timeValue.Value = 0
	timeValue.Parent = folder

	folder.Parent = player
	data.leaderstats = folder
	return folder
end

local function syncStats(player, data)
	if data.leaderstats then
		data.leaderstats.Stage.Value = data.stage
		data.leaderstats.Brainrots.Value = data.count
		if data.won then
			-- Time is frozen at the finish once a player has won.
			data.leaderstats.Time.Value = data.finishTime or data.leaderstats.Time.Value
		end
	end
	player:SetAttribute("Stage", data.stage)
	player:SetAttribute("Collected", data.count)
	player:SetAttribute("Won", data.won)
	player:SetAttribute("StartTime", data.startTime)
end

local function newPlayerData(player)
	local data = {
		stage = 0,
		collected = {},
		count = 0,
		won = false,
		finishTime = nil,
		startTime = os.clock(),
		respawnCFrame = spawnCFrame,
		checkpointY = spawnCFrame.Position.Y,
		leaderstats = nil,
	}
	playerData[player] = data
	makeLeaderstats(player, data)
	syncStats(player, data)
	return data
end

-- Work out which player a touched character belongs to.
local function playerFromHit(hit)
	if not hit or not hit.Parent then
		return nil, nil
	end
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		character = character.Parent
		if character then
			humanoid = character:FindFirstChildOfClass("Humanoid")
		end
	end
	if not character or not humanoid then
		return nil, nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	return player, humanoid
end

-- ----------------------------------------------------------------
-- Winning.
-- ----------------------------------------------------------------
local function fireConfetti()
	for _, emitter in ipairs(confettiEmitters) do
		if emitter and emitter:IsA("ParticleEmitter") then
			task.spawn(function()
				for _ = 1, 3 do
					emitter:Emit(40)
					task.wait(0.25)
				end
			end)
		end
	end
end

local function winGame(player, data)
	if data.won then
		return
	end
	data.won = true
	data.finishTime = math.max(0, math.floor(os.clock() - data.startTime))
	syncStats(player, data)
	if data.leaderstats then
		data.leaderstats.Time.Value = data.finishTime
	end
	winEvent:FireClient(player, data.finishTime, data.count)
	fireConfetti()
end

local function reachStage(player, data, stageIndex, respawnCFrame, respawnY)
	if stageIndex <= data.stage then
		return
	end
	data.stage = stageIndex
	data.respawnCFrame = respawnCFrame
	if respawnY then
		data.checkpointY = respawnY
	end
	syncStats(player, data)
end

-- ----------------------------------------------------------------
-- Touch wiring.
-- ----------------------------------------------------------------
for stageIndex, pad in ipairs(checkpoints) do
	if pad and pad:IsA("BasePart") then
		pad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if not player then
				return
			end
			local data = playerData[player]
			if not data then
				return
			end
			local respawn = stageRespawn[stageIndex] or spawnCFrame
			reachStage(player, data, stageIndex, respawn, pad.Position.Y)
		end)
	end
end

if podium and podium:IsA("BasePart") then
	podium.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end
		local data = playerData[player]
		if not data then
			return
		end
		if data.stage >= 12 then
			data.respawnCFrame = podiumRespawn or data.respawnCFrame
			data.checkpointY = podium.Position.Y
			winGame(player, data)
		else
			-- Reaching the podium early still banks stage 12,
			-- it just does not count as a finish yet.
			reachStage(player, data, 12, podiumRespawn or data.respawnCFrame, podium.Position.Y)
		end
	end)
end

for _, killPart in ipairs(killParts) do
	if killPart and killPart:IsA("BasePart") then
		killPart.Touched:Connect(function(hit)
			local _, humanoid = playerFromHit(hit)
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end
end

for index, model in ipairs(characters) do
	local primary = model and model.PrimaryPart
	if primary then
		primary.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if not player then
				return
			end
			local data = playerData[player]
			if not data or data.collected[index] then
				return
			end
			data.collected[index] = true
			data.count += 1
			syncStats(player, data)
			collectEvent:FireClient(player, index, data.count)
			local burst = primary:FindFirstChild("CollectBurst")
			if burst and burst:IsA("ParticleEmitter") then
				burst:Emit(30)
			end
		end)
	end
end

-- ----------------------------------------------------------------
-- Characters and respawning. Auto-loads is off, so the server
-- loads each character itself and reloads it after a death.
-- ----------------------------------------------------------------
Players.CharacterAutoLoads = false

local function onCharacterAdded(player, character)
	local data = playerData[player]
	if not data then
		data = newPlayerData(player)
	end
	character:PivotTo(data.respawnCFrame)

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		task.wait(2)
		if player.Parent == Players then
			player:LoadCharacter()
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	newPlayerData(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

-- ----------------------------------------------------------------
-- Animation: spinners spin, movers slide, brainrots bob.
-- ----------------------------------------------------------------
local animTime = 0

RunService.Heartbeat:Connect(function(dt)
	animTime += dt
	for _, entry in ipairs(animated) do
		if entry.kind == "spinner" and entry.part then
			local angle = (animTime * (entry.speed or 1)) + (entry.phase or 0)
			entry.part:PivotTo(entry.pivot * CFrame.Angles(0, angle, 0))
		elseif entry.kind == "move" and entry.part then
			local wave = math.sin((animTime * (entry.speed or 1)) + (entry.phase or 0))
			local newPos = entry.basePos + ((entry.axis or Vector3.new(1, 0, 0)) * wave * (entry.dist or 4))
			local rotation = entry.rot
			if typeof(rotation) == "CFrame" then
				entry.part.CFrame = CFrame.new(newPos) * rotation.Rotation
			else
				entry.part.CFrame = CFrame.new(newPos) * entry.part.CFrame.Rotation
			end
		elseif entry.kind == "char" and entry.model then
			local bob = math.sin((animTime * 2) + (entry.phase or 0)) * 0.35
			local sway = math.sin((animTime * 0.8) + (entry.phase or 0)) * 0.35
			entry.model:PivotTo(entry.basePivot * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, 0))
		end
	end
end)

-- ----------------------------------------------------------------
-- Slow loop: run the clock and catch anyone who fell off.
-- ----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.25)
		for player, data in pairs(playerData) do
			if not data.won and data.leaderstats then
				data.leaderstats.Time.Value = math.max(0, math.floor(os.clock() - data.startTime))
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				if root.Position.Y < (data.checkpointY - 16) then
					humanoid.Health = 0
				end
			end
		end
	end
end)

print("[Brainrot Obby Rush] Server ready: 12 stages, 10 brainrots, podium armed.")
