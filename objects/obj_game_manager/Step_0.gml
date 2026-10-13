// Run step events of game objects
var _player = global.player, _can_process = can_process_this_frame();

// Restart Game While Paused
if (paused) {
	if (key_z && key_x && key_enter_released) {
		with (global.controller) {
			// Giving up counts as the player killing themselves, and saves the run without evaluating it
			killed_by = obj_player;
			record_run_kill(obj_player, obj_player);
			record_run_death(killed_by);
			run_record.save();
		}
		return_to_title_screen(); 
		exit; 
	}
}
else {
	// Do Step Events
	for (var _i = 0; _i < 3; _i ++;) {
		if (_can_process) { with (_player) { event_user(_i); } }
		with (obj_game_object) { 
			if ((!is_existing_instance(_player) || id != _player.id) &&
				(_can_process || object_is_ancestor(object_index, obj_projectile))) { event_user(_i); } 
		}
		with (obj_light_source) { event_user(_i); }
		with (obj_controller) { event_user(_i); }
	}
	// Make clock sound
	var _has_clock = false;
	with (_player) { _has_clock = is_carrying_item(obj_clock); }
	if (_has_clock && (number_of_frames_since_game_began % (100*FRAMES_TO_WAIT_BEFORE_PROCESSING) == 0)) {
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
	else if (key_enter_released && instance_number(obj_title) == 0 && _can_process && number_of_frames_since_game_began > 6) {
		var _carried_rosary = noone;
		with (_player) { _carried_rosary = get_carried_item(obj_rosary); }
		if (room == rm_finish) {
			return_to_title_screen(); 
			exit; 
		}
		else if (!_player.dead || _carried_rosary) { 
			paused = true; 
			play_sound(snd_pickup, false); 
			with (obj_projectile) { prev_speed = speed; speed = 0; }
		}
	}
}
else if (paused && key_enter_released && (instance_number(obj_title) > 0 || _can_process)) {
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

// Apply the window settings for a few frames after they change, since leaving fullscreen takes a moment (see set_window_size)
if (resize_timer > 0) {
	resize_timer -= 1;
	if (!global.fullscreen) {
		window_set_size(room_width * global.window_scaling, room_height * global.window_scaling);
		window_center();
	}
	else if (!window_get_fullscreen()) {
		// Fullscreen covers the screen with a borderless window, unless the window border setting asks for exclusive fullscreen
		window_enable_borderless_fullscreen(!global.window_border);
		window_set_fullscreen(true);
	}
}
set_up_inputs_for_next_frame();
	