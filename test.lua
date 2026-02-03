-- 1. 初期設定
if not game:IsLoaded() then game.Loaded:Wait() end
if game.GameId ~= 6035872082 then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

print("Rivals Script: Loading targeted modifications...")

-----------------------------------------------------------
-- セクション1: アンチチート・ログ送信の無効化
-----------------------------------------------------------
pcall(function()
    -- 分析用関数のハング（フリーズ）処理
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "function" then
            local ok, src = pcall(function() return debug.info(v, "s") end)
            if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
                hookfunction(v, newcclosure(function(...) return task.wait(9e9) end))
            end
        end
    end

    -- Kickのブロック
    local oldKick
    oldKick = hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
        if self == LocalPlayer then return end
        return oldKick(self, ...)
    end))
end)

-----------------------------------------------------------
-- セクション2: 武器性能の強化（移動に影響しない項目を厳選）
-----------------------------------------------------------
-- スライディングや画面表示を壊さないよう、特定のキーワードを持つテーブルのみ変更
local function applyWeaponMod(targetAttribute, value)
    local count = 0
    for _, gcVal in pairs(getgc(true)) do
        if type(gcVal) == "table" and rawget(gcVal, targetAttribute) then
            -- 全てのCooldownを消すとダッシュ等が壊れるため、
            -- 武器に関連するキーワードがテーブル内に存在するか軽くチェック
            local isWeaponTable = rawget(gcVal, "Ammo") or rawget(gcVal, "MaxAmmo") or rawget(gcVal, "Damage")
            
            if isWeaponTable or targetAttribute:find("Shoot") or targetAttribute:find("Recoil") then
                gcVal[targetAttribute] = value
                count = count + 1
            end
        end
    end
    return count
end

-- 修正を加える項目（移動システムを壊さない安全なリスト）
task.spawn(function()
    task.wait(1) -- AC無効化の浸透待ち
    
    local mods = {
        {"ShootCooldown", 0},
        {"ShootSpread", 0},
        {"ShootRecoil", 0},
        {"AttackCooldown", 0},
        {"RecoilControl", 0},
        {"ReloadTime", 0} -- リロードも速くしたい場合は追加
    }

    for _, mod in ipairs(mods) do
        applyWeaponMod(mod[1], mod[2])
    end
    
    print("Weapon mods applied successfully.")
end)

-----------------------------------------------------------
-- 完了通知
-----------------------------------------------------------
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Rivals Lite",
    Text = "AC Disabled & Weapon Buffs Active",
    Duration = 5
})
