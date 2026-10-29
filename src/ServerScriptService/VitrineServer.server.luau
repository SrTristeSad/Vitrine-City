--!nonstrict
-- Vitrine City | servidor autoritativo. Progresso de sessão, sem DataStore.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Economy = require(Shared:WaitForChild("Economy"))
local Population = require(Shared:WaitForChild("Population"))
local rng = Random.new()
local population = Population.Create(Config.VirtualResidents, rng)
local competitive = Config.Mode ~= "normal"

local remotes = Instance.new("Folder")
remotes.Name = "VitrineRemotes"
remotes.Parent = ReplicatedStorage
local function event(name)
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = remotes
    return remote
end
local actionEvent, stateEvent, noticeEvent = event("Action"), event("State"), event("Notice")

local map = Instance.new("Folder")
map.Name = "VitrineCityMap"
map.Parent = Workspace
local accounts, lots, supplier, bids = {}, {}, {}, {}
local activeCustomers, customerVisits, completedSales = 0, 0, 0
local round = 1
local remaining = Config.RoundSeconds
local elapsedRound = 0
local lastAction = {}
local positions = { -66, -22, 22, 66 }

for _, product in ipairs(Catalog.List) do
    supplier[product.id] = product.initialSupply
end

local function part(parent, name, size, position, color, transparent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = CFrame.new(position)
    p.Anchored = true
    p.Material = Enum.Material.SmoothPlastic
    p.Color = color
    p.Transparency = transparent and 1 or 0
    p.Parent = parent
    return p
end

local function sign(anchor, text, offset)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Letreiro"
    gui.Size = UDim2.fromOffset(205, 70)
    gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 95
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(21, 32, 44)
    label.BackgroundTransparency = 0.1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = label
    return label
end

local function message(player, text)
    if player and player.Parent == Players then
        noticeEvent:FireClient(player, text)
    end
end

local function getLot(userId)
    for _, lot in ipairs(lots) do
        if lot.ownerId == userId then return lot end
    end
    return nil
end

local function updateSign(lot)
    local owner = lot.ownerId and Players:GetPlayerByUserId(lot.ownerId)
    lot.label.Text = owner and (owner.DisplayName .. "\nLOJA " .. lot.id)
        or ("LOJA " .. lot.id .. " - DISPONÍVEL\nAluguel $" .. Config.LeaseCost)
    lot.prompt.Enabled = owner == nil
end

local function refreshShelf(lot)
    for idx, product in ipairs(Catalog.List) do
        local display = lot.displays[product.id]
        if not display then
            local x = lot.x + ((idx - 1) % 3 - 1) * 7
            local z = lot.z + (math.floor((idx - 1) / 3) - 0.5) * 7
            local stand = part(lot.model, "Prateleira", Vector3.new(5.8, 1, 4.6), Vector3.new(x, 1.1, z), Color3.fromRGB(87, 94, 103))
            local goods = part(lot.model, product.name, Vector3.new(4.8, 1, 3.6), Vector3.new(x, 2.2, z), product.color)
            goods.CanCollide = false
            display = { goods = goods, text = sign(stand, "", Vector3.new(0, 3, 0)) }
            lot.displays[product.id] = display
        end
        local qty = lot.shelf[product.id] or 0
        display.goods.Transparency = qty > 0 and 0 or 1
        display.text.Text = product.name .. "\n$" .. lot.prices[product.id] .. " | " .. qty .. " un."
    end
end

local function makeMap()
    part(map, "Grama", Vector3.new(220, 1, 135), Vector3.new(0, -0.6, 0), Color3.fromRGB(102, 155, 110))
    part(map, "Rua", Vector3.new(210, 0.2, 28), Vector3.new(0, 0, 0), Color3.fromRGB(55, 62, 71))
    for i = -4, 4 do
        part(map, "Faixa", Vector3.new(8, 0.04, 0.35), Vector3.new(i * 23, 0.14, 0), Color3.fromRGB(246, 214, 121))
    end
    for _, side in ipairs({ -1, 1 }) do
        part(map, "Calçada", Vector3.new(210, 0.4, 8), Vector3.new(0, 0.15, side * 18), Color3.fromRGB(201, 204, 199))
        for _, x in ipairs(positions) do
            local id = #lots + 1
            local z = side * 43
            local frontZ = z - side * 15
            local model = Instance.new("Model")
            model.Name = "Loja " .. id
            model.Parent = map
            part(model, "Piso", Vector3.new(31, 0.5, 31), Vector3.new(x, 0, z), Color3.fromRGB(223, 217, 197))
            part(model, "Fundo", Vector3.new(31, 9, 1), Vector3.new(x, 4.5, z + side * 15), Color3.fromRGB(231, 225, 215))
            part(model, "Parede E", Vector3.new(1, 9, 31), Vector3.new(x - 15, 4.5, z), Color3.fromRGB(231, 225, 215))
            part(model, "Parede D", Vector3.new(1, 9, 31), Vector3.new(x + 15, 4.5, z), Color3.fromRGB(231, 225, 215))
            part(model, "Fachada E", Vector3.new(11, 9, 1), Vector3.new(x - 10, 4.5, frontZ), Color3.fromRGB(107, 161, 191))
            part(model, "Fachada D", Vector3.new(11, 9, 1), Vector3.new(x + 10, 4.5, frontZ), Color3.fromRGB(107, 161, 191))
            part(model, "Marquise", Vector3.new(31, 1, 4), Vector3.new(x, 9.3, frontZ), Color3.fromRGB(42, 117, 172))
            local door = part(model, "Alugue aqui", Vector3.new(4, 0.3, 4), Vector3.new(x, 0.3, frontZ - side * 3), Color3.fromRGB(255, 201, 79))
            door.CanCollide = false
            local prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = "Alugar loja"
            prompt.ObjectText = "Loja " .. id
            prompt.MaxActivationDistance = 12
            prompt.HoldDuration = 0.3
            prompt.Parent = door
            local anchor = part(model, "Placa", Vector3.new(1, 1, 1), Vector3.new(x, 8, frontZ), Color3.fromRGB(0, 0, 0), true)
            anchor.CanCollide = false
            local lot = {
                id = id, x = x, z = z, side = side, model = model, door = door,
                prompt = prompt, label = sign(anchor, "", Vector3.new(0, 4, 0)),
                ownerId = nil, employeeId = nil, employeeModel = nil,
                stock = {}, shelf = {}, prices = {}, costValue = {}, displays = {},
                missedBills = 0, reputation = 50,
            }
            for _, product in ipairs(Catalog.List) do
                lot.stock[product.id], lot.shelf[product.id] = 0, 0
                lot.prices[product.id], lot.costValue[product.id] = product.retail, 0
            end
            table.insert(lots, lot)
            updateSign(lot)
            refreshShelf(lot)
        end
    end
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Praça central"
    spawn.Size = Vector3.new(10, 1, 10)
    spawn.CFrame = CFrame.new(-98, 1, 0)
    spawn.Color = Color3.fromRGB(65, 190, 150)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Parent = map
end

local function npcModel(name, x, z, employee)
    local model = Instance.new("Model")
    model.Name = employee and "Funcionário NPC" or "Cliente NPC"
    model.Parent = map
    local root = part(model, "Root", Vector3.new(0.5, 0.5, 0.5), Vector3.new(x, 3, z), Color3.new(1, 1, 1), true)
    root.CanCollide = false
    model.PrimaryPart = root
    local shirt = employee and Color3.fromRGB(62, 125, 230)
        or Color3.fromRGB(rng:NextInteger(80, 220), rng:NextInteger(90, 220), rng:NextInteger(80, 220))
    local body = {
        { "Tronco", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0), shirt },
        { "Cabeça", Vector3.new(1.4, 1.4, 1.4), Vector3.new(0, 1.7, 0), Color3.fromRGB(214, 170, 132) },
        { "Perna E", Vector3.new(0.8, 1.6, 0.8), Vector3.new(-0.5, -1.7, 0), Color3.fromRGB(55, 68, 86) },
        { "Perna D", Vector3.new(0.8, 1.6, 0.8), Vector3.new(0.5, -1.7, 0), Color3.fromRGB(55, 68, 86) },
    }
    for _, piece in ipairs(body) do
        local limb = part(model, piece[1], piece[2], Vector3.new(x, 3, z) + piece[3], piece[4])
        limb.CanCollide = false
    end
    sign(root, name, Vector3.new(0, 3.6, 0))
    return model
