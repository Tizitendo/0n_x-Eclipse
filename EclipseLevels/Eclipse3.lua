local EndFight = false
local FinishedTele = false
local UpdatePacket = Packet.new("finishedTele")

Callback.add(Callback.ON_STAGE_START, function()
    EndFight = false
    FinishedTele = false
end)

Callback.add(Callback.ON_STEP, function()
    -- log.warning(DIRECTOR:alarm_get(1))
    if DIRECTOR:alarm_get(1) == 1 then
        if EndFight then
            Alarm.add(2, function()
                -- DIRECTOR:alarm_set(1, DIRECTOR:alarm_get(1) * 3)
                DIRECTOR:alarm_set(1, 1800)
            end)
        end
    end
end)

UpdatePacket:set_serializers(function(buffer, finishedTele)
    buffer:write_bool(finishedTele)
end, 
function(buffer, player)
    FinishedTele = buffer:read_bool()
end)

Callback.add(Callback.ON_SECOND, function(minute, second)
    if gm.bool(ECLIPSEARTIFACTS[3].active) and DIRECTOR:alarm_get(1) < 0 then
        DIRECTOR.points = 0
        DIRECTOR:alarm_set(1, 600)
        FinishedTele = true
        if Net.online and Net.host then
            UpdatePacket:send_to_all(FinishedTele)
        end
    end
end)

Hook.add_post(gm.constants.enemy_stats_init, function(self, other)
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

Hook.add_pre(gm.constants.interactable_set_active, function(self, other)
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