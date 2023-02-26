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
	draw_text(room_width/2, room_height/2-12, "PAUSED");
	draw_text(room_width/2, room_height/2+12, get_input_z_key_string() + " + " + get_input_x_key_string() + " + " + get_input_enter_key_string() + ": QUIT");	
}