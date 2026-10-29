/// @function								get_difficulty_string(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a string for
function get_difficulty_string(_difficulty) {
	var _result = "";
	switch (_difficulty) {
		case difficulties.easy: { _result = "Encounter"; break; }
		case difficulties.medium: { _result = "Expedition"; break; }
		case difficulties.hard: { _result = "Eons"; break; }
		case difficulties.very_hard: { _result = "Eternity"; break; }
		case difficulties.ALL: { _result = "Everything"; break; }
	}
	_result += " in Hell";
	return _result;
}

/// @function								get_graphics_mode_string(_graphics_mode);
///	@param		{graphics_mode} _graphics_mode	The graphics mode to return a string for
function get_graphics_mode_string(_graphics_mode) {
	var _result = "";
	switch (_graphics_mode) {
		case graphics_modes.standard: { _result = "EIH"; break; }
		case graphics_modes.farmer: { _result = "EIEIH"; break; }
		case graphics_modes.unknown: { _result = "???"; break; }
	}
	return _result;
}

/// @function								get_seed_option_string();
function get_seed_option_string() {
	var _result = "";
	switch (global.seed_option) {
		case seed_options.rand: { _result = "Begin"; break; }
		case seed_options.same: { _result = "Repeat"; break; }
		case seed_options.specified: { _result = "Specify:"; break; }
	}
	return _result;
}

/// @function								get_max_difficulty();
function get_max_difficulty() { 
	var _max_difficulty = difficulties.DO_NOT_USE;
	
	if (global.is_test_mode) { return difficulties.very_hard; }
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		var _next_wins = get_stats_record_total(_next_difficulty).wins;
		if (_next_wins > 0 && _next_difficulty > _max_difficulty) {
			_max_difficulty = _next_difficulty;
		}
	}
	
	if (_max_difficulty < difficulties.very_hard) { _max_difficulty += 1; }
	
	return _max_difficulty;
}

/// @function								draw_death_type_sprite(_x_pos, _y_pos, _obj_index);
///	@param		{real} _x_pos				The x_pos to draw the sprite at
///	@param		{real} _y_pos				The y_pos to draw the sprite at
///	@param		{object_index} difficulty	The object_index to draw the sprite for
function draw_death_type_sprite(_x_pos, _y_pos, _obj_index) {
	var _death_sprite = get_sprite_to_use(object_get_sprite(_obj_index), true);
	
	// Draw Sprite
	if (_obj_index == obj_controller) { 
		draw_sprite_ext(get_sprite_to_use(spr_clock), 0, _x_pos, _y_pos, 1, 1, 0, c_white, 1);
		draw_sprite_ext(get_sprite_to_use(spr_clock_sand), 7, _x_pos, _y_pos, 1, 1, 0, c_white, 1);
	}
	else if (_obj_index == obj_player) { draw_sprite(spr_player, 1, _x_pos, _y_pos); }
	else if (_obj_index == obj_locked_chest) { draw_sprite(spr_chest, 2, _x_pos, _y_pos); }
	else if (_obj_index == obj_block) { draw_sprite(spr_block, 0, _x_pos, _y_pos); }
	else if (_obj_index == obj_spider) { draw_sprite(spr_spider, 0, _x_pos, _y_pos); }
	else if (_obj_index == obj_statue) { draw_sprite_ext(_death_sprite, 0, _x_pos, _y_pos, 1, 1, 180, c_white, 1); }
	else if (_obj_index == obj_giant_worm_body) { 
		draw_sprite_ext(_death_sprite, 0, _x_pos-8, _y_pos, 1, 1, 270, c_white, 1);
		draw_sprite_ext(_death_sprite, 0, _x_pos+8, _y_pos, 1, 1, 90, c_white, 1);
	}
	else if (_obj_index == obj_bug) { draw_sprite(spr_bug_red, 0, _x_pos, _y_pos); }
	else if (_obj_index == obj_echo) {
		draw_sprite_ext(spr_player, 1, _x_pos, _y_pos, 1, 1, 0, c_white, INVERTED_COLORS_ALPHA_FLAG);
		if (global.graphics_mode == graphics_modes.farmer) { draw_sprite_ext(spr_player_farmer, 1, _x_pos, _y_pos, 1, 1, 0, c_white, INVERTED_COLORS_ALPHA_FLAG); }
	}
	else if (_obj_index == obj_lava) {
		if (global.lava_edge_type > lava_edge_types.none && global.lava_edge_type < lava_edge_types.wavy_still) { _death_sprite = spr_lava_death_edge2; }
		if (global.lava_edge_type >= lava_edge_types.wavy_still) { _death_sprite = spr_lava_death_edge3; }
		draw_sprite(_death_sprite, 0, _x_pos, _y_pos);
	}
	else if (_obj_index == obj_giant_eye) { draw_sprite(spr_giant_eye_death_sprite, 1, _x_pos, _y_pos); }
	else if (_obj_index == obj_living_block) { draw_sprite(spr_living_block, 2, _x_pos, _y_pos); }
	else { draw_sprite(_death_sprite, 0, _x_pos, _y_pos); }
}

