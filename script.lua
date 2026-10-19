local ok, Rayfield = pcall(function() return loadstring(game:HttpGet('https://sirius.menu/rayfield'))() end)
if not ok or not Rayfield then return end
local Window = Rayfield:CreateWindow({Name="Ghoul Capture",LoadingTitle="Loading",LoadingSubtitle="Short Version",Theme="Default",ConfigurationSaving={Enabled=false},KeySystem=false})
local Main = Window:CreateTab("메인",4483362458)
local Target = Window:CreateTab("타겟팅",4483362458)
local Time = Window:CreateTab("탭 시간",4483362458)

local RS, Players, UIS, VIM = game:GetService("ReplicatedStorage"), game:GetService("Players"), game:GetService("UserInputService"), game:GetService("VirtualInputManager")
local LP, Cam, Mouse = Players.LocalPlayer, workspace.CurrentCamera, Players.LocalPlayer:GetMouse()
local F, T, G, Eq, Begin, Complete, Folder
local Auto, Current, Align = false, nil, nil

local S = {
    Model = "All", TapInt = 0.12, Dist = 2.5,
    G1 = 7.0, G2 = 10.0, G3 = 15.0, G4 = 20.0, G5 = 25.0, Def = 10.0, High = true
}

pcall(function()
    F = RS:WaitForChild("Aurora"):WaitForChild("Framework")
    T = F:WaitForChild("Services"):WaitForChild("ToolService")
    G = F:WaitForChild("Services"):WaitForChild("GhoulHuntingService")
    Eq = T:WaitForChild("RF"):WaitForChild("Equip")
    Begin = G:WaitForChild("RF"):WaitForChild("BeginCapture")
    Complete = G:WaitForChild("RF"):WaitForChild("CompleteCapture")
end)
Folder = workspace:FindFirstChild("Persistent") and workspace.Persistent:FindFirstChild("Ghouls") and workspace.Persistent.Ghouls:FindFirstChild("Active") or workspace:FindFirstChild("Ghouls")

local function equip()
    if Eq then pcall(function() Eq:InvokeServer("9e29c08b-1cb6-46c5-9458-6fb10bb625e1") end) task.wait(0.1) pcall(function() Eq:InvokeServer("Bat Cannon") end) end
end

local function getGhoul()
    if not Folder then return nil end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local pr = {"Ghoul5","Ghoul4","Ghoul3","Ghoul2","Ghoul1"}
    local function check(g)
        local p = g:FindFirstChildWhichIsA("BasePart") or g.PrimaryPart
        return p and p.Position.Y > -150
    end
    if S.High and S.Model == "All" then
        for _, m in ipairs(pr) do
            local best, dist = nil, math.huge
            for _, g in ipairs(Folder:GetChildren()) do
                if g:IsA("Model") and check(g) and (g:GetAttribute("GhoulModel") or g.Name) == m then
                    local d = (g.PrimaryPart.Position - root.Position).Magnitude
                    if d < dist then dist, best = d, g end
                end
            end
            if best then return best end
        end
    else
        local best, dist = nil, math.huge
        for _, g in ipairs(Folder:GetChildren()) do
            if g:IsA("Model") and check(g) then
                local gm = g:GetAttribute("GhoulModel") or g.Name
                if S.Model == "All" or gm == S.Model then
                    local d = (g.PrimaryPart.Position - root.Position).Magnitude
                    if d < dist then dist, best = d, g end
                end
            end
        end
        return best
    end
end

local function magnet(t)
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if Align then Align:Destroy() end
    Align = Instance.new("AlignPosition", root)
    Align.Attachment0 = root:FindFirstChildWhichIsA("Attachment") or Instance.new("Attachment", root)
    Align.Mode = Enum.PositionAlignmentMode.OneAttachment
    Align.MaxForce, Align.Responsiveness = math.huge, 100
    task.spawn(function()
        while Align and Auto and Current and Current.Parent do
            local p = Current.PrimaryPart or Current:FindFirstChildWhichIsA("BasePart")
            if p then
                local off = p.CFrame.LookVector * -S.Dist
                Align.Position = Vector3.new(p.Position.X + off.X, p.Position.Y + 1, p.Position.Z + off.Z)
            end
            task.wait(0.05)
        end
        if Align then Align:Destroy() end
    end)
