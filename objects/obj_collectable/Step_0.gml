if (process_this_frame()) {
	if (instance_at_coordinates(x, y, global.player)) {
	    if (instance_number(obj_collectable) == 1) {
	        // You are collecting the final collectable in the room
			with global.controller {
				current_room.has_collectables = false;
				array_remove(rooms_with_collectables, current_room);
				if (game_progress_has_been_completed()) { 
					audio_play_sound( snd_win, 10, false ); 
					global.controller.completion_amount += 1;
				}
			}
	    }
	    instance_destroy();
	    audio_play_sound( snd_mana, 10, false );
	}

	// If this is a moving collectable, choose a random direction and move in that 
	// direction or its opposite if the opposite is away from the player
	if moving { run_away_from_player(); }

	event_inherited();
}

