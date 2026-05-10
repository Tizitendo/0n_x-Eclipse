local EnemyCooldowns = 0.6
local BuffedEnemyCooldowns = 0.5

-- decrease enemy attack cooldown
Hook.add_post(gm.constants.recalculate_stats, function(self, other)
    if self.team == 2 and gm.bool(ECLIPSEARTIFACTS[7].active) and self.object_index ~= gm.constants.oImp then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            local actor = Instance.wrap(self)
            local skills = {actor:get_active_skill(0), actor:get_active_skill(1), actor:get_active_skill(2),
                            actor:get_active_skill(3)}
            for i, skill in ipairs(skills) do
                skill.cooldown = math.ceil(skill.cooldown * BuffedEnemyCooldowns)
            end
        else
            local actor = Instance.wrap(self)
            local skills = {actor:get_active_skill(0), actor:get_active_skill(1), actor:get_active_skill(2),
                            actor:get_active_skill(3)}
            for i, skill in ipairs(skills) do
                skill.cooldown = math.ceil(skill.cooldown * EnemyCooldowns)
            end
        end
    end
end)
---- Alt ----
-- increase explosion height
Hook.add_pre(gm.constants.fire_explosion, function(self, other, result, args)
    if gm.bool(ALTECLIPSEARTIFACTS[7].active) and self.team == 2 and self.object_index ~= gm.constants.oSpitter then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            args[9].value = args[9].value + math.sqrt(args[9].value) * 1.1
        else
            args[9].value = args[9].value + math.sqrt(args[9].value)
        end
    end
end)
-- add more bullet tracers
Hook.add_pre(gm.constants.fire_bullet, function(self, other, result, args)
    if gm.bool(ALTECLIPSEARTIFACTS[7].active) and self and self.team == 2 and other ~= nil and self.object_index ~= gm.constants.oSpitter then
        args[5].value = args[5].value * 0.5
        self:fire_bullet(args[1].value, args[2].value, args[3].value - 10, args[4].value, args[5].value,
            args[6].value, args[7].value, args[8].value, args[9].value, args[10].value, args[11].value)
    end
end)