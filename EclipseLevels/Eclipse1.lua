local reducedGoldDrops = false

Callback.remove(NAMESPACE.."1-onStageStart")
Callback.add("onStageStart", NAMESPACE.."1-onStageStart", function()
    if gm.bool(ECLIPSEARTIFACTS[1].active) then
        DIRECTOR.points = DIRECTOR.points + 500
        local roomWidth = gm._mod_room_get_current_width()
        local roomHeight = gm._mod_room_get_current_height()
        local enemies = List.wrap(Stage.wrap(gm._mod_game_getCurrentStage()).spawn_enemies)

        reducedGoldDrops = true
        local function resetGoldMul()
            reducedGoldDrops = false
        end
        Alarm.create(resetGoldMul, 1)

        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            DIRECTOR.points = DIRECTOR.points + 150 + 30 * DIRECTOR.minute_current
        else
            DIRECTOR.points = DIRECTOR.points + 100 + 25 * DIRECTOR.minute_current
        end
        
        for i = 1, 100 do
            local enemy = enemies[math.random(1, #enemies)]
            if Monster_Card.wrap(enemy).spawn_cost <= DIRECTOR.points then
                DIRECTOR:director_spawn_monster_card(math.random(1, gm._mod_room_get_current_width()), math.random(1, gm._mod_room_get_current_height()), enemy, 1)
                DIRECTOR.points = DIRECTOR.points - Monster_Card.wrap(enemy).spawn_cost
            end
        end
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
    if reducedGoldDrops then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            self.exp_worth = self.exp_worth * 0.45
        else
            self.exp_worth = self.exp_worth * 0.5
        end
    end
end)
