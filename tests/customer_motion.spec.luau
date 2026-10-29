-- Execução no Luau CLI sem Roblox Studio.
-- Matemática da marcha e interpolação, não garante renderização/replicação real.
local Motion = require("../src/ReplicatedStorage/Shared/CustomerMotion")

local function close(a, b)
    return math.abs(a - b) < 0.00001
end

assert(close(Motion.StepDistance(0, 0, 3, 4), 5), "distância euclidiana")
assert(close(Motion.StepDistance(22, -17, 22, -17), 0), "sem movimento")
local x, z = Motion.Interpolate(10, 2, 20, 12, 0)
assert(close(x, 10) and close(z, 2), "início")
x, z = Motion.Interpolate(10, 2, 20, 12, 0.5)
assert(close(x, 15) and close(z, 7), "interpolação suave")
x, z = Motion.Interpolate(10, 2, 20, 12, 1)
assert(close(x, 20) and close(z, 12), "destino")
x, z = Motion.Interpolate(10, 2, 20, 12, 9)
assert(close(x, 20) and close(z, 12), "clamp superior")
x, z = Motion.Interpolate(10, 2, 20, 12, -9)
assert(close(x, 10) and close(z, 2), "clamp inferior")
assert(close(Motion.Stride(0), 0), "parado")
assert(Motion.Stride(1) <= 0.34 and Motion.Stride(1) >= -0.34, "limite de passada")
assert(close(Motion.Stride(-20), 0), "distância negativa")
for i = 0, 100 do
    local s = Motion.Stride(i / 10)
    assert(s == s and math.abs(s) <= 0.341, "passada limitada sem NaN")
end
print("PASS: distância, interpolação e oscilação leve de marcha.")
