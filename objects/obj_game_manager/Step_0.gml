// Each frame, the game manager runs the game objects' step events, handles pausing and quitting, then updates the
// frame count, the window and the inputs
var _player = global.player, _can_process = can_process_this_frame();

// While paused, Z + X + Enter quits the run. The logs count that as the player's own death, a lost run, and the game
// returns to the title screen
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
	// Run every object's begin step, step and end step (user events 0 to 2), each for all objects before the next. The
	// player and the other game objects run only on game updates, except projectiles, which run every frame. Light sources
	// and the controller run every frame too, after them.
	for (var _i = 0; _i < 3; _i ++;) {
		if (_can_process) { with (_player) { event_user(_i); } }
		with (obj_game_object) { 
			if ((!is_existing_instance(_player) || id != _player.id) &&
				(_can_process || object_is_ancestor(object_index, obj_projectile))) { event_user(_i); } 
		}
		with (obj_light_source) { event_user(_i); }
		with (obj_controller) { event_user(_i); }
	}
	// While the player carries a clock, it ticks once every 100 game updates
	var _has_clock = false;
	with (_player) { _has_clock = is_carrying_item(obj_clock); }
	if (_has_clock && (number_of_frames_since_game_began % (100*FRAMES_TO_WAIT_BEFORE_PROCESSING) == 0)) {
		play_sound(snd_clock_tick, false);
	}
}
	
// Escape pauses the game, or quits the program if it is already paused. Enter pauses and unpauses the game too
if (paused && key_esc_released) { game_end(); }
else if (!paused) {
	if (key_esc_released) {
		paused = true;
		// Clear the key release, or the next frame would read it as Escape pressed while paused, which quits the program
		key_esc_released = false; 
		play_sound(snd_pickup, false); 
		// Freeze the projectiles, remembering their speeds for when the game is unpaused
		with (obj_projectile) { prev_speed = speed; speed = 0; }
	}
	else if (key_enter_released && instance_number(obj_title) == 0 && _can_process && number_of_frames_since_game_began > 6) {
		// Enter pauses the game on a game update, except on the title screen and in a game's first few frames. On the finish
		// screen it returns to the title screen instead, and a dead player can pause only while carrying a rosary.
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
	// Enter unpauses the game, and the projectiles carry on at the speeds they had
	paused = false;
	play_sound(snd_putdown, false); 
	with (obj_projectile) { speed = prev_speed; }
}

// After each game update (and every frame on the title screen), clear the inputs that built up since the last one
// and reset what moved the player
if (instance_number(obj_title) > 0 || number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) { 
	clear_inputs_for_next_frame(); 
	with (obj_player) { moved_by = noone; }
}

// Update frame count
number_of_frames_since_game_began += 1;

// For the steps after set_window_size sets resize_timer, fit the window to the game at its scaling (or to the display
// in fullscreen) and center it
if (resize_timer > 0) { 
	resize_timer -= 1;
	var _display_width = display_get_width(), _display_height = display_get_height(); 
	var _window_scaling = (global.fullscreen) ? global.fullscreen_window_scaling : global.window_scaling;
	var _window_width = (global.fullscreen) ? _display_width : (room_width * _window_scaling);
	var _window_height = (global.fullscreen) ? _display_height : (room_height * _window_scaling);
	
	window_set_size(_window_width + gameframe_offset, _window_height + gameframe_caption_height_normal + gameframe_offset);
	window_center();
}
// On Windows, let the GameFrame library update its custom window frame
if (os_type == os_windows) { gameframe_update(); }
// Read the controls into the input variables for the next frame, adding to any inputs not yet cleared
set_up_inputs_for_next_frame();
	