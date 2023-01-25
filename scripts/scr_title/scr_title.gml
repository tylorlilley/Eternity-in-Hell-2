/// @function								get_difficulty_string(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a string for
function get_difficulty_string(difficulty) {
	var result = "";
	switch (difficulty) {
		case difficulties.easy: { result = "Moment"; break; }
		case difficulties.medium: { result = "Lifetime"; break; }
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
		case seed_options.rand: { result = "Generate Map"; break; }
		case seed_options.same: { result = "Repeat Map"; break; }
		case seed_options.specified: { result = "Specify Map"; break; }
	}
	return result;
}

/// @function								get_max_difficulty();
function get_max_difficulty() { 
	var max_difficulty = difficulties.DO_NOT_USE;
	
	if (global.TEST_MODE) { return difficulties.very_hard; }
	
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
		draw_sprite_ext(spr_clock, 0, x_pos, y_pos, 1, 1, 0, c_white, 1); 
		draw_sprite_ext(spr_sand, 7, x_pos, y_pos, 1, 1, 0, c_white, 1); 
	}
	else if (obj_index == obj_statue) { draw_sprite_ext(death_sprite, 0, x_pos, y_pos, 1, 1, 180, c_white, 1); }
	else if (obj_index == obj_giant_worm_body) { 
		draw_sprite_ext(death_sprite, 0, x_pos-8, y_pos, 1, 1, 270, c_white, 1);
		draw_sprite_ext(death_sprite, 0, x_pos+8, y_pos, 1, 1, 90, c_white, 1);
	}
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
	global.window_scaling = 2;
}

/// @function								set_window_size();
function set_window_size() {
	// Resize the drawing surface
	var draw_surface_width = (room_width*global.window_scaling), draw_surface_height = (room_height*global.window_scaling)
	window_set_size(draw_surface_width, draw_surface_height);
}

/// @function								set_window_size();
function get_input_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Arrow Keys"; }
		case inputs.keyboard_wasd: { return "WASD Keys"; }
		case inputs.gamepad: { return "Gamepad"; }
	}
}

/// @function								set_window_size();
function get_input_z_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Z"; }
		case inputs.keyboard_wasd: { return "J"; }
		case inputs.gamepad: { return "B1"; }
	}
}

/// @function								set_window_size();
function get_input_x_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "X"; }
		case inputs.keyboard_wasd: { return "K"; }
		case inputs.gamepad: { return "B2"; }
	}
}

/// @function								set_window_size();
function get_input_space_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Space"; }
		case inputs.keyboard_wasd: { return "Space"; }
		case inputs.gamepad: { return "B3"; }
	}
}

/// @function								set_window_size();
function get_input_enter_key_string() {
	switch (global.input) {
		case inputs.keyboard_default: { return "Enter"; }
		case inputs.keyboard_wasd: { return "Enter"; }
		case inputs.gamepad: { return "Start"; }
	}
}