end

local function moveNpc(model, x, z, seconds)
    if not model.Parent then return end
    local driver = Instance.new("CFrameValue")
    driver.Value = model:GetPivot()
    local conn = driver.Changed:Connect(function(value)
        if model.Parent then model:PivotTo(value) end
    end)
    local tween = TweenService:Create(driver, TweenInfo.new(seconds, Enum.EasingStyle.Linear), { Value = CFrame.new(x, 3, z) })
    tween:Play()
    tween.Completed:Wait()
    conn:Disconnect()
    driver:Destroy()
end

local function restock(lot, id)
    local move = math.min(10, lot.stock[id], math.max(0, Config.ShelfCapacity - lot.shelf[id]))
    if move > 0 then
        lot.stock[id] -= move
        lot.shelf[id] += move
    end
    return move
end

local function resetLot(lot)
    if lot.employeeId then Population.Layoff(population, lot.employeeId) end
    if lot.employeeModel then lot.employeeModel:Destroy() end
    lot.ownerId, lot.employeeId, lot.employeeModel = nil, nil, nil
    lot.missedBills, lot.reputation = 0, 50
    for _, product in ipairs(Catalog.List) do
        lot.stock[product.id], lot.shelf[product.id] = 0, 0
        lot.prices[product.id], lot.costValue[product.id] = product.retail, 0
    end
    updateSign(lot)
    refreshShelf(lot)
