-- BID FOR BRAINROT V1 (By D33RZN): UI + Auto Bid + Auto Sell + Auto Collect + Auto Rebirth + ESP
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

-- Matikan instance lama (UI + loop) kalau script dijalankan ulang
if getgenv().BrainrotState then getgenv().BrainrotState.Running = false end
if getgenv().BrainrotUI then pcall(function() getgenv().BrainrotUI:Destroy() end) end

-- ===== PENGATURAN =====
local SELL_INTERVAL = 5        -- detik antar putaran jual
local COLLECT_INTERVAL = 10    -- detik antar collect
local REBIRTH_INTERVAL = 15    -- detik antar percobaan rebirth
local FIRE_COUNT = 2           -- mode per rarity: tembakan SellAll (klik + konfirmasi)
local CONFIRM_DELAY = 1        -- mode per rarity: jeda antar tembakan
local TIER_DELAY = 2           -- mode per rarity: jeda antar rarity
local ITEM_FIRE = 2            -- mode filter nilai: tembakan SellItem per brainrot
local ITEM_CONFIRM_DELAY = 1   -- mode filter nilai: jeda klik -> konfirmasi
local ITEM_DELAY = 0.6         -- mode filter nilai: jeda antar brainrot
local MAX_PER_ROUND = 100      -- mode filter nilai: maksimal brainrot per putaran
local SKIP_GRADED = true       -- lewati brainrot yang punya grade
local DUEL_PAUSE = 10          -- detik, jeda kalau kena larangan duel
local REBIRTH_REMOTE_NAME = "RebirthRequest"

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_ON   = Color3.fromRGB(60, 190, 100)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local State = {
    AutoSell = false, AutoCollect = false, AutoRebirth = false,
    ESPPlayer = false,
    SellMin = 0, SellMax = 0,   -- SellMax = 0 berarti filter nilai mati
    Running = true, Inventory = {}, InvStamp = 0,
}
getgenv().BrainrotState = State

-- ===== REMOTE =====
local function find(parent, ...)
    local cur = parent
    for _, name in ipairs({ ... }) do
        cur = cur:WaitForChild(name, 10)
        if not cur then
            warn("[BidForBrainrot] Tidak ketemu: " .. name)
            return nil
        end
    end
    return cur
end

local Ev = find(RS, "BrainrotsThings", "Misc", "Events", "Player")
if not Ev then return end
local SellAll = Ev:WaitForChild("SellAll", 10)
local CollectCash = Ev:WaitForChild("CollectCash", 10)
local SellItem = Ev:WaitForChild("SellItem", 10)
local RequestInventory = Ev:WaitForChild("RequestInventory", 10)
local InventoryUpdated = Ev:WaitForChild("InventoryUpdated", 10)
if not (SellAll and CollectCash and SellItem and RequestInventory and InventoryUpdated) then
    warn("[BidForBrainrot] Ada remote yang tidak ketemu")
    return
end
local RebirthRemote = REBIRTH_REMOTE_NAME and Ev:FindFirstChild(REBIRTH_REMOTE_NAME) or nil

InventoryUpdated.OnClientEvent:Connect(function(inv)
    if type(inv) == "table" then
        State.Inventory = inv
        State.InvStamp += 1
    end
end)

local TIERS = {
    { "Common",       Color3.fromRGB(200, 200, 200), false },
    { "Uncommon",     Color3.fromRGB(60, 180, 60),   false },
    { "Rare",         Color3.fromRGB(50, 130, 255),  false },
    { "Epic",         Color3.fromRGB(170, 60, 230),  false },
    { "Legendary",    Color3.fromRGB(230, 200, 40),  false },
    { "Mythic",       Color3.fromRGB(255, 120, 60),  false },
    { "Cosmic",       Color3.fromRGB(40, 150, 255),  false },
    { "Secret",       Color3.fromRGB(230, 40, 140),  false },
    { "Celestial",    Color3.fromRGB(190, 90, 255),  false },
    { "Divine",       Color3.fromRGB(255, 170, 220), false },
    { "Brainrot God", Color3.fromRGB(255, 80, 80),   false },
}

local function fmtNum(n)
    if n >= 1e12 then return string.format("%.3gT", n / 1e12) end
    if n >= 1e9 then return string.format("%.3gB", n / 1e9) end
    if n >= 1e6 then return string.format("%.3gM", n / 1e6) end
    if n >= 1e3 then return string.format("%.3gK", n / 1e3) end
    return tostring(math.floor(n))
end

-- "500k", "2m", "1.5b" -> angka. Kosong = 0. Format salah = nil
local function parseValue(s)
    s = (s or ""):lower():gsub("[%s,]", "")
    if s == "" then return 0 end
    local num, suf = s:match("^(%d*%.?%d+)([kmbt]?)$")
    if not num then return nil end
    local mult = ({ k = 1e3, m = 1e6, b = 1e9, t = 1e12 })[suf] or 1
    return tonumber(num) * mult
end

local function corner(inst, r) Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r) end
local function countSelected()
    local n = 0
    for _, t in ipairs(TIERS) do if t[3] then n += 1 end end
    return n
end
local function allSelected()
    for _, t in ipairs(TIERS) do if not t[3] then return false end end
    return true
end
local function tierOn(name)
    for _, t in ipairs(TIERS) do
        if t[1] == name then return t[3] end
    end
    return false
end

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotAutoUI"
gui.ResetOnSpawn = false
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
getgenv().BrainrotUI = gui

local WIN_W, WIN_H = 430, 270
local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
main.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
main.BackgroundColor3 = C_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 12)
Instance.new("UIStroke", main).Color = Color3.fromRGB(60, 60, 72)

