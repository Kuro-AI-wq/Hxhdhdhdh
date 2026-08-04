--==========================================================--
--         🥋 GAKURAN: ULTIMATE AUTO PARRY (BLACK & WHITE)   --
--   Особенности:                                             --
--   - Детекция атак по зоне (Hitbox/расстояние)             --
--   - Не блокирует движение игрока                          --
--   - Черно-белый стиль интерфейса                         --
--   - Перетаскиваемое меню (Drag)                          --
--   - Настройка зоны и шанса                               --
--==========================================================--

-- 1. ⚙️ КОНФИГУРАЦИЯ (настрой под себя)
local CONFIG = {
    ParryChance = 0.85,              -- Шанс автопарри (0.0 - 1.0)
    DetectionRange = 12,             -- Радиус детекции атаки (в студиях)
    ParryKey = Enum.KeyCode.F,       -- Клавиша парри в игре
    GUI_Color = Color3.fromRGB(255, 255, 255),   -- Белый
    BgColor = Color3.fromRGB(15, 15, 15),        -- Черный фон
    AccentColor = Color3.fromRGB(200, 200, 200), -- Светло-серый для рамок
    TextColor = Color3.fromRGB(255, 255, 255)    -- Белый текст
}

-- 2. 🔧 СЛУЖЕБНЫЕ МОДУЛИ
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Переменные состояния
local toggleState = Instance.new("BoolValue")
toggleState.Name = "ParryToggle"
toggleState.Value = true
toggleState.Parent = player

local parryChance = CONFIG.ParryChance
local detectionRange = CONFIG.DetectionRange
local isParrying = false
local parryCooldown = false

-- 3. 🛡️ ОСНОВНАЯ ЛОГИКА ПАРРИРОВАНИЯ (с защитой от фризов)
local function doParry()
    if not toggleState.Value then return false end
    if parryCooldown then return false end
    if math.random() > parryChance then return false end
    
    -- Блокируем повторный вызов
    parryCooldown = true
    isParrying = true
    
    -- Имитация нажатия клавиши F (без залипания)
    VirtualInputManager:SendKeyEvent(true, CONFIG.ParryKey, false, nil)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, CONFIG.ParryKey, false, nil)
    
    -- Снимаем блокировку через очень короткий интервал (не мешает движению)
    task.wait(0.1)
    isParrying = false
    parryCooldown = false
    
    -- Визуальный фидбек (мигание статуса)
    statusLabel.Text = "💥 ПАРРИ!"
    task.wait(0.3)
    if not foldState.Value then
        statusLabel.Text = "⚔️ В БОЮ"
    end
    return true
end

-- 4. 🎯 ДЕТЕКЦИЯ АТАК (по зоне и анимации)
-- Сканируем всех игроков в радиусе и проверяем, атакуют ли они
local function findNearestAttacker()
    local bestTarget = nil
    local bestDist = detectionRange
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer == player then continue end
        local otherChar = otherPlayer.Character
        if not otherChar then continue end
        
        local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
        if not otherRoot then continue end
        
        local dist = (rootPart.Position - otherRoot.Position).Magnitude
        if dist > detectionRange then continue end
        
        -- Проверяем, атакует ли противник (по анимации или состоянию)
        local otherHumanoid = otherChar:FindFirstChild("Humanoid")
        if not otherHumanoid then continue end
        
        -- Флаг атаки: если у противника включена анимация атаки ИЛИ он в радиусе
        -- В Gakuran атака часто определяется по состоянию "Running" или наличию оружия
        local isAttacking = false
        
        -- Способ 1: проверка анимации (если есть)
        local animator = otherHumanoid:FindFirstChild("Animator")
        if animator then
            -- Проверяем, есть ли проигрываемая анимация атаки
            -- (зависит от игры, часто это "Attack" или "Sword")
            -- Здесь можно добавить логику по ID анимаций
        end
        
        -- Способ 2: проверка на наличие оружия в руке (часто в Gakuran)
        local tool = otherChar:FindFirstChildOfClass("Tool")
        if tool and tool:IsA("Tool") then
            -- Если оружие активно и противник в зоне - считаем атакой
            isAttacking = true
        end
        
        -- Способ 3: если противник двигается в твою сторону (агрессия)
        if not isAttacking then
            local velocity = otherRoot.Velocity
            local directionToPlayer = (rootPart.Position - otherRoot.Position).Unit
            local dot = velocity.Dot(directionToPlayer)
            if dot > 2 then -- бежит на игрока
                isAttacking = true
            end
        end
        
        if isAttacking then
            if not bestTarget or dist < bestDist then
                bestTarget = otherPlayer
                bestDist = dist
            end
        end
    end
    
    return bestTarget
