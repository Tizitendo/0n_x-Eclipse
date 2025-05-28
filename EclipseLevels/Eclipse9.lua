local ImgEclipse9 = Resources.sprite_load("Onyx", "Eclipse9", PATH .. "Eclipse9.png", 2, 13, 13)
local ImgOriginalTyphoon = Resources.sprite_load("Onyx", "Eclipse9Typhoon", PATH .. "DifficultyTyphoon.png", 5, 13, 13)
local ImgEclipse9_2x = Resources.sprite_load("Onyx", "Eclipse9Typhoon_2x", PATH .. "DifficultyTyphoon_2x.png", 4, 20, 19)

Callback.add(Callback.TYPE.onGameStart, "OnyxEclipse9-onGameStart", function()
    if gm.bool(ECLIPSEARTIFACTS[9].active) then
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
