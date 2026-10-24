
-- PREVIEW UI v3: BID FOR BRAINROT V1 (gaya sidebar + switch, tampilan saja)
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

local State = { AutoSell = false, AutoCollect = false, SellBelow = 0 }
local TIERS = {
    { "Common",      Color3.fromRGB(200, 200, 200), false },
    { "Uncommon",    Color3.fromRGB(60, 180, 60),   false },
    { "Rare",        Color3.fromRGB(50, 130, 255),  false },
    { "Epic",        Color3.fromRGB(170, 60, 230),  false },
    { "Legendary",   Color3.fromRGB(230, 200, 40),  false },
    { "Mythic",      Color3.fromRGB(255, 120, 60),  false },
    { "Cosmic",      Color3.fromRGB(40, 150, 255),  false },
    { "Secret",      Color3.fromRGB(230, 40, 140),  false },
    { "Celestial",   Color3.fromRGB(190, 90, 255),  false },
    { "Divine",      Color3.fromRGB(255, 170, 220), false },
    { "Brainrot God", Color3.fromRGB(255, 80, 80),  false },
}

local function fmtNum(n)
    if n >= 1e9 then return string.format("%.3gB", n / 1e9) end
    if n >= 1e6 then return string.format("%.3gM", n / 1e6) end
    if n >= 1e3 then return string.format("%.3gK", n / 1e3) end
    return tostring(math.floor(n))
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

local WIN_W, WIN_H = 420, 260
local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
main.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
main.BackgroundColor3 = C_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 12)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(60, 60, 72)

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

-- Drag lewat title bar
do
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
tabList.Size = UDim2.new(1, 0, 1, -56)
tabList.BackgroundTransparency = 1
tabList.Parent = sidebar
local tl = Instance.new("UIListLayout", tabList)
tl.Padding = UDim.new(0, 4)
local tp = Instance.new("UIPadding", tabList)
tp.PaddingTop = UDim.new(0, 8)
tp.PaddingLeft = UDim.new(0, 6)
tp.PaddingRight = UDim.new(0, 6)

-- Profil + FPS
local prof = Instance.new("TextLabel")
prof.Size = UDim2.new(1, -12, 0, 28)
prof.Position = UDim2.new(0, 6, 1, -52)
prof.BackgroundTransparency = 1
prof.Text = "Welcome, " .. lp.DisplayName
prof.TextColor3 = C_GRAY
prof.Font = Enum.Font.Gotham
prof.TextSize = 10
prof.TextWrapped = true
prof.TextXAlignment = Enum.TextXAlignment.Left
prof.TextYAlignment = Enum.TextYAlignment.Top
prof.Parent = sidebar

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

-- Halaman
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

local function newTab(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = tabList
    corner(b, 8)
    tabs[name] = b
    b.MouseButton1Click:Connect(function() setTab(name) end)
end

local mainPage = newPage("Main")
local miscPage = newPage("Misc")
newTab("Main")
newTab("Misc")

-- Bagian (container) yang bisa dicari
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

local refreshers = {}
local function refreshAll() for _, f in ipairs(refreshers) do f() end end

-- Baris switch
local function switchRow(parent, text, desc, key)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, desc and 46 or 36)
    row.BackgroundColor3 = C_ROW
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = 1
    row.Parent = parent
    corner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, desc and 6 or 9)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -70, 0, 14)
        d.Position = UDim2.new(0, 10, 0, 24)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C_GRAY
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = row
    end

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
-- 1) Auto Sell
local sAuto = section(mainPage, "auto sell", 1)
switchRow(sAuto, "Auto Sell", "Jual otomatis brainrot sesuai rarity", "AutoSell")

-- 2) Rarity To Sell (dropdown)
local sRar = section(mainPage, "rarity to sell all common uncommon rare epic legendary mythic cosmic secret celestial divine brainrot god", 2)

local rarBtn = Instance.new("TextButton")
rarBtn.Size = UDim2.new(1, 0, 0, 36)
rarBtn.BackgroundColor3 = C_ROW
rarBtn.Text = ""
rarBtn.AutoButtonColor = false
rarBtn.LayoutOrder = 1
rarBtn.Parent = sRar
corner(rarBtn, 8)

