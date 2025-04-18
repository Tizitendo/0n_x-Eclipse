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
local KilledBoss = false
local EndFight = false
local NumArtifacts = 0
local currentArtifact = {}
local BaseArtifacts = {}
local EclipseArtifacts = {}
local AltEclipseArtifacts = {}
local ActiveEclipse = false
local artiSelected = {}
local UpdatePacket = Packet.new()
local Interactables = {gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5, gm.constants.oChestHealing1,
                       gm.constants.oChestDamage1, gm.constants.oChestUtility1, gm.constants.oChestHealing2,
                       gm.constants.oChestDamage2, gm.constants.oChestUtility2, gm.constants.oGunchest,
                       gm.constants.oChest4, gm.constants.oEfChestRain, gm.constants.oShop1, gm.constants.oShop2,
                       gm.constants.oActivator, gm.constants.oBarrelEquipment, gm.constants.oShopEquipment,
                       gm.constants.oTeleporter, gm.constants.oBlastdoorPanel, gm.constants.oShrine1,
                       gm.constants.oShrine2, gm.constants.oShrine3, gm.constants.oShrine4, gm.constants.oShrine5}

-- Parameters
local TeleColor = 190540540
local BuffedTeleColor = Color.from_hex(0xb53f80)
local TeleRadius = 700
local BuffedTeleRadius = 350
local PriceIncrease = 1.3
local BuffedPriceIncrease = 1.4
local EnemyMoveSpeed = 1.15
local BuffedEnemyMoveSpeed = 1.2
local EnemyAttackSpeed = 1.15
local BuffedEnemyAttackSpeed = 1.2
local EnemyCooldowns = 0.6
local BuffedEnemyCooldowns = 0.5
local DefaultSacrificeDropChance = 15
local Healreduction = 0.6
local BaseSeed = os.time()

for i = 1, 9 do
    eclipses[i] = Difficulty.find("ror", "eclipse" .. i)
end

for k, v in ipairs(Global.class_artifact) do
    if v ~= 0 and v[1] == "OnyxEclipse" then
        table.insert(EclipseArtifacts, v)
    end
    if v ~= 0 and v[1] == "OnyxAltEclipse" then
        AltEclipseArtifacts[tonumber(string.sub(v[2], -1))] = v
    end
end

local boar_card = Monster_Card.new(NAMESPACE, "BoarM")
boar_card.object_id = Object.find("ror", "BoarM")
boar_card.spawn_cost = 20
boar_card.spawn_type = Monster_Card.SPAWN_TYPE.classic
boar_card.can_be_blighted = false
local bigboar_card = Monster_Card.new(NAMESPACE, "BoarR")
bigboar_card.object_id = Object.find("ror", "BoarR")
bigboar_card.spawn_cost = 150
bigboar_card.spawn_type = Monster_Card.SPAWN_TYPE.classic
bigboar_card.can_be_blighted = false
local beach = Stage.find("ror-boarBeach")

