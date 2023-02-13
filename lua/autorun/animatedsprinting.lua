AnimatedImmersiveSprinting = {Sprinters = {}}

local arse = AnimatedImmersiveSprinting
local table_IsEmpty = table.IsEmpty
local math_abs = math.abs
local maxside = 200

local function GetForwardVelocity(ply)
    return ply:EyeAngles():Forward():Dot(ply:GetVelocity())
end

local function GetSideVelocity(ply)
    return math_abs(ply:EyeAngles():Right():Dot(ply:GetVelocity()))
end

local function AddHook()
    hook.Add("StartCommand", "AnimatedImmersiveSprinting_Command", function(ply, cmd)
        local forw = GetForwardVelocity(ply)
        local side = GetSideVelocity(ply)

        if forw <= 0 or side > maxside then
            cmd:RemoveKey(IN_SPEED)
            ply.ImmerseSprint = nil
        else
            ply.ImmerseSprint = true
        end
    end)

    hook.Add("TranslateActivity", "AnimatedImmersiveSprinting_Hook", function(ply, act)

        if ply.ImmerseSprint and act == ACT_MP_RUN then
            return ply:GetSequenceActivity(ply:LookupSequence("wos_mma_sprint_rifle_all"))
        end
    end)
end

local function RemoveHook()
    hook.Remove("StartCommand", "AnimatedImmersiveSprinting_Command")
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