local rarLbl = Instance.new("TextLabel")
rarLbl.Size = UDim2.new(1, -40, 1, 0)
rarLbl.Position = UDim2.new(0, 10, 0, 0)
rarLbl.BackgroundTransparency = 1
rarLbl.TextColor3 = Color3.new(1, 1, 1)
rarLbl.Font = Enum.Font.GothamBold
rarLbl.TextSize = 12
rarLbl.TextXAlignment = Enum.TextXAlignment.Left
rarLbl.Parent = rarBtn

local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.new(0, 24, 1, 0)
arrow.Position = UDim2.new(1, -30, 0, 0)
arrow.BackgroundTransparency = 1
arrow.TextColor3 = Color3.new(1, 1, 1)
arrow.Font = Enum.Font.GothamBold
arrow.TextSize = 14
arrow.Parent = rarBtn

local panel = Instance.new("Frame")
panel.Size = UDim2.new(1, 0, 0, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
panel.Visible = false
panel.LayoutOrder = 2
panel.Parent = sRar
corner(panel, 8)
local pp = Instance.new("UIPadding", panel)
pp.PaddingLeft = UDim.new(0, 8)
pp.PaddingRight = UDim.new(0, 8)
pp.PaddingTop = UDim.new(0, 8)
pp.PaddingBottom = UDim.new(0, 8)

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, 0, 0, 0)
grid.AutomaticSize = Enum.AutomaticSize.Y
grid.BackgroundTransparency = 1
grid.Parent = panel
local gl = Instance.new("UIGridLayout", grid)
gl.SortOrder = Enum.SortOrder.LayoutOrder
gl.CellSize = UDim2.new(0.5, -3, 0, 28)
gl.CellPadding = UDim2.new(0, 6, 0, 5)

local expanded = false
local function updateRar()
    local n = countSelected()
    rarLbl.Text = "Rarity To Sell" .. (n > 0 and ("  (" .. n .. ")") or "")
    arrow.Text = expanded and "^" or ">"
    panel.Visible = expanded
end
rarBtn.MouseButton1Click:Connect(function()
    expanded = not expanded
    updateRar()
end)
table.insert(refreshers, updateRar)

local function optBtn(order)
    local b = Instance.new("TextButton")
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.LayoutOrder = order
    b.Parent = grid
    corner(b, 6)
    return b
end

local allBtn = optBtn(0)
table.insert(refreshers, function()
    if allSelected() then
        allBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        allBtn.TextColor3 = Color3.new(0, 0, 0)
        allBtn.Text = "✓ All"
    else
        allBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
        allBtn.TextColor3 = C_GRAY
        allBtn.Text = "All"
    end
end)
allBtn.MouseButton1Click:Connect(function()
    local s = not allSelected()
    for _, t in ipairs(TIERS) do t[3] = s end
    refreshAll()
end)

for idx, t in ipairs(TIERS) do
    local b = optBtn(idx)
    table.insert(refreshers, function()
        if t[3] then
            b.BackgroundColor3 = t[2]
            b.TextColor3 = Color3.new(0, 0, 0)
            b.Text = "✓ " .. t[1]
        else
            b.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
            b.TextColor3 = C_GRAY
            b.Text = t[1]
        end
    end)
    b.MouseButton1Click:Connect(function()
        t[3] = not t[3]
        refreshAll()
    end)
end

-- 3) Batas nilai (slider)
local sVal = section(mainPage, "batas nilai sell value limit slider", 3)
local MIN_FLOOR, MIN_CEIL = 1e3, 1e10

local valRow = Instance.new("Frame")
valRow.Size = UDim2.new(1, 0, 0, 52)
valRow.BackgroundColor3 = C_ROW
valRow.LayoutOrder = 1
valRow.Parent = sVal
corner(valRow, 8)

local valLbl = Instance.new("TextLabel")
valLbl.Size = UDim2.new(1, -20, 0, 18)
valLbl.Position = UDim2.new(0, 10, 0, 6)
valLbl.BackgroundTransparency = 1
valLbl.TextColor3 = Color3.new(1, 1, 1)
valLbl.Font = Enum.Font.GothamBold
valLbl.TextSize = 12
valLbl.TextXAlignment = Enum.TextXAlignment.Left
valLbl.Parent = valRow

