--!nonstrict
-- Matchmaking global beta (MemoryStore SortedMap).
-- Um registro por usuário, claim atômico e partida publicada somente após todos os claims.
-- Nenhum evento remoto ou ticket permite ao cliente definir PlaceId, saldo ou servidor.
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local GlobalMatchmaker = {}
GlobalMatchmaker.__index = GlobalMatchmaker
local QUEUE_TTL = 95
local MATCH_TTL = 90
local LOCK_SECONDS = 25
local WAIT_LEASE_SECONDS = 50
local POLL_SECONDS = 4
local COORDINATE_SECONDS = 7
local FLIGHT_TIMEOUT = 50
local MODES = { "ranked", "price_war" }

local function mapFor(mode)
    return MemoryStoreService:GetSortedMap("VC_MM_v1_" .. mode)
end
local matches = MemoryStoreService:GetSortedMap("VC_MM_v1_matches")

local function key(userId)
    return tostring(userId)
end

local function isValidTicket(record, nonce, jobId)
    return typeof(record) == "table" and record.nonce == nonce and record.job == jobId
end

function GlobalMatchmaker.new(routes, notify, changed)
    local self = setmetatable({}, GlobalMatchmaker)
    self.enabled = routes.GlobalMatchmakingEnabled == true and not RunService:IsStudio()
    self.routes = routes
    self.notify = notify
    self.changed = changed
    self.active = {}
    self.inFlight = {}
    self.approxWaiting = { ranked = 0, price_war = 0 }
    if self.enabled then
        task.spawn(function() self:_runPlayers() end)
        task.spawn(function() self:_runCoordinator() end)
    end
    return self
end

function GlobalMatchmaker:GetMode(player)
    local record = self.active[player.UserId]
    return record and record.mode or nil
end
function GlobalMatchmaker:Busy(player)
    return self.inFlight[player.UserId] ~= nil
end
function GlobalMatchmaker:Waiting(mode)
    return self.approxWaiting[mode] or 0
end

function GlobalMatchmaker:Join(player, mode)
    if not self.enabled or (mode ~= "ranked" and mode ~= "price_war") then return false end
    if player.Parent ~= Players or self.active[player.UserId] then return false end
    local cfg = self.routes[mode]
    if not cfg or typeof(cfg.placeId) ~= "number" or cfg.placeId <= 0 then
        self.notify(player, "Esse modo ainda não foi publicado.")
        return false
    end
    local nonce = HttpService:GenerateGUID(false)
    local now = os.time()
    local ticket = {
        userId = player.UserId, job = game.JobId, nonce = nonce,
        mode = mode, state = "waiting", addedAt = now,
        expiresAt = now + WAIT_LEASE_SECONDS,
    }
    local map = mapFor(mode)
    local ok, result = pcall(function()
        return map:UpdateAsync(key(player.UserId), function(old, sortKey)
            if typeof(old) == "table" and old.state ~= "cancelled"
                and typeof(old.expiresAt) == "number" and old.expiresAt > now then
                return nil
            end
            return ticket, now
        end, QUEUE_TTL)
    end)
    if not ok or not isValidTicket(result, nonce, game.JobId) then
        self.notify(player, "Fila global indisponível ou seu perfil já está em uma fila. Tente novamente.")
        warn("Vitrine City GlobalMatchmaker: falha de entrada: ", tostring(result))
        return false
    end
    self.active[player.UserId] = { mode = mode, nonce = nonce, addedAt = now, nextHeartbeat = now + 20 }
    self.notify(player, "Fila global iniciada. Procurando comerciantes de outros lobbies...")
    self.changed()
    return true
end

function GlobalMatchmaker:_cancelRecord(userId, entry)
    local map = mapFor(entry.mode)
    local now = os.time()
    local ok, result = pcall(function()
        return map:UpdateAsync(key(userId), function(old, sortKey)
            if not isValidTicket(old, entry.nonce, game.JobId) then return nil end
            local changed = table.clone(old)
            changed.state = "cancelled"
            changed.expiresAt = now
            return changed, sortKey
        end, 10)
    end)
    return ok and result ~= nil
end

function GlobalMatchmaker:Cancel(player, silent)
    local entry = self.active[player.UserId]
    if not entry or self.inFlight[player.UserId] then return false end
    -- Não apagar tickets de outro servidor/sessão: sempre verificar nonce e JobId.
    if not self:_cancelRecord(player.UserId, entry) then
        if not silent then self.notify(player, "Não foi possível cancelar agora. Tente novamente.") end
        return false
    end
    self.active[player.UserId] = nil
    if not silent then self.notify(player, "Você saiu da fila global.") end
    self.changed()
    return true
