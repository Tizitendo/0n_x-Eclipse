local EndFight = false
local FinishedTele = false
local UpdatePacket = Packet.new()

Callback.add(Callback.TYPE.onStageStart, NAMESPACE.."3-onStageStart", function()
    EndFight = false
    FinishedTele = false
end)

Callback.add("onStep", "OnyxEclipse3-onStep", function()
    -- log.warning(DIRECTOR:alarm_get(1))
    if DIRECTOR:alarm_get(1) == 1 then
        if EndFight then
            local function DecreaseSpawnRate()
                -- DIRECTOR:alarm_set(1, DIRECTOR:alarm_get(1) * 3)
                DIRECTOR:alarm_set(1, 1500)
            end
            Alarm.create(DecreaseSpawnRate, 2)
        end
    end
end)

Callback.add("onSecond", "OnyxEclipse3-onSecond", function(minute, second)
    if gm.bool(ECLIPSEARTIFACTS[3].active) and DIRECTOR:alarm_get(1) < 0 then
        DIRECTOR.points = 0
        DIRECTOR:alarm_set(1, 600)
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
    if NUMARTIFACTS == 0 then
        if FinishedTele and self.team == 2 then
            self.exp_worth = 0
        end
    else
        for i = 1, NUMARTIFACTS do
            if FinishedTele and self.team == 2 and CURRENTARTIFACT[i][2] ~= "honor" then
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