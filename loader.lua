-- ╔══════════════════════════════════════════════════════════╗
-- ║         SHADOW UI LIBRARY  v2.0  •  by Claude           ║
-- ║  G = открыть/скрыть  •  ⛶ = полный экран  •  ✕ = закрыть
-- ╚══════════════════════════════════════════════════════════╝

local ShadowLib = {}
ShadowLib.__index = ShadowLib

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

-- ── Палитра ──────────────────────────────────────────────────
local C = {
    BG          = Color3.fromRGB(10,  10,  10),
    PANEL       = Color3.fromRGB(20,  20,  20),
    BORDER      = Color3.fromRGB(180,  0,   0),
    ACCENT      = Color3.fromRGB(220,  0,   0),
    ACCENT_DIM  = Color3.fromRGB(55,  10,  10),
    SLIDER_BG   = Color3.fromRGB(35,  10,  10),
    TAB_ACTIVE  = Color3.fromRGB(150,  0,   0),
    TAB_IDLE    = Color3.fromRGB(26,  26,  26),
    TAB_HOVER   = Color3.fromRGB(40,  12,  12),
    TEXT        = Color3.fromRGB(160, 80, 220),   -- фиолетовый
    STROKE_CLR  = Color3.fromRGB(240, 200,   0),  -- жёлтая обводка текста
    BTN_CTRL_OK = Color3.fromRGB(90, 180, 255),
    BTN_CTRL_CL = Color3.fromRGB(220, 60,  60),
}

local FONT       = Enum.Font.GothamBold
local TXTSZ      = 14
local STROKE_W   = 1.5
local WIN_W, WIN_H   = 420, 340
local FULL_W, FULL_H = 720, 520

-- ── Хелперы ──────────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.18,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 6)
    c.Parent = p
    return c
end

local function stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color     = col   or C.BORDER
    s.Thickness = thick or 1.5
    s.Parent    = p
    return s
end

-- Текстовый лейбл — БЕЗ TextItalic (свойство вызывало ошибку)
local function lbl(parent, text, size, xAlign)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text           = text or ""
    t.Font           = FONT
    t.TextSize       = size or TXTSZ
    t.TextColor3     = C.TEXT
    t.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    t.RichText       = false
    t.Size           = UDim2.new(1, 0, 1, 0)
    t.Parent         = parent

    local s2 = Instance.new("UIStroke")
    s2.Color     = C.STROKE_CLR
    s2.Thickness = STROKE_W
    s2.Parent    = t

    return t
end

local function pulse(obj, baseColor)
    tw(obj, { BackgroundColor3 = Color3.fromRGB(255, 50, 50) }, 0.07)
    task.delay(0.1, function()
        tw(obj, { BackgroundColor3 = baseColor or C.ACCENT_DIM }, 0.15)
    end)
end

