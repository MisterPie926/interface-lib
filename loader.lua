-- ╔══════════════════════════════════════════════════════╗
-- ║          SHADOW UI LIBRARY  •  by Claude             ║
-- ║   Minimalist • Black/Red • Italic Bold Purple Text   ║
-- ╚══════════════════════════════════════════════════════╝

local ShadowLib = {}
ShadowLib.__index = ShadowLib

-- ── Константы стиля ──────────────────────────────────────
local COLORS = {
    BG          = Color3.fromRGB(10,  10,  10),   -- Основной фон (почти чёрный)
    PANEL       = Color3.fromRGB(18,  18,  18),   -- Панель
    BORDER      = Color3.fromRGB(180,  0,   0),   -- Красная обводка
    ACCENT      = Color3.fromRGB(220,  0,   0),   -- Красный акцент (кнопки активны)
    ACCENT_OFF  = Color3.fromRGB(60,  10,  10),   -- Тёмно-красный (выключено)
    SLIDER_FILL = Color3.fromRGB(200,  0,   0),   -- Заполнение слайдера
    SLIDER_BG   = Color3.fromRGB(35,  10,  10),   -- Фон слайдера
    TAB_ACTIVE  = Color3.fromRGB(160,  0,   0),   -- Активный таб
    TAB_IDLE    = Color3.fromRGB(28,  28,  28),   -- Неактивный таб
    TEXT        = Color3.fromRGB(160, 80, 220),   -- Фиолетовый текст
    TEXT_STROKE = Color3.fromRGB(240, 200,   0),  -- Жёлтая обводка текста
}

local FONT        = Enum.Font.GothamBold          -- Жирный шрифт (ближайший к italic+bold в Roblox)
local TEXT_SIZE   = 14
local STROKE_W    = 1.5
local CORNER_R    = UDim.new(0, 4)                -- Лёгкое скругление (минимализм)
local TWEEN_TIME  = 0.12

-- ── Вспомогательные функции ───────────────────────────────

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or TWEEN_TIME, Enum.EasingStyle.Quart), props):Play()
end

local function makeCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or CORNER_R
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color or COLORS.BORDER
    s.Thickness = thickness or 1
    s.Parent    = parent
    return s
end

local function makeLabel(parent, text, size, xAlign)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text      = text
    lbl.Font      = FONT
    lbl.TextSize  = size or TEXT_SIZE
    lbl.TextColor3 = COLORS.TEXT
    lbl.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    lbl.TextItalic = true   -- курсив
    lbl.RichText  = false
    lbl.Size      = UDim2.new(1, 0, 1, 0)
    lbl.Parent    = parent

    -- Жёлтая обводка 1.5 px
    local stroke = Instance.new("UIStroke")
    stroke.Color     = COLORS.TEXT_STROKE
    stroke.Thickness = STROKE_W
    stroke.Parent    = lbl

    return lbl
end