-- ===== TITLE BAR =====
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 32)
bar.BackgroundColor3 = C_BAR
bar.BorderSizePixel = 0
bar.Parent = main

-- Judul + tulisan kecil "By D33RZN" di sampingnya
local titleBox = Instance.new("Frame")
titleBox.Size = UDim2.new(1, -220, 1, 0)
titleBox.Position = UDim2.new(0, 12, 0, 0)
titleBox.BackgroundTransparency = 1
titleBox.Parent = bar
local tbl = Instance.new("UIListLayout", titleBox)
tbl.FillDirection = Enum.FillDirection.Horizontal
tbl.VerticalAlignment = Enum.VerticalAlignment.Center
tbl.SortOrder = Enum.SortOrder.LayoutOrder
tbl.Padding = UDim.new(0, 5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 0, 0, 16)
title.AutomaticSize = Enum.AutomaticSize.X
title.BackgroundTransparency = 1
title.Text = "BID FOR BRAINROT V1"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.LayoutOrder = 1
title.Parent = titleBox

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(0, 0, 0, 10)
credit.AutomaticSize = Enum.AutomaticSize.X
credit.BackgroundTransparency = 1
credit.Text = "By D33RZN"
credit.TextColor3 = C_GRAY
credit.Font = Enum.Font.Gotham
credit.TextSize = 7
credit.LayoutOrder = 2
credit.Parent = titleBox

local search = Instance.new("TextBox")
search.Size = UDim2.new(0, 120, 0, 22)
search.Position = UDim2.new(1, -196, 0, 5)
search.BackgroundColor3 = C_BG
search.PlaceholderText = "Search"
search.PlaceholderColor3 = C_GRAY
search.Text = ""
search.TextColor3 = Color3.new(1, 1, 1)
search.Font = Enum.Font.Gotham
search.TextSize = 11
search.ClearTextOnFocus = false
search.Parent = bar
corner(search, 6)

local function barBtn(text, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 22)
    b.Position = UDim2.new(1, xOff, 0, 5)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = bar
    corner(b, 6)
    return b
end
local minBtn = barBtn("-", -64, C_OFF)
local closeBtn = barBtn("X", -32, Color3.fromRGB(200, 50, 50))
closeBtn.MouseButton1Click:Connect(function()
    State.Running = false
    gui:Destroy()
end)

do -- drag lewat title bar
    local dragging, startPos, startPoint, dragInput
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragInput = true, i
            startPoint, startPos = i.Position, main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end)
end

-- ===== BODY: SIDEBAR + HALAMAN =====
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -32)
body.Position = UDim2.new(0, 0, 0, 32)
body.BackgroundTransparency = 1
body.Parent = main

minBtn.MouseButton1Click:Connect(function()
    body.Visible = not body.Visible
    main.Size = body.Visible and UDim2.new(0, WIN_W, 0, WIN_H) or UDim2.new(0, WIN_W, 0, 32)
end)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 96, 1, 0)
sidebar.BackgroundColor3 = C_BAR
sidebar.BorderSizePixel = 0
sidebar.Parent = body

local tabList = Instance.new("Frame")
tabList.Size = UDim2.new(1, 0, 1, -30)
tabList.BackgroundTransparency = 1
tabList.Parent = sidebar
local tl = Instance.new("UIListLayout", tabList)
tl.Padding = UDim.new(0, 4)
tl.SortOrder = Enum.SortOrder.LayoutOrder
local tp = Instance.new("UIPadding", tabList)
tp.PaddingTop = UDim.new(0, 8)
tp.PaddingLeft = UDim.new(0, 6)
tp.PaddingRight = UDim.new(0, 6)

local fpsLbl = Instance.new("TextLabel")
fpsLbl.Size = UDim2.new(1, -12, 0, 16)
fpsLbl.Position = UDim2.new(0, 6, 1, -22)
fpsLbl.BackgroundTransparency = 1
fpsLbl.Text = "-- FPS"
fpsLbl.TextColor3 = C_GRAY
fpsLbl.Font = Enum.Font.Gotham
fpsLbl.TextSize = 10
fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
fpsLbl.Parent = sidebar
do
    local frames, t0 = 0, os.clock()
    RunService.Heartbeat:Connect(function()
        if not gui.Parent then return end
        frames += 1
        local now = os.clock()
        if now - t0 >= 0.5 then
            fpsLbl.Text = math.floor(frames / (now - t0)) .. " FPS"
            frames, t0 = 0, now
        end
    end)
end

local pages, tabs = {}, {}
local function newPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, -96, 1, 0)
    p.Position = UDim2.new(0, 96, 0, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = false
    p.Parent = body
    local l = Instance.new("UIListLayout", p)
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", p)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pages[name] = p
    return p
end

local function setTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name) and C_ROW or C_BAR
        b.TextColor3 = (n == name) and Color3.new(1, 1, 1) or C_GRAY
    end
end

