--!strict
-- Configuração por Place. No lançamento: Places separados para modos distintos.
return {
    Mode = "normal", -- "normal" | "ranked" | "price_war"
    SaveEnabled = true, -- persistência real apenas na Rua Livre publicada
    StudioPersistence = false, -- NÃO ativar com dados de produção em Studio
    AutosaveSeconds = 45,
    Lots = 8,
    StartingCash = 900,
    LeaseCost = 100,
    DailyRent = 60,
    EmployeeHireCost = 130,
    EmployeeWage = 25,
    WorkerCycleSeconds = 11, -- cada repositor atende uma gôndola por viagem
    EconomicDaySeconds = 90,
    ShipmentSeconds = 65,
    MarketEventEveryDays = 2, -- notícia nova a cada dois ciclos econômicos
    CustomerInterval = 3.5,
    MaxVisibleCustomers = 12,
    VirtualResidents = 240,
    ShelfCapacity = 18,
    RoundSeconds = 900,
    WarGraceSeconds = 65,
}
