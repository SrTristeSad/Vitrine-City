--!nonstrict
-- Eventos econômicos: modificadores por categoria, sem NPCs adicionais.
-- Os eventos nunca alteram os estoques já comprados por jogadores.
local MarketEvents = {}

MarketEvents.List = {
    {
        id = "dia_comum",
        title = "Dia comum",
        description = "Mercado estável, sem mudanças de oferta ou consumo.",
        demand = {},
        supply = {},
    },
    {
        id = "queijo_em_falta",
        title = "Leite em falta",
        description = "Fornecedores entregam menos queijos; clientes continuam procurando.",
        demand = { queijo = 1.25 },
        supply = { queijo = 0.45 },
    },
    {
        id = "festival_da_moda",
        title = "Festival da moda",
        description = "Mais moradores procuram roupas durante a feira.",
        demand = { roupa = 1.8 },
        supply = {},
    },
    {
        id = "safra_farta",
        title = "Safra abundante",
        description = "Mais arroz chega aos atacadistas nesta temporada.",
        demand = { arroz = 1.1 },
        supply = { arroz = 1.8 },
    },
    {
        id = "cafe_da_manha",
        title = "Manhã na padaria",
        description = "A procura por pães aumenta no bairro.",
        demand = { pao = 1.65 },
        supply = {},
    },
}

MarketEvents.ById = {}
for _, item in ipairs(MarketEvents.List) do
    MarketEvents.ById[item.id] = item
end

function MarketEvents.Start()
    return MarketEvents.ById.dia_comum
end

function MarketEvents.Next(previous, rng)
    if #MarketEvents.List == 1 then return MarketEvents.List[1] end
    local result = previous
    -- Evitar repetição da mesma notícia em dias consecutivos.
    for _ = 1, 8 do
        local candidate = MarketEvents.List[rng:NextInteger(1, #MarketEvents.List)]
        if candidate.id ~= previous.id then
            result = candidate
            break
        end
    end
    if result == previous then
        for _, item in ipairs(MarketEvents.List) do
            if item.id ~= previous.id then return item end
        end
    end
    return result
end

function MarketEvents.DemandFactor(event, category)
    local value = event and event.demand and event.demand[category]
    return typeof(value) == "number" and math.clamp(value, 0.25, 3) or 1
end

function MarketEvents.SupplyFactor(event, category)
    local value = event and event.supply and event.supply[category]
    return typeof(value) == "number" and math.clamp(value, 0, 3) or 1
end

return MarketEvents