-- ══════════════════════════════════════════════════════════════
function ShadowLib:CreateWindow(title)
    local W = { _tabs = {}, _tabBtns = {}, _visible = true, _fullscreen = false }

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "ShadowUI"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Blur (активен только в полноэкранном режиме)
    local blurFX = Instance.new("BlurEffect")
    blurFX.Size   = 0
    blurFX.Parent = game:GetService("Lighting")

    -- Главный фрейм
    local main = Instance.new("Frame")
    main.Name             = "ShadowMain"
    main.Size             = UDim2.new(0, WIN_W * 0.82, 0, WIN_H * 0.82)
    main.Position         = UDim2.new(0.5, -(WIN_W*0.82)/2, 0.5, -(WIN_H*0.82)/2)
    main.BackgroundColor3 = C.BG
    main.BackgroundTransparency = 1
    main.BorderSizePixel  = 0
    main.ClipsDescendants = true
    main.Parent           = sg
    corner(main, UDim.new(0, 10))
    stroke(main, C.BORDER, 1.5)

    -- Анимация появления при создании
    task.defer(function()
        tw(main, {
            Size     = UDim2.new(0, WIN_W, 0, WIN_H),
            Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
            BackgroundTransparency = 0,
        }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- ── Заголовок ───────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name             = "TitleBar"
    titleBar.Size             = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = C.PANEL
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 2
    titleBar.Parent           = main
    corner(titleBar, UDim.new(0, 10))

    -- Перекрываем нижние скруглённые углы заголовка
    local titleFix = Instance.new("Frame")
    titleFix.Size             = UDim2.new(1, 0, 0, 14)
    titleFix.Position         = UDim2.new(0, 0, 1, -14)
    titleFix.BackgroundColor3 = C.PANEL
    titleFix.BorderSizePixel  = 0
    titleFix.ZIndex           = 2
    titleFix.Parent           = titleBar

    -- Неоновая подчёркивающая линия
    local accentBar = Instance.new("Frame")
    accentBar.Size             = UDim2.new(0, 56, 0, 2)
    accentBar.Position         = UDim2.new(0, 12, 1, -2)
    accentBar.BackgroundColor3 = C.ACCENT
    accentBar.BorderSizePixel  = 0
    accentBar.ZIndex           = 3
    accentBar.Parent           = titleBar
    corner(accentBar, UDim.new(1, 0))

    local titleLbl = lbl(titleBar, title or "Shadow UI", 15, Enum.TextXAlignment.Left)
    titleLbl.Size     = UDim2.new(1, -100, 1, 0)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.ZIndex   = 3

    -- Кнопки управления (справа в заголовке)
    local function ctrlBtn(icon, xOff, col, cb)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 22, 0, 22)
        b.Position         = UDim2.new(1, xOff, 0.5, -11)
        b.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
        b.BorderSizePixel  = 0
        b.Text             = icon
        b.TextColor3       = col
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 11
        b.ZIndex           = 4
        b.Parent           = titleBar
        corner(b, UDim.new(1, 0))
        b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = col }, 0.1) tw(b, { TextColor3 = Color3.new(1,1,1) }, 0.1) end)
        b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = Color3.fromRGB(32,32,32) }, 0.1) tw(b, { TextColor3 = col }, 0.1) end)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    ctrlBtn("✕", -30, C.BTN_CTRL_CL, function() W:Toggle(false) end)
    ctrlBtn("⛶", -58, C.BTN_CTRL_OK, function() W:ToggleFullscreen() end)

    -- Горизонтальный разделитель
    local divider = Instance.new("Frame")
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.Position         = UDim2.new(0, 0, 0, 36)
    divider.BackgroundColor3 = C.BORDER
    divider.BorderSizePixel  = 0
    divider.Parent           = main

    -- ── Панель табов (слева) ────────────────────────────────
    local tabPanel = Instance.new("Frame")
    tabPanel.Size             = UDim2.new(0, 112, 1, -37)
    tabPanel.Position         = UDim2.new(0, 0, 0, 37)
    tabPanel.BackgroundColor3 = C.PANEL
    tabPanel.BorderSizePixel  = 0
    tabPanel.Parent           = main

    local tabDivider = Instance.new("Frame")
    tabDivider.Size             = UDim2.new(0, 1, 1, 0)
    tabDivider.Position         = UDim2.new(1, 0, 0, 0)
    tabDivider.BackgroundColor3 = C.BORDER
    tabDivider.BorderSizePixel  = 0
    tabDivider.Parent           = tabPanel

    local tabList = Instance.new("UIListLayout")
    tabList.Padding       = UDim.new(0, 3)
    tabList.SortOrder     = Enum.SortOrder.LayoutOrder
    tabList.FillDirection = Enum.FillDirection.Vertical
    tabList.Wraps         = true            -- ← Wrap = true
    tabList.Parent        = tabPanel

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingTop   = UDim.new(0, 6)
    tabPad.PaddingLeft  = UDim.new(0, 4)
    tabPad.PaddingRight = UDim.new(0, 4)
    tabPad.Parent       = tabPanel

    -- ── Зона контента ───────────────────────────────────────
    local contentZone = Instance.new("Frame")
    contentZone.Size                 = UDim2.new(1, -114, 1, -38)
    contentZone.Position             = UDim2.new(0, 114, 0, 38)
    contentZone.BackgroundTransparency = 1
    contentZone.BorderSizePixel      = 0
    contentZone.ClipsDescendants     = true
    contentZone.Parent               = main

    -- ── Перетаскивание ──────────────────────────────────────
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and not W._fullscreen then
            dragging = true; dragStart = inp.Position; startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- ── Клавиша G ───────────────────────────────────────────
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.G then W:Toggle() end
    end)

    -- ── Window:Toggle ────────────────────────────────────────
    function W:Toggle(force)
        local show = (force ~= nil) and force or not W._visible
        W._visible = show
        if show then
            main.Visible = true
            tw(main, { BackgroundTransparency = 0,
                Size     = UDim2.new(0, WIN_W,    0, WIN_H),
                Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) },
                0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            tw(main, { BackgroundTransparency = 1,
                Size     = UDim2.new(0, WIN_W*0.85, 0, WIN_H*0.85),
                Position = UDim2.new(0.5, -(WIN_W*0.85)/2, 0.5, -(WIN_H*0.85)/2) },
                0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.2, function() main.Visible = false end)
            if W._fullscreen then tw(blurFX, { Size = 0 }, 0.2) end
        end
    end

    -- ── Window:ToggleFullscreen ──────────────────────────────
    function W:ToggleFullscreen()
        W._fullscreen = not W._fullscreen
        if W._fullscreen then
            tw(main, { Size = UDim2.new(0, FULL_W, 0, FULL_H),
                Position = UDim2.new(0.5, -FULL_W/2, 0.5, -FULL_H/2) },
                0.3, Enum.EasingStyle.Quart)
            tw(blurFX, { Size = 16 }, 0.3)
        else
            tw(main, { Size = UDim2.new(0, WIN_W, 0, WIN_H),
                Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) },
                0.3, Enum.EasingStyle.Back)
            tw(blurFX, { Size = 0 }, 0.3)
        end
    end

    -- ── Window:Destroy ───────────────────────────────────────
    function W:Destroy()
        tw(blurFX, { Size = 0 }, 0.18)
        tw(main, { BackgroundTransparency = 1 }, 0.18)
        task.delay(0.2, function() sg:Destroy(); blurFX:Destroy() end)
    end

    -- ════════════════════════════════════════════════════════
    --  Window:AddTab(name)
    -- ════════════════════════════════════════════════════════
    function W:AddTab(name)
        local Tab = { _order = 0 }

        -- Кнопка таба
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size             = UDim2.new(1, 0, 0, 28)
        tabBtn.BackgroundColor3 = C.TAB_IDLE
        tabBtn.BorderSizePixel  = 0
        tabBtn.Text             = ""
        tabBtn.AutoButtonColor  = false
        tabBtn.LayoutOrder      = #W._tabs + 1
        tabBtn.Parent           = tabPanel
        corner(tabBtn, UDim.new(0, 5))

        -- Красная вертикальная полоска активного таба
        local tabAcc = Instance.new("Frame")
        tabAcc.Size             = UDim2.new(0, 2, 0.6, 0)
        tabAcc.Position         = UDim2.new(0, 0, 0.2, 0)
        tabAcc.BackgroundColor3 = C.ACCENT
        tabAcc.BorderSizePixel  = 0
        tabAcc.BackgroundTransparency = 1
        tabAcc.Parent           = tabBtn
        corner(tabAcc, UDim.new(0, 2))

        local tabLbl = lbl(tabBtn, name, 12, Enum.TextXAlignment.Center)
        tabLbl.Size     = UDim2.new(1, -6, 1, 0)
        tabLbl.Position = UDim2.new(0, 3, 0, 0)

        tabBtn.MouseEnter:Connect(function()
            if tabBtn.BackgroundColor3 ~= C.TAB_ACTIVE then
                tw(tabBtn, { BackgroundColor3 = C.TAB_HOVER }, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if tabBtn.BackgroundColor3 ~= C.TAB_ACTIVE then
                tw(tabBtn, { BackgroundColor3 = C.TAB_IDLE }, 0.1)
            end
        end)

        -- ScrollingFrame контента
        local frame = Instance.new("ScrollingFrame")
        frame.Name                  = name .. "_Frame"
        frame.Size                  = UDim2.new(1, -8, 1, -8)
        frame.Position              = UDim2.new(0, 4, 0, 4)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel       = 0
        frame.ScrollBarThickness    = 3
        frame.ScrollBarImageColor3  = C.BORDER
        frame.CanvasSize            = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
        frame.Visible               = false
        frame.Parent                = contentZone

        local contentList = Instance.new("UIListLayout")
        contentList.Padding       = UDim.new(0, 6)
        contentList.SortOrder     = Enum.SortOrder.LayoutOrder
        contentList.FillDirection = Enum.FillDirection.Vertical
        contentList.Wraps         = true    -- ← Wrap = true
        contentList.Parent        = frame

        local cPad = Instance.new("UIPadding")
        cPad.PaddingTop    = UDim.new(0, 4)
        cPad.PaddingBottom = UDim.new(0, 4)
        cPad.PaddingLeft   = UDim.new(0, 4)
        cPad.PaddingRight  = UDim.new(0, 4)
        cPad.Parent        = frame

        local function activateTab()
            for _, t in ipairs(W._tabs)    do t._frame.Visible = false end
            for _, b in ipairs(W._tabBtns) do
                tw(b.btn, { BackgroundColor3 = C.TAB_IDLE }, 0.14)
                tw(b.acc, { BackgroundTransparency = 1 }, 0.14)
            end
            frame.Visible = true
            tw(tabBtn, { BackgroundColor3 = C.TAB_ACTIVE }, 0.14)
            tw(tabAcc, { BackgroundTransparency = 0 }, 0.14)
            W._activeTab = Tab
        end

        tabBtn.MouseButton1Click:Connect(activateTab)
        Tab._frame = frame
        if #W._tabs == 0 then task.defer(activateTab) end
        table.insert(W._tabs,    Tab)
        table.insert(W._tabBtns, { btn = tabBtn, acc = tabAcc })

        -- Вспомогательная строка
        local function row(h)
            local r = Instance.new("Frame")
            r.Size             = UDim2.new(1, 0, 0, h or 32)
            r.BackgroundTransparency = 1
            r.BorderSizePixel  = 0
            Tab._order = Tab._order + 1
            r.LayoutOrder = Tab._order
            r.Parent = frame
            return r
        end

        -- ── AddButton ────────────────────────────────────────
        function Tab:AddButton(text, callback)
            local r   = row(32)
            local btn = Instance.new("TextButton")
            btn.Size             = UDim2.new(1, 0, 1, 0)
            btn.BackgroundColor3 = C.ACCENT_DIM
            btn.BorderSizePixel  = 0
            btn.Text             = ""
            btn.AutoButtonColor  = false
            btn.Parent           = r
            corner(btn, UDim.new(0, 6))
            stroke(btn, C.BORDER, 1)

            lbl(btn, text, TXTSZ, Enum.TextXAlignment.Center).Size = UDim2.new(1, 0, 1, 0)

            -- Градиент-блик (hover)
            local grad = Instance.new("UIGradient")
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(90, 0, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 0, 0)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(90, 0, 0)),
            })
            grad.Transparency = NumberSequence.new(1)
            grad.Parent = btn

            btn.MouseEnter:Connect(function()
                tw(btn,  { BackgroundColor3 = C.ACCENT }, 0.12)
                tw(grad, { Transparency = NumberSequence.new(0) }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                tw(btn,  { BackgroundColor3 = C.ACCENT_DIM }, 0.12)
                tw(grad, { Transparency = NumberSequence.new(1) }, 0.12)
            end)
            btn.MouseButton1Click:Connect(function()
                pulse(btn, C.ACCENT_DIM)
                if callback then callback() end
            end)
            return btn
        end

        -- ── AddToggle ─────────────────────────────────────────
        function Tab:AddToggle(text, default, callback)
            local r     = row(32)
            local state = default or false

            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel  = 0
            bg.Parent           = r
            corner(bg, UDim.new(0, 6))
            stroke(bg, C.BORDER, 1)

            local nameLbl = lbl(bg, text, TXTSZ)
            nameLbl.Size     = UDim2.new(1, -62, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)

            -- Пилюля
            local pill = Instance.new("Frame")
            pill.Size             = UDim2.new(0, 44, 0, 22)
            pill.Position         = UDim2.new(1, -52, 0.5, -11)
            pill.BackgroundColor3 = state and C.ACCENT or C.ACCENT_DIM
            pill.BorderSizePixel  = 0
            pill.Parent           = bg
            corner(pill, UDim.new(1, 0))
            stroke(pill, C.BORDER, 1)

            local pillGrad = Instance.new("UIGradient")
            pillGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160,  0,  0)),
            })
            pillGrad.Transparency = state and NumberSequence.new(0) or NumberSequence.new(1)
            pillGrad.Parent = pill

            local knob = Instance.new("Frame")
            knob.Size             = UDim2.new(0, 16, 0, 16)
            knob.Position         = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            knob.BorderSizePixel  = 0
            knob.Parent           = pill
            corner(knob, UDim.new(1, 0))

            local hitBtn = Instance.new("TextButton")
            hitBtn.Size             = UDim2.new(1, 0, 1, 0)
            hitBtn.BackgroundTransparency = 1
            hitBtn.Text             = ""
            hitBtn.Parent           = bg

            local function applyState(v)
                tw(pill,     { BackgroundColor3 = v and C.ACCENT or C.ACCENT_DIM }, 0.15)
                tw(pillGrad, { Transparency = v and NumberSequence.new(0) or NumberSequence.new(1) }, 0.15)
                tw(knob,     { Position = v and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) },
                   0.15, Enum.EasingStyle.Back)
            end

            hitBtn.MouseButton1Click:Connect(function()
                state = not state
                applyState(state)
                if callback then callback(state) end
            end)

            local Toggle = {}
            function Toggle:Set(v) state = v; applyState(v); if callback then callback(v) end end
            function Toggle:Get() return state end
            return Toggle
        end

        -- ── AddSlider ─────────────────────────────────────────
        function Tab:AddSlider(text, minVal, maxVal, default, callback)
            minVal  = minVal  or 0
            maxVal  = maxVal  or 100
            default = default or minVal
            local val = math.clamp(default, minVal, maxVal)

            local r  = row(52)
            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel  = 0
            bg.Parent           = r
            corner(bg, UDim.new(0, 6))
            stroke(bg, C.BORDER, 1)

            -- Верхняя строка: имя + значение
            local topRow = Instance.new("Frame")
            topRow.Size                   = UDim2.new(1, 0, 0, 26)
            topRow.BackgroundTransparency = 1
            topRow.BorderSizePixel        = 0
            topRow.Parent                 = bg

            local nameLbl = lbl(topRow, text, TXTSZ)
            nameLbl.Size     = UDim2.new(1, -54, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)

            local valBox = Instance.new("Frame")
            valBox.Size             = UDim2.new(0, 40, 0, 18)
            valBox.Position         = UDim2.new(1, -46, 0.5, -9)
            valBox.BackgroundColor3 = C.ACCENT_DIM
            valBox.BorderSizePixel  = 0
            valBox.Parent           = topRow
            corner(valBox, UDim.new(0, 4))
            stroke(valBox, C.BORDER, 1)

            local valLbl = lbl(valBox, tostring(val), 12, Enum.TextXAlignment.Center)
            valLbl.Size = UDim2.new(1, 0, 1, 0)

            -- Трек
            local track = Instance.new("Frame")
            track.Size             = UDim2.new(1, -16, 0, 10)
            track.Position         = UDim2.new(0, 8, 0, 33)
            track.BackgroundColor3 = C.SLIDER_BG
            track.BorderSizePixel  = 0
            track.Parent           = bg
            corner(track, UDim.new(1, 0))
            stroke(track, C.BORDER, 1)

            -- Заполнение с градиентом
            local fill = Instance.new("Frame")
            fill.Size             = UDim2.new((val - minVal)/(maxVal - minVal), 0, 1, 0)
            fill.BackgroundColor3 = C.ACCENT
            fill.BorderSizePixel  = 0
            fill.Parent           = track
            corner(fill, UDim.new(1, 0))

            local fillGrad = Instance.new("UIGradient")
            fillGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160,  0,  0)),
            })
            fillGrad.Parent = fill

            -- Ручка
            local thumb = Instance.new("Frame")
            thumb.Size             = UDim2.new(0, 14, 0, 14)
            thumb.Position         = UDim2.new((val - minVal)/(maxVal - minVal), -7, 0.5, -7)
            thumb.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            thumb.BorderSizePixel  = 0
            thumb.ZIndex           = 4
            thumb.Parent           = track
            corner(thumb, UDim.new(1, 0))

            -- Прозрачная hit-area
            local hitArea = Instance.new("TextButton")
            hitArea.Size                   = UDim2.new(1, 0, 3, 0)
            hitArea.Position               = UDim2.new(0, 0, -1, 0)
            hitArea.BackgroundTransparency = 1
            hitArea.Text                   = ""
            hitArea.ZIndex                 = 5
            hitArea.Parent                 = track

            local sliding = false
            local function applyPos(inp)
                local relX = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                val        = math.floor(minVal + relX * (maxVal - minVal) + 0.5)
                local frac = (val - minVal) / (maxVal - minVal)
                fill.Size      = UDim2.new(frac, 0, 1, 0)
                thumb.Position = UDim2.new(frac, -7, 0.5, -7)
                valLbl.Text    = tostring(val)
                if callback then callback(val) end
            end

            hitArea.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true; applyPos(inp)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then applyPos(inp) end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
            end)

            local Slider = {}
            function Slider:Set(v)
                val = math.clamp(v, minVal, maxVal)
                local frac = (val - minVal) / (maxVal - minVal)
                fill.Size      = UDim2.new(frac, 0, 1, 0)
                thumb.Position = UDim2.new(frac, -7, 0.5, -7)
                valLbl.Text    = tostring(val)
                if callback then callback(val) end
            end
            function Slider:Get() return val end
            return Slider
        end

        -- ── AddLabel ─────────────────────────────────────────
        function Tab:AddLabel(text)
            local r  = row(24)
            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, 0, 1, 0)
            bg.BackgroundTransparency = 1
            bg.Parent           = r
            local l = lbl(bg, text, TXTSZ)
            l.Position = UDim2.new(0, 10, 0, 0)
            return l
        end

        -- ── AddSeparator ─────────────────────────────────────
        function Tab:AddSeparator()
            local r = row(12)
            local line = Instance.new("Frame")
            line.Size             = UDim2.new(1, -20, 0, 1)
            line.Position         = UDim2.new(0, 10, 0.5, 0)
            line.BackgroundColor3 = C.BORDER
            line.BorderSizePixel  = 0
            line.Parent           = r
            corner(line, UDim.new(1, 0))
        end

        return Tab
    end

    return W
end

return ShadowLib

--[[
══════════════════════════════════════════════════════════════
  ПРИМЕР ИСПОЛЬЗОВАНИЯ
══════════════════════════════════════════════════════════════

local ShadowLib = loadstring(game:HttpGet("URL_СЮДА"))()

local win = ShadowLib:CreateWindow("☠ Shadow UI")

-- G   = открыть / закрыть меню
-- ⛶  = переключить полный экран (420×340 ↔ 720×520)
-- ✕   = скрыть меню

local tab1 = win:AddTab("⚔ Бой")
local tab2 = win:AddTab("👁 Визуал")

tab1:AddLabel("Боевые настройки")
tab1:AddSeparator()

tab1:AddButton("Убить всех", function()
    print("Атака!")
end)

local aimToggle = tab1:AddToggle("Аимбот", false, function(v)
    print("Аим:", v)
end)

local fovSlider = tab1:AddSlider("FOV", 1, 100, 60, function(v)
    print("FOV:", v)
end)

-- Программное управление:
-- aimToggle:Set(true)
-- fovSlider:Set(80)
-- win:Toggle(false)
-- win:Destroy()

══════════════════════════════════════════════════════════════
]]
