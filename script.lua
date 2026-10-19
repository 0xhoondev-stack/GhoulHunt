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

-- 2. UI 창 생성
local Window = Rayfield:CreateWindow({
   Name = "🎃 Ghoul Auto Capture 👻",
   LoadingTitle = "🕸️ Loading... 🕸️",
   LoadingSubtitle = "Happy Halloween Edition",
   Theme = "Dark",
   KeySystem = false
})

local MainTab = Window:CreateTab("🎃 메인", 4483362458)
local PriorityTab = Window:CreateTab("👻 타겟 순서 설정", 4483362458)
local TapCountTab = Window:CreateTab("🦇 탭 횟수 설정", 4483362458)
local InfoTab = Window:CreateTab("👻 정보", 4483362458)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

local AutoEnabled = false
local CurrentTarget = nil
local AutoStick = false

-- ★ [핵심] 우선순위 초기값 (기본: Ghoul5 -> 4 -> 3 -> 2 -> 1)
local TargetPriority = {"Ghoul5", "Ghoul4", "Ghoul3", "Ghoul2", "Ghoul1"}

-- ★ 탭 횟수
local GhoulTapCounts = {
    ["Ghoul1"] = 12, ["Ghoul2"] = 19, ["Ghoul3"] = 12, ["Ghoul4"] = 17, ["Ghoul5"] = 20,
}

-- ★ 고정값
local GhoulWaitTimes = {
    ["Ghoul1"] = 0.25, ["Ghoul2"] = 0.25, ["Ghoul3"] = 0.25, ["Ghoul4"] = 0.25, ["Ghoul5"] = 0.25,
    Default = 0.25
}
local TapInterval = 0.5
local MinYPosition = -150

-- ★ [핵심 수정] 우선순위에 따라 유령 찾기 (디버깅 로그 추가)
local function getClosestGhoul()
    if not GhoulsFolder then return nil end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    -- 1순위부터 순서대로 확인
    for idx, targetModel in ipairs(TargetPriority) do
        -- ★ nil이거나 빈 문자열이면 건너뜀
        if targetModel and targetModel ~= "" then
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
            
            -- ★ 이 순위에서 유령을 찾았다면 즉시 반환
            if tierClosest then 
                print(string.format("✅ %d순위 타겟 발견: %s (거리: %.1f)", idx, targetModel, tierShortest))
                return tierClosest 
            else
                print(string.format("❌ %d순위 타겟 없음: %s (다음 순위 탐색)", idx, targetModel))
            end
        end
    end
    return nil
end

-- 자석 시스템
local function startPerfectStick(target)
    AutoStick = true
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local part = target.PrimaryPart or target:FindFirstChild("Main")
    if not root or not humanoid or not part then return end

    local targetPos = part.Position + (part.CFrame.LookVector * -2)
    root.CFrame = CFrame.lookAt(targetPos, part.Position)
    root.AssemblyLinearVelocity = Vector3.zero

    task.spawn(function()
        while AutoStick do
            task.wait(0.01)
            local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local currentPart = target.PrimaryPart or target:FindFirstChild("Main")
            local currentHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            
            if currentRoot and currentPart and currentHumanoid and target.Parent then
                if currentHumanoid:GetState() == Enum.HumanoidStateType.Freefall or currentHumanoid:GetState() == Enum.HumanoidStateType.FallingDown then
                    currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
                local targetPosition = currentPart.Position + (currentPart.CFrame.LookVector * -1.5)
                local currentPos = currentRoot.Position
                local newPos = currentPos:Lerp(Vector3.new(targetPosition.X, currentPos.Y, targetPosition.Z), 0.3)
                currentRoot.CFrame = CFrame.lookAt(newPos, Vector3.new(currentPart.Position.X, currentPos.Y, currentPart.Position.Z))
                currentRoot.AssemblyLinearVelocity = Vector3.zero
                currentRoot.AssemblyAngularVelocity = Vector3.zero
            else
                break
            end
        end
    end)
end

local function stopPerfectStick()
    AutoStick = false
end

