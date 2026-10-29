var _game_manager = global.game_manager;

if (!_game_manager.paused) {
	var _key_back_pressed = _game_manager.key_x_pressed;
	var _key_select_pressed = _game_manager.key_z_pressed;
	var _key_start_pressed = _game_manager.key_enter_released;
	var _key_left_pressed = _game_manager.key_left_pressed;
	var _key_right_pressed = _game_manager.key_right_pressed;
	var _key_up_pressed = _game_manager.key_up_pressed;
	var _key_down_pressed = _game_manager.key_down_pressed;
	
	if (_game_manager.key_up) {
		if (held_timer == 18) { _key_up_pressed = true; held_timer = 12; }
		else  { held_timer += 1; }
	}
	else if (_game_manager.key_down) {
		if (held_timer == 18) { _key_down_pressed = true; held_timer = 12; }
		else  {held_timer += 1; }
	}
	else { held_timer = 0; }
	
	// Set Initial Menu Position
	if (pos == -2) {
		update_hand_options();
		if (get_setting_for_difficulty("extra_mode", global.difficulty, false)) { pos = -1; }
		else if (get_max_difficulty() == difficulties.easy) { pos = 1; }
		else { pos = 0; }
	}
	
	// Navigate Menus
	if (prepare_screen) {
		// Toggle Selected Hand
		if (_key_left_pressed && !left_hand_selected) { left_hand_selected = true; play_sound(snd_mana, false); }
		else if (_key_right_pressed && left_hand_selected) { left_hand_selected = false; play_sound(snd_mana, false); }
		else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
			
		// Change Selected Item
		var _changed_by = 0;
		if (left_hand_selected && _key_up_pressed) { _changed_by = 1; left_hand_pos += _changed_by; }
		else if (left_hand_selected && _key_down_pressed) { _changed_by = -1; left_hand_pos += _changed_by; }
		else if (!left_hand_selected && _key_up_pressed) { _changed_by = 1; right_hand_pos += _changed_by; }
		else if (!left_hand_selected && _key_down_pressed) { _changed_by = -1; right_hand_pos += _changed_by; }
		else if (_key_up_pressed || _key_down_pressed) { play_sound(snd_locked, false); }
			
		// Update Selected Items
		if (_changed_by != 0) {
			play_sound(snd_mana, false);
			// Wrap around to other end of selection
			var _options_length = array_length(hand_options);
			if (left_hand_pos > _options_length-1) { left_hand_pos -= _options_length+1; }
			else if (left_hand_pos < -1) { left_hand_pos += _options_length+1; }
			if (right_hand_pos > _options_length-1) { right_hand_pos -= _options_length+1; }
			else if (right_hand_pos < -1) { right_hand_pos += _options_length+1; }
			
			// Make sure you can't select the same item
			if (left_hand_pos == right_hand_pos && left_hand_pos > -1 && right_hand_pos > -1) { 
				if (left_hand_selected) { left_hand_pos += _changed_by; }
				else { right_hand_pos += _changed_by; }
			}
			
			// Wrap around to other end of selection again
			_options_length = array_length(hand_options);
			if (left_hand_pos > _options_length-1) { left_hand_pos -= _options_length+1; }
			else if (left_hand_pos < -1) { left_hand_pos += _options_length+1; }
			if (right_hand_pos > _options_length-1) { right_hand_pos -= _options_length+1; }
			else if (right_hand_pos < -1) { right_hand_pos += _options_length+1; }
		}
	}
	else if (options_screen) {
		determine_gamepad();
		
		// Reset settings to default
		if (options_pos == 8 && (_key_select_pressed || _key_start_pressed)) {
			_key_select_pressed = false;
			_key_start_pressed = false;
			option_selected = false;
			play_sound(snd_stairs, false);
			reset_settings_to_defaults();
		}
		
		// Interact with Selected Option
		else if (option_selected) {
			// Adjust Fullscreen vs Window
			if (options_pos == 0) {
				if (!global.fullscreen && _key_left_pressed) { 
					global.fullscreen = true;
					global.window_border =  (os_type == os_windows) ? false : true;
					play_sound(snd_pickup, false);		
					update_setting("fullscreen", global.fullscreen);
					update_setting("window_border", global.window_border);
					set_window_size(); 
				}
				else if (global.fullscreen && _key_right_pressed) { 
					global.fullscreen = false;
					global.window_border = true;
					play_sound(snd_putdown, false);	
					update_setting("fullscreen", global.fullscreen);
					update_setting("window_border", global.window_border);
					set_window_size(); 
				}
				else if ((_key_left_pressed || _key_right_pressed)) { play_sound(snd_locked, false); }
			}
	
			// Adjust Pixel Scaling Option and Window Border Option
			if (options_pos == 1) {
				// Adjust Window Border Option
				if (global.fullscreen && os_type == os_windows) {
					if (!global.window_border && _key_left_pressed) {
						global.window_border = true;
						play_sound(snd_pickup, false);
						update_setting("window_border", global.window_border);
						set_window_size(); 
					}
					else if (global.window_border && _key_right_pressed) {
						global.window_border = false;
						play_sound(snd_putdown, false);
						update_setting("window_border", global.window_border);
						set_window_size(); 
					}
					else if ((_key_left_pressed || _key_right_pressed)) { play_sound(snd_locked, false); }
				}
				// Adjust Pixel Scaling Option
				else {
					if (global.window_scaling > 1 && _key_left_pressed) { 
						global.window_scaling -= 1; 
						play_sound(snd_move, false);
						update_setting("window_size", global.window_scaling);
						set_window_size();
					}
					else if (global.window_scaling < global.max_window_scaling && _key_right_pressed) { 
						global.window_scaling += 1; 
						play_sound(snd_move, false);
						update_setting("window_size", global.window_scaling);
						set_window_size();
					}
					else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
				}
			}
	
			// Adjust Control Option
			if (options_pos == 2) {
				if (global.input > 0 && _key_left_pressed) { 
					global.input -= 1; 
					play_sound(snd_move, false);
				}
				else if ((global.input < 1 || (global.input == 1 && gamepad_is_connected(global.gamepad))) && _key_right_pressed) {
					global.input += 1; 
					play_sound(snd_move, false);
				}
				else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
				update_setting("input", global.input);
			}
	
			// Adjust Player Outline
			if (options_pos == 3) {
				if (!global.player_outline && _key_left_pressed) { global.player_outline = true; play_sound(snd_pickup, false); }
				else if (global.player_outline && _key_right_pressed) { global.player_outline = false; play_sound(snd_putdown, false); }
				else if ((_key_left_pressed || _key_right_pressed)) { play_sound(snd_locked, false); }
				update_setting("player_outline", global.player_outline);
			}
	
			// Adjust Screen Flash Option
			if (options_pos == 4) {
				if (!global.can_screen_flash && _key_left_pressed) { global.can_screen_flash = true; play_sound(snd_pickup, false); }
				else if (global.can_screen_flash && _key_right_pressed) { global.can_screen_flash = false; play_sound(snd_putdown, false); }
				else if ((_key_left_pressed || _key_right_pressed)) { play_sound(snd_locked, false); }
				update_setting("can_screen_flash", global.can_screen_flash);
			}
	
			// Adjust Color Option
			if (options_pos == 5) {
				// Move Left and Right Through String
				if ((_key_left_pressed) && (color_options_pos > 0)) { color_options_pos -= 1; play_sound(snd_mana, false); }
				else if (_key_right_pressed && (color_options_pos < 5)) { color_options_pos += 1; play_sound(snd_mana, false); }
				else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
				
				// Modify Value
				var _current_hex_value = string_char_at(global.game_color_string, color_options_pos+1), _current_dec_value = hex_to_dec(_current_hex_value);
				if (keyboard_check_pressed(ord("1"))) { _current_hex_value = "1"; }
				else if (keyboard_check_pressed(ord("2"))) { _current_hex_value = "2"; }
				else if (keyboard_check_pressed(ord("3"))) { _current_hex_value = "3"; }
				else if (keyboard_check_pressed(ord("4"))) { _current_hex_value = "4"; }
				else if (keyboard_check_pressed(ord("5"))) { _current_hex_value = "5"; }
				else if (keyboard_check_pressed(ord("6"))) { _current_hex_value = "6"; }
				else if (keyboard_check_pressed(ord("7"))) { _current_hex_value = "7"; }
				else if (keyboard_check_pressed(ord("8"))) { _current_hex_value = "8"; }
				else if (keyboard_check_pressed(ord("9"))) { _current_hex_value = "9"; }
				else if (keyboard_check_pressed(ord("0"))) { _current_hex_value = "0"; }
				else if (keyboard_check_pressed(ord("A"))) { _current_hex_value = "A"; }
				else if (keyboard_check_pressed(ord("B"))) { _current_hex_value = "B"; }
				else if (keyboard_check_pressed(ord("C"))) { _current_hex_value = "C"; }
				else if (keyboard_check_pressed(ord("D"))) { _current_hex_value = "D"; }
				else if (keyboard_check_pressed(ord("E"))) { _current_hex_value = "E"; }
				else if (keyboard_check_pressed(ord("F"))) { _current_hex_value = "F"; }
				var _new_dec_value = hex_to_dec(_current_hex_value);
				if (_new_dec_value != _current_dec_value) { 
					play_sound(snd_move, false);
					_current_dec_value = _new_dec_value;
				}
				
				// Create New String Based on Hex Value
				var _new_hex_value = string_char_at("0123456789ABCDEF", _current_dec_value+1), _new_string = "";
				for (var _i = 0; _i < 6; _i++) {
					_new_string += (_i == color_options_pos) ? _new_hex_value : string_char_at(global.game_color_string, _i+1);
				}
				global.game_color_string = _new_string
				set_game_color();
				update_setting("game_color", global.game_color_string);
			}
	
			// Adjust Minimum Fade Option
			if (options_pos == 6) {
				if (global.game_color_fade > 0 && _key_left_pressed) { global.game_color_fade -= 2; play_sound(snd_move, false); }
				else if (global.game_color_fade < 100 && _key_right_pressed) { global.game_color_fade += 2; play_sound(snd_move, false); }
				else if ((_key_left_pressed || _key_right_pressed)) { play_sound(snd_locked, false); }
				update_setting("game_color_fade", global.game_color_fade);
			}
		
			// Adjust Lava Edge Type Option
			if (options_pos == 7) {
				if (global.lava_edge_type > lava_edge_types.none && _key_left_pressed) { 
					global.lava_edge_type -= 1; 
					play_sound(snd_move, false);
					with (obj_lava) { set_up_lava_edge_visibility(true); }
				}
				else if (global.lava_edge_type < lava_edge_types.wavy_animated && _key_right_pressed) { 
					global.lava_edge_type += 1; 
					play_sound(snd_move, false); 
					with (obj_lava) { set_up_lava_edge_visibility(true); }
				}
				else if ((_key_left_pressed || _key_right_pressed)) { play_sound(snd_locked, false); }
				update_setting("lava_edge_type", global.lava_edge_type);
			}
		}
	
		// Move Up and Down Through Option Selections
		if ((_key_up_pressed) && (options_pos > 0)) { options_pos -= 1; play_sound(snd_mana, false); }
		else if (_key_down_pressed && (options_pos < 8)) { options_pos += 1; play_sound(snd_mana, false); }
		else if (_key_up_pressed || _key_down_pressed) { play_sound(snd_locked, false); } 
		
		// Move Left and Right Through Option Selections
		if (!option_selected && options_pos < 8 && (_key_start_pressed || _key_select_pressed || _key_right_pressed)) { play_sound(snd_pickup, false); option_selected = true; color_options_pos = 5; }
		else if (option_selected && _key_back_pressed) { play_sound(snd_putdown, false); option_selected = false; _key_back_pressed = false; }
		else if ((option_selected && (_key_start_pressed || _key_select_pressed)) || (!option_selected && _key_left_pressed)) { play_sound(snd_locked, false); }
	}
	else if (controls_screen) {
		// do nothing; draw code handles lighting up sprites
	}
	else if (death_log_screen) {
		if (_key_up_pressed && death_log_pos > 0) {  death_log_pos -= 1; play_sound(snd_mana, false); }
		else if (_key_down_pressed && (death_log_pos < array_length(deaths_to_display)-death_types_on_screen)) { death_log_pos += 1; play_sound(snd_mana, false); }
		else if (_key_up_pressed || _key_down_pressed) { play_sound(snd_locked, false); }
	}
	else if (evaluation_log_screen) {
		if (_key_up_pressed && trait_surface_y_pos > 0) {  trait_surface_y_pos -= 16; play_sound(snd_mana, false); }
		else if (_key_down_pressed && (trait_surface_y_pos < trait_surface_y_max-(room_height-(16*7)))) { trait_surface_y_pos += 16; play_sound(snd_mana, false); }
		else if (_key_up_pressed || _key_down_pressed) { play_sound(snd_locked, false); }
	}
	else {
		// Adjust selected setting
		var _has_finished_a_run = has_finished_a_run(global.difficulty);
		var _can_access_seed_options = global.is_test_mode;
		if (_key_up_pressed && pos > -1) { 
			pos -= 1;
			if (pos == 2 && global.seed_option != seed_options.specified) { pos = 1; }
			if (get_max_difficulty() == difficulties.easy && pos <= 0) { pos = 1; play_sound(snd_locked, false); }
			else if (!global.is_test_mode && !get_setting_for_difficulty("extra_mode", global.difficulty, false) && pos <= -1) { pos = 0; play_sound(snd_locked, false); }
			else { play_sound(snd_mana, false); }
		}
		else if (_key_down_pressed && (pos < 6)) { 
			pos += 1; 
			if (pos == 2 && global.seed_option != seed_options.specified) { pos = 3; }
			if (!_has_finished_a_run && pos > 4 && !global.is_test_mode) { pos = 4; play_sound(snd_locked, false); }
			else { play_sound(snd_mana, false); }
		}
		else if (_key_up_pressed || _key_down_pressed) { play_sound(snd_locked, false); }
	
		// Adjust Farmer Mode Settings
		var _prev_difficulty = global.difficulty;
		if (pos == -1) {			
			if (_key_left_pressed && global.graphics_mode != graphics_modes.standard) {
				if (global.graphics_mode == graphics_modes.unknown) { global.graphics_mode = graphics_modes.farmer; play_sound(snd_putdown, false); }
				else { global.graphics_mode = graphics_modes.standard; play_sound(snd_putdown, false); }
			}
			else if (_key_right_pressed && global.graphics_mode != graphics_modes.unknown) {
				if (global.graphics_mode == graphics_modes.standard) { global.graphics_mode = graphics_modes.farmer; play_sound(snd_pickup, false); }
				else if (can_play_unknown_mode()) { global.graphics_mode = graphics_modes.unknown; play_sound(snd_pickup, false); }
				else { play_sound(snd_locked, false); }
			}
			else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
			update_setting_for_difficulty("graphics_mode", global.difficulty, global.graphics_mode);
		}

		// Adjust Seed Option Settings
		else if (pos == 1 && _can_access_seed_options) {
			if ((global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) && _key_left_pressed) { global.seed_option -= 1; play_sound(snd_mana, false); }
			else if (global.seed_option < seed_options.specified && _key_right_pressed) { global.seed_option += 1; play_sound(snd_mana, false); }
			else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
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
			else if (current_seed > 0 && _key_left_pressed) { current_seed -= 1; play_sound(snd_move, false); }
			else if (current_seed < MAX_SEED && _key_right_pressed) { current_seed += 1; play_sound(snd_move, false); }
			else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
			else {
				var _new_number = noone;
				if (keyboard_check_pressed(ord("1"))) { _new_number = 1; }
				else if (keyboard_check_pressed(ord("2"))) { _new_number = 2; }
				else if (keyboard_check_pressed(ord("3"))) { _new_number = 3; }
				else if (keyboard_check_pressed(ord("4"))) { _new_number = 4; }
				else if (keyboard_check_pressed(ord("5"))) { _new_number = 5; }
				else if (keyboard_check_pressed(ord("6"))) { _new_number = 6; }
				else if (keyboard_check_pressed(ord("7"))) { _new_number = 7; }
				else if (keyboard_check_pressed(ord("8"))) { _new_number = 8; }
				else if (keyboard_check_pressed(ord("9"))) { _new_number = 9; }
				else if (keyboard_check_pressed(ord("0"))) { _new_number = 0; }
				if (_new_number != noone) {
					if (current_seed < MAX_SEED) {
						current_seed = (current_seed * 10) + _new_number;
						play_sound(snd_move, false);
					}
					else { play_sound(snd_crunch, false); }
				}
			}
		}
	}

	if (death_log_screen || evaluation_log_screen || (!options_screen && !controls_screen && !prepare_screen)) {
		// Adjust Difficulty Settings
		var _prev_difficulty = global.difficulty;
		if (death_log_screen || evaluation_log_screen || pos == 0) {
			if ((death_log_screen || evaluation_log_screen) && global.difficulty == get_max_difficulty() && _key_right_pressed) { global.difficulty = difficulties.ALL; }
			else if ((death_log_screen || evaluation_log_screen) && global.difficulty > get_max_difficulty() && _key_left_pressed) { global.difficulty = get_max_difficulty(); }
			else if (global.difficulty > difficulties.easy && _key_left_pressed) { global.difficulty -= 1; }
			else if (global.difficulty < get_max_difficulty() && _key_right_pressed) { global.difficulty += 1; }
			else if (_key_left_pressed || _key_right_pressed) { play_sound(snd_locked, false); }
			
			if (_prev_difficulty != global.difficulty) {
				var _difficulty_sound = noone;
				switch (global.difficulty) {
					case difficulties.easy: { _difficulty_sound = snd_pickup; break; }
					case difficulties.medium: { _difficulty_sound = snd_putdown; break; }
					case difficulties.hard: { _difficulty_sound = snd_skeletonrise; break; }
					case difficulties.very_hard: { _difficulty_sound = snd_spider; break; }
					case difficulties.ALL: { _difficulty_sound = snd_magic; break; }
				}
				if (_difficulty_sound) { play_sound(_difficulty_sound, false); }
				
				update_setting("difficulty", global.difficulty);
				update_hand_options();

				// Each difficulty remembers its graphics mode, which the logs show; the ALL view keeps the mode it came from
				if (global.difficulty != difficulties.ALL) {
					if (get_setting_for_difficulty("extra_mode", global.difficulty, false)) { global.graphics_mode = get_setting_for_difficulty("graphics_mode", global.difficulty, global.graphics_mode); }
					else if (global.graphics_mode != graphics_modes.standard) { global.graphics_mode = graphics_modes.standard; update_setting_for_difficulty("graphics_mode", global.difficulty, global.graphics_mode); }
				}
				if (death_log_screen) { update_death_types(); death_log_pos = 0; }
				if (evaluation_log_screen) { trait_surface_y_pos = 0; evaluation_log_sort = 0; update_traits_to_display(); }
			}
		}
	}
	
	// Handle X Key
	if (_key_back_pressed) {
		if (controls_screen || options_screen || death_log_screen || prepare_screen || evaluation_log_screen) {
			if (!options_screen || !option_selected) {
				play_sound(snd_putdown, false); 
				prepare_screen = false;
				controls_screen = false;
				options_screen = false;
				death_log_screen = false;
				evaluation_log_screen = false;
				options_pos = 0;
				death_log_pos = 0;
				with (obj_lava) { instance_destroy(); }
				if (global.difficulty == difficulties.ALL) { global.difficulty = get_max_difficulty(); }
			}
			else if (option_selected) { play_sound(snd_putdown, false); option_selected = false; }
		}
		else { play_sound(snd_locked, false); }
	}
	
	// Start Game From Prepare Screen for Z and Enter Key
	else if (prepare_screen && (_key_start_pressed || _key_select_pressed)) { loading = true; }
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
	else if (_key_select_pressed || _key_start_pressed) {
		var _prev_death_log_screen = death_log_screen, _prev_evaluation_log_screen = evaluation_log_screen;
		if (!controls_screen && !options_screen && !death_log_screen && !prepare_screen && !evaluation_log_screen) {
			prepare_screen = (pos <= 2);
			options_screen = (pos == 3);
			controls_screen = (pos == 4);
			death_log_screen = (pos == 5);
			evaluation_log_screen = (pos == 6);
			play_sound(snd_pickup, false);
			if (death_log_screen) { death_log_sort = 1; }
			if (evaluation_log_screen) { evaluation_log_sort = 1; }
			else if (options_screen) {
				option_selected = false;
				instance_create(216, 176+6, obj_lava); 
				with (obj_lava) { initialize_tile(); set_up_lava_edge_visibility(true); }
			}
			else if (prepare_screen) { 
				update_hand_options();
				if (get_stats_record_total(global.difficulty).wins == 0) { prepare_screen = false; loading = true; }
			}
		}
		
		// Update Sort
		if (death_log_screen) {
			death_log_pos = 0;
			death_log_sort += 1
			if (death_log_sort > 2) { death_log_sort = 0; }
			if (_prev_death_log_screen) { play_sound(snd_thud, false); }
			update_death_types();
		}
		else if (evaluation_log_screen) {
			trait_surface_y_pos = 0;
			evaluation_log_sort += 1
			if (evaluation_log_sort > 1) { evaluation_log_sort = 0; }
			if (_prev_evaluation_log_screen) { play_sound(snd_thud, false); }
			update_traits_to_display();
		}
	}
}