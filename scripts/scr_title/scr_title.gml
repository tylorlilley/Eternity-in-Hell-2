/// @function get_difficulty_string(_difficulty)
/// @description The game's title for a difficulty, such as "Eternity in Hell" for very hard. It also names that
///	difficulty's section of player_data.ini, so changing it orphans the saved data.
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for "Everything in Hell"
/// @returns {string} Just " in Hell" for any other value
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

/// @function get_graphics_mode_string(_graphics_mode)
/// @description The title the title screen shows for a graphics mode: "EIH" for standard, "EIEIH" for farmer, and
///	"???" for unknown
/// @param {real} _graphics_mode The graphics mode (see graphics_modes)
/// @returns {string} An empty string for any other value
function get_graphics_mode_string(_graphics_mode) {
	var _result = "";
	switch (_graphics_mode) {
		case graphics_modes.standard: { _result = "EIH"; break; }
		case graphics_modes.farmer: { _result = "EIEIH"; break; }
		case graphics_modes.unknown: { _result = "???"; break; }
	}
	return _result;
}

/// @function get_seed_option_string()
/// @description The title screen's label for the current seed option: "Begin" for a random seed, "Repeat" for the same
///	seed as the last run, and "Specify:" for a seed the player enters
/// @returns {string} An empty string for any other value
function get_seed_option_string() {
	var _result = "";
	switch (global.seed_option) {
		case seed_options.rand: { _result = "Begin"; break; }
		case seed_options.same: { _result = "Repeat"; break; }
		case seed_options.specified: { _result = "Specify:"; break; }
	}
	return _result;
}

/// @function get_max_difficulty()
/// @description The hardest difficulty the player can choose: the one after the hardest they've won (easy before any
///	win), up to very hard. Test mode unlocks every difficulty.
/// @returns {real} A difficulty (see difficulties)
function get_max_difficulty() { 
	var _max_difficulty = difficulties.DO_NOT_USE;
	
	if (global.is_test_mode) { return difficulties.very_hard; }
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		var _next_wins = get_win_count(_next_difficulty);
		if (_next_wins > 0 && _next_difficulty > _max_difficulty) {
			_max_difficulty = _next_difficulty;
		}
	}
	
	if (_max_difficulty < difficulties.very_hard) { _max_difficulty += 1; }
	
	return _max_difficulty;
}

/// @function draw_death_type_sprite(_x_pos, _y_pos, _obj_index)
/// @description Draws the icon for a death type (what ended a run, or what the player killed) in the death log and on
///	the HUD after a lost run. Most use their object's sprite, but some need a set frame, a rotation or another sprite:
///	obj_controller (time running out) draws the clock, and lava matches the lava edge setting.
/// @param {real} _x_pos The x position to draw at
/// @param {real} _y_pos The y position to draw at
/// @param {Asset.GMObject} _obj_index The death type's object
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
		draw_sprite_ext(spr_player, 1, _x_pos, _y_pos, 1, 1, 0, c_white, INVERTED_COLORS_ALPHA);
		if (global.graphics_mode == graphics_modes.farmer) { draw_sprite_ext(spr_player_farmer, 1, _x_pos, _y_pos, 1, 1, 0, c_white, INVERTED_COLORS_ALPHA); }
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

/// @function set_max_window_size()
/// @description Works out the largest whole-number scale of the room (up to 8) that fits on the monitor, which is also
///	the fullscreen scale. Outside Windows it then resizes the window to each scale that fits, to check the window
///	really grows that big, so the window is left resized. Lowers the window scaling setting if it's above the result.
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

/// @function set_window_size()
/// @description Puts the window in the mode the fullscreen and window border settings ask for, unless it's in it
///	already: windowed, GameMaker's own fullscreen with the border setting on, or gameframe's borderless window over
///	the whole screen with it off. Then the game manager resizes and centers the window over its next four steps.
function set_window_size() {
	if (!global.fullscreen && gameframe_get_fullscreen() != 0) { gameframe_set_fullscreen(0); }
	else if (global.fullscreen && global.window_border && gameframe_get_fullscreen() != 1) { gameframe_set_fullscreen(1); }
	else if (global.fullscreen && !global.window_border && gameframe_get_fullscreen() != 2) { gameframe_set_fullscreen(2); }
	with (obj_game_manager) { resize_timer = 4; }
}

/// @function get_input_string()
/// @description The options screen's label for the current input setting: "Arrow Keys", "WASD Keys" or "Gamepad"
/// @returns {string}
function get_input_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Arrow Keys"; }
		case inputs.keyboard_wasd: { return "WASD Keys"; }
		case inputs.gamepad: { return "Gamepad"; }
	}
}

/// @function get_lava_edge_type_string()
/// @description The options screen's label for the current lava edge setting, on two lines, such as "Fuzzy,\nStill"
/// @returns {string}
function get_lava_edge_type_string() {
	switch (global.lava_edge_type) {
		case lava_edge_types.none: { return "Flat\nEdge"; }
		case lava_edge_types.fuzzy_still: { return "Fuzzy,\nStill"; }
		case lava_edge_types.fuzzy_animated: { return "Fuzzy,\nAnimated"; }
		case lava_edge_types.wavy_still: { return "Wavy,\nStill"; }
		case lava_edge_types.wavy_animated: { return "Wavy,\nAnimated"; }
	}
}

/// @function get_input_z_key_string()
/// @description The name of the key or button that acts as Z with the current input setting, for on-screen prompts
///	such as "Z: Begin"
/// @returns {string}
function get_input_z_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Z"; }
		case inputs.keyboard_wasd: { return "J"; }
		case inputs.gamepad: { return "A / L1"; }
	}
}

