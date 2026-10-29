--!nonstrict
-- Vitrine City | kit visual modular: construções low-poly com fachada comercial.
-- Apenas elementos estáticos. Nenhum loop, luz dinâmica, asset externo ou malha pesada.
local StoreVisuals = {}

local C = {
    asphalt = Color3.fromRGB(46, 53, 63),
    sidewalk = Color3.fromRGB(199, 202, 199),
    pavement = Color3.fromRGB(217, 215, 207),
    stone = Color3.fromRGB(239, 235, 223),
    dark = Color3.fromRGB(31, 41, 54),
    steel = Color3.fromRGB(74, 85, 94),
    glass = Color3.fromRGB(172, 213, 224),
    white = Color3.fromRGB(248, 249, 242),
    green = Color3.fromRGB(75, 155, 111),
}
StoreVisuals.Themes = {
    { name = "Vitrine", accent = Color3.fromRGB(27, 146, 135), wall = Color3.fromRGB(242, 235, 218) },
    { name = "Mercadinho", accent = Color3.fromRGB(230, 119, 62), wall = Color3.fromRGB(244, 238, 222) },
    { name = "Galeria", accent = Color3.fromRGB(63, 109, 185), wall = Color3.fromRGB(233, 235, 231) },
    { name = "Empório", accent = Color3.fromRGB(176, 89, 116), wall = Color3.fromRGB(246, 236, 230) },
    { name = "Casa", accent = Color3.fromRGB(120, 122, 183), wall = Color3.fromRGB(234, 237, 232) },
    { name = "Esquina", accent = Color3.fromRGB(200, 143, 61), wall = Color3.fromRGB(242, 236, 218) },
    { name = "Comércio", accent = Color3.fromRGB(86, 145, 85), wall = Color3.fromRGB(237, 239, 224) },
    { name = "Bazar", accent = Color3.fromRGB(174, 100, 74), wall = Color3.fromRGB(242, 231, 219) },
}

local function block(parent, makePart, name, size, at, color, material, collide, alpha)
    local p = makePart(parent, name, size, at, color)
    if material then p.Material = material end
    if collide == false then
        p.CanCollide = false
        p.CanTouch = false
        p.CastShadow = false
    end
    if alpha then p.Transparency = alpha end
    return p
end

-- Sinalizações legíveis, sem dezenas de BillboardGuis flutuando pela loja.
local function surfaceText(anchor, face, text, bg, fontScale)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "Comunicação visual"
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 28
    gui.LightInfluence = 0
    gui.AlwaysOnTop = false
    gui.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Name = "Texto"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = bg and 0 or 1
    if bg then label.BackgroundColor3 = bg end
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = C.white
    label.TextScaled = true
    label.TextWrapped = true
    label.Text = text
    label.Parent = gui

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0.04, 0)
    padding.PaddingRight = UDim.new(0.04, 0)
    padding.PaddingTop = UDim.new(0.11, 0)
    padding.PaddingBottom = UDim.new(0.11, 0)
    padding.Parent = label
    return label
end

