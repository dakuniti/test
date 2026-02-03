-- 1. 読み込み待ち & IDチェック
if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 6035872082 then
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

print("Rivals Full Hack Starting...")

-- ==========================================
-- セクションA: アンチチート無効化
-- ==========================================
local success, err = pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LogService = game:GetService("LogService")
    local ScriptContext = game:GetService("ScriptContext")

    -- 送信系関数のハング（AnalyticsPipeline）
    task.spawn(function()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" then
                local ok, src = pcall(function() return debug.info(v, "s") end)
                if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                    hookfunction(v, newcclosure(function(...) return task.wait(9e9) end))
                end
            end
        end
    end)

    -- リモートイベントのフック
    task.spawn(function()
        local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnalyticsPipeline"):WaitForChild("RemoteEvent")
        for _, conn in pairs(getconnections(remote.OnClientEvent)) do
            if conn.Function then
                hookfunction(conn.Function, newcclosure(function(...) end))
            end
        end
    end)

    -- ログ・エラー報告の完全遮断
    task.spawn(function()
        for _, conn in pairs(getconnections(LogService.MessageOut)) do
            if conn.Function then hookfunction(conn.Function, newcclosure(function(...) end)) end
        end
        for _, conn in ipairs(getconnections(ScriptContext.Error)) do
            conn:Disable()
        end
        hookfunction(ScriptContext.Error.Connect, newcclosure(function(...) return nil end))
    end)

    -- Kick回避
    task.spawn(function()
        local function hookKick(name)
            local old; old = hookfunction(LocalPlayer[name], newcclosure(function(self, ...)
                if self == LocalPlayer then return nil end
                return old(self, ...)
            end))
        end
        hookKick("Kick")
        hookKick("kick")
    end)
end)

-- ==========================================
-- セクションB: 全機能一括適用（toggleTableAttribute）
-- ==========================================
local function toggleTableAttribute(attribute, value)
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, attribute) then
            gcVal[attribute] = value
        end
    end
end

-- ご提示いただいたすべての項目をここに集約
toggleTableAttribute("ShootCooldown", 0)
toggleTableAttribute("ShootSpread", 0)
toggleTableAttribute("ShootRecoil", 0)
toggleTableAttribute("AttackCooldown", 0)
toggleTableAttribute("DeflectCooldown", 0)
toggleTableAttribute("DashCooldown", 0)
toggleTableAttribute("Cooldown", 0)
toggleTableAttribute("SpinCooldown", 0)
toggleTableAttribute("BuildCooldown", 0)

-- ==========================================
-- 完了通知
-- ==========================================
if success then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Rivals Script",
        Text = "Anticheat OFF & All Mods ON!",
        Duration = 5
    })
    print("Done! All attributes set to 0.")
else
    warn("Error during bypass: " .. tostring(err))
end
