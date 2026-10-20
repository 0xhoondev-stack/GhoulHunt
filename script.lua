-- ==========================================
-- 🎃 Ghoul Auto Capture (Ghoul5 기본값 수정) 👻
-- ==========================================

print("🚀 [1/6] 스크립트 시작...")

local Rayfield = nil
local success = false

success = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not Rayfield then
    success = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield.lua"))()
    end)
end
if not Rayfield then return end

local Window = Rayfield:CreateWindow({
   Name = "🎃 Ghoul Auto Capture 👻",
   LoadingTitle = "Loading...",
   LoadingSubtitle = "Clean Edition",
   KeySystem = false,
   ToggleUIKeybind = "K" -- ★ K키로 UI 열고 닫기
})

local MainTab = Window:CreateTab("🎃 메인", 4483362458)
local TargetTab = Window:CreateTab("👻 타겟", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ 설정", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 정보", 4483362458)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- [상태 표시줄]
local TapGui = Instance.new("ScreenGui")
TapGui.Parent = game.CoreGui
local TapLabel = Instance.new("TextLabel")
TapLabel.Parent = TapGui
TapLabel.Size = UDim2.new(0, 350, 0, 50)
TapLabel.Position = UDim2.new(0.5, -175, 0.1, 0)
TapLabel.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
TapLabel.BackgroundTransparency = 0.3
TapLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
TapLabel.TextSize = 22
TapLabel.Font = Enum.Font.SourceSansBold
TapLabel.Text = "🎃 대기 중... 👻"
TapLabel.Visible = false

-- [서버 경로]
local BeginCapture, TapCapture, CompleteCapture, GhoulsFolder
task.spawn(function()
    pcall(function()
        local Aurora = ReplicatedStorage:WaitForChild("Aurora", 5)
        local Framework = ReplicatedStorage:WaitForChild("Framework", 5)
        local ServiceFolder
        if Aurora then
            ServiceFolder = Aurora:WaitForChild("Framework", 5)
            if ServiceFolder then ServiceFolder = ServiceFolder:WaitForChild("Services", 5) end
        elseif Framework then
            ServiceFolder = Framework:WaitForChild("Services", 5)
        end
        if ServiceFolder then
            local GHS = ServiceFolder:WaitForChild("GhoulHuntingService", 5)
            if GHS then
                local RF = GHS:WaitForChild("RF", 5)
                if RF then
                    BeginCapture = RF:WaitForChild("BeginCapture", 5)
                    TapCapture = RF:WaitForChild("TapCapture", 5)
                    CompleteCapture = RF:WaitForChild("CompleteCapture", 5)
                end
            end
        end
        local Persistent = workspace:WaitForChild("Persistent", 5)
        if Persistent then
            local Ghouls = Persistent:WaitForChild("Ghouls", 5)
            if Ghouls then GhoulsFolder = Ghouls:WaitForChild("Active", 5) end
        end
    end)
end)

-- [변수] ★ 요청 기본값 적용
local AutoEnabled = true 
local CurrentTarget = nil
local AutoStick = false
local HighPriorityFirst = true
local RetryMode = false 

local GhoulEnabled = { ["Ghoul1"] = true, ["Ghoul2"] = true, ["Ghoul3"] = true, ["Ghoul4"] = true, ["Ghoul5"] = true }
-- Ghoul1: 4.7/4.7, Ghoul2: 7.7/7.7, Ghoul3: 4.0/8.0, Ghoul4: 5.0/12.0, Ghoul5: 8.0/18.0
local GhoulHoldTimes = { ["Ghoul1"] = 4.7, ["Ghoul2"] = 7.7, ["Ghoul3"] = 4.0, ["Ghoul4"] = 5.0, ["Ghoul5"] = 8.0, Default = 0.5 }
local GhoulRetryTimes = { ["Ghoul1"] = 4.7, ["Ghoul2"] = 7.7, ["Ghoul3"] = 8.0, ["Ghoul4"] = 12.0, ["Ghoul5"] = 18.0, Default = 0.5 }
local GhoulWaitTimes = { ["Ghoul1"] = 0.3, ["Ghoul2"] = 0.3, ["Ghoul3"] = 0.3, ["Ghoul4"] = 0.3, ["Ghoul5"] = 0.3, Default = 0.25 }
local StartDelay = 0.3 
local MinYPosition = -150

local function hasCannonEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("Type") == "GhoulCannon" then return true end
    end
    return false
end

