--!nonstrict
-- Parâmetros matemáticos da caminhada: sem dependência de física/Workspace.
-- A interpolação espacial continua a cargo do TweenService (CFrameValue).
local CustomerMotion = {}

function CustomerMotion.Stride(travelledStuds)
    local travelled = math.max(0, tonumber(travelledStuds) or 0)
    return math.sin(travelled * 2.2) * 0.34
end

function CustomerMotion.StepDistance(x1, z1, x2, z2)
    local dx, dz = x2 - x1, z2 - z1
    return math.sqrt(dx * dx + dz * dz)
end

function CustomerMotion.Interpolate(x1, z1, x2, z2, fraction)
    local t = math.clamp(tonumber(fraction) or 0, 0, 1)
    return x1 + (x2 - x1) * t, z1 + (z2 - z1) * t
end

return CustomerMotion
