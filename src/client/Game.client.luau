-- Brainrot Obby Rush - client HUD
-- Shows the run timer, the current stage and the brainrot tally for the
-- local player, and reacts to the collect and win remotes from the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TOTAL_STAGES = 12
local TOTAL_BRAINROTS = 10

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the shared remotes the server creates at startup.
local collectEvent = ReplicatedStorage:WaitForChild("BrainrotCollect")
local winEvent = ReplicatedStorage:WaitForChild("BrainrotWin")

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%02d:%02d", minutes, rest)
end

local function makeLabel(parent, name, size, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.BackgroundTransparency = 0.35
	label.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Text = ""
	label.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	return label
end

-- Root gui ---------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = playerGui

-- Top bar holding the three readouts.
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.Size = UDim2.new(1, 0, 0, 56)
bar.Position = UDim2.new(0, 0, 0, 0)
bar.BackgroundTransparency = 1
bar.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 12)
layout.Parent = bar

local timerLabel = makeLabel(bar, "Timer", UDim2.new(0, 150, 0, 44), 22)
timerLabel.Text = "00:00"

local stageLabel = makeLabel(bar, "Stage", UDim2.new(0, 150, 0, 44), 22)
stageLabel.Text = "Stage: 1/" .. TOTAL_STAGES

local brainrotLabel = makeLabel(bar, "Brainrots", UDim2.new(0, 190, 0, 44), 22)
brainrotLabel.Text = "Brainrots: 0/" .. TOTAL_BRAINROTS
brainrotLabel.TextColor3 = Color3.fromRGB(120, 255, 170)

-- Centre banner, hidden until the win remote fires.
local banner = Instance.new("Frame")
banner.Name = "WinBanner"
banner.Size = UDim2.new(0, 460, 0, 180)
banner.Position = UDim2.new(0.5, -230, 0.5, -90)
banner.BackgroundColor3 = Color3.fromRGB(20, 16, 48)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 16)
bannerCorner.Parent = banner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Name = "Title"
bannerTitle.Size = UDim2.new(1, 0, 0, 60)
bannerTitle.Position = UDim2.new(0, 0, 0, 16)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextSize = 36
bannerTitle.TextColor3 = Color3.fromRGB(255, 215, 90)
bannerTitle.Text = "You Win!"
bannerTitle.Parent = banner

local bannerDetail = Instance.new("TextLabel")
bannerDetail.Name = "Detail"
bannerDetail.Size = UDim2.new(1, -32, 0, 80)
bannerDetail.Position = UDim2.new(0, 16, 0, 84)
bannerDetail.BackgroundTransparency = 1
bannerDetail.Font = Enum.Font.Gotham
bannerDetail.TextSize = 22
bannerDetail.TextColor3 = Color3.fromRGB(235, 235, 255)
bannerDetail.TextWrapped = true
bannerDetail.Text = ""
bannerDetail.Parent = banner

-- Small hint along the bottom so new players know the goal.
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Size = UDim2.new(1, 0, 0, 28)
hint.Position = UDim2.new(0, 0, 1, -34)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 16
hint.TextColor3 = Color3.fromRGB(200, 200, 220)
hint.Text = "Clear all 12 stages and hunt down the 10 hidden brainrots!"
hint.Parent = gui

-- State readers ----------------------------------------------------------
local function currentStage()
	local stage = player:GetAttribute("Stage")
	if typeof(stage) ~= "number" then
		return 1
	end
	return math.clamp(math.floor(stage), 1, TOTAL_STAGES)
end

local function currentCollected()
	local collected = player:GetAttribute("Collected")
	if typeof(collected) ~= "number" then
		return 0
	end
	return math.clamp(math.floor(collected), 0, TOTAL_BRAINROTS)
end

local function hasWon()
	return player:GetAttribute("Won") == true
end

local function elapsedSeconds()
	local startTime = player:GetAttribute("StartTime")
	if typeof(startTime) ~= "number" then
		return 0
	end
	return math.max(0, os.clock() - startTime)
end

local function leaderstatTime()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return nil
	end
	local timeValue = stats:FindFirstChild("Time")
	if timeValue and timeValue:IsA("NumberValue") then
		return timeValue.Value
	end
	if timeValue and timeValue:IsA("IntValue") then
		return timeValue.Value
	end
	return nil
end

local function refreshCounts()
	stageLabel.Text = "Stage: " .. currentStage() .. "/" .. TOTAL_STAGES
	brainrotLabel.Text = "Brainrots: " .. currentCollected() .. "/" .. TOTAL_BRAINROTS
end

local function refreshTimer()
	if hasWon() then
		local finalTime = leaderstatTime()
		if finalTime then
			timerLabel.Text = formatTime(finalTime)
			return
		end
	end
	timerLabel.Text = formatTime(elapsedSeconds())
end

-- Collect feedback: pulse the counter so the pickup feels noticed.
local flashTween = nil
local function flashBrainrots()
	brainrotLabel.TextColor3 = Color3.fromRGB(255, 240, 120)
	if flashTween then
		flashTween:Cancel()
	end
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	flashTween = TweenService:Create(brainrotLabel, info, {
		TextColor3 = Color3.fromRGB(120, 255, 170),
	})
	flashTween:Play()
	refreshCounts()
end

-- Win presentation -------------------------------------------------------
local function showWin(finishTime, found)
	local shownTime = finishTime
	if typeof(shownTime) ~= "number" then
		shownTime = elapsedSeconds()
	end
	local shownFound = found
	if typeof(shownFound) ~= "number" then
		shownFound = currentCollected()
	end
	bannerDetail.Text = "Finish time: "
		.. formatTime(shownTime)
		.. "\nBrainrots found: "
		.. math.floor(shownFound)
		.. "/"
		.. TOTAL_BRAINROTS
	banner.Visible = true
	refreshCounts()
	refreshTimer()
end

collectEvent.OnClientEvent:Connect(function()
	flashBrainrots()
end)

winEvent.OnClientEvent:Connect(function(finishTime, found)
	showWin(finishTime, found)
end)

-- Attribute changes keep the readouts honest between remote events.
player:GetAttributeChangedSignal("Stage"):Connect(refreshCounts)
player:GetAttributeChangedSignal("Collected"):Connect(refreshCounts)
player:GetAttributeChangedSignal("Won"):Connect(function()
	refreshTimer()
	if hasWon() and not banner.Visible then
		showWin(leaderstatTime(), currentCollected())
	end
end)
player:GetAttributeChangedSignal("StartTime"):Connect(refreshTimer)

-- If the player already finished before this script loaded, show it.
if hasWon() then
	showWin(leaderstatTime(), currentCollected())
end

refreshCounts()
refreshTimer()

-- Per-frame timer tick; keeps counting until the Won attribute lands.
RunService.RenderStepped:Connect(function()
	if not hasWon() then
		refreshTimer()
	end
end)
