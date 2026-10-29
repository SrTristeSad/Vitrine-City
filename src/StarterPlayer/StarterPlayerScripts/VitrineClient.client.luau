--!nonstrict
-- Vitrine City | interface responsiva inicial (PC / celular).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("VitrineRemotes")
local actionEvent = remotes:WaitForChild("Action")
local stateEvent = remotes:WaitForChild("State")
local noticeEvent = remotes:WaitForChild("Notice")

local C = {
    bg = Color3.fromRGB(15, 26, 39),
    card = Color3.fromRGB(33, 48, 64),
    muted = Color3.fromRGB(181, 202, 214),
    bright = Color3.fromRGB(249, 253, 254),
    green = Color3.fromRGB(38, 167, 112),
    blue = Color3.fromRGB(61, 133, 226),
    amber = Color3.fromRGB(199, 139, 55),
    red = Color3.fromRGB(194, 81, 91),
    slate = Color3.fromRGB(64, 82, 100),
}
local function rounded(element, size)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, size or 8)
    c.Parent = element
end
local function text(parent, value, height, size, color, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, 0, 0, height)
    l.Text = value
    l.TextSize = size or 13
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextColor3 = color or C.bright
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    l.Parent = parent
    return l
end
local function button(parent, value, color, callback)
    local b = Instance.new("TextButton")
    b.Name = value
    b.Size = UDim2.fromOffset(91, 31)
    b.BackgroundColor3 = color
    b.TextColor3 = C.bright
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = value
    b.AutoButtonColor = true
    b.Parent = parent
    rounded(b, 6)
    b.MouseButton1Click:Connect(callback)
    return b
end
local function fire(name, payload)
    actionEvent:FireServer(name, payload or {})
end

local gui = Instance.new("ScreenGui")
gui.Name = "VitrineCityUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = button(gui, "MINHA LOJA", C.green, function() end)
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -12, 0, 12)
toggle.Size = UDim2.fromOffset(138, 43)
toggle.TextSize = 14

local exitArmed = false
local exitTicket = 0
local returnButton
returnButton = button(gui, "LOBBY OFF", C.slate, function()
    if not returnButton.Active then return end
    if not exitArmed then
        exitArmed = true
        exitTicket += 1
        local ticket = exitTicket
        returnButton.Text = "CONFIRMAR SAÍDA"
        task.delay(5, function()
            if exitTicket == ticket and returnButton.Parent then
                exitArmed = false
                returnButton.Text = "VOLTAR AO LOBBY"
            end
        end)
    else
        exitArmed = false
        exitTicket += 1
        returnButton.Text = "CONECTANDO..."
        fire("ReturnToLobby")
    end
end)
returnButton.AnchorPoint = Vector2.new(0, 0)
returnButton.Position = UDim2.fromOffset(12, 12)
returnButton.Size = UDim2.fromOffset(158, 43)
returnButton.TextSize = 12
returnButton.Active = false

local panel = Instance.new("Frame")
panel.Name = "Painel Vitrine City"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 65)
panel.Size = UDim2.fromOffset(438, 560)
panel.BackgroundColor3 = C.bg
panel.BorderSizePixel = 0
panel.Parent = gui
rounded(panel, 11)
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = panel

local heading = text(panel, "VITRINE CITY", 27, 19, C.bright, true)
local summary = text(panel, "Conectando ao mercado...", 101, 12, C.muted)
summary.Position = UDim2.fromOffset(0, 29)

local marketNews = text(panel, "NOTÍCIAS DO MERCADO • Carregando...", 43, 12, C.amber, true)
marketNews.Position = UDim2.fromOffset(0, 136)
marketNews.BackgroundColor3 = C.card
marketNews.BackgroundTransparency = 0.25
rounded(marketNews, 7)

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Inventário"
scroll.Position = UDim2.fromOffset(0, 185)
scroll.Size = UDim2.new(1, 0, 1, -189)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = C.green
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel
local vertical = Instance.new("UIListLayout")
vertical.SortOrder = Enum.SortOrder.LayoutOrder
vertical.Padding = UDim.new(0, 8)
vertical.Parent = scroll

local notice = text(gui, "", 48, 14, C.bright, true)
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.Position = UDim2.new(0.5, 0, 1, -12)
notice.Size = UDim2.new(0.92, 0, 0, 48)
notice.TextXAlignment = Enum.TextXAlignment.Center
notice.BackgroundTransparency = 0.1
notice.BackgroundColor3 = C.card
notice.Visible = false
rounded(notice, 9)

