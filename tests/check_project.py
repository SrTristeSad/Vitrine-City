#!/usr/bin/env python3
"""Static project checks. Luau compilation is handled separately in CI; Studio playtests remain mandatory."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
project = json.loads((root / "default.project.json").read_text(encoding="utf-8"))
tree = project["tree"]
assert tree["$className"] == "DataModel"
assert tree["ReplicatedStorage"]["Shared"]["$path"] == "src/ReplicatedStorage/Shared"
assert tree["ServerScriptService"]["VitrineServer"]["$path"].endswith(".server.luau")
assert tree["ServerScriptService"]["ProfileStore"]["$path"].endswith("ProfileStore.luau")
assert tree["ServerScriptService"]["StoreVisuals"]["$path"].endswith("StoreVisuals.luau")
assert tree["StarterPlayer"]["StarterPlayerScripts"]["VitrineClient"]["$path"].endswith(".client.luau")
for path in ("lobby.project.json", "ranked.project.json", "price_war.project.json"):
    extra = json.loads((root / path).read_text(encoding="utf-8"))
    assert extra["tree"]["$className"] == "DataModel", path
    assert "ReplicatedStorage" in extra["tree"] and "ServerScriptService" in extra["tree"], path
assert json.loads((root / "lobby.project.json").read_text(encoding="utf-8"))["tree"]["ReplicatedStorage"]["ModeRoutes"]["$path"].endswith("ModeRoutes.luau")
lobby_tree = json.loads((root / "lobby.project.json").read_text(encoding="utf-8"))["tree"]
assert lobby_tree["ServerScriptService"]["GlobalMatchmaker"]["$path"].endswith("GlobalMatchmaker.luau")
for path, suffix in (("ranked.project.json", "Ranked.luau"), ("price_war.project.json", "PriceWar.luau")):
    shared = json.loads((root / path).read_text(encoding="utf-8"))["tree"]["ReplicatedStorage"]["Shared"]
    assert shared["Config"]["$path"].endswith(suffix)
    assert shared["BaseConfig"]["$path"].endswith("Shared/Config.luau")


sources = [
    "src/ReplicatedStorage/Shared/Config.luau",
    "src/ReplicatedStorage/Shared/Catalog.luau",
    "src/ReplicatedStorage/Shared/CustomerRoute.luau",
    "src/ReplicatedStorage/Shared/MarketEvents.luau",
    "src/ReplicatedStorage/Shared/ShopAnalytics.luau",
    "src/ReplicatedStorage/Shared/Economy.luau",
    "src/ReplicatedStorage/Shared/Population.luau",
    "src/ServerScriptService/VitrineServer.server.luau",
    "src/ServerScriptService/ProfileStore.luau",
    "src/ServerScriptService/StoreVisuals.luau",
    "src/ServerScriptService/LobbyServer.server.luau",
    "src/ServerScriptService/GlobalMatchmaker.luau",
    "src/StarterPlayer/StarterPlayerScripts/LobbyClient.client.luau",
    "src/ReplicatedStorage/ModeRoutes.luau",
    "src/ReplicatedStorage/Shared/Configs/Ranked.luau",
    "src/ReplicatedStorage/Shared/Configs/PriceWar.luau",
    "src/StarterPlayer/StarterPlayerScripts/VitrineClient.client.luau",
]
for source in sources:
    text = (root / source).read_text(encoding="utf-8")
    assert len(text) > 100, f"Empty or suspicious file: {source}"
    assert "\x00" not in text, f"NUL byte: {source}"

catalog = (root / sources[1]).read_text(encoding="utf-8")
ids = re.findall(r'\bid = "([^"]+)"', catalog)
assert len(ids) == 6 and len(set(ids)) == len(ids), f"Unexpected catalog: {ids}"

economy = (root / "src/ReplicatedStorage/Shared/Economy.luau").read_text(encoding="utf-8")
population = (root / "src/ReplicatedStorage/Shared/Population.luau").read_text(encoding="utf-8")
server = (root / "src/ServerScriptService/VitrineServer.server.luau").read_text(encoding="utf-8")
profiles = (root / "src/ServerScriptService/ProfileStore.luau").read_text(encoding="utf-8")
client = (root / "src/StarterPlayer/StarterPlayerScripts/VitrineClient.client.luau").read_text(encoding="utf-8")
for name in ("NewNeed", "PickOffer", "NetWorth"):
    assert f"function Economy.{name}" in economy
for name in ("Create", "StartPurchase", "FinishPurchase", "Hire", "PayWorker", "Layoff", "StartDay", "Stats"):
    assert f"function Population.{name}" in population
for module in ("Config", "Catalog", "Population", "Economy"):
    assert f'WaitForChild("{module}")' in server
for remote in ("Action", "State", "Notice"):
    assert f'event("{remote}")' in server
    assert f'WaitForChild("{remote}")' in client

# Cada modo comercial precisa incluir o mesmo kit visual. Lobby tem mapa separado.
visuals = (root / "src/ServerScriptService/StoreVisuals.luau").read_text(encoding="utf-8")
for path in ("ranked.project.json", "price_war.project.json"):
    mode_tree = json.loads((root / path).read_text(encoding="utf-8"))["tree"]
    assert mode_tree["ServerScriptService"]["StoreVisuals"]["$path"].endswith("StoreVisuals.luau")
for feature in ('"Vidro da vitrine"', '"Porta de vidro"', '"Faixa do letreiro"',
                '"Toldo da fachada"', '"Balcão de atendimento"', '"Etiqueta "',
                '"Manequim torso"', '"Pedestal de vitrine"', '"Entrada pavimentada"'):
    assert feature in visuals, f"Faltou estrutura comercial {feature}"
assert "function StoreVisuals.BuildStreet" in visuals
assert "function StoreVisuals.BuildStore" in visuals
assert "function StoreVisuals.BuildShelf" in visuals
assert 'StoreVisuals.BuildStreet(map, part)' in server
assert 'StoreVisuals.BuildStore(model, id, x, z, side, part)' in server
assert 'StoreVisuals.BuildShelf(lot.model, lot, product, idx, part)' in server
assert "lot.prompt.Enabled = owner == nil" in server
assert 'prompt.Parent = door' in server
assert 'lot.statusLamp.Color' in server
assert 'CustomerRoute = require(Shared:WaitForChild("CustomerRoute"))' in server
for feature in ("CustomerRoute.Approach", "CustomerRoute.Checkout", "CustomerRoute.Exit",
                "CustomerRoute.Duration", 'event("OpenShop")',
                "lot.managementPrompt.Triggered", "openShopEvent:FireClient"):
    assert feature in server, feature
assert 'WaitForChild("OpenShop")' in client
assert 'openShopEvent.OnClientEvent:Connect' in client
assert (root / "tests/customer_route.spec.luau").exists()
for path in ("ranked.project.json", "price_war.project.json"):
    shared = json.loads((root / path).read_text(encoding="utf-8"))["tree"]["ReplicatedStorage"]["Shared"]
    assert shared["CustomerRoute"]["$path"].endswith("CustomerRoute.luau")
assert "Config.MaxVisibleCustomers" in server
assert "person.wallet < price" in server
assert "account.cash -= cost" in server
assert "Population.FinishPurchase" in server
assert "Population.PayWorker" in server
assert "ProfileStore.Load" in server and "ProfileStore.Save" in server and "ProfileStore.Release" in server
assert "ProfileStore" in profiles and "UpdateAsync" in profiles
# Um projeto .rbxlx não publicado deve iniciar no Studio sem tentar GetDataStore.
# A aquisição precisa ocorrer apenas ao carregar/salvar perfis persistentes.
assert 'local store = DataStoreService:GetDataStore(' not in profiles, "GetDataStore antecipado impede Play em Place não publicado"
assert 'local function getStore()' in profiles
assert profiles.count('getStore():UpdateAsync(') == 2
assert 'if disabled() then return cleanProfile({}, catalog), "session" end' in profiles
assert 'if disabled() then return true end' in profiles
assert "RunService:IsStudio()" in profiles and "Config.StudioPersistence" in profiles
assert "Config.AutosaveSeconds" in server
analytics = (root / "src/ReplicatedStorage/Shared/ShopAnalytics.luau").read_text(encoding="utf-8")
for name in ("New", "Restore", "BeginVisit", "RecordSale", "Reason", "RecordLost", "View"):
    assert f"function ShopAnalytics.{name}" in analytics
assert 'ShopAnalytics.BeginVisit' in server and 'ShopAnalytics.RecordLost' in server
assert 'ShopAnalytics.RecordSale' in server and 'ShopAnalytics.View' in server
assert 'lot.leaseVersion ~= expectedLease' in server
assert 'target.leaseVersion == lease' in server
assert 'account.ledger.cogs' in server and 'account.ledger.wages' in server
assert 'account.ledger.lease' in server and 'account.ledger.writeoff' in server
assert 'ShopAnalytics.Restore' in profiles and 'ledger = cleanLedger' in profiles
assert 'showReport' in client and 'RELATÓRIO DA LOJA' in client
assert 'Visitas concluídas:' in client and 'Conversão:' in client
assert (root / "tests/analytics.spec.luau").exists()
market_events = (root / "src/ReplicatedStorage/Shared/MarketEvents.luau").read_text(encoding="utf-8")
assert "function MarketEvents.Next" in market_events
assert "function MarketEvents.DemandFactor" in market_events
assert "function MarketEvents.SupplyFactor" in market_events
assert market_events.count('        id = "') == 5
assert "marketEvents.DemandFactor" in economy
assert "economy.NewNeed(catalog, rng, event, marketEvents)" in population
assert "MarketEvents.Next" in server and "MarketEvents.SupplyFactor" in server
assert "Population.StartPurchase(population, Catalog, Economy, rng, marketEvent, MarketEvents)" in server
assert "marketBoardText" in server and "market = {" in server
assert "Sacola de compras" in server and 'StatusCliente' in server
assert "lastInventorySignature" in client and "marketNews" in client
assert "fingerprint == lastInventorySignature" in client
for config_path in ("ranked.project.json", "price_war.project.json"):
    project_data = json.loads((root / config_path).read_text(encoding="utf-8"))
    assert project_data["tree"]["ReplicatedStorage"]["Shared"]["MarketEvents"]["$path"].endswith("MarketEvents.luau")
    assert project_data["tree"]["ReplicatedStorage"]["Shared"]["ShopAnalytics"]["$path"].endswith("ShopAnalytics.luau")
assert "state.loadError" in client and "state.persistence" in client
assert 'ReturnToLobby' in server and 'ReturnToLobby' in client
assert 'ProfileStore.Save(userId, snapshot, Catalog)' in server
assert 'TeleportService.TeleportInitFailed' in server
assert 'lobbyConfigured' in server and 'lobbyConfigured' in client
assert 'returning[userId]' in server
routes = (root / "src/ReplicatedStorage/ModeRoutes.luau").read_text(encoding="utf-8")
assert 'lobby = {' in routes
for path in ("default.project.json", "ranked.project.json", "price_war.project.json"):
    place_tree = json.loads((root / path).read_text(encoding="utf-8"))["tree"]
    assert place_tree["ReplicatedStorage"]["ModeRoutes"]["$path"].endswith("ModeRoutes.luau"), path
lobby_server = (root / "src/ServerScriptService/LobbyServer.server.luau").read_text(encoding="utf-8")
lobby_client = (root / "src/StarterPlayer/StarterPlayerScripts/LobbyClient.client.luau").read_text(encoding="utf-8")
assert 'TeleportService:TeleportAsync' in lobby_server
assert 'ReservedServerId' in lobby_server
assert 'TeleportInitFailed' in lobby_server
assert 'RunService:IsStudio()' in lobby_server
assert 'SetAttribute("Action"' in lobby_client
assert 'ModeRoutes' in lobby_server
assert 'GlobalMatchmaker.new' in lobby_server
assert 'globalMatch:Join' in lobby_server
assert 'globalMatch:Cancel' in lobby_server
assert 'globalMatch:TeleportFailed' in lobby_server
matchmaker = (root / "src/ServerScriptService/GlobalMatchmaker.luau").read_text(encoding="utf-8")
routes = (root / "src/ReplicatedStorage/ModeRoutes.luau").read_text(encoding="utf-8")
assert 'GlobalMatchmakingEnabled = true' in routes
for api in ("GetSortedMap", "GetRangeAsync", "UpdateAsync", "GetAsync", "TeleportAsync"):
    assert api in matchmaker, f"Global matchmaking missing {api}"
for invariant in ('_rollback', 'self:_cancelRecord', 'isValidTicket', 'ReservedServerId',
                  'LOCK_SECONDS', 'POLL_SECONDS', 'WAIT_LEASE_SECONDS', 'MATCH_TTL'):
    assert invariant in matchmaker, f"Global matchmaking missing {invariant}"
assert 'data.globalQueue' in (root / "src/StarterPlayer/StarterPlayerScripts/LobbyClient.client.luau").read_text(encoding="utf-8")
assert 'cfg.Mode = "ranked"' in (root / "src/ReplicatedStorage/Shared/Configs/Ranked.luau").read_text(encoding="utf-8")
assert 'cfg.Mode = "price_war"' in (root / "src/ReplicatedStorage/Shared/Configs/PriceWar.luau").read_text(encoding="utf-8")

print("PASS: four Rojo projects, modules, lobby routes and basic economy invariants.")
print("NOTE: CI compiles Luau separately; Roblox Studio runtime / DataStore integration tests still required.")
