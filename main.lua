log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
PATH = _ENV["!plugins_mod_folder_path"] .. "/Assets/"
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        Enabled = {true, true, true, true, true, true, true, true, true}
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local Eclipse = nil
local eclipses = {}
local currentEclipse = 0
local Teleporter = nil
local disableChests = true
local CurseIndex = 0
local Director = nil
local FinishedTele = false
local player = {}
local allies = {}
local Tele_circles = {}
local frame = 0
local ExtraCreditsEnabled = 0
local alivePlayers = 0
local Interactables = {gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5, gm.constants.oChestHealing1,
                       gm.constants.oChestDamage1, gm.constants.oChestUtility1, gm.constants.oChestHealing2,
                       gm.constants.oChestDamage2, gm.constants.oChestUtility2, gm.constants.oGunchest,
                       gm.constants.oChest4, gm.constants.oEfChestRain, gm.constants.oShop1, gm.constants.oShop2,
                       gm.constants.oActivator, gm.constants.oBarrelEquipment, gm.constants.oShopEquipment,
                       gm.constants.oTeleporter, gm.constants.oBlastdoorPanel, gm.constants.oShrine1,
                       gm.constants.oShrine2, gm.constants.oShrine3, gm.constants.oShrine4, gm.constants.oShrine5}

-- Parameters
local TeleColor = 190540540
local TeleRadius = 600
local PriceIncrease = 1.6
local EnemyStats = 1.5
local EnemySkillcdr = 0.5
local EnemySpeed = 1.25