-- 서버 통신 및 성공 판별
local function autoCapture(target)
    if not BeginCapture then return end
    CurrentTarget = target
    local part = target.PrimaryPart or target:FindFirstChild("Main")
    if not part then return end

    print("[자동화] 포획 시작:", target.Name)
    TapLabel.Visible = true
    TapLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
    TapLabel.Text = "🎃 캡처 시작 대기... 👻"

    startPerfectStick(target)
    task.wait(0.2)

    local successBegin, resultBegin = pcall(function()
        return BeginCapture:InvokeServer(target, "Tap")
    end)

    if not successBegin or not resultBegin or not resultBegin.Success then
        TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        TapLabel.Text = "💀 BeginCapture 실패!"
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

    for i = 1, finalTaps do
        if not AutoEnabled or not target.Parent then break end
        TapLabel.Text = string.format("🦇 탭 시도: %d / %d", i, finalTaps)
        pcall(function() TapCapture:InvokeServer(target) end)
        task.wait(TapInterval)
    end

    TapLabel.Text = "🕸️ 포획 완료 요청 중..."
    TapLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    local waitTime = GhoulWaitTimes[gModel] or 0.25
    
    TapLabel.Text = string.format("⏳ 대기 중... (%.2f초)", waitTime)
    task.wait(waitTime)
    
    local successComplete, resultComplete = pcall(function()
        return CompleteCapture:InvokeServer(target)
    end)
    
    if successComplete and type(resultComplete) == "table" then
        if resultComplete.Success == true then
            TapLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
            TapLabel.Text = "✅ 진짜 포획 성공! (+"..tostring(resultComplete.Amount or 0).." Skulls)"
        else
            TapLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            TapLabel.Text = "❌ 실패: "..tostring(resultComplete.Error or "알 수 없는 이유")
        end
    else
        TapLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        TapLabel.Text = "❌ 통신 오류"
    end
    
    task.wait(2)
    TapLabel.Visible = false
    stopPerfectStick()
    CurrentTarget = nil
end

local function autoLoop()
    task.spawn(function()
        while AutoEnabled do
            local target = getClosestGhoul()
            if target then
                autoCapture(target)
                task.wait(0.5)
            else
                stopPerfectStick()
                task.wait(0.5)
            end
        end
    end)
end

------------------------------------------------
-- UI 구성
------------------------------------------------
MainTab:CreateToggle({
   Name = "🎃 자동 포획 시작 👻",
   CurrentValue = false,
   Flag = "AutoToggle",
   Callback = function(Value)
       AutoEnabled = Value
       if Value then 
           autoLoop() 
           Rayfield:Notify({Title = "🎃 시작", Content = "할로윈 자동 포획을 시작합니다.", Duration = 3})
       else 
           stopPerfectStick() 
       end
   end,
})

MainTab:CreateSection("🕸️ 현재 고정 설정")
MainTab:CreateLabel("탭 속도: 0.5초")
MainTab:CreateLabel("대기 시간: 0.25초")
MainTab:CreateLabel("Y축 제한: -150")

------------------------------------------------
-- ★ 타겟 순서 설정 탭 (안전장치 강화)
------------------------------------------------
PriorityTab:CreateParagraph({
    Title = "👻 타겟 우선순위 설정",
    Content = "원하는 Ghoul 순서를 선택하세요.\n먼저 선택한 Ghoul부터 찾아서 잡습니다.\n(예: Ghoul5를 1순위로 선택하면 Ghoul5가 없을 때만 2순위를 찾습니다.)"
})

PriorityTab:CreateDropdown({
   Name = "1순위 타겟",
   Options = {"Ghoul1", "Ghoul2", "Ghoul3", "Ghoul4", "Ghoul5"},
   CurrentOption = {"Ghoul5"},
   Flag = "Priority1",
   Callback = function(Option)
       -- ★ [핵심 수정] Option이 테이블이든 문자열이든 무조건 문자열로 변환
       local val = Option[1] or Option
       TargetPriority[1] = tostring(val)
       print("1순위 변경 ->", TargetPriority[1])
   end,
})

