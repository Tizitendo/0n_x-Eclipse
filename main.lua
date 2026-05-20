mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace   = "OnyxEclipse",  -- The namespace by which your mod is identified for custom content, etc.
    mp          = true      -- Mark your mod as safe to use online
}

PATH = _ENV["!plugins_mod_folder_path"] .. "/Assets/"
ECLIPSEARTIFACTS = {}
ALTECLIPSEARTIFACTS = {}
ACTIVEECLIPSE = false
NUMARTIFACTS = 0
CURRENTARTIFACT = {}
ECLIPSEDIFFICULTIES = {}
BASESEED = os.time()
Instance.chests = {
    gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5,
    gm.constants.oChestHealing1, gm.constants.oChestDamage1, gm.constants.oChestUtility1,
    gm.constants.oChestHealing2, gm.constants.oChestDamage2, gm.constants.oChestUtility2,
    gm.constants.oGunchest
}

local Eclipse = nil
local ArtifactMenu = nil
local EclipseDisplay
local ArtifactDisplay
local beach = nil
local beachEnemiesNormal = nil
local beachEnemiesEclipse = nil

Initialize.add_hotloadable(Callback.Priority.AFTER, function()
    require("options")
    ArtifactDisplay = List.wrap(Global.artifact_display_list)
    Difficulty.new("eclipse9")

    --setup the different boar beach enemy lists
    local boar_card = MonsterCard.new("BoarM")
    boar_card.object_id = Object.find("BoarM", "ror")
    boar_card.spawn_cost = 20
    boar_card.spawn_type = 0
    boar_card.can_be_blighted = false
    local bigboar_card = MonsterCard.new("BoarR")
    bigboar_card.object_id = Object.find("BoarR", "ror")
    bigboar_card.spawn_cost = 200
    bigboar_card.spawn_type = 0
    bigboar_card.can_be_blighted = false
    beach = Stage.find("boarBeach", "ror")
    local beach_cards = List.wrap(beach.spawn_enemies)
    local boarBoss_card = MonsterCard.find("toxicBeast", "ror")
    local scavenger_card = MonsterCard.find("scavenger", "ror")
    beachEnemiesNormal = beach.spawn_enemies
    beachEnemiesEclipse = List.new({
        scavenger_card,
        scavenger_card,
        boarBoss_card,
        boarBoss_card,
        boarBoss_card,
        boarBoss_card,
        boarBoss_card,
        boarBoss_card,
        bigboar_card,
        boar_card,
        boar_card
    })

    local eclipseSound = Sound.new("EclipseSfx", PATH .. "eclipse.ogg")
    -- find eclipse difficulties
    for i = 1, 9 do
        ECLIPSEDIFFICULTIES[i] = Difficulty.find("eclipse" .. tostring(i))
        ECLIPSEDIFFICULTIES[i].sound_id = eclipseSound
        ECLIPSEDIFFICULTIES[i].token_name = gm.translate("artifact.eclipse" .. i .. ".name")
        ECLIPSEDIFFICULTIES[i].token_description = "( 1 )  "
        for o = 1, i do
            ECLIPSEDIFFICULTIES[i].token_description =  ECLIPSEDIFFICULTIES[i].token_description ..
                                                        gm.translate("artifact.eclipse" .. o .. ".description")

            if i ~= o then
                ECLIPSEDIFFICULTIES[i].token_description = ECLIPSEDIFFICULTIES[i].token_description .. "\n( " .. (o + 1) .. " )  "
            end
        end
    end

    -- add secret eclipse 9
    ECLIPSEDIFFICULTIES[9].diff_scale = 0.2
    ECLIPSEDIFFICULTIES[9].general_scale = 4.0
    ECLIPSEDIFFICULTIES[9].point_scale = 1.7
    ECLIPSEDIFFICULTIES[9].is_monsoon_or_higher = true
    ECLIPSEDIFFICULTIES[9].allow_blight_spawns = true

    ECLIPSEDIFFICULTIES[9].sprite_id = Sprite.new("Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13)
    ECLIPSEDIFFICULTIES[9].sprite_loadout_id = Sprite.new("Eclipse9_2x", PATH .. "Eclipse9_2x.png", 6, 20, 19)
    EclipseDisplay = List.wrap(GM.variable_global_get("difficulty_display_list_eclipse"))

    for i = 1, 9 do
        ECLIPSEARTIFACTS[i] = Artifact.new("eclipse" .. i)
        ECLIPSEARTIFACTS[i].sprite_loadout_id = Sprite.new("ArtiEclipse" .. i, PATH .. "ArtiEclipse" .. i .. ".png", 3, 11, 12)
        table.insert(ALTECLIPSEARTIFACTS, nil)
    end
    ALTECLIPSEARTIFACTS[8] = Artifact.new("alteclipse8")
    ALTECLIPSEARTIFACTS[8].sprite_loadout_id = Sprite.new("ArtiAltEclipse8", PATH .. "ArtiAltEclipse8.png", 3, 11, 12)
    ALTECLIPSEARTIFACTS[6] = Artifact.new("alteclipse6")
    ALTECLIPSEARTIFACTS[6].sprite_loadout_id = Sprite.new("ArtiAltEclipse6", PATH .. "ArtiAltEclipse6.png", 3, 11, 12)
    ALTECLIPSEARTIFACTS[1] = Artifact.new("alteclipse1")
    ALTECLIPSEARTIFACTS[1].sprite_loadout_id = Sprite.new("ArtiAltEclipse1", PATH .. "ArtiAltEclipse1.png", 3, 11, 12)
    ALTECLIPSEARTIFACTS[5] = Artifact.new("alteclipse5")
    ALTECLIPSEARTIFACTS[5].sprite_loadout_id = Sprite.new("ArtiAltEclipse5", PATH .. "ArtiAltEclipse5.png", 3, 11, 12)
    ALTECLIPSEARTIFACTS[7] = Artifact.new("alteclipse7")
    ALTECLIPSEARTIFACTS[7].sprite_loadout_id = Sprite.new("ArtiAltEclipse7", PATH .. "ArtiAltEclipse7.png", 3, 11, 12)

    -- get the max eclipse level of all survivors for gold eclipse
    local MaxEclipse = 9
    for i = 0, #Class.SURVIVOR - 1 do
        if gm.difficulty_eclipse_get_max_available_level_for_survivor(i) < MaxEclipse then
            MaxEclipse = GM.difficulty_eclipse_get_max_available_level_for_survivor(i)
        end
        GM.difficulty_eclipse_get_max_available_level_for_survivor(i, 1)
    end
    for i = 1, MaxEclipse - 1 do
        ECLIPSEDIFFICULTIES[i].sprite_id = Sprite.new("GoldEclipse" .. i, PATH .. "GoldEclipse" .. i .. ".png", 2, 13, 13)
        ECLIPSEDIFFICULTIES[i].sprite_loadout_id = Sprite.new("GoldEclipse" .. i .. "_2x", PATH .. "GoldEclipse" .. i .. "_2x.png", 4, 20, 19)
    end

    -- add difficulty that opens eclipse menu
    Eclipse = Difficulty.new("eclipse")
    if MaxEclipse <= 8 then
        Eclipse.sprite_id = Sprite.new("EclipseIcon", PATH .. "StartEclipse.png", 1, 12, 12)
        Eclipse.sprite_loadout_id = Sprite.new("EclipseIcon2x", PATH .. "StartEclipse_2x.png", 4, 20, 19)
    elseif MaxEclipse <= 9 then
        Eclipse.sprite_id = Sprite.new("EclipseIconTyphoon", PATH .. "StartEclipseTyphoon.png", 1, 12, 12)
        Eclipse.sprite_loadout_id = Sprite.new("EclipseIconTyphoon2x", PATH .. "StartEclipseTyphoon_2x.png", 4, 20, 19)
    else
        Eclipse.sprite_id = Sprite.new("EclipseIcon", PATH .. "StartEclipseGold.png", 1, 12, 12)
        Eclipse.sprite_loadout_id = Sprite.new("EclipseIcon2x", PATH .. "StartEclipseGold_2x.png", 4, 20, 19)
    end
    Eclipse.primary_color = Color(0x62a8e5)
    Eclipse.sound_id = Sound.new("EclipseSfx", PATH .. "eclipse.ogg")

    if Difficulty.find("typhoon", "ssr") and EclipseDisplay[#EclipseDisplay] ~= Wrap.wrap(ECLIPSEDIFFICULTIES[9]) then
        EclipseDisplay:add(ECLIPSEDIFFICULTIES[9])
    end

    for i = 1, 9 do
        require("EclipseLevels/Eclipse"..i)
    end
end)

Hook.add_post(gm.constants.difficulty_eclipse_get_max_available_level_for_survivor, function(self, other, result, args)
    -- result.value = 999
        local Survivors = Global.class_survivor
        if Params.Unlocked9[Survivors[args[1].value + 1][1] .. "-" .. Survivors[args[1].value + 1][2]] then
            result.value = 9
        end

        for i = #ArtifactDisplay, 1, -1 do
            ArtifactDisplay:delete(i - 1)
        end
        for i = 1, result.value do
            if Wrap.wrap(ALTECLIPSEARTIFACTS[i]) then
                ArtifactDisplay:add(Wrap.wrap(ALTECLIPSEARTIFACTS[i]))
            end
        end
end)

-- check if e8 was beaten
Callback.add_SO(Callback.ON_GAME_END, function(self, other)
    if self ~= nil and self.object_index == gm.constants.oCommandFinal and ECLIPSEDIFFICULTIES[8]:is_active() then
        local Survivors = Global.class_survivor
        Params.Unlocked9[Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][1] .. "-" ..
            Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][2]] = true
        -- Toml.save_cfg(_ENV["!guid"], arams)
    end
end)