end

-- 5. 🔄 ОСНОВНОЙ ЦИКЛ (проверка атак и парирование)
task.spawn(function()
    while task.wait(0.1) do
        if not toggleState.Value then 
            statusLabel.Text = "💤 ОТКЛЮЧЕН"
            continue 
        end
        
        local attacker = findNearestAttacker()
        if attacker then
            -- Если есть атакующий в зоне - пробуем парировать
            doParry()
            statusLabel.Text = "⚔️ АТАКА!"
        else
            if not foldState.Value then
                statusLabel.Text = "🛡️ В ОЖИДАНИИ"
            end
        end
    end
end)

-- 6. 🖥️ СОЗДАНИЕ GUI (ЧЕРНО-БЕЛЫЙ СТИЛЬ + DRAG)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GakuranParryGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- === КНОПКА СВОРАЧИВАНИЯ ===
local foldBtn = Instance.new("TextButton")
foldBtn.Size = UDim2.new(0, 50, 0, 50)
foldBtn.Position = UDim2.new(1, -65, 0, 15)
foldBtn.BackgroundColor3 = CONFIG.BgColor
foldBtn.TextColor3 = CONFIG.TextColor
foldBtn.Text = "⚔️"
foldBtn.TextSize = 24
foldBtn.Font = Enum.Font.GothamBold
foldBtn.BorderSizePixel = 2
foldBtn.BorderColor3 = CONFIG.AccentColor
local foldCorner = Instance.new("UICorner")
foldCorner.CornerRadius = UDim.new(1, 0)
foldCorner.Parent = foldBtn
foldBtn.Parent = screenGui

-- === ОСНОВНОЕ МЕНЮ (ЧЕРНО-БЕЛОЕ) ===
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 310)
mainFrame.Position = UDim2.new(0.02, 0, 0.5, -155)
mainFrame.BackgroundColor3 = CONFIG.BgColor
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = CONFIG.AccentColor
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Drag-перетаскивание (для мобильных и ПК)
local dragToggle = false
local dragInput = nil
local dragStart = nil
local dragStartPos = nil

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = true
        dragStart = input.Position
        dragStartPos = mainFrame.Position
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if dragToggle and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
            dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
        )
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragToggle = false
    end
end)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- === ЗАГОЛОВОК ===
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚔️ AUTO PARRY"
title.TextColor3 = CONFIG.TextColor
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.Parent = mainFrame

-- === КНОПКА ВКЛ/ВЫКЛ ===
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.1, 0, 0.13, 0)
toggleBtn.BackgroundColor3 = CONFIG.AccentColor
toggleBtn.TextColor3 = CONFIG.BgColor
toggleBtn.Text = "ВКЛ"
toggleBtn.TextSize = 16
toggleBtn.Font = Enum.Font.GothamBold
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = toggleBtn
toggleBtn.Parent = mainFrame

local function updateToggleBtn()
    toggleBtn.Text = toggleState.Value and "ВКЛ" or "ВЫКЛ"
    toggleBtn.BackgroundColor3 = toggleState.Value and CONFIG.AccentColor or CONFIG.BgColor
    toggleBtn.TextColor3 = toggleState.Value and CONFIG.BgColor or CONFIG.TextColor
    toggleBtn.BorderSizePixel = toggleState.Value and 0 or 2
    toggleBtn.BorderColor3 = CONFIG.AccentColor