function StoreVisuals.BuildStreet(map, makePart)
    -- Loja e calçada no mesmo nível: a rua tem faixa central e sarjetas baixas.
    block(map, makePart, "Terreno urbano", Vector3.new(235, 0.65, 155),
        Vector3.new(0, -0.48, 0), Color3.fromRGB(115, 165, 126), Enum.Material.Grass)
    block(map, makePart, "Asfalto", Vector3.new(223, 0.2, 26),
        Vector3.new(0, 0.01, 0), C.asphalt, Enum.Material.Asphalt)
    for x = -4, 4 do
        block(map, makePart, "Faixa central", Vector3.new(10, 0.04, 0.35),
            Vector3.new(x * 24, 0.14, 0), Color3.fromRGB(239, 218, 133), Enum.Material.SmoothPlastic, false)
    end
    for _, sign in ipairs({ -1, 1 }) do
        block(map, makePart, "Calçada principal", Vector3.new(223, 0.37, 17),
            Vector3.new(0, 0.0, sign * 21), C.sidewalk, Enum.Material.Concrete)
        block(map, makePart, "Linha da guia", Vector3.new(223, 0.4, 0.75),
            Vector3.new(0, 0.15, sign * 13.2), Color3.fromRGB(168, 175, 179), Enum.Material.Concrete)
        -- Árvores plantadas nas divisões entre pontos, não na entrada dos imóveis.
        for _, x in ipairs({ -88, -44, 0, 44, 88 }) do
            block(map, makePart, "Canteiro", Vector3.new(6, 0.24, 6),
                Vector3.new(x, 0.3, sign * 22), Color3.fromRGB(107, 119, 101), Enum.Material.Concrete)
            local grass = block(map, makePart, "Terra de canteiro",
                Vector3.new(4.8, 0.16, 4.8), Vector3.new(x, 0.48, sign * 22),
                Color3.fromRGB(95, 121, 78), Enum.Material.Grass, false)
            local trunk = block(map, makePart, "Árvore urbana",
                Vector3.new(1.25, 6.3, 1.25), Vector3.new(x, 3.65, sign * 22),
                Color3.fromRGB(116, 89, 63), Enum.Material.Wood, false)
            trunk.Shape = Enum.PartType.Cylinder
            for j = 1, 2 do
                local canopy = block(map, makePart, "Folhagem",
                    Vector3.new(j == 1 and 6.4 or 5, j == 1 and 5.1 or 4, j == 1 and 6.4 or 5),
                    Vector3.new(x + (j == 1 and -1 or 1), 8.3 + j, sign * 22),
                    j == 1 and Color3.fromRGB(69, 144, 94) or Color3.fromRGB(87, 171, 105),
                    Enum.Material.Grass, false)
                canopy.Shape = Enum.PartType.Ball
            end
        end
    end
    -- Travessia próxima à praça de nascimento.
    for i = -3, 3 do
        block(map, makePart, "Faixa de pedestre", Vector3.new(3.7, 0.035, 2.3),
            Vector3.new(-96, 0.14, i * 3.6), C.white, Enum.Material.SmoothPlastic, false)
    end
    for _, x in ipairs({ -89, 0, 89 }) do
        for _, side in ipairs({ -1, 1 }) do
            block(map, makePart, "Poste", Vector3.new(0.65, 9.8, 0.65),
                Vector3.new(x, 5, side * 14.5), C.steel, Enum.Material.Metal, false)
            block(map, makePart, "Luminária", Vector3.new(2.2, 0.55, 1.3),
                Vector3.new(x, 10.2, side * 14.5), Color3.fromRGB(244, 227, 174),
                Enum.Material.Neon, false)
        end
    end
    -- Pequena praça de entrada: orienta o jogador sem cortar o caminho.
    local landmark = block(map, makePart, "Portal da rua",
        Vector3.new(10, 4, 0.75), Vector3.new(-101, 5.0, 24),
        Color3.fromRGB(34, 73, 83), Enum.Material.Metal, false)
    surfaceText(landmark, Enum.NormalId.Front, "VITRINE CITY", C.dark)
    surfaceText(landmark, Enum.NormalId.Back, "VITRINE CITY", C.dark)
end

