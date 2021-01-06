if (process_this_frame()) {
	visible = lethal

	if lethal {
		// Turn to face the player and begin Screeching if player is in view
		try_to_see_player();
		
		// Determine course of action based on state
		if (state == SCREECHING) {
			if (screech_timer > 0) { screech_timer -= 1; }
			else { state = ATTACKING; }
		}
	    else if (state == ATTACKING && can_move_in_direction(dir, false, true)) {
			if (global.controller.number_of_frames_since_game_began mod (global.controller.FRAMES_TO_WAIT_BEFORE_PROCESSING * 2) == 0) { image_xscale *= -1; }
	        if (can_move_in_direction(dir, false, true)) { move_in_direction(dir); }
			try_to_see_player();
	        if (state == ATTACKING && can_move_in_direction(dir, false, true)) { move_in_direction(dir); }
		 }
	    else { 
			state = WAITING;
			dir = -1;
		}
    
	    event_inherited();
	}
}
