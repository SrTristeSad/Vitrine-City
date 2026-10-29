--!nonstrict
-- Lobby Vitrine City. Cada fila existe apenas no servidor deste lobby.
-- Quando chegarmos a muitos servidores, migrar matchmaking para MemoryStore.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Routes = require(ReplicatedStorage:WaitForChild("ModeRoutes"))
local remotes = Instance.new("Folder")
remotes.Name = "LobbyRemotes"
remotes.Parent = ReplicatedStorage

local function remote(name)
    local evt = Instance.new("RemoteEvent")
    evt.Name = name
    evt.Parent = remotes
    return evt
end
local actionEvent, stateEvent, noticeEvent = remote("Action"), remote("State"), remote("Notice")

local queue = { ranked = {}, price_war = {} }
local queuedMode, inFlight, lastRequest = {}, {}, {}
local countdownAt = {}
local lobby = Instance.new("Folder")
lobby.Name = "VitrineCityLobbyMap"
lobby.Parent = Workspace

local function part(name, size, pos, color, material)
    local obj = Instance.new("Part")
    obj.Name = name
    obj.Size = size
    obj.Position = pos
    obj.Color = color
    obj.Anchored = true
    obj.Material = material or Enum.Material.SmoothPlastic
    obj.Parent = lobby
    return obj
end
local function label(anchor, title)
    local g = Instance.new("BillboardGui")
    g.Size = UDim2.fromOffset(260, 78)
    g.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
    g.AlwaysOnTop = true
    g.MaxDistance = 110
    g.Parent = anchor
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 0.12
    t.BackgroundColor3 = Color3.fromRGB(20, 36, 54)
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
    t.TextWrapped = true
    t.Text = title
    t.Parent = g
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = t
end

local function notify(player, message)
    if player and player.Parent == Players then
        noticeEvent:FireClient(player, message)
    end
end
local function removeFromQueue(player)
    local mode = queuedMode[player.UserId]
    if not mode then return false end
    local list = queue[mode]
    if list then
        for i = #list, 1, -1 do
            if list[i] == player then table.remove(list, i) end
        end
        if #list < Routes[mode].minPlayers then countdownAt[mode] = nil end
    end
    queuedMode[player.UserId] = nil
    return true
end
local function cleanQueue(mode)
    for i = #queue[mode], 1, -1 do
        local p = queue[mode][i]
        if p.Parent ~= Players or queuedMode[p.UserId] ~= mode or inFlight[p.UserId] then
            table.remove(queue[mode], i)
        end
    end
end
local function requeue(player, mode)
    if player.Parent ~= Players or queuedMode[player.UserId] or inFlight[player.UserId] then return end
    table.insert(queue[mode], player)
    queuedMode[player.UserId] = mode
end
local function sendState(player)
    if player.Parent ~= Players then return end
    local modes = {}
    for _, mode in ipairs({ "normal", "ranked", "price_war" }) do
        local cfg = Routes[mode]
        modes[mode] = {
            label = cfg.label,
            configured = typeof(cfg.placeId) == "number" and cfg.placeId > 0,
            waiting = mode == "normal" and 0 or #queue[mode],
            required = cfg.minPlayers,
            maxPlayers = cfg.maxPlayers,
            remaining = countdownAt[mode] and math.max(0, math.ceil(countdownAt[mode] - os.clock())) or nil,
        }
    end
    stateEvent:FireClient(player, {
        modes = modes,
        queue = queuedMode[player.UserId],
        busy = inFlight[player.UserId] ~= nil,
        localTest = RunService:IsStudio(),
    })
end
local function broadcast()
    for _, player in ipairs(Players:GetPlayers()) do sendState(player) end
end

local function prepared(mode)
    local cfg = Routes[mode]
    return cfg and typeof(cfg.placeId) == "number" and cfg.placeId > 0 and cfg.placeId ~= game.PlaceId
end
local function teleportGroup(mode, players)
    if #players == 0 then return end
    local cfg = Routes[mode]
    if not prepared(mode) then
        for _, player in ipairs(players) do
            queuedMode[player.UserId] = nil
            notify(player, "O Place deste modo ainda não foi configurado.")
        end
        return false
    end
    if RunService:IsStudio() then
        for _, player in ipairs(players) do
            queuedMode[player.UserId] = nil
            notify(player, "O lobby funciona no Studio, mas teleporte exige teste no aplicativo Roblox publicado.")
        end
        return false
    end

    for _, player in ipairs(players) do
        inFlight[player.UserId] = mode
        queuedMode[player.UserId] = nil
    end
    local options = Instance.new("TeleportOptions")
    if mode ~= "normal" then
        -- API atual. Um GUID por partida cria uma instância reservada independente.
        options.ReservedServerId = HttpService:GenerateGUID(false)
        options:SetTeleportData({ mode = mode }) -- apenas informativo; não autoriza dinheiro nem inventário.
    end
    local ok, result = pcall(function()
        TeleportService:TeleportAsync(cfg.placeId, players, options)
    end)
    if not ok then
        warn("Vitrine City: falha ao iniciar teleporte " .. mode .. ": " .. tostring(result))
        for _, player in ipairs(players) do
            if inFlight[player.UserId] == mode then
                inFlight[player.UserId] = nil
                notify(player, "Não foi possível entrar na partida. Tente novamente.")
                if mode ~= "normal" then requeue(player, mode) end
            end
        end
        return false
    end
    return true