end

function GlobalMatchmaker:Remove(player)
    local entry = self.active[player.UserId]
    self.active[player.UserId], self.inFlight[player.UserId] = nil, nil
    if entry then
        task.spawn(function() self:_cancelRecord(player.UserId, entry) end)
    end
end

function GlobalMatchmaker:TeleportFailed(player, message)
    local entry = self.active[player.UserId]
    if not entry or not self.inFlight[player.UserId] then return end
    self.inFlight[player.UserId] = nil
    self:_cancelRecord(player.UserId, entry)
    self.active[player.UserId] = nil
    self.notify(player, message or "Não foi possível iniciar sua partida. Entre na fila novamente.")
    self.changed()
end

function GlobalMatchmaker:_claim(mode, item, matchId)
    local now = os.time()
    local map = mapFor(mode)
    local result
    local ok = pcall(function()
        result = map:UpdateAsync(item.key, function(old, sortKey)
            if typeof(old) ~= "table" or old.nonce ~= item.value.nonce or
                old.mode ~= mode or old.state ~= "waiting" or old.expiresAt <= now then
                return nil
            end
            local updated = table.clone(old)
            updated.state = "claimed"
            updated.matchId = matchId
            updated.claimedAt = now
            updated.expiresAt = now + LOCK_SECONDS
            return updated, sortKey
        end, QUEUE_TTL)
    end)
    return ok and typeof(result) == "table" and result.matchId == matchId
end

function GlobalMatchmaker:_setAssigned(mode, ticketKey, matchId, serverId)
    local now = os.time()
    local map = mapFor(mode)
    local result
    local ok = pcall(function()
        result = map:UpdateAsync(ticketKey, function(old, sortKey)
            if typeof(old) ~= "table" or old.matchId ~= matchId or old.state ~= "claimed" then
                return nil
            end
            local updated = table.clone(old)
            updated.state = "assigned"
            updated.reserved = serverId
            updated.expiresAt = now + MATCH_TTL
            return updated, sortKey
        end, MATCH_TTL)
    end)
    return ok and typeof(result) == "table" and result.matchId == matchId and result.state == "assigned"
end

function GlobalMatchmaker:_rollback(mode, ticketKey, matchId)
    local now = os.time()
    local map = mapFor(mode)
    pcall(function()
        map:UpdateAsync(ticketKey, function(old, sortKey)
            if typeof(old) ~= "table" or old.matchId ~= matchId or
                (old.state ~= "claimed" and old.state ~= "assigned") then
                return nil
            end
            local restored = table.clone(old)
            restored.state = "waiting"
            restored.matchId, restored.reserved, restored.claimedAt = nil, nil, nil
            restored.expiresAt = now + WAIT_LEASE_SECONDS
            return restored, sortKey
        end, QUEUE_TTL)
    end)
end

function GlobalMatchmaker:_coordinate(mode)
    local map = mapFor(mode)
    local cfg = self.routes[mode]
    if not cfg or typeof(cfg.placeId) ~= "number" or cfg.placeId <= 0 then return end
    local ok, items = pcall(function()
        return map:GetRangeAsync(Enum.SortDirection.Ascending, 60)
    end)
    if not ok then
        warn("Vitrine City: MemoryStore GetRangeAsync falhou em " .. mode)
        return
    end
    local now = os.time()
    local candidates = {}
    for _, item in ipairs(items) do
        local v = item.value
        if typeof(v) == "table" and v.mode == mode and v.state == "waiting" and
            typeof(v.expiresAt) == "number" and v.expiresAt > now then
            table.insert(candidates, item)
        end
    end
    self.approxWaiting[mode] = #candidates
    if #candidates < cfg.minPlayers then return end

    local matchId = HttpService:GenerateGUID(false)
    local claimed = {}
    for _, item in ipairs(candidates) do
        if #claimed >= cfg.maxPlayers then break end
        if self:_claim(mode, item, matchId) then table.insert(claimed, item.key) end
    end
    if #claimed < cfg.minPlayers then
        for _, ticketKey in ipairs(claimed) do self:_rollback(mode, ticketKey, matchId) end
        return
    end

    local reservedId = HttpService:GenerateGUID(false)
    local allAssigned = true
    for _, ticketKey in ipairs(claimed) do
        if not self:_setAssigned(mode, ticketKey, matchId, reservedId) then
            allAssigned = false
            break
        end
    end
    if not allAssigned then
        for _, ticketKey in ipairs(claimed) do self:_rollback(mode, ticketKey, matchId) end
        return
    end

    local published = pcall(function()
        -- Só depois de TODOS os tickets preparados a partida se torna visível.
        matches:SetAsync(matchId, {
            ready = true, mode = mode, reserved = reservedId,
            placeId = cfg.placeId, issuedAt = now,
        }, MATCH_TTL, now)
    end)
    if not published then
        for _, ticketKey in ipairs(claimed) do self:_rollback(mode, ticketKey, matchId) end
        warn("Vitrine City: falha ao publicar partida " .. matchId)
    end