local opened = true
local latest = nil
local lastInventorySignature = nil
local compact = false
local order = 0
local function nextOrder(frame)
    order += 1
    frame.LayoutOrder = order
    return frame
end
local function horizontal(parent, y, wide)
    local row = Instance.new("Frame")
    row.Name = "Linha"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, wide and -4 or 0, 0, 32)
    row.Position = UDim2.fromOffset(0, y)
    row.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = row
    return row
end

toggle.MouseButton1Click:Connect(function()
    opened = not opened
    panel.Visible = opened
    toggle.Text = opened and "FECHAR X" or "MINHA LOJA"
end)

local function adapt()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local width = camera.ViewportSize.X
    local height = camera.ViewportSize.Y
    local wasCompact = compact
    compact = width < 650
    if wasCompact ~= compact then lastInventorySignature = nil end
    panel.Size = UDim2.fromOffset(math.min(438, math.max(265, width - 24)), math.max(285, height - 92))
    if compact and not latest then
        opened = false
        panel.Visible = false
        toggle.Text = "MINHA LOJA"
    end
end
local cameraConn
local function connectCamera()
    if cameraConn then cameraConn:Disconnect() end
    if workspace.CurrentCamera then
        cameraConn = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adapt)
    end
    adapt()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera)
connectCamera()

local function alert(value)
    notice.Text = tostring(value)
    notice.Visible = true
    local ticket = os.clock()
    notice:SetAttribute("Ticket", ticket)
    task.delay(4.3, function()
        if notice.Parent and notice:GetAttribute("Ticket") == ticket then notice.Visible = false end
    end)
end
noticeEvent.OnClientEvent:Connect(alert)

local function section(value)
    local s = nextOrder(text(scroll, value, 30, 15, C.bright, true))
    s.BackgroundColor3 = C.slate
    s.BackgroundTransparency = 0.32
    return s
end

local function addProduct(product, competitive)
    local h = compact and (competitive and 228 or 150) or (competitive and 153 or 115)
    local card = Instance.new("Frame")
    card.Name = product.id
    card.Size = UDim2.new(1, -5, 0, h)
    card.BackgroundColor3 = C.card
    card.Parent = scroll
    rounded(card, 9)
    nextOrder(card)
    local inset = Instance.new("UIPadding")
    inset.PaddingLeft = UDim.new(0, 8)
    inset.PaddingRight = UDim.new(0, 7)
    inset.PaddingTop = UDim.new(0, 5)
    inset.Parent = card

    text(card, product.name .. " • " .. product.brand, 22, 14, C.bright, true)
    local supplier = product.supplier == -1 and "livre" or tostring(product.supplier)
    local info = text(card, "Preço $" .. product.price .. "  |  Dep. " .. product.storage .. "  |  Prat. " .. product.shelf .. "  |  Atacado " .. supplier, 31, 11, C.muted)
    info.Position = UDim2.fromOffset(0, 23)

    local first = horizontal(card, 55)
    local b1 = button(first, "Comprar 5", C.green, function() fire("Buy", { id = product.id }) end)
    local b2 = button(first, "Repor", C.blue, function() fire("Stock", { id = product.id }) end)
    local priceRow = compact and horizontal(card, 92) or first
    local b3 = button(priceRow, "Preço -", C.slate, function() fire("Price", { id = product.id, delta = -1 }) end)
    local b4 = button(priceRow, "Preço +", C.slate, function() fire("Price", { id = product.id, delta = 1 }) end)
    if compact then
        for _, b in ipairs({ b1, b2, b3, b4 }) do b.Size = UDim2.fromOffset(105, 31) end
    end
    if competitive then
        local bidRow = horizontal(card, compact and 134 or 95)
        local lastRow = compact and horizontal(card, 171) or bidRow
        for i, premium in ipairs({ 0, 20, 40 }) do
            local target = compact and i == 3 and lastRow or bidRow
            local b = button(target, "Oferta +" .. premium .. "%", C.amber, function() fire("Bid", { id = product.id, premium = premium }) end)
            if compact then b.Size = UDim2.fromOffset(105, 31) end
        end
        local cancel = button(lastRow, "Cancelar", C.red, function() fire("CancelBid", { id = product.id }) end)
        if compact then cancel.Size = UDim2.fromOffset(105, 31) end
    end
end

