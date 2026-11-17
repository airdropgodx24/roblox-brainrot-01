-- Brainrot Obby Rush - client HUD
-- Top bar with timer / brainrot count / stage, a fading title banner, a
-- collect toast and a win banner. Progress is read from player attributes
-- (Stage, Collected, StartTime) that the server maintains; collect and win
-- arrive over RemoteEvents. Collecting also hides that brainrot locally so
-- collection feels per-player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local TOTAL_BRAINROTS = 10
local TOTAL_STAGES = 12

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local gui = Instance.new("ScreenGui")
gui.Name = "ObbyGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Top bar ----------------------------------------------------------------------
local bar = Instance.new("Frame")
bar.Name = "TopBar"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 10)
bar.Size = UDim2.new(0, 540, 0, 46)
bar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
bar.BackgroundTransparency = 0.25
bar.BorderSizePixel = 0
bar.Parent = gui
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 12)
barCorner.Parent = bar

local function makeBarLabel(name, text, xScale, width)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(xScale, 0, 0.5, 0)
	label.Size = UDim2.new(0, width, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.Parent = bar
	return label
end

local timerLabel = makeBarLabel("Timer", "Time 0:00", 0.17, 160)
local brainrotLabel = makeBarLabel("Brainrots", "Brainrots: 0/" .. TOTAL_BRAINROTS, 0.5, 190)
local stageLabel = makeBarLabel("Stage", "Stage: 1/" .. TOTAL_STAGES, 0.84, 150)

-- Title banner -------------------------------------------------------------------
local titleFrame = Instance.new("Frame")
titleFrame.Name = "TitleBanner"
titleFrame.AnchorPoint = Vector2.new(0.5, 0)
titleFrame.Position = UDim2.new(0.5, 0, 0.16, 0)
titleFrame.Size = UDim2.new(0, 760, 0, 118)
titleFrame.BackgroundColor3 = Color3.fromRGB(25, 18, 50)
titleFrame.BackgroundTransparency = 0.3
titleFrame.BorderSizePixel = 0
titleFrame.Parent = gui
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.58, 0)
titleLabel.Position = UDim2.new(0, 0, 0.04, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 42
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
titleLabel.Text = "BRAINROT OBBY RUSH"
titleLabel.Parent = titleFrame

local subLabel = Instance.new("TextLabel")
subLabel.Name = "Sub"
subLabel.Size = UDim2.new(1, 0, 0.34, 0)
subLabel.Position = UDim2.new(0, 0, 0.62, 0)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.GothamBold
subLabel.TextSize = 22
subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
subLabel.Text = "Collect all 10 brainrots, reach the podium!"
subLabel.Parent = titleFrame

task.spawn(function()
	task.wait(6)
	local fadeInfo = TweenInfo.new(1)
	TweenService:Create(titleFrame, fadeInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(titleLabel, fadeInfo, { TextTransparency = 1 }):Play()
	local last = TweenService:Create(subLabel, fadeInfo, { TextTransparency = 1 })
	last:Play()
	last.Completed:Connect(function()
		titleFrame.Visible = false
	end)
end)

-- Collect toast ------------------------------------------------------------------
local toast = Instance.new("TextLabel")
toast.Name = "CollectToast"
toast.AnchorPoint = Vector2.new(0.5, 0.5)
toast.Position = UDim2.new(0.5, 0, 0.38, 0)
toast.Size = UDim2.new(0, 420, 0, 56)
toast.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextSize = 30
toast.TextColor3 = Color3.fromRGB(120, 255, 140)
toast.TextTransparency = 1
toast.Text = ""
toast.Parent = gui
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 12)
toastCorner.Parent = toast

local toastGeneration = 0
local function showToast(text)
	toastGeneration += 1
	local generation = toastGeneration
	toast.Text = text
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.3
	task.spawn(function()
		task.wait(1.6)
		if generation ~= toastGeneration then
			return
		end
		local fadeInfo = TweenInfo.new(0.5)
		TweenService:Create(toast, fadeInfo, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	end)
end

-- Win banner ---------------------------------------------------------------------
local winFrame = Instance.new("Frame")
winFrame.Name = "WinBanner"
winFrame.AnchorPoint = Vector2.new(0.5, 0.5)
winFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
winFrame.Size = UDim2.new(0, 720, 0, 170)
winFrame.BackgroundColor3 = Color3.fromRGB(50, 38, 0)
winFrame.BackgroundTransparency = 0.2
winFrame.BorderSizePixel = 0
winFrame.Visible = false
winFrame.Parent = gui
local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = winFrame

local winLabel = Instance.new("TextLabel")
winLabel.Name = "WinText"
winLabel.Size = UDim2.new(1, -20, 0.72, 0)
winLabel.Position = UDim2.new(0, 10, 0.04, 0)
winLabel.BackgroundTransparency = 1
winLabel.Font = Enum.Font.GothamBold
winLabel.TextSize = 40
winLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
winLabel.Text = ""
winLabel.Parent = winFrame

local winSub = Instance.new("TextLabel")
winSub.Name = "WinSub"
winSub.Size = UDim2.new(1, -20, 0.24, 0)
winSub.Position = UDim2.new(0, 10, 0.74, 0)
winSub.BackgroundTransparency = 1
winSub.Font = Enum.Font.GothamBold
winSub.TextSize = 20
winSub.TextColor3 = Color3.fromRGB(255, 255, 255)
winSub.Text = "You can keep exploring, or reset your character to run it again."
winSub.Parent = winFrame

-- Live HUD updates -----------------------------------------------------------------
local wonTime = nil

local function refreshStats()
	brainrotLabel.Text = "Brainrots: " .. tostring(player:GetAttribute("Collected") or 0) .. "/" .. TOTAL_BRAINROTS
	stageLabel.Text = "Stage: " .. tostring(player:GetAttribute("Stage") or 1) .. "/" .. TOTAL_STAGES
end
player:GetAttributeChangedSignal("Collected"):Connect(refreshStats)
player:GetAttributeChangedSignal("Stage"):Connect(refreshStats)
refreshStats()

task.spawn(function()
	while true do
		task.wait(0.1)
		local startTime = player:GetAttribute("StartTime")
		if startTime then
			local elapsed = Workspace:GetServerTimeNow() - startTime
			if wonTime then
				elapsed = wonTime
			end
			timerLabel.Text = "Time " .. formatTime(elapsed)
		end
	end
end)

-- Server events --------------------------------------------------------------------
local collectEvent = ReplicatedStorage:WaitForChild("BrainrotCollect")
collectEvent.OnClientEvent:Connect(function(index, count)
	-- Hide this brainrot for this player only.
	local folder = Workspace:FindFirstChild("Brainrots")
	if folder then
		local model = folder:FindFirstChild("Brainrot" .. index)
		if model then
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = 1
				elseif descendant:IsA("BillboardGui") then
					descendant.Enabled = false
				end
			end
		end
	end
	showToast("+1 Brainrot! (" .. count .. "/" .. TOTAL_BRAINROTS .. ")")
end)

local winEvent = ReplicatedStorage:WaitForChild("BrainrotWin")
winEvent.OnClientEvent:Connect(function(finishTime, count)
	wonTime = finishTime
	winLabel.Text = "YOU WIN!  Time: " .. formatTime(finishTime) .. "  -  Brainrots: " .. count .. "/" .. TOTAL_BRAINROTS
	winFrame.Visible = true
end)