-- make eclipse 9 unlockable
memory.dynamic_hook_mid("max_diff_level_fix", {"rdi"}, {"RValue*"}, 0,
gm.get_script_function_address(106251):add(475), function(args)
    if Difficulty.find("typhoon", "ssr") then
        args[1].value = 9.0
    end
end)

Hook.add_pre(gm.constants.game_lobby_start, function(self, other)
    local DifficultyDisplay = List.wrap(GM.variable_global_get("difficulty_display_list"))

    for i = #DifficultyDisplay, 1, -1 do
        if Difficulty.wrap(DifficultyDisplay[i]) == Eclipse or Difficulty.wrap(DifficultyDisplay[i]) == ECLIPSEDIFFICULTIES[9] then
            DifficultyDisplay:delete(i-1)
        elseif DifficultyDisplay[i] > 2 and DifficultyDisplay[i] < 11 then
            DifficultyDisplay:delete(i-1)
        end
    end

    for i = #ArtifactDisplay, 1, -1 do
        ArtifactDisplay:delete(i - 1)
    end

    local BaseArtifacts = {}
        for k, v in ipairs(Global.class_artifact) do
            if v ~= 0 and v[2] ~= 0 and v[1] ~= "OnyxEclipse" and v[1] ~= "OnyxAltEclipse" then
                table.insert(BaseArtifacts, k - 1)
            end
        end

        for i = 1, #BaseArtifacts do
            ArtifactDisplay:add(BaseArtifacts[i])
        end

    if self and self.class_ind == nil then
        
    else
        DifficultyDisplay:add(Eclipse)
    end

    if (self and self.class_ind == nil) or Params.ShowArtifacts then
        for i = 1, 8 do
            ArtifactDisplay:add(ECLIPSEARTIFACTS[i])
        end
        for i = 1, 9 do
            if ALTECLIPSEARTIFACTS[i] then
                ArtifactDisplay:add(ALTECLIPSEARTIFACTS[i])
            end
        end
    end

    Alarm.add(25, function()
        local selectMenu = Instance.find(gm.constants.oSelectMenu)
        if selectMenu.sections then
            ArtifactMenu = selectMenu.sections[4]
        end
    end)
end)

