-- ╔══════════════════════════════════════════════════════════╗
-- ║         SHADOW UI LIBRARY  v3.0  •  by Claude           ║
-- ║  G = открыть/скрыть  •  ⛶ = полный экран  •  ✕ = закрыть
-- ╚══════════════════════════════════════════════════════════╝
-- Что нового в v3:
--   • Текст белый (без обводки для простоты чтения)
--   • AddCheckbox  — галочка с сохранением состояния
--   • AddTextBox   — поле ввода
--   • AddDropdown  — выпадающий список
--   • Slider: sliding-состояние не сбрасывает callback при отпускании
--   • UIGradient Transparency НЕ твинится (прямое присвоение — фикс краша TweenService)
--   • Все значения сохраняются в SavedValues (доступны через element:Get())
--   • PlayerPanel — дополнительная панель справа со списком игроков + аватарки

local ShadowLib = {}
ShadowLib.__index = ShadowLib

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

-- ── Цвета ────────────────────────────────────────────────────
local C = {
    BG         = Color3.fromRGB(10,  10,  10),
    PANEL      = Color3.fromRGB(20,  20,  20),
    PANEL2     = Color3.fromRGB(16,  16,  16),
    BORDER     = Color3.fromRGB(180,  0,   0),
    ACCENT     = Color3.fromRGB(220,  0,   0),
    ACCENT_DIM = Color3.fromRGB(50,  10,  10),
    SLIDER_BG  = Color3.fromRGB(35,  10,  10),
    TAB_ACTIVE = Color3.fromRGB(150,  0,   0),
    TAB_IDLE   = Color3.fromRGB(26,  26,  26),
    TAB_HOVER  = Color3.fromRGB(40,  12,  12),
    TEXT       = Color3.fromRGB(240, 240, 240),  -- белый
    TEXT_DIM   = Color3.fromRGB(160, 160, 160),  -- серый для плейсхолдеров
    CHECK_ON   = Color3.fromRGB(220,  0,   0),
    CHECK_OFF  = Color3.fromRGB(40,  40,  40),
    INPUT_BG   = Color3.fromRGB(14,  14,  14),
    DROP_BG    = Color3.fromRGB(18,  18,  18),
    CTRL_CL    = Color3.fromRGB(220, 60,  60),
    CTRL_FS    = Color3.fromRGB(90, 180, 255),
    PLAYER_BG  = Color3.fromRGB(16,  16,  16),
}

local FONT     = Enum.Font.GothamBold
local FONTREG  = Enum.Font.Gotham
local TXTSZ    = 13
local WIN_W, WIN_H     = 420, 340
local FULL_W, FULL_H   = 720, 520
local PANEL_W          = 200   -- ширина панели игроков

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
    c.Parent = p; return c
end

local function uistroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or C.BORDER; s.Thickness = thick or 1.5
    s.Parent = p; return s
end

-- Простой белый лейбл (без TextItalic, без UIStroke на тексте)
local function lbl(parent, text, size, xAlign, color)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text           = text or ""
    t.Font           = FONT
    t.TextSize       = size or TXTSZ
    t.TextColor3     = color or C.TEXT
    t.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    t.RichText       = false
    t.Size           = UDim2.new(1, 0, 1, 0)
    t.Parent         = parent
    return t
end

local function pulse(obj, baseColor)
    tw(obj, { BackgroundColor3 = Color3.fromRGB(255, 50, 50) }, 0.07)
    task.delay(0.12, function()
        tw(obj, { BackgroundColor3 = baseColor or C.ACCENT_DIM }, 0.15)
    end)
end

-- Кнопка-иконка для заголовка
local function ctrlBtn(parent, icon, xOff, col, cb)
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
    b.Parent           = parent
    corner(b, UDim.new(1, 0))
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=col},0.1); tw(b,{TextColor3=Color3.new(1,1,1)},0.1) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=Color3.fromRGB(32,32,32)},0.1); tw(b,{TextColor3=col},0.1) end)
    b.MouseButton1Click:Connect(cb)
    return b
end

