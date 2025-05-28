local EnemyMoveSpeed = 1.15
local BuffedEnemyMoveSpeed = 1.2
local EnemyAttackSpeed = 1.15
local BuffedEnemyAttackSpeed = 1.2

gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    -- increase enemy speed
    if self.team == 2 and gm.bool(ECLIPSEARTIFACTS[4].active) and self.object_index ~= gm.constants.oGolemT and
        self.object_index ~= gm.constants.imp then
        if gm.bool(ALTECLIPSEARTIFACTS[5].active) then
            self.pHmax_raw = self.pHmax_raw * BuffedEnemyMoveSpeed
            self.pHmax = self.pHmax * BuffedEnemyMoveSpeed
            self.attack_speed = self.attack_speed * BuffedEnemyAttackSpeed
        else
            self.pHmax_raw = self.pHmax_raw * EnemyMoveSpeed
            self.pHmax = self.pHmax * EnemyMoveSpeed
            self.attack_speed = self.attack_speed * EnemyAttackSpeed
        end
    end
end)