if (process_this_frame()) {
	if (spawn_timer > 0) { spawn_timer -= 1;  }
	else if (spawn_timer == 0) {
	    // Move in a random direction, and turn toward player if that direction is away from player.
	    var dir = irandom(4);
	    if (!is_direction_toward(dir, global.player)) { dir = opposite_dir(dir); }
	    if (can_move_in_direction(dir, true, true)) { move_in_direction(dir, false); }
	    if (get_random_chance_out_of(2)) { play_sound(snd_flicker, false); }
		
		// Become lethal if time is up and it is not lethal yet
	    if (!lethal) { 
	        play_sound(snd_static, false);
	        lethal = true;
	    }
	}

	if (global.controller.current_room.lit) { 
		if (spawn_timer >= 0) { play_sound(snd_impact, false) }; 
		instance_destroy(); 
	}

	event_inherited();
	
	if (spawn_timer > 0) { visible = false; }
}