-- ══════════════════════════════════════════════════════════════
function ShadowLib:CreateWindow(title)
    local W = {
        _tabs      = {},
        _tabBtns   = {},
        _visible   = true,
        _fullscreen = false,
        _playerPanel = nil,
        SavedValues = {},   -- { elementId = value }
    }

    -- ── ScreenGui ─────────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name           = "ShadowUI"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")

    local blurFX = Instance.new("BlurEffect")
    blurFX.Size = 0; blurFX.Parent = game:GetService("Lighting")

    -- ── Главный фрейм ─────────────────────────────────────────
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
    uistroke(main, C.BORDER, 1.5)

    task.defer(function()
        tw(main, {
            Size = UDim2.new(0, WIN_W, 0, WIN_H),
            Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
            BackgroundTransparency = 0,
        }, 0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

    -- ── Заголовок ─────────────────────────────────────────────
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"; titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = C.PANEL; titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 2; titleBar.Parent = main
    corner(titleBar, UDim.new(0, 10))

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 14); titleFix.Position = UDim2.new(0, 0, 1, -14)
    titleFix.BackgroundColor3 = C.PANEL; titleFix.BorderSizePixel = 0
    titleFix.ZIndex = 2; titleFix.Parent = titleBar

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 56, 0, 2); accentBar.Position = UDim2.new(0, 12, 1, -2)
    accentBar.BackgroundColor3 = C.ACCENT; accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 3; accentBar.Parent = titleBar
    corner(accentBar, UDim.new(1, 0))

    local titleLbl = lbl(titleBar, title or "Shadow UI", 15, Enum.TextXAlignment.Left)
    titleLbl.Size = UDim2.new(1, -120, 1, 0); titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.ZIndex = 3

    ctrlBtn(titleBar, "✕", -30,  C.CTRL_CL, function() W:Toggle(false) end)
    ctrlBtn(titleBar, "⛶", -58, C.CTRL_FS, function() W:ToggleFullscreen() end)
    ctrlBtn(titleBar, "☰", -86, Color3.fromRGB(160,220,100), function() W:TogglePlayerPanel() end)

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1); divider.Position = UDim2.new(0, 0, 0, 36)
    divider.BackgroundColor3 = C.BORDER; divider.BorderSizePixel = 0; divider.Parent = main

    -- ── Панель табов (слева) ───────────────────────────────────
    local tabPanel = Instance.new("Frame")
    tabPanel.Size = UDim2.new(0, 112, 1, -37); tabPanel.Position = UDim2.new(0, 0, 0, 37)
    tabPanel.BackgroundColor3 = C.PANEL; tabPanel.BorderSizePixel = 0; tabPanel.Parent = main

    local tabDivLine = Instance.new("Frame")
    tabDivLine.Size = UDim2.new(0, 1, 1, 0); tabDivLine.Position = UDim2.new(1, 0, 0, 0)
    tabDivLine.BackgroundColor3 = C.BORDER; tabDivLine.BorderSizePixel = 0; tabDivLine.Parent = tabPanel

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 3); tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.FillDirection = Enum.FillDirection.Vertical; tabList.Wraps = true
    tabList.Parent = tabPanel

    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingTop = UDim.new(0, 6); tabPad.PaddingLeft = UDim.new(0, 4)
    tabPad.PaddingRight = UDim.new(0, 4); tabPad.Parent = tabPanel

    -- ── Зона контента ─────────────────────────────────────────
    local contentZone = Instance.new("Frame")
    contentZone.Size = UDim2.new(1, -114, 1, -38); contentZone.Position = UDim2.new(0, 114, 0, 38)
    contentZone.BackgroundTransparency = 1; contentZone.BorderSizePixel = 0
    contentZone.ClipsDescendants = true; contentZone.Parent = main

    -- ── Перетаскивание ────────────────────────────────────────
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

    -- ── Клавиша G ─────────────────────────────────────────────
    UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Enum.KeyCode.G then W:Toggle() end
    end)

    -- ── Window:Toggle ─────────────────────────────────────────
    function W:Toggle(force)
        local show = (force ~= nil) and force or not W._visible
        W._visible = show
        if show then
            main.Visible = true
            tw(main, {
                BackgroundTransparency = 0,
                Size     = UDim2.new(0, WIN_W, 0, WIN_H),
                Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
            }, 0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            tw(main, {
                BackgroundTransparency = 1,
                Size     = UDim2.new(0, WIN_W*0.85, 0, WIN_H*0.85),
                Position = UDim2.new(0.5, -(WIN_W*0.85)/2, 0.5, -(WIN_H*0.85)/2),
            }, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.2, function() main.Visible = false end)
            if W._fullscreen then tw(blurFX, { Size = 0 }, 0.2) end
            if W._playerPanel then W._playerPanel.Frame.Visible = false end
        end
    end

    -- ── Window:ToggleFullscreen ────────────────────────────────
    function W:ToggleFullscreen()
        W._fullscreen = not W._fullscreen
        if W._fullscreen then
            tw(main, { Size = UDim2.new(0, FULL_W, 0, FULL_H),
                Position = UDim2.new(0.5, -FULL_W/2, 0.5, -FULL_H/2) }, 0.3, Enum.EasingStyle.Quart)
            tw(blurFX, { Size = 16 }, 0.3)
        else
            tw(main, { Size = UDim2.new(0, WIN_W, 0, WIN_H),
                Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2) }, 0.3, Enum.EasingStyle.Back)
            tw(blurFX, { Size = 0 }, 0.3)
        end
    end

    -- ── Window:Destroy ────────────────────────────────────────
    function W:Destroy()
        tw(blurFX, { Size = 0 }, 0.18)
        tw(main, { BackgroundTransparency = 1 }, 0.18)
        task.delay(0.2, function() sg:Destroy(); blurFX:Destroy() end)
    end

    -- ════════════════════════════════════════════════════════════
    -- ПАНЕЛЬ ИГРОКОВ (справа от основного окна)
    -- ════════════════════════════════════════════════════════════
    local playerPanelFrame = Instance.new("Frame")
    playerPanelFrame.Name             = "PlayerPanel"
    playerPanelFrame.Size             = UDim2.new(0, PANEL_W, 0, WIN_H)
    playerPanelFrame.BackgroundColor3 = C.PLAYER_BG
    playerPanelFrame.BorderSizePixel  = 0
    playerPanelFrame.Visible          = false
    playerPanelFrame.ZIndex           = 5
    playerPanelFrame.Parent           = sg
    corner(playerPanelFrame, UDim.new(0, 10))
    uistroke(playerPanelFrame, C.BORDER, 1.5)

    -- Заголовок панели
    local ppTitle = Instance.new("Frame")
    ppTitle.Size = UDim2.new(1, 0, 0, 36); ppTitle.BackgroundColor3 = C.PANEL
    ppTitle.BorderSizePixel = 0; ppTitle.Parent = playerPanelFrame
    corner(ppTitle, UDim.new(0, 10))
    local ppTitleFix = Instance.new("Frame")
    ppTitleFix.Size = UDim2.new(1, 0, 0, 14); ppTitleFix.Position = UDim2.new(0, 0, 1, -14)
    ppTitleFix.BackgroundColor3 = C.PANEL; ppTitleFix.BorderSizePixel = 0; ppTitleFix.Parent = ppTitle
    lbl(ppTitle, "👥 Игроки", 13, Enum.TextXAlignment.Center).Size = UDim2.new(1, 0, 1, 0)

    local ppDivider = Instance.new("Frame")
    ppDivider.Size = UDim2.new(1, 0, 0, 1); ppDivider.Position = UDim2.new(0, 0, 0, 36)
    ppDivider.BackgroundColor3 = C.BORDER; ppDivider.BorderSizePixel = 0; ppDivider.Parent = playerPanelFrame

    -- Скролл-зона игроков
    local ppScroll = Instance.new("ScrollingFrame")
    ppScroll.Size                = UDim2.new(1, 0, 1, -38)
    ppScroll.Position            = UDim2.new(0, 0, 0, 38)
    ppScroll.BackgroundTransparency = 1
    ppScroll.BorderSizePixel     = 0
    ppScroll.ScrollBarThickness  = 3
    ppScroll.ScrollBarImageColor3 = C.BORDER
    ppScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
    ppScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ppScroll.Parent              = playerPanelFrame

    local ppList = Instance.new("UIListLayout")
    ppList.Padding = UDim.new(0, 4); ppList.SortOrder = Enum.SortOrder.LayoutOrder
    ppList.Parent = ppScroll
    local ppPad = Instance.new("UIPadding")
    ppPad.PaddingTop = UDim.new(0, 4); ppPad.PaddingLeft = UDim.new(0, 6)
    ppPad.PaddingRight = UDim.new(0, 6); ppPad.Parent = ppScroll

    -- Положение панели (правее main)
    local function updatePanelPos()
        local mx = main.AbsolutePosition.X + main.AbsoluteSize.X
        local my = main.AbsolutePosition.Y
        playerPanelFrame.Position = UDim2.new(0, mx + 6, 0, my)
        playerPanelFrame.Size     = UDim2.new(0, PANEL_W, 0, main.AbsoluteSize.Y)
    end

    -- Кнопки в ячейке игрока (callback получает имя игрока)
    local playerBtnCallbacks = {}

    local PP = {}
    W._playerPanel = { Frame = playerPanelFrame, Scroll = ppScroll, Obj = PP }

    -- Добавить действие для кнопок игрока
    function PP:OnPlayerAction(cb)
        table.insert(playerBtnCallbacks, cb)
    end

    -- Обновить список игроков
    function PP:Refresh()
        -- Удалить старые строки
        for _, c in ipairs(ppScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local order = 0
        for _, player in ipairs(Players:GetPlayers()) do
            order = order + 1
            local row = Instance.new("Frame")
            row.Size             = UDim2.new(1, 0, 0, 46)
            row.BackgroundColor3 = C.PANEL
            row.BorderSizePixel  = 0
            row.LayoutOrder      = order
            row.Parent           = ppScroll
            corner(row, UDim.new(0, 5))
            uistroke(row, Color3.fromRGB(50, 10, 10), 1)

            -- Аватар
            local avatarImg = Instance.new("ImageLabel")
            avatarImg.Size             = UDim2.new(0, 34, 0, 34)
            avatarImg.Position         = UDim2.new(0, 6, 0.5, -17)
            avatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            avatarImg.BorderSizePixel  = 0
            avatarImg.Parent           = row
            corner(avatarImg, UDim.new(1, 0))

            -- Загрузить аватар
            local ok, thumbUrl = pcall(function()
                return Players:GetUserThumbnailAsync(
                    player.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48
                )
            end)
            if ok and thumbUrl then avatarImg.Image = thumbUrl end

            -- Имя
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size             = UDim2.new(1, -100, 1, 0)
            nameLbl.Position         = UDim2.new(0, 46, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text             = player.Name
            nameLbl.Font             = Enum.Font.GothamBold
            nameLbl.TextSize         = 11
            nameLbl.TextColor3       = C.TEXT
            nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
            nameLbl.TextTruncate     = Enum.TextTruncate.AtEnd
            nameLbl.Parent           = row

            -- Кнопка действия
            local actBtn = Instance.new("TextButton")
            actBtn.Size             = UDim2.new(0, 42, 0, 22)
            actBtn.Position         = UDim2.new(1, -48, 0.5, -11)
            actBtn.BackgroundColor3 = C.ACCENT_DIM
            actBtn.BorderSizePixel  = 0
            actBtn.Text             = "···"
            actBtn.TextColor3       = C.TEXT
            actBtn.Font             = Enum.Font.GothamBold
            actBtn.TextSize         = 11
            actBtn.Parent           = row
            corner(actBtn, UDim.new(0, 4))
            uistroke(actBtn, C.BORDER, 1)

            actBtn.MouseEnter:Connect(function() tw(actBtn,{BackgroundColor3=C.ACCENT},0.1) end)
            actBtn.MouseLeave:Connect(function() tw(actBtn,{BackgroundColor3=C.ACCENT_DIM},0.1) end)
            actBtn.MouseButton1Click:Connect(function()
                pulse(actBtn, C.ACCENT_DIM)
                for _, cb in ipairs(playerBtnCallbacks) do cb(player) end
            end)
        end
    end

    -- ── Window:TogglePlayerPanel ───────────────────────────────
    local ppVisible = false
    function W:TogglePlayerPanel()
        ppVisible = not ppVisible
        if ppVisible then
            updatePanelPos()
            PP:Refresh()
            playerPanelFrame.Visible = true
            playerPanelFrame.BackgroundTransparency = 1
            tw(playerPanelFrame, { BackgroundTransparency = 0 }, 0.2)
        else
            tw(playerPanelFrame, { BackgroundTransparency = 1 }, 0.18)
            task.delay(0.2, function() playerPanelFrame.Visible = false end)
        end
    end

    -- Обновлять позицию панели при движении окна
    RunService.RenderStepped:Connect(function()
        if ppVisible and playerPanelFrame.Visible then
            updatePanelPos()
        end
    end)

    -- ════════════════════════════════════════════════════════════
    --  Window:AddTab(name)
    -- ════════════════════════════════════════════════════════════
    function W:AddTab(name)
        local Tab = { _order = 0 }

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 28); tabBtn.BackgroundColor3 = C.TAB_IDLE
        tabBtn.BorderSizePixel = 0; tabBtn.Text = ""; tabBtn.AutoButtonColor = false
        tabBtn.LayoutOrder = #W._tabs + 1; tabBtn.Parent = tabPanel
        corner(tabBtn, UDim.new(0, 5))

        local tabAcc = Instance.new("Frame")
        tabAcc.Size = UDim2.new(0, 2, 0.6, 0); tabAcc.Position = UDim2.new(0, 0, 0.2, 0)
        tabAcc.BackgroundColor3 = C.ACCENT; tabAcc.BorderSizePixel = 0
        tabAcc.BackgroundTransparency = 1; tabAcc.Parent = tabBtn
        corner(tabAcc, UDim.new(0, 2))

        lbl(tabBtn, name, 12, Enum.TextXAlignment.Center)

        tabBtn.MouseEnter:Connect(function()
            if tabBtn.BackgroundColor3 ~= C.TAB_ACTIVE then tw(tabBtn,{BackgroundColor3=C.TAB_HOVER},0.1) end
        end)
        tabBtn.MouseLeave:Connect(function()
            if tabBtn.BackgroundColor3 ~= C.TAB_ACTIVE then tw(tabBtn,{BackgroundColor3=C.TAB_IDLE},0.1) end
        end)

        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, -8, 1, -8); frame.Position = UDim2.new(0, 4, 0, 4)
        frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 3; frame.ScrollBarImageColor3 = C.BORDER
        frame.CanvasSize = UDim2.new(0, 0, 0, 0); frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Visible = false; frame.Parent = contentZone

        local contentList = Instance.new("UIListLayout")
        contentList.Padding = UDim.new(0, 5); contentList.SortOrder = Enum.SortOrder.LayoutOrder
        contentList.FillDirection = Enum.FillDirection.Vertical; contentList.Wraps = true
        contentList.Parent = frame

        local cPad = Instance.new("UIPadding")
        cPad.PaddingTop = UDim.new(0, 4); cPad.PaddingBottom = UDim.new(0, 4)
        cPad.PaddingLeft = UDim.new(0, 4); cPad.PaddingRight = UDim.new(0, 4)
        cPad.Parent = frame

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

        local function row(h)
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, 0, 0, h or 32)
            r.BackgroundTransparency = 1; r.BorderSizePixel = 0
            Tab._order = Tab._order + 1; r.LayoutOrder = Tab._order
            r.Parent = frame
            return r
        end

        -- ─────────────────────────────────────────────────────
        -- AddButton
        -- ─────────────────────────────────────────────────────
        function Tab:AddButton(text, callback)
            local r   = row(32)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundColor3 = C.ACCENT_DIM
            btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = r
            corner(btn, UDim.new(0, 6)); uistroke(btn, C.BORDER, 1)

            local l = lbl(btn, text, TXTSZ, Enum.TextXAlignment.Center)
            l.Size = UDim2.new(1, 0, 1, 0)

            -- ФИКС: не анимируем UIGradient.Transparency через TweenService —
            -- просто меняем BackgroundColor3 кнопки
            btn.MouseEnter:Connect(function()
                tw(btn, { BackgroundColor3 = C.ACCENT }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                tw(btn, { BackgroundColor3 = C.ACCENT_DIM }, 0.12)
            end)
            btn.MouseButton1Click:Connect(function()
                pulse(btn, C.ACCENT_DIM)
                if callback then callback() end
            end)
            return btn
        end

        -- ─────────────────────────────────────────────────────
        -- AddToggle — сохраняет состояние в W.SavedValues[id]
        -- ─────────────────────────────────────────────────────
        function Tab:AddToggle(text, default, callback, id)
            local r     = row(32)
            local state = default or false
            local saveKey = id or text

            W.SavedValues[saveKey] = state

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)

            lbl(bg, text, TXTSZ).Size = UDim2.new(1, -66, 1, 0)
            local ll = bg:FindFirstChildWhichIsA("TextLabel")
            if ll then ll.Position = UDim2.new(0, 10, 0, 0) end

            local pill = Instance.new("Frame")
            pill.Size = UDim2.new(0, 44, 0, 22); pill.Position = UDim2.new(1, -52, 0.5, -11)
            pill.BackgroundColor3 = state and C.ACCENT or C.ACCENT_DIM
            pill.BorderSizePixel = 0; pill.Parent = bg
            corner(pill, UDim.new(1, 0)); uistroke(pill, C.BORDER, 1)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
            knob.BorderSizePixel = 0; knob.Parent = pill
            corner(knob, UDim.new(1, 0))

            local hitBtn = Instance.new("TextButton")
            hitBtn.Size = UDim2.new(1, 0, 1, 0); hitBtn.BackgroundTransparency = 1
            hitBtn.Text = ""; hitBtn.Parent = bg

            local function applyState(v)
                state = v; W.SavedValues[saveKey] = v
                -- ФИКС: только BackgroundColor3, не UIGradient
                tw(pill,  { BackgroundColor3 = v and C.ACCENT or C.ACCENT_DIM }, 0.15)
                tw(knob,  { Position = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) },
                   0.15, Enum.EasingStyle.Back)
                if callback then callback(v) end
            end

            hitBtn.MouseButton1Click:Connect(function() applyState(not state) end)

            local Toggle = {}
            function Toggle:Set(v) applyState(v) end
            function Toggle:Get() return state end
            return Toggle
        end

        -- ─────────────────────────────────────────────────────
        -- AddCheckbox — галочка с сохранением
        -- ─────────────────────────────────────────────────────
        function Tab:AddCheckbox(text, default, callback, id)
            local r     = row(30)
            local state = default or false
            local saveKey = id or ("cb_" .. text)

            W.SavedValues[saveKey] = state

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)

            -- Квадрат-чекбокс
            local box = Instance.new("Frame")
            box.Size             = UDim2.new(0, 18, 0, 18)
            box.Position         = UDim2.new(0, 8, 0.5, -9)
            box.BackgroundColor3 = state and C.CHECK_ON or C.CHECK_OFF
            box.BorderSizePixel  = 0; box.Parent = bg
            corner(box, UDim.new(0, 4))
            uistroke(box, C.BORDER, 1)

            -- Галочка
            local checkIcon = Instance.new("TextLabel")
            checkIcon.Size = UDim2.new(1, 0, 1, 0); checkIcon.BackgroundTransparency = 1
            checkIcon.Text = "✓"; checkIcon.Font = Enum.Font.GothamBold
            checkIcon.TextSize = 12; checkIcon.TextColor3 = Color3.new(1,1,1)
            checkIcon.TextXAlignment = Enum.TextXAlignment.Center
            checkIcon.TextTransparency = state and 0 or 1
            checkIcon.Parent = box

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -34, 1, 0); nameLbl.Position = UDim2.new(0, 32, 0, 0)
            nameLbl.BackgroundTransparency = 1; nameLbl.Text = text
            nameLbl.Font = FONT; nameLbl.TextSize = TXTSZ; nameLbl.TextColor3 = C.TEXT
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Parent = bg

            local hitBtn = Instance.new("TextButton")
            hitBtn.Size = UDim2.new(1, 0, 1, 0); hitBtn.BackgroundTransparency = 1
            hitBtn.Text = ""; hitBtn.Parent = bg

            local function applyState(v)
                state = v; W.SavedValues[saveKey] = v
                tw(box, { BackgroundColor3 = v and C.CHECK_ON or C.CHECK_OFF }, 0.12)
                tw(checkIcon, { TextTransparency = v and 0 or 1 }, 0.1)
                if callback then callback(v) end
            end

            hitBtn.MouseButton1Click:Connect(function() applyState(not state) end)

            local Checkbox = {}
            function Checkbox:Set(v) applyState(v) end
            function Checkbox:Get() return state end
            return Checkbox
        end

        -- ─────────────────────────────────────────────────────
        -- AddSlider — ФИКС: sliding не сбрасывает callback при отпускании
        -- ─────────────────────────────────────────────────────
        function Tab:AddSlider(text, minVal, maxVal, default, callback, id)
            minVal  = minVal  or 0
            maxVal  = maxVal  or 100
            default = default or minVal
            local val     = math.clamp(default, minVal, maxVal)
            local saveKey = id or ("sl_" .. text)
            W.SavedValues[saveKey] = val

            local r  = row(52)
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)

            local topRow = Instance.new("Frame")
            topRow.Size = UDim2.new(1, 0, 0, 26); topRow.BackgroundTransparency = 1
            topRow.BorderSizePixel = 0; topRow.Parent = bg

            local nameLbl = lbl(topRow, text, TXTSZ)
            nameLbl.Size = UDim2.new(1, -54, 1, 0); nameLbl.Position = UDim2.new(0, 10, 0, 0)

            local valBox = Instance.new("Frame")
            valBox.Size = UDim2.new(0, 40, 0, 18); valBox.Position = UDim2.new(1, -46, 0.5, -9)
            valBox.BackgroundColor3 = C.ACCENT_DIM; valBox.BorderSizePixel = 0; valBox.Parent = topRow
            corner(valBox, UDim.new(0, 4)); uistroke(valBox, C.BORDER, 1)
            local valLbl = lbl(valBox, tostring(val), 12, Enum.TextXAlignment.Center)
            valLbl.Size = UDim2.new(1, 0, 1, 0)

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -16, 0, 10); track.Position = UDim2.new(0, 8, 0, 33)
            track.BackgroundColor3 = C.SLIDER_BG; track.BorderSizePixel = 0; track.Parent = bg
            corner(track, UDim.new(1, 0)); uistroke(track, C.BORDER, 1)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((val - minVal)/(maxVal - minVal), 0, 1, 0)
            fill.BackgroundColor3 = C.ACCENT; fill.BorderSizePixel = 0; fill.Parent = track
            corner(fill, UDim.new(1, 0))

            -- Градиент на заполнении
            local fillGrad = Instance.new("UIGradient")
            fillGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160,  0,  0)),
            })
            fillGrad.Parent = fill

            local thumb = Instance.new("Frame")
            thumb.Size = UDim2.new(0, 14, 0, 14)
            thumb.Position = UDim2.new((val - minVal)/(maxVal - minVal), -7, 0.5, -7)
            thumb.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
            thumb.BorderSizePixel = 0; thumb.ZIndex = 4; thumb.Parent = track
            corner(thumb, UDim.new(1, 0))

            local hitArea = Instance.new("TextButton")
            hitArea.Size = UDim2.new(1, 10, 3, 0); hitArea.Position = UDim2.new(0, -5, -1, 0)
            hitArea.BackgroundTransparency = 1; hitArea.Text = ""; hitArea.ZIndex = 5
            hitArea.Parent = track

            local sliding = false

            local function setVal(x)
                local relX = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local newVal = math.floor(minVal + relX * (maxVal - minVal) + 0.5)
                if newVal == val then return end
                val = newVal; W.SavedValues[saveKey] = val
                local frac = (val - minVal) / (maxVal - minVal)
                -- Напрямую, без tw — мгновенный отклик при перетаскивании
                fill.Size      = UDim2.new(frac, 0, 1, 0)
                thumb.Position = UDim2.new(frac, -7, 0.5, -7)
                valLbl.Text    = tostring(val)
                if callback then callback(val) end
            end

            -- ФИКС InputBegan/Changed/Ended — sliding сбрасывается только на InputEnded MouseButton1
            hitArea.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true; setVal(inp.Position.X)
                end
            end)
            -- Слушаем глобально, чтобы не терять события при выходе за пределы hitArea
            UserInputService.InputChanged:Connect(function(inp)
                if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    setVal(inp.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and sliding then
                    sliding = false
                    -- callback уже был вызван в setVal, НЕ вызываем повторно
                end
            end)

            local Slider = {}
            function Slider:Set(v)
                val = math.clamp(v, minVal, maxVal); W.SavedValues[saveKey] = val
                local frac = (val - minVal) / (maxVal - minVal)
                fill.Size = UDim2.new(frac, 0, 1, 0); thumb.Position = UDim2.new(frac, -7, 0.5, -7)
                valLbl.Text = tostring(val)
                if callback then callback(val) end
            end
            function Slider:Get() return val end
            return Slider
        end

        -- ─────────────────────────────────────────────────────
        -- AddTextBox — поле ввода текста
        -- ─────────────────────────────────────────────────────
        function Tab:AddTextBox(placeholderText, callback, id)
            local r       = row(36)
            local saveKey = id or ("tb_" .. placeholderText)
            W.SavedValues[saveKey] = ""

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.INPUT_BG
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)

            local tb = Instance.new("TextBox")
            tb.Size = UDim2.new(1, -12, 1, -8); tb.Position = UDim2.new(0, 6, 0, 4)
            tb.BackgroundTransparency = 1; tb.BorderSizePixel = 0
            tb.Text = ""; tb.PlaceholderText = placeholderText or "Введите текст..."
            tb.Font = FONTREG; tb.TextSize = TXTSZ; tb.TextColor3 = C.TEXT
            tb.PlaceholderColor3 = C.TEXT_DIM; tb.TextXAlignment = Enum.TextXAlignment.Left
            tb.ClearTextOnFocus = false; tb.Parent = bg

            -- Подсветка при фокусе
            local inputStroke = uistroke(bg, C.BORDER, 1)
            tb.Focused:Connect(function()
                tw(inputStroke, { Color = C.ACCENT, Thickness = 1.5 }, 0.12)
            end)
            tb.FocusLost:Connect(function(enterPressed)
                tw(inputStroke, { Color = C.BORDER, Thickness = 1 }, 0.12)
                W.SavedValues[saveKey] = tb.Text
                if callback then callback(tb.Text, enterPressed) end
            end)

            local TextBox = {}
            function TextBox:Get() return tb.Text end
            function TextBox:Set(v) tb.Text = v or ""; W.SavedValues[saveKey] = tb.Text end
            function TextBox:Clear() tb.Text = ""; W.SavedValues[saveKey] = "" end
            return TextBox
        end

        -- ─────────────────────────────────────────────────────
        -- AddDropdown — выпадающий список
        -- ─────────────────────────────────────────────────────
        function Tab:AddDropdown(titleText, options, callback, id)
            options = options or {}
            local saveKey  = id or ("dd_" .. titleText)
            local selected = options[1] or "—"
            local open     = false
            W.SavedValues[saveKey] = selected

            -- Высота: шапка 32 + список 28*n при раскрытии
            local itemH = 26
            local r = row(32)

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)
            bg.ClipsDescendants = true

            -- Шапка
            local header = Instance.new("TextButton")
            header.Size = UDim2.new(1, 0, 0, 32); header.BackgroundTransparency = 1
            header.BorderSizePixel = 0; header.Text = ""; header.Parent = bg

            local titleL = lbl(header, titleText, TXTSZ)
            titleL.Size = UDim2.new(0.5, -4, 1, 0); titleL.Position = UDim2.new(0, 10, 0, 0)

            local selL = lbl(header, selected, TXTSZ, Enum.TextXAlignment.Right, C.TEXT_DIM)
            selL.Size = UDim2.new(0.5, -24, 1, 0); selL.Position = UDim2.new(0.5, 0, 0, 0)

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 1, 0); arrow.Position = UDim2.new(1, -22, 0, 0)
            arrow.BackgroundTransparency = 1; arrow.Text = "▾"
            arrow.Font = FONT; arrow.TextSize = 12; arrow.TextColor3 = C.ACCENT
            arrow.TextXAlignment = Enum.TextXAlignment.Center; arrow.Parent = header

            -- Список опций
            local listFrame = Instance.new("Frame")
            listFrame.Size = UDim2.new(1, 0, 0, #options * itemH)
            listFrame.Position = UDim2.new(0, 0, 0, 32)
            listFrame.BackgroundTransparency = 1; listFrame.BorderSizePixel = 0
            listFrame.Visible = false; listFrame.Parent = bg

            local listLayout2 = Instance.new("UIListLayout")
            listLayout2.Padding = UDim.new(0, 0); listLayout2.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout2.Parent = listFrame

            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, itemH); optBtn.BackgroundColor3 = C.DROP_BG
                optBtn.BorderSizePixel = 0; optBtn.Text = ""; optBtn.LayoutOrder = i; optBtn.Parent = listFrame

                local optL = lbl(optBtn, opt, 12, Enum.TextXAlignment.Left, C.TEXT)
                optL.Size = UDim2.new(1, -10, 1, 0); optL.Position = UDim2.new(0, 10, 0, 0)

                optBtn.MouseEnter:Connect(function() tw(optBtn,{BackgroundColor3=C.ACCENT_DIM},0.08) end)
                optBtn.MouseLeave:Connect(function() tw(optBtn,{BackgroundColor3=C.DROP_BG},0.08) end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt; selL.Text = opt
                    W.SavedValues[saveKey] = opt
                    if callback then callback(opt) end
                    open = false
                    tw(r, { Size = UDim2.new(1, 0, 0, 32) }, 0.15, Enum.EasingStyle.Quart)
                    tw(bg, { Size = UDim2.new(1, 0, 1, 0) }, 0.15)
                    task.delay(0.15, function() listFrame.Visible = false end)
                    tw(arrow, { Rotation = 0 }, 0.15)
                end)
            end

            header.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    listFrame.Visible = true
                    local newH = 32 + #options * itemH
                    tw(r, { Size = UDim2.new(1, 0, 0, newH) }, 0.18, Enum.EasingStyle.Quart)
                    tw(bg, { Size = UDim2.new(1, 0, 0, newH) }, 0.18)
                    tw(arrow, { Rotation = 180 }, 0.15)
                else
                    tw(r, { Size = UDim2.new(1, 0, 0, 32) }, 0.15)
                    tw(bg, { Size = UDim2.new(1, 0, 1, 0) }, 0.15)
                    task.delay(0.15, function() listFrame.Visible = false end)
                    tw(arrow, { Rotation = 0 }, 0.15)
                end
            end)

            local Dropdown = {}
            function Dropdown:Get() return selected end
            function Dropdown:Set(v)
                selected = v; selL.Text = v; W.SavedValues[saveKey] = v
                if callback then callback(v) end
            end
            function Dropdown:SetOptions(newOpts)
                -- Пересоздание опций не реализовано упрощённо — передайте новый AddDropdown
                options = newOpts
            end
            return Dropdown
        end

        -- ─────────────────────────────────────────────────────
        -- AddLabel / AddSeparator
        -- ─────────────────────────────────────────────────────
        function Tab:AddLabel(text)
            local r  = row(24)
            local bg = Instance.new("Frame"); bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundTransparency = 1; bg.Parent = r
            local l = lbl(bg, text, TXTSZ, Enum.TextXAlignment.Left, C.TEXT_DIM)
            l.Position = UDim2.new(0, 10, 0, 0)
            return l
        end

        function Tab:AddSeparator()
            local r = row(12)
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, -20, 0, 1); line.Position = UDim2.new(0, 10, 0.5, 0)
            line.BackgroundColor3 = C.BORDER; line.BorderSizePixel = 0; line.Parent = r
            corner(line, UDim.new(1, 0))
        end

        return Tab
    end

    return W
