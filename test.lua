-- 初期ロード待ちとゲームIDチェック
if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 6035872082 then
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

print("Rivals Integrated Script starting...")

-- ==========================================
-- セクション1: アンチチートディスエイブラー
-- ==========================================
local success, err = pcall(function()
    assert(getgc, "executor missing required function getgc")
    assert(debug and debug.info, "executor missing required function debug.info")
    assert(hookfunction, "executor missing required function hookfunction")
    assert(getconnections, "executor missing required function getconnections")
    assert(newcclosure, "executor missing required function newcclosure")

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LogService = game:GetService("LogService")
    local ScriptContext = game:GetService("ScriptContext")

    -- AnalyticsPipelineの無効化
    task.spawn(function()
        local hooked = 0
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" then
                local ok, src = pcall(function() return debug.info(v, "s") end)
                if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                    hooked += 1
                    hookfunction(v, newcclosure(function(...)
                        return task.wait(9e9)
                    end))
                end
            end
        end
        print("Hanged " .. hooked .. " functions")
    end)

    -- リモートイベントのフック
    task.spawn(function()
        local ok, remote = pcall(function()
            return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnalyticsPipeline"):WaitForChild("RemoteEvent")
        end)
        if ok and remote and remote.OnClientEvent then
            local hooked = 0
            for _, conn in pairs(getconnections(remote.OnClientEvent)) do
                if conn and conn.Function then
                    if pcall(function() hookfunction(conn.Function, newcclosure(function(...) end)) end) then 
                        hooked += 1
                    end
                end
            end
            print("Hooked " .. hooked .. " anticheat remotes")
        end
    end)

    -- ログ送信とエラー報告の遮断
    task.spawn(function()
        for _, conn in pairs(getconnections(LogService.MessageOut)) do
            if conn and conn.Function then
                pcall(function() hookfunction(conn.Function, newcclosure(function(...) end)) end)
            end
        end
        
        for _, conn in ipairs(getconnections(ScriptContext.Error)) do
            pcall(function() conn:Disable() end)
        end
        
        pcall(function()
            hookfunction(ScriptContext.Error.Connect, newcclosure(function(...) return nil end))
        end)
        print("Log/Error connections disabled")
    end)

    -- Kick関数の無効化
    task.spawn(function()
        local KickNames = {"Kick", "kick"}
        for _, name in ipairs(KickNames) do
            local fn = LocalPlayer[name]
            if type(fn) == "function" then
                local oldkick
                oldkick = hookfunction(fn, newcclosure(function(self, ...)
                    if self == LocalPlayer then return end
                    return oldkick(self, ...)
                end))
            end
        end
    end)
end)

-- ==========================================
-- セクション2: パラメータ書き換え (Mod機能)
-- ==========================================
local function toggleTableAttribute(attribute, value)
    local count = 0
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, attribute) then
            gcVal[attribute] = value
            count += 1
        end
    end
    return count
end

if success then
    -- クールダウンやリコイルの適用
    toggleTableAttribute("ShootCooldown", 0)
    toggleTableAttribute("ShootSpread", 0)
    toggleTableAttribute("ShootRecoil", 0)
    toggleTableAttribute("AttackCooldown", 0)
    toggleTableAttribute("DeflectCooldown", 0)
    toggleTableAttribute("DashCooldown", 0)
    toggleTableAttribute("Cooldown", 0)
    toggleTableAttribute("SpinCooldown", 0)
    toggleTableAttribute("BuildCooldown", 0)

    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Rivals Multi-Hack",
        Text = "Anticheat Disabled & Mods Applied!",
        Duration = 5
    })
    print("All modifications applied successfully!")
else
    warn("Failed to initialize: " .. tostring(err))
end
