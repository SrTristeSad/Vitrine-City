-- Testes unitários do agendamento de reposição, sem NPCs nem APIs Roblox.
local WorkerPlanner = require("../src/ReplicatedStorage/Shared/WorkerPlanner")

local catalog = {
    List = { { id = "queijo" }, { id = "pao" }, { id = "arroz" } },
}
local function next(stock, shelf, cap)
    return WorkerPlanner.Next(catalog, stock, shelf, cap or 18)
end
local p, idx, qty = next({ queijo = 5, pao = 0, arroz = 0 },
    { queijo = 0, pao = 0, arroz = 0 })
assert(p.id == "queijo" and idx == 1 and qty == 5, "somente mercadoria disponível")

p, idx, qty = next({ queijo = 9, pao = 9, arroz = 9 },
    { queijo = 8, pao = 0, arroz = 4 })
assert(p.id == "pao" and idx == 2 and qty == 9, "prioriza gôndola vazia")

p, idx, qty = next({ queijo = 100, pao = 100, arroz = 100 },
    { queijo = 17, pao = 18, arroz = 17 })
assert(p.id == "queijo" and qty == 1, "respeita capacidade e ordem estável")

p, idx, qty = next({ queijo = 2, pao = 3, arroz = 4 },
    { queijo = 18, pao = 18, arroz = 18 })
assert(p == nil and idx == nil and qty == 0, "sem serviço: tudo cheio")

p, idx, qty = next({ queijo = 0, pao = 0, arroz = 0 },
    { queijo = 0, pao = 0, arroz = 0 })
assert(p == nil and qty == 0, "sem serviço: depósito vazio")

p, idx, qty = next({ queijo = 30, pao = 0, arroz = 0 },
    { queijo = 0, pao = 0, arroz = 0 })
assert(p.id == "queijo" and qty == 10, "limita serviço a dez unidades")

print("PASS: prioridade do repositor, capacidade, quantidade e casos sem serviço.")
