-- Brainrot Obby Rush - server
-- Builds the world, owns player progress (stage / brainrots / time), wires
-- checkpoints, collectibles, kill parts and the finish podium, and animates
-- moving platforms, spinner bars and the brainrot characters.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Brainrots = require(script:WaitForChild("Brainrots"))
local Course = require(script:WaitForChild("Course"))

-- Bright, cheerful lighting so the neon course pops in screenshots.
Lighting.Ambient = Color3.fromRGB(175, 175, 195)
Lighting.OutdoorAmbient = Color3.fromRGB(175, 175, 195)
Lighting.Brightness = 3
Lighting.ClockTime = 14
Lighting.FogEnd = 100000

local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Color = Color3.fromRGB(30, 24, 54)
end

-- Remote events the client HUD listens to.
local collectEvent = Instance.new("RemoteEvent")
collectEvent.Name = "BrainrotCollect"
collectEvent.Parent = ReplicatedStorage

local winEvent = Instance.new("RemoteEvent")
winEvent.Name = "BrainrotWin"
winEvent.Parent = ReplicatedStorage

-- Build the world before anyone joins.
local world = Course.build(Brainrots)

local playerData = {}

local function getPlayerFromHit(hit)
	if not hit or not hit.Parent then
		return nil, nil
	end
	local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end
	return Players:GetPlayerFromCharacter(hit.Parent), humanoid
end

local function applyCheckpoint(player, data, stageNumber)
	if stageNumber > data.stage then
		data.stage = stageNumber
		data.respawnCFrame = world.stageRespawn[stageNumber]
		data.checkpointY = world.stageRespawn[stageNumber].Position.Y
		player:SetAttribute("Stage", stageNumber)
		if data.leaderstats then
			data.leaderstats.Stage.Value = stageNumber
		end
	end
end

local function onPodium(player, data)
	if data.won then
		return
	end
	if data.stage >= 12 then
		data.won = true
		local finishTime = math.floor(Workspace:GetServerTimeNow() - data.startTime)
		player:SetAttribute("Won", true)
		if data.leaderstats then
			data.leaderstats.Time.Value = finishTime
		end
		winEvent:FireClient(player, finishTime, data.count)
		for _, emitter in ipairs(world.confettiEmitters) do
			emitter:Emit(80)
		end
		task.spawn(function()
			for _ = 1, 3 do
				task.wait(0.7)
				for _, emitter in ipairs(world.confettiEmitters) do
					emitter:Emit(50)
				end
			end
		end)
	else
		-- Reached the podium without stage 12's checkpoint: the podium
		-- becomes the player's stage 12 checkpoint instead of a win.
		data.stage = 12
		data.respawnCFrame = world.podiumRespawn
		data.checkpointY = world.podiumRespawn.Position.Y
		player:SetAttribute("Stage", 12)
		if data.leaderstats then
			data.leaderstats.Stage.Value = 12
		end
	end
end

-- Touch wiring ---------------------------------------------------------------
for i, pad in ipairs(world.checkpoints) do
	pad.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player then
			local data = playerData[player]
			if data then
				applyCheckpoint(player, data, i)
			end
		end
	end)
end

world.podium.Touched:Connect(function(hit)
	local player = getPlayerFromHit(hit)
	if player then
		local data = playerData[player]
		if data then
			onPodium(player, data)
		end
	end
end)

for _, part in ipairs(world.killParts) do
	part.Touched:Connect(function(hit)
		local _, humanoid = getPlayerFromHit(hit)
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end)
end

for index, model in pairs(world.characters) do
	local body = model.PrimaryPart
	if body then
		body.Touched:Connect(function(hit)
			local player = getPlayerFromHit(hit)
			if not player then
				return
			end
			local data = playerData[player]
			if not data or data.collected[index] then
				return
			end
			data.collected[index] = true
			data.count += 1
			player:SetAttribute("Collected", data.count)
			if data.leaderstats then
				data.leaderstats.Brainrots.Value = data.count
			end
			collectEvent:FireClient(player, index, data.count)
			local burst = body:FindFirstChild("CollectBurst")
			if burst then
				burst:Emit(30)
			end
		end)
	end
end

-- Player lifecycle -------------------------------------------------------------
local function setupPlayer(player)
	local data = {
		stage = 1,
		collected = {},
		count = 0,
		won = false,
		startTime = Workspace:GetServerTimeNow(),
		respawnCFrame = world.spawnCFrame,
		checkpointY = world.spawnCFrame.Position.Y,
		leaderstats = nil,
	}
	playerData[player] = data

	player:SetAttribute("Stage", 1)
	player:SetAttribute("Collected", 0)
	player:SetAttribute("Won", false)
	player:SetAttribute("StartTime", data.startTime)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = 1
	stageValue.Parent = leaderstats
	local brainrotValue = Instance.new("IntValue")
	brainrotValue.Name = "Brainrots"
	brainrotValue.Value = 0
	brainrotValue.Parent = leaderstats
	local timeValue = Instance.new("IntValue")
	timeValue.Name = "Time"
	timeValue.Value = 0
	timeValue.Parent = leaderstats
	leaderstats.Parent = player
	data.leaderstats = leaderstats

	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root then
			character:PivotTo(data.respawnCFrame)
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				task.wait(2)
				if player.Parent == Players then
					player:LoadCharacter()
				end
			end)
		end
	end)

	-- CharacterAutoLoads is false, so spawn the first character ourselves.
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

-- Animation loop: spinners, moving platforms, bobbing brainrots. ---------------
RunService.Heartbeat:Connect(function()
	local t = os.clock()
	for _, item in ipairs(world.animated) do
		if item.kind == "spinner" then
			item.part.CFrame = CFrame.new(item.pivot) * CFrame.Angles(0, t * item.speed + item.phase, 0)
		elseif item.kind == "move" then
			local offset = math.sin(t * item.speed + item.phase) * item.dist * 0.5
			item.part.CFrame = CFrame.new(item.basePos + item.axis * offset) * item.rot
		elseif item.kind == "char" then
			local bob = (math.sin(t * 2 + item.phase) * 0.5 + 0.5) * 0.5
			item.model:PivotTo(item.basePivot * CFrame.new(0, bob, 0) * CFrame.Angles(0, t * 0.9 + item.phase, 0))
		end
	end
end)

-- Timer updates + fall detection (respawn when far below the checkpoint). -----
task.spawn(function()
	while true do
		task.wait(0.25)
		local now = Workspace:GetServerTimeNow()
		for player, data in pairs(playerData) do
			if not data.won and data.leaderstats then
				data.leaderstats.Time.Value = math.floor(now - data.startTime)
			end
			local character = player.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and humanoid.Health > 0 and root.Position.Y < data.checkpointY - 16 then
					humanoid.Health = 0
				end
			end
		end
	end
end)

print("Brainrot Obby Rush: world built, ready for players.")