Callback.add("onGameStart", "OnyxEclipseGen-onGameStart", function()
    for o = 1, 9 do
        artiSelected[o] = false
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
        if ActiveEclipse and (AltEclipseArtifacts[i] == nil or not AltEclipseArtifacts[i][9]) then
            EclipseArtifacts[i][9] = true
        end
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
                (not gm.bool(BaseArtifacts[i][9]) or BaseArtifacts[i][1] == "OnyxEclipse" or BaseArtifacts[i][1] ==
                    "OnyxAltEclipse") then
                table.remove(BaseArtifacts, i)
            end
        end
    end

    for i = 9, 1, -1 do
        if ((AltEclipseArtifacts[i] ~= nil and AltEclipseArtifacts[i][9]) or EclipseArtifacts[i][9]) then
            ActiveEclipse = true
        end
    end

    -- add little boars to boar beach when eclipse is active
    local beach_cards = List.wrap(beach.spawn_enemies)
    if ActiveEclipse then
        for i = #beach_cards, 1, -1 do
            if Monster_Card.wrap(beach_cards[i]) == boar_card then
                return
            end
        end
        beach:add_monster(boar_card)
        beach:add_monster(boar_card)
        beach:add_monster(bigboar_card)
        -- beach:add_monster(bigboar_card)
    else
        for i = #beach_cards, 1, -1 do
            if Monster_Card.wrap(beach_cards[i]) == boar_card then
                table.remove(List.wrap(beach.spawn_enemies), i)
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
        KilledBoss = false
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
    Teleporter = nil

    if gm.bool(EclipseArtifacts[1][9]) then
        Director.points = Director.points + (40 + 10 * Director.minute_current)
        if gm.bool(AltEclipseArtifacts[5][9]) then
            Director.points = Director.points + (40 + 10 * Director.minute_current)
        end
        ExtraCreditsEnabled = 60
    end

    if gm.bool(AltEclipseArtifacts[1][9]) then
        local allies = Instance.find_all(gm.constants.pFriend)
        for i = 1, #allies do
            if gm.bool(AltEclipseArtifacts[5][9]) then
                allies[i].hp = allies[i].hp * 0.4
            else
                allies[i].hp = allies[i].hp * 0.5
            end
        end
    end
end)
gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    if gm.bool(AltEclipseArtifacts[1][9]) and result.value ~= nil and result.value.hp ~= nil and result.value.team == 1 and
        result.value.object_index ~= gm.constants.oP then
        if gm.bool(AltEclipseArtifacts[5][9]) then
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
        Director.points = Director.points + (4 + 1.3 * minute)
        ExtraCreditsEnabled = ExtraCreditsEnabled - 1
    end

    if Teleporter and
        (Teleporter.object_index == gm.constants.oTeleporter or Teleporter.object_index == gm.constants.oTeleporterEpic) and
        (Teleporter.time == Teleporter.maxtime - 1 or Teleporter.time == Teleporter.maxtime - 2) then
        Director.points = Director.points - (2 + 1.7 * minute) * 0.5
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
                    else
                        if AltEclipseArtifacts[5][9] then
                            if math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >= BuffedTeleRadius then
                                Teleporter.time = Teleporter.time - (1 / alivePlayers) * 0.3
                            else
                                Teleporter.time = Teleporter.time + (1 / alivePlayers) * 0.3
                            end
                        end
                    end
                end
            end

            -- don't let teleporter finish unless boss is killed
            if Teleporter.object_index == gm.constants.oTeleporter or Teleporter.object_index ==
                gm.constants.oTeleporterEpic then
                if KilledBoss and Teleporter.time >= Teleporter.maxtime - 3 then
                    Teleporter.time = Teleporter.time + 2
                elseif Teleporter.time >= Teleporter.maxtime - 2 then
                    Teleporter.time = Teleporter.time - 1
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

gm.post_script_hook(gm.constants.update_boss_party_active_gml_Object_oDirectorControl_Create_0,
    function(self, other, result, args)
        KilledBoss = true
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
            if AltEclipseArtifacts[5][9] then
                gm.draw_circle_colour(Teleporter.x, Teleporter.y, BuffedTeleRadius * RadiusMul, BuffedTeleColor, BuffedTeleColor, true)
            end
        end
        if Teleporter.active ~= 1 and RadiusMul >= 1 and RadiusMul < 1.1 then
            RadiusMul = RadiusMul * 1.01
            gm.draw_set_alpha(0.8 - math.fmod(RadiusMul, 0.1))
            gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * RadiusMul, TeleColor, TeleColor, true)
            if AltEclipseArtifacts[5][9] then
                gm.draw_circle_colour(Teleporter.x, Teleporter.y, BuffedTeleRadius * RadiusMul, BuffedTeleColor, BuffedTeleColor, true)
            end
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
                    gm.draw_circle_colour(Teleporter.x, Teleporter.y, TeleRadius * Tele_circles[i], TeleColor, TeleColor, true)
                    if AltEclipseArtifacts[5][9] then
                        gm.draw_circle_colour(Teleporter.x, Teleporter.y, BuffedTeleRadius * Tele_circles[i], BuffedTeleColor, BuffedTeleColor, true)
                    end
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
            if Director.teleporter_active == 1 and math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >= TeleRadius then
                self.exp_worth = self.exp_worth * (1 - 0.5 / alivePlayers)
            end
        end
    end
end)

