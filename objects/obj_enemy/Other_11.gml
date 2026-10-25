/// @description Step
event_inherited();
	
visible = activated;
	
if (activated) {
	if (corporeal) {
		var _death_by_fire_skeleton = object_index != obj_fire_skeleton && instance_place(x, y, obj_fire_skeleton);
			
		if (!floating) {
			// TEST THIS ENEMY LAVA DEATH - Eval?
			if (!fire_resistant && (is_covered_at_each_quadrant_by(obj_lava_part) || _death_by_fire_skeleton)) { 
				with instance_place(x, y, obj_lava) {
					with other {
						kill_enemy(snd_extinguish, obj_lava);
						increment_run_stat("lava_kill_count");
					}
				}
			}
		}
			
		depth = (floating) ? FLOATING_ENEMY_DEPTH : start_depth;
	}
	else {
		// Flicker sprite if not corporeal
		depth = INCORPOREAL_ENEMY_DEPTH;
		visible = is_blink_frame();
	}
}

