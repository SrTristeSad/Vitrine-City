--!nonstrict
-- Métricas de gestão: calculadas APENAS no servidor, sem criar NPCs extras.
-- Contagens são de visitas concluídas a uma loja, não da população inteira.
local ShopAnalytics = {}

ShopAnalytics.Reasons = {
    shelf_empty = "Prateleira vazia",
    not_restocked = "Produto no depósito, mas não exposto",
    too_expensive = "Preço acima do orçamento",
    price_changed = "Oferta alterada durante a visita",
    no_sale = "Compra não concluída",
}

local MAX = 100000000
local function count(value)
    if typeof(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return 0 end
    return math.clamp(math.floor(value + 0.5), 0, MAX)
end

local function field(source, key)
    if typeof(source) == "table" then return source[key] end
    return nil
end

function ShopAnalytics.New()
    return {
        visits = 0, sales = 0, lost = 0, salesValue = 0, cogs = 0,
        reasons = { shelf_empty = 0, not_restocked = 0, too_expensive = 0, price_changed = 0, no_sale = 0 },
        demand = {},
        units = {},
        productRevenue = {},
    }
end

function ShopAnalytics.Restore(raw, catalog)
    local stats = ShopAnalytics.New()
    if typeof(raw) ~= "table" then return stats end
    for _, key in ipairs({ "visits", "sales", "lost", "salesValue", "cogs" }) do
        stats[key] = count(raw[key])
    end
    for reason in pairs(stats.reasons) do
        stats.reasons[reason] = count(field(raw.reasons, reason))
    end
    for category in pairs(catalog.ByCategory) do
        stats.demand[category] = count(field(raw.demand, category))
    end
    for _, p in ipairs(catalog.List) do
        stats.units[p.id] = count(field(raw.units, p.id))
        stats.productRevenue[p.id] = count(field(raw.productRevenue, p.id))
    end
    return stats
end

function ShopAnalytics.BeginVisit(stats, category)
    stats.visits += 1
    stats.demand[category] = (stats.demand[category] or 0) + 1
end

function ShopAnalytics.RecordSale(stats, product, price, historicalCost)
    stats.sales += 1
    stats.salesValue += price
    stats.cogs += historicalCost
    stats.units[product.id] = (stats.units[product.id] or 0) + 1
    stats.productRevenue[product.id] = (stats.productRevenue[product.id] or 0) + price
end

function ShopAnalytics.Reason(lot, need, catalog, attemptedProduct, attemptedPrice)
    if attemptedProduct then
        if (lot.shelf[attemptedProduct.id] or 0) < 1 then
            if (lot.stock[attemptedProduct.id] or 0) > 0 then return "not_restocked" end
            return "shelf_empty"
        end
        if (lot.prices[attemptedProduct.id] or attemptedProduct.retail) ~= attemptedPrice then return "price_changed" end
    end
    local group = catalog.ByCategory[need.category] or {}
    local shelfAvailable, storageAvailable, affordable = false, false, false
    for _, product in ipairs(group) do
        local shelf = lot.shelf[product.id] or 0
        if (lot.stock[product.id] or 0) > 0 then storageAvailable = true end
        if shelf > 0 then
            shelfAvailable = true
            if (lot.prices[product.id] or product.retail) <= need.budget then
                affordable = true
            end
        end
    end
    if not shelfAvailable then
        return storageAvailable and "not_restocked" or "shelf_empty"
    end
    if not affordable then return "too_expensive" end
    return "no_sale"
end

function ShopAnalytics.RecordLost(stats, reason)
    if stats.reasons[reason] == nil then reason = "no_sale" end
    stats.lost += 1
    stats.reasons[reason] += 1
end

function ShopAnalytics.View(stats, catalog)
    local categories = {}
    for category in pairs(catalog.ByCategory) do
        table.insert(categories, { category = category, demand = stats.demand[category] or 0 })
    end
    table.sort(categories, function(a, b)
        if a.demand == b.demand then return a.category < b.category end
        return a.demand > b.demand
    end)
    local products = {}
    for _, item in ipairs(catalog.List) do
        table.insert(products, {
            id = item.id, name = item.name,
            units = stats.units[item.id] or 0,
            revenue = math.floor(stats.productRevenue[item.id] or 0),
        })
    end
    table.sort(products, function(a, b)
        if a.units == b.units then return a.id < b.id end
        return a.units > b.units
    end)
    local causes = {}
    for reason, label in pairs(ShopAnalytics.Reasons) do
        table.insert(causes, { id = reason, label = label, count = stats.reasons[reason] or 0 })
    end
    table.sort(causes, function(a, b)
        if a.count == b.count then return a.id < b.id end
        return a.count > b.count
    end)
    return {
        visits = stats.visits, sales = stats.sales, lost = stats.lost,
        conversion = stats.visits > 0 and math.floor(stats.sales * 1000 / stats.visits + 0.5) / 10 or 0,
        revenue = math.floor(stats.salesValue),
        cogs = math.floor(stats.cogs),
        grossProfit = math.floor(stats.salesValue - stats.cogs),
        categories = categories, products = products, reasons = causes,
    }
end

return ShopAnalytics