local function createProgressBar(target)
    local oldGui = target:FindFirstChild("AutoProgressGui")
    if oldGui then oldGui:Destroy() end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "AutoProgressGui"
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = target.PrimaryPart or target:FindFirstChild("Main") or target:FindFirstChildWhichIsA("BasePart")
    billboard.Parent = target

    local bgFrame = Instance.new("Frame")
    bgFrame.Size = UDim2.new(1, 0, 0.6, 0)
    bgFrame.Position = UDim2.new(0, 0, 0.2, 0)
    bgFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    bgFrame.BackgroundTransparency = 0.2
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bgFrame

    local fillFrame = Instance.new("Frame")
    fillFrame.Name = "Fill"
    fillFrame.Size = UDim2.new(0, 0, 1, 0)
    fillFrame.BackgroundColor3 = Color3.fromRGB(255, 125, 190)
    fillFrame.BorderSizePixel = 0
    fillFrame.Parent = bgFrame
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fillFrame

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.4, 0)
    textLabel.Position = UDim2.new(0, 0, 0.6, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "0%"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard

    return billboard, fillFrame, textLabel
end

local function updateProgressBar(gui, fill, text, progress)
    if not gui or not gui.Parent then return end
    if type(progress) ~= "number" then return end 
    progress = math.clamp(progress, 0, 1)
    fill.Size = UDim2.new(progress, 0, 1, 0)
    text.Text = string.format("%d%%", math.floor(progress * 100))
    if progress < 0.5 then fill.BackgroundColor3 = Color3.fromRGB(255, 125, 190)
    elseif progress < 0.8 then fill.BackgroundColor3 = Color3.fromRGB(255, 175, 50)
    else fill.BackgroundColor3 = Color3.fromRGB(100, 210, 100) end
end

local function getFarmOrder()
    local order = {}
    local startIdx = HighPriorityFirst and 5 or 1
    local endIdx = HighPriorityFirst and 1 or 5
    local step = HighPriorityFirst and -1 or 1
    for i = startIdx, endIdx, step do
        local gName = "Ghoul" .. i
        if GhoulEnabled[gName] then table.insert(order, gName) end
    end
    return order
end

local function getClosestGhoul()
    if not GhoulsFolder then return nil end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    for _, targetModel in ipairs(getFarmOrder()) do
        local closest, shortest = nil, math.huge
        for _, ghoul in ipairs(GhoulsFolder:GetChildren()) do
            if ghoul:IsA("Model") and ghoul:GetAttribute("Captured") ~= true and ghoul:GetAttribute("BeingCaptured") ~= true then
                local gModel = ghoul:GetAttribute("GhoulModel") or ghoul.Name
                if gModel == targetModel then
                    local part = ghoul.PrimaryPart or ghoul:FindFirstChild("Main")
                    if part and part.Position.Y > MinYPosition then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < shortest then shortest, closest = dist, ghoul end
                    end
                end
            end
        end
        if closest then return closest end
    end
    return nil
end

local function startPerfectStick(target)
    AutoStick = true
    local char = LocalPlayer.Character
    if not char then return end
    local root, humanoid = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
    local part = target.PrimaryPart or target:FindFirstChild("Main")
    if not root or not humanoid or not part then return end
    pcall(function() humanoid.AutoRotate = false; humanoid.PlatformStand = false end)
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not AutoStick or not target.Parent then
            if connection then connection:Disconnect() end
            return
        end
        local cRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local cHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local cPart = target.PrimaryPart or target:FindFirstChild("Main")
        if not cRoot or not cHum or not cPart then return end
        local state = cHum:GetState()
        if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown then
            pcall(function() cHum:ChangeState(Enum.HumanoidStateType.GettingUp); cHum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        local targetPos = cPart.Position + (cPart.CFrame.LookVector * -1.5)
        cRoot.CFrame = CFrame.lookAt(targetPos, cPart.Position)
        cRoot.AssemblyLinearVelocity = Vector3.zero
        cRoot.AssemblyAngularVelocity = Vector3.zero
        pcall(function() cHum.AutoRotate = false end)
    end)
end

local function stopPerfectStick()
    AutoStick = false
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.AutoRotate = true; hum.PlatformStand = false end) end
    end
end

