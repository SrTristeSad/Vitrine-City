-- Os próximos passos devem reagir ao estoque real, sem conceder bônus nem vender automaticamente.
local Guide = require("../src/ReplicatedStorage/Shared/ShopGuide")

local function check(lot, products, sales, expected)
    local result = Guide.Step(lot, products, sales)
    assert(result.id == expected, string.format("esperado %s, veio %s", expected, tostring(result.id)))
    assert(type(result.title) == "string" and #result.title > 0)
    assert(type(result.detail) == "string" and #result.detail > 0)
    return result
end

check(0, {}, 0, "rent")
check(1, {}, 0, "buy")
check(1, { { storage = 0, shelf = 0 } }, 0, "buy")
check(2, { { storage = 5, shelf = 0 } }, 0, "stock")
check(3, { { storage = 2, shelf = 3 } }, 0, "sell")
check(4, { { storage = 0, shelf = 2 } }, 1, "grow")
check(5, { { storage = 0, shelf = 0 } }, 1, "buy")
check(5, { { storage = 2, shelf = 0 } }, 3, "stock")
check(6, { { storage = -10, shelf = -9 } }, 0, "buy")
assert(check(0, {}, 0, "rent").action == "explore")
assert(check(1, {}, 0, "buy").action == "manage")
assert(check(1, { { storage = 0, shelf = 3 } }, 0, "sell").action == "observe")
print("PASS: aluguel, primeiro estoque, reposição, venda e gestão pós-venda.")
