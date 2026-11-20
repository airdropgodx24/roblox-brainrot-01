--!strict
--[[
	Brainrot Obby Rush - client HUD

	Builds the heads-up display for one player: a stopwatch, a brainrot
	counter and a stage tracker across the top of the screen, plus a
	celebration banner when the run is won. The server owns the run and
	mirrors it onto the player as attributes (Stage, Collected, Won and
	StartTime), with the final time also published in leaderstats as
	"Time", which the banner prefers when present. Two RemoteEvents sit
	directly in ReplicatedStorage (no folder): BrainrotCollect, fired on
	a pickup, and BrainrotWin, fired at the podium. The collect event
	only drives a flash on the counter; the numbers always come from
	the attributes, so a missed event cannot leave the HUD out of step.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TOTAL_STAGES = 12
local TOTAL_BRAINROTS = 10

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
-- The two remotes live directly under ReplicatedStorage.
local collectEvent = ReplicatedStorage:WaitForChild("BrainrotCollect") :: RemoteEvent
local winEvent = ReplicatedStorage:WaitForChild("BrainrotWin") :: RemoteEvent

-- Small helpers

-- Turn a count of seconds into "m:ss.t" (tenths keep the finish lively).
local function formatTime(seconds: number): string
	if seconds < 0 then
		seconds = 0
	end
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	local whole = math.floor(rest)
	local tenth = math.floor((rest - whole) * 10)
	return string.format("%d:%02d.%d", minutes, whole, tenth)
end

-- Read one attribute as a number, with a fallback while it is unset.
local function numberAttr(name: string, fallback: number): number
	local value = player:GetAttribute(name)
	if typeof(value) == "number" then
		return value
	end
	return fallback
end

-- The leaderstats Time value, if the server has published one yet.
local function leaderstatTime(): number?
	local stats = player:FindFirstChild("leaderstats")
	if stats == nil then
		return nil
	end
	local entry = stats:FindFirstChild("Time")
	if entry ~= nil and (entry:IsA("NumberValue") or entry:IsA("IntValue")) then
		return entry.Value
	end
	return nil
end

-- Build the interface

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = playerGui
-- A slim bar pinned to the top centre of the screen.
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 10)
bar.Size = UDim2.new(0, 520, 0, 52)
bar.BackgroundColor3 = Color3.fromRGB(18, 16, 34)
bar.BackgroundTransparency = 0.15
bar.BorderSizePixel = 0
bar.Parent = gui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 14)
barCorner.Parent = bar

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(0, 255, 200)
barStroke.Thickness = 2
barStroke.Transparency = 0.35
barStroke.Parent = bar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 26)
layout.Parent = bar

-- One labelled readout inside the bar.
local function makeReadout(name: string, firstText: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.TextColor3 = Color3.fromRGB(240, 244, 255)
	label.Text = firstText
	label.Parent = bar
	return label
end

local timerLabel = makeReadout("Timer", "0:00.0")
local brainrotLabel = makeReadout("Brainrots", "Brainrots: 0/" .. TOTAL_BRAINROTS)
local stageLabel = makeReadout("Stage", "Stage: 1/" .. TOTAL_STAGES)

brainrotLabel.TextColor3 = Color3.fromRGB(255, 214, 90)
stageLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
-- The win banner starts hidden in the middle of the screen.
local banner = Instance.new("Frame")
banner.Name = "WinBanner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.new(0.5, 0, 0.42, 0)
banner.Size = UDim2.new(0, 560, 0, 190)
banner.BackgroundColor3 = Color3.fromRGB(24, 20, 48)
banner.BackgroundTransparency = 0.08
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 20)
bannerCorner.Parent = banner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Color = Color3.fromRGB(255, 214, 90)
bannerStroke.Thickness = 3
bannerStroke.Parent = banner

