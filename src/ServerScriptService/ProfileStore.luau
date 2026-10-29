--!nonstrict
-- Persistência da Rua Livre. Não usar para partidas ranqueadas.
-- Carregamento com lease, UpdateAsync atômico e liberação ao sair.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ProfileStore = {}
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local VERSION = 1
local KEY_PREFIX = "player_v1_"
local LEASE_SECONDS = 180
local serverToken = HttpService:GenerateGUID(false)
local saving = {}
local store = DataStoreService:GetDataStore("VitrineCity_RuaLivre_V1")

local function money(v, fallback)
    if typeof(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return fallback end
    return math.clamp(math.floor(v), 0, 1000000000)
end

local function cleanShop(shop, catalog)
    if typeof(shop) ~= "table" then return nil end
    local result = { stock = {}, shelf = {}, costValue = {}, prices = {}, reputation = 50, hasEmployee = shop.hasEmployee == true }
    result.reputation = math.clamp(money(shop.reputation, 50), 10, 100)
    for _, item in ipairs(catalog.List) do
        local id = item.id
        result.stock[id] = math.clamp(money(shop.stock and shop.stock[id], 0), 0, 100000)
        result.shelf[id] = math.clamp(money(shop.shelf and shop.shelf[id], 0), 0, Config.ShelfCapacity)
        result.costValue[id] = money(shop.costValue and shop.costValue[id], 0)
        result.prices[id] = math.clamp(money(shop.prices and shop.prices[id], item.retail), 1, item.retail * 3)
    end
    return result
end

local function cleanProfile(raw, catalog)
    if typeof(raw) ~= "table" then raw = {} end
    return {
        schema = VERSION,
        cash = money(raw.cash, Config.StartingCash),
        revenue = money(raw.revenue, 0),
        expenses = money(raw.expenses, 0),
        sales = money(raw.sales, 0),
        penalties = money(raw.penalties, 0),
        shop = cleanShop(raw.shop, catalog),
    }
end

local function profilePayload(profile, catalog)
    -- Snapshot independente do estado mutável em memória.
    local sanitized = cleanProfile(profile, catalog)
    return sanitized
end

local function disabled()
    return not Config.SaveEnabled or (RunService:IsStudio() and not Config.StudioPersistence)
end

function ProfileStore.Load(userId, catalog)
    if disabled() then return cleanProfile({}, catalog), "session" end
    local key = KEY_PREFIX .. userId
    for attempt = 1, 2 do
        local rejected = nil
        local now = os.time()
        local success, value = pcall(function()
            return store:UpdateAsync(key, function(old)
                if old ~= nil and typeof(old) ~= "table" then rejected = "invalid"; return nil end
                if old and old.schema ~= VERSION then rejected = "schema"; return nil end
                if old and old.lease and old.lease.token ~= serverToken and
                    typeof(old.lease.expires) == "number" and old.lease.expires > now then
                    rejected = "locked"
                    return nil
                end
                local clean = cleanProfile(old, catalog)
                clean.lease = { token = serverToken, expires = now + LEASE_SECONDS }
                return clean
            end)
        end)
        if success and value and value.lease and value.lease.token == serverToken then
            return cleanProfile(value, catalog), "persistent"
        end
        if rejected == "locked" then return nil, "locked" end
        if rejected == "schema" or rejected == "invalid" then return nil, "schema" end
        warn("Vitrine City: erro de leitura de perfil " .. userId .. ": " .. tostring(value))
        if attempt < 2 then task.wait(2) end
    end
    return nil, "unavailable"
end

local function write(userId, profile, catalog, release)
    if disabled() then return true end
    local waits = 0
    while saving[userId] and waits < 40 do
        task.wait(0.1)
        waits += 1
    end
    if saving[userId] then return false, "busy" end
    saving[userId] = true
    local key = KEY_PREFIX .. userId
    local snapshot = profilePayload(profile, catalog)
    local reason = "unavailable"
    local ok = false
    for attempt = 1, 2 do
        local now = os.time()
        local rejected = false
        local success, value = pcall(function()
            return store:UpdateAsync(key, function(old)
                if typeof(old) ~= "table" or old.schema ~= VERSION or
                    typeof(old.lease) ~= "table" or old.lease.token ~= serverToken then
                    rejected = true
                    return nil
                end
                local next = table.clone(snapshot)
                if not release then
                    next.lease = { token = serverToken, expires = now + LEASE_SECONDS }
                end
                return next
            end)
        end)
        if success and value and (release or (value.lease and value.lease.token == serverToken)) then
            ok = true
            break
        end
        if rejected then reason = "lock_lost"; break end
        reason = tostring(value)
        if attempt < 2 then task.wait(1) end
    end
    saving[userId] = nil
    return ok, ok and nil or reason
end

function ProfileStore.Save(userId, profile, catalog)
    return write(userId, profile, catalog, false)
end

function ProfileStore.Release(userId, profile, catalog)
    return write(userId, profile, catalog, true)
end

return ProfileStore
