if (process_this_frame()) {
	if (instance_at_coordinates(x, y, global.player)) {
	    if (instance_number(obj_collectable) == 1) {
	        // You are collecting the final collectable in the room
	        global.controller.current_room.collectables_collected = true;
	        global.controller.rooms_with_collectables_collected += 1;
	        if (game_has_been_won()) { audio_play_sound( snd_win, 10, false ); }
	    }
	    instance_destroy();
	    audio_play_sound( snd_mana, 10, false );
	}

	// If this is a moving collectable, choose a random direction and move in that 
	// direction or its opposite if the opposite is away from the player
	if moving { 
	    var dir = irandom(3);
	    if (is_direction_toward_player(dir)) { dir = opposite_dir(dir); }
	    if (get_random_chance_out_of(3)) { dir = 4; }
	    if (can_move_in_direction(dir, false, false)) { move_in_direction(dir); }
	}

	event_inherited();
}

