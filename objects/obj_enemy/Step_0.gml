if (process_this_frame()) {
	event_inherited();
	
	visible = activated;
	if (activated) {
		if (corporeal) {
			var death_sound = noone;
			if (!fire_resistant && (instance_place(x, y, obj_fireball) || is_covered_at_each_quadrant_by(obj_lava))) { death_sound = snd_extinguish; }
			else if (corporeal && is_covered_at_each_quadrant_by(obj_solid)) { death_sound = snd_crunch; }
			
			if (death_sound != noone) { kill_enemy(death_sound); }
		}
		else {
			// Flicker sprite if not corporeal
			visible = (global.controller.number_of_frames_since_game_began mod (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING * 2) == 0);
		}
		
		/*
		// Fidget Sprite if Eating Meat
		if (meat_eater) {
			var dropped_meat = noone;
			with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
			if (dropped_meat != noone || instance_position(x, y, obj_player_corpse)) {
				if (get_random_chance_out_of(4)) { play_sound(snd_walk, false); image_xscale *= -1; }
			}
		}
		*/
	}
}