-- ══════════════════════════════════════════════════════════
--  ShadowLib:CreateWindow(title)
--  Создаёт главное окно. Возвращает объект Window.
-- ══════════════════════════════════════════════════════════
function ShadowLib:CreateWindow(title)
    local Window = {}
    Window._tabs     = {}
    Window._tabBtns  = {}
    Window._activeTab = nil

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name             = "ShadowUI"
    screenGui.ResetOnSpawn     = false
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.Parent           = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Главная рамка
    local main = Instance.new("Frame")
    main.Name             = "Main"
    main.Size             = UDim2.new(0, 420, 0, 340)
    main.Position         = UDim2.new(0.5, -210, 0.5, -170)
    main.BackgroundColor3 = COLORS.BG
    main.BorderSizePixel  = 0
    main.Parent           = screenGui
    makeCorner(main, UDim.new(0, 6))
    makeStroke(main, COLORS.BORDER, 1.5)

    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Name             = "TitleBar"
    titleBar.Size             = UDim2.new(1, 0, 0, 34)
    titleBar.BackgroundColor3 = COLORS.PANEL
    titleBar.BorderSizePixel  = 0
    titleBar.Parent           = main
    makeCorner(titleBar, UDim.new(0, 6))

    -- Нижние углы заголовка — перекрываем скругление
    local titleFix = Instance.new("Frame")
    titleFix.Size             = UDim2.new(1, 0, 0, 10)
    titleFix.Position         = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3 = COLORS.PANEL
    titleFix.BorderSizePixel  = 0
    titleFix.Parent           = titleBar

    local titleLbl = makeLabel(titleBar, title or "Shadow UI", 15, Enum.TextXAlignment.Center)
    titleLbl.Size = UDim2.new(1, -40, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)

    -- Красная линия под заголовком
    local divider = Instance.new("Frame")
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.Position         = UDim2.new(0, 0, 0, 34)
    divider.BackgroundColor3 = COLORS.BORDER
    divider.BorderSizePixel  = 0
    divider.Parent           = main

    -- Панель табов (слева)
    local tabPanel = Instance.new("Frame")
    tabPanel.Name             = "TabPanel"
    tabPanel.Size             = UDim2.new(0, 110, 1, -35)
    tabPanel.Position         = UDim2.new(0, 0, 0, 35)
    tabPanel.BackgroundColor3 = COLORS.PANEL
    tabPanel.BorderSizePixel  = 0
    tabPanel.Parent           = main

    -- Правая граница панели табов
    local tabDivider = Instance.new("Frame")
    tabDivider.Size             = UDim2.new(0, 1, 1, 0)
    tabDivider.Position         = UDim2.new(1, 0, 0, 0)
    tabDivider.BackgroundColor3 = COLORS.BORDER
    tabDivider.BorderSizePixel  = 0
    tabDivider.Parent           = tabPanel

    local tabList = Instance.new("UIListLayout")
    tabList.Padding         = UDim.new(0, 2)
    tabList.SortOrder       = Enum.SortOrder.LayoutOrder
    tabList.Parent          = tabPanel
    tabList.Wrap = true

    -- Контент-зона
    local contentZone = Instance.new("Frame")
    contentZone.Name             = "ContentZone"
    contentZone.Size             = UDim2.new(1, -112, 1, -36)
    contentZone.Position         = UDim2.new(0, 112, 0, 36)
    contentZone.BackgroundTransparency = 1
    contentZone.BorderSizePixel  = 0
    contentZone.Parent           = main

    -- Перетаскивание окна
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- ── Метод: AddTab ────────────────────────────────────
    function Window:AddTab(name)
        local Tab = {}
        Tab._elements = {}

        -- Кнопка таба
        local btn = Instance.new("TextButton")
        btn.Name             = name
        btn.Size             = UDim2.new(1, -2, 0, 30)
        btn.BackgroundColor3 = COLORS.TAB_IDLE
        btn.BorderSizePixel  = 0
        btn.Text             = ""
        btn.LayoutOrder      = #Window._tabs + 1
        btn.Parent           = tabPanel
        makeCorner(btn, UDim.new(0, 3))

        local btnLbl = makeLabel(btn, name, 13, Enum.TextXAlignment.Center)
        btnLbl.Size = UDim2.new(1, 0, 1, 0)

        -- Контент-фрейм таба
        local frame = Instance.new("ScrollingFrame")
        frame.Name                 = name .. "_Frame"
        frame.Size                 = UDim2.new(1, -10, 1, -10)
        frame.Position             = UDim2.new(0, 5, 0, 5)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel      = 0
        frame.ScrollBarThickness   = 3
        frame.ScrollBarImageColor3 = COLORS.BORDER
        frame.CanvasSize           = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
        frame.Visible              = false
        frame.Parent               = contentZone

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding    = UDim.new(0, 6)
        listLayout.SortOrder  = Enum.SortOrder.LayoutOrder
        listLayout.Parent     = frame

        local function activate()
            -- Скрыть остальные табы
            for _, t in ipairs(Window._tabs) do
                t._frame.Visible = false
            end
            for _, b in ipairs(Window._tabBtns) do
                tween(b, { BackgroundColor3 = COLORS.TAB_IDLE })
            end
            frame.Visible = true
            tween(btn, { BackgroundColor3 = COLORS.TAB_ACTIVE })
            Window._activeTab = Tab
        end

        btn.MouseButton1Click:Connect(activate)

        Tab._frame  = frame
        Tab._list   = listLayout
        Tab._order  = 0

        -- Первый таб активируется автоматически
        if #Window._tabs == 0 then
            task.defer(activate)
        end

        table.insert(Window._tabs,    Tab)
        table.insert(Window._tabBtns, btn)

        -- ── Добавить элемент-обёртку (строку) ────────────
        local function newRow(h)
            local row = Instance.new("Frame")
            row.Size             = UDim2.new(1, -6, 0, h or 30)
            row.BackgroundTransparency = 1
            row.BorderSizePixel  = 0
            Tab._order = Tab._order + 1
            row.LayoutOrder = Tab._order
            row.Parent = frame
            return row
        end

        -- ── Tab:AddButton(text, callback) ─────────────────
        function Tab:AddButton(text, callback)
            local row = newRow(30)

            local btn2 = Instance.new("TextButton")
            btn2.Size             = UDim2.new(1, 0, 1, 0)
            btn2.BackgroundColor3 = COLORS.ACCENT_OFF
            btn2.BorderSizePixel  = 0
            btn2.Text             = ""
            btn2.Parent           = row
            makeCorner(btn2)
            makeStroke(btn2, COLORS.BORDER, 1)

            local lbl2 = makeLabel(btn2, text, TEXT_SIZE, Enum.TextXAlignment.Center)
            lbl2.Size = UDim2.new(1, 0, 1, 0)

            btn2.MouseEnter:Connect(function()
                tween(btn2, { BackgroundColor3 = COLORS.ACCENT })
            end)
            btn2.MouseLeave:Connect(function()
                tween(btn2, { BackgroundColor3 = COLORS.ACCENT_OFF })
            end)
            btn2.MouseButton1Click:Connect(function()
                tween(btn2, { BackgroundColor3 = Color3.fromRGB(255, 30, 30) })
                task.delay(0.1, function()
                    tween(btn2, { BackgroundColor3 = COLORS.ACCENT_OFF })
                end)
                if callback then callback() end
            end)

            return btn2
        end

        -- ── Tab:AddToggle(text, default, callback) ────────
        function Tab:AddToggle(text, default, callback)
            local row    = newRow(30)
            local state  = default or false

            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = COLORS.PANEL
            bg.BorderSizePixel  = 0
            bg.Parent           = row
            makeCorner(bg)
            makeStroke(bg, COLORS.BORDER, 1)

            local lbl3 = makeLabel(bg, text, TEXT_SIZE)
            lbl3.Size     = UDim2.new(1, -60, 1, 0)
            lbl3.Position = UDim2.new(0, 8, 0, 0)

            -- Переключатель-пилюля
            local pillBG = Instance.new("Frame")
            pillBG.Size             = UDim2.new(0, 40, 0, 20)
            pillBG.Position         = UDim2.new(1, -48, 0.5, -10)
            pillBG.BackgroundColor3 = state and COLORS.ACCENT or COLORS.ACCENT_OFF
            pillBG.BorderSizePixel  = 0
            pillBG.Parent           = bg
            makeCorner(pillBG, UDim.new(1, 0))
            makeStroke(pillBG, COLORS.BORDER, 1)

            local knob = Instance.new("Frame")
            knob.Size             = UDim2.new(0, 14, 0, 14)
            knob.Position         = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            knob.BorderSizePixel  = 0
            knob.Parent           = pillBG
            makeCorner(knob, UDim.new(1, 0))

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size             = UDim2.new(1, 0, 1, 0)
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Text             = ""
            toggleBtn.Parent           = bg

            toggleBtn.MouseButton1Click:Connect(function()
                state = not state
                tween(pillBG, { BackgroundColor3 = state and COLORS.ACCENT or COLORS.ACCENT_OFF })
                tween(knob, { Position = state
                    and UDim2.new(1, -17, 0.5, -7)
                    or  UDim2.new(0,  3, 0.5, -7)
                })
                if callback then callback(state) end
            end)

            local Toggle = {}
            function Toggle:Set(v)
                state = v
                tween(pillBG, { BackgroundColor3 = v and COLORS.ACCENT or COLORS.ACCENT_OFF })
                tween(knob, { Position = v
                    and UDim2.new(1, -17, 0.5, -7)
                    or  UDim2.new(0,  3, 0.5, -7)
                })
                if callback then callback(v) end
            end
            function Toggle:Get() return state end
            return Toggle
        end

        -- ── Tab:AddSlider(text, min, max, default, callback) ──
        function Tab:AddSlider(text, min, max, default, callback)
            min     = min     or 0
            max     = max     or 100
            default = default or min
            local value = math.clamp(default, min, max)

            local row = newRow(48)

            local bg = Instance.new("Frame")
            bg.Size             = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = COLORS.PANEL
            bg.BorderSizePixel  = 0
            bg.Parent           = row
            makeCorner(bg)
            makeStroke(bg, COLORS.BORDER, 1)

            -- Заголовок + значение
            local topRow = Instance.new("Frame")
            topRow.Size             = UDim2.new(1, 0, 0, 22)
            topRow.BackgroundTransparency = 1
            topRow.BorderSizePixel  = 0
            topRow.Parent           = bg

            local nameLbl = makeLabel(topRow, text, TEXT_SIZE)
            nameLbl.Size     = UDim2.new(1, -40, 1, 0)
            nameLbl.Position = UDim2.new(0, 8, 0, 0)

            local valLbl = makeLabel(topRow, tostring(value), TEXT_SIZE, Enum.TextXAlignment.Right)
            valLbl.Size     = UDim2.new(0, 36, 1, 0)
            valLbl.Position = UDim2.new(1, -40, 0, 0)

            -- Трек слайдера
            local track = Instance.new("Frame")
            track.Size             = UDim2.new(1, -16, 0, 8)
            track.Position         = UDim2.new(0, 8, 0, 28)
            track.BackgroundColor3 = COLORS.SLIDER_BG
            track.BorderSizePixel  = 0
            track.Parent           = bg
            makeCorner(track, UDim.new(1, 0))
            makeStroke(track, COLORS.BORDER, 1)

            -- Заполнение
            local fill = Instance.new("Frame")
            fill.Size             = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = COLORS.SLIDER_FILL
            fill.BorderSizePixel  = 0
            fill.Parent           = track
            makeCorner(fill, UDim.new(1, 0))

            -- Ручка
            local thumb = Instance.new("Frame")
            thumb.Size             = UDim2.new(0, 12, 0, 12)
            thumb.Position         = UDim2.new((value - min) / (max - min), -6, 0.5, -6)
            thumb.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            thumb.BorderSizePixel  = 0
            thumb.ZIndex           = 3
            thumb.Parent           = track
            makeCorner(thumb, UDim.new(1, 0))

            -- Перетаскивание
            local sliding = false

            local function updateFromInput(inp)
                local trackPos  = track.AbsolutePosition.X
                local trackSize = track.AbsoluteSize.X
                local relX      = math.clamp((inp.Position.X - trackPos) / trackSize, 0, 1)
                value           = math.floor(min + relX * (max - min) + 0.5)
                local frac      = (value - min) / (max - min)
                fill.Size             = UDim2.new(frac, 0, 1, 0)
                thumb.Position        = UDim2.new(frac, -6, 0.5, -6)
                valLbl.Text           = tostring(value)
                if callback then callback(value) end
            end

            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    updateFromInput(inp)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromInput(inp)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            local Slider = {}
            function Slider:Set(v)
                value = math.clamp(v, min, max)
                local frac = (value - min) / (max - min)
                fill.Size      = UDim2.new(frac, 0, 1, 0)
                thumb.Position = UDim2.new(frac, -6, 0.5, -6)
                valLbl.Text    = tostring(value)
                if callback then callback(value) end
            end
            function Slider:Get() return value end
            return Slider
        end

        -- ── Tab:AddLabel(text) ────────────────────────────
        function Tab:AddLabel(text)
            local row = newRow(24)
            local bg  = Instance.new("Frame")
            bg.Size             = UDim2.new(1, 0, 1, 0)
            bg.BackgroundTransparency = 1
            bg.Parent           = row
            local lbl = makeLabel(bg, text, TEXT_SIZE)
            lbl.Position = UDim2.new(0, 8, 0, 0)
            return lbl
        end

        -- ── Tab:AddSeparator() ────────────────────────────
        function Tab:AddSeparator()
            local row = newRow(10)
            local line = Instance.new("Frame")
            line.Size             = UDim2.new(1, -16, 0, 1)
            line.Position         = UDim2.new(0, 8, 0.5, 0)
            line.BackgroundColor3 = COLORS.BORDER
            line.BorderSizePixel  = 0
            line.Parent           = row
        end

        return Tab
    end

    -- ── Window:Destroy() ─────────────────────────────────
    function Window:Destroy()
        screenGui:Destroy()
    end

    return Window
