if (process_this_frame()) {
	if (spawn_timer > 0) { spawn_timer -= 1; }
	else { var dir = irandom(skeleton_speed); if (can_move_in_direction(dir, false, true)) { move_in_direction(dir); } }

	event_inherited();
}
