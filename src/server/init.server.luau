-- init.server.luau
-- Brainrot Obby Rush: server bootstrap and gameplay wiring.
-- Builds the neon course, tracks every runner's stage, brainrot
-- collection, timer and respawn point, and animates the world.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brainrots = require(script:WaitForChild("Brainrots"))
local Course = require(script:WaitForChild("Course"))

-- Cheerful daytime lighting so the neon colours pop.
Lighting.ClockTime = 14
Lighting.GeographicLatitude = 35
Lighting.Brightness = 2.5
Lighting.ExposureCompensation = 0.2
Lighting.Ambient = Color3.fromRGB(170, 160, 255)
Lighting.OutdoorAmbient = Color3.fromRGB(200, 195, 255)
Lighting.FogEnd = 100000
Lighting.GlobalShadows = true

local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Color = Color3.fromRGB(48, 24, 84)
	baseplate.Material = Enum.Material.SmoothPlastic
end

-- Remote events the client HUD listens to.
local collectEvent = Instance.new("RemoteEvent")
collectEvent.Name = "BrainrotCollect"
collectEvent.Parent = ReplicatedStorage

local winEvent = Instance.new("RemoteEvent")
winEvent.Name = "BrainrotWin"
winEvent.Parent = ReplicatedStorage

-- Build the whole course: stages, podium, hazards and brainrots.
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

-- Per-player run state, keyed by the Player instance.
local playerData = {}

local function syncStats(player, data)
	if data.leaderstats then
		local stageValue = data.leaderstats:FindFirstChild("Stage")
		if stageValue then
			stageValue.Value = data.stage
		end
		local brainrotValue = data.leaderstats:FindFirstChild("Brainrots")
		if brainrotValue then
			brainrotValue.Value = data.count
		end
		local timeValue = data.leaderstats:FindFirstChild("Time")
		if timeValue and not data.won then
			timeValue.Value = math.floor(os.clock() - data.startTime)
		end
	end
	player:SetAttribute("Stage", data.stage)
	player:SetAttribute("Collected", data.count)
	player:SetAttribute("Won", data.won)
	player:SetAttribute("StartTime", data.startTime)
end

