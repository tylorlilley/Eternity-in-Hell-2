var game_manager = global.game_manager;
var key_x = game_manager.key_x, key_x_pressed = game_manager.key_x_pressed, key_x_released = game_manager.key_x_released;
var key_z = game_manager.key_z, key_z_pressed = game_manager.key_z_pressed, key_enter_released = game_manager.key_enter_released;
var key_space = game_manager.key_space, key_space_pressed = game_manager.key_space_pressed, key_space_released = game_manager.key_space_released;
var key_left_pressed = game_manager.key_left_pressed, key_right_pressed = game_manager.key_right_pressed , key_up_pressed = game_manager.key_up_pressed, key_down_pressed = game_manager.key_down_pressed;

if (pos == -2) {
	can_access_farmer_mode = (get_win_count(difficulties.very_hard) > 0)
	pos = (can_access_farmer_mode) ? -1 : 0;
}

if (blink_timer == 0) {
	blink = !blink;
	blink_timer = 15;
}
else { blink_timer -= 1; }

if (options_screen) {
	determine_gamepad();
	
	// Move Up and Down Through Option Selections
	if ((key_up_pressed) && (options_pos > 0)) { options_pos -= 1; play_sound(snd_mana, false); }
	else if (key_down_pressed && (options_pos < 6)) { options_pos += 1; play_sound(snd_mana, false); }
	
	// Adjust Fullscreen vs Window
	if (options_pos == 0) {
		if (!global.fullscreen && key_left_pressed) { 
			global.fullscreen = true; 
			play_sound(snd_pickup, false);		
			update_setting("fullscreen", global.fullscreen);
			set_window_size(); 
		}
		else if (global.fullscreen && key_right_pressed) { 
			global.fullscreen = false; 
			play_sound(snd_putdown, false);	
			update_setting("fullscreen", global.fullscreen);
			set_window_size(); 
		}
		else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
	}
	
	// Adjust Pixel Scaling Option
	if (options_pos == 1) {
		if (global.window_scaling > 1 && key_left_pressed) { 
			global.window_scaling -= 1; 
			play_sound(snd_move, false);
			update_setting("window_size", global.window_scaling);
			set_window_size();
		}
		else if (global.window_scaling < global.max_window_scaling && key_right_pressed) { 
			global.window_scaling += 1; 
			play_sound(snd_move, false);
			update_setting("window_size", global.window_scaling);
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
		update_setting("input", global.input);
	}
	
	// Adjust Screen Flash Option
	if (options_pos == 3) {
		if (!global.can_screen_flash && key_left_pressed) { global.can_screen_flash = true; play_sound(snd_pickup, false); }
		else if (global.can_screen_flash && key_right_pressed) { global.can_screen_flash = false; play_sound(snd_putdown, false); }
		else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
		update_setting("can_screen_flash", global.can_screen_flash);
	}
	
	// Adjust Lava Edge Type Option
	if (options_pos == 4) {
		if (global.lava_edge_type > lava_edge_types.none && key_left_pressed) { 
			global.lava_edge_type -= 1; 
			play_sound(snd_move, false);
			with (obj_lava) { set_up_lava_edge_visibility(true); }
		}
		else if (global.lava_edge_type < lava_edge_types.wavy_animated && key_right_pressed) { 
			global.lava_edge_type += 1; 
			play_sound(snd_move, false); 
			with (obj_lava) { set_up_lava_edge_visibility(true); }
		}
		else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
		update_setting("lava_edge_type", global.lava_edge_type);
	}
	
	// Adjust Color Option
	if (options_pos == 5) {
		if (keyboard_check_pressed(vk_backspace)) { 
			if (global.game_color_string != "") {
				global.game_color_string = string_delete(global.game_color_string, string_length(global.game_color_string), 1);
				play_sound(snd_move, false);
			}
			else { play_sound(snd_crunch, false); }
		}
		else if (keyboard_check_pressed(vk_delete)) {
			global.game_color_string = "";
			play_sound(snd_crunch, false);
		}
		else if (string_length(global.game_color_string) < 6) {
			if (keyboard_check_pressed(ord("1"))) { global.game_color_string += "1"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("2"))) { global.game_color_string += "2"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("3"))) { global.game_color_string += "3"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("4"))) { global.game_color_string += "4"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("5"))) { global.game_color_string += "5"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("6"))) { global.game_color_string += "6"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("7"))) { global.game_color_string += "7"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("8"))) { global.game_color_string += "8"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("9"))) { global.game_color_string += "9"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("A"))) { global.game_color_string += "A"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("B"))) { global.game_color_string += "B"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("C"))) { global.game_color_string += "C"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("D"))) { global.game_color_string += "D"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("E"))) { global.game_color_string += "E"; play_sound(snd_move, false);  }
			else if (keyboard_check_pressed(ord("F"))) { global.game_color_string += "F"; play_sound(snd_move, false);  }
			if (global.game_color_string != "" && keyboard_check_pressed(ord("0"))) { global.game_color_string += "0"; play_sound(snd_move, false); }
		}
		else {
			if (keyboard_check_pressed(ord("1"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("2"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("3"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("4"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("5"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("6"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("7"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("8"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("9"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("A"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("B"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("C"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("D"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("E"))) { play_sound(snd_locked, false);  }
			else if (keyboard_check_pressed(ord("F"))) { play_sound(snd_locked, false);  }
		}
		set_game_color();
		update_setting("game_color", global.game_color_string);
	}
	
	// Adjust Minimum Fade Option
	if (options_pos == 6) {
		if (global.game_color_fade > 0 && key_left_pressed) { global.game_color_fade -= 2; play_sound(snd_move, false); }
		else if (global.game_color_fade < 100 && key_right_pressed) { global.game_color_fade += 2; play_sound(snd_move, false); }
		else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
		update_setting("game_color_fade", global.game_color_fade);
	}
	
	// Reset settings when x is pressed
	if (key_z_pressed) {
		play_sound(snd_stairs, false);
		reset_settings_to_defaults();
	}
}
else {
	// Make sounds for space bar
	if (key_space_pressed && !death_log_screen) { play_sound(snd_pickup, false); controls_screen = true; }
	else if (key_space_released && controls_screen) { play_sound(snd_putdown, false); controls_screen = false; }

	// Make sounds for X key
	var completed_attempts_count = get_total_death_count(global.difficulty) + get_win_count(global.difficulty);
	if (completed_attempts_count > 0) {
		if (key_x_pressed && !controls_screen) { play_sound(snd_pickup, false); death_log_screen = true; }
		else if (key_x_released && death_log_screen) { play_sound(snd_putdown, false); death_log_screen = false; }
	}
	else if (key_x_pressed) { play_sound(snd_locked, false); }

	// Draw main title screen
	if (controls_screen || ((pos > 0 && death_log_screen) && completed_attempts_count > 0)) {
		// do nothing
	}
	else {
		// Adjust selected setting
		var can_access_seed_options = global.is_test_mode;
		if (key_up_pressed && (pos > 0 || (pos > -1 && can_access_farmer_mode))) { pos -= 1; play_sound(snd_mana, false); }
		else if (key_down_pressed && (pos < ((can_access_seed_options) ? 1 : 0) || (pos < 2 && global.seed_option == seed_options.specified))) { pos += 1; play_sound(snd_mana, false); }
	
		// Adjust Farmer Mode Settings
		var prev_difficulty = global.difficulty;
		if (pos == -1) {
			if (global.is_farm_mode && key_left_pressed) { global.is_farm_mode = false; play_sound(snd_putdown, false); }
			else if (!global.is_farm_mode && key_right_pressed) { global.is_farm_mode = true; play_sound(snd_pickup, false); }
			update_setting("extra_mode", global.is_farm_mode);
		}

		// Adjust Difficulty Settings
		var prev_difficulty = global.difficulty;
		if (pos == 0) {
			if (global.difficulty > difficulties.easy && key_left_pressed && !death_log_screen) { global.difficulty -= 1; }
			else if (global.difficulty < get_max_difficulty() && key_right_pressed && !death_log_screen) { global.difficulty += 1; }
			else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			if (prev_difficulty != global.difficulty) {
				var difficulty_sound = noone;
				switch (global.difficulty) {
					case difficulties.easy: { difficulty_sound = snd_pickup; break; }
					case difficulties.medium: { difficulty_sound = snd_putdown; break; }
					case difficulties.hard: { difficulty_sound = snd_skeletonrise; break; }
					case difficulties.very_hard: { difficulty_sound = snd_spider; break; }
				}
				if (difficulty_sound) { play_sound(difficulty_sound, false); }
			}
			update_setting("difficulty", global.difficulty);
		}

		// Adjust Seed Option Settings
		else if (pos == 1) {
			if ((global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) && key_left_pressed) { global.seed_option -= 1; play_sound(snd_mana, false); }
			else if (global.seed_option < seed_options.specified && key_right_pressed) { global.seed_option += 1; play_sound(snd_mana, false); }
			else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			update_setting("seed_option", global.seed_option);
		}

		// Adjust Seed Manually
		if (current_seed == noone) { current_seed = global.seed ? global.seed : irandom_range(0, MAX_SEED); }
		if (pos == 2) {
			if (keyboard_check_pressed(vk_backspace)) { 
				if (current_seed > 0) {
					current_seed = floor(current_seed / 10); 
					play_sound(snd_move, false);
				}
				else { play_sound(snd_crunch, false); }
			}
			else if (keyboard_check_pressed(vk_delete)) { 
				current_seed = 0;
				play_sound(snd_crunch, false);
			}
			else if (current_seed > 0 && key_left_pressed) { current_seed -= 1; play_sound(snd_move, false); }
			else if (current_seed < MAX_SEED && key_right_pressed) { current_seed += 1; play_sound(snd_move, false); }
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
					if (current_seed < MAX_SEED) {
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
			else if (global.seed_option == seed_options.rand) { global.seed = irandom_range(0, MAX_SEED); }
			update_setting("last_seed", global.seed);
			room_goto(rm_start);
		}
	}
}

// Switch Between Options Menu
if (key_x_pressed && options_screen) { 
	play_sound(snd_putdown, false); 
	with (obj_lava) { instance_destroy(); } 
	options_screen = false;
}
else if (key_z_pressed && !options_screen && !death_log_screen && !controls_screen){ 
	play_sound(snd_pickup, false); 
	instance_create(184+56, 136, obj_lava); 
	with (obj_lava) { initialize_lava(); set_up_lava_edge_visibility(true); }
	options_screen = true;
}