-- Eclipse3
Callback.add("onStep", "OnyxEclipse3-onStep", function()
    if Director:alarm_get(1) == 1 then
        if EndFight then
            local function DecreaseSpawnRate()
                Director:alarm_set(1, Director:alarm_get(1) * 5)
            end
            Alarm.create(DecreaseSpawnRate, 5)
        end
    end
end)

local AllowSpawn = true
Callback.add("onSecond", "OnyxEclipse3-onSecond", function(minute, second)
    if gm.bool(EclipseArtifacts[3][9]) and Director:alarm_get(1) < 0 then
        Director.points = 0
        Director:alarm_set(1, 600)
        FinishedTele = true
        if gm._mod_net_isOnline() and gm._mod_net_isHost() then
            local msg = UpdatePacket:message_begin()
            msg:write_byte(FinishedTele)
            msg:send_to_all()
        end
    end
end)

UpdatePacket:onReceived(function(msg)
    FinishedTele = gm.bool(msg:read_byte())
end)

gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    if NumArtifacts == 0 then
        if FinishedTele and self.team == 2 then
            self.exp_worth = 0
        end
    else
        for i = 1, NumArtifacts do
            if FinishedTele and self.team == 2 and currentArtifact[i][2] ~= "honor" then
                self.exp_worth = 0
            end
        end
    end
end)

gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    if self.object_index == gm.constants.oCommand then
        -- reduce enemy spawning after starting provi fight
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
    if self.team == 2 and gm.bool(EclipseArtifacts[4][9]) and self.object_index ~= gm.constants.oGolemT and
        self.object_index ~= gm.constants.imp then
        if gm.bool(AltEclipseArtifacts[5][9]) then
            self.pHmax_raw = self.pHmax_raw * BuffedEnemyMoveSpeed
            self.pHmax = self.pHmax * BuffedEnemyMoveSpeed
            self.attack_speed = self.attack_speed * BuffedEnemyAttackSpeed
        else
            self.pHmax_raw = self.pHmax_raw * EnemyMoveSpeed
            self.pHmax = self.pHmax * EnemyMoveSpeed
            self.attack_speed = self.attack_speed * EnemyAttackSpeed
        end
    end
end)

