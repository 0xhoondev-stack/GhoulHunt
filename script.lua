-- Ghoul Auto Capture | 공중 부양 & 완벽한 유령 추적 (+ 20분 튕김 방지)

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not success or not Rayfield then warn("Rayfield 로드 실패") return end

local Window = Rayfield:CreateWindow({
   Name = "Ghoul Auto Capture",
   LoadingTitle = "Ghoul Auto Capture",
   LoadingSubtitle = "Fly & Anti-AFK",
   Theme = "Default",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("메인", 4483362458)
local TargetTab = Window:CreateTab("타겟팅", 4483362458)
local TimeTab = Window:CreateTab("탭 시간 설정", 4483362458)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Framework, ToolService, GhoulHuntingService, Equip, BeginCapture, CompleteCapture, GhoulsFolder
local isMobile = UserInputService.TouchEnabled
local AutoEnabled = false
local CurrentTarget = nil
local AlignPos = nil

local Settings = {
    TargetModel = "All",
    MobileTapInterval = 0.12,
    TeleportDistance = 2.5,
    Ghoul1Time = 7.0, Ghoul2Time = 10.0, Ghoul3Time = 15.0, Ghoul4Time = 20.0, Ghoul5Time = 25.0,
    DefaultTime = 10.0,
    PrioritizeHighTier = true
}

local function init()
    pcall(function()
        Framework = ReplicatedStorage:WaitForChild("Aurora"):WaitForChild("Framework")
        ToolService = Framework:WaitForChild("Services"):WaitForChild("ToolService")
        GhoulHuntingService = Framework:WaitForChild("Services"):WaitForChild("GhoulHuntingService")
        Equip = ToolService:WaitForChild("RF"):WaitForChild("Equip")
        BeginCapture = GhoulHuntingService:WaitForChild("RF"):WaitForChild("BeginCapture")
        CompleteCapture = GhoulHuntingService:WaitForChild("RF"):WaitForChild("CompleteCapture")
    end)
    GhoulsFolder = workspace:FindFirstChild("Persistent") and workspace.Persistent:FindFirstChild("Ghouls") and workspace.Persistent.Ghouls:FindFirstChild("Active")
    if not GhoulsFolder then GhoulsFolder = workspace:FindFirstChild("Ghouls") end
end
init()

local function forceEquip()
    local toolId = "9e29c08b-1cb6-46c5-9458-6fb10bb625e1"
    local toolName = "Bat Cannon"
    if Equip then
        pcall(function() Equip:InvokeServer(toolId) end)
        task.wait(0.1)
        pcall(function() Equip:InvokeServer(toolName) end)
    end
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if character and backpack then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local tool = backpack:FindFirstChild(toolName) or backpack:FindFirstChildOfClass("Tool")
            if tool then humanoid:EquipTool(tool) end
        end
    end
end

function getClosestGhoul()
    if not GhoulsFolder then init() return nil end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    local priorityModels = {"Ghoul5", "Ghoul4", "Ghoul3", "Ghoul2", "Ghoul1"}

    if Settings.PrioritizeHighTier and Settings.TargetModel == "All" then
        for _, modelName in ipairs(priorityModels) do
            local tierClosest, tierShortest = nil, math.huge
            for _, ghoul in ipairs(GhoulsFolder:GetChildren()) do
                if ghoul:IsA("Model") then
                    local part = ghoul.PrimaryPart or ghoul:FindFirstChildWhichIsA("BasePart")
                    if part and part.Position.Y > -150 then
                        local gModel = ghoul:GetAttribute("GhoulModel") or ghoul.Name
                        if gModel == modelName then
                            local dist = (part.Position - root.Position).Magnitude
                            if dist < tierShortest then
                                tierShortest = dist
                                tierClosest = ghoul
                            end
                        end
                    end
                end
            end
            if tierClosest then return tierClosest end
        end
    else
        local closest, shortest = nil, math.huge
        for _, ghoul in ipairs(GhoulsFolder:GetChildren()) do
            if ghoul:IsA("Model") then
                local part = ghoul.PrimaryPart or ghoul:FindFirstChildWhichIsA("BasePart")
                if part and part.Position.Y > -150 then
                    local gModel = ghoul:GetAttribute("GhoulModel") or ghoul.Name
                    if Settings.TargetModel == "All" or gModel == Settings.TargetModel then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < shortest then
                            shortest = dist
                            closest = ghoul
                        end
                    end
                end
            end
        end
        return closest
    end
    return nil
end

local function startMagnet(target)
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    if AlignPos then AlignPos:Destroy() end
    
    AlignPos = Instance.new("AlignPosition")
    AlignPos.Parent = root
    AlignPos.Attachment0 = root:FindFirstChildWhichIsA("Attachment") or Instance.new("Attachment", root)
    AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    AlignPos.MaxForce = math.huge
    AlignPos.Responsiveness = 100 
    
    task.spawn(function()
        while AlignPos and AlignPos.Parent and AutoEnabled and CurrentTarget and CurrentTarget.Parent do
            local part = CurrentTarget.PrimaryPart or CurrentTarget:FindFirstChildWhichIsA("BasePart")
            if part then
                local offset = part.CFrame.LookVector * -Settings.TeleportDistance
                local targetPos = part.Position + offset
                AlignPos.Position = Vector3.new(targetPos.X, part.Position.Y + 1, targetPos.Z)
            end
            task.wait(0.05)
        end
        if AlignPos then AlignPos:Destroy() end
    end)
end

local function stopMagnet()
    if AlignPos then
        AlignPos:Destroy()
        AlignPos = nil
    end
end

-- 물리 엔진 분리 (공중 부양)
task.spawn(function()
    while task.wait(0.1) do
        if AutoEnabled then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.PlatformStand = true end
                for _, v in ipairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end
    end
end)

-- ★ [추가] 20분 AFK 튕김 완벽 방지 시스템
task.spawn(function()
    while task.wait(60) do -- 1분마다 실행
        if AutoEnabled then
            local vu = game:GetService("VirtualUser")
            -- 마우스 미세 이동 및 클릭 신호 전송 (잠수 판정 방지)
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
            
            -- 캐릭터 점프 강제 발생
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.Jump = true end
            end
            print("🛡️ AFK 방지: 가상 입력 전송 완료")
        end
    end
end)

-- 마우스 추적 루프
task.spawn(function()
    while task.wait(0.01) do
        if AutoEnabled and CurrentTarget and CurrentTarget.Parent then
            local part = CurrentTarget.PrimaryPart or CurrentTarget:FindFirstChildWhichIsA("BasePart")
            if part then
                local aimPos = part.Position + Vector3.new(0, part.Size.Y / 2, 0)
                local sp, onScreen = Camera:WorldToViewportPoint(aimPos)
                if onScreen then 
                    Mouse.X = sp.X 
                    Mouse.Y = sp.Y 
                end
            end
        end
    end
end)

local function doTap()
    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
    task.wait(0.02)
    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
end

local function captureGhoul(target)
    if not target or not target.Parent then return false end
    CurrentTarget = target
    
    startMagnet(target)
    task.wait(0.3)

    if BeginCapture then
        local ok = pcall(function() BeginCapture:InvokeServer(target, "Hold") end)
        if not ok then 
            stopMagnet()
            CurrentTarget = nil 
            return false 
        end
    end
    task.wait(0.1)

    local gModel = target:GetAttribute("GhoulModel") or "Unknown"
    local targetTime = Settings.DefaultTime
    if gModel == "Ghoul1" then targetTime = Settings.Ghoul1Time
    elseif gModel == "Ghoul2" then targetTime = Settings.Ghoul2Time
    elseif gModel == "Ghoul3" then targetTime = Settings.Ghoul3Time
    elseif gModel == "Ghoul4" then targetTime = Settings.Ghoul4Time
    elseif gModel == "Ghoul5" then targetTime = Settings.Ghoul5Time
    end

    print(string.format("=== [%s] 포획 시작 (%.1f초) ===", gModel, targetTime))

    local start = tick()
    while tick() - start < targetTime and AutoEnabled do
        if not target.Parent then break end
        doTap()
        task.wait(Settings.MobileTapInterval)
    end

    if CompleteCapture then pcall(function() CompleteCapture:InvokeServer(target) end) end
    
    stopMagnet()
    CurrentTarget = nil
    task.wait(0.1)
    return true
end

local function autoLoop()
    task.spawn(function()
        forceEquip()
        task.wait(0.3)
        while AutoEnabled do
            pcall(function()
                local target = getClosestGhoul()
                if target then 
                    captureGhoul(target) 
                else
                    task.wait(0.5)
                end
            end)
        end
    end)
end

------------------------------------------------
-- UI 구성
------------------------------------------------
MainTab:CreateToggle({
   Name = "자동 포획 ON/OFF (공중부양)",
   CurrentValue = false,
   Callback = function(Value) 
       AutoEnabled = Value 
       if Value then 
           autoLoop() 
       else
           local character = LocalPlayer.Character
           if character then
               local humanoid = character:FindFirstChildOfClass("Humanoid")
               if humanoid then humanoid.PlatformStand = false end
               for _, v in ipairs(character:GetDescendants()) do
                   if v:IsA("BasePart") then v.CanCollide = true end
               end
           end
       end
   end,
})

MainTab:CreateButton({
   Name = "툴 강제 장착",
   Callback = function() forceEquip() end,
})

MainTab:CreateToggle({
    Name = "높은 등급 우선 탐색 (Ghoul5 -> 1)",
    CurrentValue = true,
    Callback = function(Value) Settings.PrioritizeHighTier = Value end,
})

TargetTab:CreateDropdown({
    Name = "타겟 Ghoul 모델 선택",
    Options = {"All", "Ghoul1", "Ghoul2", "Ghoul3", "Ghoul4", "Ghoul5"},
    CurrentOption = {"All"},
    MultipleOptions = false,
    Callback = function(option) Settings.TargetModel = option[1] end,
})

TimeTab:CreateSlider({ Name = "Ghoul1 탭 시간", Range = {1, 20}, Increment = 1, CurrentValue = 7, Callback = function(v) Settings.Ghoul1Time = v end })
TimeTab:CreateSlider({ Name = "Ghoul2 탭 시간", Range = {1, 25}, Increment = 1, CurrentValue = 10, Callback = function(v) Settings.Ghoul2Time = v end })
TimeTab:CreateSlider({ Name = "Ghoul3 탭 시간", Range = {1, 30}, Increment = 1, CurrentValue = 15, Callback = function(v) Settings.Ghoul3Time = v end })
TimeTab:CreateSlider({ Name = "Ghoul4 탭 시간", Range = {1, 40}, Increment = 1, CurrentValue = 20, Callback = function(v) Settings.Ghoul4Time = v end })
TimeTab:CreateSlider({ Name = "Ghoul5 탭 시간", Range = {1, 50}, Increment = 1, CurrentValue = 25, Callback = function(v) Settings.Ghoul5Time = v end })

TimeTab:CreateSlider({ Name = "탭 간격 (초)", Range = {0.05, 0.3}, Increment = 0.01, CurrentValue = 0.12, Callback = function(v) Settings.MobileTapInterval = v end })
TimeTab:CreateSlider({ Name = "텔레포트 거리", Range = {2, 4.5}, Increment = 0.1, CurrentValue = 2.5, Callback = function(v) Settings.TeleportDistance = v end })

Rayfield:Notify({ Title = "로드 완료", Content = "AFK 튕김 방지 & 공중 부양 활성화", Duration = 5 })
