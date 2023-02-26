/// @description Step
if (x < 0 && y < 0 && !activated) { teleport_to_player(); }

if (spawn_timer > 0) { spawn_timer -= 1;  }
else if (spawn_timer == 0) {
	// Move in a random direction, and turn toward player if that direction is away from player.
	move_toward_player(true, true, 4);
	if (get_coin_flip()) { play_sound(snd_flicker, false); }
		
	// Become lethal if time is up and it is not lethal yet
	if (!activated) { 
	    play_sound(snd_static, false);
	    activated = true;
	}
}

// If room becomes fully lit, destroy self
if (global.controller.current_room.lit) { 
	if (spawn_timer >= 0) { play_sound(snd_impact, false); screen_flash(); instance_destroy(); }
}
	
if (spawn_timer > 0) { activated = false; }

event_inherited();