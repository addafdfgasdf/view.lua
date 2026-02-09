local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- === НАСТРОЙКИ ===
local PROXY = "https://develop.roproxy.com/v1/universes/%s/places?limit=100"

-- === GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PhantomExplorer_V2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = gethui and gethui() or LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 400)
Main.Position = UDim2.new(0.5, -160, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Main.BackgroundTransparency = 0.1
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Main)
local UIStroke = Instance.new("UIStroke", Main)
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Transparency = 0.7

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "PHANTOM // UNIVERSE_SCAN"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1
Title.TextSize = 14

-- Поле поиска
local SearchBar = Instance.new("TextBox", Main)
SearchBar.Size = UDim2.new(0.7, 0, 0, 30)
SearchBar.Position = UDim2.new(0.05, 0, 0.12, 0)
SearchBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SearchBar.PlaceholderText = "ENTER UNIVERSE ID..."
SearchBar.Text = ""
SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBar.Font = Enum.Font.Code
SearchBar.TextSize = 12
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0, 4)

local SearchBtn = Instance.new("TextButton", Main)
SearchBtn.Size = UDim2.new(0.18, 0, 0, 30)
SearchBtn.Position = UDim2.new(0.77, 0, 0.12, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Text = "SCAN"
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 10
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 4)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(0.9, 0, 0.65, 0)
Scroll.Position = UDim2.new(0.05, 0, 0.22, 0)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 4)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 0, 25)
Status.Position = UDim2.new(0, 0, 0.9, 0)
Status.Text = "READY TO SCAN"
Status.TextColor3 = Color3.fromRGB(150, 150, 150)
Status.Font = Enum.Font.Code
Status.BackgroundTransparency = 1
Status.TextSize = 10

-- === ФУНКЦИИ ===

local function clearList()
    for _, item in pairs(Scroll:GetChildren()) do
        if item:IsA("TextButton") then item:Destroy() end
    end
end

local function addPlace(name, id)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, -10, 0, 35)
    B.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    B.BackgroundTransparency = 0.95
    B.Text = "  " .. name:upper()
    B.TextColor3 = Color3.fromRGB(200, 200, 200)
    B.Font = Enum.Font.Gotham
    B.TextSize = 11
    B.TextXAlignment = Enum.TextXAlignment.Left
    B.Parent = Scroll
    
    Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
    
    B.MouseButton1Click:Connect(function()
        Status.Text = "TELEPORTING TO " .. id .. "..."
        TeleportService:Teleport(id, LocalPlayer)
    end)
end

local function scanUniverse(uId)
    clearList()
    Status.Text = "FETCHING DATA..."
    
    local url = string.format(PROXY, tostring(uId))
    local requestFunc = syn and syn.request or http_request or request or (http and http.request)
    
    if not requestFunc then
        Status.Text = "ERROR: EXECUTOR NOT SUPPORTED"
        return
    end

    task.spawn(function()
        local success, response = pcall(function()
            return requestFunc({Url = url, Method = "GET"})
        end)
        
        if success and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.data then
                for _, p in pairs(data.data) do
                    addPlace(p.name or "Unnamed", p.id)
                end
                Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
                Status.Text = "SCAN COMPLETE: " .. #data.data .. " PLACES FOUND"
            else
                Status.Text = "NO PLACES FOUND"
            end
        else
            Status.Text = "FAILED TO CONNECT TO API"
        end
    end)
end

-- Авто-скан текущей игры при запуске
SearchBar.Text = tostring(game.GameId)
scanUniverse(game.GameId)

-- Обработка кнопки
SearchBtn.MouseButton1Click:Connect(function()
    local id = tonumber(SearchBar.Text)
    if id then scanUniverse(id) else Status.Text = "INVALID ID" end
end)

-- Драг
local dragStart, startPos, dragging
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
