local alivePlayers = 0
local TeleRadius = 700
local BuffedTeleRadius = 300

local KilledBoss = false
local RadiusMul = 0
local disableChests = true
local BlockedInteractables = {gm.constants.oChest1, gm.constants.oChest2, gm.constants.oChest5, gm.constants.oChestHealing1,
                       gm.constants.oChestDamage1, gm.constants.oChestUtility1, gm.constants.oChestHealing2,
                       gm.constants.oChestDamage2, gm.constants.oChestUtility2, gm.constants.oGunchest,
                       gm.constants.oChest4, gm.constants.oEfChestRain, gm.constants.oShop1, gm.constants.oShop2, 
                       gm.constants.oBarrelEquipment, gm.constants.oShopEquipment,
                       gm.constants.oTeleporter, gm.constants.oBlastdoorPanel, gm.constants.oShrine1,
                       gm.constants.oShrine2, gm.constants.oShrine3, gm.constants.oShrine4, gm.constants.oShrine5}
local TeleColor = 190540540
local BuffedTeleColor = Color.from_hex(0xb53f80)
local Tele_circles = {}

Callback.add(Callback.TYPE.onStageStart, NAMESPACE.."2-onStageStart", function()
    disableChests = true
    Tele_circles = {}
end)

Callback.add("onStep", "OnyxEclipse2-onStep", function()
    -- get number of alive players
    alivePlayers = 0
    for i = 1, #PLAYER do
        if not PLAYER[i].dead then
            alivePlayers = alivePlayers + 1
        end
    end

    if gm.bool(ECLIPSEARTIFACTS[2].active) and TELEPORTER then
        if TELEPORTER.active == 1 then
            -- don't let tp timer count up if player is outside radius
            for i = 1, #PLAYER do
                if PLAYER[i].dead == false then
                    local DistanceX, DistanceY
                    DistanceX = PLAYER[i].x - TELEPORTER.x
                    DistanceY = PLAYER[i].y - TELEPORTER.y

                    if math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >= TeleRadius then
                        TELEPORTER.time = TELEPORTER.time - (1 / alivePlayers)
                    else
                        if ALTECLIPSEARTIFACTS[5].active then
                            if math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >= BuffedTeleRadius then
                                TELEPORTER.time = TELEPORTER.time - (1 / alivePlayers) * 0.2
                            else
                                TELEPORTER.time = TELEPORTER.time + (1 / alivePlayers) * 0.2
                            end
                        end
                    end
                end
            end

            -- don't let teleporter finish unless boss is killed
            if TELEPORTER.object_index == gm.constants.oTeleporter or TELEPORTER.object_index ==
                gm.constants.oTeleporterEpic then
                if KilledBoss and TELEPORTER.time >= TELEPORTER.maxtime - 3 then
                    TELEPORTER.time = TELEPORTER.time + 2
                elseif TELEPORTER.time >= TELEPORTER.maxtime - 2 then
                    TELEPORTER.time = TELEPORTER.maxtime - 2
                end
            end

            -- lock chests outside of tp radius
            if disableChests then
                disableChests = false
                local chests = Instance.find_all(BlockedInteractables)
                for k, v in pairs(chests) do
                    if v.active == 0 then
                        local DistanceX = v.x - TELEPORTER.x
                        local DistanceY = v.y - TELEPORTER.y
                        if math.sqrt(DistanceX ^ 2 + DistanceY ^ 2) >= TeleRadius then
                            v.active = -1
                        end
                    end
                end
            end
        else
            -- reenable locked chests after tp event
            if not disableChests then
                local chests = Instance.find_all(BlockedInteractables)
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

gm.post_script_hook(gm.constants["update_boss_party_active@gml_Object_oDirectorControl_Create_0"],
    function(self, other, result, args)
        KilledBoss = true
    end)

gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
    if self.object_index == gm.constants.oTeleporter or self.object_index == gm.constants.oTeleporterEpic or
        self.object_index == gm.constants.oBlastdoorPanel then
        RadiusMul = 0
        KilledBoss = false
    end
end)

Callback.add("onDraw", "OnyxEclipse2-onDraw", function()
    if gm.bool(ECLIPSEARTIFACTS[2].active) and TELEPORTER then
        gm.draw_set_circle_precision(128)
        if TELEPORTER.active == 1 then
            gm.draw_set_alpha(0.6 + 0.3 * math.cos(FRAME / 90))
            if RadiusMul < 0.999 then
                RadiusMul = RadiusMul + (1 - RadiusMul) * 0.05
            else
                RadiusMul = 1
            end
            gm.draw_circle_colour(TELEPORTER.x, TELEPORTER.y, TeleRadius * RadiusMul, TeleColor, TeleColor, true)
            if ALTECLIPSEARTIFACTS[5].active then
                gm.draw_circle_colour(TELEPORTER.x, TELEPORTER.y, BuffedTeleRadius * RadiusMul, BuffedTeleColor, BuffedTeleColor, true)
            end
        end
        if TELEPORTER.active ~= 1 and RadiusMul >= 1 and RadiusMul < 1.1 then
            RadiusMul = RadiusMul * 1.01
            gm.draw_set_alpha(0.8 - math.fmod(RadiusMul, 0.1))
            gm.draw_circle_colour(TELEPORTER.x, TELEPORTER.y, TeleRadius * RadiusMul, TeleColor, TeleColor, true)
            if ALTECLIPSEARTIFACTS[5].active then
                gm.draw_circle_colour(TELEPORTER.x, TELEPORTER.y, BuffedTeleRadius * RadiusMul, BuffedTeleColor, BuffedTeleColor, true)
            end
        end
        if RadiusMul == 1 then
            FRAME = FRAME + 1
            if FRAME % 45 == 0 then
                table.insert(Tele_circles, 0.9)
            end
        end
        if RadiusMul >= 1 then
            for i = #Tele_circles, 1, -1 do
                if Tele_circles[i] then
                    gm.draw_set_alpha(0.9 - ((Tele_circles[i] - 0.95) / 0.05) ^ 2)
                    Tele_circles[i] = Tele_circles[i] * 1.001
                    gm.draw_circle_colour(TELEPORTER.x, TELEPORTER.y, TeleRadius * Tele_circles[i], TeleColor, TeleColor, true)
                    if ALTECLIPSEARTIFACTS[5].active then
                        gm.draw_circle_colour(TELEPORTER.x, TELEPORTER.y, BuffedTeleRadius * Tele_circles[i], BuffedTeleColor, BuffedTeleColor, true)
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
    if TELEPORTER and TELEPORTER.active == 1 and gm.bool(ECLIPSEARTIFACTS[2].active) then
        local DistanceX, DistanceY
        for i = 1, #PLAYER do
            DistanceX = PLAYER[i].x - TELEPORTER.x
            DistanceY = PLAYER[i].y - TELEPORTER.y
            if DIRECTOR.teleporter_active == 1 and math.sqrt(DistanceX * DistanceX + DistanceY * DistanceY) >= TeleRadius then
                self.exp_worth = self.exp_worth * (1 - 0.5 / alivePlayers)
            end
        end
    end
end)