local function render(state)
    latest = state
    if state.loadError then
        heading.Text = "VITRINE CITY — DADOS INDISPONÍVEIS"
        summary.Text = state.loadError
        summary.TextColor3 = C.red
        panel.Visible = true
        opened = true
        toggle.Text = "FECHAR X"
        return
    end
    summary.TextColor3 = C.muted
    local event = state.market
    if event and event.title then
        marketNews.Text = "NOTÍCIA: " .. event.title .. "\n" .. (event.description or "")
    else
        marketNews.Text = "NOTÍCIAS DO MERCADO • Dia comum"
    end
    returnButton.Active = state.lobbyConfigured == true and not state.returning
    returnButton.AutoButtonColor = returnButton.Active
    returnButton.BackgroundColor3 = returnButton.Active and C.blue or C.slate
    if state.returning then
        returnButton.Text = "CONECTANDO..."
    elseif not exitArmed then
        returnButton.Text = state.lobbyConfigured and "VOLTAR AO LOBBY" or "LOBBY OFF"
    end
    local competitive = state.mode ~= "normal"
    heading.Text = "VITRINE CITY  |  " .. (state.mode == "normal" and "RUA LIVRE" or (state.mode == "price_war" and "GUERRA DE PREÇOS" or "GUERRA COMERCIAL"))
    heading.TextSize = compact and 16 or 19
    local status = state.lot > 0 and ("Sua loja: " .. state.lot) or "Sem loja: aproxime-se de uma placa amarela"
    if state.eliminated then status = "FALÊNCIA — aguarde a próxima rodada" end
    local saveInfo = state.persistence == "persistent" and "SALVAMENTO ATIVO"
        or (state.persistence == "conflict" and "SESSÃO BLOQUEADA" or
        (state.persistence == "round" and "PARTIDA TEMPORÁRIA" or "TESTE LOCAL SEM SALVAR"))
    if state.persistence == "conflict" then status = "Sua sessão perdeu a trava de dados. Não é seguro continuar operando." end
    summary.Text = status ..
        "\nCaixa: $" .. math.floor(state.cash) .. "   |   Lucro: $" .. state.profit .. "   |   Vendas: " .. state.sales ..
        "\nHabitantes: " .. state.citizens.residents .. "   |   Empregados: " .. state.citizens.employed ..
        "\n" .. saveInfo ..
        (competitive and ("\nRodada " .. state.round .. "   |   " .. math.ceil(state.remaining / 60) .. " min restantes") or "")

    -- Não destruir/recriar todos os cartões a cada 5 segundos quando nada mudou.
    -- Economia/cronômetro/avisos continuam atualizados acima deste ponto.
    local fingerprint = HttpService:JSONEncode({
        state.lot, state.hasEmployee, state.eliminated,
        state.products, state.bids, state.ranking, competitive, compact,
    })
    if fingerprint == lastInventorySignature then return end
    lastInventorySignature = fingerprint
    local savedY = scroll.CanvasPosition.Y
    order = 0
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    if state.lot == 0 then
        section(state.eliminated and "Você está eliminado desta partida" or "Alugue uma loja para começar!")
    else
        local employeeRow = nextOrder(horizontal(scroll, 0))
        button(employeeRow, state.hasEmployee and "Repositor contratado" or "Contratar repositor $130", C.green,
            function() fire("Hire") end).Size = UDim2.fromOffset(220, 32)
        section("Estoque e preços")
    end
    for _, product in ipairs(state.products) do addProduct(product, competitive) end
    if competitive then
        section("Contratos de fornecimento")
        if #state.bids == 0 then
            nextOrder(text(scroll, "Nenhum contrato. Uma oferta maior tem prioridade na próxima entrega.", 44, 12, C.muted))
        else
            for _, bid in ipairs(state.bids) do
                nextOrder(text(scroll, bid.product .. "  |  " .. bid.qty .. " un.  |  +" .. bid.premium .. "%  |  Reservado $" .. bid.escrow, 32, 12, C.muted))
            end
        end
        section("Classificação")
        for i, item in ipairs(state.ranking) do
            nextOrder(text(scroll, i .. "º " .. item.name .. "  |  Patrimônio $" .. item.worth .. "  |  Vendas " .. item.sales .. (item.eliminated and "  (Faliu)" or ""), 28, 12, C.muted))
        end
    end
    task.defer(function()
        if scroll.Parent then scroll.CanvasPosition = Vector2.new(0, savedY) end
    end)
end

stateEvent.OnClientEvent:Connect(render)
fire("GetState")
