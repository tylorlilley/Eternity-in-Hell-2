if (process_this_frame()) {
	if (spawn_timer > 0) { spawn_timer -= 1;  }
	else if (spawn_timer == 0) {
	    // Move in a random direction, and turn toward player if that direction is away from player.
	    var dir = irandom(4);
	    if (!is_direction_toward(dir, global.player)) { dir = get_opposite_dir(dir); }
	    if (can_move_in_direction(dir, true, true)) { move_in_direction(dir, false); }
	    if (get_coin_flip()) { play_sound(snd_flicker, false); }
		
		// Become lethal if time is up and it is not lethal yet
	    if (!activated) { 
	        play_sound(snd_static, false);
	        activated = true;
	    }
	}

	// If room becomes fully lit, destroy self
	if (global.controller.current_room.lit) { 
		if (spawn_timer >= 0) { play_sound(snd_impact, false); instance_destroy(); }
	}
	
	if (spawn_timer > 0) { activated = false; }

	event_inherited();
}