function StoreVisuals.BuildStore(model, id, x, z, side, makePart)
    local theme = StoreVisuals.Themes[(id - 1) % #StoreVisuals.Themes + 1]
    local front = z - side * 15
    local back = z + side * 15
    local frame = Color3.fromRGB(44, 58, 69)
    local towardInside = side
    local face = side == 1 and Enum.NormalId.Front or Enum.NormalId.Back

    -- Base, paredes completas e cobertura: conjunto de uma loja térrea real.
    block(model, makePart, "Piso de porcelanato", Vector3.new(31, 0.48, 31),
        Vector3.new(x, 0, z), Color3.fromRGB(236, 229, 214), Enum.Material.Concrete)
    block(model, makePart, "Rodapé fundo", Vector3.new(30.6, 0.65, 0.18),
        Vector3.new(x, 0.57, back - side * 0.62), Color3.fromRGB(177, 175, 165), Enum.Material.Concrete, false)
    block(model, makePart, "Parede de fundo", Vector3.new(31, 10.4, 0.9),
        Vector3.new(x, 5.2, back), theme.wall, Enum.Material.Concrete)
    for _, direction in ipairs({ -1, 1 }) do
        block(model, makePart, "Parede lateral", Vector3.new(0.9, 10.4, 31),
            Vector3.new(x + direction * 15, 5.2, z), theme.wall, Enum.Material.Concrete)
        block(model, makePart, "Coluna de fachada", Vector3.new(1.2, 10.1, 1.3),
            Vector3.new(x + direction * 14.5, 5.05, front), frame, Enum.Material.Metal)
    end
    block(model, makePart, "Laje e cobertura", Vector3.new(31.8, 0.68, 31.7),
        Vector3.new(x, 10.8, z), Color3.fromRGB(50, 60, 70), Enum.Material.Concrete)
    block(model, makePart, "Platibanda", Vector3.new(32, 1.7, 1.2),
        Vector3.new(x, 11.8, front - side * 0.45), theme.accent, Enum.Material.SmoothPlastic)
    -- As lojas têm duas vitrines: vidro com caixilhos, porta central atravessável.
    for _, direction in ipairs({ -1, 1 }) do
        local wx = x + direction * 9
        block(model, makePart, "Painel superior da vitrine", Vector3.new(10.5, 1.3, 0.75),
            Vector3.new(wx, 8.3, front), theme.wall, Enum.Material.Concrete)
        block(model, makePart, "Base da vitrine", Vector3.new(10.5, 1.2, 0.75),
            Vector3.new(wx, 0.65, front), frame, Enum.Material.Metal)
        block(model, makePart, "Vidro da vitrine", Vector3.new(10.2, 6, 0.18),
            Vector3.new(wx, 4.4, front), C.glass, Enum.Material.Glass, true, 0.45)
        block(model, makePart, "Travessa da vitrine", Vector3.new(10.5, 0.16, 0.35),
            Vector3.new(wx, 4.35, front - side * 0.06), frame, Enum.Material.Metal, false)
        block(model, makePart, "Divisor externo", Vector3.new(0.22, 7.4, 0.4),
            Vector3.new(x + direction * 14.1, 4.5, front - side * 0.08), frame, Enum.Material.Metal, false)
        block(model, makePart, "Divisor interno", Vector3.new(0.24, 8.4, 0.4),
            Vector3.new(x + direction * 3.55, 4.5, front - side * 0.08), frame, Enum.Material.Metal, false)

        -- Cenografia da vitrine (AMOSTRA, não estoque comercial): exposição já visível
        -- antes do primeiro aluguel. Fica atrás do vidro, sem obstruir a porta central.
        local displayZ = front + side * 2.8
        block(model, makePart, "Pedestal de vitrine", Vector3.new(7.4, 0.9, 2.5),
            Vector3.new(wx, 0.7, displayZ), Color3.fromRGB(222, 210, 188),
            Enum.Material.WoodPlanks, false)
        if direction == -1 then
            block(model, makePart, "Manequim torso", Vector3.new(1.6, 2.7, 0.9),
                Vector3.new(wx, 3.1, displayZ), theme.accent,
                Enum.Material.SmoothPlastic, false)
            local head = block(model, makePart, "Manequim cabeça", Vector3.new(1.25, 1.25, 1.25),
                Vector3.new(wx, 5.2, displayZ), Color3.fromRGB(214, 194, 171),
                Enum.Material.SmoothPlastic, false)
            head.Shape = Enum.PartType.Ball
            block(model, makePart, "Manequim suporte", Vector3.new(0.27, 0.85, 0.27),
                Vector3.new(wx, 1.5, displayZ), C.steel, Enum.Material.Metal, false)
        else
            for n = -1, 1 do
                block(model, makePart, "Embalagem cenográfica de vitrine",
                    Vector3.new(1.6, 1.8 + (n == 0 and 0.55 or 0), 1.2),
                    Vector3.new(wx + n * 2, 2.15 + (n == 0 and 0.3 or 0), displayZ),
                    n == 0 and theme.accent or C.white, Enum.Material.SmoothPlastic, false)
            end
        end
    end
    -- Porta de vidro decorativa e SEM colisão para preservar a entrada NPC/jogador.
    block(model, makePart, "Vergas da entrada", Vector3.new(7, 1.3, 0.75),
        Vector3.new(x, 8.3, front), frame, Enum.Material.Metal)
    for _, direction in ipairs({ -1, 1 }) do
        block(model, makePart, "Porta de vidro", Vector3.new(3.2, 7, 0.14),
            Vector3.new(x + direction * 1.65, 3.5, front), C.glass, Enum.Material.Glass, false, 0.77)
        block(model, makePart, "Puxador de porta", Vector3.new(0.18, 1.1, 0.28),
            Vector3.new(x + direction * 0.28, 3.35, front - side * 0.2),
            C.steel, Enum.Material.Metal, false)
    end
    -- Fachada reconhecível vista da rua: placa comercial, toldo e status.
    local fascia = block(model, makePart, "Faixa do letreiro", Vector3.new(26.8, 2.0, 0.65),
        Vector3.new(x, 10.85, front - side * 1.1), C.dark, Enum.Material.Metal, false)
    local title = surfaceText(fascia, face,
        string.format("VITRINE %02d  •  DISPONÍVEL", id), C.dark)
    block(model, makePart, "Toldo da fachada", Vector3.new(32.3, 0.38, 3.8),
        Vector3.new(x, 9.1, front - side * 2.1), theme.accent, Enum.Material.SmoothPlastic)
    for n = -3, 3 do
        block(model, makePart, "Friso do toldo", Vector3.new(3.2, 0.16, 0.38),
            Vector3.new(x + n * 4.55, 8.84, front - side * 3.85),
            C.white, Enum.Material.SmoothPlastic, false)
    end
    local lamp = block(model, makePart, "Indicador de loja disponível",
        Vector3.new(1.0, 1.0, 0.5), Vector3.new(x - 13.8, 10.85, front - side * 1.4),
        C.green, Enum.Material.Neon, false)

    -- Loja tem frente pavimentada contínua até a calçada.
    block(model, makePart, "Entrada pavimentada", Vector3.new(25, 0.28, 8.5),
        Vector3.new(x, 0.09, front - side * 4.4), C.pavement, Enum.Material.Concrete)
    block(model, makePart, "Tapete de entrada", Vector3.new(5.8, 0.06, 2.4),
        Vector3.new(x, 0.29, front + side * 1.1), Color3.fromRGB(89, 106, 101),
        Enum.Material.Fabric, false)
    local door = block(model, makePart, "Alugue aqui", Vector3.new(5.5, 0.25, 4.3),
        Vector3.new(x, 0.38, front - side * 4.0), Color3.fromRGB(252, 208, 86),
        Enum.Material.SmoothPlastic, false, 0.05)

    -- Balcão e equipamento de caixa junto à vitrine, sem bloquear o corredor central.
    block(model, makePart, "Balcão de atendimento", Vector3.new(4.9, 2.15, 2.2),
        Vector3.new(x + 10.1, 1.35, front + side * 4.7),
        Color3.fromRGB(155, 110, 72), Enum.Material.WoodPlanks)
    block(model, makePart, "Tampo do balcão", Vector3.new(5.1, 0.22, 2.45),
        Vector3.new(x + 10.1, 2.53, front + side * 4.7), C.stone, Enum.Material.Marble)
    local cashRegister = block(model, makePart, "Caixa registradora", Vector3.new(1.5, 0.8, 1.25),
        Vector3.new(x + 10.2, 3.04, front + side * 4.7), frame, Enum.Material.Metal, false)
    local screen = block(model, makePart, "Monitor do caixa", Vector3.new(1.25, 0.45, 0.12),
        Vector3.new(x + 10.2, 3.2, front + side * 4.03), Color3.fromRGB(101, 197, 178),
        Enum.Material.Neon, false)
    screen.CanCollide = false

    -- Cartaz de promoções e painel de parede: ambiente identificável mesmo sem estoque.
    local poster = block(model, makePart, "Cartaz de ofertas", Vector3.new(8, 4.2, 0.14),
        Vector3.new(x, 6.5, back - side * 0.58), theme.accent,
        Enum.Material.SmoothPlastic, false)
    surfaceText(poster, side == 1 and Enum.NormalId.Front or Enum.NormalId.Back,
        "OFERTAS\nDA SEMANA", theme.accent)
    return {
        door = door,
        signLabel = title,
        statusLamp = lamp,
        cashRegister = cashRegister,
        theme = theme,
        front = front,
    }
end

function StoreVisuals.BuildShelf(model, lot, product, idx, makePart)
    -- Racks nas paredes laterais: centro inteiramente livre para jogadores e NPCs.
    local onLeft = idx <= 3
    local x = lot.x + (onLeft and -10.5 or 10.5)
    local slot = ((idx - 1) % 3)
    local front = lot.z - lot.side * 15
    local z = front + lot.side * (11.4 + slot * 7.0)
    local steel = Color3.fromRGB(95, 106, 112)
    local goods = {}

    -- Estrutura: dois pés e três prateleiras; embalagens em vez de cubos gigantes.
    for _, dz in ipairs({ -2.4, 2.4 }) do
        block(model, makePart, "Coluna da gôndola", Vector3.new(0.25, 4.4, 0.28),
            Vector3.new(x, 2.3, z + dz), steel, Enum.Material.Metal, false)
    end
    for _, height in ipairs({ 0.85, 2.5, 4.12 }) do
        block(model, makePart, "Nível da gôndola " .. product.name,
            Vector3.new(2.9, 0.22, 5.25), Vector3.new(x, height, z),
            Color3.fromRGB(195, 198, 192), Enum.Material.Metal, false)
    end
    for n = 1, 6 do
        local row = math.floor((n - 1) / 3)
        local zOffset = ((n - 1) % 3 - 1) * 1.65
        local itemSize = Vector3.new(1.1, 1.15, 1.15)
        local itemY = row == 0 and 1.56 or 3.22
        if product.category == "roupa" then
            itemSize = Vector3.new(1.3, 1.25, 0.65)
        elseif product.category == "pao" then
            itemSize = Vector3.new(1.0, 0.85, 1.05)
        end
        local item = block(model, makePart, product.name .. " embalagem " .. n,
            itemSize, Vector3.new(x, itemY, z + zOffset),
            product.color, Enum.Material.SmoothPlastic, false)
        if product.category == "pao" then
            item.Shape = Enum.PartType.Ball
        elseif product.category == "queijo" then
            item.Shape = Enum.PartType.Cylinder
        elseif product.category == "roupa" or product.category == "arroz" then
            item.Material = Enum.Material.Fabric
        end
        item.CastShadow = false
        item.Transparency = 1
        goods[n] = item
    end
    local towardAisle = onLeft and 1 or -1
    local plaque = block(model, makePart, "Etiqueta " .. product.name,
        Vector3.new(0.14, 1.0, 5.0), Vector3.new(x + towardAisle * 1.55, 4.45, z),
        Color3.fromRGB(42, 55, 69), Enum.Material.Metal, false)
    local label = surfaceText(plaque,
        onLeft and Enum.NormalId.Right or Enum.NormalId.Left,
        product.name .. "  •  $--", Color3.fromRGB(42, 55, 69))
    return { goods = goods, text = label }
end

return StoreVisuals
