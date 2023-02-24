if (can_process_this_frame()) {	
	if (activated) {		
		// Determine course of action based on state
		if (state == SCREECHING) {
			if (screech_timer > 0) { screech_timer -= 1; }
			else { state = ATTACKING; }
		}
		else if (state == ATTACKING) {
			if (can_move_in_direction(dir, false, true)) {
				var prev_xscale = image_xscale;
				if (can_move_in_direction(dir, false, true)) { move_in_direction(dir, true); image_xscale = -1 * prev_xscale; }
				try_to_see_player();
				if (state == ATTACKING && can_move_in_direction(dir, false, true)) { move_in_direction(dir, true); image_xscale = -1 * prev_xscale; }
				try_to_see_player();
			}
			else {
				state = RETURNING;
				dir = directions.none;
				play_sound(snd_give_up, false);
				path_add_point(target_path, x, y, 1);
				path_reverse(target_path);
				initialize_target_path();
				set_path_point_to_target_path_start();
			}
		}
		else if (state == RETURNING) {
			if (target_path == noone) { start_waiting(); } 
			else {
				var prev_xscale = image_xscale;
				move_towards_coordinates_on_path(false, false, 1);
				try_to_see_player();
				image_xscale = -1 * prev_xscale;
			}
		}
		else { 
			start_waiting();
			
			if (get_random_chance_out_of(16)) {
				image_xscale *= -1;
				if (!place_meeting(x, y, obj_bush)) { play_sound(snd_walk, false); }
			}
		}
	}

	event_inherited();
}