local function newTab(name, order, icon)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = order
    b.Parent = tabList
    corner(b, 8)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 32)

    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 24, 1, 0)
    ic.Position = UDim2.new(0, -26, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 15
    ic.Font = Enum.Font.GothamBold
    ic.TextColor3 = Color3.new(1, 1, 1)
    ic.Parent = b

    tabs[name] = b
    b.MouseButton1Click:Connect(function() setTab(name) end)
end

local mainPage = newPage("Main")
local miscPage = newPage("Misc")
newTab("Main", 1, "🏠")
newTab("Misc", 2, "⚙")

local sections = {}
local function section(page, keyword, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.LayoutOrder = order
    f.Parent = page
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 4)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    sections[#sections + 1] = { f, keyword:lower() }
    return f
end

search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = search.Text:lower()
    for _, s in ipairs(sections) do
        s[1].Visible = (q == "") or (s[2]:find(q, 1, true) ~= nil)
    end
end)

local function groupTitle(page, text, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order
    l.Parent = page
end

local refreshers = {}
local function refreshAll() for _, f in ipairs(refreshers) do f() end end

local statusLbl
local function setStatus(t, color)
    if statusLbl and statusLbl.Parent then
        statusLbl.Text = t
        statusLbl.TextColor3 = color or C_GRAY
    end
end

local function textBlock(parent, titleText, desc, widthOffset, inList)
    local txt = Instance.new("Frame")
    txt.Size = UDim2.new(1, inList and 0 or widthOffset, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.LayoutOrder = 1
    if not inList then txt.Position = UDim2.new(0, 10, 0, 0) end
    txt.Parent = parent
    local l = Instance.new("UIListLayout", txt)
    l.Padding = UDim.new(0, 2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", txt)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 16)
    t.BackgroundTransparency = 1
    t.Text = titleText
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.LayoutOrder = 1
    t.Parent = txt

    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, 0, 0, 0)
        d.AutomaticSize = Enum.AutomaticSize.Y
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C_GRAY
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.TextWrapped = true
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
        d.LayoutOrder = 2
        d.Parent = txt
    end
    return txt, t
end

local function switchRow(parent, text, desc, key)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = C_ROW
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = 1
    row.Parent = parent
    corner(row, 8)
    Instance.new("UISizeConstraint", row).MinSize = Vector2.new(0, 38)

    textBlock(row, text, desc, -64, false)

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -50, 0.5, -10)
    pill.Parent = row
    corner(pill, 10)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = pill
    corner(knob, 8)

    local function refresh(animate)
        local on = State[key]
        local col = on and C_ON or C_OFF
        local pos = on and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        if animate then
            local info = TweenInfo.new(0.15)
            TS:Create(pill, info, { BackgroundColor3 = col }):Play()
            TS:Create(knob, info, { Position = pos }):Play()
        else
            pill.BackgroundColor3 = col
            knob.Position = pos
        end
    end
    row.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh(true)
    end)
    refresh(false)
end

-- ===== HALAMAN MAIN: urutan grup = Bid (1-4), Sell (10-13), Auto (20-22), Status (99) =====

-- ----- SELL (urutan 10-13) -----
groupTitle(mainPage, "Sell", 10)

local sAuto = section(mainPage, "auto sell", 11)
switchRow(sAuto, "Auto Sell",
    "Jual brainrot otomatis tiap beberapa detik, hanya rarity yang kamu pilih di bawah.", "AutoSell")

local sRar = section(mainPage,
    "rarity to sell all common uncommon rare epic legendary mythic cosmic secret celestial divine brainrot god", 12)

local rarBtn = Instance.new("TextButton")
rarBtn.Size = UDim2.new(1, 0, 0, 0)
rarBtn.AutomaticSize = Enum.AutomaticSize.Y
rarBtn.BackgroundColor3 = C_ROW
rarBtn.Text = ""
rarBtn.AutoButtonColor = false
rarBtn.LayoutOrder = 1
rarBtn.Parent = sRar
corner(rarBtn, 8)
Instance.new("UISizeConstraint", rarBtn).MinSize = Vector2.new(0, 38)
local _, rarTitle = textBlock(rarBtn, "Rarity To Sell",
    "Pilih rarity yang boleh dijual. Rarity yang tidak dicentang tidak akan disentuh.", -40, false)

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.new(0, 24, 0, 20)
arrow.Position = UDim2.new(1, -30, 0.5, -10)
arrow.BackgroundTransparency = 1
arrow.TextColor3 = Color3.new(1, 1, 1)
arrow.Font = Enum.Font.GothamBold
arrow.TextSize = 14
arrow.Parent = rarBtn

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, 0, 0, 130)
list.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Visible = false
list.LayoutOrder = 2
list.Parent = sRar
corner(list, 8)
local ll = Instance.new("UIListLayout", list)
ll.Padding = UDim.new(0, 2)
ll.SortOrder = Enum.SortOrder.LayoutOrder
local lpad = Instance.new("UIPadding", list)
lpad.PaddingLeft = UDim.new(0, 6)
lpad.PaddingRight = UDim.new(0, 8)
lpad.PaddingTop = UDim.new(0, 6)
lpad.PaddingBottom = UDim.new(0, 6)

local expanded = false
local function updateRar()
    local n = countSelected()
    rarTitle.Text = "Rarity To Sell" .. (n > 0 and ("  (" .. n .. ")") or "")
    arrow.Text = expanded and "^" or ">"
    list.Visible = expanded
end
rarBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    updateRar()
end)
table.insert(refreshers, updateRar)

local function optRow(order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 22)
    b.BackgroundColor3 = C_ROW
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = order
    b.Parent = list
    corner(b, 5)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
    return b
end

local allRow = optRow(0)
table.insert(refreshers, function()
    local on = allSelected()
    allRow.Text = (on and "✓  " or "    ") .. "All"
    allRow.TextColor3 = on and Color3.new(1, 1, 1) or C_GRAY
    allRow.BackgroundTransparency = on and 0 or 1
end)
allRow.MouseButton1Click:Connect(function()
    local s = not allSelected()
    for _, t in ipairs(TIERS) do t[3] = s end
    refreshAll()
end)

