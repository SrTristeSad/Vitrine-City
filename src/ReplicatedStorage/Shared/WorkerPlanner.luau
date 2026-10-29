--!nonstrict
-- Escolha do próximo serviço do repositor. É uma decisão pura, sem mover itens.
-- O servidor transfere o estoque apenas depois que o funcionário chega à gôndola.
local WorkerPlanner = {}

function WorkerPlanner.Next(catalog, stock, shelf, capacity)
    local chosen, chosenIndex, quantity, lowestShelf = nil, nil, 0, math.huge
    for index, product in ipairs(catalog.List) do
        local id = product.id
        local available = math.max(0, stock[id] or 0)
        local exposed = math.max(0, shelf[id] or 0)
        local missing = math.max(0, capacity - exposed)
        local move = math.min(10, available, missing)
        -- Priorizar a prateleira mais vazia, desempate por ordem do catálogo.
        if move > 0 and exposed < lowestShelf then
            chosen, chosenIndex, quantity, lowestShelf = product, index, move, exposed
        end
    end
    return chosen, chosenIndex, quantity
end

return WorkerPlanner
