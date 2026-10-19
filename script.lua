-- 1. Rayfield 다중 주소 로드 (3중 안전장치)
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

if not success or not Rayfield then
    success = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
    end)
end

if not Rayfield then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "UI 로드 실패",
        Text = "실행기에서 HttpGet이 차단되었습니다.",
        Duration = 5
    })
    return
end

print("✅ Rayfield 로드 성공!")

local Window = Rayfield:CreateWindow({
   Name = "🎃 Ghoul Auto Capture 👻",
   LoadingTitle = "🕸️ Loading... 🕸️",
   LoadingSubtitle = "Happy Halloween Edition",
   Theme = "Dark",
   KeySystem = false
})

local MainTab = Window:CreateTab("🎃 메인", 4483362458)
local TargetTab = Window:CreateTab("👻 타겟 선택", 4483362458)
local GhoulTab = Window:CreateTab("⚙️ Ghoul 설정", 4483362458)
local InfoTab = Window:CreateTab("ℹ️ 정보", 4483362458)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

-- 화면 상태 표시 UI
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

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Parent = TapLabel

-- Ghoul 개수 실시간 표시 UI
local CountGui = Instance.new("ScreenGui")
CountGui.Parent = game.CoreGui
CountGui.Name = "GhoulCountGui"

local CountFrame = Instance.new("Frame")
CountFrame.Parent = CountGui
CountFrame.Size = UDim2.new(0, 220, 0, 200)
CountFrame.Position = UDim2.new(0, 10, 0, 100)
CountFrame.BackgroundColor3 = Color3.fromRGB(20, 15, 10)
CountFrame.BackgroundTransparency = 0.2
CountFrame.BorderSizePixel = 0

local CountCorner = Instance.new("UICorner")
CountCorner.CornerRadius = UDim.new(0, 8)
CountCorner.Parent = CountFrame

local CountStroke = Instance.new("UIStroke")
CountStroke.Color = Color3.fromRGB(255, 100, 0)
CountStroke.Thickness = 2
CountStroke.Parent = CountFrame

local CountTitle = Instance.new("TextLabel")
CountTitle.Parent = CountFrame
CountTitle.Size = UDim2.new(1, 0, 0, 30)
CountTitle.BackgroundTransparency = 1
CountTitle.Text = "👻 Ghoul 현황"
CountTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
CountTitle.TextSize = 16
CountTitle.Font = Enum.Font.SourceSansBold

local CountList = Instance.new("Frame")
CountList.Parent = CountFrame
CountList.Size = UDim2.new(1, -20, 1, -40)
CountList.Position = UDim2.new(0, 10, 0, 35)
CountList.BackgroundTransparency = 1

local CountLayout = Instance.new("UIListLayout")
CountLayout.Parent = CountList
CountLayout.Padding = UDim.new(0, 2)
CountLayout.SortOrder = Enum.SortOrder.LayoutOrder

local CountLabels = {}

for i = 5, 1, -1 do
    local lbl = Instance.new("TextLabel")
    lbl.Parent = CountList
    lbl.Size = UDim2.new(1, 0, 0, 26)
    lbl.BackgroundTransparency = 0.7
    lbl.BackgroundColor3 = Color3.fromRGB(40, 20, 10)
    lbl.Text = string.format("Ghoul%d : 0", i)
    lbl.TextColor3 = Color3.fromRGB(255, 150, 0)
    lbl.TextSize = 15
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = 10 - i

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = lbl

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = lbl

    CountLabels["Ghoul" .. i] = lbl
end

-- 서버 경로
local Framework, GhoulService, ToolService, RF, EquipRF
local BeginCapture, TapCapture, CompleteCapture, GhoulsFolder

