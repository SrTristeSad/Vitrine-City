--!nonstrict
-- Guia de primeira loja. Lê apenas estado replicado, sem dar dinheiro nem alterar gameplay.
local Guide = {}

function Guide.Step(lotId, products, sales)
    if type(lotId) ~= "number" or lotId <= 0 then
        return {
            id = "rent", title = "1 / 4 • Abra seu negócio",
            detail = "Procure a entrada amarela de uma loja disponível e pressione E para alugar.",
            action = "explore",
        }
    end

    local inStorage, onShelf = 0, 0
    local items = typeof(products) == "table" and products or {}
    for _, item in ipairs(items) do
        inStorage += math.max(0, tonumber(item.storage) or 0)
        onShelf += math.max(0, tonumber(item.shelf) or 0)
    end

    if inStorage == 0 and onShelf == 0 then
        return {
            id = "buy", title = "2 / 4 • Compre mercadorias",
            detail = "Sua loja está vazia. Abra o estoque e compre 5 unidades de um produto.",
            action = "manage",
        }
    end
    if onShelf == 0 then
        return {
            id = "stock", title = "3 / 4 • Abasteça as gôndolas",
            detail = "Seu depósito tem produtos, mas clientes só compram itens expostos na prateleira.",
            action = "manage",
        }
    end
    if (tonumber(sales) or 0) <= 0 then
        return {
            id = "sell", title = "4 / 4 • Aguarde a primeira venda",
            detail = "Prateleiras abastecidas! Veja um NPC entrar, procurar o produto e passar no caixa.",
            action = "observe",
        }
    end
    return {
        id = "grow", title = "Loja funcionando • Continue crescendo",
        detail = "Acompanhe as vendas no relatório. Preços, estoque e concorrência mudam o resultado.",
        action = "manage",
    }
end

return Guide