local function makeLeaderstats(player, data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = data.stage
	stageValue.Parent = folder

	local brainrotValue = Instance.new("IntValue")
	brainrotValue.Name = "Brainrots"
	brainrotValue.Value = data.count
	brainrotValue.Parent = folder

	local timeValue = Instance.new("IntValue")
	timeValue.Name = "Time"
	timeValue.Value = 0
	timeValue.Parent = folder

	folder.Parent = player
	data.leaderstats = folder
end

local function newPlayerData(player)
	local data = {
		stage = 0,
		collected = {},
		count = 0,
		won = false,
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

local function playerFromHit(hit)
	if not hit or not hit.Parent then
		return nil, nil
	end
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil, nil
	end
	return player, humanoid
end

local function burstConfetti()
	for _, emitter in ipairs(confettiEmitters) do
		if emitter and emitter:IsA("ParticleEmitter") then
			emitter:Emit(75)
		end
	end
end

local function onCheckpointTouched(index)
	return function(hit)
		local player, humanoid = playerFromHit(hit)
		if not player or not humanoid or humanoid.Health <= 0 then
			return
		end
		local data = playerData[player]
		if not data then
			return
		end
		-- Checkpoints only ever move a runner forward.
		if index > data.stage then
			data.stage = index
			local respawn = stageRespawn[index]
			if respawn then
				data.respawnCFrame = respawn
				data.checkpointY = respawn.Position.Y
			end
			syncStats(player, data)
		end
	end
end

for index, checkpoint in ipairs(checkpoints) do
	if checkpoint and checkpoint:IsA("BasePart") then
		checkpoint.Touched:Connect(onCheckpointTouched(index))
	end
end

local function onPodiumTouched(hit)
	local player, humanoid = playerFromHit(hit)
	if not player or not humanoid or humanoid.Health <= 0 then
		return
	end
	local data = playerData[player]
	if not data or data.won then
		return
	end
	if data.stage >= 12 then
		data.won = true
		local finishTime = os.clock() - data.startTime
		if data.leaderstats then
			local timeValue = data.leaderstats:FindFirstChild("Time")
			if timeValue then
				timeValue.Value = math.floor(finishTime)
			end
		end
		syncStats(player, data)
		winEvent:FireClient(player, finishTime, data.count)
		burstConfetti()
		task.delay(0.4, burstConfetti)
		task.delay(0.8, burstConfetti)
	else
		-- Reached the podium early: bank it as the stage-12
		-- checkpoint so the next arrival respawns right here.
		data.stage = 12
		if podiumRespawn then
			data.respawnCFrame = podiumRespawn
			data.checkpointY = podiumRespawn.Position.Y
		end
		syncStats(player, data)
	end
end

if podium and podium:IsA("BasePart") then
	podium.Touched:Connect(onPodiumTouched)
end

local function onKillPartTouched(hit)
	local _, humanoid = playerFromHit(hit)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

for _, killPart in ipairs(killParts) do
	if killPart and killPart:IsA("BasePart") then
		killPart.Touched:Connect(onKillPartTouched)
	end
end

local function onCharacterTouched(index, model)
	return function(hit)
		local player, humanoid = playerFromHit(hit)
		if not player or not humanoid or humanoid.Health <= 0 then
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
		local primary = model.PrimaryPart
		if primary then
			local burst = primary:FindFirstChild("CollectBurst")
			if burst and burst:IsA("ParticleEmitter") then
				burst:Emit(30)
			end
		end
	end
end

for index, model in ipairs(characters) do
	if model and model:IsA("Model") and model.PrimaryPart then
		model.PrimaryPart.Touched:Connect(onCharacterTouched(index, model))
	end
end

local function onCharacterAdded(player, data)
	return function(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root then
			character:PivotTo(data.respawnCFrame)
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				task.wait(2)
				if player.Parent == Players and playerData[player] == data then
					player:LoadCharacter()
				end
			end)
		end
	end
end

Players.CharacterAutoLoads = false

Players.PlayerAdded:Connect(function(player)
	local data = newPlayerData(player)
	player.CharacterAdded:Connect(onCharacterAdded(player, data))
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

-- Animate spinners, movers and the bobbing brainrot characters.
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, entry in ipairs(animated) do
		if entry.kind == "spinner" and entry.part then
			local pivot = entry.pivot or entry.part.CFrame
			local angle = t * (entry.speed or 1) + (entry.phase or 0)
			entry.part.CFrame = pivot * CFrame.Angles(0, angle, 0)
		elseif entry.kind == "move" and entry.part then
			local offset = math.sin(t * (entry.speed or 1) + (entry.phase or 0)) * (entry.dist or 0)
			local position = entry.basePos + (entry.axis or Vector3.new(1, 0, 0)) * offset
			if typeof(entry.rot) == "CFrame" then
				entry.part.CFrame = CFrame.new(position) * entry.rot
			elseif typeof(entry.rot) == "number" then
				entry.part.CFrame = CFrame.new(position) * CFrame.Angles(0, entry.rot, 0)
			else
				entry.part.CFrame = CFrame.new(position)
			end
		elseif entry.kind == "char" and entry.model then
			local bob = math.sin(t * 2 + (entry.phase or 0)) * 0.5
			local spin = t * 0.8 + (entry.phase or 0)
			entry.model:PivotTo(entry.basePivot * CFrame.new(0, bob, 0) * CFrame.Angles(0, spin, 0))
		end
	end
end)

-- Timer updates and the fall-below-the-course safety net.
task.spawn(function()
	while true do
		task.wait(0.25)
		for player, data in pairs(playerData) do
			if not data.won and data.leaderstats then
				local timeValue = data.leaderstats:FindFirstChild("Time")
				if timeValue then
					timeValue.Value = math.floor(os.clock() - data.startTime)
				end
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				if root.Position.Y < data.checkpointY - 16 then
					humanoid.Health = 0
				end
			end
		end
	end
end)

print("[Brainrot Obby Rush] Ready: 12 stages, 10 brainrots, one very shiny podium.")
