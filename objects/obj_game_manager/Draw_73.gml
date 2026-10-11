// While paused, draw the pause screen over the game: a framed box with the controls to unpause and to quit
if (paused) {
	// Cover the game with the background color
	draw_set_color(global.bg_color);
	draw_rectangle(0, 0, room_width-1, room_height-1, false);
	
	// Draw a white box for the frame
	draw_set_color(c_white);
	draw_rectangle(16, 16, room_width-1-16, room_height-1-16, false);
	
	// Fill the inside of the box with the background color, which leaves a white border
	draw_set_color(global.bg_color);
	draw_rectangle(20, 20, room_width-1-20, room_height-1-20, false);
	
	// Draw the text, centered
	draw_set_color(c_white);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	
	// Without a game in progress there is no line to quit the run, so the text sits 16 pixels lower
	var _y_pos = (room_height/2)-16, _x_pos = room_width/2;
	if (instance_number(obj_controller) == 0) { _y_pos += 16; }
	// The title blinks, and the unpause control comes below it
	draw_set_font(ft_hud_large);
	if (!is_blink_frame()) { draw_text(room_width/2, _y_pos-16-2, "GAME PAUSED"); }
	draw_set_font(ft_hud);
	draw_text(_x_pos, _y_pos+16, get_input_enter_key_string() + ": UNPAUSE");
	// During a game, show the controls that quit the run, spread over several lines for a gamepad
	if (is_existing_instance(global.controller)) {	
		if (global.input != inputs.gamepad) {
			draw_text(_x_pos, _y_pos+(16*2), get_input_z_key_string() + "+" + get_input_x_key_string() + "+" + get_input_enter_key_string() + ": QUIT RUN");
		}
		else {
			draw_text(_x_pos, _y_pos+(16*2), "("+get_input_z_key_string() + ") + (" + get_input_x_key_string() + ") +");
			draw_text(_x_pos, _y_pos+(16*3), "("+get_input_enter_key_string() + "): ");
			draw_text(_x_pos, _y_pos+(16*4), "QUIT RUN");
		}
	}
	// The control that quits the whole program sits near the bottom, in the inverted game color
	draw_set_color(get_inverted_game_color());
	_y_pos = room_height-32;
	draw_text(_x_pos, _y_pos, "ESC: QUIT PROGRAM");
	draw_set_color(c_white);
}

// Turn off the color shader that the Draw Begin event turned on (see set_eih_shader)
shader_reset();

// In test mode, hold Q to show the current room's solid path grid, or W to show its lava path grid, along with the
// grid's lines and the path each enemy is following
if (global.is_test_mode && instance_exists(global.controller)) {
	var _show_solid_path_grid = keyboard_check(ord("Q")), _show_lava_path_grid = keyboard_check(ord("W"));
	if (_show_solid_path_grid || _show_lava_path_grid) {
		draw_set_alpha(0.1);
		draw_set_colour(c_white);
		if (_show_solid_path_grid) { 
			mp_grid_draw(global.controller.current_room.solid_path_grid);
		}
		if (_show_lava_path_grid) { mp_grid_draw(global.controller.current_room.lava_path_grid); }
		
		// Draw a line between each column of the grid cells, then between each row
		for (var _i = 0; _i < room_width; _i += GRID_SIZE;) {
			draw_line_width(_i, 0, _i, room_height, 1);
		}
		for (var _j = 0; _j < room_width; _j += GRID_SIZE;) {
			draw_line_width(0, _j, room_width, _j, 1);
		}
		draw_set_alpha(1);
		with (obj_enemy) {
			if (target_path_grid != -1 && path_exists(target_path)) { draw_path(target_path, x, y, true); }
		}
	}
}