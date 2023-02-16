if (can_process_this_frame()) {
	var game_manager = global.game_manager;
	if (game_manager.key_up_pressed || 
		game_manager.key_down_pressed || 
		game_manager.key_right_pressed || 
		game_manager.key_left_pressed) {
	   teleport_this_frame = true; 
	}

	event_inherited();
}