pcall(function()
    Framework = ReplicatedStorage:WaitForChild("Aurora"):WaitForChild("Framework")
    GhoulService = Framework:WaitForChild("Services"):WaitForChild("GhoulHuntingService")
    ToolService = Framework:WaitForChild("Services"):WaitForChild("ToolService")
    RF = GhoulService:WaitForChild("RF")
    EquipRF = ToolService:WaitForChild("RF"):WaitForChild("Equip")

    BeginCapture = RF:WaitForChild("BeginCapture")
    TapCapture = RF:WaitForChild("TapCapture")
    CompleteCapture = RF:WaitForChild("CompleteCapture")

    GhoulsFolder = workspace:WaitForChild("Persistent"):WaitForChild("Ghouls"):WaitForChild("Active")
end)

-- ★★★ [수정] 실행하자마자 자동사냥이 켜지도록 기본값 true로 설정 ★★★
local AutoEnabled = true 
local CurrentTarget = nil
local AutoStick = false

local HighPriorityFirst = true

local GhoulEnabled = {
    ["Ghoul1"] = true,
    ["Ghoul2"] = true,
    ["Ghoul3"] = true,
    ["Ghoul4"] = true,
    ["Ghoul5"] = true,
}

local GhoulTapCounts = {
    ["Ghoul1"] = 12, ["Ghoul2"] = 20, ["Ghoul3"] = 15, ["Ghoul4"] = 20, ["Ghoul5"] = 20,
}

local GhoulTapIntervals = {
    ["Ghoul1"] = 0.3, ["Ghoul2"] = 0.3, ["Ghoul3"] = 0.3, ["Ghoul4"] = 0.4, ["Ghoul5"] = 0.5,
    Default = 0.5
}
local GhoulWaitTimes = {
    ["Ghoul1"] = 0.3, ["Ghoul2"] = 0.3, ["Ghoul3"] = 0.3, ["Ghoul4"] = 0.3, ["Ghoul5"] = 0.25,
    Default = 0.25
}

local MinYPosition = -150

local function clampSpeed(val)
    local num = tonumber(val)
    if not num then return nil end
    if num < 0.05 then num = 0.05 end
    if num > 2.0 then num = 2.0 end
    return num
end

local function countGhouls()
    local counts = {
        ["Ghoul1"] = 0, ["Ghoul2"] = 0, ["Ghoul3"] = 0, ["Ghoul4"] = 0, ["Ghoul5"] = 0,
    }
    if not GhoulsFolder then return counts end

    for _, ghoul in ipairs(GhoulsFolder:GetChildren()) do
        if ghoul:IsA("Model") and ghoul:GetAttribute("Captured") ~= true and ghoul:GetAttribute("BeingCaptured") ~= true then
            local gModel = ghoul:GetAttribute("GhoulModel") or ghoul.Name
            local part = ghoul.PrimaryPart or ghoul:FindFirstChild("Main")
            if part and part.Position.Y > MinYPosition then
                if counts[gModel] then
                    counts[gModel] = counts[gModel] + 1
                end
            end
        end
    end

    return counts
end

local function updateCountLabels()
    local counts = countGhouls()
    for name, lbl in pairs(CountLabels) do
        local cnt = counts[name] or 0
        lbl.Text = string.format("%s : %d", name, cnt)
        if cnt > 0 then
            lbl.TextColor3 = Color3.fromRGB(100, 255, 150)
        else
            lbl.TextColor3 = Color3.fromRGB(150, 100, 100)
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(updateCountLabels)
    end
end)

local function getFarmOrder()
    local enabledList = {}
    for i = 1, 5 do
        local name = "Ghoul" .. i
        if GhoulEnabled[name] then
            table.insert(enabledList, name)
        end
    end

    if #enabledList == 0 then return {} end

    if HighPriorityFirst then
        table.sort(enabledList, function(a, b)
            local numA = tonumber(a:match("%d+")) or 0
            local numB = tonumber(b:match("%d+")) or 0
            return numA > numB
        end)
    else
        table.sort(enabledList, function(a, b)
            local numA = tonumber(a:match("%d+")) or 0
            local numB = tonumber(b:match("%d+")) or 0
            return numA < numB
        end)
    end

    return enabledList
end

