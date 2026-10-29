--!nonstrict
-- Lobby UI, responsiva e com seleção explícita dos três modos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LobbyRemotes")
local action = remotes:WaitForChild("Action")
local state = remotes:WaitForChild("State")
local notice = remotes:WaitForChild("Notice")

local colors = {
    background = Color3.fromRGB(16, 26, 40),
    panel = Color3.fromRGB(31, 48, 66),
    white = Color3.fromRGB(245, 251, 255),
    muted = Color3.fromRGB(189, 205, 216),
    green = Color3.fromRGB(38, 161, 113),
    blue = Color3.fromRGB(60, 126, 225),
    orange = Color3.fromRGB(213, 132, 55),
    gray = Color3.fromRGB(82, 94, 111),
}
local modes = {
    { id = "normal", title = "RUA LIVRE", subtitle = "Administre sua loja sem eliminação.", accent = colors.green },
    { id = "ranked", title = "GUERRA COMERCIAL", subtitle = "Concorra por clientes e fornecedores.", accent = colors.blue },
    { id = "price_war", title = "GUERRA DE PREÇOS", subtitle = "O último negócio sobrevivente vence.", accent = colors.orange },
}
local function rounded(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end
local function t(parent, content, size, height, color, weight)
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, height)
    label.BackgroundTransparency = 1
    label.Font = weight and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Text = content
    label.TextSize = size
    label.TextColor3 = color or colors.white
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Parent = parent
    return label
end
local function btn(parent, caption, accent)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 42)
    button.Text = caption
    button.TextColor3 = colors.white
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.BackgroundColor3 = accent
    button.Parent = parent
    rounded(button, 8)
    return button
end

local screen = Instance.new("ScreenGui")
screen.Name = "VitrineLobbyUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.Parent = player:WaitForChild("PlayerGui")

local toggle = btn(screen, "MODOS DE JOGO", colors.green)
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Size = UDim2.fromOffset(174, 42)
toggle.Position = UDim2.new(1, -14, 0, 12)

local panel = Instance.new("ScrollingFrame")
panel.Name = "Seleção de modos"
panel.BackgroundColor3 = colors.background
panel.BorderSizePixel = 0
panel.ScrollBarThickness = 4
panel.ScrollBarImageColor3 = colors.green
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.CanvasSize = UDim2.fromOffset(0, 0)
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -14, 0, 64)
panel.Size = UDim2.fromOffset(420, 550)
panel.Parent = screen
rounded(panel, 12)
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.Parent = panel
local list = Instance.new("UIListLayout")
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, 10)
list.Parent = panel

local header = t(panel, "VITRINE CITY", 23, 32, colors.white, true)
header.LayoutOrder = 1
local tagline = t(panel, "Seu negócio. Suas decisões. Sua cidade.", 13, 26, colors.muted)
tagline.LayoutOrder = 2
local rows = {}
for index, meta in ipairs(modes) do
    local card = Instance.new("Frame")
    card.Name = meta.id
    card.Size = UDim2.new(1, -6, 0, 142)
    card.BackgroundColor3 = colors.panel
    card.LayoutOrder = index + 2
    card.Parent = panel
    rounded(card, 10)
    local inner = Instance.new("UIPadding")
    inner.PaddingTop = UDim.new(0, 7)
    inner.PaddingBottom = UDim.new(0, 6)
    inner.PaddingLeft = UDim.new(0, 10)
    inner.PaddingRight = UDim.new(0, 10)
    inner.Parent = card
    local title = t(card, meta.title, 16, 26, colors.white, true)
    local desc = t(card, meta.subtitle, 12, 29, colors.muted)
    desc.Position = UDim2.fromOffset(0, 27)
    local status = t(card, "Verificando disponibilidade...", 11, 24, colors.muted)
    status.Position = UDim2.fromOffset(0, 55)
    local button = btn(card, "ENTRAR", meta.accent)
    button.Size = UDim2.new(1, 0, 0, 36)
    button.Position = UDim2.fromOffset(0, 85)
    button.MouseButton1Click:Connect(function()
        if button:GetAttribute("Action") == "Cancel" then
            action:FireServer("Cancel")
        elseif button:GetAttribute("Action") == "Join" then
            action:FireServer("Join", meta.id)
        end
    end)
    rows[meta.id] = { status = status, button = button, accent = meta.accent }
end

local footer = t(panel, "Na versão Studio, os portais mostram o lobby, mas teleporte exige um jogo publicado.", 12, 56, colors.muted)
footer.LayoutOrder = 9

local banner = t(screen, "", 14, 49, colors.white, true)
banner.AnchorPoint = Vector2.new(0.5, 1)
banner.Size = UDim2.new(0.9, 0, 0, 49)
banner.Position = UDim2.new(0.5, 0, 1, -20)
banner.BackgroundColor3 = colors.panel
banner.BackgroundTransparency = 0.09
banner.TextXAlignment = Enum.TextXAlignment.Center
banner.Visible = false
rounded(banner, 9)

local opened = true
toggle.MouseButton1Click:Connect(function()
    opened = not opened
    panel.Visible = opened
    toggle.Text = opened and "FECHAR MODOS" or "MODOS DE JOGO"
end)
local function adapt()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    panel.Size = UDim2.fromOffset(math.min(420, math.max(270, viewport.X - 28)), math.max(260, viewport.Y - 95))
end
local cameraConnection
local function cameraChanged()
    if cameraConnection then cameraConnection:Disconnect() end
    if workspace.CurrentCamera then
        cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
    end
    adapt()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged)
cameraChanged()

local function update(data)
    for _, meta in ipairs(modes) do
        local row = rows[meta.id]
        local info = data.modes[meta.id]
        if info then
            local status = info.configured and (meta.id == "normal" and "Salvamento persistente após publicação"
                or (info.waiting .. "/" .. info.maxPlayers .. " aguardando"
                    .. (info.remaining and (" | Começa em " .. info.remaining .. "s") or "")))
                or "Aguardando configuração do PlaceId"
            if data.localTest and info.configured then status = status .. " | Studio sem teleporte" end
            row.status.Text = status
            local disabled = not info.configured or data.busy
            local selected = data.queue == meta.id
            if selected then
                row.button.Text = "CANCELAR FILA"
                row.button.BackgroundColor3 = colors.orange
                row.button:SetAttribute("Action", "Cancel")
            else
                row.button.Text = data.busy and "CONECTANDO..." or
                    (disabled and "INDISPONÍVEL" or (data.queue and "EM OUTRA FILA" or "ENTRAR"))
                row.button.BackgroundColor3 = disabled or data.queue and colors.gray or row.accent
                row.button:SetAttribute("Action", disabled or data.queue and "None" or "Join")
            end
        end
    end
end
state.OnClientEvent:Connect(update)
notice.OnClientEvent:Connect(function(content)
    banner.Text = tostring(content)
    banner.Visible = true
    local ticket = os.clock()
    banner:SetAttribute("Ticket", ticket)
    task.delay(4.5, function()
        if banner.Parent and banner:GetAttribute("Ticket") == ticket then banner.Visible = false end
    end)
end)
action:FireServer("State")