end

local function joinMode(player, mode)
    if typeof(mode) ~= "string" or not Routes[mode] then return end
    if queuedMode[player.UserId] or inFlight[player.UserId] then return end
    if not prepared(mode) then notify(player, "Esse modo ainda não tem um Place publicado/configurado."); return end
    if mode == "normal" then
        task.spawn(teleportGroup, mode, { player })
    else
        cleanQueue(mode)
        table.insert(queue[mode], player)
        queuedMode[player.UserId] = mode
        notify(player, "Entrou na fila: " .. Routes[mode].label)
    end
    broadcast()
end

local function makeMap()
    part("Praça", Vector3.new(146, 1, 110), Vector3.new(0, -0.55, 0), Color3.fromRGB(110, 163, 128), Enum.Material.Grass)
    part("Caminho", Vector3.new(114, 0.15, 35), Vector3.new(0, 0.04, 8), Color3.fromRGB(214, 208, 192))
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Entrada da Vitrine City"
    spawn.Size = Vector3.new(9, 1, 9)
    spawn.Position = Vector3.new(0, 0.5, 34)
    spawn.Neutral = true
    spawn.Anchored = true
    spawn.Parent = lobby
    local modes = {
        { id = "normal", x = -39, color = Color3.fromRGB(36, 164, 111) },
        { id = "ranked", x = 0, color = Color3.fromRGB(65, 126, 218) },
        { id = "price_war", x = 39, color = Color3.fromRGB(206, 119, 51) },
    }
    for _, m in ipairs(modes) do
        part("Quiosque " .. m.id, Vector3.new(27, 9, 12), Vector3.new(m.x, 4.5, -18), m.color)
        local roof = part("Cobertura " .. m.id, Vector3.new(30, 1, 15), Vector3.new(m.x, 10, -18), Color3.fromRGB(23, 42, 60))
        label(roof, Routes[m.id].label .. "\n" .. (m.id == "normal" and "Progresso permanente" or "Partida competitiva"))
        local pad = part("Fila " .. m.id, Vector3.new(12, 0.5, 8), Vector3.new(m.x, 0.4, -5), m.color)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ObjectText = Routes[m.id].label
        prompt.ActionText = "Entrar no modo"
        prompt.MaxActivationDistance = 12
        prompt.HoldDuration = 0.25
        prompt.Parent = pad
        prompt.Triggered:Connect(function(player) joinMode(player, m.id) end)
    end
end
makeMap()

actionEvent.OnServerEvent:Connect(function(player, action, mode)
    if typeof(action) ~= "string" then return end
    local now = os.clock()
    if now - (lastRequest[player.UserId] or -999) < 0.5 then return end
    lastRequest[player.UserId] = now
    if action == "Join" then
        joinMode(player, mode)
    elseif action == "Cancel" then
        if removeFromQueue(player) then notify(player, "Fila cancelada.") end
        broadcast()
    elseif action == "State" then
        sendState(player)
    end
end)

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage, _placeId, _options)
    local mode = inFlight[player.UserId]
    if not mode then return end
    inFlight[player.UserId] = nil
    warn("Vitrine City: TeleportInitFailed: " .. tostring(teleportResult) .. " / " .. tostring(errorMessage))
    notify(player, "Falha no teleporte. Você continua no lobby.")
    if mode ~= "normal" then requeue(player, mode) end
    broadcast()
end)

Players.PlayerAdded:Connect(function(player) task.defer(sendState, player) end)
Players.PlayerRemoving:Connect(function(player)
    removeFromQueue(player)
    inFlight[player.UserId] = nil
    lastRequest[player.UserId] = nil
    broadcast()
end)
for _, p in ipairs(Players:GetPlayers()) do task.defer(sendState, p) end

task.spawn(function()
    while true do
        task.wait(1)
        for _, mode in ipairs({ "ranked", "price_war" }) do
            cleanQueue(mode)
            local cfg = Routes[mode]
            local count = #queue[mode]
            if count < cfg.minPlayers then
                countdownAt[mode] = nil
            elseif not countdownAt[mode] then
                countdownAt[mode] = os.clock() + cfg.countdown
            end
            if count >= cfg.maxPlayers or (countdownAt[mode] and os.clock() >= countdownAt[mode]) then
                local batch = {}
                for _ = 1, math.min(cfg.maxPlayers, #queue[mode]) do
                    local p = table.remove(queue[mode], 1)
                    if p and p.Parent == Players then table.insert(batch, p) end
                end
                countdownAt[mode] = nil
                if #batch >= cfg.minPlayers then
                    task.spawn(teleportGroup, mode, batch)
                else
                    for _, p in ipairs(batch) do
                        queuedMode[p.UserId] = nil
                        requeue(p, mode)
                    end
                end
            end
        end
        broadcast()
    end
end)

print("Vitrine City: lobby iniciado; matchmaking local por servidor.")