local bannerLayout = Instance.new("UIListLayout")
bannerLayout.FillDirection = Enum.FillDirection.Vertical
bannerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
bannerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
bannerLayout.Padding = UDim.new(0, 8)
bannerLayout.Parent = banner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Name = "Title"
bannerTitle.AutomaticSize = Enum.AutomaticSize.XY
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextSize = 44
bannerTitle.TextColor3 = Color3.fromRGB(255, 214, 90)
bannerTitle.Text = "YOU WIN!"
bannerTitle.Parent = banner

local bannerDetail = Instance.new("TextLabel")
bannerDetail.Name = "Detail"
bannerDetail.AutomaticSize = Enum.AutomaticSize.XY
bannerDetail.BackgroundTransparency = 1
bannerDetail.Font = Enum.Font.Gotham
bannerDetail.TextSize = 24
bannerDetail.TextColor3 = Color3.fromRGB(240, 244, 255)
bannerDetail.Text = ""
bannerDetail.Parent = banner
-- Refresh logic

local function refreshCounters()
	local stage = math.clamp(math.floor(numberAttr("Stage", 1)), 1, TOTAL_STAGES)
	local found = math.clamp(math.floor(numberAttr("Collected", 0)), 0, TOTAL_BRAINROTS)
	stageLabel.Text = string.format("Stage: %d/%d", stage, TOTAL_STAGES)
	brainrotLabel.Text = string.format("Brainrots: %d/%d", found, TOTAL_BRAINROTS)
end

local function showBanner(finishSeconds: number)
	local found = math.clamp(math.floor(numberAttr("Collected", 0)), 0, TOTAL_BRAINROTS)
	bannerDetail.Text = string.format(
		"Finished in %s - Brainrots found: %d/%d",
		formatTime(finishSeconds),
		found,
		TOTAL_BRAINROTS
	)
	banner.Visible = true
end

-- Seconds on the clock right now, or nil while no run is in progress.
local function elapsedNow(): number?
	local start = player:GetAttribute("StartTime")
	if typeof(start) ~= "number" then
		return nil
	end
	return os.clock() - start
end

-- The stopwatch: one update per rendered frame until the run is won.
local heartbeat = RunService.RenderStepped:Connect(function()
	if player:GetAttribute("Won") == true then
		return
	end
	local elapsed = elapsedNow()
	if elapsed ~= nil then
		timerLabel.Text = formatTime(elapsed)
	end
end)

-- React to the server

player:GetAttributeChangedSignal("Stage"):Connect(refreshCounters)
player:GetAttributeChangedSignal("Collected"):Connect(refreshCounters)
player:GetAttributeChangedSignal("Won"):Connect(function()
	if player:GetAttribute("Won") == true then
		local final = leaderstatTime() or elapsedNow() or 0
		timerLabel.Text = formatTime(final)
		showBanner(final)
	end
end)

-- A pickup makes the counter pop: swell, tint, then settle back down.
local flashing = false
local function flashCounter()
	if flashing then
		return
	end
	flashing = true
	local baseSize = brainrotLabel.TextSize
	local baseColour = brainrotLabel.TextColor3
	brainrotLabel.TextSize = baseSize + 8
	brainrotLabel.TextColor3 = Color3.fromRGB(140, 255, 170)
	task.wait(0.12)
	brainrotLabel.TextSize = baseSize
	task.wait(0.12)
	brainrotLabel.TextColor3 = baseColour
	flashing = false
end

collectEvent.OnClientEvent:Connect(function()
	refreshCounters()
	task.spawn(flashCounter)
end)
winEvent.OnClientEvent:Connect(function(finalTime)
	local finish = finalTime
	if typeof(finish) ~= "number" then
		finish = leaderstatTime() or elapsedNow() or 0
	end
	timerLabel.Text = formatTime(finish :: number)
	showBanner(finish :: number)
end)

-- If the player already won before this script loaded (a rejoin onto
-- the podium, say), show the end state straight away. The heartbeat
-- connection lives for the whole session and is never disconnected.
refreshCounters()
if player:GetAttribute("Won") == true then
	local final = leaderstatTime() or elapsedNow() or 0
	timerLabel.Text = formatTime(final)
	showBanner(final)
end
local _keepAlive = heartbeat
