clear_inputs_for_next_frame();
set_up_inputs_for_next_frame();

if (pos == -2) { 
	global.can_access_farmer_mode = (get_win_count(difficulties.very_hard) > 0);
	pos = (global.can_access_farmer_mode) ? -1 : 0;
}

if (blink_timer == 0) {
	blink = !blink;
	blink_timer = 15;
}
else { blink_timer -= 1; }

// Make Sounds for X key
if (key_x_pressed) {
	if (options_screen) { play_sound(snd_putdown, false); }
	else { play_sound(snd_pickup, false); }
	options_screen = !options_screen;
}

if (options_screen) {
	determine_gamepad();
	
	// Move Up and Down Through Option Selections
	if ((key_up_pressed) && (options_pos > 0)) { options_pos -= 1; play_sound(snd_mana, false); }
	else if (key_down_pressed && (options_pos < 2)) { options_pos += 1; play_sound(snd_mana, false); }
	
	// Adjust Fullscreen vs Window
	if (options_pos == 0) {
		if (!window_get_fullscreen() && key_left_pressed) { window_set_fullscreen(true); play_sound(snd_putdown, false); }
		else if (window_get_fullscreen() && key_right_pressed) { window_set_fullscreen(false); play_sound(snd_pickup, false); }
		else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
	}
	
	// Adjust Pixel Scaling Option
	if (options_pos == 1) {
		if (global.window_scaling > 1 && key_left_pressed) { 
			global.window_scaling -= 1; 
			play_sound(snd_move, false); 
			set_window_size();
		}
		else if (global.window_scaling < global.max_window_scaling && key_right_pressed) { 
			global.window_scaling += 1; 
			play_sound(snd_move, false);
			set_window_size();
		}
		else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
	}
	
	// Adjust Control Option
	if (options_pos == 2) {
		if (global.input > 0 && key_left_pressed) { 
			global.input -= 1; 
			play_sound(snd_move, false);
		}
		else if ((global.input < 1 || (global.input == 1 && gamepad_is_connected(global.gamepad))) && key_right_pressed) {
			global.input += 1; 
			play_sound(snd_move, false);
		}
		else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
	}
}
else {
	// Make sounds for space bar
	if (key_space_pressed) { play_sound(snd_pickup, false); }
	else if (key_space_released) { play_sound(snd_putdown, false); }

	// Make sounds for Z key
	var completed_attempts_count = get_total_death_count(global.difficulty) + get_win_count(global.difficulty);
	if (completed_attempts_count > 0) {
		if (key_z_pressed) { play_sound(snd_pickup, false); }
		else if (key_z_released) { play_sound(snd_putdown, false); }
	}
	else if (key_z_pressed) { play_sound(snd_locked, false); }

	// Draw main title screen
	if (key_space || ((pos > 0 && key_z) && completed_attempts_count > 0)) {
		// do nothing
	}
	else {
		// Adjust selected setting
		var can_access_seed_options = global.TEST_MODE;
		if (key_up_pressed && (pos > 0 || (pos > -1 && global.can_access_farmer_mode))) { pos -= 1; play_sound(snd_mana, false); }
		else if (key_down_pressed && (pos < ((can_access_seed_options) ? 1 : 0) || (pos < 2 && global.seed_option == seed_options.specified))) { pos += 1; play_sound(snd_mana, false); }
	
		// Adjust Farmer Mode Settings
		var prev_difficulty = global.difficulty;
		if (pos == -1) {
			if (global.FARM_MODE && key_left_pressed) { global.FARM_MODE = false; play_sound(snd_putdown, false); }
			else if (!global.FARM_MODE && key_right_pressed) { global.FARM_MODE = true; play_sound(snd_pickup, false); }
		}

		// Adjust Difficulty Settings
		var prev_difficulty = global.difficulty;
		if (pos == 0) {
			if (global.difficulty > difficulties.easy && key_left_pressed) { global.difficulty -= 1; }
			else if (global.difficulty < get_max_difficulty() && key_right_pressed) { global.difficulty += 1; }
			else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			if (prev_difficulty != global.difficulty) {
				var difficulty_sound = noone;
				switch (global.difficulty) {
					case difficulties.easy: { difficulty_sound = snd_pickup; break; }
					case difficulties.medium: { difficulty_sound = snd_putdown; break; }
					case difficulties.hard: { difficulty_sound = snd_skeletonrise; break; }
					case difficulties.very_hard: { difficulty_sound = snd_lose; break; }
				}
				if (difficulty_sound) { play_sound(difficulty_sound, false); }
			}
		}

		// Adjust Seed Option Settings
		else if (pos == 1) {
			if ((global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) && key_left_pressed) { global.seed_option -= 1; play_sound(snd_mana, false); }
			else if (global.seed_option < seed_options.specified && key_right_pressed) { global.seed_option += 1; play_sound(snd_mana, false); }
			else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
		}

		// Adjust Seed Manually
		if (current_seed == noone) { current_seed = global.seed ? global.seed : irandom_range(0,99999999); }
		else if (pos == 2) {
			if (keyboard_check_pressed(vk_backspace)) { 
				if (current_seed > 0) {
					current_seed = floor(current_seed / 10); 
					play_sound(snd_move, false);
				}
				else { play_sound(snd_crunch, false); }
			}
			else if (current_seed > 0 && key_left_pressed) { current_seed -= 1; play_sound(snd_move, false); }
			else if (current_seed < 99999999 && key_right_pressed) { current_seed += 1; play_sound(snd_move, false); }
			else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			else {
				var new_number = noone;
				if (keyboard_check_pressed(ord("1"))) { new_number = 1; }
				else if (keyboard_check_pressed(ord("2"))) { new_number = 2; }
				else if (keyboard_check_pressed(ord("3"))) { new_number = 3; }
				else if (keyboard_check_pressed(ord("4"))) { new_number = 4; }
				else if (keyboard_check_pressed(ord("5"))) { new_number = 5; }
				else if (keyboard_check_pressed(ord("6"))) { new_number = 6; }
				else if (keyboard_check_pressed(ord("7"))) { new_number = 7; }
				else if (keyboard_check_pressed(ord("8"))) { new_number = 8; }
				else if (keyboard_check_pressed(ord("9"))) { new_number = 9; }
				else if (keyboard_check_pressed(ord("0"))) { new_number = 0; }
				if (new_number != noone) {
					if (current_seed < 99999999) {
						current_seed = (current_seed * 10) + new_number;
						play_sound(snd_move, false);
					}
					else { play_sound(snd_crunch, false); }
				}
			}
		}
	
		// Start Game
		if (key_enter_released) { loading = true; }
		else if (loading) {
			play_sound(snd_move, false);
			if (global.seed_option == seed_options.specified) { global.seed = current_seed; }
			else if (global.seed_option == seed_options.rand) { global.seed = irandom_range(0,99999999); }
			room_goto(rm_start);
		}
	}
}