end
updateToggleBtn()

-- === СЛАЙДЕР ШАНСА ===
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0.85, 0, 0, 50)
sliderFrame.Position = UDim2.new(0.075, 0, 0.30, 0)
sliderFrame.BackgroundTransparency = 1
sliderFrame.Parent = mainFrame

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(1, 0, 0.4, 0)
sliderLabel.Position = UDim2.new(0, 0, 0, 0)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "ШАНС: 85%"
sliderLabel.TextColor3 = CONFIG.TextColor
sliderLabel.TextSize = 13
sliderLabel.Font = Enum.Font.GothamMedium
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = sliderFrame

local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(1, 0, 0.35, 0)
sliderBack.Position = UDim2.new(0, 0, 0.55, 0)
sliderBack.BackgroundColor3 = CONFIG.BgColor
sliderBack.BorderSizePixel = 1
sliderBack.BorderColor3 = CONFIG.AccentColor
local sliderBackCorner = Instance.new("UICorner")
sliderBackCorner.CornerRadius = UDim.new(0, 4)
sliderBackCorner.Parent = sliderBack
sliderBack.Parent = sliderFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(parryChance, 0, 1, 0)
sliderFill.BackgroundColor3 = CONFIG.AccentColor
sliderFill.BorderSizePixel = 0
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = sliderFill
sliderFill.Parent = sliderBack

-- === ОБРАБОТКА СЛАЙДЕРА ===
local dragging = false
local function updateSliderFromInput(input)
    local relX = input.Position.X - sliderBack.AbsolutePosition.X
    local width = sliderBack.AbsoluteSize.X
    local percent = math.clamp(relX / width, 0, 1)
    parryChance = percent
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    sliderLabel.Text = string.format("ШАНС: %.0f%%", percent * 100)
end

sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        updateSliderFromInput(input)
    end
end)
sliderBack.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateSliderFromInput(input)
    end
end)
sliderBack.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- === СЛАЙДЕР ЗОНЫ ДЕТЕКЦИИ ===
local rangeSliderFrame = Instance.new("Frame")
rangeSliderFrame.Size = UDim2.new(0.85, 0, 0, 50)
rangeSliderFrame.Position = UDim2.new(0.075, 0, 0.48, 0)
rangeSliderFrame.BackgroundTransparency = 1
rangeSliderFrame.Parent = mainFrame

local rangeSliderLabel = Instance.new("TextLabel")
rangeSliderLabel.Size = UDim2.new(1, 0, 0.4, 0)
rangeSliderLabel.Position = UDim2.new(0, 0, 0, 0)
rangeSliderLabel.BackgroundTransparency = 1
rangeSliderLabel.Text = "ЗОНА: 12"
rangeSliderLabel.TextColor3 = CONFIG.TextColor
rangeSliderLabel.TextSize = 13
rangeSliderLabel.Font = Enum.Font.GothamMedium
rangeSliderLabel.TextXAlignment = Enum.TextXAlignment.Left
rangeSliderLabel.Parent = rangeSliderFrame

local rangeSliderBack = Instance.new("Frame")
rangeSliderBack.Size = UDim2.new(1, 0, 0.35, 0)
rangeSliderBack.Position = UDim2.new(0, 0, 0.55, 0)
rangeSliderBack.BackgroundColor3 = CONFIG.BgColor
rangeSliderBack.BorderSizePixel = 1
rangeSliderBack.BorderColor3 = CONFIG.AccentColor
local rangeBackCorner = Instance.new("UICorner")
rangeBackCorner.CornerRadius = UDim.new(0, 4)
rangeBackCorner.Parent = rangeSliderBack
rangeSliderBack.Parent = rangeSliderFrame

