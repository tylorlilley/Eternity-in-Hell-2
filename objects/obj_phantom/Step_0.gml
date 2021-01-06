if (process_this_frame()) {
	if (spawn_timer > 0) { spawn_timer -= 1;  }
	else if (spawn_timer == 0) {
	    // Move in a random direction, and turn toward player if that direction is away from player.
	    var dir = irandom(4);
	    if (!is_direction_toward_player(dir)) { dir = opposite_dir(dir); }
	    if (can_move_in_direction(dir, true, true)) { move_in_direction(dir); }
	    if (get_random_chance_out_of(2)) { audio_play_sound( snd_flicker, 10, false ); }
		
		// Become lethal if time is up and it is not lethal yet
	    if (!lethal) { 
	        audio_play_sound_for_object_only_once( snd_static );
	        lethal = true;
	    }
	}

	if (global.controller.current_room.lit) { audio_play_sound_for_object_only_once( snd_impact ); instance_destroy(); }

	event_inherited();
}