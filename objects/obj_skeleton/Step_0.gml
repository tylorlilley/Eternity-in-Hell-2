if (process_this_frame()) {
	if (spawn_timer > 0) { spawn_timer -= 1; }
	else { 
		var dir = irandom(skeleton_speed);
		var dropped_meat = get_dropped_meat();
		if (dir <= 3) {
			if (dropped_meat != noone && get_random_possible_direction(dropped_meat.x, dropped_meat.y, false, true) != noone) { move_towards_coordinates(dropped_meat.x, dropped_meat.y, false, true); }
			else if (can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); } 
		}
	}

	event_inherited();
}