---- eclipse 5 ----
gm.pre_script_hook(gm.constants.actor_heal_raw, function(self, other, result, args)
    if gm.bool(EclipseArtifacts[5][9]) and args[1].value.team == 1 then
        if gm.bool(AltEclipseArtifacts[5][9]) then
            args[2].value = args[2].value * Healreduction
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
        if artifact ~= 0 and artifact[2] ~= 0 and AltEclipseArtifacts[o] and  artifact[6] == AltEclipseArtifacts[o][6] then
            AltArtiIds[o] = i - 1
        end
    end
end
gm.post_script_hook(gm.constants.anon_gml_Object_oSelectMenu_Create_0_200742116_gml_Object_oSelectMenu_Create_0, function(self, other, result, args)
    for i = 1, 9 do
        if args[1].value == AltArtiIds[i] then
            artiSelected[i] = not artiSelected[i]
        end
    end

    if artiSelected[5] then
        self.customize_sections[1].height = 200
        for i = 1, 9 do
            if artiSelected[i] then
                EclipseArtifacts[i][5] = "artifactbuffed.alteclipse"..i..".description"
            else
                EclipseArtifacts[i][5] = "artifactbuffed.eclipse"..i..".description"
            end
        end
    else
        for i = 1, 9 do
            if artiSelected[i] then
                EclipseArtifacts[i][5] = "artifact.alteclipse"..i..".description"
            else
                EclipseArtifacts[i][5] = "artifact.eclipse"..i..".description"
            end
        end
    end

    for i = 1, 9 do
        eclipses[i].token_description = "( 1 )  "
        for o = 1, i do
            eclipses[i].token_description = eclipses[i].token_description ..
                                                Language.translate_token(EclipseArtifacts[o][5])

            if i ~= o then
                eclipses[i].token_description = eclipses[i].token_description .. "\n( " .. (o + 1) .. " )  "
            end
        end
    end
end)

---- eclipse 6 ----
-- increase chest prices
gm.pre_script_hook(gm.constants.interactable_init_cost, function(self, other, result, args)
    if args[2].value == 0 and gm.bool(EclipseArtifacts[6][9]) and type(args[1].value) ~= "number" and
    (gm.object_get_parent(args[1].value.object_index) == gm.constants.pInteractableChest or 
    args[1].value.object_index == gm.constantsoChest4 or 
    gm.object_get_parent(args[1].value.object_index) == gm.constants.pInteractableTriShop) then
        if gm.bool(AltEclipseArtifacts[5][9]) then
            args[3].value = args[3].value * BuffedPriceIncrease
        else
            args[3].value = args[3].value * PriceIncrease
        end
    end
end)
-- Alt --
local ChestRemoveCount = 0
local ChestPacket = Packet.new()
Callback.add("onGameStart", "OnyxAltEclipse5-onGameStart", function()
    ChestRemoveCount = 0
end)
local function EmptyChest(minute)
    local player = Player.get_client()
    local Chests = Instance.find_all(Instance.chests)

    local function compareDistance(a, b)
        return a:distance_to_point(player.x, player.y) < b:distance_to_point(player.x, player.y)
    end
    table.sort(Chests, compareDistance)
    
    while ChestRemoveCount > 0 and #Chests > 0 do
        if Chests[1].active <= 0 then
            Chests[1].active = 1
            Chests[1].open_delay = 0
            ChestRemoveCount = ChestRemoveCount - 1
        end
        if gm._mod_net_isOnline() then
            local msg = ChestPacket:message_begin()
            msg:write_instance(Chests[1])
            msg:send_to_all()
        end
        table.remove(Chests, 1)
    end
end
ChestPacket:onReceived(function(msg)
    local chest = msg:read_instance()
    chest.active = 1
    chest.open_delay = 0
end)

Callback.add("onStageStart", "OnyxAltEclipse5-onStageStart", function()
    if gm.bool(AltEclipseArtifacts[6][9]) then
        if gm._mod_net_isHost() then
        Alarm.create(EmptyChest, 1, 0)
        end
    end
end)
Callback.add("onMinute", "OnyxAltEclipse5-onMinute", function(minute, second)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "sacrifice" then
            return;
        end
    end
    if gm.bool(AltEclipseArtifacts[6][9]) then
        if gm.bool(AltEclipseArtifacts[5][9]) then
            if minute % 4 == 0 then
                ChestRemoveCount = 1
            end
        else
            if minute % 5 == 0 then
                ChestRemoveCount = 1
            end
        end
    end
    
    if gm._mod_net_isHost() then
        EmptyChest(minute)
    end
end)

---- eclipse 7 ----
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- decrease enemy attack cooldown
    if self.team == 2 and gm.bool(EclipseArtifacts[7][9]) and self.object_index ~= gm.constants.oImp then
        if gm.bool(AltEclipseArtifacts[5][9]) then
            local actor = Instance.wrap(self)
            local skills = {actor:get_active_skill(0), actor:get_active_skill(1), actor:get_active_skill(2),
                            actor:get_active_skill(3)}
            for i, skill in ipairs(skills) do
                skill.cooldown = math.ceil(skill.cooldown * BuffedEnemyCooldowns)
            end
        else
            local actor = Instance.wrap(self)
            local skills = {actor:get_active_skill(0), actor:get_active_skill(1), actor:get_active_skill(2),
                            actor:get_active_skill(3)}
            for i, skill in ipairs(skills) do
                skill.cooldown = math.ceil(skill.cooldown * EnemyCooldowns)
            end
        end
    end
end)
---- Alt ----
-- increase explosion height
gm.pre_script_hook(gm.constants.fire_explosion, function(self, other, result, args)
    if gm.bool(AltEclipseArtifacts[7][9]) and self.team == 2 and self.object_index ~= gm.constants.oSpitter then
        if gm.bool(AltEclipseArtifacts[5][9]) then
            args[9].value = args[9].value + math.sqrt(args[9].value) * 1.1
        else
            args[9].value = args[9].value + math.sqrt(args[9].value)
        end
    end
end)
-- add more bullet tracers
gm.pre_script_hook(gm.constants.fire_bullet, function(self, other, result, args)
    if gm.bool(AltEclipseArtifacts[7][9]) and self and self.team == 2 and other ~= nil and self.object_index ~= gm.constants.oSpitter then
        args[5].value = args[5].value * 0.5
        self:fire_bullet(args[1].value, args[2].value, args[3].value - 10, args[4].value, args[5].value,
            args[6].value, args[7].value, args[8].value, args[9].value, args[10].value, args[11].value)
    end
end)

