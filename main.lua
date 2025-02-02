log.info("Successfully loaded " .. _ENV["!guid"] .. ".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()
PATH = _ENV["!plugins_mod_folder_path"] .. "/Assets/"
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

Initialize(function()
    local ArtifactDisplay = List.wrap(Global.artifact_display_list)
    Difficulty.new("ror", "eclipse9")

    -- find eclipse difficulties
    for i = 1, 9 do
        eclipses[i] = Difficulty.find("ror", "eclipse" .. tostring(i))
        eclipses[i]:set_sound(Resources.sfx_load("Onyx", "EclipseSfx", PATH .. "eclipse.ogg"))
    end
    -- add secret eclipse 9
    eclipses[9]:set_scaling(0.2, 4.0, 1.7)
    eclipses[9]:set_monsoon_or_higher(true)
    eclipses[9]:set_allow_blight_spawns(true)
    eclipses[9]:set_sprite(Resources.sprite_load("Onyx", "Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13),
        Resources.sprite_load("Onyx", "Eclipse9_2x", PATH .. "Eclipse9_2x.png", 6, 20, 19))
    local EclipseDisplay = List.wrap(GM.variable_global_get("difficulty_display_list_eclipse"))
    
    if Mod.find("Robomandoslab-StarstormReturns") ~= nil then
        EclipseDisplay:add(Wrap.wrap(eclipses[9]))
    end

    for i = 1, 9 do
        EclipseArtifacts[i] = Artifact.new("OnyxEclipse", "eclipse"..i)
        EclipseArtifacts[i]:set_sprites(Resources.sprite_load("Onyx", "ArtiEclipse"..i, PATH .. "ArtiEclipse"..i..".png", 3, 11, 12), 1)
    end
    ArtifactDisplay:delete(#ArtifactDisplay-1)

    gm.post_script_hook(gm.constants.difficulty_eclipse_get_max_available_level_for_survivor, function(self, other, result, args)
        --result.value = 999
        local Survivors = Global.class_survivor
        if params.Unlocked9[Survivors[args[1].value + 1][1].."-"..Survivors[args[1].value + 1][2]] then
            result.value = 9
        end
    end)

    -- check if e8 was beaten
    Callback_Raw.add(Callback.TYPE.onGameEnd, "OnyxEclipse-onGameEnd", function(self, other, result, args)
        if self ~= nil and self.object_index == gm.constants.oCommandFinal and eclipses[8]:is_active() then
            local Survivors = Global.class_survivor
            params.Unlocked9[Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][1].."-"..Survivors[GM._mod_player_get_survivor(Player.get_client()) + 1][2]] = true
            Toml.save_cfg(_ENV["!guid"], params)
        end
    end)

    -- make eclipse 9 unlockable
    memory.dynamic_hook_mid("max_diff_level_fix", {"rdi"}, {"RValue*"}, 0,
    gm.get_script_function_address(106251):add(475), function(args)
        args[1].value = 9.0
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
            for o = 1, 9 do
                if ArtifactDisplay[i] == Wrap.wrap(EclipseArtifacts[o]) then
                    ArtifactDisplay:delete(i-1)
                end
            end
        end

        if (self and self.class_ind == nil) or params.ShowArtifacts then
            for i = 1, 8 do
                ArtifactDisplay:add(Wrap.wrap(EclipseArtifacts[i]))
            end
        end

        if self and self.class_ind == nil then
            
        else
            DifficultyDisplay:add(Wrap.wrap(Eclipse))
        end
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
