/// @description Step
if (x < 0 && y < 0 && !activated) { teleport_to_player(); }

if (!start_timer) {
	if (spawn_timer > 0 && (global.player.x != get_exit_x_pos(global.controller.entered_from_dir) || global.player.y != get_exit_y_pos(global.controller.entered_from_dir))) { 
		start_timer = true; 
		play_sound(snd_dread, false); 
	}
}
else {
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
}

// If room becomes fully lit, destroy self
if (global.controller.current_room.lit) { 
	if (spawn_timer >= 0) {
		audio_stop_sound(snd_dread);
		play_sound(snd_impact, false); 
		screen_flash(); 
		instance_destroy();
		update_kill_log(object_index, global.difficulty, object_index);
	}
}
	
if (spawn_timer > 0) { activated = false; }

event_inherited();

if (spawn_timer > 0 && start_timer) { visible = get_coin_flip(); turn_to_face_player(); }
image_index = (activated) ? 2 : 0;