---- eclipse 8 ----
-- apply curse
local CurseIndex = 0
local damagePacket = Packet.new()

Callback.add("onStageStart", "OnyxEclipse8-onStageStart", function()
    -- reset ally curse when entering a new stage
    local allies = Instance.find_all(gm.constants.pFriend)
    for i, ally in ipairs(allies) do
        local allydata = ally:get_data()
        if allydata.curseId then
            if gm.bool(AltEclipseArtifacts[5][9]) then
                allydata.curseStacks = math.floor(allydata.curseStacks * 0.25)
                Curse.apply(ally.value, "OnyxEclipse-PermaDamage" .. allydata.curseId, 1 - 1/(1 + 0.01*allydata.curseStacks))
            else
                allydata.curseStacks = 0
                Curse.remove(ally.value, "OnyxEclipse-PermaDamage" .. allydata.curseId)
            end
        end
        -- CurseIndex = 0
    end
end)

-- Callback.add(Callback.TYPE.onSecond, NAMESPACE.."eclipse8-onSecond", function(minute, second)
--     if gm.bool(AltEclipseArtifacts[5][9]) and second % 20 == 0 then
--         local allies = Instance.find_all(gm.constants.pFriend)
--         for i, ally in ipairs(allies) do
--             local allydata = ally:get_data()
--             if allydata.curseId then
--                 allydata.curseStacks = math.max(allydata.curseStacks -1, 0)
--                 Curse.apply(ally.value, "OnyxEclipse-PermaDamage" .. allydata.curseId, 1 - 1/(1 + 0.01*allydata.curseStacks))
--             end
--         end
--     end
-- end)

local function apply_Curse(player, damage)
    if gm.bool(EclipseArtifacts[8][9]) and player.team == 1 then
        local playerdata = player:get_data()
        if not playerdata.curseId then
            playerdata.curseId = CurseIndex
            playerdata.curseStacks = 0
            CurseIndex = CurseIndex + 1
        end

        if damage > Curse.get_effective(player) * 0.05 then
            playerdata.curseStacks = playerdata.curseStacks + math.floor(30 * damage / Curse.get_effective(player))
            Curse.apply(player, "OnyxEclipse-PermaDamage" .. playerdata.curseId, 1 - 1/(1 + 0.01*playerdata.curseStacks))
        end

        if player.hp <= 0 then
            playerdata.curseStacks = 0
            Curse.remove(player, "OnyxEclipse-PermaDamage" .. playerdata.curseId)
        end
    end
end

gm.post_script_hook(gm.constants.damage_inflict_raw, function(self, other, result, args)
    apply_Curse(Instance.wrap(args[1].value), args[2].value.damage)
end)

---- Alt ----
local ItemDropChance = 0
local KeepArtifact = {}
local spiritStatHandler = Item.new("OnyxEclipse", "spiritStatHandler", true)
spiritStatHandler.is_hidden = true
spiritStatHandler:toggle_loot(false)
local SeedPacket = Packet.new()

local Artifacts = {}
Callback.add("onGameStart", "OnyxAltEclipse8-onGameStart", function()
    ItemDropChance = DefaultSacrificeDropChance
    for i = 1, #currentArtifact do
        currentArtifact[i] = 0
        KeepArtifact[i] = false
        NumArtifacts = 0
        Artifacts = {}
    end
end)

gm.post_script_hook(gm.constants.net_refresh_players, function(self, other, result, args)
    if gm._mod_net_isHost() and not gm._mod_game_ingame() then
        BaseSeed = os.time()
        math.randomseed(BaseSeed)
        local msg = SeedPacket:message_begin()
        msg:write_uint(BaseSeed)
        msg:send_to_all()
    end
end)

SeedPacket:onReceived(function(msg)
    BaseSeed = msg:read_uint()
    math.randomseed(BaseSeed)
end)

local ArtifactScene = false
gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
    -- Helper.log_hook(self, other, result, args)
    -- log.warning(self.object_index)
    -- log.warning(other)
    if self == nil or self.object_index == gm.constants.oDirectorControl then
        -- ArtifactScene = true
        -- return false
    end
