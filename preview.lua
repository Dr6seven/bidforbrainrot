-- PREVIEW UI v8: BID FOR BRAINROT V1 (By D33RZN)
-- Tampilan saja. Tidak memanggil remote game, jadi aman dijalankan buat ngecek bentuk UI.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

if getgenv().PreviewUI then pcall(function() getgenv().PreviewUI:Destroy() end) end

-- Ikon minimize: upload icon.png ke repo GitHub yang sama (folder paling atas)
local ICON_URL = "https://raw.githubusercontent.com/Dr6seven/bidforbrainrot/refs/heads/main/icon.png"
local ICON_FILE = "bfb_icon.png"

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_ON   = Color3.fromRGB(60, 190, 100)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local State = {
    AutoSell = false, AutoCollect = false, AutoRebirth = false, ESPPlayer = false,
    AutoBid = false, AutoGrade = false,
    BidOption = "Small", GradeTarget = nil,
    SellMin = 0, SellMax = 0, StopStreak = 0,
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
local GTIERS = {}
for i, t in ipairs(TIERS) do GTIERS[i] = { t[1], t[2], false } end

-- Grade untuk preview (di script asli dibaca dari BrainrotGradeConfig)
local GRADE_LIST = { { "C", 1 }, { "C+", 1.15 }, { "B", 1.25 }, { "A", 1.75 } }

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

-- Konfirmasi tutup: "Do you want to close this window" -> No / Yes
local dlg = Instance.new("Frame")
dlg.Size = UDim2.new(1, 0, 1, 0)
dlg.BackgroundColor3 = Color3.new(0, 0, 0)
dlg.BackgroundTransparency = 0.45
dlg.BorderSizePixel = 0
dlg.Active = true
dlg.Visible = false
dlg.ZIndex = 50
dlg.Parent = main

local dbox = Instance.new("Frame")
dbox.Size = UDim2.new(0, 270, 0, 110)
dbox.AnchorPoint = Vector2.new(0.5, 0.5)
dbox.Position = UDim2.new(0.5, 0, 0.5, 0)
dbox.BackgroundColor3 = C_ROW
dbox.BorderSizePixel = 0
dbox.ZIndex = 51
dbox.Parent = dlg
corner(dbox, 10)
Instance.new("UIStroke", dbox).Color = Color3.fromRGB(70, 70, 85)

local dtxt = Instance.new("TextLabel")
dtxt.Size = UDim2.new(1, -20, 0, 50)
dtxt.Position = UDim2.new(0, 10, 0, 10)
dtxt.BackgroundTransparency = 1
dtxt.Text = "Do you want to close this window"
dtxt.TextColor3 = Color3.new(1, 1, 1)
dtxt.Font = Enum.Font.GothamBold
dtxt.TextSize = 13
dtxt.TextWrapped = true
dtxt.ZIndex = 52
dtxt.Parent = dbox

local function dlgBtn(text, xScale, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 105, 0, 30)
    b.Position = UDim2.new(xScale, xOff, 1, -42)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.ZIndex = 52
    b.Parent = dbox
    corner(b, 8)
    return b
end
local noBtn = dlgBtn("No", 0, 20, Color3.fromRGB(70, 70, 82))
local yesBtn = dlgBtn("Yes", 1, -125, Color3.fromRGB(200, 50, 50))

closeBtn.MouseButton1Click:Connect(function() dlg.Visible = true end)
noBtn.MouseButton1Click:Connect(function() dlg.Visible = false end)
yesBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

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

-- ===== IKON MINIMIZE (gambar dari icon.png, cadangan huruf "D") =====
local mini = Instance.new("ImageButton")
mini.Size = UDim2.new(0, 46, 0, 46)
mini.BackgroundColor3 = C_BAR
mini.AutoButtonColor = false
mini.Image = ""
mini.ScaleType = Enum.ScaleType.Crop
mini.Visible = false
mini.Parent = gui
corner(mini, 12)
Instance.new("UIStroke", mini).Color = Color3.fromRGB(220, 130, 30)

local miniLetter = Instance.new("TextLabel")
miniLetter.Size = UDim2.new(1, 0, 1, 0)
miniLetter.BackgroundTransparency = 1
miniLetter.Text = "D"
miniLetter.TextColor3 = Color3.new(1, 1, 1)
miniLetter.Font = Enum.Font.GothamBold
miniLetter.TextSize = 22
miniLetter.Parent = mini

-- Unduh gambar sekali, simpan sebagai file lokal, lalu pasang ke ikon
task.spawn(function()
    local okIcon, asset = pcall(function()
        local getAsset = getcustomasset or getsynasset
        if not (writefile and getAsset) then error("executor tidak mendukung writefile/getcustomasset") end
        local data = game:HttpGet(ICON_URL)
        writefile(ICON_FILE, data)
        return getAsset(ICON_FILE)
    end)
    if okIcon and asset and mini.Parent then
        mini.Image = asset
        miniLetter.Visible = false
    end
end)

minBtn.MouseButton1Click:Connect(function()
    mini.Position = main.Position
    main.Visible = false
    mini.Visible = true
end)

do -- ikon bisa digeser; tap (tanpa geser) untuk membuka jendela lagi
    local dragging, moved, startPoint, startPos, dragInput
    mini.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragInput = true, false, i
            startPoint, startPos = i.Position, mini.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            if d.Magnitude > 8 then moved = true end
            if moved then
                mini.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if dragging and i == dragInput then
            dragging = false
            if not moved then
                main.Position = mini.Position
                mini.Visible = false
                main.Visible = true
            end
        end
    end)
