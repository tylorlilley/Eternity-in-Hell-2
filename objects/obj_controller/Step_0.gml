if (number_of_frames_since_game_began % 6 == 0) {
	if (!game_has_been_lost() && !game_has_been_won()) {
	    // Play map Sound Effects
	    if key_space_pressed { audio_play_sound( snd_pickup, 10, false ); }
	    if key_space_released { audio_play_sound( snd_putdown, 10, false ); }
	    if key_space { points -= 1/game_get_speed(gamespeed_fps); }
    
	    // Update per frame values
	    points -= 1/game_get_speed(gamespeed_fps);
	    if (game_has_been_lost()) { audio_play_sound( snd_lose, 10, false ); }
	
		// Update background
		bg_color = make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(points/INITIAL_SCORE), 8), 1)), 20, 20);
		layer_background_blend( background_id,  bg_color );
		
		// Handle room transition blackout to get around macOS drawing bug
		if (transition != noone && !blackout) { blackout = true; }
		else if (transition != noone && blackout) {
			transition_to_room();
		}
		
		// Restart game if necessary
		if key_enter_released { game_restart(); }
	}
	else if (game_has_been_lost()) { points = 0; }
	
	clear_inputs_for_next_frame();
}

if (!game_has_been_lost() && !game_has_been_won()) { number_of_frames_since_game_began += 1; }
get_inputs_for_next_frame();