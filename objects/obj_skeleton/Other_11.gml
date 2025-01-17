/// @description Step
if (spawn_timer > 0) { spawn_timer -= 1; }
else if (skeleton_speed > 0) { 
	var dir = irandom(skeleton_speed);
	var dropped_meat = get_dropped_meat();
	if (is_cardinal_direction(dir)) {
		// Try to set up path toward dropped meat
		if (is_existing_instance(dropped_meat)) {
			target_x = dropped_meat.x;
			target_y = dropped_meat.y;
			set_automatic_target_path();
		}
		else { end_target_path(); }
		
		// Move toward point
		if (target_path != noone) { move_towards_coordinates_on_path(false, false, 1); }
		else if (can_move_in_direction(dir, false, fire_resistant)) { move_in_direction(dir, true); }
	}
}

event_inherited();
