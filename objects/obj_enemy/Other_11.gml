/// @description Step
event_inherited();
	
visible = activated;
	
if (activated) {
	if (corporeal) {
		var death_sound = noone;
			
		if (!floating) {
			if (!fire_resistant && is_covered_at_each_quadrant_by(obj_lava_part)) { death_sound = snd_extinguish; }
			else if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) { death_sound = snd_crunch; }
		}
			
		if (death_sound != noone) { kill_enemy(death_sound); }
		depth = (floating) ? FLOATING_ENEMY_DEPTH : start_depth;
	}
	else {
		// Flicker sprite if not corporeal
		depth = INCORPOREAL_ENEMY_DEPTH;
		visible = (modulo(global.game_manager.number_of_frames_since_game_began, (FRAMES_TO_WAIT_BEFORE_PROCESSING * 2)) == 0);
	}
}

