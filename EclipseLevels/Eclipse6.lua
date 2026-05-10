local PriceIncrease = 1.3
local BuffedPriceIncrease = 1.4

-- increase chest prices
Hook.add_pre(gm.constants.interactable_init_cost, function(self, other, result, args)
    if args[2].value == 0 and gm.bool(ECLIPSEARTIFACTS[6].active) and type(args[1].value) ~= "number" and
    (gm.object_get_parent(args[1].value.object_index) == gm.constants.pInteractableChest or 
    args[1].value.object_index == gm.constantsoChest4 or 
    gm.object_get_parent(args[1].value.object_index) == gm.constants.pInteractableTriShop) then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            args[3].value = args[3].value * BuffedPriceIncrease
        else
            args[3].value = args[3].value * PriceIncrease
        end
    end
end)

-- Alt --
local ChestRemoveCount = 0
local ChestPacket = Packet.new("ChestPacket")

Callback.add(Callback.ON_GAME_START, function()
    ChestRemoveCount = 0
end)

ChestPacket:set_serializers(function(buffer, chest)
    buffer:write_instance(chest)
end, 
function(buffer, player)
    local chest = buffer:read_instance()
    chest.active = 1
    chest.open_delay = 0
end)

local function EmptyChest(minute)
    local player = Player.get_local()
    local Chests = Instance.find_all(Instance.chests)

    local function compareDistance(a, b)
        return a:distance_to_point(player.x, player.y) < b:distance_to_point(player.x, player.y)
    end
    table.sort(Chests, compareDistance)
    
    while ChestRemoveCount > 0 and #Chests > 0 do
        if Chests[1].active <= 0 then
            Chests[1].active = 1
            Chests[1].open_delay = 0
            ChestRemoveCount = ChestRemoveCount - 1
        end
        if Net.online then
            ChestPacket:send_to_all(Chests[1])
        end
        table.remove(Chests, 1)
    end
end

Callback.add(Callback.ON_STAGE_START, function()
    if gm.bool(ALTECLIPSEARTIFACTS[6].active) then
        if gm._mod_net_isHost() then
        Alarm.create(EmptyChest, 1, 0)
        end
    end
end)
Callback.add(Callback.ON_MINUTE, function(minute, second)
    for i = 1, NUMARTIFACTS do
        if CURRENTARTIFACT[i][2] == "sacrifice" then
            return;
        end
    end
    if gm.bool(ALTECLIPSEARTIFACTS[6].active) then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            if minute % 8 == 0 then
                ChestRemoveCount = 4
            end
        else
            if minute % 4 == 0 then
                ChestRemoveCount = 1
            end
        end
    end
    
    if gm._mod_net_isHost() then
        EmptyChest(minute)
    end
end)