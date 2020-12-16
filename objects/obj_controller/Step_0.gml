if (number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
	if (!game_has_timed_out() && !game_has_been_won()) {
	    // Play map Sound Effects
	    if key_space_pressed { audio_play_sound( snd_pickup, 10, false ); }
	    if key_space_released { audio_play_sound( snd_putdown, 10, false ); }
    
	    // Update per frame values
	    points -= FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps);
	    if key_space { points -= FRAMES_TO_WAIT_BEFORE_PROCESSING/game_get_speed(gamespeed_fps); }
	    if (game_has_timed_out()) { audio_play_sound( snd_lose, 10, false ); }
	
		// Update background
		background_id = layer_background_get_id(layer_get_id("Background"));
		bg_color = make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(points/INITIAL_SCORE), 8), 1)), 20, 20);
		layer_background_blend( background_id,  bg_color );
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != noone && !blackout) { blackout = true; }
		else if (transition != noone && blackout) {
			transition_to_room();
		}
	}
	else if (game_has_been_lost()) { points = 0; }
	
	// Restart game if necessary
	if key_enter_released { game_restart(); }
	
	// ALL CODE CHECKING FOR KEYS DURING THIS FRAME MUST HAPPEN BEFORE THIS POINT
	clear_inputs_for_next_frame();
}

if (!game_has_timed_out() && !game_has_been_won()) { number_of_frames_since_game_began += 1; }
get_inputs_for_next_frame();