--!nonstrict
-- Planejamento geométrico de visitas: não depende de NPCs, Workspace nem PathfindingService.
-- Todos os pontos ficam no corredor livre das lojas low-poly construídas por StoreVisuals.
local Route = {}

local function step(x, z, hold)
    return { x = x, z = z, hold = hold or 0 }
end

local function front(lot)
    return lot.z - lot.side * 15
end

function Route.ShelfPosition(lot, productIndex)
    local index = math.clamp(math.floor(tonumber(productIndex) or 1), 1, 6)
    local onLeft = index <= 3
    local slot = (index - 1) % 3
    return lot.x + (onLeft and -6.8 or 6.8),
        front(lot) + lot.side * (11.4 + slot * 7.0)
end

function Route.Approach(lot, arrivalX, productIndex)
    local facade = front(lot)
    local shelfX, shelfZ = Route.ShelfPosition(lot, productIndex)
    local walkZ = lot.side * 17
    -- Aproximação reta pela calçada, porta central e corredor da loja.
    return {
        step(lot.x, walkZ),
        step(lot.x, facade - lot.side * 2.8),
        step(lot.x, facade + lot.side * 5.0),
        step(lot.x, shelfZ),
        step(shelfX, shelfZ, 0.75),
    }
end

function Route.Checkout(lot, productIndex)
    local facade = front(lot)
    local _, shelfZ = Route.ShelfPosition(lot, productIndex)
    -- Passa pelo eixo central e se aproxima do balcão lateral sem atravessá-lo.
    return {
        step(lot.x, shelfZ),
        step(lot.x, facade + lot.side * 6.0),
        step(lot.x + 6.8, facade + lot.side * 6.0, 0.5),
    }
end

function Route.Exit(lot, arrivalX)
    local facade = front(lot)
    local streetZ = lot.side * 17
    local direction = arrivalX <= lot.x and -1 or 1
    return {
        step(lot.x, facade + lot.side * 5.0),
        step(lot.x, facade - lot.side * 2.8),
        step(lot.x, streetZ),
        step(lot.x + direction * 13, streetZ),
    }
end

-- Ponto de descanso do repositor, ao lado do balcão (sem bloquear caixa/porta).
function Route.StaffHome(lot)
    return lot.x + 6.8, front(lot) + lot.side * 6.0
end

function Route.StaffToShelf(lot, productIndex)
    local shelfX, shelfZ = Route.ShelfPosition(lot, productIndex)
    local _, checkoutZ = Route.StaffHome(lot)
    return {
        step(lot.x, checkoutZ),
        step(lot.x, shelfZ),
        step(shelfX, shelfZ, 0.55),
    }
end

function Route.StaffReturn(lot, productIndex)
    return Route.Checkout(lot, productIndex)
end

function Route.Duration(fromX, fromZ, toX, toZ)
    local dist = math.sqrt((fromX - toX)^2 + (fromZ - toZ)^2)
    return math.clamp(dist / 12, 0.28, 5.5)
end

return Route