local function getClosestGhoul()
    if not GhoulsFolder then return nil end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local farmOrder = getFarmOrder()
    if #farmOrder == 0 then
        return nil
    end

    for idx, targetModel in ipairs(farmOrder) do
        local tierClosest, tierShortest = nil, math.huge
        
        for _, ghoul in ipairs(GhoulsFolder:GetChildren()) do
            if ghoul:IsA("Model") and ghoul:GetAttribute("Captured") ~= true and ghoul:GetAttribute("BeingCaptured") ~= true then
                local gModel = ghoul:GetAttribute("GhoulModel") or ghoul.Name
                
                if gModel == targetModel then
                    local part = ghoul.PrimaryPart or ghoul:FindFirstChild("Main")
                    if part and part.Position.Y > MinYPosition then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < tierShortest then
                            tierShortest = dist
                            tierClosest = ghoul
                        end
                    end
                end
            end
        end
        
        if tierClosest then 
            print(string.format("✅ %d번째 우선순위 타겟 발견: %s (거리: %.1f)", idx, targetModel, tierShortest))
            return tierClosest 
        else
            print(string.format("❌ %d번째 우선순위 타겟 없음: %s (다음 순위 탐색)", idx, targetModel))
        end
    end
    return nil
end

local function startPerfectStick(target)
    AutoStick = true
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local part = target.PrimaryPart or target:FindFirstChild("Main")
    if not root or not humanoid or not part then return end

    local function computeTargetPos()
        local currentPart = target.PrimaryPart or target:FindFirstChild("Main")
        if not currentPart then return nil end
        return currentPart.Position + (currentPart.CFrame.LookVector * -1.5)
    end

    local initPos = computeTargetPos()
    if initPos then
        root.CFrame = CFrame.lookAt(initPos, part.Position)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end

    pcall(function()
        humanoid.PlatformStand = false
        humanoid.AutoRotate = false
    end)

    task.spawn(function()
        while AutoStick do
            task.wait()
            
            if not AutoStick then break end

            local char = LocalPlayer.Character
            if not char then break end

            local currentRoot = char:FindFirstChild("HumanoidRootPart")
            local currentHumanoid = char:FindFirstChildOfClass("Humanoid")
            local currentPart = target.PrimaryPart or target:FindFirstChild("Main")
            
            if not currentRoot or not currentHumanoid or not currentPart or not target.Parent then
                break
            end

            local state = currentHumanoid:GetState()
            if state == Enum.HumanoidStateType.Freefall 
               or state == Enum.HumanoidStateType.FallingDown 
               or state == Enum.HumanoidStateType.Ragdoll
               or state == Enum.HumanoidStateType.Physics then
                pcall(function()
                    currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                    currentHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end

            local targetPosition = currentPart.Position + (currentPart.CFrame.LookVector * -1.5)
            currentRoot.CFrame = CFrame.lookAt(targetPosition, currentPart.Position)

            currentRoot.AssemblyLinearVelocity = Vector3.zero
            currentRoot.AssemblyAngularVelocity = Vector3.zero
            currentRoot.Velocity = Vector3.zero
            currentRoot.RotVelocity = Vector3.zero

            pcall(function()
                currentHumanoid.AutoRotate = false
                currentHumanoid.PlatformStand = false
            end)
        end
    end)
end

local function stopPerfectStick()
    AutoStick = false
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid.AutoRotate = true
                humanoid.PlatformStand = false
            end)
        end
    end
end