end

local function refundBids(userId)
    for i = #bids, 1, -1 do
        local bid = bids[i]
        if bid.userId == userId then
            local account = accounts[userId]
            if account then
                account.cash += bid.escrow
                account.reserved -= bid.escrow
            end
            table.remove(bids, i)
        end
    end
end

local function rent(player, lot)
    local account = accounts[player.UserId]
    if not account or lot.ownerId or getLot(player.UserId) or account.eliminated then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - lot.door.Position).Magnitude > 18 then return end
    if account.cash < Config.LeaseCost then message(player, "Saldo insuficiente para alugar."); return end
    account.cash -= Config.LeaseCost
    account.expenses += Config.LeaseCost
    account.everRented = true
    lot.ownerId = player.UserId
    updateSign(lot)
    message(player, "Loja " .. lot.id .. " alugada! Compre mercadorias, reponha e defina os preços.")
end

local function sendState(player)
    local account = accounts[player.UserId]
    if not account then return end
    local lot = getLot(player.UserId)
    local products = {}
    for _, p in ipairs(Catalog.List) do
        table.insert(products, {
            id = p.id, name = p.name, brand = p.brand, wholesale = p.wholesale,
            price = lot and lot.prices[p.id] or p.retail,
            storage = lot and lot.stock[p.id] or 0,
            shelf = lot and lot.shelf[p.id] or 0,
            supplier = competitive and supplier[p.id] or -1,
        })
    end
    local ranking = {}
    for userId, other in pairs(accounts) do
        local plr = Players:GetPlayerByUserId(userId)
        if plr then
            table.insert(ranking, { name = plr.DisplayName, worth = Economy.NetWorth(other, getLot(userId)), sales = other.sales, eliminated = other.eliminated })
        end
    end
    table.sort(ranking, function(a, b) return a.worth > b.worth end)
    local pending = {}
    for _, bid in ipairs(bids) do
        if bid.userId == player.UserId then
            table.insert(pending, { product = bid.productId, qty = bid.qty, premium = bid.premium, escrow = bid.escrow })
        end
    end
    stateEvent:FireClient(player, {
        mode = Config.Mode, cash = account.cash, sales = account.sales,
        profit = math.floor(account.revenue - account.expenses),
        lot = lot and lot.id or 0, hasEmployee = lot ~= nil and lot.employeeId ~= nil,
        eliminated = account.eliminated, products = products, ranking = ranking, bids = pending,
        round = round, remaining = remaining, citizens = Population.Stats(population),
        customers = customerVisits, customerSales = completedSales,
    })
end

local function pushState()
    for _, player in ipairs(Players:GetPlayers()) do sendState(player) end
end

