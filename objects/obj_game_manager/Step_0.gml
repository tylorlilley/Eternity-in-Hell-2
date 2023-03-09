// Run step events of game objects
var player = global.player, can_process = can_process_this_frame();

// Restart Game While Paused
if (paused) {
	if (key_z && key_x && key_enter_released) { return_to_title_screen(); exit; }
}
else {
	// Do Step Events
	for (var i = 0; i < 3; i ++;) {
		if (can_process) { with (player) { event_user(i); } }
		with (obj_game_object) { 
			if ((!is_existing_instance(player) || id != player.id) &&
				(can_process || object_index == obj_fireball)) { event_user(i); } 
		}
		with (obj_light_source) { event_user(i); }
		with (obj_controller) { event_user(i); }
	}
}
	
/// Pause or Unpause Game
if (key_enter_released && (instance_number(obj_title) > 0 || can_process)) {
	if (!paused) {
		if (instance_number(obj_title) == 0) {
			if (is_game_won() || is_game_lost() || is_time_up()) { return_to_title_screen(); exit; }
			else { 
				paused = true; 
				play_sound(snd_pickup, false); 
				with (obj_fireball) { speed = 0; }
			}
		}
	}
	else { 
		paused = false; 
		escaped = false;
		play_sound(snd_putdown, false); 
		with (obj_fireball) { speed = 2; }
	}
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
	var window_scaling = (global.fullscreen) ? global.max_window_scaling : global.window_scaling;
	var window_width = (global.fullscreen) ? display_width : (room_width * window_scaling);
	var window_height = (global.fullscreen) ? display_height : (room_height * window_scaling);
	
	window_set_size(window_width + gameframe_offset, window_height + gameframe_caption_height_normal + gameframe_offset);
	window_center();
}
gameframe_update();
set_up_inputs_for_next_frame();
	