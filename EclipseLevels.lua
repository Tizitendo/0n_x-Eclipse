local PATH = _ENV["!plugins_mod_folder_path"]
Curse = mods["Klehrik-CurseHelper"].setup()

local ExtraCreditsEnabled = 0
local alivePlayers = 0
local Teleporter = nil
local player = {}
local Director = nil
local eclipses = {}
local disableChests = true;
local RadiusMul = 0
local frame = 0
local Tele_circles = {}
local FinishedTele = false
local EndFight = false
local NumArtifacts = 0
local currentArtifact = {}
local BaseArtifacts = {}
local EclipseArtifacts = {}
local ActiveEclipse = false
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
local EnemyStats = 1.30
local EnemySkillcdr = 0.75
local EnemySpeed = 1.25
local DefaultSacrificeDropChance = 15

for i = 1, 9 do
    eclipses[i] = Difficulty.find("ror", "eclipse" .. i)
end

for k, v in ipairs(Global.class_artifact) do
    if v ~= 0 and v[1] == "OnyxEclipse" then
        table.insert(EclipseArtifacts, v)
    end
end

Callback.add("onGameStart", "OnyxEclipseGen-onGameStart", function()
    for i = 0, #Class.SURVIVOR - 1 do
        --log.warning(GM.difficulty_eclipse_get_max_available_level_for_survivor(i))

    end


    ExtraCreditsEnabled = 0
    player = {}
    Director = GM._mod_game_getDirector()
    EndFight = false

    if not params.ShowArtifacts then
        for i = 1, 9 do
            EclipseArtifacts[i][9] = false
        end
    end

    ActiveEclipse = false
    for i = 9, 1, -1 do
        if eclipses[i]:is_active() then
            ActiveEclipse = true
        end
        if ActiveEclipse then
            EclipseArtifacts[i][9] = true
        end
    end

    if eclipses[9]:is_active() then
        GM._mod_game_setDifficulty(Difficulty.find("ssr", "typhoon"))
    end

    -- Get Artifacts, including modded and check if activated
    if not ActiveEclipse then
        BaseArtifacts = {}
        for k, v in ipairs(Global.class_artifact) do
            if v ~= 0 and v[2] ~= 0 then
                table.insert(BaseArtifacts, v)
            end
        end

        for i = #BaseArtifacts, 1, -1 do
            if (BaseArtifacts[i][1] ~= "ror" or BaseArtifacts[i][2] == "enigma" or BaseArtifacts[i][2] == "command") and
                (not gm.bool(BaseArtifacts[i][9]) or BaseArtifacts[i][1] == "OnyxEclipse") then
                table.remove(BaseArtifacts, i)
            end
        end
    end
end)

gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    -- get teleporter when interacting with it
    if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
        self.object_index == gm.constants.oBlastdoorPanel then
        RadiusMul = 0
        Teleporter = self
    end
end)

Callback.add("onPlayerInit", "OnyxEclipseGen-onPlayerInit", function(self)
    local PlayerId = self.m_id
    if PlayerId == 0 then
        PlayerId = 1
    end
    player[PlayerId] = Wrap.wrap(self)
end)

---- Eclipse 1 ----
Callback.add("onStageStart", "OnyxEclipse1-onStageStart", function()
    frame = 0
    disableChests = true
    Tele_circles = {}
    FinishedTele = false

    if gm.bool(EclipseArtifacts[1][9]) then
        Director.bonus_rate = Director.bonus_rate + 2
        ExtraCreditsEnabled = 30
    end
end)

-- doesn't use drop_gold_and_exp to keep barrel gold the same
gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    if gm.bool(EclipseArtifacts[1][9]) then
        self.exp_worth = self.exp_worth * 0.90
    end
end)

-- add director credits
Callback.add("onSecond", "OnyxEclipse1-onSecond", function(arg1, arg2)
    if ExtraCreditsEnabled > 0 then
        Director.points = Director.points + (Director.stages_passed + 1) * 2 + 5
        ExtraCreditsEnabled = ExtraCreditsEnabled - 1
        if ExtraCreditsEnabled == 1 then
            Director.bonus_rate = Director.bonus_rate - 2
        end
    end
end)

---- Eclipse 2 ----
Callback.add("onStep", "OnyxEclipse2-onStep", function()
    -- get number of alive players
    alivePlayers = 0
    for i = 1, #player do
        if not player[i].dead then
            alivePlayers = alivePlayers + 1
        end
    end

    if gm.bool(EclipseArtifacts[2][9]) and Teleporter then
        if Teleporter.active == 1 then
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
                        local DistanceX = v.x - Teleporter.x
                        local DistanceY = v.y - Teleporter.y
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
    end

end)