end)

local hest = Resources.sprite_load("Onyx", "ArtifactBackground", PATH .. "SelectArtifactBackground.png", 1, 0, 0)
local Cursor = Resources.sprite_load("Onyx", "Cursor", PATH .. "Cursor.png", 1, 5, 4)
local SpriteScale = 1
local TileScale = 2
local CursorX = 0
local CursorY = 0
local ArtifactShowTimer = 0
local Pausemenu = Instance.find(Object.find("ror", "PauseMenu"))
local lastanimate = 0

gm.pre_code_execute("gml_Object_oHUD_Draw_73", function(self, other)
    if ArtifactScene then
        return false
    end
end)

gm.post_script_hook(gm.constants._ui_draw_button, function(self, other, result, args)
    -- Helper.log_hook(self, other, result, args)
    -- log.warning(gm.is_struct(args[1].value))
end)

gm.post_code_execute("gml_Object_oInit_Draw_64", function(self, other)
    -- gm._ui_draw_button_overlay(hest, 2070, 1176, -44, 1216, -16, 0, nil)
    -- local hi = gm.new_struct()
    -- hi.was_updated = true
    -- hi.draw_hover

    local ViewWidth = gm.display_get_gui_width()
    local ViewHeight = gm.display_get_gui_height()

    if ArtifactShowTimer > 0 and lastanimate == Pausemenu.pause_animate then
        ArtifactShowTimer = ArtifactShowTimer - 1
        -- NumArtifacts = 1
        for i = 1, NumArtifacts do
            -- gm.draw_sprite_ext(currentArtifact[i][7], 0, ViewWidth / 2 - SpriteScale * 5, ViewHeight / 2 + 83 *
            --     SpriteScale * (1 + (i - 1) * 0.65) - 50 + SpriteScale * (NumArtifacts - 1) * 25, SpriteScale,
            --     SpriteScale, 0, Color.WHITE, ArtifactShowTimer / 20)
            gm.draw_sprite_ext(currentArtifact[i][7], 0, ViewWidth / 2 - SpriteScale * 5, ViewHeight * 0.5 - 5 + 60 *
                SpriteScale * (1 + (i - 1) * 0.95) + SpriteScale * (NumArtifacts - 1) * 25, SpriteScale, SpriteScale, 0,
                Color.WHITE, ArtifactShowTimer / 20)
        end
        if not gm._mod_game_ingame() then
            ArtifactShowTimer = 0
        end
    end
    lastanimate = Pausemenu.pause_animate

    -- if ArtifactScene or true then
    --     gm.draw_rectangle_colour(0, 0, ViewWidth, ViewHeight, 0, 0, 0, 0, false);
    --     local TilePosX = 0
    --     local TilePosY = ViewHeight / 2 - 100

    --     for i = 0, 2 do
    --         TilePosX = ViewWidth / 2 - 69 * TileScale + 50 * i * TileScale
    --         gm.draw_sprite_ext(hest, 0, TilePosX, TilePosY, TileScale, TileScale, 0, Color.WHITE, 1)
    --         if CursorX > TilePosX and CursorX < TilePosX + 38 * TileScale and CursorY > TilePosY and CursorY < TilePosY +
    --             38 * TileScale then
    --             gm.draw_sprite_ext(Cursor, 0, TilePosX, TilePosY, SpriteScale, SpriteScale, 0, Color.WHITE, 1)
    --         end
    --     end
    -- end
end)

-- gui.add_always_draw_imgui(function()
--     CursorX, CursorY = ImGui.GetMousePos()
-- end)

gm.pre_script_hook(gm.constants.prefs_set_hud_scale, function(self, other, result, args)
    SpriteScale = args[1].value
    TileScale = args[1].value * 2
end)

gm.post_script_hook(gm.constants.stage_load_room, function(self, other, result, args)
    SpriteScale = gm.prefs_get_hud_scale()
    TileScale = SpriteScale * 2
end)