local function autoCapture(target)
    if not BeginCapture then return end
    CurrentTarget = target
    local part = target.PrimaryPart or target:FindFirstChild("Main")
    if not part then 
        CurrentTarget = nil
        return 
    end

    print("[자동화] 포획 시작:", target.Name)
    TapLabel.Visible = true
    TapLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    TapLabel.Text = "🎃 캡처 시작 대기... 👻"

    startPerfectStick(target)
    task.wait(0.15)

    local successBegin, resultBegin = pcall(function()
        return BeginCapture:InvokeServer(target, "Tap")
    end)

    if not successBegin or not resultBegin or not resultBegin.Success then
        TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        TapLabel.Text = "💀 BeginCapture 실패! 재시도..."
        stopPerfectStick()
        CurrentTarget = nil
        return
    end

    local serverTaps = resultBegin.TapsRequired or 16
    local gModel = target:GetAttribute("GhoulModel") or target.Name
    
    local customTaps = GhoulTapCounts[gModel] or 0

    local finalTaps = serverTaps
    if customTaps and customTaps > 0 then
        finalTaps = customTaps
    end

    local tapInterval = GhoulTapIntervals[gModel] or GhoulTapIntervals.Default

    for i = 1, finalTaps do
        if not AutoEnabled or not target.Parent then break end
        TapLabel.Text = string.format("🦇 탭 시도: %d / %d", i, finalTaps)
        pcall(function() TapCapture:InvokeServer(target) end)
        task.wait(tapInterval)
    end

    if not target.Parent then
        stopPerfectStick()
        CurrentTarget = nil
        return
    end

    TapLabel.Text = "🕸️ 포획 완료 요청 중..."
    TapLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local waitTime = GhoulWaitTimes[gModel] or GhoulWaitTimes.Default
    
    TapLabel.Text = string.format("⏳ 대기 중... (%.2f초)", waitTime)
    task.wait(waitTime)
    
    local successComplete, resultComplete = pcall(function()
        return CompleteCapture:InvokeServer(target)
    end)
    
    task.spawn(function()
        if successComplete and type(resultComplete) == "table" then
            if resultComplete.Success == true then
                TapLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
                TapLabel.Text = "✅ 성공! (+"..tostring(resultComplete.Amount or 0).." Skulls)"
            else
                TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                TapLabel.Text = "❌ 실패: "..tostring(resultComplete.Error or "재시도")
            end
        else
            TapLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            TapLabel.Text = "❌ 통신 오류 - 재시도"
        end
        task.wait(1.5)
        if not CurrentTarget then
            TapLabel.Visible = false
        end
    end)
    
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

------------------------------------------------
-- 🎃 메인 탭
------------------------------------------------
local AutoToggle 

AutoToggle = MainTab:CreateToggle({
   Name = "🎃 자동 포획 시작 / 정지 👻",
   -- ★ 기본값을 true로 설정
   CurrentValue = true, 
   Flag = "AutoToggle",
   Callback = function(Value)
       AutoEnabled = Value
       if Value then 
           autoLoop() 
           Rayfield:Notify({Title = "🎃 시작", Content = "할로윈 자동 포획을 시작합니다.", Duration = 3})
       else 
           stopPerfectStick() 
           TapLabel.Visible = false
       end
   end,
})

-- ★★★ [추가] 스크립트가 실행되자마자 즉시 자동사냥 루프 시작 ★★★
task.spawn(function()
    task.wait(1) -- UI 로딩 대기
    if AutoEnabled then
        autoLoop()
        Rayfield:Notify({Title = "🎃 자동 시작", Content = "스크립트 로드와 동시에 자동 포획이 켜졌습니다.", Duration = 3})
    end
end)

MainTab:CreateSection("📊 현재 설정 요약")
MainTab:CreateLabel("• 파밍할 Ghoul은 '👻 타겟 선택' 탭에서 조절")
MainTab:CreateLabel("• 탭 횟수, 속도, 대기 시간은 '⚙️ Ghoul 설정' 탭에서 조절")
MainTab:CreateLabel("• 화면 좌측 상단에 Ghoul 개수 실시간 표시")
MainTab:CreateLabel("• Y축 제한: -150")

------------------------------------------------
-- 👻 타겟 선택 탭
------------------------------------------------
TargetTab:CreateParagraph({
    Title = "👻 타겟 선택 방식",
    Content = "아래 두 가지 방식으로 파밍할 Ghoul을 정할 수 있습니다.\n\n① '높은 순서부터 파밍' 스위치로 전체 순서 결정\n   (ON: 5→4→3→2→1 / OFF: 1→2→3→4→5)\n\n② Ghoul별 스위치로 파밍할 Ghoul만 개별 선택"
})

