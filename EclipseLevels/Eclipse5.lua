local Healreduction = 0.6
local BuffedHealReduction = 0.6

local artiSelected = {}

gm.pre_script_hook(gm.constants.actor_heal_raw, function(self, other, result, args)
    if gm.bool(ECLIPSEARTIFACTS[5].active) and args[1].value.team == 1 then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            args[2].value = args[2].value * BuffedHealReduction
        else
            args[2].value = args[2].value * Healreduction
        end
    end
end)

-- Alt
local AltArtiIds = {}

for i, artifact in ipairs(Global.class_artifact) do
    for o = 1, 9 do
        artiSelected[o] = false
        if artifact ~= 0 and artifact[2] ~= 0 and ALTECLIPSEARTIFACTS[o] and  artifact[6] == ALTECLIPSEARTIFACTS[o].loadout_sprite_id then
            AltArtiIds[o] = i - 1
        end
    end
end

local function UpdateDescription()
    if artiSelected[5] then
        for i = 1, 9 do
            if artiSelected[i] then
                ECLIPSEARTIFACTS[i].token_description = "artifactbuffed.alteclipse"..i..".description"
            else
                ECLIPSEARTIFACTS[i].token_description = "artifactbuffed.eclipse"..i..".description"
            end
        end
    else
        for i = 1, 9 do
            if artiSelected[i] then
                ECLIPSEARTIFACTS[i].token_description = "artifact.alteclipse"..i..".description"
            else
                ECLIPSEARTIFACTS[i].token_description = "artifact.eclipse"..i..".description"
            end
        end
    end

    for i = 1, 9 do
        ECLIPSEDIFFICULTIES[i].token_description = "( 1 )  "
        for o = 1, i do
            ECLIPSEDIFFICULTIES[i].token_description = ECLIPSEDIFFICULTIES[i].token_description ..
                                                Language.translate_token(ECLIPSEARTIFACTS[o].token_description)

            if i ~= o then
                ECLIPSEDIFFICULTIES[i].token_description = ECLIPSEDIFFICULTIES[i].token_description .. "\n( " .. (o + 1) .. " )  "
            end
        end
    end
end

Callback.add(Callback.TYPE.onGameStart, NAMESPACE.."5alt-onGameStart", function()
    for o = 1, 9 do
        artiSelected[o] = false
    end
    UpdateDescription()
end)

gm.post_script_hook(gm.constants.anon_gml_Object_oSelectMenu_Create_0_200742116_gml_Object_oSelectMenu_Create_0, function(self, other, result, args)
    for i = 1, 9 do
        if args[1].value == AltArtiIds[i] then
            artiSelected[i] = not artiSelected[i]
        end
    end
    UpdateDescription()
end)