end

function GlobalMatchmaker:_send(player, entry, assignment)
    if self.inFlight[player.UserId] or player.Parent ~= Players then return end
    local mode = entry.mode
    local cfg = self.routes[mode]
    if assignment.placeId ~= cfg.placeId or
        typeof(assignment.reserved) ~= "string" or #assignment.reserved == 0 then
        return
    end
    self.inFlight[player.UserId] = os.clock()
    self.changed()
    local opts = Instance.new("TeleportOptions")
    opts.ReservedServerId = assignment.reserved
    opts:SetTeleportData({ mode = mode, matchId = assignment.matchId })
    self.notify(player, "Partida encontrada! Conectando...")
    task.spawn(function()
        local ok, err = pcall(function()
            TeleportService:TeleportAsync(cfg.placeId, { player }, opts)
        end)
        if not ok then
            warn("Vitrine City: TeleportAsync global falhou: " .. tostring(err))
            self:TeleportFailed(player)
        end
    end)
end

function GlobalMatchmaker:_inspect(player, entry)
    local map = mapFor(entry.mode)
    local ok, ticket = pcall(function()
        return map:GetAsync(key(player.UserId))
    end)
    if not ok then return end -- Falha temporária: próxima leitura ou heartbeat.
    if not isValidTicket(ticket, entry.nonce, game.JobId) then
        self.active[player.UserId] = nil
        self.notify(player, "Seu ticket expirou ou foi substituído. Entre na fila novamente.")
        self.changed()
        return
    end
    local now = os.time()
    if ticket.state == "waiting" then
        if now >= entry.nextHeartbeat then
            local success, updated = pcall(function()
                return map:UpdateAsync(key(player.UserId), function(old, sortKey)
                    if not isValidTicket(old, entry.nonce, game.JobId) or old.state ~= "waiting" then
                        return nil
                    end
                    local fresh = table.clone(old)
                    fresh.expiresAt = now + WAIT_LEASE_SECONDS
                    return fresh, sortKey
                end, QUEUE_TTL)
            end)
            if success and updated then entry.nextHeartbeat = now + 20 end
        end
    elseif ticket.state == "claimed" or ticket.state == "assigned" then
        if ticket.state == "assigned" and typeof(ticket.matchId) == "string" then
            local matchOk, match = pcall(function() return matches:GetAsync(ticket.matchId) end)
            if matchOk and match and match.ready and match.mode == entry.mode
                and match.reserved == ticket.reserved then
                self:_send(player, entry, {
                    placeId = match.placeId, reserved = match.reserved, matchId = ticket.matchId
                })
                return
            end
        end
        if ticket.expiresAt <= now or (ticket.claimedAt and now - ticket.claimedAt >= 30) then
            -- Se o match morreu antes de ficar pronto, liberar o claim.
            self:_rollback(entry.mode, key(player.UserId), ticket.matchId)
        end
    else
        self.active[player.UserId] = nil
        self.notify(player, "Fila encerrada. Entre novamente quando quiser.")
        self.changed()
    end
end

function GlobalMatchmaker:_runPlayers()
    while true do
        task.wait(POLL_SECONDS)
        for userId, entry in pairs(self.active) do
            local player = Players:GetPlayerByUserId(userId)
            if player and player.Parent == Players then
                local started = self.inFlight[userId]
                if started then
                    if os.clock() - started >= FLIGHT_TIMEOUT then
                        self:TeleportFailed(player, "Tempo limite de conexão. Tente entrar novamente.")
                    end
                else
                    task.spawn(function()
                        if self.active[userId] == entry then self:_inspect(player, entry) end
                    end)
                end
            end
        end
        self.changed()
    end
end

function GlobalMatchmaker:_runCoordinator()
    task.wait(math.random(1, 4))
    while true do
        for _, mode in ipairs(MODES) do
            self:_coordinate(mode)
        end
        task.wait(COORDINATE_SECONDS + math.random())
    end
end

return GlobalMatchmaker
