local reducedGoldDrops = false

Callback.add(Callback.ON_STAGE_START, function()
    if gm.bool(ECLIPSEARTIFACTS[1].active) then
        -- local roomWidth = gm._mod_room_get_current_width()
        -- local roomHeight = gm._mod_room_get_current_height()
        local enemies = List.wrap(Stage.wrap(gm._mod_game_getCurrentStage()).spawn_enemies)

        reducedGoldDrops = true
        Alarm.add(1, function()
            if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
                DIRECTOR.points = DIRECTOR.points + 300 + 30 * DIRECTOR.minute_current
            else
                DIRECTOR.points = DIRECTOR.points + 200 + 25 * DIRECTOR.minute_current
            end
            
            for i = 1, 100 do
                local enemy = enemies[math.random(1, #enemies)]
                local ground = DIRECTOR:ground_nearest(math.random(1, gm._mod_room_get_current_width()), math.random(1, gm._mod_room_get_current_height()))
                DIRECTOR.points = DIRECTOR.points + 5 + 2 * DIRECTOR.stages_passed
                if MonsterCard.wrap(enemy).spawn_cost <= DIRECTOR.points then
                    local instance = DIRECTOR:director_spawn_monster_card(ground.x + math.random(0, ground.width_box * 32 - 32), ground.y - ground.height_box * 32, enemy, 10)
                    DIRECTOR.points = DIRECTOR.points - MonsterCard.wrap(enemy).spawn_cost
                    DIRECTOR:director_try_elite_spawn(instance, enemy, false)
                end
            end
            reducedGoldDrops = false
        end)
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
Hook.add_post(gm.constants.instance_create_depth, function(self, other, result, args)
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
Hook.add_post(gm.constants.enemy_stats_init, function(self, other, result, args)
    if reducedGoldDrops then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            self.exp_worth = self.exp_worth * 0.45
        else
            self.exp_worth = self.exp_worth * 0.5
        end
    end
end)
