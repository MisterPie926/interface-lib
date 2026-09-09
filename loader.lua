-- ╔══════════════════════════════════════════════════════════╗
-- ║         SHADOW UI LIBRARY  v3.1  •  by Claude           ║
-- ║  G = открыть/скрыть  •  ⛶ = полный экран  •  ✕ = закрыть
-- ╚══════════════════════════════════════════════════════════╝
-- Что нового в v3.1:
--   • Полноценное окно списка игроков (PlayerList)
--   • Плавный поиск/фильтр элементов
--   • Система уведомлений
--   • Элемент Keybind (горячая клавиша) с сохранением
--   • Модальные окна подтверждения
--   • Мобильная адаптивность
--   • Темы оформления (4 встроенные)
--   • Индикатор FPS и пинга
--   • Подсказки (тултипы)
--   • Все предыдущие функции v3 сохранены

local ShadowLib = {}
ShadowLib.__index = ShadowLib

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local HttpService      = game:GetService("HttpService")

-- ── Цвета (базовая тема Shadow Red) ─────────────────────────
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
    TEXT       = Color3.fromRGB(240, 240, 240),
    TEXT_DIM   = Color3.fromRGB(160, 160, 160),
    CHECK_ON   = Color3.fromRGB(220,  0,   0),
    CHECK_OFF  = Color3.fromRGB(40,  40,  40),
    INPUT_BG   = Color3.fromRGB(14,  14,  14),
    DROP_BG    = Color3.fromRGB(18,  18,  18),
    CTRL_CL    = Color3.fromRGB(220, 60,  60),
    CTRL_FS    = Color3.fromRGB(90, 180, 255),
    PLAYER_BG  = Color3.fromRGB(16,  16,  16),
}

-- Темы
local Themes = {
    ["Shadow Red"] = {
        BORDER     = Color3.fromRGB(180,  0,   0),
        ACCENT     = Color3.fromRGB(220,  0,   0),
        ACCENT_DIM = Color3.fromRGB(50,  10,  10),
        SLIDER_BG  = Color3.fromRGB(35,  10,  10),
        TAB_ACTIVE = Color3.fromRGB(150,  0,   0),
        TAB_HOVER  = Color3.fromRGB(40,  12,  12),
        CTRL_CL    = Color3.fromRGB(220, 60,  60),
    },
    ["Ocean Blue"] = {
        BORDER     = Color3.fromRGB(0,  120, 200),
        ACCENT     = Color3.fromRGB(0,  150, 255),
        ACCENT_DIM = Color3.fromRGB(10, 30,  60),
        SLIDER_BG  = Color3.fromRGB(10, 30,  60),
        TAB_ACTIVE = Color3.fromRGB(0,  100, 180),
        TAB_HOVER  = Color3.fromRGB(12, 40,  80),
        CTRL_CL    = Color3.fromRGB(255, 80,  80),
    },
    ["Toxic Green"] = {
        BORDER     = Color3.fromRGB(100, 200, 0),
        ACCENT     = Color3.fromRGB(150, 255, 0),
        ACCENT_DIM = Color3.fromRGB(20, 50,  0),
        SLIDER_BG  = Color3.fromRGB(20, 50,  0),
        TAB_ACTIVE = Color3.fromRGB(80, 160, 0),
        TAB_HOVER  = Color3.fromRGB(30, 60,  10),
        CTRL_CL    = Color3.fromRGB(255, 100, 100),
    },
    ["Purple"] = {
        BORDER     = Color3.fromRGB(150, 0, 220),
        ACCENT     = Color3.fromRGB(180, 0, 255),
        ACCENT_DIM = Color3.fromRGB(30, 10,  50),
        SLIDER_BG  = Color3.fromRGB(30, 10,  50),
        TAB_ACTIVE = Color3.fromRGB(120, 0, 180),
        TAB_HOVER  = Color3.fromRGB(40, 15,  70),
        CTRL_CL    = Color3.fromRGB(255, 80,  80),
    },
}

local FONT     = Enum.Font.GothamBold
local FONTREG  = Enum.Font.Gotham
local TXTSZ    = 13
local WIN_W, WIN_H     = 420, 340
local FULL_W, FULL_H   = 720, 520
local PANEL_W          = 200   -- ширина панели игроков