local function ArtifactNewLevel(stage)
    BaseSeed = BaseSeed + 100
    if ActiveEclipse then
        for i = 1, 9 do
            eclipses[i]:set_allow_blight_spawns(true)
        end
    end

    if gm.bool(AltEclipseArtifacts[8][9]) then
        NumArtifacts = math.min(math.floor((Director.stages_passed + 1) / 5 + 1), 3)
        -- NumArtifacts = 3
        -- log.warning(NumArtifacts)
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
                math.randomseed(BaseSeed + i)
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
                Global.level_subname = Global.level_subname .. "\n" .. Spaces ..
                                           Language.translate_token(currentArtifact[i][3]) .. "\n\n"
                ArtifactShowTimer = 240
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
                    math.randomseed(BaseSeed)
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

            if currentArtifact[i][2] == "cognation" then
                if stage then
                    local Stage = Stage.wrap(stage)
                    Stage.interactable_spawn_points = Stage.interactable_spawn_points * 1.2
                    local function RevertStageCredits(Stage)
                        Stage.interactable_spawn_points = Stage.interactable_spawn_points / 1.2
                    end
                    Alarm.create(RevertStageCredits, 1, Stage)
                end
            end
        end
    end
end

Callback.add(Callback.TYPE.onStageStart, "OnyxAltEclipse8-onStageStart", function()
    if not gm._mod_net_isHost() then
        ArtifactNewLevel()
    end
end)

-- gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
gm.pre_script_hook(gm.constants.stage_goto, function(self, other, result, args)
    if gm._mod_net_isHost() then
        ArtifactNewLevel(args[1].value)
    end
end)

-- Distortion
Callback.add("onMinute", "OnyxAltEclipse8-onMinute", function(minute, second)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "distortion" then
            player[1]:remove_skill_override(0, 0)
            player[1]:remove_skill_override(1, 0)
            player[1]:remove_skill_override(2, 0)
            player[1]:remove_skill_override(3, 0)
            math.randomseed(BaseSeed + minute)
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
                        Director.mountain = 2
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
local timeMinute = 0
Callback.add("onMinute", "OnyxArtifactOrigin-onMinute", function(minute, second)
    if NumArtifacts == 0 then
        timeMinute = 0
    end
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "origin" and minute % 5 == 0 then
            timeMinute = minute
            local Invasion = Object.find("ror", "ImpPortal")
            for i = 1, 1 + minute / 10 do
                Invasion:create(player[1].x, player[1].y)
            end
        end
    end
end)
gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    if self ~= nil and self.object_index == gm.constants.oImpGS then
        self.damage_base = self.damage_base * (1 + timeMinute / 10)
    end
end)

-- Tempus
gm.post_script_hook(gm.constants.item_give, function(self, other, result, args)
    for i = 1, NumArtifacts do
        if currentArtifact[i][2] == "temporary" and args[3].value == 3 then
            gm.item_give_internal(args[1].value, args[2].value, 2, args[4].value)
        end
    end
end)

---- eclipse 9 ----
local ImgEclipse9 = Resources.sprite_load("Onyx", "Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13)
local ImgOriginalTyphoon = Resources.sprite_load("Onyx", "Eclipse9Typhoon", PATH .. "DifficultyTyphoon.png", 5, 13, 13)
local ImgEclipse9_2x =
    Resources.sprite_load("Onyx", "Eclipse9Typhoon_2x", PATH .. "DifficultyTyphoon_2x.png", 4, 20, 19)
Callback.add(Callback.TYPE.onGameStart, "OnyxEclipse9-onGameStart", function()
    if gm.bool(EclipseArtifacts[9][9]) then
        local Eclipse9 = Difficulty.find("ssr", "typhoon")
        GM._mod_game_setDifficulty(Eclipse9)
        Eclipse9:set_sprite(ImgEclipse9, ImgEclipse9_2x)
        -- Eclipse9:set_sprite(Resources.sprite_load("Onyx", "Eclipse9Typhoon", PATH .. "DifficultyTyphoon.png", 5, 13, 13),
        -- Resources.sprite_load("Onyx", "Eclipse9Typhoon_2x", PATH .. "DifficultyTyphoon_2x.png", 4, 20, 19))
    end
end)

Callback.add(Callback.TYPE.onGameEnd, "OnyxEclipse9-onGameEnd", function()
    local Eclipse9 = Difficulty.find("ssr", "typhoon")
    if Eclipse9 then
        Eclipse9:set_sprite(ImgOriginalTyphoon, ImgEclipse9_2x)
    end
end)
