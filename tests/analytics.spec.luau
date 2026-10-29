-- Testes do núcleo de indicadores sem dependência de Workspace, jogadores ou DataStore.
local Analytics = require("../src/ReplicatedStorage/Shared/ShopAnalytics")

local queijo = { id = "queijo", name = "Queijo", category = "queijo", retail = 20 }
local pao = { id = "pao", name = "Pão", category = "pao", retail = 10 }
local catalog = {
    List = { queijo, pao },
    ByCategory = { queijo = { queijo }, pao = { pao } },
}
local stats = Analytics.New()
local lot = {
    shelf = { queijo = 0, pao = 0 },
    stock = { queijo = 0, pao = 0 },
    prices = { queijo = 20, pao = 10 },
}
local need = { category = "queijo", budget = 19 }

assert(Analytics.Reason(lot, need, catalog, nil, 0) == "shelf_empty", "Sem produto")
lot.stock.queijo = 5
assert(Analytics.Reason(lot, need, catalog, nil, 0) == "not_restocked", "Depósito sem reposição")
lot.shelf.queijo = 2
lot.stock.queijo = 3
assert(Analytics.Reason(lot, need, catalog, nil, 0) == "too_expensive", "Preço alto")
need.budget = 25
assert(Analytics.Reason(lot, need, catalog, queijo, 15) == "price_changed", "Preço mudou")
assert(Analytics.Reason(lot, need, catalog, queijo, 20) == "no_sale", "Oferta disponível")

Analytics.BeginVisit(stats, "queijo")
Analytics.RecordLost(stats, "too_expensive")
Analytics.BeginVisit(stats, "queijo")
Analytics.RecordSale(stats, queijo, 20, 12.5)
Analytics.BeginVisit(stats, "pao")
Analytics.RecordLost(stats, "not_restocked")

local view = Analytics.View(stats, catalog)
assert(view.visits == 3, "Três visitas")
assert(view.sales == 1, "Uma venda")
assert(view.lost == 2, "Duas perdas")
assert(view.conversion == 33.3, "Conversão correta")
assert(view.revenue == 20 and view.cogs == 12 and view.grossProfit == 7, "Margem bruta")
assert(view.products[1].id == "queijo" and view.products[1].units == 1)
assert(view.categories[1].category == "queijo" and view.categories[1].demand == 2)
assert(stats.reasons.too_expensive == 1 and stats.reasons.not_restocked == 1)

local restored = Analytics.Restore({
    visits = -30, sales = 2, lost = math.huge,
    reasons = { too_expensive = 5, nonsense = 1234 },
    demand = { queijo = 3, unknown = 999 },
    units = { queijo = 2, unknown = 999 },
    productRevenue = { queijo = 40 },
}, catalog)
assert(restored.visits == 0 and restored.sales == 2 and restored.lost == 0, "Sanitização")
assert(restored.reasons.nonsense == nil, "Motivo não reconhecido")
assert(restored.units.unknown == nil, "Item não reconhecido")
assert(restored.productRevenue.queijo == 40, "Receita restaurada")
local corrupted = Analytics.Restore({
    reasons = 123, demand = "inválido", units = true, productRevenue = false,
}, catalog)
assert(corrupted.reasons.too_expensive == 0 and corrupted.units.queijo == 0, "Subtabelas corrompidas")
print("PASS: motivo de perdas, visitas, conversão, custos, produtos e restauração.")