/// @function								set_max_window_size();
function set_max_window_size() {
	var _monitor_width = display_get_width(), _monitor_height = display_get_height();
	global.max_window_scaling = 1;
	for (var _i = 2; _i <= 8; _i++) {
		if (_monitor_width >= (room_width*_i) && _monitor_height >= (room_height*_i)) {
			global.max_window_scaling = _i;
		}
	}
	global.fullscreen_window_scaling = global.max_window_scaling;
	
	if (os_type != os_windows) {
		global.max_window_scaling = 1;
		for (var _i = 2; _i <= 8; _i++) {
			var _surface_width = (room_width*_i), _surface_height = (room_height*_i);
			if (_monitor_width >= _surface_width && _monitor_height >= _surface_width) {
				window_set_size(_surface_width, _surface_height);
				if (window_get_width() >= _surface_width && window_get_height() >= _surface_height) {
					global.max_window_scaling = _i;
				}
			}
		}
	}
	
	if (global.window_scaling > global.max_window_scaling) { global.window_scaling = global.max_window_scaling; }
}

/// @function								set_window_size();
function set_window_size() {
	// Leave fullscreen when going windowed, or when switching between borderless and exclusive fullscreen, which only
	// takes effect on entering fullscreen. The game manager then sizes the window or enters fullscreen again
	if (window_get_fullscreen() && (!global.fullscreen || window_get_borderless_fullscreen() == global.window_border)) { window_set_fullscreen(false); }
	with (obj_game_manager) { resize_timer = 12; }
}

/// @function								get_input_string();
function get_input_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Arrow Keys"; }
		case inputs.keyboard_wasd: { return "WASD Keys"; }
		case inputs.gamepad: { return "Gamepad"; }
	}
}

function get_lava_edge_type_string() {
	switch (global.lava_edge_type) {
		case lava_edge_types.none: { return "Flat\nEdge"; }
		case lava_edge_types.fuzzy_still: { return "Fuzzy,\nStill"; }
		case lava_edge_types.fuzzy_animated: { return "Fuzzy,\nAnimated"; }
		case lava_edge_types.wavy_still: { return "Wavy,\nStill"; }
		case lava_edge_types.wavy_animated: { return "Wavy,\nAnimated"; }
	}
}

/// @function								get_input_z_key_string();
function get_input_z_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Z"; }
		case inputs.keyboard_wasd: { return "J"; }
		case inputs.gamepad: { return "A / L1"; }
	}
}

/// @function								get_input_x_key_string();
function get_input_x_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "X"; }
		case inputs.keyboard_wasd: { return "K"; }
		case inputs.gamepad: { return "B / R1"; }
	}
}

/// @function								get_input_enter_key_string();
function get_input_enter_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Enter"; }
		case inputs.keyboard_wasd: { return "Enter"; }
		case inputs.gamepad: { return "Start / Select"; }
	}
}

/// @function								determine_gamepad();
function determine_gamepad() {
	var _gp_num = gamepad_get_device_count();
	global.gamepad = noone;
	for (var _i = 0; _i < _gp_num; _i++;) {
	    if (gamepad_is_connected(_i)) { global.gamepad = _i; break; }
	}
	if (global.gamepad == noone && global.input == inputs.gamepad) { global.input = inputs.keyboard_default; }
	return global.gamepad;
}

/// @function								reset_settings_to_defaults();
function reset_settings_to_defaults() {
	global.fullscreen = FULLSCREEN_DEFAULT;
	global.window_scaling = WINDOW_SCALING_DEFAULT;
	global.window_border = WINDOW_BORDER_DEFAULT;
	global.input = INPUT_DEFAULT;
	global.can_screen_flash = CAN_SCREEN_FLASH_DEFAULT;
	global.lava_edge_type = LAVA_EDGE_TYPE_DEFAULT;
	global.game_color_fade = GAME_COLOR_FADE_DEFAULT;
	global.game_color_string = GAME_COLOR_STRING_DEFAULT;
	global.player_outline = PLAYER_OUTLINE_DEFAULT;
	
	update_setting("fullscreen", FULLSCREEN_DEFAULT);
	update_setting("window_size", WINDOW_SCALING_DEFAULT);
	update_setting("window_border", WINDOW_BORDER_DEFAULT);
	update_setting("input", INPUT_DEFAULT);
	update_setting("can_screen_flash", CAN_SCREEN_FLASH_DEFAULT);
	update_setting("lava_edge_type", LAVA_EDGE_TYPE_DEFAULT);
	update_setting("game_color_fade", GAME_COLOR_FADE_DEFAULT);
	update_setting("game_color", GAME_COLOR_STRING_DEFAULT);
	update_setting("player_outline", PLAYER_OUTLINE_DEFAULT);
	
	with (obj_lava) { set_up_lava_edge_visibility(true); }
	set_game_color();
	set_window_size();
}

