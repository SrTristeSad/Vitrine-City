--!nonstrict
-- Núcleo de decisões isolado do mapa / interface.
local Economy = {}

function Economy.NewNeed(catalog, rng)
    local total = 0
    for _, p in ipairs(catalog.List) do total += p.weight end
    local roll = rng:NextNumber(0, total)
    local picked = catalog.List[#catalog.List]
    for _, p in ipairs(catalog.List) do
        roll -= p.weight
        if roll <= 0 then picked = p; break end
    end
    local group = catalog.ByCategory[picked.category]
    local preferred = group[rng:NextInteger(1, #group)]
    return {
        category = picked.category,
        brand = preferred.brand,
        budget = math.floor(preferred.retail * rng:NextNumber(0.95, 1.7)),
        brandLoyalty = rng:NextNumber() < 0.35,
        priceSensitive = rng:NextNumber(0.4, 1.3),
    }
end

local function offers(store, need, catalog)
    local result = {}
    for _, p in ipairs(catalog.ByCategory[need.category] or {}) do
        local price = store.prices[p.id] or p.retail
        if (store.shelf[p.id] or 0) > 0 and price <= need.budget then
            table.insert(result, { product = p, price = price })
        end
    end
    return result
end

function Economy.PickOffer(stores, need, catalog, mode, rng, arrivalX)
    if mode == "normal" then
        if #stores == 0 then return nil end
        local store = stores[rng:NextInteger(1, #stores)]
        local winner, score = nil, -math.huge
        for _, offer in ipairs(offers(store, need, catalog)) do
            local s = -offer.price + (offer.product.brand == need.brand and 8 or 0)
            if s > score then winner, score = offer, s end
        end
        return { store = store, product = winner and winner.product or nil, price = winner and winner.price or 0 }
    end

    local winner, highest = nil, -math.huge
    for _, store in ipairs(stores) do
        for _, offer in ipairs(offers(store, need, catalog)) do
            local brand = offer.product.brand == need.brand and (need.brandLoyalty and 3.5 or 0.7) or 0
            local discount = ((offer.product.retail - offer.price) / offer.product.retail) * 5 * need.priceSensitive
            local score = brand + discount + (store.reputation - 50) / 40 - math.abs(store.x - arrivalX) / 150 + rng:NextNumber(-0.8, 0.8)
            if score > highest then highest, winner = score, { store = store, product = offer.product, price = offer.price } end
        end
    end
    return winner
end

function Economy.NetWorth(account, lot)
    local total = account.cash + account.reserved - account.penalties
    if lot then
        for _, cost in pairs(lot.costValue) do total += cost end
    end
    return math.floor(total)
end

return Economy
