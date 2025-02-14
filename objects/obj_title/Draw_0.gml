var game_manager = global.game_manager, game_color = get_game_color();
var death_count_string = get_death_count_string(global.difficulty), win_count_string = (global.is_test_mode) ? "alotta wins man" : get_win_count_string(global.difficulty);
var title_y_pos = room_height*2, title_scale = 0.125, blink = is_blink_frame();

// Draw General Submenu Info
draw_set_color(c_white);
draw_set_font(ft_hud);
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
var submenu_title = "";

if (prepare_screen) { submenu_title = "Prepare Yourself"; }
else if (options_screen) { submenu_title = "Options"; }
else if (controls_screen) { submenu_title = "View Controls"; }
else if (death_log_screen) { submenu_title = "View Log"; }
draw_set_color(game_color);
if (options_screen || controls_screen || death_log_screen || prepare_screen) {
	draw_set_font(ft_hud_large);
	draw_text(room_width/2, 16-2, submenu_title);
	
	draw_set_font(ft_hud_small);
	var return_text = get_input_x_key_string() + ": Return";
	if (death_log_screen) { return_text = get_input_z_key_string() + ": Change Sort; " + get_input_x_key_string() + ": Return"; }
	draw_text(room_width/2, room_height-16, return_text);
	draw_set_font(ft_hud);
}
draw_set_color(c_white);

