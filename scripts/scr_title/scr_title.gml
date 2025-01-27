/// @function								get_difficulty_string(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a string for
function get_difficulty_string(difficulty) {
	var result = "";
	switch (difficulty) {
		case difficulties.easy: { result = "Encounter"; break; }
		case difficulties.medium: { result = "Expedition"; break; }
		case difficulties.hard: { result = "Eons"; break; }
		case difficulties.very_hard: { result = "Eternity"; break; }
	}
	result += " in Hell";
	return result;
}

/// @function								get_seed_option_string();
function get_seed_option_string() {
	var result = "";
	switch (global.seed_option) {
		case seed_options.rand: { result = "Begin"; break; }
		case seed_options.same: { result = "Repeat"; break; }
		case seed_options.specified: { result = "Specify:"; break; }
	}
	return result;
}

/// @function								get_max_difficulty();
function get_max_difficulty() { 
	var max_difficulty = difficulties.DO_NOT_USE;
	
	if (global.is_test_mode) { return difficulties.very_hard; }
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		var next_wins = get_win_count(next_difficulty);
		if (next_wins > 0 && next_difficulty > max_difficulty) {
			max_difficulty = next_difficulty;
		}
	}
	
	if (max_difficulty < difficulties.very_hard) { max_difficulty += 1; }
	
	return max_difficulty;
}

/// @function								draw_death_type_sprite(x_pos, y_pos, obj_index);
///	@param		{real} x_pos				The x_pos to draw the sprite at
///	@param		{real} y_pos				The y_pos to draw the sprite at
///	@param		{object_index} difficulty	The object_index to draw the sprite for
function draw_death_type_sprite(x_pos, y_pos, obj_index) {
	var death_sprite = get_sprite_to_use(object_get_sprite(obj_index));
	
	// Draw Sprite
	if (obj_index == obj_controller) { 
		draw_sprite_ext(get_sprite_to_use(spr_clock), 7, x_pos, y_pos, 1, 1, 0, c_white, 1);
	}
	else if (obj_index == obj_statue) { draw_sprite_ext(death_sprite, 0, x_pos, y_pos, 1, 1, 180, c_white, 1); }
	else if (obj_index == obj_giant_worm_body) { 
		draw_sprite_ext(death_sprite, 0, x_pos-8, y_pos, 1, 1, 270, c_white, 1);
		draw_sprite_ext(death_sprite, 0, x_pos+8, y_pos, 1, 1, 90, c_white, 1);
	}
	else if (obj_index == obj_bug) { draw_sprite(spr_bug_red, 0, x_pos, y_pos); }
	else if (obj_index == obj_lava) {
		if (global.lava_edge_type > lava_edge_types.none && global.lava_edge_type < lava_edge_types.wavy_still) { death_sprite = spr_lava_death_edge2; }
		if (global.lava_edge_type >= lava_edge_types.wavy_still) { death_sprite = spr_lava_death_edge3; }
		draw_sprite(death_sprite, 0, x_pos, y_pos);
	}
	else if (obj_index == obj_fast_skeleton) { draw_sprite(spr_skeleton, 1, x_pos, y_pos); }
	else if (obj_index == obj_giant_eye) { draw_sprite(spr_giant_eye_death_sprite, 1, x_pos, y_pos); }
	else { draw_sprite(death_sprite, 0, x_pos, y_pos); }
}

/// @function								set_max_window_size();
function set_max_window_size() {
	var monitor_width = display_get_width(), monitor_height = display_get_height();
	global.max_window_scaling = 1;
	for (var i = 2; i <= 8; i++) {
		if (monitor_width >= (room_width*i) && monitor_height >= (room_height*i)) {
			global.max_window_scaling = i;
		}
	}
	global.fullscreen_window_scaling = global.max_window_scaling;
	
	if (os_type != os_windows) {
		global.max_window_scaling = 1;
		for (var i = 2; i <= 8; i++) {
			var surface_width = (room_width*i), surface_height = (room_height*i);
			if (monitor_width >= surface_width && monitor_height >= surface_width) {
				window_set_size(surface_width, surface_height);
				if (window_get_width() >= surface_width && window_get_height() >= surface_height) {
					global.max_window_scaling = i;
				}
			}
		}
	}
	
	if (global.window_scaling > global.max_window_scaling) { global.window_scaling = global.max_window_scaling; }
}

/// @function								set_window_size();
function set_window_size() {
	if (!global.fullscreen && gameframe_get_fullscreen() != 0) { gameframe_set_fullscreen(0); }
	else if (global.fullscreen && global.window_border && gameframe_get_fullscreen() != 1) { gameframe_set_fullscreen(1); }
	else if (global.fullscreen && !global.window_border && gameframe_get_fullscreen() != 2) { gameframe_set_fullscreen(2); }
	with (obj_game_manager) { resize_timer = 4; }
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
		case lava_edge_types.none: { return "None"; }
		case lava_edge_types.fuzzy_still: { return "Type 1"; }
		case lava_edge_types.fuzzy_animated: { return "Type 2"; }
		case lava_edge_types.wavy_still: { return "Type 3"; }
		case lava_edge_types.wavy_animated: { return "Type 4"; }
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

/// @function								get_input_space_key_string();
function get_input_space_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Space"; }
		case inputs.keyboard_wasd: { return "Space"; }
		case inputs.gamepad: { return "X / Y / R2 / L2"; }
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
	var gp_num = gamepad_get_device_count();
	global.gamepad = noone;
	for (var i = 0; i < gp_num; i++;) {
	    if (gamepad_is_connected(i)) { global.gamepad = i; break; }
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
	global.can_screen_flash = CAN_SCREEN_FLASH_DEFUALT;
	global.lava_edge_type = LAVA_EDGE_TYPE_DEFAULT;
	global.game_color_fade = GAME_COLOR_FADE_DEFAULT;
	global.game_color_string = GAME_COLOR_STRING_DEFAULT;
	global.player_outline = PLAYER_OUTLINE_DEFAULT;
	
	update_setting("fullscreen", FULLSCREEN_DEFAULT);
	update_setting("window_size", WINDOW_SCALING_DEFAULT);
	update_setting("window_border", WINDOW_BORDER_DEFAULT);
	update_setting("input", INPUT_DEFAULT);
	update_setting("can_screen_flash", CAN_SCREEN_FLASH_DEFUALT);
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
	var new_color = get_game_color();
	global.game_color = get_shader_color_from_gms_color(new_color);
}
