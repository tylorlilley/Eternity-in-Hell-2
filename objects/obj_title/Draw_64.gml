/// @description Insert description here
// You can write your code in this editor
var death_count_string = get_death_count_string(global.difficulty);
var title_y_pos = room_height/4+16, title_scale = 0.125;

// Draw background
draw_set_color(c_black);
draw_rectangle(0, 0, room_width, room_height, false);

if (loading) { title_y_pos = room_height/2; title_scale = 0.25; }
else if (options_screen) {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_center);
	
	var column_width = room_width/3, y_pos = 32;
	
	// Draw General OIptions Info
	title_y_pos = room_height*2;
	
	draw_text(room_width/2, 16, "Options");	
	draw_text(room_width/2, room_height-24, get_input_x_key_string() + ": Return");
	draw_set_valign(fa_left);
	
	// Draw Fullscreen Option
	var is_full_screen = window_get_fullscreen()
	draw_text(column_width, y_pos, "Fullscreen: ");
	draw_text(column_width*2, y_pos, ((is_full_screen) ? "ON" : "OFF"));
	if (blink && options_pos == 0) {
		if (is_full_screen) { draw_sprite_ext(spr_title_arrow, 0, column_width*2+24, y_pos+8, -1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_title_arrow, 0, column_width*2-24, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Screen Scale Option
	y_pos += 24;
	var color = (is_full_screen) ? c_gray : c_white;
	draw_set_color(color);
	draw_text(column_width, y_pos, "Window Size: ");
	draw_text(column_width*2, y_pos, "x "+ string(global.window_scaling));
	if (!is_full_screen && blink && options_pos == 1) {
		if (global.window_scaling < global.max_window_scaling) { draw_sprite_ext(spr_title_arrow, 0, column_width*2+24, y_pos+8, -1, 1, 0, color, 1); }
		if (global.window_scaling > 1) { draw_sprite_ext(spr_title_arrow, 0, column_width*2-24, y_pos+8, 1, 1, 0, color, 1); }
	}
	
	// Draw Controls Option
	y_pos += 24;
	var color = (is_full_screen) ? c_gray : c_white;
	draw_set_color(color);
	draw_text(column_width, y_pos, "Control Type: ");
	draw_text(column_width*2, y_pos, get_input_string());
	if (!is_full_screen && blink && options_pos == 1) {
		if (global.input < 1 || (global.input < 2 && gamepad_is_connected(0))) { draw_sprite_ext(spr_title_arrow, 0, column_width*2+24, y_pos+8, -1, 1, 0, color, 1); }
		if (global.input > 1) { draw_sprite_ext(spr_title_arrow, 0, column_width*2-24, y_pos+8, 1, 1, 0, color, 1); }
	}
}
else if keyboard_check(vk_space) {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	
	// Draw Controls
	draw_set_halign(fa_left);
	draw_text(room_width/4+8, room_height/2-8,"Move / Push / Open");
	draw_text(room_width/4+8, room_height/2+16+8, "Left: Take / Drop");
	draw_text(room_width/4+8, room_height/2+16+16+8, "Right: - Take / Drop");
	draw_text(room_width/4+8, room_height/2+16+16+24+8, "View Map");
	draw_text(room_width/4+8, room_height/2+16+16+24+24+8, "Restart Game");
	
	draw_sprite(spr_small_key, 0, room_width/4 - 36, room_height/2-16);
	draw_sprite(spr_small_key, 1,  room_width/4 - 36 + 16, room_height/2);
	draw_sprite(spr_small_key, 2, room_width/4 - 36, room_height/2);
	draw_sprite(spr_small_key, 3, room_width/4 - 36 - 16, room_height/2);
	draw_sprite(spr_small_key, 4, room_width/4 - 36, room_height/2+32-8);
	draw_sprite(spr_small_key, 5, room_width/4 - 36, room_height/2+32+16-8);
	draw_sprite(spr_large_key, 0, room_width/4 - 36, room_height/2+32+16+24-8);
	draw_sprite(spr_large_key, 1, room_width/4 - 36, room_height/2+32+16+24+24-8);
	
	// Draw Game Version
	draw_set_halign(fa_right);
	draw_text(room_width, 16, "v." + string(GM_version));
}
else if (keyboard_check(ord("Z")) && death_count_string != noone) {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	
	// Draw General Log Info
	title_y_pos = room_height*2;
	draw_set_halign(fa_center);
	
	var win_count_string = get_win_count_string(global.difficulty), best_score_string = get_best_score_string(global.difficulty);
	draw_text(room_width/2, 16, get_difficulty_string(global.difficulty));

	if (death_count_string != noone) { draw_text(room_width/2, 16*2, death_count_string); }
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
		var death_to_display = array_pop(deaths_to_display), death_object = death_to_display[0], death_count = death_to_display[1];
		
		// Draw Death Sprite and Count
		draw_death_type_sprite(x_pos, y_pos, death_object);
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
	if (death_count_string != noone) { message_y_pos -= 16; messages_y_offset += 16; draw_text(room_width/2, message_y_pos, "Hold " + get_input_z_key_string() + ": View Death Log"); }
	draw_text(room_width/2, message_y_pos+messages_y_offset, "Hold " + get_input_space_key_string() + ": View Controls");
	draw_text(room_width/2, message_y_pos+messages_y_offset+16, "Press " + get_input_x_key_string() + ": Game Options");
	draw_text(room_width/2, message_y_pos+messages_y_offset+32, "Press " + get_input_enter_key_string() + ": Begin Game");
	
	// Draw difficulty selection
	if (global.seed_option == seed_options.specified) { title_y_pos -= 16; }
	var difficulty_y_pos = (global.TEST_MODE) ? title_y_pos + room_height/4 - 16 : (title_y_pos + message_y_pos) / 2;
	draw_text(room_width/2, difficulty_y_pos, get_difficulty_string(global.difficulty));
	if (blink && pos == 0) {
		if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, difficulty_y_pos, 1, 1, 0, c_white, 1); }
		if (global.difficulty < get_max_difficulty()) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, difficulty_y_pos, -1, 1, 0, c_white, 1); }
	}
	// Draw death count for current difficulty
	if (death_count_string != noone) { draw_text(room_width/2, difficulty_y_pos+16, death_count_string); }

	// Draw seed selection
	if (global.TEST_MODE) {
		var seed_y_pos = difficulty_y_pos + 40;
		draw_text(room_width/2, seed_y_pos, get_seed_option_string());
		if (blink && pos == 1) {
			if (global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, seed_y_pos, 1, 1, 0, c_white, 1); }
			if (global.seed_option < seed_options.specified) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, seed_y_pos, -1, 1, 0, c_white, 1); }
		}
		// Draw seed
		if (global.seed_option == seed_options.specified) { draw_text(room_width/2, seed_y_pos+16, get_zero_padded_string(current_seed, 9)); }
		if (blink && pos == 2) {
			if (current_seed < 99999999) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, seed_y_pos+16, -1, 1, 0, c_white, 1); }
		    if (current_seed > 0) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, seed_y_pos+16, 1, 1, 0, c_white, 1); }
		}
	}
	
	// Draw farmer mode selection
	if (blink && pos == -1) {
		if (global.FARM_MODE) { draw_sprite_ext(spr_title_arrow, 0, room_width/4-32, title_y_pos, 1, 1, 0, c_white, 1); }
		if (!global.FARM_MODE) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4+32, title_y_pos, -1, 1, 0, c_white, 1); }
	}
}

// Draw Logo 
draw_sprite_ext(spr_logo, (global.FARM_MODE) ? 1 : 0, room_width/2, title_y_pos, title_scale, title_scale, 0, c_white, 1);