local function autoCapture(target)
    if not BeginCapture then return end
    if not hasCannonEquipped() then
        TapLabel.Visible = true
        TapLabel.Text = "⚠️ 대포를 장착하세요!"
        TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        task.wait(1)
        return
    end

    CurrentTarget = target
    local part = target.PrimaryPart or target:FindFirstChild("Main")
    if not part then CurrentTarget = nil return end

    TapLabel.Visible = true
    TapLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    TapLabel.Text = "🎃 캡처 준비..."
    
    startPerfectStick(target)
    task.wait(StartDelay)
    
    if not target.Parent or not AutoEnabled then
        stopPerfectStick()
        CurrentTarget = nil
        return
    end

    TapLabel.Text = "🎃 캡처 시작..."
    local gui, fill, text = createProgressBar(target)

    local successBegin, resultBegin = pcall(function()
        return BeginCapture:InvokeServer(target, "Tap")
    end)

    if not successBegin or type(resultBegin) ~= "table" or not resultBegin.Success then
        TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        TapLabel.Text = "💀 Begin 실패!"
        if gui then gui:Destroy() end
        stopPerfectStick()
        CurrentTarget = nil
        return
    end

    local gModel = target:GetAttribute("GhoulModel") or target.Name
    local tapsRequired = tonumber(resultBegin.TapsRequired) or 10
    
    local holdDuration = RetryMode and (GhoulRetryTimes[gModel] or GhoulRetryTimes.Default) or (GhoulHoldTimes[gModel] or GhoulHoldTimes.Default)
    TapLabel.Text = string.format("🕸️ 게이지 채우는 중... (%.1f초)", holdDuration)
    
    local startTime = os.clock()
    local lastTapTime = 0
    
    while os.clock() - startTime < holdDuration do
        if not target.Parent or not AutoEnabled then break end
        
        if os.clock() - lastTapTime > 0.1 then
            lastTapTime = os.clock()
            local s, res = pcall(function() return TapCapture:InvokeServer(target) end)
            
            if s and type(res) == "table" then
                local currentProgress = 0
                if type(res.Progress) == "number" then
                    currentProgress = res.Progress
                elseif type(res.Taps) == "number" then
                    currentProgress = math.clamp(res.Taps / tapsRequired, 0, 1)
                end
                
                if currentProgress > 0 then
                    updateProgressBar(gui, fill, text, currentProgress)
                end
                
                if currentProgress >= 1 or res.Active == false then break end
            end
        end
        RunService.RenderStepped:Wait()
    end

    if not target.Parent then
        if gui then gui:Destroy() end
        stopPerfectStick()
        CurrentTarget = nil
        return
    end

    updateProgressBar(gui, fill, text, 1)
    TapLabel.Text = "🕸️ 포획 완료 요청 중..."
    TapLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    task.wait(GhoulWaitTimes[gModel] or GhoulWaitTimes.Default)
    
    local successComplete, resultComplete = pcall(function()
        return CompleteCapture:InvokeServer(target)
    end)
    
    task.spawn(function()
        if successComplete and type(resultComplete) == "table" and resultComplete.Success then
            TapLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
            TapLabel.Text = "✅ 성공! +" .. tostring(resultComplete.Amount or 0) .. " Skulls"
            RetryMode = false
        else
            TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            TapLabel.Text = "❌ 실패 (다음엔 재시도 모드 적용)"
            RetryMode = true
        end
        task.wait(1.5)
        if not CurrentTarget then TapLabel.Visible = false end
    end)

    task.wait(0.5)
    if gui then gui:Destroy() end
    stopPerfectStick()
    CurrentTarget = nil
end

local function autoLoop()
    task.spawn(function()
        while AutoEnabled do
            local target = getClosestGhoul()
            if target then
                autoCapture(target)
                task.wait(0.01)
            else
                stopPerfectStick()
                task.wait(0.2)
            end
        end
    end)
end

-- 메인 UI
MainTab:CreateToggle({
   Name = "🎃 자동 포획 시작 / 정지 👻",
   CurrentValue = true, 
   Flag = "AutoToggle",
   Callback = function(Value)
       AutoEnabled = Value
       if Value then 
           RetryMode = false 
           autoLoop() 
       else 
           stopPerfectStick() 
           TapLabel.Visible = false 
       end
   end,
})

task.spawn(function()
    task.wait(1.5)
    if AutoEnabled then autoLoop() end
end)

TargetTab:CreateToggle({
   Name = "⬆️ 높은 순서부터 파밍", CurrentValue = true, Flag = "HighPriorityFirst",
   Callback = function(Value) HighPriorityFirst = Value end,
})

TargetTab:CreateSection("👻 파밍할 Ghoul 선택")
for i = 5, 1, -1 do
    TargetTab:CreateToggle({
       Name = "Ghoul" .. i .. " 파밍", CurrentValue = GhoulEnabled["Ghoul" .. i], Flag = "Farm_Ghoul" .. i,
       Callback = function(Value) GhoulEnabled["Ghoul" .. i] = Value end,
    })
end

