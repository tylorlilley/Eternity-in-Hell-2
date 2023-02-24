var game_manager = global.game_manager;
var key_space = game_manager.key_space, key_z = game_manager.key_z;
var death_count_string = get_death_count_string(global.difficulty), win_count_string = get_win_count_string(global.difficulty);
var title_y_pos = room_height/4+16, title_scale = 0.125;

if (loading) { title_y_pos = room_height*2; title_scale = 0.25; }
else if (options_screen) {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_center);
	
	var y_pos = 32, x_pos = room_width-56-8;
	
	// Draw General Options Info
	title_y_pos = room_height*2;
	
	draw_text(room_width/2, 16, "Options");	
	draw_text(room_width/2, room_height-32, get_input_z_key_string() + ": Reset to Defaults");
	draw_text(room_width/2, room_height-16, get_input_x_key_string() + ": Return");
	draw_set_valign(fa_left);
	
	// Draw Fullscreen Option
	var is_full_screen = window_get_fullscreen()
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Fullscreen: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, ((is_full_screen) ? "ON" : "OFF"));
	if (blink && options_pos == 0) {
		if (is_full_screen) { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Screen Scale Option
	y_pos += 24;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Window Size: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, "x "+ string(global.window_scaling));
	if (blink && options_pos == 1) {
		if (global.window_scaling < global.max_window_scaling) { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.window_scaling > 1) { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Controls Option
	y_pos += 24;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Controls: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, get_input_string());
	if (blink && options_pos == 2) {
		if (global.input < 1 || (global.input == 1 && gamepad_is_connected(global.gamepad))) { draw_sprite_ext(spr_title_arrow, 0, x_pos+48, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.input > 0) { draw_sprite_ext(spr_title_arrow, 0, x_pos-48, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Screen Flash Option
	y_pos += 24;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Screen Flash: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, ((global.can_screen_flash) ? "ON" : "OFF"));
	if (blink && options_pos == 3) {
		if (!global.can_screen_flash) { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
	}
	
	// Draw Lava Edge Type Option
	x_pos -= 8;
	y_pos += 24;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Lava Edge: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, get_lava_edge_type_string());
	if (blink && options_pos == 4) {
		if (global.lava_edge_type < lava_edge_types.wavy_animated) { draw_sprite_ext(spr_title_arrow, 0, x_pos+32, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.lava_edge_type > lava_edge_types.none) { draw_sprite_ext(spr_title_arrow, 0, x_pos-32, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Color Option
	y_pos += 24;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Color: ");
	draw_set_halign(fa_center);
	var padded_game_color_string = global.game_color_string;
	while (string_length(padded_game_color_string) < 6) {
		padded_game_color_string = "0"+padded_game_color_string;
	}
	draw_text(x_pos, y_pos, "#       ");
	if (options_pos != 5 || blink) {
		draw_text(x_pos, y_pos, "  " + padded_game_color_string);
	}
	var new_color = get_gms_color_from_hex_string(padded_game_color_string);
	draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 1, 1, 0, c_white, 1);
	draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 0.875, 0.875, 0, new_color, 1);
	
	// Draw Minimum Fade Option
	y_pos += 24;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Min. Brightness: ");
	draw_set_halign(fa_center);
	draw_text(x_pos+4, y_pos, get_percentage_string(global.game_color_fade));
	if (blink && options_pos == 6) {
		if (global.game_color_fade < 100) { draw_sprite_ext(spr_title_arrow, 0, x_pos+32+8, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.game_color_fade > 0) { draw_sprite_ext(spr_title_arrow, 0, x_pos-32, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	var new_color_minimum_fade = make_color_rgb(global.game_color_fade/100.0 * color_get_red(new_color), global.game_color_fade/100.0 * color_get_green(new_color), global.game_color_fade/100.0 * color_get_blue(new_color));
	draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 1, 1, 0, c_white, 1);
	draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 0.875, 0.875, 0, new_color_minimum_fade, 1);
}
else if key_space {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	var title_y_pos = room_height*2;
	var x_pos = room_width/3, y_pos = 64, y_offset = 40;
	
	// Draw Controls
	draw_set_halign(fa_left);
	draw_text(x_pos, y_pos,"Move / Push / Open");
	draw_text(x_pos, y_pos+y_offset, "Left: Take / Drop");
	draw_text(x_pos, y_pos+y_offset*2, "Right: Take / Drop");
	draw_text(x_pos, y_pos+y_offset*3, "View Map");
	draw_text(x_pos, y_pos+y_offset*4, "Restart Game");
	
	x_pos = room_width/3 - 40;
	y_pos = 64;
	if (global.input != inputs.gamepad) {
		var input_offset = (global.input == inputs.keyboard_wasd) ? 6 : 0;
		draw_sprite(spr_small_key, 0+input_offset ,x_pos, y_pos-8);
		draw_sprite(spr_small_key, 1+input_offset, x_pos + 16, y_pos+8);
		draw_sprite(spr_small_key, 2+input_offset, x_pos, y_pos+8);
		draw_sprite(spr_small_key, 3+input_offset, x_pos - 16, y_pos+8);
		draw_sprite(spr_small_key, 4+input_offset, x_pos, y_pos+y_offset);
		draw_sprite(spr_small_key, 5+input_offset, x_pos,y_pos+y_offset*2);
		draw_sprite(spr_large_key, 0, x_pos, y_pos+y_offset*3);
		draw_sprite(spr_large_key, 1, x_pos,y_pos+y_offset*4);
	}
	else {
		draw_sprite(spr_dpad, 0,x_pos, y_pos);
		
		draw_sprite(spr_small_button, 0, x_pos - 14,y_pos+y_offset);
		draw_sprite(spr_small_button, 4, x_pos - 4, y_pos+y_offset);
		draw_sprite(spr_large_button, 4, x_pos + 14, y_pos+y_offset);
		
		draw_sprite(spr_small_button, 1, x_pos - 14, y_pos+y_offset*2);
		draw_sprite(spr_small_button, 4, x_pos - 4, y_pos+y_offset*2);
		draw_sprite(spr_large_button, 2, x_pos + 14, y_pos+y_offset*2);
		
		draw_sprite(spr_small_button, 2, x_pos - 10, y_pos+y_offset*3-8);
		draw_sprite(spr_small_button, 4, x_pos, y_pos+y_offset*3-8);
		draw_sprite(spr_small_button, 3, x_pos + 10, y_pos+y_offset*3-8);
		draw_sprite(spr_large_button, 5, x_pos - 18, y_pos+y_offset*3+8);
		draw_sprite(spr_small_button, 4, x_pos, y_pos+y_offset*3+8);
		draw_sprite(spr_large_button, 3, x_pos + 18, y_pos+y_offset*3+8);
		
		draw_sprite(spr_large_button, 0, x_pos - 18, y_pos+y_offset*4);
		draw_sprite(spr_small_button, 4, x_pos, y_pos+y_offset*4);
		draw_sprite(spr_large_button, 1, x_pos + 18, y_pos+y_offset*4);
	}
	
	// Draw Game Version
	draw_set_halign(fa_right);
	draw_text(room_width-8, 16, "v." + string(GM_version));
}
else if (key_z && (death_count_string != noone || win_count_string != noone)) {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	title_y_pos = room_height*2;
	
	// Draw General Log Info
	var best_score_string = get_best_score_string(global.difficulty);
	draw_text(room_width/2, 16, get_difficulty_string(global.difficulty));

	if (death_count_string != noone) { draw_text(room_width/2, 16*2, death_count_string); }
	else { draw_text(room_width/2, 16*2, "Death Count: 0"); }
	if (win_count_string != noone) { draw_text(room_width/2, room_height-16, win_count_string); }
	if (best_score_string != noone) { draw_text(room_width/2, room_height-16-16, best_score_string); }
	
	// Create list of all deaths to display
	var death_types = get_death_types(), deaths_to_display = array_create(0),
	
	while (array_length(death_types) > 0) {
		var death_type = array_pop(death_types);
		
		var death_count = get_death_count(death_type, global.difficulty);
		if (death_count > 0) { array_push(deaths_to_display, [death_type, death_count]); }
	}
	
	// Sort deaths to display by death count
	array_sort(deaths_to_display, function(elm1, elm2) { return elm1[1] - elm2[1]; });
	
	// Cycle through deaths to display
	draw_set_halign(fa_left);
	var y_initial = (16*3)+8, x_columns = (array_length(deaths_to_display) <= 9) ? 3 : 5, x_initial = room_width/x_columns, y_pos = y_initial, x_pos = x_initial;
	while (array_length(deaths_to_display) > 0) {
		var death_to_display = array_pop(deaths_to_display), death_obj = death_to_display[0], death_count = death_to_display[1];
		
		// Draw Death Sprite and Count
		draw_death_type_sprite(x_pos, y_pos, death_obj);
		draw_text(x_pos+x_initial, y_pos, string(death_count));
		
		// Increase Draw Position
		y_pos += 18;
		if (y_pos > (y_initial+(18*8))) { y_pos = y_initial; x_pos += 2*x_initial; }
	}
}
else {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	
	// Draw Settings Switch Messages
	var message_y_pos = room_height - 48, messages_y_offset = 0;
	if (death_count_string != noone || win_count_string != noone) { message_y_pos -= 16; messages_y_offset += 16; draw_text(room_width/2, message_y_pos, + get_input_z_key_string() + ": View Death Log"); }
	draw_text(room_width/2, message_y_pos+messages_y_offset, get_input_space_key_string() + ": View Controls");
	draw_text(room_width/2, message_y_pos+messages_y_offset+16, get_input_x_key_string() + ": Game Options");
	draw_text(room_width/2, message_y_pos+messages_y_offset+32, get_input_enter_key_string() + ": Begin Game");
	
	// Draw difficulty selection
	if (global.seed_option == seed_options.specified) { title_y_pos -= 16; }
	var difficulty_y_pos = (global.is_test_mode) ? title_y_pos + room_height/4 - 16 : (title_y_pos + message_y_pos) / 2;
	draw_text(room_width/2, difficulty_y_pos, get_difficulty_string(global.difficulty));
	if (blink && pos == 0) {
		if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, difficulty_y_pos, 1, 1, 0, c_white, 1); }
		if (global.difficulty < get_max_difficulty()) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, difficulty_y_pos, -1, 1, 0, c_white, 1); }
	}
	// Draw death count for current difficulty
	if (death_count_string != noone) { draw_text(room_width/2, difficulty_y_pos+16, death_count_string); }

	// Draw seed selection
	if (global.is_test_mode) {
		var seed_y_pos = difficulty_y_pos + 40;
		draw_text(room_width/2, seed_y_pos, get_seed_option_string());
		if (blink && pos == 1) {
			if (global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, seed_y_pos, 1, 1, 0, c_white, 1); }
			if (global.seed_option < seed_options.specified) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, seed_y_pos, -1, 1, 0, c_white, 1); }
		}
		// Draw seed
		if (global.seed_option == seed_options.specified) { draw_text(room_width/2, seed_y_pos+16, get_zero_padded_string(current_seed, 9)); }
		if (blink && pos == 2) {
			if (current_seed < MAX_SEED) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, seed_y_pos+16, -1, 1, 0, c_white, 1); }
		    if (current_seed > 0) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, seed_y_pos+16, 1, 1, 0, c_white, 1); }
		}
	}
	
	// Draw farmer mode selection
	if (blink && pos == -1) {
		if (global.is_farm_mode) { draw_sprite_ext(spr_title_arrow, 0, room_width/4-32, title_y_pos, 1, 1, 0, c_white, 1); }
		if (!global.is_farm_mode) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4+32, title_y_pos, -1, 1, 0, c_white, 1); }
	}
}

// Draw Logo 
draw_sprite_ext(spr_logo, (global.is_farm_mode) ? 1 : 0, room_width/2, title_y_pos, title_scale, title_scale, 0, c_white, 1);