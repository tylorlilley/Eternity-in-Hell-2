var game_manager = global.game_manager;

if (!game_manager.paused) {
	var key_back_pressed = game_manager.key_x_pressed;
	var key_select_pressed = game_manager.key_z_pressed;
	var key_start_pressed = game_manager.key_enter_released;
	var key_left_pressed = game_manager.key_left_pressed, key_right_pressed = game_manager.key_right_pressed , key_up_pressed = game_manager.key_up_pressed, key_down_pressed = game_manager.key_down_pressed;

	
	// Set Initial Menu Position
	if (pos == -2) {
		update_hand_options();
		if (get_setting_for_difficulty("extra_mode", global.difficulty, false)) { pos = -1; }
		else if (get_max_difficulty() == difficulties.easy) { pos = 1; }
		else { pos = 0; }
	}
	
	// Handle X Key
	if (key_back_pressed) {
		if (controls_screen || options_screen || death_log_screen || prepare_screen) {
			play_sound(snd_putdown, false); 
			prepare_screen = false;
			controls_screen = false;
			options_screen = false;
			death_log_screen = false;
			options_pos = 0;
			death_log_pos = 0;
			with (obj_lava) { instance_destroy(); } 
		}
		else { play_sound(snd_locked, false); }
	}
	
	// Start Game From Prepare Screen for Z and Enter Key
	else if (prepare_screen && (key_start_pressed || key_select_pressed)) { loading = true; }
	else if (loading) {
		play_sound(snd_move, false);
		
		// Update Seed Settings
		if (global.seed_option == seed_options.specified) { global.seed = current_seed; }
		else if (global.seed_option == seed_options.rand) { global.seed = irandom_range(0, MAX_SEED); }
		update_setting("last_seed", global.seed);
		
		// Update Item Hand Settings
		global.player_left_hand_item = (left_hand_pos > -1) ? hand_options[left_hand_pos] : noone;
		global.player_right_hand_item = (right_hand_pos > -1) ? hand_options[right_hand_pos] : noone;
		update_setting_for_difficulty("last_player_left_hand_item", global.difficulty, global.player_left_hand_item);
		update_setting_for_difficulty("last_player_right_hand_item", global.difficulty, global.player_right_hand_item);
		
		room_goto(rm_start);
	}
	
	// Handle Z and Enter Key
	else if (key_select_pressed || key_start_pressed) {
		var just_switched = false;
		if (!controls_screen && !options_screen && !death_log_screen && !prepare_screen) {
			if (key_start_pressed || pos >= 1) { play_sound(snd_pickup, false); }
			else if (!key_start_pressed) { play_sound(snd_locked, false); }
			prepare_screen = (key_start_pressed || pos == 1);
			options_screen = (!key_start_pressed && pos == 3);
			controls_screen = (!key_start_pressed && pos == 4);
			death_log_screen = (!key_start_pressed && pos == 5);
			if (death_log_screen) { death_log_sort = 1; just_switched = true; }  // TODO: Remember last sort?
			else if (options_screen) {
				instance_create(184+56, 152, obj_lava); 
				with (obj_lava) { initialize_tile(); set_up_lava_edge_visibility(true); }
			}
			else if (prepare_screen) { 
				update_hand_options();
				if (array_length(hand_options) < 2) { prepare_screen = false; loading = true; }
			}
		}
		if (death_log_screen) {
			// Update Sort
			death_log_sort += 1;
			if (death_log_sort > 2) { death_log_sort = 0; }
			if (!just_switched) { play_sound(snd_thud, false); }
			
			// Update Death Count Values
			var death_types = get_death_types();
			deaths_to_display = array_create(0);
			while (array_length(death_types) > 0) {
				var death_type = array_pop(death_types);
		
				var death_count = get_death_count(death_type, global.difficulty), kill_count = get_kill_count(death_type, global.difficulty), last_killed = get_last_killed(death_type, global.difficulty);
				if (death_count > 0 || kill_count > 0) { array_push(deaths_to_display, [death_type, death_count, kill_count, last_killed]); }
			}
				
			// Sort deaths to display by death count
			array_sort(deaths_to_display, function(elm1, elm2) { 
				switch (death_log_sort) {
					case 1: { return elm2[1] - elm1[1]; break; }
					case 0: { return elm2[2] - elm1[2]; break; }
					case 2: { return elm2[3] - elm1[3]; break; }
				}
			});
		}
	}
	
	// Navigate Menus
	if (prepare_screen) {
		// Toggle Selected Hand
		if (key_left_pressed && !left_hand_selected) { left_hand_selected = true; play_sound(snd_mana, false); }
		else if (key_right_pressed && left_hand_selected) { left_hand_selected = false; play_sound(snd_mana, false); }
		else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			
		// Change Selected Item
		var changed_by = 0;
		if (left_hand_selected && key_up_pressed) { changed_by = 1; left_hand_pos += changed_by; }
		else if (left_hand_selected && key_down_pressed) { changed_by = -1; left_hand_pos += changed_by; }
		else if (!left_hand_selected && key_up_pressed) { changed_by = 1; right_hand_pos += changed_by; }
		else if (!left_hand_selected && key_down_pressed) { changed_by = -1; right_hand_pos += changed_by; }
		else if (key_up_pressed || key_down_pressed) { play_sound(snd_locked, false); }
			
		// Update Selected Items
		if (changed_by != 0) {
			play_sound(snd_mana, false);
			// Wrap around to other end of selection
			var options_length = array_length(hand_options);
			if (left_hand_pos > options_length-1) { left_hand_pos -= options_length+1; }
			else if (left_hand_pos < -1) { left_hand_pos += options_length+1; }
			if (right_hand_pos > options_length-1) { right_hand_pos -= options_length+1; }
			else if (right_hand_pos < -1) { right_hand_pos += options_length+1; }
			
			// Make sure you can't select the same item
			if (left_hand_pos == right_hand_pos && left_hand_pos > -1 && right_hand_pos > -1) { 
				if (left_hand_selected) { left_hand_pos += changed_by; }
				else { right_hand_pos += changed_by; }
			}
			
			// Wrap around to other end of selection again
			var options_length = array_length(hand_options);
			if (left_hand_pos > options_length-1) { left_hand_pos -= options_length+1; }
			else if (left_hand_pos < -1) { left_hand_pos += options_length+1; }
			if (right_hand_pos > options_length-1) { right_hand_pos -= options_length+1; }
			else if (right_hand_pos < -1) { right_hand_pos += options_length+1; }
		}
	}
	else if (options_screen) {
		determine_gamepad();
	
		// Move Up and Down Through Option Selections
		if ((key_up_pressed) && (options_pos > 0)) { options_pos -= 1; play_sound(snd_mana, false); }
		else if (key_down_pressed && (options_pos < 8)) { options_pos += 1; play_sound(snd_mana, false); }
		else if (key_up_pressed || key_down_pressed) { play_sound(snd_locked, false); } 
	
		// Adjust Fullscreen vs Window
		if (options_pos == 0) {
			if (!global.fullscreen && key_left_pressed) { 
				global.fullscreen = true;
				global.window_border =  (os_type == os_windows) ? false : true;
				play_sound(snd_pickup, false);		
				update_setting("fullscreen", global.fullscreen);
				update_setting("window_border", global.window_border);
				set_window_size(); 
			}
			else if (global.fullscreen && key_right_pressed) { 
				global.fullscreen = false;
				global.window_border = true;
				play_sound(snd_putdown, false);	
				update_setting("fullscreen", global.fullscreen);
				update_setting("window_border", global.window_border);
				set_window_size(); 
			}
			else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
		}
	
		// Adjust Pixel Scaling Option and Window Border Option
		if (options_pos == 1) {
			// Adjust Window Border Option
			if (global.fullscreen && os_type == os_windows) {
				if (!global.window_border && key_left_pressed) {
					global.window_border = true;
					play_sound(snd_pickup, false);
					update_setting("window_border", global.window_border);
					set_window_size(); 
				}
				else if (global.window_border && key_right_pressed) {
					global.window_border = false;
					play_sound(snd_putdown, false);
					update_setting("window_border", global.window_border);
					set_window_size(); 
				}
				else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
			}
			// Adjust Pixel Scaling Option
			else {
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
	
		// Adjust Player Outline
		if (options_pos == 3) {
			if (!global.player_outline && key_left_pressed) { global.player_outline = true; play_sound(snd_pickup, false); }
			else if (global.player_outline && key_right_pressed) { global.player_outline = false; play_sound(snd_putdown, false); }
			else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
			update_setting("player_outline", global.player_outline);
		}
	
		// Adjust Screen Flash Option
		if (options_pos == 4) {
			if (!global.can_screen_flash && key_left_pressed) { global.can_screen_flash = true; play_sound(snd_pickup, false); }
			else if (global.can_screen_flash && key_right_pressed) { global.can_screen_flash = false; play_sound(snd_putdown, false); }
			else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
			update_setting("can_screen_flash", global.can_screen_flash);
		}
	
		// Adjust Lava Edge Type Option
		if (options_pos == 5) {
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
		if (options_pos == 6) {
			if (keyboard_check_pressed(vk_backspace)) { 
				if (global.game_color_string != "") {
					global.game_color_string = string_delete(global.game_color_string, string_length(global.game_color_string), 1);
					play_sound(snd_move, false);
				}
				else { play_sound(snd_crunch, false); }
			}
			else if (keyboard_check_pressed(vk_delete) && global.game_color_string != "") {
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
		if (options_pos == 7) {
			if (global.game_color_fade > 0 && key_left_pressed) { global.game_color_fade -= 2; play_sound(snd_move, false); }
			else if (global.game_color_fade < 100 && key_right_pressed) { global.game_color_fade += 2; play_sound(snd_move, false); }
			else if ((key_left_pressed || key_right_pressed)) { play_sound(snd_locked, false); }
			update_setting("game_color_fade", global.game_color_fade);
		}
	
		// Reset settings to default
		if (options_pos == 8 && key_select_pressed) {
			play_sound(snd_stairs, false);
			reset_settings_to_defaults();
		}
	}
	else if (controls_screen) {
		// do nothing; draw code handles lighting up sprites
	}
	else if (death_log_screen) {
		if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			
		if (key_up_pressed && death_log_pos > 0) {  death_log_pos -= 1; play_sound(snd_mana, false); }
		else if (key_down_pressed && (death_log_pos < array_length(deaths_to_display)-5)) { death_log_pos += 1; play_sound(snd_mana, false); }
		else if (key_up_pressed || key_down_pressed) { play_sound(snd_locked, false); }
	}
	else {
		// Adjust selected setting
		var completed_attempts_count = get_total_death_count(global.difficulty) + get_win_count(global.difficulty);
		var can_access_seed_options = global.is_test_mode;
		if (key_up_pressed && pos > -1) { 
			pos -= 1;
			if (pos == 2 && global.seed_option != seed_options.specified) { pos = 1; }
			if (get_max_difficulty() == difficulties.easy && pos <= 0) { pos = 1; play_sound(snd_locked, false); }
			else if (!global.is_test_mode && !get_setting_for_difficulty("extra_mode", global.difficulty, false) && pos <= -1) { pos = 0; play_sound(snd_locked, false); }
			else { play_sound(snd_mana, false); }
		}
		else if (key_down_pressed && (pos < 5)) { 
			pos += 1; 
			if (pos == 2 && global.seed_option != seed_options.specified) { pos = 3; }
			if (completed_attempts_count == 0 && pos > 4) { pos = 4; play_sound(snd_locked, false); }
			else { play_sound(snd_mana, false); }
		}
		else if (key_up_pressed || key_down_pressed) { play_sound(snd_locked, false); }
	
		// Adjust Farmer Mode Settings
		var prev_difficulty = global.difficulty;
		if (pos == -1) {			
			if (key_left_pressed && global.graphics_mode != graphics_modes.standard) {
				if (global.graphics_mode == graphics_modes.unknown) { global.graphics_mode = graphics_modes.farmer; play_sound(snd_putdown, false); }
				else { global.graphics_mode = graphics_modes.standard; play_sound(snd_putdown, false); }
			}
			else if (key_right_pressed && global.graphics_mode != graphics_modes.unknown) {
				if (global.graphics_mode == graphics_modes.standard) { global.graphics_mode = graphics_modes.farmer; play_sound(snd_pickup, false); }
				else if (can_play_unknown_mode()) { global.graphics_mode = graphics_modes.unknown; play_sound(snd_pickup, false); }
				else { play_sound(snd_locked, false); }
			}
			else if (key_left_pressed || key_right_pressed) { play_sound(snd_locked, false); }
			update_setting_for_difficulty("graphics_mode", global.difficulty, global.graphics_mode);
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
			update_hand_options();
			if (get_setting_for_difficulty("extra_mode", global.difficulty, false)) { global.graphics_mode = get_setting_for_difficulty("graphics_mode", global.difficulty, global.graphics_mode); }
			else if (global.graphics_mode != graphics_modes.standard) { global.graphics_mode = graphics_modes.standard; update_setting_for_difficulty("graphics_mode", global.difficulty, global.graphics_mode); }
		}

		// Adjust Seed Option Settings
		else if (pos == 1 && can_access_seed_options) {
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
			else if (keyboard_check_pressed(vk_delete) && current_seed != 0) { 
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
	}
}