end

return ShadowLib

--[[
══════════════════════════════════════════════════════════════
  ПРИМЕР v3
══════════════════════════════════════════════════════════════

local ShadowLib = loadstring(game:HttpGet("URL"))()
local win = ShadowLib:CreateWindow("☠ Shadow UI")

-- G   = показать / скрыть
-- ⛶   = полный экран
-- ✕   = скрыть
-- ☰   = открыть/закрыть панель игроков справа

local tab1 = win:AddTab("⚔ Бой")
local tab2 = win:AddTab("👁 Визуал")
local tab3 = win:AddTab("⚙ Прочее")

tab1:AddLabel("Боевые настройки")
tab1:AddSeparator()

-- Кнопка (повторно нажимается)
tab1:AddButton("Убить всех", function() print("Атака!") end)

-- Тоггл (сохраняет состояние)
local aim = tab1:AddToggle("Аимбот", false, function(v) print("Aim:", v) end, "aim")

-- Чекбокс
local wb = tab1:AddCheckbox("Стены", false, function(v) print("Wallbang:", v) end, "wb")

-- Слайдер (1–100, нет краша при отпускании)
local fov = tab1:AddSlider("FOV", 1, 100, 60, function(v) print("FOV:", v) end, "fov")

-- Текстбокс
local reason = tab3:AddTextBox("Причина бана...", function(text, enter)
    if enter then print("Причина:", text) end
end, "ban_reason")

-- Дропдаун
local mode = tab3:AddDropdown("Режим", {"Kill", "Kick", "Ban", "Teleport"}, function(v)
    print("Выбрано:", v)
end, "mode_select")

-- Панель игроков
local pp = win._playerPanel.Obj
pp:OnPlayerAction(function(player)
    print("Нажато на игрока:", player.Name)
    -- Пример: применить выбранный режим
end)

-- Читать сохранённые значения в любой момент:
-- print(win.SavedValues)  -- { aim=false, wb=false, fov=60, ban_reason="", mode_select="Kill" }
-- print(fov:Get())
-- aim:Set(true)

══════════════════════════════════════════════════════════════
]]
