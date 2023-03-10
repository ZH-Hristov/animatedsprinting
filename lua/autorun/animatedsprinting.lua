AnimatedImmersiveSprinting = {Sprinters = {}}

local arse = AnimatedImmersiveSprinting
local table_IsEmpty = table.IsEmpty
local math_abs = math.abs
local maxside = 240

local TwoHandedHoldTypes = {
    ar2 = true,
    smg = true,
    rpg = true,
    physgun = true,
    crossbow = true,
    shotgun = true
}

local function GetForwardVelocity(ply)
    return ply:EyeAngles():Forward():Dot(ply:GetVelocity())
end

local function GetSideVelocity(ply)
    return math_abs(ply:EyeAngles():Right():Dot(ply:GetVelocity()))
end

local function AddHook()
    hook.Add("SetupMove", "AnimatedImmersiveSprinting_Move", function(ply, mv)
        local forw = GetForwardVelocity(ply)
        local side = GetSideVelocity(ply)

        if (forw <= 0 or side > maxside) or ply:GetSuitPower() <= 1 then
            ply.ImmerseSprint = nil
            if ply:IsOnGround() then
                mv:SetMaxClientSpeed(ply:GetWalkSpeed())
            end
        else
            ply.ImmerseSprint = true
        end
    end)

    hook.Add("TranslateActivity", "AnimatedImmersiveSprinting_Hook", function(ply, act)

        if ply.ImmerseSprint and act == ACT_MP_RUN then
            if ply:GetActiveWeapon() and TwoHandedHoldTypes[ply:GetActiveWeapon():GetHoldType()] then
                
                return ply:GetSequenceActivity(ply:LookupSequence("wos_mma_sprint_rifle_all"))
            end
            return ply:GetSequenceActivity(ply:LookupSequence("wos_mma_sprint_all"))
        end
    end)
end

local function RemoveHook()
    hook.Remove("SetupMove", "AnimatedImmersiveSprinting_Move")
    hook.Remove("TranslateActivity", "AnimatedImmersiveSprinting_Hook")
end

hook.Add("KeyPress", "AnimatedImmersiveSprinting_HandleKeyPress", function(ply, key)
    if key == IN_SPEED then
        arse.AddSprinter(ply)
    end
end)

hook.Add("KeyRelease", "AnimatedImmersiveSprinting_HandleKeyRelease", function(ply, key)
    if key == IN_SPEED then
        arse.RemoveSprinter(ply)
    end
end)

arse.AddSprinter = function(ply)
    if table_IsEmpty(arse.Sprinters) then
        AddHook()
    end

    arse.Sprinters[ply] = true
end

arse.RemoveSprinter = function(ply)
    arse.Sprinters[ply] = nil

    if table_IsEmpty(arse.Sprinters) then
        RemoveHook()
    end
end