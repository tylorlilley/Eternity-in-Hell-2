if (process_this_frame()) {
	if (usurped) {
		instance_create_depth(x, y, 0, obj_bumper);
		instance_destroy();
	}
	
	if (spawn_timer > 0) { spawn_timer -= 1; }
	else { 
		var dir = irandom(skeleton_speed); 
		if (can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); } 
	}

	event_inherited();
}
