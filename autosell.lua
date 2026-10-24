-- Auto Sell Brainrot: UI + auto sell tier terpilih (2x konfirmasi) + auto collect
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

-- Matikan instance lama (UI + loop) kalau script dijalankan ulang
if getgenv().BrainrotState then getgenv().BrainrotState.Running = false end
if getgenv().BrainrotUI then pcall(function() getgenv().BrainrotUI:Destroy() end) end

local SELL_INTERVAL = 5      -- detik, dihitung setelah proses jual selesai
local COLLECT_INTERVAL = 10  -- detik
local CONFIRM_DELAY = 0.5    -- jeda antar tembakan (klik 1 -> klik konfirmasi)

local State = { AutoSell = false, AutoCollect = false, Running = true }
getgenv().BrainrotState = State

-- Cari remote dengan timeout
local function find(parent, ...)
    local cur = parent
    for _, name in ipairs({ ... }) do
        cur = cur:WaitForChild(name, 10)
        if not cur then
            warn("[AutoSell] Tidak ketemu: " .. name)
            return nil
        end
    end
    return cur
end

local Ev = find(RS, "BrainrotsThings", "Misc", "Events", "Player")
if not Ev then return end
local SellAll = Ev:WaitForChild("SellAll", 10)
local CollectCash = Ev:WaitForChild("CollectCash", 10)
if not (SellAll and CollectCash) then
    warn("[AutoSell] Remote SellAll / CollectCash tidak ketemu")
    return
end

local TIERS = {
    { "Common",    Color3.fromRGB(200, 200, 200), false },
    { "Uncommon",  Color3.fromRGB(60, 180, 60),   false },
    { "Rare",      Color3.fromRGB(50, 130, 255),  false },
    { "Epic",      Color3.fromRGB(170, 60, 230),  false },
    { "Legendary", Color3.fromRGB(230, 200, 40),  false },
    { "Mythic",    Color3.fromRGB(255, 120, 60),  false },
    { "Cosmic",    Color3.fromRGB(40, 150, 255),  false },
    { "Secret",    Color3.fromRGB(230, 40, 140),  false },
    { "Celestial", Color3.fromRGB(190, 90, 255),  false },
}

-- ================= UI =================
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotAutoUI"
gui.ResetOnSpawn = false
local ok = pcall(function()
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
getgenv().BrainrotUI = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 270, 0, 330)
main.Position = UDim2.new(0, 20, 0.5, -165)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 32)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Auto Sell Brainrot"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -32)
body.Position = UDim2.new(0, 0, 0, 32)
body.BackgroundTransparency = 1
body.Parent = main

local status = Instance.new("TextLabel")
local function setStatus(text)
    if status and status.Parent then status.Text = text end
end

local function smallBtn(text, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 24)
    b.Position = UDim2.new(1, xOff, 0, 4)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local minBtn = smallBtn("-", -64, Color3.fromRGB(70, 70, 80))
local closeBtn = smallBtn("X", -32, Color3.fromRGB(200, 50, 50))

minBtn.MouseButton1Click:Connect(function()
    body.Visible = not body.Visible
    main.Size = body.Visible and UDim2.new(0, 270, 0, 330) or UDim2.new(0, 270, 0, 32)
end)
closeBtn.MouseButton1Click:Connect(function()
    State.Running = false
    gui:Destroy()
end)

-- Drag (mouse & sentuh, hanya input yang mulai di judul)
do
    local dragging, startPos, startPoint, dragInput
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragInput = true, i
            startPoint, startPos = i.Position, main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput
            or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end)
end

local function toggleRow(text, y, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Parent = body
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local function refresh()
        local on = State[key]
        btn.Text = text .. ": " .. (on and "ON" or "OFF")
        btn.BackgroundColor3 = on and Color3.fromRGB(40, 160, 70) or Color3.fromRGB(70, 70, 80)
    end
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh()
    end)
    refresh()
end

toggleRow("Auto Sell", 6, "AutoSell")
toggleRow("Auto Collect Cash", 44, "AutoCollect")

local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, -20, 0, 20)
lbl.Position = UDim2.new(0, 10, 0, 84)
lbl.BackgroundTransparency = 1
lbl.Text = "Tier yang dijual (tap untuk pilih):"
lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
lbl.Font = Enum.Font.Gotham
lbl.TextSize = 12
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.Parent = body

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, -20, 0, 120)
grid.Position = UDim2.new(0, 10, 0, 106)
grid.BackgroundTransparency = 1
grid.Parent = body
local gl = Instance.new("UIGridLayout", grid)
gl.CellSize = UDim2.new(0.333, -4, 0, 34)
gl.CellPadding = UDim2.new(0, 5, 0, 5)

for _, t in ipairs(TIERS) do
    local b = Instance.new("TextButton")
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = grid
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local function refresh()
        if t[3] then
            b.BackgroundColor3 = t[2]
            b.TextColor3 = Color3.new(0, 0, 0)
            b.Text = "✓ " .. t[1]
        else
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
            b.TextColor3 = Color3.fromRGB(150, 150, 150)
            b.Text = t[1]
        end
    end
    b.MouseButton1Click:Connect(function()
        t[3] = not t[3]
        refresh()
    end)
    refresh()
end

-- ================= LOGIKA JUAL =================
local selling = false

local function countSelected()
    local n = 0
    for _, t in ipairs(TIERS) do
        if t[3] then n += 1 end
    end
    return n
end

-- Tiap tier ditembak 2x (klik 1 + konfirmasi), dengan kunci biar tidak tumpang tindih
local function sellSelected()
    if selling then return end
    if countSelected() == 0 then
        setStatus("Pilih tier dulu.")
        return
    end
    selling = true
    setStatus("Menjual...")
    for _, t in ipairs(TIERS) do
        if not State.Running then break end
        if t[3] then
            for _ = 1, 2 do
                pcall(function() SellAll:FireServer(t[1]) end)
                task.wait(CONFIRM_DELAY)
            end
            task.wait(0.3)
        end
    end
    selling = false
    setStatus("Sell terakhir: " .. os.date("%H:%M:%S"))
end

local sellNow = Instance.new("TextButton")
sellNow.Size = UDim2.new(1, -20, 0, 32)
sellNow.Position = UDim2.new(0, 10, 0, 236)
sellNow.BackgroundColor3 = Color3.fromRGB(220, 130, 30)
sellNow.Text = "Sell Sekarang (tier terpilih)"
sellNow.TextColor3 = Color3.new(1, 1, 1)
sellNow.Font = Enum.Font.GothamBold
sellNow.TextSize = 13
sellNow.Parent = body
Instance.new("UICorner", sellNow).CornerRadius = UDim.new(0, 8)
sellNow.MouseButton1Click:Connect(function() task.spawn(sellSelected) end)

status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.new(0, 10, 0, 272)
status.BackgroundTransparency = 1
status.Text = "Siap."
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = body

-- ================= LOOP (terpisah) =================
task.spawn(function() -- auto sell
    local t = 0
    while State.Running do
        task.wait(1)
        if State.AutoSell then
            t += 1
            if t >= SELL_INTERVAL then
                sellSelected()
                t = 0
            end
        else
            t = SELL_INTERVAL -- begitu dinyalakan langsung jual
        end
    end
end)

task.spawn(function() -- auto collect
    local t = 0
    while State.Running do
        task.wait(1)
        if State.AutoCollect then
            t += 1
            if t >= COLLECT_INTERVAL then
                pcall(function() CollectCash:FireServer() end)
                t = 0
            end
        else
            t = COLLECT_INTERVAL
        end
    end
end)
