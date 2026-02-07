-- ==========================================
-- 1. 読み込み待ち & IDチェック
-- ==========================================
if not game:IsLoaded() then game.Loaded:Wait() end
if game.GameId ~= 6035872082 then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local VirtualInputManager = game:GetService("VirtualInputManager")
local runS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

print("Rivals Silent Aim Edition Starting...")

-- ==========================================
-- 2. アンチチートバイパス (Analytics & Kick)
-- ==========================================
pcall(function()
    -- Analyticsの無効化
    task.spawn(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" then
                local ok, src = pcall(function() return debug.info(v, "s") end)
                if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                    hookfunction(v, newcclosure(function(...) return task.wait(9e9) end))
                end
            end
        end
    end)

    -- ログ・エラー報告の完全遮断
    for _, conn in pairs(getconnections(LogService.MessageOut)) do
        if conn.Function then hookfunction(conn.Function, newcclosure(function(...) end)) end
    end
    hookfunction(ScriptContext.Error.Connect, newcclosure(function(...) return nil end))

    -- Kick回避
    local function hookKick(name)
        local old; old = hookfunction(LocalPlayer[name], newcclosure(function(self, ...)
            return (self == LocalPlayer) and nil or old(self, ...)
        end))
    end
    hookKick("Kick") hookKick("kick")
end)

-- ==========================================
-- 3. 武器属性変更 (No Recoil, No Spread, No Cooldown)
-- ==========================================
local function applyMods()
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" then
            local mods = {
                "ShootCooldown", "ShootSpread", "ShootRecoil", "AttackCooldown", 
                "DeflectCooldown", "DashCooldown", "Cooldown", "SpinCooldown", "BuildCooldown"
            }
            for _, attr in ipairs(mods) do
                if rawget(gcVal, attr) then gcVal[attr] = 0 end
            end
        end
    end
end
applyMods()

-- ==========================================
-- 4. Silent Aim & ESP 設定
-- ==========================================
local Config = {
    Silent = {
        Enabled = true,
        HitPart = "HitboxHead",
        TriggerKey = Enum.UserInputType.MouseButton2, -- 右クリックでON/OFF
        FovSize = 200,
        TeamCheck = true,
        WallCheck = true
    },
    Esp = {
        Enabled = true,
        FillColor = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5
    }
}

-- 状態管理用
local silentActive = false
local FOV = Drawing.new("Circle")

-- Silent Aim ロジック
runS.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()
    FOV.Position = mousePos
    FOV.Radius = Config.Silent.FovSize
    FOV.Visible = Config.Silent.Enabled
    FOV.Color = silentActive and Color3.new(1, 0, 0) or Color3.new(1, 1, 1)
    FOV.Thickness = 1

    if Config.Silent.Enabled and silentActive then
        -- ロビーチェック (UIが出ている時は動かさない)
        local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        if mainGui and mainGui.MainFrame.Lobby.Currency.Visible then return end

        local target = nil
        local shortestDist = Config.Silent.FovSize

        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Config.Silent.HitPart) then
                -- 生存/チームチェック
                if v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
                if Config.Silent.TeamCheck and v.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("TeammateLabel") then continue end

                local pos, onScreen = camera:WorldToViewportPoint(v.Character[Config.Silent.HitPart].Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortestDist then
                        if Config.Silent.WallCheck then
                            local hit = camera:GetPartsObscuringTarget({v.Character[Config.Silent.HitPart].Position}, {LocalPlayer.Character, camera})
                            if #hit > 0 then continue end
                        end
                        target = v.Character[Config.Silent.HitPart]
                        shortestDist = dist
                    end
                end
            end
        end

        if target then
            -- Silent Aim: カメラをターゲットに一瞬向け、クリックを送信して即座に戻す
            -- ※Rivalsの仕様上、完全にカメラを固定しない方式にしています
            local oldCF = camera.CFrame
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, true, game, 0)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(mousePos.X, mousePos.Y, 0, false, game, 0)
            camera.CFrame = oldCF
        end
    end
end)

-- 切り替え入力
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Config.Silent.TriggerKey then
        silentActive = not silentActive
    end
end)

-- ESP ロジック (Highlight)
task.spawn(function()
    while task.wait(1) do
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                local isTeammate = v.Character:FindFirstChild("HumanoidRootPart"):FindFirstChild("TeammateLabel")
                local h = v.Character:FindFirstChild("EspHighlight") or Instance.new("Highlight")
                
                if Config.Esp.Enabled and not isTeammate then
                    h.Name = "EspHighlight"
                    h.Parent = v.Character
                    h.Adornee = v.Character
                    h.FillColor = Config.Esp.FillColor
                    h.FillTransparency = Config.Esp.Transparency
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                else
                    if v.Character:FindFirstChild("EspHighlight") then v.Character.EspHighlight:Destroy() end
                end
            end
        end
    end
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Rivals Script",
    Text = "Silent Aim & Full Mods Active!",
    Duration = 5
})
