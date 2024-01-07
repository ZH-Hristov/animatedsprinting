AnimatedImmersiveSprinting = {Sprinters = {}}
local loadedConfig = {}

if file.Exists("animatedsprintingserverconfig.json", "DATA") and util.JSONToTable(file.Read("animatedsprintingserverconfig.json")) then
    print("Animated Sprinting - Loading saved server config")

    loadedConfig = util.JSONToTable(file.Read("animatedsprintingserverconfig.json"))
else
    loadedConfig = {
        enabled = 1,
        forceforward = 1,
        maxsidevel = 0.7
    }
end

local as_cvars = {
    enabled = CreateConVar("AnimatedSprinting_enabled", loadedConfig.enabled, bit.band(FCVAR_REPLICATED), "Enable or disable animated sprinting.", 0, 1),
    forceforward = CreateConVar("AnimatedSprinting_forwardonly", loadedConfig.forceforward, bit.band(FCVAR_REPLICATED), "Force sprinting to only work when running forward.", 0, 1),
    maxsidevel = CreateConVar("AnimatedSprinting_maxsidevelocity", loadedConfig.maxsidevel, bit.band(FCVAR_REPLICATED), "Max side velocity range (0 to 1) player can move at before sprinting is forced off. Default is 0.7 Requires forwardonly to be enabled.", 0, 1)
}

local function saveConfig()
    if CLIENT then return end
    local t = {
        enabled = as_cvars.enabled:GetInt(),
        forceforward = as_cvars.forceforward:GetFloat(),
        maxsidevel = as_cvars.maxsidevel:GetFloat()
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

hook.Add("KeyPress", "AnimatedImmersiveSprinting_HandleKeyPress", function(ply, key)
    if !as_cvars.enabled:GetBool() then return end

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
    arse.Sprinters[ply] = true
end

arse.RemoveSprinter = function(ply)
    arse.Sprinters[ply] = nil
end