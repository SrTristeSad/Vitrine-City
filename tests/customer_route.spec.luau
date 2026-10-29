-- Testes geométricos das rotas comerciais: executáveis no Luau CLI.
local Route = require("../src/ReplicatedStorage/Shared/CustomerRoute")

local function near(a, b, epsilon)
    return math.abs(a - b) < (epsilon or 0.00001)
end

for _, side in ipairs({ -1, 1 }) do
    local lot = { x = 22, z = 43 * side, side = side }
    local facade = lot.z - side * 15
    for idx = 1, 6 do
        local shelfX, shelfZ = Route.ShelfPosition(lot, idx)
        assert(near(math.abs(shelfX - lot.x), 6.8), "corredor interno")
        assert((shelfZ - facade) * side >= 11.399, "gôndola está dentro da loja")
        assert((shelfZ - facade) * side <= 25.5, "gôndola não atravessa fundo")

        local approach = Route.Approach(lot, 0, idx)
        assert(#approach == 5, "aproximação = calçada, entrada e gôndola")
        assert(near(approach[1].x, lot.x) and near(approach[1].z, 17 * side))
        assert(near(approach[2].z, facade - side * 2.8), "porta exterior")
        assert(near(approach[3].z, facade + side * 5.0), "corredor interior")
        assert(near(approach[5].x, shelfX) and near(approach[5].z, shelfZ), "gôndola correta")
        assert(approach[5].hold > 0, "cliente observa produto")

        local checkout = Route.Checkout(lot, idx)
        assert(#checkout == 3, "deve passar pelo corredor até o caixa")
        assert(near(checkout[1].x, lot.x) and near(checkout[1].z, shelfZ), "retorna ao corredor")
        assert(near(checkout[3].x, lot.x + 6.8), "caixa ao lado direito")
        assert(near(checkout[3].z, facade + side * 6.0), "caixa dentro da loja")

        local exitRoute = Route.Exit(lot, 0)
        assert(#exitRoute == 4 and near(exitRoute[3].z, side * 17), "sai para calçada")
        assert(exitRoute[4].x < lot.x, "despedida para lado original")
        local reverseExit = Route.Exit(lot, lot.x + 50)
        assert(reverseExit[4].x > lot.x, "despedida para outro lado")
    end
end
assert(Route.Duration(0, 0, 0, 0) >= 0.28, "tween não pode ter duração zero")
assert(Route.Duration(0, 0, 999, 0) <= 5.5, "tween não pode ficar preso")
print("PASS: percursos NPC em ambos os lados da rua, corredor, gôndolas, caixa e saída.")
