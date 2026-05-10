Callback.add(Callback.ON_GAME_START, function()
    if gm.bool(ECLIPSEARTIFACTS[9].active) then
        local Eclipse9 = Difficulty.find("ssr", "typhoon")
        GM._mod_game_setDifficulty(Eclipse9)
        Eclipse9.sprite_id = Sprite.new("Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13)
        Eclipse9.sprite_loadout_id = Sprite.new("Eclipse9Typhoon_2x", PATH .. "DifficultyTyphoon_2x.png", 4, 20, 19)
    end
end)

Callback.add(Callback.ON_GAME_END, function()
    local Eclipse9 = Difficulty.find("ssr", "typhoon")
    if Eclipse9 then
        Eclipse9.sprite_id = Sprite.new("Eclipse9Typhoon", PATH .. "DifficultyTyphoon.png", 5, 13, 13)
        Eclipse9.sprite_loadout_id = Sprite.new("Eclipse9Typhoon_2x", PATH .. "DifficultyTyphoon_2x.png", 4, 20, 19)
    end
end)
