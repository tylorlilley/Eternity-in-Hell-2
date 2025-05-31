// Run step events of game objects
var player = global.player, can_process = can_process_this_frame();

// Restart Game While Paused
if (paused) {
	if (key_z && key_x && key_enter_released) {
		with (global.controller) {
			killed_by = obj_player;
			update_kill_log(obj_player, global.difficulty, obj_player);
			update_death_log(killed_by, global.difficulty, false);
		}
		return_to_title_screen(); 
		exit; 
	}
}
else {
	// Do Step Events
	for (var i = 0; i < 3; i ++;) {
		if (can_process) { with (player) { event_user(i); } }
		with (obj_game_object) { 
			if ((!is_existing_instance(player) || id != player.id) &&
				(can_process || object_is_ancestor(object_index, obj_projectile))) { event_user(i); } 
		}
		with (obj_light_source) { event_user(i); }
		with (obj_controller) { event_user(i); }
	}
	// Make clock sound
	var has_clock = false;
	with (player) { has_clock = is_carrying_item(obj_clock); }
	if (has_clock && number_of_frames_since_game_began % 100*FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) {
		play_sound(snd_clock_tick, false);
	}
}
	
/// Pause or Unpause Game
if (paused && key_esc_released) { game_end(); }
else if (!paused) {
	if (key_esc_released) {
		paused = true;
		key_esc_released = false; 
		play_sound(snd_pickup, false); 
		with (obj_projectile) { prev_speed = speed; speed = 0; }
	}
	else if (key_enter_released && instance_number(obj_title) == 0 && can_process && number_of_frames_since_game_began > 6) {
		var carried_rosary = noone;
		with (player) { carried_rosary = get_carried_item(obj_rosary); }
		if (room == rm_finish) {
			return_to_title_screen(); 
			exit; 
		}
		else if (!player.dead || carried_rosary) { 
			paused = true; 
			play_sound(snd_pickup, false); 
			with (obj_projectile) { prev_speed = speed; speed = 0; }
		}
	}
}
else if (paused && key_enter_released && (instance_number(obj_title) > 0 || can_process)) {
	paused = false;
	play_sound(snd_putdown, false); 
	with (obj_projectile) { speed = prev_speed; }
}

// Update input variables
if (instance_number(obj_title) > 0 || number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) { 
	clear_inputs_for_next_frame(); 
	with (obj_player) { moved_by = noone; }
}

// Update frame count
number_of_frames_since_game_began += 1;

if (resize_timer > 0) { 
	resize_timer -= 1;
	var display_width = display_get_width(), display_height = display_get_height(); 
	var window_scaling = (global.fullscreen) ? global.fullscreen_window_scaling : global.window_scaling;
	var window_width = (global.fullscreen) ? display_width : (room_width * window_scaling);
	var window_height = (global.fullscreen) ? display_height : (room_height * window_scaling);
	
	window_set_size(window_width + gameframe_offset, window_height + gameframe_caption_height_normal + gameframe_offset);
	window_center();
}
if (os_type == os_windows) { gameframe_update(); }
set_up_inputs_for_next_frame();
	