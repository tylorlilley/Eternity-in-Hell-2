/// @description Step
var controller = global.controller;
if (x < 0 && y < 0 && !activated) { 
	teleport_to_player();
	if (!controller.current_room.lit && controller.entered_from_dir != directions.respawn) {
		// Check distance to each unlit lantern
		var lantern_count = 0, total_distance_to_lanterns = 0;
		for (var i = 0; i < instance_number(obj_lantern); i++) {
			var lantern = instance_find(obj_lantern, i);
		
			if (is_existing_instance(lantern) && is_existing_instance(lantern.light_source)) { continue; }
		
			lantern_count += 1;
			total_distance_to_lanterns += get_distance_to_instance(lantern) / 8.0;
		}
	
		if (lantern_count == 0) { instance_destroy(); }
		else {
			// Set spawn timer based on distance to each lantern
			spawn_timer = ceil(total_distance_to_lanterns) - (global.difficulty*lantern_count)
			if (spawn_timer > 32) { spawn_timer = 32; } 
			if (spawn_timer < 12) { spawn_timer = 12; }
			if (controller.entered_from_dir == directions.stairs) { spawn_timer += 12; }
		}
	}
}

if (!start_timer) {
	if (spawn_timer > 0 && (global.player.x != get_exit_x_pos(controller.entered_from_dir) || global.player.y != get_exit_y_pos(controller.entered_from_dir))) { 
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
if (controller.current_room.lit) { 
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