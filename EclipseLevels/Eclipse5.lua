local Healreduction = 0.6
local BuffedHealReduction = 0.6

local artiSelected = {}

Callback.add(Callback.ON_HEAL, function(actor_unwrapped, amount)
    local actor = Instance.wrap(actor_unwrapped)
    if Util.bool(ECLIPSEARTIFACTS[5].active) and actor.team == 1 then
        if not Instance.exists(actor) then return end
        if Net.client then return end

        if Util.bool(ALTECLIPSEARTIFACTS[5].active) then
            amount.value = amount.value * BuffedHealReduction
        else
            amount.value = amount.value * Healreduction
        end
    end
	
end)

RecalculateStats.add(Callback.Priority.AFTER, function(actor, api)
    if Util.bool(ECLIPSEARTIFACTS[5].active) and actor.team == 1 then
        if Util.bool(ALTECLIPSEARTIFACTS[5].active) then
            api.hp_regen_mult(BuffedHealReduction)
        else
            api.hp_regen_mult(Healreduction)
        end
    end
end)

-- Alt
local AltArtiIds = {}

for i, artifact in ipairs(Global.class_artifact) do
    for o = 1, 9 do
        artiSelected[o] = false
        if artifact ~= 0 and artifact[2] ~= 0 and ALTECLIPSEARTIFACTS[o] and  artifact[6] == ALTECLIPSEARTIFACTS[o].sprite_loadout_id then
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
                                                gm.translate(ECLIPSEARTIFACTS[o].token_description)

            if i ~= o then
                ECLIPSEDIFFICULTIES[i].token_description = ECLIPSEDIFFICULTIES[i].token_description .. "\n( " .. (o + 1) .. " )  "
            end
        end
    end
end

Callback.add(Callback.ON_GAME_START, function()
    for o = 1, 9 do
        artiSelected[o] = false
    end
    UpdateDescription()
end)

Hook.add_post(gm.constants["anon@20227@gml_Object_oSelectMenu_Create_0"], function(self, other, result, args)
    for i = 1, 9 do
        if args[1].value == AltArtiIds[i] then
            artiSelected[i] = not artiSelected[i]
        end
    end
    UpdateDescription()
end)