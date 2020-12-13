if (process_this_frame()) {
	visible = lethal

	if lethal {
	    if (!attacking && !global.player.dead) {
	        if (global.player.x == x) {
	            if (global.player.y > y) { dir = 2; }
	            else { dir = 0; }
	            attacking = true;
	        }
	        else if (global.player.y == y) {
	            if (global.player.x > x) { dir = 1; }
	            else { dir = 3; }
	            attacking = true;
	        }
	    }
    
	    if (attacking && can_move_in_direction(dir, false)) { 
	        if !screeched {
	            audio_play_sound( snd_lose, 10, false ); 
	            screeched = 1; 
	        }
	        else if screeched < 3 {
	            screeched += 1;
	        }
	        else {
	            if (can_move_in_direction(dir, false)) { move_in_direction(dir); }
	            if (can_move_in_direction(dir, false)) { move_in_direction(dir); }
	            if (global.controller.number_of_frames_since_game_began mod 12 == 0) { image_xscale *= -1; }
	        }
	    }
	    else { attacking = false; screeched = 0; }
    
	    event_inherited();
	}
}