-- 설정 탭
SettingsTab:CreateSection("⚙️ 공통 설정")
SettingsTab:CreateInput({
   Name = "서버 안전장치 (시작 전 대기) | 현재: " .. tostring(StartDelay),
   PlaceholderText = "예: 0.3 (초)",
   CurrentValue = tostring(StartDelay),
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local num = tonumber(Text)
       if num and num >= 0 then
           StartDelay = num
           Rayfield:Notify({Title = "설정 변경", Content = "시작 전 안전 대기: " .. num .. "초", Duration = 2})
       end
   end,
})

SettingsTab:CreateSection("⚙️ Ghoul별 세부 설정")
for i = 1, 5 do
    local gName = "Ghoul" .. i
    SettingsTab:CreateSection("👻 " .. gName)

    SettingsTab:CreateInput({
       Name = "일반 빔 유지 시간 (초) | 현재: " .. tostring(GhoulHoldTimes[gName]),
       PlaceholderText = "예: 0.5",
       CurrentValue = tostring(GhoulHoldTimes[gName]),
       RemoveTextAfterFocusLost = false,
       Callback = function(Text)
           local num = tonumber(Text)
           if num and num > 0 then
               GhoulHoldTimes[gName] = num
               Rayfield:Notify({Title = "설정 변경", Content = gName .. " 일반 유지: " .. num .. "초", Duration = 2})
           end
       end,
    })

    SettingsTab:CreateInput({
       Name = "재시도 빔 유지 시간 (초) | 현재: " .. tostring(GhoulRetryTimes[gName]),
       PlaceholderText = "예: 7.0 (실패 후 적용)",
       CurrentValue = tostring(GhoulRetryTimes[gName]),
       RemoveTextAfterFocusLost = false,
       Callback = function(Text)
           local num = tonumber(Text)
           if num and num > 0 then
               GhoulRetryTimes[gName] = num
               Rayfield:Notify({Title = "설정 변경", Content = gName .. " 재시도 유지: " .. num .. "초", Duration = 2})
           end
       end,
    })

    SettingsTab:CreateInput({
       Name = "대기 시간 (초) | 현재: " .. tostring(GhoulWaitTimes[gName]),
       PlaceholderText = "예: 0.3",
       CurrentValue = tostring(GhoulWaitTimes[gName]),
       RemoveTextAfterFocusLost = false,
       Callback = function(Text)
           local num = tonumber(Text)
           if num and num >= 0 then
               GhoulWaitTimes[gName] = num
               Rayfield:Notify({Title = "설정 변경", Content = gName .. " 대기: " .. num .. "초", Duration = 2})
           end
       end,
    })
end

------------------------------------------------
-- ★★★ [신규 추가] 실시간 Ghoul 현황판 ★★★
------------------------------------------------
InfoTab:CreateSection("📊 실시간 Ghoul 현황")
local CountLabels = {}
local function createCountLabel(ghoulName)
    local label = InfoTab:CreateLabel(ghoulName .. " : 확인 중...")
    CountLabels[ghoulName] = label
end

for i = 1, 5 do
    createCountLabel("Ghoul" .. i)
end

-- 0.5초마다 실시간으로 개수 업데이트
task.spawn(function()
    while task.wait(0.5) do
        if GhoulsFolder then
            local counts = { ["Ghoul1"] = 0, ["Ghoul2"] = 0, ["Ghoul3"] = 0, ["Ghoul4"] = 0, ["Ghoul5"] = 0 }
            for _, ghoul in ipairs(GhoulsFolder:GetChildren()) do
                if ghoul:IsA("Model") and ghoul:GetAttribute("Captured") ~= true and ghoul:GetAttribute("BeingCaptured") ~= true then
                    local gModel = ghoul:GetAttribute("GhoulModel") or ghoul.Name
                    local part = ghoul.PrimaryPart or ghoul:FindFirstChild("Main")
                    if part and part.Position.Y > MinYPosition then
                        if counts[gModel] then counts[gModel] = counts[gModel] + 1 end
                    end
                end
            end
            
            for gName, lbl in pairs(CountLabels) do
                local cnt = counts[gName] or 0
                if cnt > 0 then
                    pcall(function() lbl:Set("🟢 " .. gName .. " : " .. cnt .. "마리") end)
                else
                    pcall(function() lbl:Set("🔴 " .. gName .. " : 없음") end)
                end
            end
        end
    end
end)
------------------------------------------------

InfoTab:CreateSection("ℹ️ 안내")
InfoTab:CreateParagraph({
    Title = "🎃 안내",
    Content = "1. 게임에서 'Ghoul Cannon' 무기를 장착하세요.\n2. 유령 머리 위에 게이지가 뜨면서 자동으로 잡힙니다.\n3. K 키를 눌러 UI를 열고 닫을 수 있습니다."
})

print("✅ [6/6] Ghoul5 기본값 수정 및 실시간 현황판 적용 완료! (K키로 UI 열기)")