for idx, t in ipairs(TIERS) do
    local r = optRow(idx)
    table.insert(refreshers, function()
        r.Text = (t[3] and "✓  " or "    ") .. t[1]
        r.TextColor3 = t[3] and t[2] or C_GRAY
        r.BackgroundTransparency = t[3] and 0 or 1
    end)
    r.MouseButton1Click:Connect(function()
        t[3] = not t[3]
        refreshAll()
    end)
end

-- Filter nilai: Min dan Max (Max inklusif)
local sVal = section(mainPage, "minimum maximum brainrot to sell nilai batas value min max", 13)
local valCard = Instance.new("Frame")
valCard.Size = UDim2.new(1, 0, 0, 0)
valCard.AutomaticSize = Enum.AutomaticSize.Y
valCard.BackgroundColor3 = C_ROW
valCard.LayoutOrder = 1
valCard.Parent = sVal
corner(valCard, 8)
local vl = Instance.new("UIListLayout", valCard)
vl.Padding = UDim.new(0, 4)
vl.SortOrder = Enum.SortOrder.LayoutOrder
local vpad = Instance.new("UIPadding", valCard)
vpad.PaddingLeft = UDim.new(0, 10)
vpad.PaddingRight = UDim.new(0, 10)
vpad.PaddingBottom = UDim.new(0, 8)

textBlock(valCard, "Min / Max Brainrot To Sell",
    "Hanya jual brainrot yang nilainya di antara Min dan Max (termasuk angkanya). Max kosong = filter nilai mati (jual per rarity). Bisa pakai k, m, b.",
    0, true)

local valRow = Instance.new("Frame")
valRow.Size = UDim2.new(1, 0, 0, 26)
valRow.BackgroundTransparency = 1
valRow.LayoutOrder = 2
valRow.Parent = valCard

local function valBox(placeholder, xScale, xOff)
    local b = Instance.new("TextBox")
    b.Size = UDim2.new(0.5, -3, 1, 0)
    b.Position = UDim2.new(xScale, xOff, 0, 0)
    b.BackgroundColor3 = C_BG
    b.PlaceholderText = placeholder
    b.PlaceholderColor3 = C_GRAY
    b.Text = ""
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.ClearTextOnFocus = false
    b.Parent = valRow
    corner(b, 6)
    return b
end
local minBox = valBox("Min  eg. 500k", 0, 0)
local maxBox = valBox("Max  eg. 2m", 0.5, 3)

local function applyRange()
    local mn, mx = parseValue(minBox.Text), parseValue(maxBox.Text)
    if mn == nil or mx == nil then
        State.SellMin, State.SellMax = 0, 0
        setStatus("Format salah. Contoh: 500k, 2m, 1b", C_WARN)
    elseif mx == 0 then
        State.SellMin, State.SellMax = 0, 0
        setStatus("Filter nilai OFF (jual per rarity)")
    elseif mn > mx then
        State.SellMin, State.SellMax = 0, 0
        setStatus("Min tidak boleh lebih besar dari Max", C_WARN)
    else
        State.SellMin, State.SellMax = mn, mx
        setStatus("Jual nilai " .. fmtNum(mn) .. " - " .. fmtNum(mx), C_GOOD)
    end
end
minBox.FocusLost:Connect(applyRange)
maxBox.FocusLost:Connect(applyRange)

-- ----- AUTO (urutan 20-22) -----
groupTitle(mainPage, "Auto", 20)
local sCol = section(mainPage, "auto collect cash", 21)
switchRow(sCol, "Auto Collect Cash",
    "Ambil uang otomatis tiap beberapa detik tanpa menekan tombol Collect.", "AutoCollect")

local sReb = section(mainPage, "auto rebirth", 22)
switchRow(sReb, "Auto Rebirth",
    "Rebirth otomatis kalau syaratnya sudah terpenuhi. Hati-hati: rebirth bisa mereset progres.",
    "AutoRebirth")

-- ----- STATUS (paling bawah) -----
local sStat = section(mainPage, "status", 99)
statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 18)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Siap."
statusLbl.TextColor3 = C_GRAY
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.TextWrapped = true
statusLbl.AutomaticSize = Enum.AutomaticSize.Y
statusLbl.LayoutOrder = 1
statusLbl.Parent = sStat

-- ===== HALAMAN MISC =====
groupTitle(miscPage, "ESP", 1)
local sEsp = section(miscPage, "esp player", 2)
switchRow(sEsp, "ESP Player",
    "Menampilkan nama, jarak, dan glow pemain lain yang tembus tembok.", "ESPPlayer")

