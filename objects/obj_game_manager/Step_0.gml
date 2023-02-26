// Run step events of game objects
//if (instance_number(obj_title) == 0) {
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
	if (key_enter_released && can_process && instance_number(obj_title) == 0) {
		if (!paused) {
			if (is_game_won() || is_game_lost() || is_time_up()) { return_to_title_screen(); exit; }
			else { paused = true; play_sound(snd_pickup, false); }
		}
		else { paused = false; play_sound(snd_putdown, false); }
	}
//}

// Update input variables
if (instance_number(obj_title) > 0 || number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) { 
	clear_inputs_for_next_frame(); 
	with (obj_player) { moved_by = noone; }
}

// Update frame count
number_of_frames_since_game_began += 1;
if (resize_timer > 0) {
	resize_timer -= 1;
	if (resize_timer == 0) {
		// Resize the drawing surface
		var window_scaling = global.window_scaling;
		var draw_surface_width = (room_width*window_scaling), draw_surface_height = (room_height*window_scaling)
		window_set_size(draw_surface_width, draw_surface_height);
	}
}
set_up_inputs_for_next_frame();