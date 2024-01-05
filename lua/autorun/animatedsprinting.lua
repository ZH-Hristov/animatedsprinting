AnimatedImmersiveSprinting = {Sprinters = {}}

local cvars = {
    enabled = CreateConVar("AnimatedSprinting_enabled", 1, bit.band(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Enable or disable animated sprinting.", 0, 1),
    forceforward = CreateConVar("AnimatedSprinting_forwardonly", 1, bit.band(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Force sprinting to only work when running forward.", 0, 1),
    maxsidevel = CreateConVar("AnimatedSprinting_maxsidevelocity", 0.7, bit.band(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Max side velocity range (0 to 1) player can move at before sprinting is forced off. Default is 0.7 Requires forwardonly to be enabled.", 0, 1)
}

local arse = AnimatedImmersiveSprinting
local table_IsEmpty = table.IsEmpty
local math_abs = math.abs
local round = math.Round

local TwoHandedHoldTypes = {
    ar2 = true,
    smg = true,
    rpg = true,
    physgun = true,
    crossbow = true,
    shotgun = true,
    passive = true
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
        local side = round(GetSideVelocity(ply) / ply:GetRunSpeed(), 1)

        if (forw <= 0 or side > cvars.maxsidevel:GetFloat()) and cvars.forceforward:GetBool() or ply:GetSuitPower() <= 1 then
            ply:SetNWBool("ImmerseSprint", nil)
            if ply:IsOnGround() then
                mv:SetMaxClientSpeed(ply:GetWalkSpeed())
            end
        else
            ply:SetNWBool("ImmerseSprint", true)
        end
    end)

    hook.Add("CalcMainActivity", "AnimatedImmersiveSprinting_Hook", function(ply, act)

        if ply:GetNWBool("ImmerseSprint", nil) == true and act == ACT_MP_RUN then
            if IsValid(ply:GetActiveWeapon()) and TwoHandedHoldTypes[ply:GetActiveWeapon():GetHoldType()] then
                
                return nil, ply:LookupSequence("wos_mma_sprint_rifle_all")
            end
            return nil, ply:LookupSequence("wos_mma_sprint_all")
        end
    end)
end

local function RemoveHook()
    hook.Remove("SetupMove", "AnimatedImmersiveSprinting_Move")
    hook.Remove("CalcMainActivity", "AnimatedImmersiveSprinting_Hook")
end

hook.Add("KeyPress", "AnimatedImmersiveSprinting_HandleKeyPress", function(ply, key)
    if !cvars.enabled:GetBool() then return end

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