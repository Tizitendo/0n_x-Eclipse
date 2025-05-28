log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
PATH = _ENV["!plugins_mod_folder_path"] .. "/Assets/"
NAMESPACE = "OnyxEclipse"
ECLIPSEARTIFACTS = {}
ALTECLIPSEARTIFACTS = {}
ACTIVEECLIPSE = false
NUMARTIFACTS = 0
CURRENTARTIFACT = {}
ECLIPSEDIFFICULTIES = {}
BASESEED = os.time()
mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        ShowArtifacts = true,
        Unlocked9 = {}
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

local Eclipse = nil
-- local eclipses = {}
local SelectMenu = nil
local ArtifactMenu = nil
local EclipseDisplay
local ArtifactDisplay
local beach = nil
local beachEnemiesNormal = nil
local beachEnemiesEclipse = nil

Initialize(function()
    ArtifactDisplay = List.wrap(Global.artifact_display_list)
    Difficulty.new("ror", "eclipse9")

    --setup the different boar beach enemy lists
    local boar_card = Monster_Card.new(NAMESPACE, "BoarM")
    boar_card.object_id = Object.find("ror", "BoarM")
    boar_card.spawn_cost = 20
    boar_card.spawn_type = Monster_Card.SPAWN_TYPE.classic
    boar_card.can_be_blighted = false
    local bigboar_card = Monster_Card.new(NAMESPACE, "BoarR")
    bigboar_card.object_id = Object.find("ror", "BoarR")
    bigboar_card.spawn_cost = 200
    bigboar_card.spawn_type = Monster_Card.SPAWN_TYPE.classic
    bigboar_card.can_be_blighted = false
    beach = Stage.find("ror-boarBeach")
    local beach_cards = List.wrap(beach.spawn_enemies)
    local boarBoss_card = Monster_Card.find("ror", "toxicBeast")
    local scavenger_card = Monster_Card.find("ror", "scavenger")
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

    -- find eclipse difficulties
    for i = 1, 9 do
        ECLIPSEDIFFICULTIES[i] = Difficulty.find("ror", "eclipse" .. tostring(i))
        ECLIPSEDIFFICULTIES[i]:set_sound(Resources.sfx_load("Onyx", "EclipseSfx", PATH .. "eclipse.ogg"))
        ECLIPSEDIFFICULTIES[i].token_name = Language.translate_token("artifact.eclipse" .. i .. ".name")
        ECLIPSEDIFFICULTIES[i].token_description = "( 1 )  "
        for o = 1, i do
            ECLIPSEDIFFICULTIES[i].token_description = ECLIPSEDIFFICULTIES[i].token_description ..
                                                Language.translate_token("artifact.eclipse" .. o .. ".description")

            if i ~= o then
                ECLIPSEDIFFICULTIES[i].token_description = ECLIPSEDIFFICULTIES[i].token_description .. "\n( " .. (o + 1) .. " )  "
            end
        end
    end

    -- add secret eclipse 9
    ECLIPSEDIFFICULTIES[9]:set_scaling(0.2, 4.0, 1.7)
    ECLIPSEDIFFICULTIES[9]:set_monsoon_or_higher(true)
    ECLIPSEDIFFICULTIES[9]:set_allow_blight_spawns(true)
    ECLIPSEDIFFICULTIES[9]:set_sprite(Resources.sprite_load("Onyx", "Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13),
        Resources.sprite_load("Onyx", "Eclipse9_2x", PATH .. "Eclipse9_2x.png", 6, 20, 19))
    EclipseDisplay = List.wrap(GM.variable_global_get("difficulty_display_list_eclipse"))

    for i = 1, 9 do
        ECLIPSEARTIFACTS[i] = Artifact.new("OnyxEclipse", "eclipse" .. i)
        ECLIPSEARTIFACTS[i]:set_sprites(Resources.sprite_load("Onyx", "ArtiEclipse" .. i,
            PATH .. "ArtiEclipse" .. i .. ".png", 3, 11, 12), 1)
        table.insert(ALTECLIPSEARTIFACTS, nil)
    end
    ALTECLIPSEARTIFACTS[8] = Artifact.new("OnyxAltEclipse", "alteclipse8")
    ALTECLIPSEARTIFACTS[8]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse8", PATH .. "ArtiAltEclipse8.png",
        3, 11, 12), 1)
    ALTECLIPSEARTIFACTS[6] = Artifact.new("OnyxAltEclipse", "alteclipse6")
    ALTECLIPSEARTIFACTS[6]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse6", PATH .. "ArtiAltEclipse6.png",
        3, 11, 12), 1)
    ALTECLIPSEARTIFACTS[1] = Artifact.new("OnyxAltEclipse", "alteclipse1")
    ALTECLIPSEARTIFACTS[1]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse1", PATH .. "ArtiAltEclipse1.png",
        3, 11, 12), 1)
    ALTECLIPSEARTIFACTS[5] = Artifact.new("OnyxAltEclipse", "alteclipse5")
    ALTECLIPSEARTIFACTS[5]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse5", PATH .. "ArtiAltEclipse5.png",
        3, 11, 12), 1)
    ALTECLIPSEARTIFACTS[7] = Artifact.new("OnyxAltEclipse", "alteclipse7")
    ALTECLIPSEARTIFACTS[7]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse7", PATH .. "ArtiAltEclipse7.png",
        3, 11, 12), 1)

    -- get the max eclipse level of all survivors for gold eclipse
    local MaxEclipse = 9
    for i = 0, #Class.SURVIVOR - 1 do
        if gm.difficulty_eclipse_get_max_available_level_for_survivor(i) < MaxEclipse then
            MaxEclipse = GM.difficulty_eclipse_get_max_available_level_for_survivor(i)
        end
        GM.difficulty_eclipse_get_max_available_level_for_survivor(i, 1)
    end
    for i = 1, MaxEclipse - 1 do
        ECLIPSEDIFFICULTIES[i]:set_sprite(Resources.sprite_load("Onyx", "GoldEclipse" .. i, PATH .. "GoldEclipse" .. i .. ".png",
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

    for i = 1, 9 do
        require("EclipseLevels/Eclipse"..i)
    end
end)

gm.post_script_hook(gm.constants.difficulty_eclipse_get_max_available_level_for_survivor,
    function(self, other, result, args)
        -- result.value = 999
        local Survivors = Global.class_survivor
        if params.Unlocked9[Survivors[args[1].value + 1][1] .. "-" .. Survivors[args[1].value + 1][2]] then
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
Callback_Raw.add(Callback.TYPE.onGameEnd, "OnyxEclipse-onGameEnd", function(self, other, result, args)
    if self ~= nil and self.object_index == gm.constants.oCommandFinal and ECLIPSEDIFFICULTIES[8]:is_active() then
        local Survivors = Global.class_survivor
        params.Unlocked9[Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][1] .. "-" ..
            Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][2]] = true
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

-- make eclipse 9 unlockable
memory.dynamic_hook_mid("max_diff_level_fix", {"rdi"}, {"RValue*"}, 0,
    gm.get_script_function_address(106251):add(475), function(args)
        if Difficulty.find("ssr", "typhoon") then
            args[1].value = 9.0
        end
    end)

gm.pre_script_hook(gm.constants.game_lobby_start, function(self, other, result, args)
    local DifficultyDisplay = List.wrap(GM.variable_global_get("difficulty_display_list"))

    if Difficulty.find("ssr", "typhoon") and EclipseDisplay[#EclipseDisplay] ~= Wrap.wrap(ECLIPSEDIFFICULTIES[9]) then
        EclipseDisplay:add(Wrap.wrap(ECLIPSEDIFFICULTIES[9]))
    end

    for i = #DifficultyDisplay, 1, -1 do
        if DifficultyDisplay[i] == Wrap.wrap(Eclipse) or DifficultyDisplay[i] == Wrap.wrap(ECLIPSEDIFFICULTIES[9]) then
            DifficultyDisplay:delete(i - 1)
        elseif DifficultyDisplay[i] > 2 and DifficultyDisplay[i] < 11 then
            DifficultyDisplay:delete(i - 1)
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
        DifficultyDisplay:add(Wrap.wrap(Eclipse))
    end

    if (self and self.class_ind == nil) or params.ShowArtifacts then
        for i = 1, 8 do
            ArtifactDisplay:add(Wrap.wrap(ECLIPSEARTIFACTS[i]))
        end
        for i = 1, 9 do
            if Wrap.wrap(ALTECLIPSEARTIFACTS[i]) then
                ArtifactDisplay:add(Wrap.wrap(ALTECLIPSEARTIFACTS[i]))
            end
        end
    end

    local function WaitForInit()
        local SelectMenu = Instance.find(Object.find("ror", "SelectMenu"))
        if SelectMenu.sections then
            ArtifactMenu = SelectMenu.sections[4]
        end
    end
    Alarm.create(WaitForInit, 25)
end)

-- check which eclipse difficulty is active, if any
Callback.add("onGameStart", "OnyxEclipse-onGameStart", function()
    DIRECTOR = GM._mod_game_getDirector()
    FRAME = 0
    PLAYER = {}
    ACTIVEECLIPSE = false

    if not params.ShowArtifacts then
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
        -- for i = #beach_cards, 1, -1 do
        --     if Monster_Card.wrap(beach_cards[i]) == boar_card then
        --         return
        --     end
        -- end
        -- beach:add_monster(boar_card)
        -- beach:add_monster(boar_card)
        -- beach:add_monster(bigboar_card)
        -- beach:add_monster(boarBoss_card)
        -- beach:add_monster(boarBoss_card)
        -- beach:add_monster(boarBoss_card)
        -- beach:add_monster(scavenger_card)
    else
        beach.spawn_enemies = beachEnemiesNormal
        -- for i = #beach_cards, 1, -1 do
        --     table.remove(List.wrap(beach.spawn_enemies), i)
        -- end
        -- beach:add_monster(boarBoss_card)
        -- beach:add_monster(boarBoss_card)
        -- beach:add_monster(boarBoss_card)
        -- beach:add_monster(scavenger_card)
    end

    local function OpenEclipse()
        if Eclipse:is_active() then
            GM.run_destroy()
            GM.variable_global_set("__gamemode_current", 1)
            GM.game_lobby_start()
            GM.room_goto(gm.constants.rSelect)
            local function Wait()
                local SelectMenu = Instance.find(Object.find("ror", "SelectMenu"))
                table.insert(SelectMenu.sections, ArtifactMenu)
                SelectMenu.section_number = 4
            end
            Alarm.create(Wait, 11)
        end
    end
    Alarm.create(OpenEclipse, 1)
end)

Callback.add(Callback.TYPE.onStageStart, NAMESPACE.."onStageStart", function()
    TELEPORTER = nil
end)

Callback.add("onPlayerInit", "OnyxEclipseGen-onPlayerInit", function(self)
    local PlayerId = self.m_id
    if PlayerId == 0 then
        PlayerId = 1
    end
    PLAYER[PlayerId] = Wrap.wrap(self)
end)

Callback.add(Callback.TYPE.onStep, NAMESPACE.."onStep", function()
    FRAME = FRAME + 1
end)

gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    -- get teleporter when interacting with it
    if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
        self.object_index == gm.constants.oBlastdoorPanel then
        RadiusMul = 0
        TELEPORTER = self
        KilledBoss = false
    end
end)

-- Add ImGui window
gui.add_to_menu_bar(function()
    params.ShowArtifacts = ImGui.Checkbox("Show Artifacts", params.ShowArtifacts)
    Toml.save_cfg(_ENV["!guid"], params)
end)
gui.add_imgui(function()
    if ImGui.Begin("Eclipse") then
        params.ShowArtifacts = ImGui.Checkbox("Show Artifacts", params.ShowArtifacts)
        Toml.save_cfg(_ENV["!guid"], params)
    end
    ImGui.End()
end)