-- Мобильная адаптивность
if UserInputService.TouchEnabled then
    WIN_W, WIN_H = 520, 400
    FULL_W, FULL_H = 900, 620
    PANEL_W = 240
    TXTSZ = 14
end

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

-- ── Уведомления ─────────────────────────────────────────────
local notificationGui
local function createNotificationGui()
    if notificationGui then return notificationGui end
    notificationGui = Instance.new("ScreenGui")
    notificationGui.Name = "ShadowNotifications"
    notificationGui.ResetOnSpawn = false
    notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notificationGui.IgnoreGuiInset = true
    notificationGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    return notificationGui
end

-- ── Тултип ──────────────────────────────────────────────────
local tooltipFrame
local function showTooltip(text, anchor)
    if not tooltipFrame then
        tooltipFrame = Instance.new("Frame")
        tooltipFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tooltipFrame.BorderSizePixel = 0
        tooltipFrame.Visible = false
        tooltipFrame.ZIndex = 10
        tooltipFrame.Parent = createNotificationGui()
        corner(tooltipFrame, UDim.new(0, 6))
        uistroke(tooltipFrame, C.BORDER, 1)
        local tipLabel = lbl(tooltipFrame, "", 12, Enum.TextXAlignment.Center, C.TEXT)
        tipLabel.Name = "TipLabel"
        tipLabel.Size = UDim2.new(1, 0, 1, 0)
    end
    local label = tooltipFrame:FindFirstChild("TipLabel")
    label.Text = text
    tooltipFrame.Size = UDim2.new(0, label.TextBounds.X + 20, 0, 24)
    tooltipFrame.Position = UDim2.new(0, anchor.AbsolutePosition.X + anchor.AbsoluteSize.X/2 - tooltipFrame.AbsoluteSize.X/2, 0, anchor.AbsolutePosition.Y - 30)
    tooltipFrame.Visible = true
    return tooltipFrame
end
local function hideTooltip()
    if tooltipFrame then tooltipFrame.Visible = false end
end

