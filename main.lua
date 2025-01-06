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
local currentArtifact = {}
local NumArtifacts = 1
local Teleporter = nil
local disableChests = true
local CurseIndex = 0
local ItemDropChance = 10
local Director = nil
local FinishedTele = false
local player = {}
local allies = {}
local Tele_circles = {}
local frame = 0
local ExtraCreditsEnabled = 0
local alivePlayers = 0
local EndFight = false
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
local EnemyStats = 1.4
local EnemySkillcdr = 0.75
local EnemySpeed = 1.25

Initialize(function()
    Curse = mods["Klehrik-CurseHelper"].setup()
    Difficulty.new("ror", "eclipse9")
    local spiritStatHandler = Item.new("OnyxEclipse", "spiritStatHandler", true)
    spiritStatHandler.is_hidden = true
    spiritStatHandler:toggle_loot(false)

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

    for i = 1, 14 do
        Resources.sprite_load("Onyx", "Arti" .. i, PATH .. "arti" .. i .. ".png", 1, 0, 0)
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
    Callback.add("onPlayerInit", "OnyxEclipse-onPlayerInit", function(self)
        if (Player.get_client():same(self)) then
            player = {}
            PlayerIndex = 1
        end
        player[PlayerIndex] = self
        PlayerIndex = PlayerIndex + 1
    end)

    -- check which eclipse difficulty is active, if any
    Callback.add("onGameStart", "OnyxEclipse-onGameStart", function()
        local function OpenEclipse()
            if Eclipse:is_active() then
                GM.run_destroy()
                GM.variable_global_set("__gamemode_current", 1)
                GM.game_lobby_start()
                GM.room_goto(gm.constants.rSelect)
            end
        end
        Alarm.create(OpenEclipse, 1)

        EndFight = false
        Director = GM._mod_game_getDirector()
        Director.bonus_spawn_delay = 100
        Director.rate = 0
        for i = 1, NumArtifacts do
            currentArtifact[i] = 0
        end
        currentEclipse = 0
        for i = 1, 9 do
            if eclipses[i]:is_active() then
                currentEclipse = i
            end
        end

        if currentEclipse >= 9 then
            Director.elite_spawn_chance = 0.4
        end
    end)

    Callback.add("onStep", "OnyxEclipse-onStep", function()
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
            if currentEclipse >= 3 and Director:alarm_get(1) == -1 then
                Director:alarm_set(1, 600)
                Director.bonus_rate = 1
                Director.bonus_spawn_delay = 0
                FinishedTele = true
            end
        end

        if EndFight and Director:alarm_get(1) == 1 then
            local function DecreaseSpawnRate()
                Director:alarm_set(1, Director:alarm_get(1) * 5)
            end
            Alarm.create(DecreaseSpawnRate, 5)
        end
    end)

    local r = 0
    -- draws teleporter radius while timer isn't finished
    Callback.add("onDraw", "OnyxEclipse-onDraw", function()
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

    Callback.add("onSecond", "OnyxEclipse-onSecond", function(arg1, arg2)
        if ExtraCreditsEnabled > 0 then
            Director.points = Director.points + (Director.stages_passed + 1) * 2 + 5
            ExtraCreditsEnabled = ExtraCreditsEnabled - 1
            if ExtraCreditsEnabled == 1 then
                Director.bonus_rate = Director.bonus_rate - 2
            end
        end
    end)

    -- reduces hp when entering a new stage and when creating a new ally
    Callback.add("onStageStart", "OnyxEclipse-onStageStart", function()
        Tele_circles = {}
        FinishedTele = false
        disableChests = true

        if currentEclipse >= 1 then
            Director.bonus_rate = Director.bonus_rate + 2
            ExtraCreditsEnabled = 30
        end

        -- reset ally curse when entering a new stage
        allies = Instance.find_all(gm.constants.pFriend)
        for i, ally in ipairs(allies) do
            for i = 0, CurseIndex do
                Curse.remove(ally.value, "OnyxEclipse-PermaDamage" .. tostring(i))
            end
        end
        CurseIndex = 0
    end)

    -- doesn't use drop_gold_and_exp to keep barrel gold the same
    gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
        if currentEclipse >= 1 then
            self.exp_worth = self.exp_worth * 0.85
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
            EndFight = true
            local floors = nil
            if Instance.find(gm.constants.oB).object_index ~= nil then
                floors = Object.wrap(Instance.find(gm.constants.oB).object_index)
            end
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

    gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
        if currentEclipse ~= 0 then
            eclipses[currentEclipse]:set_allow_blight_spawns(true)
            log.warning("hi")
        end
        NumArtifacts = 1
        if args[1] == 9 then
            NumArtifacts = 2
        end
        if currentEclipse >= 7 then
            for i = 1, NumArtifacts do
                if currentArtifact[i] ~= nil and currentArtifact[i] ~= 0  then
                    player[1]:item_remove(Item.find("ror", "glassStatHandler"))
                    player[1]:item_remove(Item.find("ror", "distortionStatHandler"))
                    player[1]:item_remove(spiritStatHandler)
                    player[1]:recalculate_stats()
                    player[1]:remove_skill_override(0, 0)
                    player[1]:remove_skill_override(1, 0)
                    player[1]:remove_skill_override(2, 0)
                    player[1]:remove_skill_override(3, 0)
                    local Artifact = gm.variable_global_get("class_artifact")[currentArtifact[i]]
                    Artifact[9] = false
                    ItemDropChance = 20
                    currentArtifact[i] = 0
                end
            end

            local PickableArtifacts = {1, 2, 3, 4, 5, 7, 9, 10, 11, 12, 13, 14}
            local level_subname_length = 0
            for i = 1, NumArtifacts do
                local RandomArti = math.random(1, #PickableArtifacts)
                currentArtifact[i] = PickableArtifacts[RandomArti]
                table.remove(PickableArtifacts, RandomArti)
                
                --currentArtifact[i] = 7
                local Artifact = gm.variable_global_get("class_artifact")[currentArtifact[i]]
                local function DisplayCurrentArtifact()
                    if i == 1 then
                        level_subname_length = Global.level_subname:len()
                    end
                    local numSpaces = (level_subname_length - Language.translate_token(Artifact[3]):len() + 1) / 2
                    local Spaces = ""
                    for o = 1, numSpaces do
                        Spaces = Spaces .. " "
                    end
                    local Spaces2 = ""
                    numSpaces = (level_subname_length - 6) / 2
                    for o = 1, numSpaces do
                        Spaces2 = Spaces2 .. " "
                    end
                    Global.level_subname = Global.level_subname .. "\n" .. Spaces ..
                                               Language.translate_token(Artifact[3]) .. "\n" .. Spaces2 .. "<spr Arti" ..
                                               currentArtifact[i] .. " 1>"
                end
                Alarm.create(DisplayCurrentArtifact, 1)
                if currentArtifact[i] ~= 3 and currentArtifact[i] ~= 9 and currentArtifact[i] ~= 5 and
                    currentArtifact[i] ~= 7 then
                    Artifact[9] = true
                end
                if currentArtifact[i] == 3 then
                    local function WaitforPlayerInit()
                        if player[1]:item_stack_count(Item.find("ror", "distortionStatHandler")) == 0 then
                            player[1]:item_give(Item.find("ror", "distortionStatHandler"))
                        end
                        player[1]:add_skill_override(math.random(0, 3), 0)
                    end
                    Alarm.create(WaitforPlayerInit, 1)
                end
                if currentArtifact[i] == 9 then
                    local function WaitforPlayerInit()
                        if player[1]:item_stack_count(spiritStatHandler) == 0 then
                            player[1]:item_give(spiritStatHandler)
                        end
                    end
                    Alarm.create(WaitforPlayerInit, 1)
                end
                if currentArtifact[i] == 5 then
                    local function WaitforPlayerInit()
                        if player[1]:item_stack_count(Item.find("ror", "glassStatHandler")) == 0 then
                            player[1]:item_give(Item.find("ror", "glassStatHandler"))
                        end
                    end
                    Alarm.create(WaitforPlayerInit, 1)
                end
                if currentArtifact[i] == 1 then
                    eclipses[currentEclipse]:set_allow_blight_spawns(false)
                end
            end
        end
    end)

    local defaultcooldown = {}
    Callback.add("onMinute", "OnyxEclipse-onMinute", function(minute, second)
        for i = 1, NumArtifacts do
            if currentArtifact[i] == 3 then
                player[1]:remove_skill_override(0, 0)
                player[1]:remove_skill_override(1, 0)
                player[1]:remove_skill_override(2, 0)
                player[1]:remove_skill_override(3, 0)
                player[1]:add_skill_override(math.random(0, 3), 0)
            end
        end
    end)

    spiritStatHandler:onPostStep(function(actor, stack)
        actor.pHmax = actor.pHmax_raw - 2 * (actor.hp / actor.maxhp) + 2
    end)

    Callback.add(Callback.TYPE.onKillProc, "OnyxEclipse-onKillProc", function(victim, killer)
        for i = 1, NumArtifacts do
            if currentArtifact[i] == 7 and not FinishedTele and math.random(1, ItemDropChance) == ItemDropChance then
                if math.random(1, 100) == 100 then
                    Item.get_random(2):create(victim.x, victim.y)
                elseif math.random(1, 4) == 4 then
                    Item.get_random(1):create(victim.x, victim.y)
                elseif math.random(1, 5) == 5 then
                    Item.get_random(3):create(victim.x, victim.y)
                else
                    Item.get_random(0):create(victim.x, victim.y)
                end
                ItemDropChance = ItemDropChance + 8
            end
        end
    end)

    gm.post_script_hook(gm.constants.interactable_init, function(self, other, result, args)
        for i = 1, NumArtifacts do
            if currentArtifact[i] == 7 then
                local function myFunc(actor)
                    if actor.object_index ~= gm.constants.oTeleporter and actor.object_index ~=
                        gm.constants.oBlastdoorPanel and actor.object_index ~= gm.constants.oTeleporterEpic and
                        actor.object_index ~= gm.constants.oCustomObject_pInteractable and actor.object_index ~=
                        gm.constants.oCommand and actor.object_index ~= gm.constants.oRiftChest1 and actor.object_index ~=
                        gm.constants.oDoor and actor.object_index ~= gm.constants.oMedbay and actor.object_index ~=
                        gm.constants.oGauss and actor.object_index ~= gm.constants.oUsechest and actor.object_index ~=
                        gm.constants.oUsechestActive and actor.object_index ~= gm.constants.oGaussActive and
                        actor.object_index ~= gm.constants.oHiddenHand and actor.object_index ~= gm.constants.oMedcab and
                        actor.object_index ~= gm.constants.oChestToxin and actor.object_index ~= gm.constants.oBarrel3 and
                        actor.object_index ~= gm.constants.oMedbayActive and actor.object_index ~=
                        gm.constants.oCommandFinal and actor.object_index ~=
                        gm.constants.oCustomObject_pInteractableCrate and actor.object_index ~=
                        gm.constants.oCustomObject_pMapObjects and actor.object_index ~= gm.constants.oRoboBuddyBroken and
                        actor.object_index ~= gm.constants.oDroneRecycler and actor.object_index ~=
                        gm.constants.oDroneUpgrader then
                        -- log.warning(actor.value.object_name)
                        actor:destroy()
                    end
                end
                Alarm.create(myFunc, 1, Instance.wrap(self))
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

        for i = 1, NumArtifacts do
            if self.team == 2 and currentArtifact[i] == 9 then
                if Instance.wrap(self):item_stack_count(spiritStatHandler) == 0 then
                    Instance.wrap(self):item_give(spiritStatHandler)
                end
            end
            if self.team == 2 and currentArtifact[i] == 1 then
                self.exp_worth = self.exp_worth * 1.5
            end
        end

        -- increase enemy damage
        if currentEclipse >= 6 and self.team == 2.0 then
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

    Callback.add(Callback.TYPE.onDirectorPopulateSpawnArrays, "OnyxEclipse-onDirectorPopulateSpawnArrays", function()
        if Director.loops == 0 and currentEclipse >= 9 then
            -- add loop-exclusive spawns to pre-loop
            local director_spawn_array = Director.monster_spawn_array
            local current_stage = Stage.wrap(GM._mod_game_getCurrentStage())

            local loop_spawns = List.wrap(current_stage.spawn_enemies_loop)

            for _, card_id in ipairs(loop_spawns) do
                director_spawn_array:push(card_id)
            end
        end
    end)
end)

-- Add ImGui window
gui.add_to_menu_bar(function()
    for i = 1, 9 do
        params.Enabled[i] = ImGui.Checkbox("Eclipse " .. i .. " Enabled", params.Enabled[i])
    end
    Toml.save_cfg(_ENV["!guid"], params)
end)
gui.add_imgui(function()
    if ImGui.Begin("Eclipse") then
        for i = 1, 9 do
            params.Enabled[i] = ImGui.Checkbox("Eclipse " .. i .. " Enabled", params.Enabled[i])
        end
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
