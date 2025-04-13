log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)
PATH = _ENV["!plugins_mod_folder_path"] .. "/Assets/"
NAMESPACE = "OnyxEclipse"
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
local eclipses = {}
local EclipseArtifacts = {}
local AlternativeEclipses = {}
local SelectMenu = nil

Initialize(function()
    local ArtifactDisplay = List.wrap(Global.artifact_display_list)
    Difficulty.new("ror", "eclipse9")

    -- find eclipse difficulties
    for i = 1, 9 do
        eclipses[i] = Difficulty.find("ror", "eclipse" .. tostring(i))
        eclipses[i]:set_sound(Resources.sfx_load("Onyx", "EclipseSfx", PATH .. "eclipse.ogg"))
        eclipses[i].token_name = Language.translate_token("artifact.eclipse"..i..".name")
        eclipses[i].token_description = "( 1 )  "
        for o = 1, i do
            eclipses[i].token_description = eclipses[i].token_description..Language.translate_token("artifact.eclipse"..o..".description")

            if i ~= o then
                eclipses[i].token_description = eclipses[i].token_description.."\n( "..(o+1).." )  "
            end
        end
    end
    -- add secret eclipse 9
    eclipses[9]:set_scaling(0.2, 4.0, 1.7)
    eclipses[9]:set_monsoon_or_higher(true)
    eclipses[9]:set_allow_blight_spawns(true)
    eclipses[9]:set_sprite(Resources.sprite_load("Onyx", "Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13),
        Resources.sprite_load("Onyx", "Eclipse9_2x", PATH .. "Eclipse9_2x.png", 6, 20, 19))
    local EclipseDisplay = List.wrap(GM.variable_global_get("difficulty_display_list_eclipse"))

    if Mod.find("RobomandosLab-StarstormReturns") or Mod.find("Robomandoslab-StarstormReturns") then
        EclipseDisplay:add(Wrap.wrap(eclipses[9]))
    end

    for i = 1, 9 do
        EclipseArtifacts[i] = Artifact.new("OnyxEclipse", "eclipse" .. i)
        EclipseArtifacts[i]:set_sprites(Resources.sprite_load("Onyx", "ArtiEclipse" .. i,
            PATH .. "ArtiEclipse" .. i .. ".png", 3, 11, 12), 1)
        table.insert(AlternativeEclipses, 0)
    end
    -- table.insert(AlternativeEclipses, Artifact.new("OnyxAltEclipse", "alteclipse6"))
    AlternativeEclipses[8] = Artifact.new("OnyxAltEclipse", "alteclipse8")
    AlternativeEclipses[8]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse8", PATH .. "ArtiAltEclipse8.png",
        3, 11, 12), 1)
    AlternativeEclipses[6] = Artifact.new("OnyxAltEclipse", "alteclipse6")
    AlternativeEclipses[6]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse6", PATH .. "ArtiAltEclipse6.png",
        3, 11, 12), 1)
    AlternativeEclipses[1] = Artifact.new("OnyxAltEclipse", "alteclipse1")
    AlternativeEclipses[1]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse1", PATH .. "ArtiAltEclipse1.png",
        3, 11, 12), 1)
    AlternativeEclipses[5] = Artifact.new("OnyxAltEclipse", "alteclipse5")
    AlternativeEclipses[5]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse5", PATH .. "ArtiAltEclipse5.png",
        3, 11, 12), 1)
    AlternativeEclipses[7] = Artifact.new("OnyxAltEclipse", "alteclipse7")
    AlternativeEclipses[7]:set_sprites(Resources.sprite_load("Onyx", "ArtiAltEclipse7", PATH .. "ArtiAltEclipse7.png",
        3, 11, 12), 1)

    

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
                if Wrap.wrap(AlternativeEclipses[i]) ~= 0 then
                    ArtifactDisplay:add(Wrap.wrap(AlternativeEclipses[i]))
                end
            end
        end)

    -- check if e8 was beaten
    Callback_Raw.add(Callback.TYPE.onGameEnd, "OnyxEclipse-onGameEnd", function(self, other, result, args)
        if self ~= nil and self.object_index == gm.constants.oCommandFinal and eclipses[8]:is_active() then
            local Survivors = Global.class_survivor
            params.Unlocked9[Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][1] .. "-" ..
                Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][2]] = true
            Toml.save_cfg(_ENV["!guid"], params)
        end
    end)

    -- make eclipse 9 unlockable
    memory.dynamic_hook_mid("max_diff_level_fix", {"rdi"}, {"RValue*"}, 0,
        gm.get_script_function_address(106251):add(475), function(args)
            if Mod.find("RobomandosLab-StarstormReturns") or Mod.find("Robomandoslab-StarstormReturns") then
                args[1].value = 9.0
            end
        end)

    -- get the max eclipse level of all survivors for gold eclipse
    local MaxEclipse = 9
    for i = 0, #Class.SURVIVOR - 1 do
        if gm.difficulty_eclipse_get_max_available_level_for_survivor(i) < MaxEclipse then
            MaxEclipse = GM.difficulty_eclipse_get_max_available_level_for_survivor(i)
        end
        GM.difficulty_eclipse_get_max_available_level_for_survivor(i, 1)
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

    local ArtifactMenu = nil
    gm.pre_script_hook(gm.constants.game_lobby_start, function(self, other, result, args)
        local DifficultyDisplay = List.wrap(GM.variable_global_get("difficulty_display_list"))

        for i = #DifficultyDisplay, 1, -1 do
            if DifficultyDisplay[i] == Wrap.wrap(Eclipse) or DifficultyDisplay[i] == Wrap.wrap(eclipses[9]) then
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
            if v ~= 0 and v[2] ~= 0 and v[1] ~= "OnyxEclipse" then
                table.insert(BaseArtifacts, v)
            end
        end

        for i = 1, #BaseArtifacts do
            ArtifactDisplay:add(Wrap.wrap(Artifact.find(BaseArtifacts[i][1], BaseArtifacts[i][2])))
        end

        if (self and self.class_ind == nil) or params.ShowArtifacts then
            for i = 1, 8 do
                ArtifactDisplay:add(Wrap.wrap(EclipseArtifacts[i]))
            end
            for i = 1, #AlternativeEclipses do
                if Wrap.wrap(AlternativeEclipses[i]) ~= 0 then
                    ArtifactDisplay:add(Wrap.wrap(AlternativeEclipses[i]))
                end
            end
        end

        if self and self.class_ind == nil then

        else
            DifficultyDisplay:add(Wrap.wrap(Eclipse))
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
                Alarm.create(Wait, 10)
            end
        end
        Alarm.create(OpenEclipse, 1)
    end)

    require("EclipseLevels")
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
