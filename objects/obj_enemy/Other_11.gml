/// @description Step
event_inherited();
	
// An enemy that isn't activated is hidden, and skips the checks below
visible = activated;
	
if (activated) {
	if (corporeal) {
		var _death_by_fire_skeleton = object_index != obj_fire_skeleton && instance_place(x, y, obj_fire_skeleton);
			
		if (!floating) {
			// An enemy that isn't fire resistant dies in lava: when lava covers every quadrant of its spot, or when it
			// touches lava and a fire skeleton stands on it too. The lava gets the credit for the kill.
			// TODO: Test these lava deaths, and check that lava_kill_count counts them correctly
			if (!fire_resistant && (is_covered_at_each_quadrant_by(obj_lava_part) || _death_by_fire_skeleton)) { 
				with instance_place(x, y, obj_lava) {
					with other {
						kill_enemy(snd_extinguish, obj_lava);
						global.controller.evaluation_manager.increment_evaluation_variable("lava_kill_count");
					}
				}
			}
		}
			
		// Floating enemies are drawn in front of the others
		depth = (floating) ? FLOATING_ENEMY_DEPTH : start_depth;
	}
	else {
		// Flicker sprite if not corporeal
		depth = INCORPOREAL_ENEMY_DEPTH;
		visible = is_blink_frame();
	}
}

