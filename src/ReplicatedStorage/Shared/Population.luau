--!nonstrict
-- 240 moradores são registros, não Models 3D nem loops por frame.
-- Empregos e renda são atualizados apenas em ciclos econômicos.
local Population = {}
local JOBS = {
    { title = "Professor", income = 73, weight = 13 },
    { title = "Enfermeiro", income = 85, weight = 10 },
    { title = "Motorista", income = 62, weight = 17 },
    { title = "Cozinheiro", income = 54, weight = 17 },
    { title = "Técnico", income = 91, weight = 13 },
    { title = "Escriturário", income = 67, weight = 16 },
    { title = "Desempregado", income = 0, weight = 14 },
}
local function rollJob(rng)
    local count = 0
    for _, job in ipairs(JOBS) do count += job.weight end
    local value = rng:NextNumber(0, count)
    for _, job in ipairs(JOBS) do
        value -= job.weight
        if value <= 0 then return job end
    end
    return JOBS[#JOBS]
end

function Population.Create(count, rng)
    local world = { people = {}, days = 0, purchases = 0, spent = 0 }
    for id = 1, count do
        local job = rollJob(rng)
        world.people[id] = {
            id = id,
            profession = job.title,
            income = job.income,
            wallet = rng:NextInteger(50, 190),
            household = rng:NextInteger(1, 5),
            preferredBrand = nil,
            busy = false,
            employedAt = nil,
        }
    end
    return world
end

function Population.StartPurchase(world, catalog, economy, rng, event, marketEvents)
    -- O cliente só aparece se houver orçamento; nunca reserva dinheiro em duplicidade.
    for _ = 1, 18 do
        local person = world.people[rng:NextInteger(1, #world.people)]
        if not person.busy then
            local need = economy.NewNeed(catalog, rng, event, marketEvents)
            need.budget = math.min(need.budget, math.floor(person.wallet * 0.65))
            if need.budget >= 5 then
                person.busy = true
                return person, need
            end
        end
    end
    return nil, nil
end

function Population.FinishPurchase(world, person, amount)
    if person and person.busy then
        if amount > 0 and person.wallet >= amount then
            person.wallet -= amount
            world.purchases += 1
            world.spent += amount
        end
        person.busy = false
    end
end

function Population.Hire(world, lotId)
    for _, person in ipairs(world.people) do
        if person.profession == "Desempregado" and not person.employedAt then
            person.profession = "Repositor"
            person.employedAt = lotId
            return person.id
        end
    end
    return nil
end

function Population.PayWorker(world, personId, amount)
    local person = personId and world.people[personId]
    if person and person.profession == "Repositor" then
        person.wallet += amount
    end
end

function Population.Layoff(world, personId)
    local person = personId and world.people[personId]
    if person and person.profession == "Repositor" then
        person.profession = "Desempregado"
        person.employedAt = nil
    end
end

function Population.StartDay(world)
    world.days += 1
    for _, person in ipairs(world.people) do
        if person.income > 0 and person.profession ~= "Repositor" then
            person.wallet += person.income
        end
        -- Moradia e contas são saídas econômicas abstratas; famílias maiores gastam mais.
        person.wallet = math.max(0, person.wallet - (6 + person.household * 2))
    end
end

function Population.Stats(world)
    local workers, unemployed, buyingPower = 0, 0, 0
    for _, person in ipairs(world.people) do
        if person.profession == "Desempregado" then unemployed += 1 else workers += 1 end
        buyingPower += person.wallet
    end
    return { residents = #world.people, employed = workers, unemployed = unemployed, buyingPower = buyingPower, purchases = world.purchases, days = world.days }
end

return Population
