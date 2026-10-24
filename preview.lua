-- PREVIEW UI v5: BID FOR BRAINROT V1 (tampilan saja, belum terhubung ke logika)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

if getgenv().PreviewUI then pcall(function() getgenv().PreviewUI:Destroy() end) end

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_ON   = Color3.fromRGB(60, 190, 100)
local C_ACC  = Color3.fromRGB(220, 130, 30)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local State = {
    AutoSell = false, AutoCollect = false, AutoRebirth = false,
    ESPPlayer = false,
    SellMin = 0, SellMax = 0,   -- SellMax = 0 berarti filter nilai mati
}
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

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "PreviewUI"
gui.ResetOnSpawn = false
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
getgenv().PreviewUI = gui

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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -220, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "BID FOR BRAINROT V1"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = bar

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
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

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

-- Tab dengan ikon (emoji). Ganti ikon di parameter ketiga kalau mau.
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

-- Bagian yang bisa dicari lewat kolom Search
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
    if statusLbl then
        statusLbl.Text = t
        statusLbl.TextColor3 = color or C_GRAY
    end
end

-- Judul + penjelasan kecil. inList=true: dipakai di dalam kartu ber-UIListLayout
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

-- Baris switch dengan penjelasan
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

-- ===== HALAMAN MAIN =====
groupTitle(mainPage, "Sell", 1)

-- Auto Sell
local sAuto = section(mainPage, "auto sell", 2)
switchRow(sAuto, "Auto Sell",
    "Jual brainrot otomatis tiap beberapa detik, hanya rarity yang kamu pilih di bawah.", "AutoSell")

-- Rarity To Sell (dropdown daftar vertikal, bisa discroll)
local sRar = section(mainPage,
    "rarity to sell all common uncommon rare epic legendary mythic cosmic secret celestial divine brainrot god", 3)

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

-- Filter nilai: Min dan Max (mendukung k, m, b)
local sVal = section(mainPage, "minimum maximum brainrot to sell nilai batas value min max", 4)
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
    "Hanya jual brainrot yang nilainya di antara Min dan Max. Max kosong = filter nilai mati (jual per rarity). Bisa pakai k, m, b.",
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
    elseif mn >= mx then
        State.SellMin, State.SellMax = 0, 0
        setStatus("Min harus lebih kecil dari Max", C_WARN)
    else
        State.SellMin, State.SellMax = mn, mx
        setStatus("Jual nilai " .. fmtNum(mn) .. " - " .. fmtNum(mx), C_GOOD)
    end
end
minBox.FocusLost:Connect(applyRange)
maxBox.FocusLost:Connect(applyRange)

-- Tombol Cek / Sell Sekarang
local sBtn = section(mainPage, "cek sell sekarang", 5)
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, 0, 0, 28)
btnRow.BackgroundTransparency = 1
btnRow.LayoutOrder = 1
btnRow.Parent = sBtn

local function rowBtn(text, color, xScale, xOff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -3, 1, 0)
    b.Position = UDim2.new(xScale, xOff, 0, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Parent = btnRow
    corner(b, 8)
    return b
end
local checkBtn = rowBtn("Cek (tanpa jual)", Color3.fromRGB(60, 110, 200), 0, 0)
local sellNow = rowBtn("Sell Sekarang", C_ACC, 0.5, 3)
checkBtn.MouseButton1Click:Connect(function() setStatus("Preview: Cek belum terhubung", C_WARN) end)
sellNow.MouseButton1Click:Connect(function() setStatus("P