local rangeSliderFill = Instance.new("Frame")
rangeSliderFill.Size = UDim2.new(detectionRange / 25, 0, 1, 0)
rangeSliderFill.BackgroundColor3 = CONFIG.AccentColor
rangeSliderFill.BorderSizePixel = 0
local rangeFillCorner = Instance.new("UICorner")
rangeFillCorner.CornerRadius = UDim.new(0, 4)
rangeFillCorner.Parent = rangeSliderFill
rangeSliderFill.Parent = rangeSliderBack

local rangeDragging = false
local function updateRangeSlider(input)
    local relX = input.Position.X - rangeSliderBack.AbsolutePosition.X
    local width = rangeSliderBack.AbsoluteSize.X
    local percent = math.clamp(relX / width, 0, 1)
    detectionRange = math.floor(percent * 25 + 3)
    rangeSliderFill.Size = UDim2.new(percent, 0, 1, 0)
    rangeSliderLabel.Text = string.format("ЗОНА: %d", detectionRange)
end

rangeSliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rangeDragging = true
        updateRangeSlider(input)
    end
end)
rangeSliderBack.InputChanged:Connect(function(input)
    if rangeDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        updateRangeSlider(input)
    end
end)
rangeSliderBack.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rangeDragging = false
    end
end)

-- === СТАТУС-СТРОКА ===
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -16, 0, 26)
statusLabel.Position = UDim2.new(0.035, 0, 0.70, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "🛡️ В ОЖИДАНИИ"
statusLabel.TextColor3 = CONFIG.TextColor
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = mainFrame

-- === ПОДСКАЗКА ===
local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -16, 0, 20)
infoText.Position = UDim2.new(0.035, 0, 0.86, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "F — ручной пари"
infoText.TextColor3 = CONFIG.AccentColor
infoText.TextSize = 11
infoText.Font = Enum.Font.Gotham
infoText.TextXAlignment = Enum.TextXAlignment.Center
infoText.Parent = mainFrame

-- 7. 🔄 ФУНКЦИИ СВОРАЧИВАНИЯ
local foldState = Instance.new("BoolValue")
foldState.Name = "ParryFold"
foldState.Value = false
foldState.Parent = player

local function updateFold()
    if foldState.Value then
        mainFrame.Visible = false
        foldBtn.Text = "☰"
        foldBtn.Size = UDim2.new(0, 50, 0, 50)
        foldBtn.Position = UDim2.new(1, -65, 0, 15)
    else
        mainFrame.Visible = true
        foldBtn.Text = "⚔️"
        foldBtn.Size = UDim2.new(0, 50, 0, 50)
        foldBtn.Position = UDim2.new(1, -65, 0, 15)
    end
end
updateFold()

foldBtn.MouseButton1Click:Connect(function()
    foldState.Value = not foldState.Value
    updateFold()
end)

-- 8. 🎮 ОБРАБОТЧИКИ КНОПОК
toggleBtn.MouseButton1Click:Connect(function()
    toggleState.Value = not toggleState.Value
    updateToggleBtn()
    statusLabel.Text = toggleState.Value and "⚔️ ВКЛЮЧЕН" or "💤 ОТКЛЮЧЕН"
    task.wait(1)
    if not foldState.Value then
        statusLabel.Text = "🛡️ В ОЖИДАНИИ"
    end
end)

-- 9. ⌨️ ГОРЯЧАЯ КЛАВИША ДЛЯ СВОРАЧИВАНИЯ (G)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        foldState.Value = not foldState.Value
        updateFold()
    end
end)

-- 10. 🧹 ИНИЦИАЛИЗАЦИЯ
print("🥋 Gakuran Ultimate Auto Parry загружен!")
print("⚔️ Черно-белый стиль | Drag-меню | Детекция зоны")
statusLabel.Text = "✅ ЗАГРУЖЕН"
task.wait(1)
if not foldState.Value then
    statusLabel.Text = "🛡️ В ОЖИДАНИИ"
end