Callback.add("onDraw", "OnyxEclipse2-onDraw", function()
    frame = frame + 1
    if gm.bool(EclipseArtifacts[2][9]) and Teleporter then
        gm.draw_set_circle_precision(128)
        if Teleporter.active == 1 then
            gm.draw_set_alpha(0.8)
            if RadiusMul < 0.999 then
                RadiusMul = RadiusMul + (1 - RadiusMul) * 0.05
            else
                RadiusMul = 1
            end
            gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * RadiusMul, TeleColor, TeleColor, true)
        end
        if Teleporter.active ~= 1 and RadiusMul >= 1 and RadiusMul < 1.1 then
            RadiusMul = RadiusMul * 1.01
            gm.draw_set_alpha(0.8 - math.fmod(RadiusMul, 0.1))
            gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * RadiusMul, TeleColor, TeleColor, true)
        end
        if RadiusMul == 1 then
            frame = frame + 1
            if frame % 45 == 0 then
                table.insert(Tele_circles, 0.9)
            end
        end
        if RadiusMul >= 1 then
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

gm.pre_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    if Teleporter and Teleporter.active == 1 and gm.bool(EclipseArtifacts[2][9]) then
        local DistanceX, DistanceY
        for i = 1, #player do
            DistanceX = player[i].x - Teleporter.x
            DistanceY = player[i].y - Teleporter.y
            if Director.teleporter_active == 1 and math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >=
                TeleRadius then
                self.exp_worth = self.exp_worth * (1 - 0.5 / alivePlayers)
            end
        end
    end
end)

-- Eclipse3
Callback.add("onStep", "OnyxEclipse3-onStep", function()
    if EndFight and Director:alarm_get(1) == 1 then
        local function DecreaseSpawnRate()
            Director:alarm_set(1, Director:alarm_get(1) * 5)
        end
        Alarm.create(DecreaseSpawnRate, 5)
    end
end)

local AllowSpawn = true
Callback.add("onSecond", "OnyxEclipse3-onSecond", function(minute, second)
    if gm.bool(EclipseArtifacts[3][9]) and Director:alarm_get(1) < 0 then
        Director.points = 0
        Director:alarm_set(1, 600)
        Director.bonus_rate = 1
        Director.bonus_spawn_delay = 0
        FinishedTele = true
    end
end)

gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    for i = 1, NumArtifacts do
        if FinishedTele and self.team == 2 and currentArtifact[i][2] ~= "honor" then
            self.exp_worth = 0
        end
    end
end)

gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
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

---- eclipse 4 ----
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- increase enemy speed
    if self.team == 2 and gm.bool(EclipseArtifacts[4][9]) then
        self.pHmax_raw = self.pHmax_raw * EnemySpeed
        self.pHmax = self.pHmax * EnemySpeed
        self.attack_speed = self.attack_speed * EnemySpeed
        local actor = Instance.wrap(self)
        local skills = {actor:get_active_skill(0), actor:get_active_skill(1), actor:get_active_skill(2),
                        actor:get_active_skill(3)}
        for i, skill in ipairs(skills) do
            skill.cooldown = math.ceil(skill.cooldown * EnemySkillcdr)
        end
    end
end)

---- eclipse 5 ----
-- increase chest prices
gm.pre_script_hook(gm.constants.interactable_init_cost, function(self, other, result, args)
    if args[2].value == 0 and gm.bool(EclipseArtifacts[5][9]) then
        args[3].value = args[3].value * PriceIncrease
    end
end)

---- eclipse 7 ----
gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    -- increase enemy damage
    if gm.bool(EclipseArtifacts[7][9]) and self.team == 2.0 then
        self.damage_base = self.damage_base * EnemyStats
    end
end)

---- eclipse 6 ----
local ItemDropChance = 0
local KeepArtifact = {}
local spiritStatHandler = Item.new("OnyxEclipse", "spiritStatHandler", true)
spiritStatHandler.is_hidden = true
spiritStatHandler:toggle_loot(false)

local Load = {table.unpack(Artifact.find_all(), 1, 13)}
Load[14] = Artifact.find("ror", "cognation")
for i = 1, 14 do
    Resources.sprite_load("Onyx", Load[i].identifier, PATH .. "\\Assets\\" .. Load[i].identifier .. ".png", 1, 0, 0)
end

local Artifacts = {}
Callback.add("onGameStart", "OnyxEclipse7-onGameStart", function()
    ItemDropChance = DefaultSacrificeDropChance
    for i = 1, #currentArtifact do
        currentArtifact[i] = 0
        KeepArtifact[i] = false
        NumArtifacts = 0
        Artifacts = {}
    end
end)

gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
    if ActiveEclipse then
        for i = 1, 9 do
            eclipses[i]:set_allow_blight_spawns(true)
        end
    end

    if gm.bool(EclipseArtifacts[6][9]) then
        NumArtifacts = math.min(math.floor((Director.stages_passed + 1) / 5 + 1), 3)
        if #Artifacts < NumArtifacts then
            for i = 1, #BaseArtifacts do
                table.insert(Artifacts, BaseArtifacts[i])
            end
        end
        for i = 1, NumArtifacts do
            if currentArtifact[i] ~= nil and currentArtifact[i] ~= 0 then
                currentArtifact[i][9] = false
                player[1]:item_remove(Item.find("ror", "glassStatHandler"))
                player[1]:item_remove(Item.find("ror", "distortionStatHandler"))
                player[1]:item_remove(spiritStatHandler)
                player[1]:recalculate_stats()
                player[1]:remove_skill_override(0, 0)
                player[1]:remove_skill_override(1, 0)
                player[1]:remove_skill_override(2, 0)
                player[1]:remove_skill_override(3, 0)
            end
            ItemDropChance = DefaultSacrificeDropChance
            if not KeepArtifact[i] then
                currentArtifact[i] = 0
            else
                for o = #Artifacts, 1, -1 do
                    if Artifacts[o] == currentArtifact[i] then
                        table.remove(Artifacts, o)
                    end
                end
            end
            KeepArtifact[i] = false
        end

        -- Honor, Kin, Distortion, Spite, Glass, Sacrifice, Spirit, Origin, Prestige, Dissonance, Tempus, Cognation
        local level_subname_length = 0
        for i = 1, NumArtifacts do
            if currentArtifact[i] == 0 then
                currentArtifact[i] = Artifacts[math.random(1, #Artifacts)]
            end
            for o = #Artifacts, 1, -1 do
                if Artifacts[o] == currentArtifact[i] then
                    table.remove(Artifacts, o)
                end
            end

            -- currentArtifact[i] = Artifact.find("ror", "honor")

            local function DisplayCurrentArtifact()
                if i == 1 then
                    level_subname_length = Global.level_subname:len()
                end
                local numSpaces = (level_subname_length - Language.translate_token(currentArtifact[i][3]):len() + 1) / 2
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
                                           Language.translate_token(currentArtifact[i][3]) .. "\n" .. Spaces2 .. "<spr " ..
                                           currentArtifact[i][2] .. ">"
            end
            Alarm.create(DisplayCurrentArtifact, 1)
            if currentArtifact[i][2] ~= "distortion" and currentArtifact[i][2] ~= "spirit" and currentArtifact[i][2] ~=
                "glass" and currentArtifact[i][2] ~= "sacrifice" and currentArtifact[i][2] ~= "origin" then
                currentArtifact[i][9] = true
            end
            if currentArtifact[i][2] == "distortion" then
                local function WaitforPlayerInit()
                    if player[1]:item_stack_count(Item.find("ror", "distortionStatHandler")) == 0 then
                        player[1]:item_give(Item.find("ror", "distortionStatHandler"))
                    end
                    player[1]:add_skill_override(math.random(0, 3), 0)
                end
                Alarm.create(WaitforPlayerInit, 1)
            end
            if currentArtifact[i][2] == "spirit" then
                local function WaitforPlayerInit()
                    if player[1]:item_stack_count(spiritStatHandler) == 0 then
                        player[1]:item_give(spiritStatHandler)
                    end
                end
                Alarm.create(WaitforPlayerInit, 1)
            end
            if currentArtifact[i][2] == "glass" then
                local function WaitforPlayerInit()
                    if player[1]:item_stack_count(Item.find("ror", "glassStatHandler")) == 0 then
                        player[1]:item_give(Item.find("ror", "glassStatHandler"))
                    end
                end
                Alarm.create(WaitforPlayerInit, 1)
            end
            if currentArtifact[i][2] == "honor" then
                for i = 1, 9 do
                    eclipses[i]:set_allow_blight_spawns(false)
                end
            end
        end
    end
end)

-- Distortion
Callback.add("onMinute", "OnyxEclipse7-onMinute", function(minute, second)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "distortion" then
            player[1]:remove_skill_override(0, 0)
            player[1]:remove_skill_override(1, 0)
            player[1]:remove_skill_override(2, 0)
            player[1]:remove_skill_override(3, 0)
            player[1]:add_skill_override(math.random(0, 3), 0)
        end
    end
end)

-- Spirit
spiritStatHandler:onPostStep(function(actor, stack)
    actor.pHmax = actor.pHmax_raw - 2 * (actor.hp / actor.maxhp) + 2
end)

gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    for i = 1, NumArtifacts do
        -- Spririt
        if self.team == 2 and currentArtifact[i][2] == "spirit" then
            if Instance.wrap(self):item_stack_count(spiritStatHandler) == 0 then
                Instance.wrap(self):item_give(spiritStatHandler)
            end
        end
        -- Honor
        if self.team == 2 and currentArtifact[i][2] == "honor" then
            self.exp_worth = self.exp_worth * 2
        end
    end
end)