end

task.spawn(function()
    while task.wait(0.1) do
        if Auto and LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = true end
            for _, v in ipairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.01) do
        if Auto and Current and Current.Parent then
            local p = Current.PrimaryPart or Current:FindFirstChildWhichIsA("BasePart")
            if p then
                local sp, on = Cam:WorldToViewportPoint(p.Position + Vector3.new(0, p.Size.Y/2, 0))
                if on then Mouse.X, Mouse.Y = sp.X, sp.Y end
            end
        end
    end
end)

local function capture(t)
    if not t or not t.Parent then return end
    Current = t
    magnet(t)
    task.wait(0.3)
    if Begin then pcall(function() Begin:InvokeServer(t, "Hold") end) end
    task.wait(0.1)
    local gm = t:GetAttribute("GhoulModel") or "Unknown"
    local tm = S.Def
    if gm == "Ghoul1" then tm = S.G1 elseif gm == "Ghoul2" then tm = S.G2 elseif gm == "Ghoul3" then tm = S.G3 elseif gm == "Ghoul4" then tm = S.G4 elseif gm == "Ghoul5" then tm = S.G5 end
    local st = tick()
    while tick() - st < tm and Auto do
        if not t.Parent then break end
        VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 1)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 1)
        task.wait(S.TapInt)
    end
    if Complete then pcall(function() Complete:InvokeServer(t) end) end
    if Align then Align:Destroy() end
    Current = nil
end

local function loop()
    task.spawn(function()
        equip()
        task.wait(0.3)
        while Auto do
            local t = getGhoul()
            if t then capture(t) else task.wait(0.5) end
        end
    end)
end

Main:CreateToggle({Name="자동 포획 ON/OFF",CurrentValue=false,Callback=function(v)
    Auto = v
    if v then loop() else
        local c = LP.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
            for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end
end})
Main:CreateButton({Name="툴 강제 장착",Callback=equip})
Main:CreateToggle({Name="높은 등급 우선 (Ghoul5->1)",CurrentValue=true,Callback=function(v) S.High = v end})
Target:CreateDropdown({Name="타겟 모델",Options={"All","Ghoul1","Ghoul2","Ghoul3","Ghoul4","Ghoul5"},CurrentOption={"All"},Callback=function(o) S.Model = o[1] end})
Time:CreateSlider({Name="Ghoul1 탭 시간",Range={1,20},Increment=1,CurrentValue=7,Callback=function(v) S.G1 = v end})
Time:CreateSlider({Name="Ghoul2 탭 시간",Range={1,25},Increment=1,CurrentValue=10,Callback=function(v) S.G2 = v end})
Time:CreateSlider({Name="Ghoul3 탭 시간",Range={1,30},Increment=1,CurrentValue=15,Callback=function(v) S.G3 = v end})
Time:CreateSlider({Name="Ghoul4 탭 시간",Range={1,40},Increment=1,CurrentValue=20,Callback=function(v) S.G4 = v end})
Time:CreateSlider({Name="Ghoul5 탭 시간",Range={1,50},Increment=1,CurrentValue=25,Callback=function(v) S.G5 = v end})
Time:CreateSlider({Name="탭 간격",Range={0.05,0.3},Increment=0.01,CurrentValue=0.12,Callback=function(v) S.TapInt = v end})
Time:CreateSlider({Name="텔레포트 거리",Range={2,4.5},Increment=0.1,CurrentValue=2.5,Callback=function(v) S.Dist = v end})
Rayfield:Notify({Title="로드 완료",Content="공중부양 활성화",Duration=5})
