--!strict
local cfg = table.clone(require(script.Parent:WaitForChild("BaseConfig")))
cfg.Mode = "ranked"
cfg.SaveEnabled = false
return cfg