-- Sacrifice
Callback.add(Callback.TYPE.onKillProc, "OnyxArtifactSacrifice-onKillProc", function(victim, killer)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "sacrifice" and not FinishedTele and math.random(1, ItemDropChance) ==
            ItemDropChance then
            if math.random(1, 50) == 50 then
                Item.get_random(2):create(victim.x, victim.y)
            elseif math.random(1, 4) == 4 then
                Item.get_random(1):create(victim.x, victim.y)
            elseif math.random(1, 5) == 5 then
                Equipment.get_random():create(victim.x, victim.y)
            else
                Item.get_random(0):create(victim.x, victim.y)
            end
            ItemDropChance = ItemDropChance + 3
        end
    end
end)
gm.post_script_hook(gm.constants.interactable_init, function(self, other, result, args)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "sacrifice" then
            local function WaitforInteractableLoad(actor)
                if actor.object_index ~= gm.constants.oTeleporter and actor.object_index ~= gm.constants.oBlastdoorPanel and
                    actor.object_index ~= gm.constants.oTeleporterEpic and actor.object_index ~=
                    gm.constants.oCustomObject_pInteractable and actor.object_index ~= gm.constants.oCommand and
                    actor.object_index ~= gm.constants.oRiftChest1 and actor.object_index ~= gm.constants.oDoor and
                    actor.object_index ~= gm.constants.oMedbay and actor.object_index ~= gm.constants.oGauss and
                    actor.object_index ~= gm.constants.oUsechest and actor.object_index ~= gm.constants.oUsechestActive and
                    actor.object_index ~= gm.constants.oGaussActive and actor.object_index ~= gm.constants.oHiddenHand and
                    actor.object_index ~= gm.constants.oMedcab and actor.object_index ~= gm.constants.oChestToxin and
                    actor.object_index ~= gm.constants.oBarrel3 and actor.object_index ~= gm.constants.oMedbayActive and
                    actor.object_index ~= gm.constants.oCommandFinal and actor.object_index ~=
                    gm.constants.oCustomObject_pInteractableCrate and actor.object_index ~=
                    gm.constants.oCustomObject_pMapObjects and actor.object_index ~= gm.constants.oRoboBuddyBroken and
                    actor.object_index ~= gm.constants.oDroneRecycler and actor.object_index ~=
                    gm.constants.oDroneUpgrader then
                    actor:destroy()
                end
            end
            Alarm.create(WaitforInteractableLoad, 1, Instance.wrap(self))
        end
    end
end)

-- Cognation
Callback.add("onEliteInit", "OnyxArtifactCognant-onEliteInit", function(actor)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "cognation" and actor.elite_type == 7 then
            local function NerfCognants()
                actor.maxhp = actor.maxhp / 2
                actor.hp = actor.hp / 2
                actor.damage_base = actor.damage_base / 2
            end
            Alarm.create(NerfCognants, 2)
        end
    end
end)

-- Prestige
gm.post_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "mountain" and self.object_index == gm.constants.oShrineMountainS then
            local function DoubleMountains()
                if Director.teleporter_active == 0 then
                    Director.mountain = Director.mountain - 1
                    if Director.mountain <= 0 then
                        Director.mountain = 1
                    else
                        Director.mountain = Director.mountain * 2
                    end
                    KeepArtifact[i] = true
                end
            end
            Alarm.create(DoubleMountains, 1)
        end

        -- Honor
        if currentArtifact[i][2] == "honor" and
            (self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
                self.object_index == gm.constants.oBlastdoorPanel) then
            self.maxtime = 1
        end
    end
end)

-- Origin
Callback.add("onMinute", "OnyxArtifactOrigin-onMinute", function(minute, second)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "origin" and minute % 5 == 0 then
            local Invasion = Object.find("ror", "ImpPortal")
            for i = 1, minute / 5 do
                Invasion:create(player[1].x, player[1].y)
            end
        end
    end
end)

---- eclipse 8 ----
-- apply curse
local CurseIndex = 0

Callback.add("onStageStart", "OnyxEclipse8-onStageStart", function()
    -- reset ally curse when entering a new stage
    allies = Instance.find_all(gm.constants.pFriend)
    for i, ally in ipairs(allies) do
        for i = 0, CurseIndex do
            Curse.remove(ally.value, "OnyxEclipse-PermaDamage" .. i)
        end
    end
    CurseIndex = 0
end)

gm.post_script_hook(gm.constants.actor_proc_on_damage, function(self, other, result, args)
    if gm.bool(EclipseArtifacts[8][9]) and self.team == 1 then
        Curse.apply(self, "OnyxEclipse-PermaDamage" .. CurseIndex, 0.01 * 40 * args[1].value.damage_true / self.maxhp)
        CurseIndex = CurseIndex + 1
    end
end)