Initialize(function()
    Curse = mods["Klehrik-CurseHelper"].setup()
    Difficulty.new("ror", "eclipse9")

    -- find eclipse difficulties
    for i = 1, 9 do
        eclipses[i] = Difficulty.find("ror", "eclipse" .. tostring(i))
        eclipses[i]:set_sound(Resources.sfx_load("Onyx", "EclipseSfx", PATH .. "eclipse.ogg"))
    end

    -- get the max eclipse level of all survivors for gold eclipse
    local MaxEclipse = 9
    for i = 0, #Class.SURVIVOR - 1 do
        if gm.difficulty_eclipse_get_max_available_level_for_survivor(i) < MaxEclipse then
            MaxEclipse = GM.difficulty_eclipse_get_max_available_level_for_survivor(i)
        end
    end
    for i = 1, MaxEclipse - 1 do
        eclipses[i]:set_sprite(Resources.sprite_load("Onyx", "GoldEclipse" .. i, PATH .. "GoldEclipse" .. i .. ".png",
            2, 13, 13), Resources.sprite_load("Onyx", "GoldEclipse" .. i .. "_2x",
            PATH .. "GoldEclipse" .. i .. "_2x.png", 4, 20, 19))
    end

    -- add difficulty that opens eclipse menu
    Eclipse = Difficulty.new("Onyx", "eclipse")
    if MaxEclipse <= 8 then
        Eclipse:set_sprite(Resources.sprite_load("Onyx", "EclipseIcon", PATH .. "StartEclipse.png", 1, 12, 12),
            Resources.sprite_load("Onyx", "EclipseIcon2x", PATH .. "StartEclipse_2x.png", 4, 20, 19))
    elseif MaxEclipse <= 9 then
        Eclipse:set_sprite(
            Resources.sprite_load("Onyx", "EclipseIconTyphoon", PATH .. "StartEclipseTyphoon.png", 1, 12, 12),
            Resources.sprite_load("Onyx", "EclipseIconTyphoon2x", PATH .. "StartEclipseTyphoon_2x.png", 4, 20, 19))
    else
        Eclipse:set_sprite(Resources.sprite_load("Onyx", "EclipseIcon", PATH .. "StartEclipseGold.png", 1, 12, 12),
            Resources.sprite_load("Onyx", "EclipseIcon2x", PATH .. "StartEclipseGold_2x.png", 4, 20, 19))
    end
    Eclipse:set_primary_color(Color(0x62a8e5))
    Eclipse:set_sound(Resources.sfx_load("Onyx", "EclipseSfx", PATH .. "eclipse.ogg"))

    -- add secret eclipse 9
    eclipses[9]:set_scaling(0.2, 4.0, 1.7)
    eclipses[9]:set_monsoon_or_higher(true)
    eclipses[9]:set_allow_blight_spawns(true)
    eclipses[9]:set_sprite(Resources.sprite_load("Onyx", "Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13),
        Resources.sprite_load("Onyx", "Eclipse9_2x", PATH .. "Eclipse9_2x.png", 6, 20, 19))
    local EclipseDisplay = List.wrap(GM.variable_global_get("difficulty_display_list_eclipse"))
    EclipseDisplay:add(Wrap.wrap(eclipses[9]))

    gm.pre_script_hook(gm.constants.game_lobby_start, function(self, other, result, args)
        local DifficultyDisplay = List.wrap(GM.variable_global_get("difficulty_display_list"))

        for i = #DifficultyDisplay, 1, -1 do
            if DifficultyDisplay[i] == Wrap.wrap(Eclipse) or DifficultyDisplay[i] == Wrap.wrap(eclipses[9]) then
                DifficultyDisplay:delete(i - 1)
            elseif DifficultyDisplay[i] > 2 and DifficultyDisplay[i] < 11 then
                DifficultyDisplay:delete(i - 1)
            end
        end

        if self and self.class_ind == nil then
            for i = 1, 9 do
                if params.Enabled[i] then
                    DifficultyDisplay:add(2 + i)
                end
            end
        else
            DifficultyDisplay:add(Wrap.wrap(Eclipse))
        end
    end)

    local PlayerIndex = 1
    Callback.add("onPlayerInit", "OnyxEclipse-onPlayerInit", function(self, other, result, args)
        if (self.player_p_number == Player.get_client().player_p_number) then
            player = {}
            PlayerIndex = 1
        end
        player[PlayerIndex] = self
        PlayerIndex = PlayerIndex + 1
    end)

    Callback.add("onStep", "OnyxEclipse-onStep", function(self, other, result, args)
        -- open the eclipse menu
        if Eclipse:is_active() then
            GM.run_destroy()
            GM.variable_global_set("__gamemode_current", 1)
            GM.game_lobby_start()
            GM.room_goto(gm.constants.rSelect)
        end

        -- get number of alive players
        alivePlayers = 0
        for i = 1, #player do
            if not player[i].dead then
                alivePlayers = alivePlayers + 1
            end
        end

        ---Add Eclipse modifiers---

        if Teleporter then
            if currentEclipse >= 2 and Teleporter.active == 1 then
                -- don't let tp timer count up if player is outside radius
                for i = 1, #player do
                    if player[i].dead == false then
                        local DistanceX, DistanceY
                        DistanceX = player[i].x - Teleporter.x
                        DistanceY = player[i].y - Teleporter.y
                        if math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >= TeleRadius then
                            Teleporter.time = Teleporter.time - (1 / alivePlayers)
                        end
                    end
                end

                -- lock chests outside of tp radius
                if disableChests then
                    disableChests = false
                    local chests = Instance.find_all(Interactables)
                    for k, v in pairs(chests) do
                        if v.active == 0 then
                            DistanceX = v.x - Teleporter.x
                            DistanceY = v.y - Teleporter.y
                            if math.sqrt(DistanceX ^ 2 + DistanceY ^ 2) >= TeleRadius then
                                v.active = -1
                            end
                        end
                    end
                end
            else
                -- reenable locked chests after tp event
                if not disableChests then
                    local chests = Instance.find_all(Interactables)
                    disableChests = true
                    for k, v in pairs(chests) do
                        if v.active == -1 then
                            v.active = 0
                        end
                    end
                end
            end
            -- reenable enemy spawning after tp event
            if currentEclipse >= 3 and Director:alarm_get(1) == -1 and not FinishedTele then
                Director:alarm_set(1, 600)
                Director.bonus_rate = 1
                Director.bonus_spawn_delay = 0
                FinishedTele = true
            end
        end
    end)

    local r = 0
    -- draws teleporter radius while timer isn't finished
    Callback.add("onDraw", "OnyxEclipse-onDraw", function(self, other, result, args)
        if Teleporter then
            if Teleporter.active == 1 and currentEclipse >= 2 then
                gm.draw_set_circle_precision(128)
                gm.draw_set_alpha(0.8)
                if r < 0.999 then
                    r = r + (1 - r) * 0.05
                else
                    r = 1
                end
                gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * r, TeleColor, TeleColor, true)

            end
            if Teleporter.active ~= 1 and r >= 1 and r < 1.1 then
                r = r * 1.01
                gm.draw_set_alpha(0.8 - math.fmod(r, 0.1))
                gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * r, TeleColor, TeleColor, true)
            end
            if r == 1 then
                frame = frame + 1
                if frame % 45 == 0 then
                    table.insert(Tele_circles, 0.9)
                end
            end
            if r >= 1 then
                for i = #Tele_circles, 1, -1 do
                    if Tele_circles[i] then
                        gm.draw_set_alpha(0.9 - ((Tele_circles[i] - 0.95) / 0.05) ^ 2)
                        Tele_circles[i] = Tele_circles[i] * 1.001
                        gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * Tele_circles[i], TeleColor,
                            TeleColor, true)
                        if Tele_circles[i] >= 1 then
                            table.remove(Tele_circles, i)
                        end
                    end
                end
            end
            gm.draw_set_alpha(1.0)
        end
    end)

    Callback.add("onSecond", "OnyxEclipse-onSecond", function(self, other, result, args)
        if ExtraCreditsEnabled > 0 then
            Director.points = Director.points + (Director.stages_passed + 1) * 2 + 5
            ExtraCreditsEnabled = ExtraCreditsEnabled - 1
            if ExtraCreditsEnabled == 1 then
                Director.bonus_rate = Director.bonus_rate - 2
            end
        end
    end)

    -- check which eclipse difficulty is active, if any
    Callback.add("onGameStart", "OnyxEclipse-onGameStart", function(self, other, result, args)
        Director = self
        currentEclipse = 0
        for i = 1, 9 do
            if eclipses[i]:is_active() then
                currentEclipse = i
            end
        end
    end)

    -- reduces hp when entering a new stage and when creating a new ally
    Callback.add("onStageStart", "OnyxEclipse-onStageStart", function(self, other, result, args)
        FinishedTele = false
        disableChests = true

        if currentEclipse >= 1 then
            Director.bonus_rate = Director.bonus_rate + 2
            ExtraCreditsEnabled = 30
        end
        CurseIndex = 0
    end)

    -- doesn't use drop_gold_and_exp to keep barrel gold the same
    gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
        if currentEclipse >= 1 then
            self.exp_worth = self.exp_worth * 0.9
        end

        if currentEclipse >= 9 then
            self.exp_worth = self.exp_worth * 0.7
        end
    end)

    -- decrease gold and xp gain outside of tp zone
    gm.pre_script_hook(gm.constants.drop_gold_and_exp, function(self, other, result, args)
        if Teleporter and currentEclipse >= 2 then
            local DistanceX, DistanceY
            for i = 1, #player do
                DistanceX = player[i].x - Teleporter.x
                DistanceY = player[i].y - Teleporter.y
                if Director.teleporter_active == 1 and math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >=
                    TeleRadius then
                    args[3].value = args[3].value * (1 - 0.3 / alivePlayers)
                end
            end
        end
    end)

    gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        -- get teleporter when interacting with it
        if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
            self.object_index == gm.constants.oBlastdoorPanel then
            r = 0
            Teleporter = self
        end

        if self.object_index == gm.constants.oCommand then
            -- reduce enemy spawning after starting provi fight
            Director.bonus_rate = 0.5
            Director.bonus_spawn_delay = 0.5
            local floors = Object.wrap(Instance.find(gm.constants.oB).object_index)
            local Spawns = Instance.find_all({gm.constants.oNoNavHere, gm.constants.oBFloorNoSpawn, gm.constants.oB,
                                              gm.constants.oBNoSpawnHalf, gm.constants.oBFloorNoSpawn2})

            -- I have 0 clue why this works. Replicates providence arena collission to allow mob spawning and destroys collission outside of arena
            for i = 1, #Spawns do
                if Spawns[i].object_index == gm.constants.oBFloorNoSpawn2 then
                    local floor = nil
                    floor = floors:create(Spawns[i].x, Spawns[i].y)
                    floor.width_box = Spawns[i].width_box - 1
                    floor.height_box = Spawns[i].height_box
                    floors:create(Spawns[i].x - 3, Spawns[i].y)
                else
                    Spawns[i]:destroy()
                end
            end
        end
    end)

    gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
        -- increase enemy speed
        if self.team == 2.0 and currentEclipse >= 4 then
            self.pHmax_raw = self.pHmax_raw * EnemySpeed
            self.pHmax = self.pHmax * EnemySpeed
            self.attack_speed = self.attack_speed * EnemySpeed
        end

        -- reduce enemy skill cooldowns
        if currentEclipse >= 7 then
            local actor = Instance.wrap(self)
            local skills = {actor:get_active_skill(Skill.SLOT.primary), actor:get_active_skill(Skill.SLOT.secondary),
                            actor:get_active_skill(Skill.SLOT.utility), actor:get_active_skill(Skill.SLOT.special)}
            for i, skill in ipairs(skills) do
                skill.cooldown = math.ceil(skill.cooldown * EnemySkillcdr)
            end
        end

        if self.team == 2.0 and currentEclipse >= 9 then
            local actor = Instance.wrap(self)
            actor.attack_speed = actor.attack_speed + actor.attack_speed_base * 0.15
            actor.pHmax_raw = actor.pHmax_raw + actor.pHmax_base * 0.15
            actor.pHmax = actor.pHmax + actor.pHmax_base * 0.15

            -- the cdr variable does nothing at this point. handle skill cdr manually.
            local skills = {actor:get_active_skill(Skill.SLOT.primary), actor:get_active_skill(Skill.SLOT.secondary),
                            actor:get_active_skill(Skill.SLOT.utility), actor:get_active_skill(Skill.SLOT.special)}
            for _, skill in ipairs(skills) do
                skill.cooldown = math.ceil(skill.cooldown * 0.85)
            end
        end
    end)

    -- increase chest prices
    gm.pre_script_hook(gm.constants.interactable_init_cost, function(self, other, result, args)
        if args[2].value == 0 and currentEclipse >= 5 then
            args[3].value = args[3].value * PriceIncrease
        end
    end)

    gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
        -- disable gold drops on enemies spawned after tp event
        if FinishedTele and self.team == 2 then
            self.exp_worth = 0
        end

        -- increase enemy max health and damage
        if currentEclipse >= 6 and self.team == 2.0 then
            self.maxhp = self.maxhp * EnemyStats
            self.maxhp_base = self.maxhp_base * EnemyStats
            self.hp = self.hp * EnemyStats
            self.damage_base = self.damage_base * EnemyStats
        end
    end)

    -- give curse on e8
    gm.post_script_hook(gm.constants.actor_proc_on_damage, function(self, other, result, args)
        if currentEclipse >= 8 and self.team == 1 then
            Curse.apply(self, "OnyxEclipse-PermaDamage" .. tostring(CurseIndex),
                0.01 * 40 * args[1].value.damage_true / self.maxhp)
            CurseIndex = CurseIndex + 1
        end
    end)

    Callback.add("onDirectorPopulateSpawnArrays", "SSTyphoonPreLoopMonsters", function(self, other, result, args)
        if self.loops == 0 and currentEclipse >= 9 then
            -- add loop-exclusive spawns to pre-loop
            local director_spawn_array = Array.wrap(self.monster_spawn_array)
            local current_stage = Stage.wrap(GM._mod_game_getCurrentStage())

            local loop_spawns = List.wrap(current_stage.spawn_enemies_loop)

            for _, card_id in ipairs(loop_spawns) do
                director_spawn_array:push(card_id)
            end
        end
    end)
end)

-- Add ImGui window
gui.add_imgui(function()
    if ImGui.Begin("Eclipse") then
        for i = 1, 9 do
            params.Enabled[i] = ImGui.Checkbox("Eclipse " .. i .. " Enabled", params.Enabled[i])
        end
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