// Draw Menu Specific Stuff
if (loading) { title_y_pos = room_height*2; title_scale = 0.25; }
else if (prepare_screen) {
	var player_x_pos = room_width/2, left_hand_x_pos = player_x_pos - (16*4), right_hand_x_pos = player_x_pos + (16*4);
	var player_y_pos = (room_height/2)+16;
	
	// Draw Text
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	draw_set_font(ft_hud_large);
	draw_text(room_width/2, 32-2, get_difficulty_string(global.difficulty));
	draw_set_font(ft_hud);
	draw_text(room_width/2, room_height-32, get_input_z_key_string() + ": Begin");
	var best_count = array_length(hand_options);
	var possible_count = array_length(global.available_items[global.difficulty]);
	//var available_text = "AVAILABLE: "+string(best_count)+"/"+string(possible_count);
	//if (best_count == possible_count) { available_text += "; COMPLETE"; draw_set_color(game_color); }
	//var available_text = (best_count == possible_count) ? "COMPLETE" : "";
	//draw_text(room_width/2, 64, available_text);
	draw_set_color(c_white);
	
	// Draw Player Visuals
	if (best_count == possible_count) { draw_sprite_ext(spr_crown, (get_win_count(global.difficulty, graphics_modes.unknown) > 0) ? 1 : 0, player_x_pos, player_y_pos - (16*3), 3, 3, 0, c_white, 1); }
	draw_sprite_ext(spr_player, 1, player_x_pos, player_y_pos, 4, 4, 0, c_white, 1);
	if (global.graphics_mode == graphics_modes.farmer) { draw_sprite_ext(spr_player_farmer, 1, player_x_pos, player_y_pos, 4, 4, 0, c_white, 1); }
	if (left_hand_pos != -1) {
		var item = hand_options[left_hand_pos], sprite_to_use = get_sprite_to_use(object_get_sprite(item), true);
		draw_sprite_ext(sprite_to_use, 0, left_hand_x_pos, player_y_pos, 4, 4, 0, c_white, 1);
		if (sprite_to_use == spr_compass) { draw_sprite_ext(spr_compass_hands, 0, left_hand_x_pos, player_y_pos, 4, 4, 0, c_white, 1); }
		else if (sprite_to_use == spr_clock) { draw_sprite_ext(spr_clock_sand, 0, left_hand_x_pos, player_y_pos, 4, 4, 0, c_white, 1); }
		else if (sprite_to_use == spr_clock_farmer) { draw_sprite_ext(spr_clock_sand_farmer, 0, left_hand_x_pos, player_y_pos, 4, 4, 0, c_white, 1); }
	}
	if (right_hand_pos != -1) {
		var item = hand_options[right_hand_pos], sprite_to_use = get_sprite_to_use(object_get_sprite(item), true)
		draw_sprite_ext(sprite_to_use, 0, right_hand_x_pos, player_y_pos, -4, 4, 0, c_white, 1);
		if (sprite_to_use == spr_compass) { draw_sprite_ext(spr_compass_hands, 0, right_hand_x_pos, player_y_pos, -4, 4, 0, c_white, 1); }
		else if (sprite_to_use == spr_clock) { draw_sprite_ext(spr_clock_sand, 0, right_hand_x_pos, player_y_pos, -4, 4, 0, c_white, 1); }
		else if (sprite_to_use == spr_clock_farmer) { draw_sprite_ext(spr_clock_sand_farmer, 0, right_hand_x_pos, player_y_pos, -4, 4, 0, c_white, 1); }
	}
	if (left_hand_selected && blink) {
		draw_sprite_ext(spr_title_arrow, 0, left_hand_x_pos, player_y_pos - (16*3), 2, 2, -90, c_white, 1);
		draw_sprite_ext(spr_title_arrow, 0, left_hand_x_pos, player_y_pos + (16*3), 2, 2, 90, c_white, 1);
		draw_sprite_ext(spr_title_arrow, 0, right_hand_x_pos + (16*3), player_y_pos, 2, 2, 180, c_white, 1);
	}
	else if (!left_hand_selected && blink) {
		draw_sprite_ext(spr_title_arrow, 0, right_hand_x_pos, player_y_pos - (16*3), -2, 2, 90, c_white, 1);
		draw_sprite_ext(spr_title_arrow, 0, right_hand_x_pos, player_y_pos + (16*3), -2, 2, -90, c_white, 1);
		draw_sprite_ext(spr_title_arrow, 0, left_hand_x_pos - (16*3), player_y_pos, 2, 2, 0, c_white, 1);
	}
}
else if (options_screen) {
	draw_set_valign(fa_top);
	draw_set_halign(fa_left);
	
	var y_pos = 32, x_pos = room_width-56-8, y_offset = 22;
	
	// Draw Fullscreen Option
	var is_full_screen = global.fullscreen;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Fullscreen: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, ((is_full_screen) ? "ON" : "OFF"));
	if (blink && options_pos == 0) {
		if (is_full_screen) { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Screen Scale or Borderless Option
	y_pos += y_offset;
	if (!global.fullscreen || os_type != os_windows) {
		draw_set_halign(fa_left);
		draw_text(16, y_pos, "Window Size: ");
		draw_set_halign(fa_center);
		draw_text(x_pos, y_pos, "x "+ string(global.window_scaling));
		if (blink && options_pos == 1) {
			if (global.window_scaling < global.max_window_scaling) { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
			if (global.window_scaling > 1) { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
		}
	}
	else {
		draw_set_halign(fa_left);
		draw_text(16, y_pos, "Window Border: ");
		draw_set_halign(fa_center);
		draw_text(x_pos, y_pos, ((global.window_border) ? "ON" : "OFF"));
		if (blink && options_pos == 1) {
			if (global.window_border) { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
			else { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
		}
	}
	
	// Draw Controls Option
	y_pos += y_offset;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Controls: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, get_input_string());
	if (blink && options_pos == 2) {
		if (global.input < 1 || (global.input == 1 && gamepad_is_connected(global.gamepad))) { draw_sprite_ext(spr_title_arrow, 0, x_pos+48, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.input > 0) { draw_sprite_ext(spr_title_arrow, 0, x_pos-48, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Player Outline
	y_pos += y_offset;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Player Outline: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, ((global.player_outline) ? "ON" : "OFF"));
	if (blink && options_pos == 3) {
		if (!global.player_outline) { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
	}
	
	// Draw Screen Flash Option
	y_pos += y_offset;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Screen Flash: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, ((global.can_screen_flash) ? "ON" : "OFF"));
	if (blink && options_pos == 4) {
		if (!global.can_screen_flash) { draw_sprite_ext(spr_title_arrow, 0, x_pos-24, y_pos+8, 1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_title_arrow, 0, x_pos+24, y_pos+8, -1, 1, 0, c_white, 1); }
	}
	
	// Draw Lava Edge Type Option
	x_pos -= 8;
	y_pos += y_offset;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Lava Edge: ");
	draw_set_halign(fa_center);
	draw_text(x_pos, y_pos, get_lava_edge_type_string());
	if (blink && options_pos == 5) {
		if (global.lava_edge_type < lava_edge_types.wavy_animated) { draw_sprite_ext(spr_title_arrow, 0, x_pos+32, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.lava_edge_type > lava_edge_types.none) { draw_sprite_ext(spr_title_arrow, 0, x_pos-32, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Color Option
	y_pos += y_offset;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Color: ");
	draw_set_halign(fa_center);
	var padded_game_color_string = global.game_color_string;
	while (string_length(padded_game_color_string) < 6) {
		padded_game_color_string = "0"+padded_game_color_string;
	}
	var new_color = get_gms_color_from_hex_string(padded_game_color_string);
	if (blink && options_pos == 6) { padded_game_color_string = string_delete(padded_game_color_string, 6, 1); padded_game_color_string += "_" }
	draw_text(x_pos, y_pos, "#       ");
	draw_text(x_pos+12, y_pos, padded_game_color_string);
	//draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 1, 1, 0, c_white, 1);
	draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 0.875, 0.875, 0, new_color, 1);
	
	// Draw Minimum Fade Option
	y_pos += y_offset;
	draw_set_halign(fa_left);
	draw_text(16, y_pos, "Min. Brightness: ");
	draw_set_halign(fa_center);
	draw_text(x_pos+4, y_pos, get_percentage_string(global.game_color_fade));
	if (blink && options_pos == 7) {
		if (global.game_color_fade < 100) { draw_sprite_ext(spr_title_arrow, 0, x_pos+32+8, y_pos+8, -1, 1, 0, c_white, 1); }
		if (global.game_color_fade > 0) { draw_sprite_ext(spr_title_arrow, 0, x_pos-32, y_pos+8, 1, 1, 0, c_white, 1); }
	}
	var new_color_minimum_fade = make_color_rgb(global.game_color_fade/100.0 * color_get_red(new_color), global.game_color_fade/100.0 * color_get_green(new_color), global.game_color_fade/100.0 * color_get_blue(new_color));
	//draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 1, 1, 0, c_white, 1);
	draw_sprite_ext(spr_box, 0, x_pos + 56, y_pos+8, 0.875, 0.875, 0, new_color_minimum_fade, 1);
	
	// Draw Reset to Defaults Option
	y_pos += y_offset;
	draw_set_halign(fa_left);
	if ((blink && options_pos == 8) || options_pos != 8) { draw_text(16, y_pos, "Reset to Default Settings"); }
	draw_set_halign(fa_center);
}
else if (controls_screen) {
	draw_set_valign(fa_middle);
	draw_set_halign(fa_left);
	var title_y_pos = room_height*2;
	var x_pos = room_width/3, y_pos = 56, y_offset = 40;
	
	// Draw Controls
	draw_set_halign(fa_left);
	draw_text(x_pos, y_pos,"Move / Push / Open");
	draw_text(x_pos, y_pos+y_offset, "Left: Take / Drop");
	draw_text(x_pos, y_pos+y_offset*2, "Right: Take / Drop");
	draw_text(x_pos, y_pos+y_offset*3, "View Map");
	draw_text(x_pos, y_pos+y_offset*4, "Pause Game");
	
	x_pos = room_width/3 - 40;
	y_pos = 48;
	if (global.input != inputs.gamepad) {
		var input_offset = (global.input == inputs.keyboard_wasd) ? 6 : 0;
		
		draw_sprite_ext(spr_small_key, 0+input_offset ,x_pos, y_pos-8, 1, 1, 1, (game_manager.key_up ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 1+input_offset, x_pos + 16, y_pos+8, 1, 1, 1, (game_manager.key_right ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 2+input_offset, x_pos, y_pos+8, 1, 1, 1, (game_manager.key_down ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 3+input_offset, x_pos - 16, y_pos+8, 1, 1, 1, (game_manager.key_left ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 4+input_offset, x_pos, y_pos+y_offset, 1, 1, 1, (game_manager.key_z ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 5+input_offset, x_pos,y_pos+y_offset*2, 1, 1, 1, (game_manager.key_x ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_key, 0, x_pos, y_pos+y_offset*3, 1, 1, 1, (game_manager.key_space ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_key, 1, x_pos,y_pos+y_offset*4, 1, 1, 1, (game_manager.key_enter ? game_color : c_white), 1);
	}
	else {
		var d_pad_pressed = game_manager.key_up || game_manager.key_down || game_manager.key_right || game_manager.key_left;
		draw_sprite_ext(spr_dpad, 0,x_pos, y_pos, 1, 1, 0, (d_pad_pressed ? game_color : c_white), 1);
		
		draw_sprite_ext(spr_small_button, 0, x_pos - 14, y_pos+y_offset, 1, 1, 0, (game_manager.key_z ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, x_pos - 4, y_pos+y_offset, 1, 1, 0, (game_manager.key_z ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 4, x_pos + 14, y_pos+y_offset, 1, 1, 0, (game_manager.key_z ? game_color : c_white), 1);
		
		draw_sprite_ext(spr_small_button, 1, x_pos - 14, y_pos+y_offset*2, 1, 1, 0, (game_manager.key_x ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, x_pos - 4, y_pos+y_offset*2, 1, 1, 0, (game_manager.key_x ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 2, x_pos + 14, y_pos+y_offset*2, 1, 1, 0, (game_manager.key_x ? game_color : c_white), 1);
		
		draw_sprite_ext(spr_small_button, 2, x_pos - 10, y_pos+y_offset*3-8, 1, 1, 0, (game_manager.key_space ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, x_pos, y_pos+y_offset*3-8, 1, 1, 0, (game_manager.key_space ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 3, x_pos + 10, y_pos+y_offset*3-8, 1, 1, 0, (game_manager.key_space ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 5, x_pos - 18, y_pos+y_offset*3+8, 1, 1, 0, (game_manager.key_space ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, x_pos, y_pos+y_offset*3+8, 1, 1, 0, (game_manager.key_space ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 3, x_pos + 18, y_pos+y_offset*3+8, 1, 1, 0, (game_manager.key_space ? game_color : c_white), 1);
		
		draw_sprite_ext(spr_large_button, 0, x_pos - 18, y_pos+y_offset*4, 1, 1, 0, (game_manager.key_enter ? game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, x_pos, y_pos+y_offset*4, 1, 1, 0, (game_manager.key_enter ? game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 1, x_pos + 18, y_pos+y_offset*4, 1, 1, 0, (game_manager.key_enter ? game_color : c_white), 1);
	}
}
else if (death_log_screen && (death_count_string != noone || win_count_string != noone)) {
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	title_y_pos = room_height*2;
	
	// Draw Headers
	var y_initial = 16*2, x_initial = (room_width/4)-16, y_pos = y_initial, x_pos = x_initial-16;
	var best_score_string = get_best_score_string(global.difficulty), killed_x_pos = (x_initial*2)-16, deaths_x_pos = (x_initial*3), last_x_pos = (x_initial*4)+16;
	draw_set_font(ft_hud_large);
	draw_text(room_width/2, y_pos-2, get_difficulty_string(global.difficulty));
	draw_set_font(ft_hud);
	y_pos += 16;
	if (death_count_string != noone) { draw_text(room_width/2, y_pos, death_count_string); }
	else { draw_text(room_width/2, y_pos, "Death Count: 0"); }
	y_pos += 24;
	draw_set_font(ft_hud_small);
	draw_set_color((death_log_sort == 0) ? game_color : c_white);
	draw_text(killed_x_pos, y_pos, "Killed:");
	draw_set_color((death_log_sort == 1) ? game_color : c_white);
	draw_text(deaths_x_pos, y_pos, "Killed By:");
	draw_set_color((death_log_sort == 2) ? game_color : c_white);
	draw_text(last_x_pos, y_pos, "Last Run\nEnded By:");
	draw_set_font(ft_hud);
	draw_set_color(c_white);
	if (win_count_string != noone) { draw_text(room_width/2, room_height-16-16-16, win_count_string); }
	if (best_score_string != noone) { draw_text(room_width/2, room_height-16-16, best_score_string); }
	
	// Draw Arrow Keys
	if (blink && !game_manager.key_up_pressed && death_log_pos > 0) { draw_sprite_ext(spr_title_arrow, 0 , x_pos, y_pos, 1, 1, -90, c_white, 1); }
	y_pos += 16;
	if (blink && !game_manager.key_down_pressed && death_log_pos < array_length(deaths_to_display)-5) { draw_sprite_ext(spr_title_arrow, 2, x_pos, room_height-(16*3), 1, 1, 90, c_white, 1); }
	y_pos += 16;
	
	// Draw Deaths
	for (var i = 0; i < 5; i++) {
		var log_pos = death_log_pos + i;
		if (log_pos >= array_length(deaths_to_display)) { break; }
		else {
			var death_to_display = deaths_to_display[log_pos], death_obj = death_to_display[0], death_count = death_to_display[1], kill_count = death_to_display[2], last_killed = death_to_display[3] ;
			draw_death_type_sprite(x_pos, y_pos, death_obj);
			draw_text(killed_x_pos, y_pos, string(kill_count));
			draw_text(deaths_x_pos, y_pos, string(death_count));
			draw_text(last_x_pos, y_pos, string(last_killed));
			y_pos += 18;
		}
	}
}
else {
	// Draw Main Menu
	draw_set_valign(fa_middle);
	draw_set_halign(fa_left);
	var title_y_pos = room_height/4;
	
	// Draw Game Version
	draw_set_font(ft_hud_small);
	draw_set_halign(fa_right);
	draw_text(room_width-6, room_height-6, "ver." + string(GM_version));
	draw_set_font(ft_hud);
	
	// Draw farmer mode selection
	if (blink && pos == -1) {
		if (global.graphics_mode != graphics_modes.standard) { draw_sprite_ext(spr_title_arrow, 0, room_width/4-32, title_y_pos, 1, 1, 0, c_white, 1); }
		if (global.graphics_mode == graphics_modes.standard || (can_play_unknown_mode() && global.graphics_mode == graphics_modes.farmer)) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4+32, title_y_pos, -1, 1, 0, c_white, 1); }
	}
	
	// Draw difficulty selection
	draw_set_halign(fa_center);
	draw_set_font(ft_hud_large);
	var difficulty_y_pos = title_y_pos + room_height/4 - 32 + 4;
	draw_text(room_width/2, difficulty_y_pos, get_difficulty_string(global.difficulty));
	draw_set_font(ft_hud);
	if (blink && pos == 0) {
		if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, 24, difficulty_y_pos, 1, 1, 0, c_white, 1); }
		if (global.difficulty < get_max_difficulty()) { draw_sprite_ext(spr_title_arrow, 0, room_width - 24, difficulty_y_pos, -1, 1, 0, c_white, 1); }
	}
	// Draw death count for current difficulty
	if (death_count_string != noone) { draw_text(room_width/2, difficulty_y_pos+16, death_count_string); }
	
	// Draw remaining menu options
	var message_y_pos = difficulty_y_pos+16+24+16, messages_y_offset = 0;
	draw_set_halign(fa_left);
	draw_text(32, message_y_pos+messages_y_offset, get_seed_option_string());
	draw_text(32, message_y_pos+messages_y_offset+32, "Options");
	draw_text(32, message_y_pos+messages_y_offset+48, "View Controls");
	if (death_count_string != noone || win_count_string != noone) { message_y_pos -= 16; messages_y_offset += 16; draw_text(32, message_y_pos+messages_y_offset+64, + "View Log"); }
	var arrow_y =-64;
	if (pos == 1) { arrow_y = message_y_pos+messages_y_offset; }
	else if (pos == 2) { arrow_y = message_y_pos+messages_y_offset+16; }
	else if (pos == 3) { arrow_y = message_y_pos+messages_y_offset+32; }
	else if (pos == 4) { arrow_y = message_y_pos+messages_y_offset+48; }
	else if (pos == 5) { arrow_y = message_y_pos+messages_y_offset+64; }
	
	// Draw seed
	if (global.seed_option == seed_options.specified) { draw_text(48, message_y_pos+messages_y_offset+16, get_zero_padded_string(current_seed, 9)); }
	if (blink) {
		if (pos == 1 && global.is_test_mode) {
			// Draw option arrows
			if (blink) {
				if (global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) { draw_sprite_ext(spr_title_arrow, 0, 16, arrow_y, 1, 1, 0, c_white, 1); }
				if (global.seed_option < seed_options.specified) { draw_sprite_ext(spr_title_arrow, 0, 96, arrow_y, -1, 1, 0, c_white, 1); }
			}
		}
		else if (pos == 2) {
			if (current_seed < MAX_SEED) { draw_sprite_ext(spr_title_arrow, 0, 40, message_y_pos+messages_y_offset+16, 1, 1, 0, c_white, 1); }
			if (current_seed > 0) { draw_sprite_ext(spr_title_arrow, 0, 96+16+16, message_y_pos+messages_y_offset+16, -1, 1, 0, c_white, 1); }
		}
		else { draw_sprite_ext(spr_title_arrow, 0, 16, arrow_y, -1, 1, 0, c_white, 1); }
	}
}

// Draw Logo
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
draw_set_font(ft_hud_giant);
draw_set_color(game_color);
draw_text(room_width/2, title_y_pos, get_graphics_mode_string(global.graphics_mode));
//draw_sprite_ext(spr_logo, global.graphics_mode, room_width/2, title_y_pos, title_scale, title_scale, 0, c_white, 1);

/*
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
	*/