local track = Instance.new("Frame")
track.Size = UDim2.new(1, -28, 0, 6)
track.Position = UDim2.new(0, 14, 0, 36)
track.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
track.BorderSizePixel = 0
track.Parent = valRow
corner(track, 3)

local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = C_ACC
fill.BorderSizePixel = 0
fill.Parent = track
corner(fill, 3)

local sknob = Instance.new("TextButton")
sknob.Size = UDim2.new(0, 18, 0, 18)
sknob.AnchorPoint = Vector2.new(0.5, 0.5)
sknob.Position = UDim2.new(0, 0, 0.5, 0)
sknob.BackgroundColor3 = Color3.new(1, 1, 1)
sknob.Text = ""
sknob.Parent = track
corner(sknob, 9)

local function setSlider(p)
    p = math.clamp(p, 0, 1)
    sknob.Position = UDim2.new(p, 0, 0.5, 0)
    fill.Size = UDim2.new(p, 0, 1, 0)
    if p < 0.01 then
        State.SellBelow = 0
        valLbl.Text = "Batas nilai: OFF (jual per tier)"
    else
        local raw = MIN_FLOOR * (MIN_CEIL / MIN_FLOOR) ^ p
        local mag = 10 ^ (math.floor(math.log10(raw)) - 1)
        State.SellBelow = math.floor(raw / mag + 0.5) * mag
        valLbl.Text = "Jual yg nilainya < [" .. fmtNum(State.SellBelow) .. " / " .. fmtNum(MIN_CEIL) .. "]"
    end
end
do
    local dragging, dragInput = false, nil
    local function fromX(x) setSlider((x - track.AbsolutePosition.X) / track.AbsoluteSize.X) end
    local function begin(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragInput = true, i
            fromX(i.Position.X)
        end
    end
    sknob.InputBegan:Connect(begin)
    track.InputBegan:Connect(begin)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            fromX(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end)
end
setSlider(0)

-- 4) Tombol Cek / Sell Sekarang
local sBtn = section(mainPage, "cek sell sekarang", 4)
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, 0, 0, 32)
btnRow.BackgroundTransparency = 1
btnRow.LayoutOrder = 1
btnRow.Parent = sBtn

local statusLbl
local function setStatus(t, color)
    if statusLbl then
        statusLbl.Text = t
        statusLbl.TextColor3 = color or C_GRAY
    end
end

local function rowBtn(text, color, xScale, xOff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.5, -3, 1, 0)
    b.Position = UDim2.new(xScale, xOff, 0, 0)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Parent = btnRow
    corner(b, 8)
    return b
end
local checkBtn = rowBtn("Cek (tanpa jual)", Color3.fromRGB(60, 110, 200), 0, 0)
local sellNow = rowBtn("Sell Sekarang", C_ACC, 0.5, 3)
checkBtn.MouseButton1Click:Connect(function() setStatus("Preview: Cek belum terhubung", C_WARN) end)
sellNow.MouseButton1Click:Connect(function() setStatus("Preview: Sell belum terhubung", C_WARN) end)

-- 5) Auto Collect Cash
local sCol = section(mainPage, "auto collect cash", 5)
switchRow(sCol, "Auto Collect Cash", nil, "AutoCollect")

-- 6) Status
local sStat = section(mainPage, "status", 6)
statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 18)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Siap. (preview)"
statusLbl.TextColor3 = C_GRAY
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.LayoutOrder = 1
statusLbl.Parent = sStat

-- ===== HALAMAN MISC =====
local sMisc = section(miscPage, "misc", 1)
local miscLbl = Instance.new("TextLabel")
miscLbl.Size = UDim2.new(1, 0, 0, 30)
miscLbl.BackgroundTransparency = 1
miscLbl.Text = "Belum ada fitur di sini."
miscLbl.TextColor3 = C_GRAY
miscLbl.Font = Enum.Font.Gotham
miscLbl.TextSize = 11
miscLbl.TextXAlignment = Enum.TextXAlignment.Left
miscLbl.Parent = sMisc

refreshAll()
setTab("Main")
