if (paused) {
	// Draw background
	draw_set_color(global.bg_color);
	draw_rectangle(0, 0, room_width-1, room_height-1, false);
	
	// Draw border
	draw_set_color(c_white);
	draw_rectangle(16, 16, room_width-1-16, room_height-1-16, false);
	
	// Draw center
	draw_set_color(global.bg_color);
	draw_rectangle(20, 20, room_width-1-20, room_height-1-20, false);
	
	// Draw Text
	draw_set_color(c_white);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ft_hud);
	
	var y_pos = (global.input != inputs.gamepad) ? (room_height/2)-16 : (room_height/2)-(16*2), x_pos = room_width/2;
	if (!is_blink_frame()) { draw_text(room_width/2, y_pos-16, "GAME PAUSED"); }
	draw_text(x_pos, y_pos+16, get_input_enter_key_string() + ": UNPAUSE");
	if (is_existing_instance(global.controller)) {	
		if (global.input != inputs.gamepad) {
			draw_text(x_pos, y_pos+(16*2), get_input_z_key_string() + "+" + get_input_x_key_string() + "+" + get_input_enter_key_string() + ": QUIT RUN");
		}
		else {
			draw_text(x_pos, y_pos+(16*2), get_input_z_key_string() + " +");
			draw_text(x_pos, y_pos+(16*3), get_input_x_key_string() + " +");
			draw_text(x_pos, y_pos+(16*4), get_input_enter_key_string() + ": ");
			draw_text(x_pos, y_pos+(16*5), "QUIT RUN");
		}
	}
	draw_set_color(get_inverted_game_bg_color());
	y_pos = room_height-32;
	draw_text(x_pos, y_pos, "ESC: QUIT PROGRAM");
	draw_set_color(c_white);
}