--!strict
local cfg = table.clone(require(script.Parent:WaitForChild("BaseConfig")))
cfg.Mode = "price_war"
cfg.SaveEnabled = false
return cfg