/// @function								set_game_color();
function set_game_color() {
	global.gms_game_color = calculate_gms_game_color();
	global.game_color = get_shader_color_from_gms_color(global.gms_game_color);
}


/// @function								update_hand_options();
function update_hand_options() {
	// Set up array of item options
	hand_options = [];
	left_hand_pos = -1;
	right_hand_pos = -1;
	global.player_left_hand_item = get_setting_for_difficulty("last_player_left_hand_item", global.difficulty, obj_torch);
	global.player_right_hand_item = get_setting_for_difficulty("last_player_right_hand_item", global.difficulty, noone);
	var _possible_options = global.available_items[global.difficulty], _history_record = get_stats_record_total(global.difficulty);
	for (var _i = 0; _i < array_length(_possible_options); _i++) {
		var _next_option = _possible_options[_i];
		// Ensure Torch is always available
		if (_next_option == obj_torch) { 
			array_push(hand_options, _next_option);
		}
		else if (_history_record.get_item_win_count(_next_option) > 0) {
			array_push(hand_options, _next_option); 
		}
		// Preselect Previous Items
		if (_next_option == global.player_left_hand_item) { left_hand_pos = array_length(hand_options)-1; }
		else if (_next_option == global.player_right_hand_item) { right_hand_pos = array_length(hand_options)-1; }
	}
	var _farmer_mode_available = (array_length(hand_options) == array_length(global.available_items[global.difficulty]));
	update_setting_for_difficulty("extra_mode", global.difficulty, _farmer_mode_available);
}


/// @function update_death_types()
/// @description Lists the rows of the death log for the selected difficulty and graphics mode: each thing that has
///	killed the player or that the player has killed, with its deaths, the player's kills of it (see
///	is_player_killer) and the last run it ended, sorted by the column death_log_sort picks (0 kills, 1 deaths,
///	2 last run ended)
function update_death_types() {
	// Update Death Count Values
	var _death_types = get_death_types(), _history_record = get_stats_record_total(global.difficulty, global.graphics_mode);
	deaths_to_display = [];
	while (array_length(_death_types) > 0) {
		var _death_type = array_pop(_death_types);
		
		var _death_count = _history_record.get_death_count(_death_type), _kill_count = _history_record.get_player_kill_count(_death_type), _last_killed = _history_record.get_last_killed(_death_type);
		if (_death_count > 0 || _kill_count > 0) { array_push(deaths_to_display, [_death_type, _death_count, _kill_count, _last_killed]); }
	}
				
	// Sort deaths to display by death count
	array_sort(deaths_to_display, function(_elm1, _elm2) { 
		switch (death_log_sort) {
			case 1: { return _elm2[1] - _elm1[1]; }
			case 0: { return _elm2[2] - _elm1[2]; }
			case 2: { return _elm2[3] - _elm1[3]; }
		}
	});
}

/// @function update_traits_to_display()
/// @description Lists the rows of the trait list for the selected difficulty and graphics mode: each achievement
///	earned (see get_evaluation_messages) with how many runs earned it, in the order evaluation_log_sort picks (0 the
///	evaluation's order, 1 the most earned first). Test mode lists every achievement.
function update_traits_to_display() {
	traits_to_display = [];
	var _evaluation_messages = get_evaluation_messages(), _history_record = get_stats_record_total(global.difficulty, global.graphics_mode);
	for (var _i = 0; _i < array_length(_evaluation_messages); _i++) {
		var _message = _evaluation_messages[_i];
		if (!_message.is_achievement) { continue; }

		var _times_earned = (global.is_test_mode) ? 9999 : _history_record.get_evaluation_message_count(_message.title);
		if (_times_earned > 0) { array_push(traits_to_display, [_message, _times_earned, _i]); }
	}

	// Sort by times earned, keeping the evaluation's order among ties
	if (evaluation_log_sort == 1) {
		array_sort(traits_to_display, function(_trait_1, _trait_2) {
			return (_trait_1[1] != _trait_2[1]) ? _trait_2[1] - _trait_1[1] : _trait_1[2] - _trait_2[2];
		});
	}
}

/// @function has_finished_a_run(_difficulty)
/// @description Whether a run on a difficulty has ended, in any graphics mode, which unlocks the main menu's death
///	log and trait list for it
/// @param {real} _difficulty The difficulty (see difficulties)
/// @returns {bool}
function has_finished_a_run(_difficulty) {
	return (get_stats_record_total(_difficulty).runs > 0);
}

/// @function								can_play_unknown_mode();
function can_play_unknown_mode() {
	var _can_play_easy = get_setting_for_difficulty("extra_mode", difficulties.easy, false);
	var _can_play_medium = get_setting_for_difficulty("extra_mode", difficulties.medium, false);
	var _can_play_hard = get_setting_for_difficulty("extra_mode", difficulties.hard, false);
	var _can_play_very_hard = get_setting_for_difficulty("extra_mode", difficulties.very_hard, false);
				
	return global.is_test_mode || (_can_play_easy && _can_play_medium && _can_play_hard && _can_play_very_hard);
}