-- log.info(Instance.find(gm.constants.oSelectMenu).run_start.script_name)
Hook.add_pre(gm.constants["anon@26822@gml_Object_oSelectMenu_Create_0"], function()
    local voted_diff = Difficulty.wrap(Global.__game_lobby.rulebook.difficulty_choice.true_votable.highest_voted_index)
    local eclipse_diff = Difficulty.find("eclipse")
    if voted_diff.namespace..voted_diff.identifier == eclipse_diff.namespace..""..eclipse_diff.identifier then
        GM.variable_global_set("__gamemode_current", 1)
        GM.room_goto(gm.constants.rSelect)
        
        for i = 1, #Global.__game_lobby.rulebook.artifact_toggle do
            Wrap.unwrap(Global.__game_lobby.rulebook.artifact_toggle[i]).value = false
        end
        Alarm.add(1, function()
            local selectMenu = Instance.find(gm.constants.oSelectMenu)
            Array.wrap(selectMenu.sections):push(ArtifactMenu)
            selectMenu.section_number = 4
        end)
        return false
    end
end)

-- check which eclipse difficulty is active, if any
Callback.add(Callback.ON_GAME_START, function()
    DIRECTOR = GM._mod_game_getDirector()
    FRAME = 0
    PLAYER = {}
    ACTIVEECLIPSE = false

    if not Params.ShowArtifacts then
        for i = 1, 9 do
            ECLIPSEARTIFACTS[i].active = false
        end
    end

    for i = 9, 1, -1 do
        if ECLIPSEDIFFICULTIES[i]:is_active() then
            ACTIVEECLIPSE = true
        end

        if ACTIVEECLIPSE and (not ALTECLIPSEARTIFACTS[i] or not ALTECLIPSEARTIFACTS[i].active) then
            ECLIPSEARTIFACTS[i].active = true
        end
    end

    for i = 9, 1, -1 do
        if ((ALTECLIPSEARTIFACTS[i] and ALTECLIPSEARTIFACTS[i] ~= 0 and ALTECLIPSEARTIFACTS[i].active) or ECLIPSEARTIFACTS[i].active) then
            ACTIVEECLIPSE = true
        end
    end

    -- add little boars to boar beach when eclipse is active
    if ACTIVEECLIPSE then
        beach.spawn_enemies = beachEnemiesEclipse
    else
        beach.spawn_enemies = beachEnemiesNormal
    end
end)

Callback.add(Callback.ON_STAGE_START, function()
    TELEPORTER = nil
end)

Callback.add(Callback.ON_PLAYER_INIT, function(player)
    local PlayerId = player.m_id
    if PlayerId == 0 then
        PlayerId = 1
    end
    PLAYER[PlayerId] = Wrap.wrap(player)
end)

Callback.add(Callback.ON_STEP, function()
    FRAME = FRAME + 1
end)

Hook.add_pre(gm.constants.interactable_set_active, function(self, other)
    -- get teleporter when interacting with it
    if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
        self.object_index == gm.constants.oBlastdoorPanel then
        RadiusMul = 0
        TELEPORTER = self
        KilledBoss = false
    end
end)