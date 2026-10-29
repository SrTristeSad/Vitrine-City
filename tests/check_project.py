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
assert tree["StarterPlayer"]["StarterPlayerScripts"]["VitrineClient"]["$path"].endswith(".client.luau")

sources = [
    "src/ReplicatedStorage/Shared/Config.luau",
    "src/ReplicatedStorage/Shared/Catalog.luau",
    "src/ReplicatedStorage/Shared/Economy.luau",
    "src/ReplicatedStorage/Shared/Population.luau",
    "src/ServerScriptService/VitrineServer.server.luau",
    "src/ServerScriptService/ProfileStore.luau",
    "src/StarterPlayer/StarterPlayerScripts/VitrineClient.client.luau",
]
for source in sources:
    text = (root / source).read_text(encoding="utf-8")
    assert len(text) > 100, f"Empty or suspicious file: {source}"
    assert "\x00" not in text, f"NUL byte: {source}"

catalog = (root / sources[1]).read_text(encoding="utf-8")
ids = re.findall(r'\bid = "([^"]+)"', catalog)
assert len(ids) == 6 and len(set(ids)) == len(ids), f"Unexpected catalog: {ids}"

economy = (root / sources[2]).read_text(encoding="utf-8")
population = (root / sources[3]).read_text(encoding="utf-8")
server = (root / sources[4]).read_text(encoding="utf-8")
profiles = (root / sources[5]).read_text(encoding="utf-8")
client = (root / sources[6]).read_text(encoding="utf-8")
for name in ("NewNeed", "PickOffer", "NetWorth"):
    assert f"function Economy.{name}" in economy
for name in ("Create", "StartPurchase", "FinishPurchase", "Hire", "PayWorker", "Layoff", "StartDay", "Stats"):
    assert f"function Population.{name}" in population
for module in ("Config", "Catalog", "Population", "Economy"):
    assert f'WaitForChild("{module}")' in server
for remote in ("Action", "State", "Notice"):
    assert f'event("{remote}")' in server
    assert f'WaitForChild("{remote}")' in client

assert "Config.MaxVisibleCustomers" in server
assert "person.wallet < price" in server
assert "account.cash -= cost" in server
assert "Population.FinishPurchase" in server
assert "Population.PayWorker" in server
assert "ProfileStore.Load" in server and "ProfileStore.Save" in server and "ProfileStore.Release" in server
assert "ProfileStore" in profiles and "UpdateAsync" in profiles
assert "RunService:IsStudio()" in profiles and "Config.StudioPersistence" in profiles
assert "Config.AutosaveSeconds" in server
assert "state.loadError" in client and "state.persistence" in client
print("PASS: Rojo mappings, module references, six unique items and basic economy invariants.")
print("NOTE: CI compiles Luau separately; Roblox Studio runtime / DataStore integration tests still required.")
