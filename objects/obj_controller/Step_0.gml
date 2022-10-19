// If this frame should be processed
if (number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	if (!game_has_been_lost() && !game_has_been_won()) {
	    // Play map Sound Effects
	    if key_space_pressed { audio_play_sound( snd_pickup, 10, false ); }
	    if key_space_released { audio_play_sound( snd_putdown, 10, false ); }
    
	    // Update per frame values
	    time_remaining -= one_unit_of_game_time();
	    //if key_space { time_remaining -= one_unit_of_game_time(); }
	    if (game_has_timed_out()) { time_remaining = 0; audio_play_sound( snd_lose, 10, false ); }
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != noone && !blackout) { blackout = true; }
		else if (transition != noone && blackout) { transition_to_room(); }
	}
	if (room != rm_finish && (game_has_been_lost() || game_has_been_won())) {
		if (game_has_been_won() || game_has_timed_out() || death_timer == 0) { global.player.visible = false; room_goto(rm_finish); }
		else { death_timer -= 1; }
	}
	
	// Update background
	background_id = layer_background_get_id(layer_get_id("Background"));
	bg_color = make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(time_remaining/time_provided), 8), 1)), 20, 20);
	//if (game_has_been_won()) { bg_color = c_white; }
	layer_background_blend( background_id,  bg_color );
	
	// Restart game if necessary
	if initialized && key_enter_released { restart_game(); }
	
	// ALL CODE CHECKING FOR KEYS DURING THIS FRAME MUST HAPPEN BEFORE THIS POINT
	clear_inputs_for_next_frame();
}

// Increment number of processed frames
number_of_frames_since_game_began += 1;

// Record inputs that happen between frames to apply to the next frame
get_inputs_for_next_frame();