end

-- ===== BODY: SIDEBAR + HALAMAN =====
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -32)
body.Position = UDim2.new(0, 0, 0, 32)
body.BackgroundTransparency = 1
body.Parent = main

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
        setStatus("Preview: belum terhubung ke game", C_WARN)
    end)
    refresh(false)
end

-- Dropdown serbaguna.
-- opts.items = { {key=, label=, color=} }, opts.hasAll, opts.scroll,
-- opts.isOn(key), opts.pick(key), opts.allOn(), opts.setAll(v), opts.summary()
local function makeDropdown(page, order, keyword, titleText, desc, opts)
    local sec = section(page, keyword, order)

    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 0)
    head.AutomaticSize = Enum.AutomaticSize.Y
    head.BackgroundColor3 = C_ROW
    head.Text = ""
    head.AutoButtonColor = false
    head.LayoutOrder = 1
    head.Parent = sec
    corner(head, 8)
    Instance.new("UISizeConstraint", head).MinSize = Vector2.new(0, 38)
    local _, titleLbl = textBlock(head, titleText, desc, -40, false)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 0, 20)
    arrow.Position = UDim2.new(1, -30, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.TextColor3 = Color3.new(1, 1, 1)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.Parent = head

    local list
    if opts.scroll then
        list = Instance.new("ScrollingFrame")
        list.Size = UDim2.new(1, 0, 0, 130)
        list.BorderSizePixel = 0
        list.ScrollBarThickness = 3
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        list.CanvasSize = UDim2.new(0, 0, 0, 0)
    else
        list = Instance.new("Frame")
        list.Size = UDim2.new(1, 0, 0, 0)
        list.AutomaticSize = Enum.AutomaticSize.Y
    end
    list.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    list.Visible = false
    list.LayoutOrder = 2
    list.Parent = sec
    corner(list, 8)
    local ll = Instance.new("UIListLayout", list)
    ll.Padding = UDim.new(0, 2)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    local lp2 = Instance.new("UIPadding", list)
    lp2.PaddingLeft = UDim.new(0, 6)
    lp2.PaddingRight = UDim.new(0, 8)
    lp2.PaddingTop = UDim.new(0, 6)
    lp2.PaddingBottom = UDim.new(0, 6)

    local rowsUI, open = {}, false

    local function addRow(rowOrder, key, label, color, isAll)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 22)
        b.BackgroundColor3 = C_ROW
        b.BackgroundTransparency = 1
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.LayoutOrder = rowOrder
        b.Parent = list
        corner(b, 5)
        Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
        b.MouseButton1Click:Connect(function()
            if isAll then opts.setAll(not opts.allOn()) else opts.pick(key) end
            refreshAll()
        end)
        rowsUI[#rowsUI + 1] = { btn = b, key = key, label = label, color = color, isAll = isAll }
    end
    if opts.hasAll then addRow(0, nil, "All", nil, true) end
    for i, it in ipairs(opts.items) do addRow(i, it.key, it.label, it.color, false) end

    local function refresh()
        titleLbl.Text = titleText .. opts.summary()
        arrow.Text = open and "^" or ">"
        list.Visible = open
        for _, r in ipairs(rowsUI) do
            local on
            if r.isAll then on = opts.allOn() else on = opts.isOn(r.key) end
            r.btn.Text = (on and "✓  " or "    ") .. r.label
            r.btn.TextColor3 = on and (r.color or Color3.new(1, 1, 1)) or C_GRAY
            r.btn.BackgroundTransparency = on and 0 or 1
        end
    end
    head.MouseButton1Click:Connect(function()
        open = not open
        refresh()
    end)
    table.insert(refreshers, refresh)
end

-- Dropdown rarity (pilih banyak) dari daftar tier
local function rarityDropdown(order, keyword, titleText, desc, list)
    local items = {}
    for i, t in ipairs(list) do items[i] = { key = i, label = t[1], color = t[2] } end
    makeDropdown(mainPage, order, keyword, titleText, desc, {
        items = items, hasAll = true, scroll = true,
        isOn = function(k) return list[k][3] end,
        pick = function(k) list[k][3] = not list[k][3] end,
        allOn = function()
            for _, t in ipairs(list) do if not t[3] then return false end end
            return true
        end,
        setAll = function(v) for _, t in ipairs(list) do t[3] = v end end,
        summary = function()
            local n = 0
            for _, t in ipairs(list) do if t[3] then n += 1 end end
            return n > 0 and ("  (" .. n .. ")") or ""
        end,
    })
end

-- Kartu dengan satu atau dua kotak isian
local function boxCard(page, order, keyword, titleText, desc)
    local sec = section(page, keyword, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C_ROW
    card.LayoutOrder = 1
    card.Parent = sec
    corner(card, 8)
    local cl = Instance.new("UIListLayout", card)
    cl.Padding = UDim.new(0, 4)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    local cp = Instance.new("UIPadding", card)
    cp.PaddingLeft = UDim.new(0, 10)
    cp.PaddingRight = UDim.new(0, 10)
    cp.PaddingBottom = UDim.new(0, 8)
    textBlock(card, titleText, desc, 0, true)
    return card
end

local function newBox(parent, placeholder, size, pos, order)
    local b = Instance.new("TextBox")
    b.Size = size
    if pos then b.Position = pos end
    b.BackgroundColor3 = C_BG
    b.PlaceholderText = placeholder
    b.PlaceholderColor3 = C_GRAY
    b.Text = ""
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.ClearTextOnFocus = false
    if order then b.LayoutOrder = order end
    b.Parent = parent
    corner(b, 6)
    return b
end

-- ===== HALAMAN MAIN: Bid (1-4), Sell (10-13), Grade (15-18), Auto (20-22), Status (99) =====

-- ----- BID -----
groupTitle(mainPage, "Bid", 1)

local sBid = section(mainPage, "auto bid", 2)
switchRow(sBid, "Auto Bid",
    "Cari meja yang sudah ada pemainnya (Quick Join) kalau belum duduk, lalu bid di giliranmu sesuai opsi di bawah.",
    "AutoBid")

do
    local items = {}
    for i, name in ipairs({ "Small", "Medium", "High", "Extreme", "Pass" }) do
        items[i] = { key = name, label = name }
    end
    makeDropdown(mainPage, 3, "select bid options small medium high extreme pass",
        "Select Bid Options", "Pilih salah satu. Pass = lewati giliran tanpa bid.", {
            items = items,
            isOn = function(k) return State.BidOption == k end,
            pick = function(k) State.BidOption = k end,
            summary = function() return "  (" .. State.BidOption .. ")" end,
        })
end

do
    local card = boxCard(mainPage, 4, "stop at streak batas", "Stop At Streak",
        "Auto Bid mati sendiri saat streak sudah sama atau lebih dari angka ini. Kosong = tidak dibatasi.")
    local streakBox = newBox(card, "eg. 100", UDim2.new(1, 0, 0, 26), nil, 2)
    local streakLbl = Instance.new("TextLabel")
    streakLbl.Size = UDim2.new(1, 0, 0, 16)
    streakLbl.BackgroundTransparency = 1
    streakLbl.Text = "Streak: -"
    streakLbl.TextColor3 = C_GRAY
    streakLbl.Font = Enum.Font.GothamBold
    streakLbl.TextSize = 11
    streakLbl.TextXAlignment = Enum.TextXAlignment.Left
    streakLbl.LayoutOrder = 3
    streakLbl.Parent = card
    streakBox.FocusLost:Connect(function()
        local v = parseValue(streakBox.Text)
        if v == nil then
            State.StopStreak = 0
            setStatus("Streak: format salah (contoh 100)", C_WARN)
        else
            State.StopStreak = v
            setStatus(v == 0 and "Stop streak: OFF" or ("Berhenti di streak " .. fmtNum(v)),
                v == 0 and C_GRAY or C_GOOD)
        end
    end)
end

-- ----- SELL -----
groupTitle(mainPage, "Sell", 10)

local sSell = section(mainPage, "auto sell", 11)
switchRow(sSell, "Auto Sell",
    "Jual brainrot otomatis tiap beberapa detik, hanya rarity yang kamu pilih di bawah.", "AutoSell")

rarityDropdown(12,
    "rarity to sell all common uncommon rare epic legendary mythic cosmic secret celestial divine brainrot god",
    "Rarity To Sell",
    "Pilih rarity yang boleh dijual. Rarity yang tidak dicentang tidak akan disentuh.", TIERS)

do
    local card = boxCard(mainPage, 13, "minimum maximum brainrot to sell nilai batas value min max",
        "Min / Max Brainrot To Sell",
        "Hanya jual brainrot yang nilainya di antara Min dan Max (termasuk angkanya). Max kosong = filter nilai mati (jual per rarity). Bisa pakai k, m, b.")
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = 2
    row.Parent = card
    local minBox = newBox(row, "Min  eg. 500k", UDim2.new(0.5, -3, 1, 0), UDim2.new(0, 0, 0, 0))
    local maxBox = newBox(row, "Max  eg. 2m", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0))
    local function apply()
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
    minBox.FocusLost:Connect(apply)
    maxBox.FocusLost:Connect(apply)
end

-- ----- GRADE -----
groupTitle(mainPage, "Grade", 15)

local sGrade = section(mainPage, "auto grade", 16)
switchRow(sGrade, "Auto Grade",
    "Roll grade otomatis untuk brainrot pada rarity yang dipilih, mulai dari yang termahal. Atur target di Stop At Grade.",
    "AutoGrade")

rarityDropdown(17,
    "rarity to grade all common uncommon rare epic legendary mythic cosmic secret celestial divine brainrot god",
    "Rarity To Grade",
    "Pilih rarity yang boleh di-grade. Rarity yang tidak dicentang tidak akan disentuh.", GTIERS)

do
    local items = { { key = "__once", label = "Sekali saja (tanpa roll ulang)" } }
    for _, g in ipairs(GRADE_LIST) do
        items[#items + 1] = { key = g[1], label = g[1] .. "  (x" .. tostring(g[2]) .. ")" }
    end
    makeDropdown(mainPage, 18, "stop at grade target sekali saja roll ulang",
        "Stop At Grade",
        "Pilih salah satu. Dengan target, brainrot di-roll ulang sampai grade-nya mencapai atau melebihi target. Setiap roll bisa makan biaya.", {
            items = items,
            isOn = function(k) return (State.GradeTarget or "__once") == k end,
            pick = function(k) State.GradeTarget = (k ~= "__once") and k or nil end,
            summary = function() return "  (" .. (State.GradeTarget or "Sekali saja") .. ")" end,
        })
end

-- ----- AUTO -----
groupTitle(mainPage, "Auto", 20)
local sCol = section(mainPage, "auto collect cash", 21)
switchRow(sCol, "Auto Collect Cash",
    "Ambil uang otomatis tiap beberapa detik tanpa menekan tombol Collect.", "AutoCollect")
local sReb = section(mainPage, "auto rebirth", 22)
switchRow(sReb, "Auto Rebirth",
    "Rebirth otomatis kalau syaratnya sudah terpenuhi. Hati-hati: rebirth bisa mereset progres.",
    "AutoRebirth")

-- ----- STATUS -----
local sStat = section(mainPage, "status", 99)
statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1, 0, 0, 18)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "Siap. (mode preview, tampilan saja)"
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

refreshAll()
setTab("Main")
