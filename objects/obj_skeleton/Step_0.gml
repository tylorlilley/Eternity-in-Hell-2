if (can_process_this_frame()) {
	if (spawn_timer > 0) { spawn_timer -= 1; }
	else { 
		var dir = irandom(skeleton_speed);
		var dropped_meat = get_dropped_meat();
		if (is_cardinal_direction(dir)) {
			if (is_existing_instance(dropped_meat) && 
				get_random_possible_direction(dropped_meat.x, dropped_meat.y, false, true) != directions.none) { 
					move_towards_coordinates(dropped_meat.x, dropped_meat.y, false, true); 
			}
			else if (can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); } 
		}
	}

	event_inherited();
}
