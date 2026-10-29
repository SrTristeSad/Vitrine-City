--!strict
-- IDs 0 significam "não configurado". Preencher com os IDs dos Places
-- CRIADOS DENTRO DA MESMA EXPERIÊNCIA no Creator Dashboard.
return {
    lobby = { label = "Praça central", placeId = 0, minPlayers = 1, maxPlayers = 1 },
    normal = { label = "Rua Livre", placeId = 0, minPlayers = 1, maxPlayers = 1 },
    ranked = { label = "Guerra Comercial", placeId = 0, minPlayers = 2, maxPlayers = 8, countdown = 12 },
    price_war = { label = "Guerra de Preços", placeId = 0, minPlayers = 2, maxPlayers = 8, countdown = 12 },
}
