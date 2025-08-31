Curse = mods["Klehrik-CurseHelper"].setup()
local DefaultSacrificeDropChance = 15
local BaseArtifacts = {}

-- apply curse
local CurseIndex = 0
local damagePacket = Packet.new()

Callback.add("onStageStart", "OnyxEclipse8-onStageStart", function()
    -- reset ally curse when entering a new stage
    local allies = Instance.find_all(gm.constants.pFriend)
    for i, ally in ipairs(allies) do
        local allydata = ally:get_data()
        if allydata.curseId then
            if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
                allydata.curseStacks = math.floor(allydata.curseStacks * 0.25)
                Curse.apply(ally.value, "OnyxEclipse-PermaDamage" .. allydata.curseId, 1 - 1/(1 + 0.01*allydata.curseStacks))
            else
                allydata.curseStacks = 0
                Curse.remove(ally.value, "OnyxEclipse-PermaDamage" .. allydata.curseId)
            end
        end
    end
end)

local function apply_Curse(player, damage)
    if gm.bool(ECLIPSEARTIFACTS[8].active) and player.team == 1 then
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
    for i = 1, #CURRENTARTIFACT do
        CURRENTARTIFACT[i] = 0
        KeepArtifact[i] = false
        NUMARTIFACTS = 0
        Artifacts = {}
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
end)

gm.post_script_hook(gm.constants.net_refresh_players, function(self, other, result, args)
    if gm._mod_net_isHost() and not gm._mod_game_ingame() then
        math.randomseed(BASESEED)
        local msg = SeedPacket:message_begin()
        msg:write_uint(BASESEED)
        msg:send_to_all()
    end
end)