-- ----- BID (urutan 1-4, paling atas di tab Main) -----
do
    groupTitle(mainPage, "Bid", 1)

    State.AutoBid = false
    State.BidOption = "Small"
    State.MaxBid = 0
    State.StopStreak = 0
    State.Streak = nil
    State.BidLast = nil

    -- Auto Bid (switch)
    local sBid = section(mainPage, "auto bid", 2)
    local rowB = Instance.new("TextButton")
    rowB.Size = UDim2.new(1, 0, 0, 0)
    rowB.AutomaticSize = Enum.AutomaticSize.Y
    rowB.BackgroundColor3 = C_ROW
    rowB.Text = ""
    rowB.AutoButtonColor = false
    rowB.LayoutOrder = 1
    rowB.Parent = sBid
    corner(rowB, 8)
    Instance.new("UISizeConstraint", rowB).MinSize = Vector2.new(0, 38)
    textBlock(rowB, "Auto Bid",
        "Cari meja yang sudah ada pemainnya (Quick Join) kalau belum duduk, lalu bid di giliranmu sesuai opsi di bawah.",
        -64, false)

    local pillB = Instance.new("Frame")
    pillB.Size = UDim2.new(0, 40, 0, 20)
    pillB.Position = UDim2.new(1, -50, 0.5, -10)
    pillB.Parent = rowB
    corner(pillB, 10)
    local knobB = Instance.new("Frame")
    knobB.Size = UDim2.new(0, 16, 0, 16)
    knobB.BackgroundColor3 = Color3.new(1, 1, 1)
    knobB.Parent = pillB
    corner(knobB, 8)

    local function refreshBidSwitch(animate)
        local on = State.AutoBid
        local col = on and C_ON or C_OFF
        local pos = on and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        if animate then
            local info = TweenInfo.new(0.15)
            TS:Create(pillB, info, { BackgroundColor3 = col }):Play()
            TS:Create(knobB, info, { Position = pos }):Play()
        else
            pillB.BackgroundColor3 = col
            knobB.Position = pos
        end
    end
    State.BidSetAuto = function(on)
        State.AutoBid = on
        refreshBidSwitch(true)
    end
    rowB.MouseButton1Click:Connect(function()
        State.BidSetAuto(not State.AutoBid)
        if State.AutoBid then setStatus("Auto Bid: menunggu giliran...") end
    end)
    refreshBidSwitch(false)

    -- Select Bid Options (dropdown, pilih salah satu)
    local OPTIONS = { "Small", "Medium", "High", "Extreme", "Pass" }
    local sOpt = section(mainPage, "select bid options small medium high extreme pass", 3)

    local optBtn = Instance.new("TextButton")
    optBtn.Size = UDim2.new(1, 0, 0, 0)
    optBtn.AutomaticSize = Enum.AutomaticSize.Y
    optBtn.BackgroundColor3 = C_ROW
    optBtn.Text = ""
    optBtn.AutoButtonColor = false
    optBtn.LayoutOrder = 1
    optBtn.Parent = sOpt
    corner(optBtn, 8)
    Instance.new("UISizeConstraint", optBtn).MinSize = Vector2.new(0, 38)
    local _, optTitle = textBlock(optBtn, "Select Bid Options",
        "Pilih salah satu. Pass = lewati giliran tanpa bid.", -40, false)

    local optArrow = Instance.new("TextLabel")
    optArrow.Size = UDim2.new(0, 24, 0, 20)
    optArrow.Position = UDim2.new(1, -30, 0.5, -10)
    optArrow.BackgroundTransparency = 1
    optArrow.TextColor3 = Color3.new(1, 1, 1)
    optArrow.Font = Enum.Font.GothamBold
    optArrow.TextSize = 14
    optArrow.Parent = optBtn

    local optList = Instance.new("Frame")
    optList.Size = UDim2.new(1, 0, 0, 0)
    optList.AutomaticSize = Enum.AutomaticSize.Y
    optList.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    optList.Visible = false
    optList.LayoutOrder = 2
    optList.Parent = sOpt
    corner(optList, 8)
    local oll = Instance.new("UIListLayout", optList)
    oll.Padding = UDim.new(0, 2)
    oll.SortOrder = Enum.SortOrder.LayoutOrder
    local olp = Instance.new("UIPadding", optList)
    olp.PaddingLeft = UDim.new(0, 6)
    olp.PaddingRight = UDim.new(0, 6)
    olp.PaddingTop = UDim.new(0, 6)
    olp.PaddingBottom = UDim.new(0, 6)

    local optRows, optOpen = {}, false
    local function refreshBidOpts()
        optTitle.Text = "Select Bid Options  (" .. State.BidOption .. ")"
        optArrow.Text = optOpen and "^" or ">"
        optList.Visible = optOpen
        for name, r in pairs(optRows) do
            local on = (name == State.BidOption)
            r.Text = (on and "✓  " or "    ") .. name
            r.TextColor3 = on and Color3.new(1, 1, 1) or C_GRAY
            r.BackgroundTransparency = on and 0 or 1
        end
    end
    for i, name in ipairs(OPTIONS) do
        local r = Instance.new("TextButton")
        r.Size = UDim2.new(1, 0, 0, 24)
        r.BackgroundColor3 = C_ROW
        r.BackgroundTransparency = 1
        r.Font = Enum.Font.GothamBold
        r.TextSize = 11
        r.TextXAlignment = Enum.TextXAlignment.Left
        r.LayoutOrder = i
        r.Parent = optList
        corner(r, 5)
        Instance.new("UIPadding", r).PaddingLeft = UDim.new(0, 8)
        optRows[name] = r
        r.MouseButton1Click:Connect(function()
            State.BidOption = name
            refreshBidOpts()
        end)
    end
    optBtn.MouseButton1Click:Connect(function()
        optOpen = not optOpen
        refreshBidOpts()
    end)
    table.insert(refreshers, refreshBidOpts)

    -- Stop At Streak / Max Bid
    local sLim = section(mainPage, "stop at streak max bid batas", 4)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C_ROW
    card.LayoutOrder = 1
    card.Parent = sLim
    corner(card, 8)
    local cl = Instance.new("UIListLayout", card)
    cl.Padding = UDim.new(0, 4)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    local cp = Instance.new("UIPadding", card)
    cp.PaddingLeft = UDim.new(0, 10)
    cp.PaddingRight = UDim.new(0, 10)
    cp.PaddingBottom = UDim.new(0, 8)

    textBlock(card, "Stop At Streak / Max Bid",
        "Auto Bid mati sendiri saat streak sudah sama atau lebih dari angka ini. Max Bid melewati giliran yang nominalnya lebih besar. Kosong = tidak dibatasi.",
        0, true)

    local limRow = Instance.new("Frame")
    limRow.Size = UDim2.new(1, 0, 0, 26)
    limRow.BackgroundTransparency = 1
    limRow.LayoutOrder = 2
    limRow.Parent = card

    local function limBox(placeholder, xScale, xOff)
        local b = Instance.new("TextBox")
        b.Size = UDim2.new(0.5, -3, 1, 0)
        b.Position = UDim2.new(xScale, xOff, 0, 0)
        b.BackgroundColor3 = C_BG
        b.PlaceholderText = placeholder
        b.PlaceholderColor3 = C_GRAY
        b.Text = ""
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.ClearTextOnFocus = false
        b.Parent = limRow
        corner(b, 6)
        return b
    end
    local streakBoxB = limBox("Streak  eg. 100", 0, 0)
    local maxBoxB = limBox("Max bid  eg. 5m", 0.5, 3)

    local streakLblB = Instance.new("TextLabel")
    streakLblB.Size = UDim2.new(1, 0, 0, 16)
    streakLblB.BackgroundTransparency = 1
    streakLblB.Text = "Streak: -"
    streakLblB.TextColor3 = C_GRAY
    streakLblB.Font = Enum.Font.GothamBold
    streakLblB.TextSize = 11
    streakLblB.TextXAlignment = Enum.TextXAlignment.Left
    streakLblB.LayoutOrder = 3
    streakLblB.Parent = card
    State.ShowStreak = function(n) streakLblB.Text = "Streak: " .. tostring(n) end

    streakBoxB.FocusLost:Connect(function()
        local v = parseValue(streakBoxB.Text)
        if v == nil then
            State.StopStreak = 0
            setStatus("Streak: format salah (contoh 100)", C_WARN)
        else
            State.StopStreak = v
            setStatus(v == 0 and "Stop streak: OFF" or ("Berhenti di streak " .. fmtNum(v)),
                v == 0 and C_GRAY or C_GOOD)
        end
    end)
    maxBoxB.FocusLost:Connect(function()
        local v = parseValue(maxBoxB.Text)
        if v == nil then
            State.MaxBid = 0
            setStatus("Max bid: format salah (contoh 5m)", C_WARN)
        else
            State.MaxBid = v
            setStatus(v == 0 and "Max bid: tanpa batas" or ("Max bid: " .. fmtNum(v)),
                v == 0 and C_GRAY or C_GOOD)
        end
    end)