-- ══════════════════════════════════════════════════════════════
function ShadowLib:CreateWindow(title)
    local W = {
        _tabs      = {},
        _tabBtns   = {},
        _visible   = true,
        _fullscreen = false,
        _playerPanel = nil,
        SavedValues = {},
        Keybinds   = {},
        _theme     = "Shadow Red",
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
    -- ПАНЕЛЬ ИГРОКОВ (справа от основного окна) — сохранено из v3
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

    local function updatePanelPos()
        local mx = main.AbsolutePosition.X + main.AbsoluteSize.X
        local my = main.AbsolutePosition.Y
        playerPanelFrame.Position = UDim2.new(0, mx + 6, 0, my)
        playerPanelFrame.Size     = UDim2.new(0, PANEL_W, 0, main.AbsoluteSize.Y)
    end

    local playerBtnCallbacks = {}
    local PP = {}
    W._playerPanel = { Frame = playerPanelFrame, Scroll = ppScroll, Obj = PP }

    function PP:OnPlayerAction(cb)
        table.insert(playerBtnCallbacks, cb)
    end

    function PP:Refresh()
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

            local avatarImg = Instance.new("ImageLabel")
            avatarImg.Size             = UDim2.new(0, 34, 0, 34)
            avatarImg.Position         = UDim2.new(0, 6, 0.5, -17)
            avatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            avatarImg.BorderSizePixel  = 0
            avatarImg.Parent           = row
            corner(avatarImg, UDim.new(1, 0))

            local ok, thumbUrl = pcall(function()
                return Players:GetUserThumbnailAsync(
                    player.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48
                )
            end)
            if ok and thumbUrl then avatarImg.Image = thumbUrl end

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

    RunService.RenderStepped:Connect(function()
        if ppVisible and playerPanelFrame.Visible then
            updatePanelPos()
        end
    end)

    -- ════════════════════════════════════════════════════════════
    --  НОВОЕ: Отдельное окно PlayerList (по запросу)
    -- ════════════════════════════════════════════════════════════
    function W:CreatePlayerList()
        local plWindow = {}
        local plGui = Instance.new("ScreenGui")
        plGui.Name = "ShadowPlayerList"
        plGui.ResetOnSpawn = false
        plGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        plGui.IgnoreGuiInset = true
        plGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

        local plFrame = Instance.new("Frame")
        plFrame.Size = UDim2.new(0, 250, 0, 350)
        plFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
        plFrame.BackgroundColor3 = C.PLAYER_BG
        plFrame.BorderSizePixel = 0
        plFrame.Visible = true
        plFrame.Parent = plGui
        corner(plFrame, UDim.new(0, 8))
        uistroke(plFrame, C.BORDER, 1.5)

        local plTitleBar = Instance.new("Frame")
        plTitleBar.Size = UDim2.new(1, 0, 0, 30)
        plTitleBar.BackgroundColor3 = C.PANEL
        plTitleBar.BorderSizePixel = 0
        plTitleBar.Parent = plFrame
        corner(plTitleBar, UDim.new(0, 8))
        local plTitleLabel = lbl(plTitleBar, "Player List", 14, Enum.TextXAlignment.Center)
        plTitleLabel.Size = UDim2.new(1, 0, 1, 0)

        local closeBtn = ctrlBtn(plTitleBar, "✕", -30, C.CTRL_CL, function()
            plFrame.Visible = false
        end)

        local plScroll = Instance.new("ScrollingFrame")
        plScroll.Size = UDim2.new(1, 0, 1, -32)
        plScroll.Position = UDim2.new(0, 0, 0, 32)
        plScroll.BackgroundTransparency = 1
        plScroll.BorderSizePixel = 0
        plScroll.ScrollBarThickness = 3
        plScroll.ScrollBarImageColor3 = C.BORDER
        plScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        plScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        plScroll.Parent = plFrame

        local plLayout = Instance.new("UIListLayout")
        plLayout.Padding = UDim.new(0, 5)
        plLayout.SortOrder = Enum.SortOrder.LayoutOrder
        plLayout.Parent = plScroll

        local function refreshPlayers()
            for _, child in ipairs(plScroll:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            local i = 0
            for _, player in ipairs(Players:GetPlayers()) do
                i = i + 1
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 40)
                row.BackgroundColor3 = C.PANEL
                row.BorderSizePixel = 0
                row.LayoutOrder = i
                row.Parent = plScroll
                corner(row, UDim.new(0, 5))

                local avatar = Instance.new("ImageLabel")
                avatar.Size = UDim2.new(0, 30, 0, 30)
                avatar.Position = UDim2.new(0, 5, 0.5, -15)
                avatar.BackgroundColor3 = Color3.fromRGB(30,30,30)
                avatar.BorderSizePixel = 0
                avatar.Parent = row
                corner(avatar, UDim.new(1, 0))

                local ok, thumb = pcall(function()
                    return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok and thumb then avatar.Image = thumb end

                local nameLabel = lbl(row, player.Name, 12, Enum.TextXAlignment.Left)
                nameLabel.Size = UDim2.new(1, -40, 1, 0)
                nameLabel.Position = UDim2.new(0, 40, 0, 0)
            end
        end

        refreshPlayers()
        Players.PlayerAdded:Connect(refreshPlayers)
        Players.PlayerRemoving:Connect(refreshPlayers)

        function plWindow:Refresh() refreshPlayers() end
        function plWindow:Show() plFrame.Visible = true end
        function plWindow:Hide() plFrame.Visible = false end
        function plWindow:Destroy() plGui:Destroy() end

        return plWindow
    end

    -- ════════════════════════════════════════════════════════════
    --  НОВОЕ: Уведомления
    -- ════════════════════════════════════════════════════════════
    function W:Notify(titleText, messageText, duration)
        local gui = createNotificationGui()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 220, 0, 60)
        notif.Position = UDim2.new(1, -230, 1, -70)
        notif.BackgroundColor3 = C.PANEL
        notif.BorderSizePixel = 0
        notif.Parent = gui
        corner(notif, UDim.new(0, 8))
        uistroke(notif, C.BORDER, 1.5)
        notif.BackgroundTransparency = 1
        tw(notif, { BackgroundTransparency = 0 }, 0.2)

        local titleLabel = lbl(notif, titleText or "Уведомление", 13, Enum.TextXAlignment.Left)
        titleLabel.Size = UDim2.new(1, -20, 0, 20)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.TextColor3 = C.TEXT

        local msgLabel = lbl(notif, messageText or "", 12, Enum.TextXAlignment.Left)
        msgLabel.Size = UDim2.new(1, -20, 0, 30)
        msgLabel.Position = UDim2.new(0, 10, 0, 25)
        msgLabel.TextColor3 = C.TEXT_DIM
        msgLabel.TextWrapped = true

        task.delay(duration or 3, function()
            tw(notif, { BackgroundTransparency = 1, Position = UDim2.new(1, -230, 1, -70) + UDim2.new(0, 0, 0, -30) }, 0.3)
            task.delay(0.3, function() notif:Destroy() end)
        end)
    end

    -- ════════════════════════════════════════════════════════════
    --  НОВОЕ: Модальное окно подтверждения
    -- ════════════════════════════════════════════════════════════
    function W:Confirm(titleText, messageText, onYes, onNo)
        local gui = createNotificationGui()
        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.new(0, 0, 0)
        overlay.BackgroundTransparency = 0.6
        overlay.BorderSizePixel = 0
        overlay.Parent = gui
        overlay.ZIndex = 50

        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0, 300, 0, 120)
        modal.Position = UDim2.new(0.5, -150, 0.5, -60)
        modal.BackgroundColor3 = C.PANEL
        modal.BorderSizePixel = 0
        modal.Parent = overlay
        corner(modal, UDim.new(0, 8))
        uistroke(modal, C.BORDER, 1.5)
        modal.ZIndex = 51

        local mTitle = lbl(modal, titleText or "Подтверждение", 15, Enum.TextXAlignment.Center)
        mTitle.Size = UDim2.new(1, 0, 0, 30)
        mTitle.Position = UDim2.new(0, 0, 0, 10)

        local mMsg = lbl(modal, messageText or "Вы уверены?", 13, Enum.TextXAlignment.Center)
        mMsg.Size = UDim2.new(1, 0, 0, 40)
        mMsg.Position = UDim2.new(0, 0, 0, 40)
        mMsg.TextWrapped = true

        local yesBtn = Instance.new("TextButton")
        yesBtn.Size = UDim2.new(0, 100, 0, 30)
        yesBtn.Position = UDim2.new(0.5, -110, 1, -35)
        yesBtn.BackgroundColor3 = C.ACCENT
        yesBtn.BorderSizePixel = 0
        yesBtn.Text = "Да"
        yesBtn.TextColor3 = C.TEXT
        yesBtn.Font = FONT
        yesBtn.TextSize = 13
        yesBtn.Parent = modal
        corner(yesBtn, UDim.new(0, 4))

        local noBtn = Instance.new("TextButton")
        noBtn.Size = UDim2.new(0, 100, 0, 30)
        noBtn.Position = UDim2.new(0.5, 10, 1, -35)
        noBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        noBtn.BorderSizePixel = 0
        noBtn.Text = "Нет"
        noBtn.TextColor3 = C.TEXT
        noBtn.Font = FONT
        noBtn.TextSize = 13
        noBtn.Parent = modal
        corner(noBtn, UDim.new(0, 4))

        yesBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
            if onYes then onYes() end
        end)
        noBtn.MouseButton1Click:Connect(function()
            overlay:Destroy()
            if onNo then onNo() end
        end)
    end

    -- ════════════════════════════════════════════════════════════
    --  НОВОЕ: Темы оформления
    -- ════════════════════════════════════════════════════════════
    function W:SetTheme(themeName)
        local theme = Themes[themeName]
        if not theme then return end
        for k, v in pairs(theme) do
            if C[k] then C[k] = v end
        end
        W._theme = themeName
        -- Обновляем основные элементы
        main.BackgroundColor3 = C.BG
        titleBar.BackgroundColor3 = C.PANEL
        titleFix.BackgroundColor3 = C.PANEL
        accentBar.BackgroundColor3 = C.ACCENT
        divider.BackgroundColor3 = C.BORDER
        tabPanel.BackgroundColor3 = C.PANEL
        tabDivLine.BackgroundColor3 = C.BORDER
        uistroke(main, C.BORDER, 1.5) -- обновляем обводку (просто заменим цвет)
        for _, tabInfo in ipairs(W._tabBtns) do
            if tabInfo.btn.BackgroundColor3 == C.TAB_ACTIVE or tabInfo.btn.BackgroundColor3 == Themes[W._theme].TAB_ACTIVE then
                tabInfo.btn.BackgroundColor3 = C.TAB_ACTIVE
            end
        end
        -- Уведомление о смене темы
        W:Notify("Тема", "Применена тема: " .. themeName, 2)
    end

    -- ════════════════════════════════════════════════════════════
    --  НОВОЕ: Индикатор FPS и пинга
    -- ════════════════════════════════════════════════════════════
    local statsLabel
    function W:ShowStats()
        if statsLabel then
            statsLabel.Visible = not statsLabel.Visible
            return
        end
        local gui = createNotificationGui()
        statsLabel = Instance.new("TextLabel")
        statsLabel.Size = UDim2.new(0, 100, 0, 20)
        statsLabel.Position = UDim2.new(1, -110, 0, 10)
        statsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        statsLabel.BackgroundTransparency = 0.3
        statsLabel.BorderSizePixel = 0
        statsLabel.Text = "FPS: 0 | Ping: 0"
        statsLabel.Font = FONTREG
        statsLabel.TextSize = 12
        statsLabel.TextColor3 = C.TEXT
        statsLabel.Parent = gui
        corner(statsLabel, UDim.new(0, 4))
        uistroke(statsLabel, C.BORDER, 1)

        RunService.RenderStepped:Connect(function()
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = Players.LocalPlayer:GetNetworkPing() * 1000
            statsLabel.Text = string.format("FPS: %d | Ping: %.0f", fps, ping)
        end)
    end

    -- ════════════════════════════════════════════════════════════
    --  Window:AddTab(name)
    -- ════════════════════════════════════════════════════════════
    function W:AddTab(name)
        local Tab = { _order = 0, _searchText = "" }

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

        -- Поисковая строка (добавляется первой)
        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, 0, 0, 28)
        searchBox.BackgroundColor3 = C.INPUT_BG
        searchBox.BorderSizePixel = 0
        searchBox.PlaceholderText = "Поиск..."
        searchBox.Font = FONTREG
        searchBox.TextSize = 12
        searchBox.TextColor3 = C.TEXT
        searchBox.PlaceholderColor3 = C.TEXT_DIM
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.Parent = frame
        corner(searchBox, UDim.new(0, 4))
        uistroke(searchBox, C.BORDER, 1)
        searchBox.LayoutOrder = 0
        searchBox.ZIndex = 2

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = searchBox.Text:lower()
            for _, child in ipairs(frame:GetChildren()) do
                if child:IsA("Frame") and child ~= searchBox and child:GetAttribute("SearchText") then
                    local searchText = child:GetAttribute("SearchText"):lower()
                    local shouldShow = string.find(searchText, query, 1, true) ~= nil
                    child.Visible = shouldShow
                end
            end
        end)

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

        local function row(h, searchText)
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, 0, 0, h or 32)
            r.BackgroundTransparency = 1; r.BorderSizePixel = 0
            Tab._order = Tab._order + 1; r.LayoutOrder = Tab._order
            r.Parent = frame
            if searchText then
                r:SetAttribute("SearchText", searchText)
            end
            return r
        end

        -- ─────────────────────────────────────────────────────
        -- AddButton
        -- ─────────────────────────────────────────────────────
        function Tab:AddButton(text, callback, tooltip)
            local r   = row(32, text)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundColor3 = C.ACCENT_DIM
            btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = r
            corner(btn, UDim.new(0, 6)); uistroke(btn, C.BORDER, 1)

            local l = lbl(btn, text, TXTSZ, Enum.TextXAlignment.Center)
            l.Size = UDim2.new(1, 0, 1, 0)

            btn.MouseEnter:Connect(function()
                tw(btn, { BackgroundColor3 = C.ACCENT }, 0.12)
                if tooltip then showTooltip(tooltip, btn) end
            end)
            btn.MouseLeave:Connect(function()
                tw(btn, { BackgroundColor3 = C.ACCENT_DIM }, 0.12)
                hideTooltip()
            end)
            btn.MouseButton1Click:Connect(function()
                pulse(btn, C.ACCENT_DIM)
                if callback then callback() end
            end)
            return btn
        end

        -- ─────────────────────────────────────────────────────
        -- AddToggle
        -- ─────────────────────────────────────────────────────
        function Tab:AddToggle(text, default, callback, id, tooltip)
            local r     = row(32, text)
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
            if tooltip then
                hitBtn.MouseEnter:Connect(function() showTooltip(tooltip, hitBtn) end)
                hitBtn.MouseLeave:Connect(hideTooltip)
            end

            local function applyState(v)
                state = v; W.SavedValues[saveKey] = v
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
        -- AddCheckbox
        -- ─────────────────────────────────────────────────────
        function Tab:AddCheckbox(text, default, callback, id, tooltip)
            local r     = row(30, text)
            local state = default or false
            local saveKey = id or ("cb_" .. text)
            W.SavedValues[saveKey] = state

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)

            local box = Instance.new("Frame")
            box.Size             = UDim2.new(0, 18, 0, 18)
            box.Position         = UDim2.new(0, 8, 0.5, -9)
            box.BackgroundColor3 = state and C.CHECK_ON or C.CHECK_OFF
            box.BorderSizePixel  = 0; box.Parent = bg
            corner(box, UDim.new(0, 4)); uistroke(box, C.BORDER, 1)

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
            if tooltip then
                hitBtn.MouseEnter:Connect(function() showTooltip(tooltip, hitBtn) end)
                hitBtn.MouseLeave:Connect(hideTooltip)
            end

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
        -- AddSlider
        -- ─────────────────────────────────────────────────────
        function Tab:AddSlider(text, minVal, maxVal, default, callback, id, tooltip)
            minVal  = minVal  or 0
            maxVal  = maxVal  or 100
            default = default or minVal
            local val     = math.clamp(default, minVal, maxVal)
            local saveKey = id or ("sl_" .. text)
            W.SavedValues[saveKey] = val

            local r  = row(52, text)
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)
            if tooltip then
                bg.MouseEnter:Connect(function() showTooltip(tooltip, bg) end)
                bg.MouseLeave:Connect(hideTooltip)
            end

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
                fill.Size      = UDim2.new(frac, 0, 1, 0)
                thumb.Position = UDim2.new(frac, -7, 0.5, -7)
                valLbl.Text    = tostring(val)
                if callback then callback(val) end
            end

            hitArea.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true; setVal(inp.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    setVal(inp.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 and sliding then
                    sliding = false
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
        -- AddTextBox
        -- ─────────────────────────────────────────────────────
        function Tab:AddTextBox(placeholderText, callback, id, tooltip)
            local r       = row(36, placeholderText)
            local saveKey = id or ("tb_" .. placeholderText)
            W.SavedValues[saveKey] = ""

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.INPUT_BG
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)
            if tooltip then
                bg.MouseEnter:Connect(function() showTooltip(tooltip, bg) end)
                bg.MouseLeave:Connect(hideTooltip)
            end

            local tb = Instance.new("TextBox")
            tb.Size = UDim2.new(1, -12, 1, -8); tb.Position = UDim2.new(0, 6, 0, 4)
            tb.BackgroundTransparency = 1; tb.BorderSizePixel = 0
            tb.Text = ""; tb.PlaceholderText = placeholderText or "Введите текст..."
            tb.Font = FONTREG; tb.TextSize = TXTSZ; tb.TextColor3 = C.TEXT
            tb.PlaceholderColor3 = C.TEXT_DIM; tb.TextXAlignment = Enum.TextXAlignment.Left
            tb.ClearTextOnFocus = false; tb.Parent = bg

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
        -- AddDropdown
        -- ─────────────────────────────────────────────────────
        function Tab:AddDropdown(titleText, options, callback, id, tooltip)
            options = options or {}
            local saveKey  = id or ("dd_" .. titleText)
            local selected = options[1] or "—"
            local open     = false
            W.SavedValues[saveKey] = selected

            local itemH = 26
            local r = row(32, titleText)

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)
            bg.ClipsDescendants = true
            if tooltip then
                bg.MouseEnter:Connect(function() showTooltip(tooltip, bg) end)
                bg.MouseLeave:Connect(hideTooltip)
            end

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
            return Dropdown
        end

        -- ─────────────────────────────────────────────────────
        -- AddLabel / AddSeparator
        -- ─────────────────────────────────────────────────────
        function Tab:AddLabel(text)
            local r  = row(24, text)
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

        -- ─────────────────────────────────────────────────────
        -- НОВОЕ: AddKeybind (горячая клавиша)
        -- ─────────────────────────────────────────────────────
        function Tab:AddKeybind(text, defaultKey, callback, id, tooltip)
            defaultKey = defaultKey or Enum.KeyCode.F
            local saveKey = id or ("key_" .. text)
            local currentKey = defaultKey
            W.SavedValues[saveKey] = currentKey.Name

            -- Попытка загрузить сохранённое значение
            if writefile and readfile then
                local filename = "shadow_keybinds.txt"
                local ok, data = pcall(readfile, filename)
                if ok and data then
                    local keybinds = HttpService:JSONDecode(data)
                    if keybinds[saveKey] then
                        currentKey = Enum.KeyCode[keybinds[saveKey]] or defaultKey
                        W.SavedValues[saveKey] = currentKey.Name
                    end
                end
            end

            local r = row(32, text)
            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 1, 0); bg.BackgroundColor3 = C.PANEL
            bg.BorderSizePixel = 0; bg.Parent = r
            corner(bg, UDim.new(0, 6)); uistroke(bg, C.BORDER, 1)
            if tooltip then
                bg.MouseEnter:Connect(function() showTooltip(tooltip, bg) end)
                bg.MouseLeave:Connect(hideTooltip)
            end

            local nameLabel = lbl(bg, text, TXTSZ)
            nameLabel.Size = UDim2.new(1, -90, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0, 70, 0, 22)
            keyBtn.Position = UDim2.new(1, -80, 0.5, -11)
            keyBtn.BackgroundColor3 = C.ACCENT_DIM
            keyBtn.BorderSizePixel = 0
            keyBtn.Text = currentKey.Name
            keyBtn.TextColor3 = C.TEXT
            keyBtn.Font = FONT
            keyBtn.TextSize = 11
            keyBtn.Parent = bg
            corner(keyBtn, UDim.new(0, 4))
            uistroke(keyBtn, C.BORDER, 1)

            local waitingForInput = false
            local originalText = keyBtn.Text

            keyBtn.MouseButton1Click:Connect(function()
                waitingForInput = true
                keyBtn.Text = "..."
                keyBtn.BackgroundColor3 = C.ACCENT
            end)

            local function setKey(newKey)
                currentKey = newKey
                W.SavedValues[saveKey] = newKey.Name
                keyBtn.Text = newKey.Name
                waitingForInput = false
                keyBtn.BackgroundColor3 = C.ACCENT_DIM

                -- Сохранить в файл (если возможно)
                if writefile then
                    local filename = "shadow_keybinds.txt"
                    local keybinds = {}
                    if readfile then
                        local ok, data = pcall(readfile, filename)
                        if ok and data then
                            keybinds = HttpService:JSONDecode(data) or {}
                        end
                    end
                    keybinds[saveKey] = newKey.Name
                    pcall(writefile, filename, HttpService:JSONEncode(keybinds))
                end
            end

            UserInputService.InputBegan:Connect(function(inp, gp)
                if waitingForInput and not gp then
                    if inp.KeyCode ~= Enum.KeyCode.Unknown then
                        setKey(inp.KeyCode)
                    end
                elseif not waitingForInput and inp.KeyCode == currentKey and not gp then
                    if callback then callback() end
                end
            end)

            local Keybind = {}
            function Keybind:Set(key) setKey(key) end
            function Keybind:Get() return currentKey end
            return Keybind
        end

        return Tab
    end

    return W
end

return ShadowLib

--[[
Пример использования:
local ShadowLib = loadstring(game:HttpGet("URL"))()
local win = ShadowLib:CreateWindow("My UI")

win:Notify("Добро пожаловать", "Это уведомление!", 3)
win:ShowStats()
win:SetTheme("Ocean Blue")

local tab = win:AddTab("Main")
tab:AddButton("Click me", function() print("Clicked!") end, "Это кнопка")
tab:AddToggle("Toggle", false, function(v) print(v) end, "tog", "Включить/выключить")
tab:AddKeybind("Open Menu", Enum.KeyCode.F, function() print("Key pressed") end, "key1", "Нажмите клавишу")

local pl = win:CreatePlayerList()
pl:Show()

win:Confirm("Выход", "Вы уверены?", function() print("Yes") end)
]]