local function sale(lot, product, expectedPrice, expectedOwner, person)
    if not lot.ownerId or lot.ownerId ~= expectedOwner then return false end
    local account = accounts[lot.ownerId]
    if not account or not product or account.eliminated then return false end
    local price = lot.prices[product.id]
    if price ~= expectedPrice or lot.shelf[product.id] < 1 or person.wallet < price then return false end
    local units = lot.shelf[product.id] + lot.stock[product.id]
    local historicalCost = units > 0 and lot.costValue[product.id] / units or product.wholesale
    lot.costValue[product.id] = math.max(0, lot.costValue[product.id] - historicalCost)
    lot.shelf[product.id] -= 1
    account.cash += price
    account.revenue += price
    account.expenses += historicalCost
    account.sales += 1
    completedSales += 1
    lot.reputation = math.min(100, lot.reputation + 0.15)
    Population.FinishPurchase(population, person, price)
    refreshShelf(lot)
    return true
end

local CATEGORY = { queijo = "queijo", roupa = "roupa", pao = "pão", arroz = "arroz" }
local function generateCustomer()
    if activeCustomers >= Config.MaxVisibleCustomers then return end
    local open = {}
    for _, lot in ipairs(lots) do
        if lot.ownerId then table.insert(open, lot) end
    end
    if #open == 0 then return end
    local person, need = Population.StartPurchase(population, Catalog, Economy, rng)
    if not person then return end
    local startedRound = round
    local arrivalX = rng:NextNumber(-88, 88)
    local offer = Economy.PickOffer(open, need, Catalog, Config.Mode, rng, arrivalX)
    if not offer then offer = { store = open[rng:NextInteger(1, #open)], product = nil, price = 0 } end
    local target = offer.store
    local owner = target.ownerId
    local sidewalk = target.side * 17
    local npc = npcModel((CATEGORY[need.category] or need.category) .. " | " .. person.profession, arrivalX, sidewalk, false)
    activeCustomers += 1
    customerVisits += 1
    task.spawn(function()
        local bought = false
        local ok, err = pcall(function()
            moveNpc(npc, target.x, sidewalk, math.max(0.35, math.abs(target.x - arrivalX) / 16))
            moveNpc(npc, target.x, target.z - target.side * 8, 1.2)
            task.wait(0.35)
            if round == startedRound and offer.product then
                bought = sale(target, offer.product, offer.price, owner, person)
            end
            if not bought and round == startedRound and target.ownerId == owner then
                target.reputation = math.max(10, target.reputation - 0.12)
            end
            moveNpc(npc, target.x, sidewalk, 1.1)
        end)
        if not ok then warn("Vitrine City NPC: " .. tostring(err)) end
        if not bought then Population.FinishPurchase(population, person, 0) end
        npc:Destroy()
        activeCustomers -= 1
    end)
end

local function settleBids(product)
    table.sort(bids, function(a, b)
        if a.premium ~= b.premium then return a.premium > b.premium end
        return a.sequence < b.sequence
    end)
    local index = 1
    while index <= #bids do
        local bid = bids[index]
        if bid.productId == product.id then
            local account, lot = accounts[bid.userId], getLot(bid.userId)
            if not account or not lot then
                if account then
                    account.cash += bid.escrow
                    account.reserved -= bid.escrow
                end
                table.remove(bids, index)
            else
                local qty = math.min(bid.qty, supplier[product.id])
                if qty > 0 then
                    local cost = qty * bid.unitPrice
                    lot.stock[product.id] += qty
                    lot.costValue[product.id] += cost
                    account.reserved -= cost
                    bid.escrow -= cost
                    bid.qty -= qty
                    supplier[product.id] -= qty
                    message(Players:GetPlayerByUserId(bid.userId), "Entrega contratada: " .. qty .. "x " .. product.name)
                end
                if bid.qty == 0 then
                    account.cash += bid.escrow
                    account.reserved -= bid.escrow
                    table.remove(bids, index)
                else
                    index += 1
                end
            end
        else
            index += 1
        end
    end
end

local function replenishSupplier()
    for _, p in ipairs(Catalog.List) do
        -- Limitar estoque encalhado para não gerar números sem fim em servidores longos.
        supplier[p.id] = math.min(p.initialSupply * 3, supplier[p.id] + p.shipment)
        settleBids(p)
    end
end

local function payBills()
    for _, lot in ipairs(lots) do
        if lot.ownerId then
            local account = accounts[lot.ownerId]
            if account then
                local wages = lot.employeeId and Config.EmployeeWage or 0
                local bill = Config.DailyRent + wages
                if account.cash >= bill then
                    account.cash -= bill
                    account.expenses += bill
                    if wages > 0 then Population.PayWorker(population, lot.employeeId, wages) end
                    lot.missedBills = 0
                else
                    lot.missedBills += 1
                    message(Players:GetPlayerByUserId(lot.ownerId), "Atenção: faltou dinheiro para aluguel e salários!")
                    if lot.missedBills >= 2 then
                        local userId = lot.ownerId
                        refundBids(userId)
                        for _, cost in pairs(lot.costValue) do account.expenses += cost end
                        resetLot(lot)
                        if Config.Mode == "price_war" then
                            account.eliminated = true
                            message(Players:GetPlayerByUserId(userId), "Sua empresa faliu: eliminado da Guerra de Preços!")
                        else
                            if account.cash < Config.LeaseCost then
                                local help = Config.LeaseCost + 100 - account.cash
                                account.cash += help
                                account.penalties += help + 300
                            end
                            message(Players:GetPlayerByUserId(userId), "Empresa fechada. Você pode recomeçar em outra loja.")
                        end
                    end
                end
            end
        end
    end
    Population.StartDay(population)
end

local function endRound(reason)
    local ranking = {}
    for userId, account in pairs(accounts) do
        local player = Players:GetPlayerByUserId(userId)
        if player and account.everRented then
            table.insert(ranking, { player = player, value = Economy.NetWorth(account, getLot(userId)), eliminated = account.eliminated })
        end
    end
    table.sort(ranking, function(a, b)
        if Config.Mode == "price_war" and a.eliminated ~= b.eliminated then return not a.eliminated end
        return a.value > b.value
    end)
    local winner = ranking[1]
    if Config.Mode == "price_war" and winner and winner.eliminated then winner = nil end
    for _, player in ipairs(Players:GetPlayers()) do
        message(player, winner and ("Rodada " .. round .. ": " .. winner.player.DisplayName .. " venceu! " .. reason) or ("Rodada encerrada. " .. reason))
    end
    for _, lot in ipairs(lots) do resetLot(lot) end
    table.clear(bids)
    for _, account in pairs(accounts) do
        account.cash, account.reserved, account.penalties = Config.StartingCash, 0, 0
        account.revenue, account.expenses, account.sales = 0, 0, 0
        account.eliminated, account.everRented = false, false
    end
    for _, p in ipairs(Catalog.List) do supplier[p.id] = p.initialSupply end
    population = Population.Create(Config.VirtualResidents, rng)
    customerVisits, completedSales = 0, 0
    round += 1
    remaining, elapsedRound = Config.RoundSeconds, 0
end

local nextBidSequence = 0
local function handleAction(player, action, payload)
    local account = accounts[player.UserId]
    if not account then return end
    if action == "GetState" then sendState(player); return end
    if type(payload) ~= "table" then return end
    local lot = getLot(player.UserId)
    if not lot then message(player, "Alugue uma loja primeiro, na placa amarela da entrada."); return end
    local product = type(payload.id) == "string" and Catalog.ById[payload.id] or nil
    if action == "Hire" then
        if lot.employeeId then return end
        if account.cash < Config.EmployeeHireCost then message(player, "Saldo insuficiente para contratar."); return end
        local id = Population.Hire(population, lot.id)
        if not id then message(player, "Nenhum trabalhador disponível."); return end
        account.cash -= Config.EmployeeHireCost
        account.expenses += Config.EmployeeHireCost
        lot.employeeId = id
        lot.employeeModel = npcModel("Repositor", lot.x - 10, lot.z, true)
        message(player, "Repositor contratado: ele recebe salário e consome na cidade.")
    elseif action == "Buy" and product then
        local qty = 5
        if competitive and supplier[product.id] < qty then message(player, "Fornecedor sem estoque. Espere a remessa!"); return end
        local cost = qty * product.wholesale
        if account.cash < cost then message(player, "Saldo insuficiente."); return end
        account.cash -= cost
        if competitive then supplier[product.id] -= qty end
        lot.stock[product.id] += qty
        lot.costValue[product.id] += cost
    elseif action == "Stock" and product then
        if restock(lot, product.id) == 0 then message(player, "Depósito vazio ou prateleira cheia.") end
        refreshShelf(lot)
    elseif action == "Price" and product and (payload.delta == 1 or payload.delta == -1) then
        local nextPrice = lot.prices[product.id] + payload.delta
        if nextPrice >= 1 and nextPrice <= product.retail * 3 then
            lot.prices[product.id] = nextPrice
            refreshShelf(lot)
        end
    elseif action == "Bid" and product and competitive then
        local premium = payload.premium
        if premium ~= 0 and premium ~= 20 and premium ~= 40 then return end
        local active = 0
        for _, bid in ipairs(bids) do
            if bid.userId == player.UserId then
                active += 1
                if bid.productId == product.id then return end
            end
        end
        if active >= 3 then message(player, "Limite de três contratos."); return end
        local unitPrice = math.ceil(product.wholesale * (1 + premium / 100))
        local escrow = unitPrice * 10
        if account.cash < escrow then message(player, "Saldo insuficiente para o contrato."); return end
        account.cash -= escrow
        account.reserved += escrow
        nextBidSequence += 1
        table.insert(bids, {
            userId = player.UserId, productId = product.id,
            qty = 10, unitPrice = unitPrice, escrow = escrow,
            premium = premium, sequence = nextBidSequence,
        })
        message(player, "Contrato aceito. Reserva em caixa até a próxima entrega.")
    elseif action == "CancelBid" and product and competitive then
        for i = #bids, 1, -1 do
            local bid = bids[i]
            if bid.userId == player.UserId and bid.productId == product.id then
                account.cash += bid.escrow
                account.reserved -= bid.escrow
                table.remove(bids, i)
                break
            end
        end
    end
    sendState(player)
end

makeMap()
for _, lot in ipairs(lots) do
    lot.prompt.Triggered:Connect(function(player)
        rent(player, lot)
        pushState()
    end)
end

local ACCEPTED = { GetState = true, Hire = true, Buy = true, Stock = true, Price = true, Bid = true, CancelBid = true }
actionEvent.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or not ACCEPTED[action] then return end
    local now = os.clock()
    if now - (lastAction[player.UserId] or -999) < 0.12 then return end
    lastAction[player.UserId] = now
    handleAction(player, action, payload)
end)

local function join(player)
    accounts[player.UserId] = {
        cash = Config.StartingCash, reserved = 0, penalties = 0,
        revenue = 0, expenses = 0, sales = 0,
        eliminated = false, everRented = false,
    }
    task.delay(1.5, function() if player.Parent == Players then sendState(player) end end)
end
Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(function(player)
    refundBids(player.UserId)
    local lot = getLot(player.UserId)
    if lot then resetLot(lot) end
    accounts[player.UserId] = nil
    lastAction[player.UserId] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do join(player) end

task.spawn(function()
    while true do
        task.wait(Config.CustomerInterval)
        generateCustomer()
    end
end)

task.spawn(function()
    while true do
        task.wait(11)
        for _, lot in ipairs(lots) do
            if lot.ownerId and lot.employeeId then
                local changed = false
                for _, p in ipairs(Catalog.List) do
                    if restock(lot, p.id) > 0 then changed = true end
                end
                if changed then refreshShelf(lot) end
            end
        end
    end
end)

task.spawn(function()
    local bills, deliveries, broadcast = 0, 0, 0
    while true do
        local dt = task.wait(1)
        bills += dt
        deliveries += dt
        broadcast += dt
        if competitive then
            remaining -= dt
            elapsedRound += dt
            local lastStanding = false
            if Config.Mode == "price_war" and elapsedRound >= Config.WarGraceSeconds then
                local active, participated = 0, 0
                for _, account in pairs(accounts) do
                    if account.everRented then participated += 1 end
                end
                -- Contar apenas proprietários ainda solventes.
                for _, lot in ipairs(lots) do
                    if lot.ownerId and accounts[lot.ownerId] and not accounts[lot.ownerId].eliminated then
                        active += 1
                    end
                end
                lastStanding = participated >= 2 and active <= 1
            end
            if remaining <= 0 or lastStanding then
                endRound(lastStanding and "Último comércio sobrevivente." or "Tempo esgotado.")
                bills, deliveries = 0, 0
            end
        end
        if bills >= Config.EconomicDaySeconds then
            bills = 0
            payBills()
        end
        if competitive and deliveries >= Config.ShipmentSeconds then
            deliveries = 0
            replenishSupplier()
        end
        if broadcast >= 5 then
            broadcast = 0
            pushState()
        end
    end
end)

print("Vitrine City iniciado em modo:", Config.Mode, "| habitantes virtuais:", Config.VirtualResidents)