PriorityTab:CreateDropdown({
   Name = "2순위 타겟",
   Options = {"Ghoul1", "Ghoul2", "Ghoul3", "Ghoul4", "Ghoul5"},
   CurrentOption = {"Ghoul4"},
   Flag = "Priority2",
   Callback = function(Option)
       local val = Option[1] or Option
       TargetPriority[2] = tostring(val)
       print("2순위 변경 ->", TargetPriority[2])
   end,
})

PriorityTab:CreateDropdown({
   Name = "3순위 타겟",
   Options = {"Ghoul1", "Ghoul2", "Ghoul3", "Ghoul4", "Ghoul5"},
   CurrentOption = {"Ghoul3"},
   Flag = "Priority3",
   Callback = function(Option)
       local val = Option[1] or Option
       TargetPriority[3] = tostring(val)
       print("3순위 변경 ->", TargetPriority[3])
   end,
})

PriorityTab:CreateDropdown({
   Name = "4순위 타겟",
   Options = {"Ghoul1", "Ghoul2", "Ghoul3", "Ghoul4", "Ghoul5"},
   CurrentOption = {"Ghoul2"},
   Flag = "Priority4",
   Callback = function(Option)
       local val = Option[1] or Option
       TargetPriority[4] = tostring(val)
       print("4순위 변경 ->", TargetPriority[4])
   end,
})

PriorityTab:CreateDropdown({
   Name = "5순위 타겟",
   Options = {"Ghoul1", "Ghoul2", "Ghoul3", "Ghoul4", "Ghoul5"},
   CurrentOption = {"Ghoul1"},
   Flag = "Priority5",
   Callback = function(Option)
       local val = Option[1] or Option
       TargetPriority[5] = tostring(val)
       print("5순위 변경 ->", TargetPriority[5])
   end,
})

------------------------------------------------
-- ★ 탭 횟수 설정 탭
------------------------------------------------
TapCountTab:CreateInput({
   Name = "Ghoul1 탭 횟수", PlaceholderText = "예: 12", Flag = "TapCount_Ghoul1", RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local num = tonumber(Text)
       if num and num >= 0 then GhoulTapCounts["Ghoul1"] = num end
   end,
})
TapCountTab:CreateInput({
   Name = "Ghoul2 탭 횟수", PlaceholderText = "예: 19", Flag = "TapCount_Ghoul2", RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local num = tonumber(Text)
       if num and num >= 0 then GhoulTapCounts["Ghoul2"] = num end
   end,
})
TapCountTab:CreateInput({
   Name = "Ghoul3 탭 횟수", PlaceholderText = "예: 12", Flag = "TapCount_Ghoul3", RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local num = tonumber(Text)
       if num and num >= 0 then GhoulTapCounts["Ghoul3"] = num end
   end,
})
TapCountTab:CreateInput({
   Name = "Ghoul4 탭 횟수", PlaceholderText = "예: 17", Flag = "TapCount_Ghoul4", RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local num = tonumber(Text)
       if num and num >= 0 then GhoulTapCounts["Ghoul4"] = num end
   end,
})
TapCountTab:CreateInput({
   Name = "Ghoul5 탭 횟수", PlaceholderText = "예: 20", Flag = "TapCount_Ghoul5", RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local num = tonumber(Text)
       if num and num >= 0 then GhoulTapCounts["Ghoul5"] = num end
   end,
})

------------------------------------------------
-- ★ 정보 탭
------------------------------------------------
InfoTab:CreateParagraph({
    Title = "🎃 Happy Halloween! 👻",
    Content = "1. 유령을 찾아 자석처럼 붙습니다.\n2. 서버와 직접 통신하여 포획합니다.\n3. 20분 AFK 튕김을 방지합니다.\n4. 탭 횟수는 '탭 횟수 설정' 탭에서 변경 가능합니다.\n5. 타겟 순서는 '타겟 순서 설정' 탭에서 변경 가능합니다.\n\n🕸️ 즐거운 할로윈 되세요! 🕸️"
})

-- 툴 자동 장착
task.spawn(function()
    task.wait(1)
    if EquipRF then
        pcall(function()
            EquipRF:InvokeServer("9e29c08b-1cb6-46c5-9458-6fb10bb625e1")
            print("✅ 툴 자동 장착 성공!")
        end)
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