end

refreshAll()
setTab("Main")

-- ===== LOGIKA JUAL =====
local selling = false

local function duelBlocked()
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and d.Text:lower():find("active duel") then
            return true
        end
    end
    return false
end

local function refreshInventory()
    local stamp = State.InvStamp
    pcall(function() RequestInventory:FireServer() end)
    for _ = 1, 30 do
        if State.InvStamp > stamp then return true end
        task.wait(0.1)
    end
    return State.InvStamp > stamp
end

-- Brainrot yang memenuhi syarat: rarity tercentang + nilai di antara Min dan Max + tanpa grade
local function getTargets()
    local result = {}
    local stat = { rarityOk = 0, valueOut = 0, graded = 0 }
    local seen = {}
    for _, it in pairs(State.Inventory) do
        if type(it) == "table" and it.id then
            local rname = tostring(it.rarity)
            seen[rname] = (seen[rname] or 0) + 1
            if tierOn(it.rarity) then
                stat.rarityOk += 1
                local graded = SKIP_GRADED and it.grade ~= nil and it.grade ~= "None"
                if graded then
                    stat.graded += 1
                elseif type(it.value) ~= "number" or it.value < State.SellMin
                    or it.value > State.SellMax then
                    stat.valueOut += 1
                else
                    result[#result + 1] = it
                end
            end
        end
    end
    table.sort(result, function(a, b) return a.value < b.value end)
    return result, stat, seen
end

-- Mode per rarity (Max kosong): SellAll, klik + konfirmasi
local function sellByTier()
    for _, t in ipairs(TIERS) do
        if not State.Running then return end
        if t[3] then
            setStatus("Jual " .. t[1] .. "...")
            for i = 1, FIRE_COUNT do
                pcall(function() SellAll:FireServer(t[1]) end)
                if i < FIRE_COUNT then task.wait(CONFIRM_DELAY) end
            end
            task.wait(0.5)
            if duelBlocked() then
                setStatus("Duel aktif, jeda " .. DUEL_PAUSE .. " detik", C_WARN)
                task.wait(DUEL_PAUSE)
                return
            end
            task.wait(TIER_DELAY)
        end
    end
    setStatus("Sell terakhir: " .. os.date("%H:%M:%S"), C_GOOD)
end

-- Mode filter nilai (Max diisi): SellItem satu per satu, klik + konfirmasi
local function sellFiltered()
    setStatus("Baca inventory...")
    if not refreshInventory() then
        setStatus("Inventory tidak terbaca.", C_WARN)
        return
    end
    local targets, stat, seen = getTargets()
    if #targets == 0 then
        local names = {}
        for k, n in pairs(seen) do names[#names + 1] = k .. "(" .. n .. ")" end
        table.sort(names)
        setStatus("Kosong. Cocok rarity: " .. stat.rarityOk
            .. ", di luar nilai: " .. stat.valueOut
            .. ", bergrade: " .. stat.graded
            .. " | Inventory: " .. table.concat(names, ", "), C_WARN)
        return
    end
    local total = math.min(#targets, MAX_PER_ROUND)
    for i = 1, total do
        if not State.Running then return end
        local it = targets[i]
        setStatus("Jual " .. i .. "/" .. total .. ": " .. tostring(it.name))
        for n = 1, ITEM_FIRE do
            pcall(function() SellItem:FireServer(it.id) end)
            if n < ITEM_FIRE then task.wait(ITEM_CONFIRM_DELAY) end
        end
        task.wait(ITEM_DELAY)
        if i == 1 then
            task.wait(0.3)
            if duelBlocked() then
                setStatus("Duel aktif, jeda " .. DUEL_PAUSE .. " detik", C_WARN)
                task.wait(DUEL_PAUSE)
                return
            end
        end
    end
    setStatus("Terjual " .. total .. " item, " .. os.date("%H:%M:%S"), C_GOOD)
end

local function sellSelected()
    if selling then return end
    if countSelected() == 0 then
        setStatus("Pilih rarity dulu.", C_WARN)
        return
    end
    selling = true
    if State.SellMax > 0 then sellFiltered() else sellByTier() end
    selling = false
end

-- ===== LOOP (terpisah) =====
task.spawn(function() -- auto sell
    local t = SELL_INTERVAL
    while State.Running do
        task.wait(1)
        if State.AutoSell then
            t += 1
            if t >= SELL_INTERVAL then
                sellSelected()
                t = 0
            end
        else
            t = SELL_INTERVAL
        end
    end
end)

task.spawn(function() -- auto collect
    local t = COLLECT_INTERVAL
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

task.spawn(function() -- auto rebirth
    local t = REBIRTH_INTERVAL
    local warned = false
    while State.Running do
        task.wait(1)
        if State.AutoRebirth then
            if not RebirthRemote then
                if not warned then
                    setStatus("Auto Rebirth: remote tidak ketemu", C_WARN)
                    warned = true
                end
            else
                t += 1
                if t >= REBIRTH_INTERVAL then
                    pcall(function() RebirthRemote:FireServer() end)
                    t = 0
                end
            end
        else
            t = REBIRTH_INTERVAL
            warned = false
        end
    end
end)

-- ===== ESP PLAYER (nama + jarak + glow) =====
local espHolder = Instance.new("Folder")
espHolder.Name = "BrainrotESP"
espHolder.Parent = gui.Parent

local tags, glows = {}, {}

local function clearEsp()
    for p, bb in pairs(tags) do
        if bb then bb:Destroy() end
        tags[p] = nil
    end
    for p, h in pairs(glows) do
        if h then h:Destroy() end
        glows[p] = nil
    end
end

local function makeTag(head)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESPTag"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 140, 0, 24)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = espHolder

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.Text = ""
    lbl.Parent = bb
    return bb
end

local function makeGlow(char)
    local h = Instance.new("Highlight")
    h.Name = "ESPGlow"
    h.Adornee = char
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = Color3.fromRGB(255, 80, 80)
    h.FillTransparency = 0.65
    h.OutlineColor = Color3.new(1, 1, 1)
    h.OutlineTransparency = 0
    h.Parent = espHolder
    return h
end

Players.PlayerRemoving:Connect(function(plr)
    if tags[plr] then tags[plr]:Destroy() tags[plr] = nil end
    if glows[plr] then glows[plr]:Destroy() glows[plr] = nil end
end)

task.spawn(function()
    while State.Running do
        task.wait(0.4)
        if State.ESPPlayer then
            local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp then
                    local char = plr.Character
                    local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
                    local tag = tags[plr]
                    if head and (not tag or tag.Adornee ~= head or not tag.Parent) then
                        if tag then tag:Destroy() end
                        tag = makeTag(head)
                        tags[plr] = tag
                    end
                    local glow = glows[plr]
                    if char and (not glow or glow.Adornee ~= char or not glow.Parent) then
                        if glow then glow:Destroy() end
                        glows[plr] = makeGlow(char)
                    end
                    if tag then
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local dist = (myRoot and root) and math.floor((myRoot.Position - root.Position).Magnitude) or 0
                        local lbl = tag:FindFirstChild("Label")
                        if lbl then lbl.Text = plr.DisplayName .. "  [" .. dist .. "m]" end
                    end
                end
            end
        else
            clearEsp()
        end
    end
    clearEsp()
    espHolder:Destroy()
end)

-- ===== LOGIKA AUTO BID =====
do
    local PASS_ACTION = "pass"

    local TablesFolder = Ev.Parent:WaitForChild("Tables", 10)
    local BidSubmitted = TablesFolder and TablesFolder:WaitForChild("BidSubmitted", 10)
    local AuctionPrompt = TablesFolder and TablesFolder:WaitForChild("AuctionPrompt", 10)
    local StreakUpdated = Ev:FindFirstChild("StreakUpdated")

    if not (BidSubmitted and AuctionPrompt) then
        warn("[BidForBrainrot] Remote lelang tidak ketemu, Auto Bid tidak aktif")
    else
        local function stopIfReached()
            if State.AutoBid and State.StopStreak > 0 and State.Streak
                and State.Streak >= State.StopStreak then
                State.BidSetAuto(false)
                setStatus("Auto Bid berhenti: streak " .. State.Streak
                    .. " mencapai " .. State.StopStreak, C_GOOD)
                return true
            end
            return false
        end

        if StreakUpdated then
            StreakUpdated.OnClientEvent:Connect(function(n)
                if type(n) == "number" then
                    State.Streak = n
                    if State.ShowStreak then State.ShowStreak(n) end
                    stopIfReached()
                end
            end)
        end

        AuctionPrompt.OnClientEvent:Connect(function(p)
            if not State.AutoBid or not State.Running then return end
            if type(p) ~= "table" or not p.active then return end   -- active = giliranmu
            if p.promptId == nil or p.auctionId == nil then return end

            local key = tostring(p.auctionId) .. ":" .. tostring(p.promptId)
            if State.BidLast == key then return end
            State.BidLast = key

            task.spawn(function()
                task.wait(0.8 + math.random() * 0.7)
                if not State.AutoBid or not State.Running then return end
                if stopIfReached() then return end

                if State.BidOption == "Pass" then
                    if p.canPass then
                        pcall(function()
                            BidSubmitted:FireServer({
                                promptId = p.promptId,
                                action = PASS_ACTION,
                                auctionId = p.auctionId,
                            })
                        end)
                        setStatus("Pass (" .. os.date("%H:%M:%S") .. ")", C_GOOD)
                    else
                        setStatus("Giliran ini tidak bisa di-pass", C_WARN)
                    end
                    return
                end

                local pick
                for _, o in pairs(p.options or {}) do
                    if type(o) == "table" and tostring(o.label) == State.BidOption then
                        pick = o
                        break
                    end
                end
                if not pick then
                    setStatus("Opsi " .. State.BidOption .. " tidak ada di giliran ini", C_WARN)
                    return
                end
                if pick.canAfford == false then
                    setStatus("Uang tidak cukup untuk " .. State.BidOption, C_WARN)
                    return
                end
                if State.MaxBid > 0 and pick.amount > State.MaxBid then
                    setStatus("Dilewati: " .. fmtNum(pick.amount)
                        .. " di atas batas " .. fmtNum(State.MaxBid), C_WARN)
                    return
                end

                pcall(function()
                    BidSubmitted:FireServer({
                        promptId = p.promptId,
                        action = "bid",
                        auctionId = p.auctionId,
                        amount = pick.amount,
                    })
                end)
                setStatus("Bid " .. State.BidOption .. " " .. fmtNum(pick.amount)
                    .. " (" .. os.date("%H:%M:%S") .. ")", C_GOOD)
            end)
        end)
    end
end

-- ===== AUTO BID: MASUK MEJA OTOMATIS (QuickJoin + cadangan EnterRequest) =====
do
    local JOIN_IDLE = 20           -- detik tanpa aktivitas lelang sebelum coba QuickJoin
    local JOIN_COOLDOWN = 15       -- detik antar percobaan QuickJoin
    local FALLBACK_ENABLED = true  -- false = matikan cadangan duduk lewat EnterRequest
    local FALLBACK_IDLE = 35       -- detik tanpa aktivitas lelang sebelum cadangan jalan
    local FALLBACK_COOLDOWN = 45   -- detik antar putaran cadangan
    local CHAIRS = { "Chair1" }    -- tambah "Chair2" kalau memang ada

    local TablesFolder = Ev.Parent:WaitForChild("Tables", 10)
    local AuctionPrompt = TablesFolder and TablesFolder:WaitForChild("AuctionPrompt", 10)
    local AuctionState = TablesFolder and TablesFolder:FindFirstChild("AuctionStateUpdated")
    local EnterRequest = TablesFolder and TablesFolder:FindFirstChild("EnterRequest")
    local QuickJoin = Ev:FindFirstChild("QuickJoin")

    if not (AuctionPrompt and (QuickJoin or EnterRequest)) then
        warn("[BidForBrainrot] Remote masuk meja tidak ketemu, masuk meja otomatis tidak aktif")
    else
        State.BidSeen = os.clock()

        -- Tandai kapan terakhir kamu terlihat ikut lelang
        AuctionPrompt.OnClientEvent:Connect(function()
            State.BidSeen = os.clock()
        end)
        if AuctionState then
            AuctionState.OnClientEvent:Connect(function(s)
                if type(s) == "table" and type(s.participants) == "table" then
                    for _, pt in pairs(s.participants) do
                        if type(pt) == "table" and pt.userId == lp.UserId then
                            State.BidSeen = os.clock()
                            return
                        end
                    end
                end
            end)
        end

        local function seated()
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            return hum ~= nil and hum.SeatPart ~= nil
        end

        local function joined()
            return seated() or (os.clock() - State.BidSeen) < 5
        end

        local function findTables()
            local result, seen = {}, {}
            for _, d in ipairs(workspace:GetDescendants()) do
                if d.Name:match("^Table%d+$") and not seen[d.Name] then
                    seen[d.Name] = true
                    result[#result + 1] = d.Name
                end
            end
            if #result == 0 then result = { "Table5", "Table7", "Table9", "Table11" } end
            table.sort(result, function(a, b)
                return tonumber(a:match("%d+")) < tonumber(b:match("%d+"))
            end)
            return result
        end

        if QuickJoin then
            task.spawn(function()
                local lastTry = 0
                while State.Running do
                    task.wait(2)
                    if State.AutoBid then
                        local now = os.clock()
                        if now - State.BidSeen > JOIN_IDLE
                            and now - lastTry > JOIN_COOLDOWN
                            and not seated() then
                            lastTry = now
                            pcall(function() QuickJoin:FireServer() end)
                            setStatus("Auto Bid: masuk meja (Quick Join)...", C_GRAY)
                        end
                    end
                end
            end)
        end

        if FALLBACK_ENABLED and EnterRequest then
            task.spawn(function()
                local last = 0
                while State.Running do
                    task.wait(2)
                    local now = os.clock()
                    if State.AutoBid and not joined()
                        and now - State.BidSeen > FALLBACK_IDLE
                        and now - last > FALLBACK_COOLDOWN then
                        last = now
                        for _, tname in ipairs(findTables()) do
                            if not State.AutoBid or not State.Running or joined() then break end
                            for _, chair in ipairs(CHAIRS) do
                                pcall(function() EnterRequest:FireServer(tname, chair, true) end)
                                setStatus("Auto Bid: coba duduk di " .. tname .. " " .. chair)
                                task.wait(2)
                                if joined() then break end
                            end
                        end
                    end
                end
            end)
        end
    end
end
