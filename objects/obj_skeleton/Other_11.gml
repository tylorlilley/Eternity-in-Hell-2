/// @description Step
if (spawn_timer > 0) { spawn_timer -= 1; }
else if (skeleton_speed > 0) { 
	var dir = irandom(skeleton_speed);
	if (is_cardinal_direction(dir)) {
		// Move on path towards meat or player
		if (is_existing_instance(get_dropped_meat()) || get_random_chance_out_of(SKELETON_MOVE_towards_PLAYER_FREQUENCY)) {
			move_towards_meat_or_player(false, fire_resistant);
		}
		else { end_target_path(); }
		
		// Otherwise, move in a random direction
		if (can_move_in_direction(dir, false, fire_resistant)) { move_in_direction(dir, true); }
	}
}

event_inherited();
