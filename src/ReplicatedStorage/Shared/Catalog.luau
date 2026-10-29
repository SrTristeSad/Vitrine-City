--!nonstrict
-- Valores fictícios em moedas do jogo, nunca Robux.
local items = {
    { id = "queijo_serra", name = "Queijo Serra", category = "queijo", brand = "Serra", wholesale = 12, retail = 22, weight = 12, initialSupply = 35, shipment = 18, color = Color3.fromRGB(244, 219, 91) },
    { id = "queijo_vale", name = "Queijo Vale", category = "queijo", brand = "Vale", wholesale = 9, retail = 17, weight = 12, initialSupply = 40, shipment = 24, color = Color3.fromRGB(249, 240, 164) },
    { id = "camiseta_urbana", name = "Camiseta Urbana", category = "roupa", brand = "Urbana", wholesale = 22, retail = 39, weight = 12, initialSupply = 18, shipment = 10, color = Color3.fromRGB(61, 155, 223) },
    { id = "camiseta_basica", name = "Camiseta Básica", category = "roupa", brand = "Básica", wholesale = 14, retail = 26, weight = 12, initialSupply = 24, shipment = 14, color = Color3.fromRGB(87, 198, 144) },
    { id = "pao", name = "Pão Artesanal", category = "pao", brand = "Forno", wholesale = 5, retail = 11, weight = 17, initialSupply = 60, shipment = 36, color = Color3.fromRGB(202, 142, 72) },
    { id = "arroz", name = "Arroz 1kg", category = "arroz", brand = "Campo", wholesale = 7, retail = 14, weight = 15, initialSupply = 55, shipment = 30, color = Color3.fromRGB(237, 233, 221) },
}
local byId, byCategory = {}, {}
for _, item in ipairs(items) do
    byId[item.id] = item
    byCategory[item.category] = byCategory[item.category] or {}
    table.insert(byCategory[item.category], item)
end
return { List = items, ById = byId, ByCategory = byCategory }
