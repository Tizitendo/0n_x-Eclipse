local ExtraCreditsEnabled = 0

Callback.remove(NAMESPACE.."1-onStageStart")
Callback.add("onStageStart", NAMESPACE.."1-onStageStart", function()
    if gm.bool(ECLIPSEARTIFACTS[1].active) then
        DIRECTOR.points = DIRECTOR.points + (40 + 10 * DIRECTOR.minute_current)
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            DIRECTOR.points = DIRECTOR.points + (40 + 10 * DIRECTOR.minute_current)
        end
        ExtraCreditsEnabled = 60
    end

    -- Alt
    if gm.bool(ALTECLIPSEARTIFACTS[1].active) then
        local allies = Instance.find_all(gm.constants.pFriend)
        for i = 1, #allies do
            if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
                allies[i].hp = allies[i].hp * 0.4
            else
                allies[i].hp = allies[i].hp * 0.5
            end
        end
    end
end)
gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    if gm.bool(ALTECLIPSEARTIFACTS[1].active) and result.value ~= nil and result.value.hp ~= nil and result.value.team == 1 and
        result.value.object_index ~= gm.constants.oP then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            result.value.hp = result.value.hp * 0.4
        else
            result.value.hp = result.value.hp * 0.5
        end
    end
end)

-- doesn't use drop_gold_and_exp to keep barrel gold the same
gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    if ExtraCreditsEnabled > 0 then
        self.exp_worth = self.exp_worth * 0.5
    end
end)

-- add director credits
Callback.add("onSecond", "OnyxEclipse1-onSecond", function(minute, second)
    if ExtraCreditsEnabled > 0 then
        DIRECTOR.points = DIRECTOR.points + (4 + 1.3 * minute)
        ExtraCreditsEnabled = ExtraCreditsEnabled - 1
    end

    if TELEPORTER and
        (TELEPORTER.object_index == gm.constants.oTeleporter or TELEPORTER.object_index == gm.constants.oTeleporterEpic) and
        (TELEPORTER.time == TELEPORTER.maxtime - 1 or TELEPORTER.time == TELEPORTER.maxtime - 2) then
            DIRECTOR.points = DIRECTOR.points - (2 + 1.7 * minute) * 0.5
    end
end)