TargetTab:CreateSection("🔢 파밍 순서")
TargetTab:CreateToggle({
   Name = "⬆️ 높은 순서부터 파밍 (Ghoul5 → Ghoul1)",
   CurrentValue = true,
   Flag = "HighPriorityFirst",
   Callback = function(Value)
       HighPriorityFirst = Value
       if Value then
           print("파밍 순서: 높은 순서부터 (5→4→3→2→1)")
       else
           print("파밍 순서: 낮은 순서부터 (1→2→3→4→5)")
       end
   end,
})

TargetTab:CreateSection("👻 파밍할 Ghoul 선택")
TargetTab:CreateToggle({
   Name = "Ghoul5 파밍",
   CurrentValue = true,
   Flag = "Farm_Ghoul5",
   Callback = function(Value)
       GhoulEnabled["Ghoul5"] = Value
       print("Ghoul5 파밍:", Value and "ON" or "OFF")
   end,
})
TargetTab:CreateToggle({
   Name = "Ghoul4 파밍",
   CurrentValue = true,
   Flag = "Farm_Ghoul4",
   Callback = function(Value)
       GhoulEnabled["Ghoul4"] = Value
       print("Ghoul4 파밍:", Value and "ON" or "OFF")
   end,
})
TargetTab:CreateToggle({
   Name = "Ghoul3 파밍",
   CurrentValue = true,
   Flag = "Farm_Ghoul3",
   Callback = function(Value)
       GhoulEnabled["Ghoul3"] = Value
       print("Ghoul3 파밍:", Value and "ON" or "OFF")
   end,
})
TargetTab:CreateToggle({
   Name = "Ghoul2 파밍",
   CurrentValue = true,
   Flag = "Farm_Ghoul2",
   Callback = function(Value)
       GhoulEnabled["Ghoul2"] = Value
       print("Ghoul2 파밍:", Value and "ON" or "OFF")
   end,
})
TargetTab:CreateToggle({
   Name = "Ghoul1 파밍",
   CurrentValue = true,
   Flag = "Farm_Ghoul1",
   Callback = function(Value)
       GhoulEnabled["Ghoul1"] = Value
       print("Ghoul1 파밍:", Value and "ON" or "OFF")
   end,
})

------------------------------------------------
-- ⚙️ Ghoul 설정 탭
------------------------------------------------
GhoulTab:CreateParagraph({
    Title = "⚙️ Ghoul별 상세 설정",
    Content = "각 Ghoul마다 아래 3가지를 키보드로 입력하세요.\n• 탭 횟수\n• 탭 간격 (0.05 ~ 2.0초)\n• 대기 시간 (0.05 ~ 2.0초)\n\n⚠️ 입력 후 Enter를 누르면 적용됩니다."
})

local function createGhoulSection(ghoulName)
    GhoulTab:CreateSection("👻 " .. ghoulName)

    GhoulTab:CreateInput({
       Name = "탭 횟수",
       PlaceholderText = "예: 12",
       CurrentValue = tostring(GhoulTapCounts[ghoulName]),
       RemoveTextAfterFocusLost = false,
       Flag = "TapCount_" .. ghoulName,
       Callback = function(Text)
           local num = tonumber(Text)
           if num and num >= 0 then
               GhoulTapCounts[ghoulName] = num
               print(string.format("%s 탭 횟수 -> %d", ghoulName, num))
           end
       end,
    })

    GhoulTab:CreateInput({
       Name = "탭 간격 (초)",
       PlaceholderText = "0.05 ~ 2.0 (예: 0.5)",
       CurrentValue = tostring(GhoulTapIntervals[ghoulName]),
       RemoveTextAfterFocusLost = false,
       Flag = "TapIntervalInput_" .. ghoulName,
       Callback = function(Text)
           local num = clampSpeed(Text)
           if num then
               GhoulTapIntervals[ghoulName] = num
               print(string.format("%s 탭 간격 -> %.2f초", ghoulName, num))
           else
               Rayfield:Notify({Title = "⚠️ 잘못된 값", Content = "0.05 ~ 2.0 사이 숫자를 입력하세요.", Duration = 3})
           end
       end,
    })

    GhoulTab:CreateInput({
       Name = "대기 시간 (초)",
       PlaceholderText = "0.05 ~ 2.0 (예: 0.25)",
       CurrentValue = tostring(GhoulWaitTimes[ghoulName]),
       RemoveTextAfterFocusLost = false,
       Flag = "WaitTimeInput_" .. ghoulName,
       Callback = function(Text)
           local num = clampSpeed(Text)
           if num then
               GhoulWaitTimes[ghoulName] = num
               print(string.format("%s 대기 시간 -> %.2f초", ghoulName, num))
           else
               Rayfield:Notify({Title = "⚠️ 잘못된 값", Content = "0.05 ~ 2.0 사이 숫자를 입력하세요.", Duration = 3})
           end
       end,
    })