/// @function get_input_x_key_string()
/// @description The name of the key or button that acts as X with the current input setting, for on-screen prompts
///	such as "X: Return"
/// @returns {string}
function get_input_x_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "X"; }
		case inputs.keyboard_wasd: { return "K"; }
		case inputs.gamepad: { return "B / R1"; }
	}
}

/// @function get_input_enter_key_string()
/// @description The name of the key or button that acts as Enter with the current input setting, for on-screen
///	prompts such as "Enter: Return"
/// @returns {string}
function get_input_enter_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Enter"; }
		case inputs.keyboard_wasd: { return "Enter"; }
		case inputs.gamepad: { return "Start / Select"; }
	}
}

/// @function determine_gamepad()
/// @description Finds the first connected gamepad and stores its slot in global.gamepad. With none connected, the
///	gamepad input setting falls back to the arrow keys.
/// @returns {real} The gamepad's slot, or noone if none is connected
function determine_gamepad() {
	var _gp_num = gamepad_get_device_count();
	global.gamepad = noone;
	for (var _i = 0; _i < _gp_num; _i++;) {
	    if (gamepad_is_connected(_i)) { global.gamepad = _i; break; }
	}
	if (global.gamepad == noone && global.input == inputs.gamepad) { global.input = inputs.keyboard_default; }
	return global.gamepad;
}

/// @function reset_settings_to_defaults()
/// @description Resets the display, input and appearance settings (fullscreen, window size and border, input, screen
///	flash, lava edges, game color and its fade, player outline) to their defaults and saves them. Then it applies the
///	ones that need it: the lava edges, the game color and the window size.
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

/// @function set_game_color()
/// @description Sets the game color from its setting (a hex string): as a GameMaker color in global.gms_game_color, and
///	as the [r, g, b, a] array the shaders use in global.game_color
function set_game_color() {
	global.gms_game_color = calculate_gms_game_color();
	global.game_color = get_shader_color_from_gms_color(global.gms_game_color);
}


/// @function update_hand_options()
/// @description Lists, in obj_title's hand_options, the items the player can start a run holding on the current
///	difficulty: the torch, plus each item they've won with there. It preselects the items they held last time
///	(left_hand_pos and right_hand_pos, -1 when not offered), and records whether every item is available, which
///	unlocks the graphics mode choice (farmer mode) on that difficulty.
function update_hand_options() {
	// Set up array of item options
	hand_options = [];
	left_hand_pos = -1;
	right_hand_pos = -1;
	global.player_left_hand_item = get_setting_for_difficulty("last_player_left_hand_item", global.difficulty, obj_torch);
	global.player_right_hand_item = get_setting_for_difficulty("last_player_right_hand_item", global.difficulty, noone);
	var _possible_options = global.available_items[global.difficulty];
	for (var _i = 0; _i < array_length(_possible_options); _i++) {
		var _next_option = _possible_options[_i];
		// The torch is always available, and any other item once the player has won with it on this difficulty
		if (_next_option == obj_torch) { 
			array_push(hand_options, _next_option);
		}
		else if (get_item_win_count(_next_option, global.difficulty) > 0) {
			array_push(hand_options, _next_option); 
		}
		// Preselect the items the player held last time
		if (_next_option == global.player_left_hand_item) { left_hand_pos = array_length(hand_options)-1; }
		else if (_next_option == global.player_right_hand_item) { right_hand_pos = array_length(hand_options)-1; }
	}
	var _farmer_mode_available = (array_length(hand_options) == array_length(global.available_items[global.difficulty]));
	update_setting_for_difficulty("extra_mode", global.difficulty, _farmer_mode_available);
}


/// @function update_death_types()
/// @description Fills obj_title's death log for the current difficulty: deaths_to_display gets a [death type, deaths,
///	kills, last run ended] entry for each death type that has ended a run or been killed, sorted by the column
///	death_log_sort picks
function update_death_types() {
	// List each death type that has ended a run or been killed, with its counts
	var _death_types = get_death_types();
	deaths_to_display = [];
	while (array_length(_death_types) > 0) {
		var _death_type = array_pop(_death_types);
		
		var _death_count = get_death_count(_death_type, global.difficulty), _kill_count = get_kill_count(_death_type, global.difficulty), _last_killed = get_last_killed(_death_type, global.difficulty);
		if (_death_count > 0 || _kill_count > 0) { array_push(deaths_to_display, [_death_type, _death_count, _kill_count, _last_killed]); }
	}
				
	// Sort by the chosen column, highest first: 0 for kills, 1 for deaths, 2 for the last run it ended
	array_sort(deaths_to_display, function(_elm1, _elm2) { 
		switch (death_log_sort) {
			case 1: { return _elm2[1] - _elm1[1]; break; }
			case 0: { return _elm2[2] - _elm1[2]; break; }
			case 2: { return _elm2[3] - _elm1[3]; break; }
		}
	});
}

/// @function can_play_unknown_mode()
/// @description Whether the unknown graphics mode is unlocked: farmer mode is unlocked on every difficulty, or test
///	mode is on
/// @returns {bool}
function can_play_unknown_mode() {
	var _can_play_easy = get_setting_for_difficulty("extra_mode", difficulties.easy, false);
	var _can_play_medium = get_setting_for_difficulty("extra_mode", difficulties.medium, false);
	var _can_play_hard = get_setting_for_difficulty("extra_mode", difficulties.hard, false);
	var _can_play_very_hard = get_setting_for_difficulty("extra_mode", difficulties.very_hard, false);
				
	return global.is_test_mode || (_can_play_easy && _can_play_medium && _can_play_hard && _can_play_very_hard);
}