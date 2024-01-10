AnimatedImmersiveSprinting = {Sprinters = {}}
local loadedConfig = {
    enabled = 1,
    forceforward = 1,
    maxsidevel = 0.7,
    limitmousemovement = 0.3
}

if file.Exists("animatedsprintingserverconfig.json", "DATA") and util.JSONToTable(file.Read("animatedsprintingserverconfig.json")) then
    print("Animated Sprinting - Loading saved server config")

    local nlc = util.JSONToTable(file.Read("animatedsprintingserverconfig.json"))

    for k, v in pairs(nlc) do
        loadedConfig[k] = v
    end
end

local as_cvars = {
    enabled = CreateConVar("AnimatedSprinting_enabled", loadedConfig.enabled, FCVAR_REPLICATED, "Enable or disable animated sprinting.", 0, 1),
    forceforward = CreateConVar("AnimatedSprinting_forwardonly", loadedConfig.forceforward, FCVAR_REPLICATED, "Force sprinting to only work when running forward.", 0, 1),
    maxsidevel = CreateConVar("AnimatedSprinting_maxsidevelocity", loadedConfig.maxsidevel, FCVAR_REPLICATED, "Max side velocity range (0 to 1) player can move at before sprinting is forced off. Default is 0.7 Requires forwardonly to be enabled.", 0, 1),
    limitmousemovement = CreateConVar("AnimatedSprinting_limitmousemovement", loadedConfig.limitmousemovement, FCVAR_REPLICATED, "Max turn speed percentage while sprinting. Float from 0 to 1. Set to 1 to disable.", 0, 1)
}

local function saveConfig()
    if CLIENT then return end
    local t = {
        enabled = as_cvars.enabled:GetInt(),
        forceforward = as_cvars.forceforward:GetFloat(),
        maxsidevel = as_cvars.maxsidevel:GetFloat(),
        limitmousemovement = as_cvars.limitmousemovement:GetFloat()
    }

    file.Write("animatedsprintingserverconfig.json", util.TableToJSON(t))
end

if SERVER then
    for _, cvar in pairs(as_cvars) do
        cvars.AddChangeCallback(cvar:GetName(), saveConfig, "ascs_"..cvar:GetName())
    end
end

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

local function CanSprint(ply)
    local forw = GetForwardVelocity(ply)
    local side = round(GetSideVelocity(ply) / ply:GetRunSpeed(), 1)

    if not ply:IsSprinting() then return false end
    if ply:GetMoveType() ~= MOVETYPE_WALK then return false end
    if not ply:IsOnGround() then return false end

    if as_cvars.forceforward:GetBool() then
        if forw <= 0 then return false end
        if side > as_cvars.maxsidevel:GetFloat() then return false end
    end

    return true
end

hook.Add("SetupMove", "AnimatedImmersiveSprinting_Move", function(ply, mv)
    if not as_cvars.enabled:GetBool() then return end

    if CanSprint(ply) then
        ply:SetNWBool("ImmerseSprint", true)
    else
        ply:SetNWBool("ImmerseSprint", false)
        if as_cvars.forceforward:GetBool() and ply:IsSprinting() and ply:IsOnGround() and ply:GetMoveType() == MOVETYPE_WALK and mv:GetMaxClientSpeed() >= ply:GetWalkSpeed() then
            mv:SetMaxClientSpeed(ply:GetWalkSpeed())
        end
    end
end)

hook.Add("CalcMainActivity", "AnimatedImmersiveSprinting_Hook", function(ply)
    if not as_cvars.enabled:GetBool() then return end
    if ply:GetNWBool("ImmerseSprint", nil) == true then
        if IsValid(ply:GetActiveWeapon()) and TwoHandedHoldTypes[ply:GetActiveWeapon():GetHoldType()] then
            
            return -1, ply:LookupSequence("wos_mma_sprint_rifle_all")
        end
        return -1, ply:LookupSequence("wos_mma_sprint_all")
    end
end)

if CLIENT then
    hook.Add("AdjustMouseSensitivity", "AnimatedImmersiveSprinting_LimitMouseMovement", function(sens)
        if not as_cvars.enabled:GetBool() then return end
        if as_cvars.limitmousemovement:GetFloat() >= 1 then return end
        if not LocalPlayer():GetNWBool("ImmerseSprint") then return end

        return as_cvars.limitmousemovement:GetFloat()
    end)
end