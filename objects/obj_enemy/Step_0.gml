if (process_this_frame()) {
	event_inherited();
	
	visible = activated;
	if (activated) {
		if (corporeal) {
			var death_sound = noone;
			if (!fire_resistant && is_covered_at_each_quadrant_by(obj_lava)) { death_sound = snd_extinguish; }
			else if (corporeal && is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) { death_sound = snd_crunch; }
			
			if (death_sound != noone) { kill_enemy(death_sound); }
		}
		else {
			// Flicker sprite if not corporeal
			visible = (global.controller.number_of_frames_since_game_began mod (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING * 2) == 0);
		}
	}
}