end

createGhoulSection("Ghoul1")
createGhoulSection("Ghoul2")
createGhoulSection("Ghoul3")
createGhoulSection("Ghoul4")
createGhoulSection("Ghoul5")

------------------------------------------------
-- ℹ️ 정보 탭
------------------------------------------------
InfoTab:CreateParagraph({
    Title = "🎃 Happy Halloween! 👻",
    Content = "📌 사용 방법\n1. '👻 타겟 선택'에서 파밍할 Ghoul과 순서 결정\n2. '⚙️ Ghoul 설정'에서 탭 횟수/속도 조절\n3. '🎃 메인'에서 자동 포획 시작\n\n⚡ 타겟 선택 방식\n• '높은 순서부터 파밍' 스위치: 전체 순서 결정\n• Ghoul별 스위치: 파밍할 Ghoul만 개별 선택\n• 상위 Ghoul이 없으면 자동으로 다음 순위 탐색\n\n👻 Ghoul 현황\n• 화면 좌측 상단에 실시간 개수 표시\n• 0.5초마다 자동 갱신\n• 초록색 = 있음 / 빨간색 = 없음\n\n🎯 자석 시스템\n• Ghoul에 완전 고정 (물리 무시)\n• 넘어져도 즉시 복구\n• 포획 후 즉시 다음 Ghoul로 이동\n\n🕸️ 즐거운 할로윈 되세요!"
})

-- 툴 자동 장착
local function equipTool()
    if EquipRF then
        pcall(function()
            EquipRF:InvokeServer("9e29c08b-1cb6-46c5-9458-6fb10bb625e1")
            print("✅ 툴 자동 장착 성공!")
        end)
    end
end

task.spawn(function()
    task.wait(1)
    equipTool()
end)

-- ★★★ [추가] 텔레포트(서버 이동) 감지 시 자동사냥 재시작 ★★★
LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        print("🔄 서버 이동(텔레포트) 시작 감지...")
    elseif State == Enum.TeleportState.InProgress then
        print("🔄 새 서버로 이동 중...")
    end
end)

TeleportService.LocalPlayerArrivedFromTeleport:Connect(function()
    print("🔄 새 서버 도착! 자동사냥 재시작...")
    task.wait(3) -- 새 서버 로딩 대기
    equipTool()
    if AutoEnabled then
        autoLoop()
        Rayfield:Notify({Title = "🔄 서버 이동 감지", Content = "새 서버에서 자동 포획이 다시 시작되었습니다!", Duration = 3})
    end
end)

-- ★★★ [추가] 캐릭터 리스폰(사망 후 부활) 시 재시작 ★★★
LocalPlayer.CharacterAdded:Connect(function(character)
    print("🔄 캐릭터 리스폰 감지됨...")
    task.wait(2)
    equipTool()
    if AutoEnabled then
        autoLoop()
    end
end)

-- 20분 AFK 방지
task.spawn(function()
    while task.wait(60) do
        if AutoEnabled then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Jump = true end
            end
            print("🛡️ AFK 방지: 가상 입력 전송 완료")
        end
    end
end)
