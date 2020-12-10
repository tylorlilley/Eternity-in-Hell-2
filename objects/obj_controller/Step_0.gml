if (!game_has_been_lost() && !game_has_been_won()) {
    // Play map Sound Effects
    if keyboard_check_pressed(vk_space) { audio_play_sound( snd_pickup, 10, false ); }
    if keyboard_check_released(vk_space) { audio_play_sound( snd_putdown, 10, false ); }
    if keyboard_check(vk_space) { points -= 1/game_get_speed(gamespeed_fps); }
    
    // Update per frame values
    points -= 1/game_get_speed(gamespeed_fps);
    if (game_has_been_lost()) { audio_play_sound( snd_lose, 10, false ); }
    number_of_frames_since_game_began += 1
	
	// Update background
	bg_color = make_color_rgb(floor(get_scaling_amount(20, 255, power(1-(points/INITIAL_SCORE), 8), 1)), 20, 20);
	layer_background_blend( background_id,  bg_color );
}
else if (game_has_been_lost()) { points = 0; }

// Handle room transition blackout to get around macOS drawing bug
if (blackout && !transition) { transition = true; }
else if (blackout && transition) {
	entered_from_stairs = (blackout == 4);
	current_room = global.controller.current_room.adj_rooms[blackout]; 
	room_goto(current_room.room_reference);
	blackout = noone;
	transition = false;
}