SeedPacket:onReceived(function(msg)
    BASESEED = msg:read_uint()
    math.randomseed(BASESEED)
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
        -- NUMARTIFACTS = 1
        for i = 1, NUMARTIFACTS do
            -- gm.draw_sprite_ext(CURRENTARTIFACT[i][7], 0, ViewWidth / 2 - SpriteScale * 5, ViewHeight / 2 + 83 *
            --     SpriteScale * (1 + (i - 1) * 0.65) - 50 + SpriteScale * (NUMARTIFACTS - 1) * 25, SpriteScale,
            --     SpriteScale, 0, Color.WHITE, ArtifactShowTimer / 20)
            gm.draw_sprite_ext(CURRENTARTIFACT[i][7], 0, ViewWidth / 2 - SpriteScale * 5, ViewHeight * 0.5 - 5 + 60 *
                SpriteScale * (1 + (i - 1) * 0.95) + SpriteScale * (NUMARTIFACTS - 1) * 25, SpriteScale, SpriteScale, 0,
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
    BASESEED = BASESEED + 100
    if ACTIVEECLIPSE then
        for i = 1, 9 do
            ECLIPSEDIFFICULTIES[i]:set_allow_blight_spawns(true)
        end
    end

    if gm.bool(ALTECLIPSEARTIFACTS[8].active) then
        NUMARTIFACTS = math.min(math.floor((Director.stages_passed + 1) / 5 + 1), 3)
        -- NUMARTIFACTS = 3
        -- log.warning(NUMARTIFACTS)
        if #Artifacts < NUMARTIFACTS then
            for i = 1, #BaseArtifacts do
                table.insert(Artifacts, BaseArtifacts[i])
            end
        end
        for i = 1, NUMARTIFACTS do
            if CURRENTARTIFACT[i] ~= nil and CURRENTARTIFACT[i] ~= 0 then
                CURRENTARTIFACT[i][9] = false
                PLAYER[1]:item_remove(Item.find("ror", "glassStatHandler"))
                PLAYER[1]:item_remove(Item.find("ror", "distortionStatHandler"))
                PLAYER[1]:item_remove(spiritStatHandler)
                PLAYER[1]:recalculate_stats()
                PLAYER[1]:remove_skill_override(0, 0)
                PLAYER[1]:remove_skill_override(1, 0)
                PLAYER[1]:remove_skill_override(2, 0)
                PLAYER[1]:remove_skill_override(3, 0)
            end
            ItemDropChance = DefaultSacrificeDropChance
            if not KeepArtifact[i] then
                CURRENTARTIFACT[i] = 0
            else
                for o = #Artifacts, 1, -1 do
                    if Artifacts[o] == CURRENTARTIFACT[i] then
                        table.remove(Artifacts, o)
                    end
                end
            end
            KeepArtifact[i] = false
        end

        -- Honor, Kin, Distortion, Spite, Glass, Sacrifice, Spirit, Origin, Prestige, Dissonance, Tempus, Cognation
        local level_subname_length = 0
        for i = 1, NUMARTIFACTS do
            if CURRENTARTIFACT[i] == 0 then
                math.randomseed(BASESEED + i)
                CURRENTARTIFACT[i] = Artifacts[math.random(1, #Artifacts)]
            end
            for o = #Artifacts, 1, -1 do
                if Artifacts[o] == CURRENTARTIFACT[i] then
                    table.remove(Artifacts, o)
                end
            end

            -- CURRENTARTIFACT[i] = Artifact.find("ror", "honor")

            local function DisplayCurrentArtifact()
                if i == 1 then
                    level_subname_length = Global.level_subname:len()
                end
                local numSpaces = (level_subname_length - Language.translate_token(CURRENTARTIFACT[i][3]):len() + 1) / 2
                local Spaces = ""
                for o = 1, numSpaces do
                    Spaces = Spaces .. " "
                end
                Global.level_subname = Global.level_subname .. "\n" .. Spaces ..
                                           Language.translate_token(CURRENTARTIFACT[i][3]) .. "\n\n"
                ArtifactShowTimer = 240
            end
            Alarm.create(DisplayCurrentArtifact, 1)
            if CURRENTARTIFACT[i][2] ~= "distortion" and CURRENTARTIFACT[i][2] ~= "spirit" and CURRENTARTIFACT[i][2] ~=
                "glass" and CURRENTARTIFACT[i][2] ~= "sacrifice" and CURRENTARTIFACT[i][2] ~= "origin" then
                    CURRENTARTIFACT[i][9] = true
            end
            if CURRENTARTIFACT[i][2] == "distortion" then
                local function WaitforPlayerInit()
                    if PLAYER[1]:item_stack_count(Item.find("ror", "distortionStatHandler")) == 0 then
                        PLAYER[1]:item_give(Item.find("ror", "distortionStatHandler"))
                    end
                    math.randomseed(BASESEED)
                    PLAYER[1]:add_skill_override(math.random(0, 3), 0)
                end
                Alarm.create(WaitforPlayerInit, 1)
            end
            if CURRENTARTIFACT[i][2] == "spirit" then
                local function WaitforPlayerInit()
                    if PLAYER[1]:item_stack_count(spiritStatHandler) == 0 then
                        PLAYER[1]:item_give(spiritStatHandler)
                    end
                end
                Alarm.create(WaitforPlayerInit, 1)
            end
            if CURRENTARTIFACT[i][2] == "glass" then
                local function WaitforPlayerInit()
                    if PLAYER[1]:item_stack_count(Item.find("ror", "glassStatHandler")) == 0 then
                        PLAYER[1]:item_give(Item.find("ror", "glassStatHandler"))
                    end
                end
                Alarm.create(WaitforPlayerInit, 1)
            end
            if CURRENTARTIFACT[i][2] == "honor" then
                for i = 1, 9 do
                    eclipses[i]:set_allow_blight_spawns(false)
                end
            end

            if CURRENTARTIFACT[i][2] == "cognation" then
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
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "distortion" then
            PLAYER[1]:remove_skill_override(0, 0)
            PLAYER[1]:remove_skill_override(1, 0)
            PLAYER[1]:remove_skill_override(2, 0)
            PLAYER[1]:remove_skill_override(3, 0)
            math.randomseed(BASESEED + minute)
            PLAYER[1]:add_skill_override(math.random(0, 3), 0)
        end
    end
end)

-- Spirit
spiritStatHandler:onPostStep(function(actor, stack)
    actor.pHmax = actor.pHmax_raw - 2 * (actor.hp / actor.maxhp) + 2
end)

gm.post_script_hook(gm.constants.enemy_stats_init, function(self, other, result, args)
    for i = 1, NUMARTIFACTS do
        -- Spririt
        if self.team == 2 and CURRENTARTIFACT[i][2] == "spirit" then
            if Instance.wrap(self):item_stack_count(spiritStatHandler) == 0 then
                Instance.wrap(self):item_give(spiritStatHandler)
            end
        end
        -- Honor
        if self.team == 2 and CURRENTARTIFACT[i][2] == "honor" then
            self.exp_worth = self.exp_worth * 2
        end
    end
end)

-- Sacrifice
Callback.add(Callback.TYPE.onKillProc, "OnyxArtifactSacrifice-onKillProc", function(victim, killer)
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "sacrifice" and not FinishedTele and math.random(1, ItemDropChance) ==
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
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "sacrifice" then
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
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "cognation" and actor.elite_type == 7 then
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
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "mountain" and self.object_index == gm.constants.oShrineMountainS then
            local function DoubleMountains()
                if DIRECTOR.teleporter_active == 0 then
                    DIRECTOR.mountain = DIRECTOR.mountain - 1
                    if DIRECTOR.mountain <= 0 then
                        DIRECTOR.mountain = 2
                    else
                        DIRECTOR.mountain = DIRECTOR.mountain * 2
                    end
                    KeepArtifact[i] = true
                end
            end
            Alarm.create(DoubleMountains, 1)
        end

        -- Honor
        if CURRENTARTIFACT[i][2] == "honor" and
            (self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
                self.object_index == gm.constants.oBlastdoorPanel) then
            self.maxtime = 1
        end
    end
end)

-- Origin
local timeMinute = 0
Callback.add("onMinute", "OnyxArtifactOrigin-onMinute", function(minute, second)
    if NUMARTIFACTS == 0 then
        timeMinute = 0
    end
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "origin" and minute % 5 == 0 then
            timeMinute = minute
            local Invasion = Object.find("ror", "ImpPortal")
            for i = 1, 1 + minute / 10 do
                Invasion:create(PLAYER[1].x, PLAYER[1].y)
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
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "temporary" and args[3].value == 3 then
            gm.item_give_internal(args[1].value, args[2].value, 2, args[4].value)
        end
    end
end)