end

return ShadowLib

--[[
╔══════════════════════════════════════════════════════════╗
║                   ПРИМЕР ИСПОЛЬЗОВАНИЯ                   ║
╠══════════════════════════════════════════════════════════╣

local ShadowLib = loadstring(game:HttpGet("URL_HERE"))()
-- или require(ShadowLib) если лежит в скриптах

local win = ShadowLib:CreateWindow("☠ Shadow UI")

-- Таб 1: Боевые настройки
local combatTab = win:AddTab("⚔ Бой")

combatTab:AddLabel("Базовые параметры")
combatTab:AddSeparator()

combatTab:AddButton("Убить всех", function()
    print("Атакуем!")
end)

local aimToggle = combatTab:AddToggle("Аимбот", false, function(state)
    print("Аимбот:", state)
end)

local fovSlider = combatTab:AddSlider("FOV", 1, 100, 50, function(val)
    print("FOV:", val)
end)

-- Таб 2: Визуал
local visualTab = win:AddTab("👁 Визуал")

local espToggle = visualTab:AddToggle("ESP Игроки", true, function(state)
    print("ESP:", state)
end)

local distSlider = visualTab:AddSlider("Дистанция", 1, 100, 75, function(val)
    print("Дистанция:", val)
end)

-- Таб 3: Прочее
local miscTab = win:AddTab("⚙ Прочее")

miscTab:AddButton("Телепорт к споуну", function()
    print("Телепорт!")
end)

miscTab:AddSeparator()

miscTab:AddButton("Закрыть меню", function()
    win:Destroy()
end)

╚══════════════════════════════════════════════════════════╝
]]
