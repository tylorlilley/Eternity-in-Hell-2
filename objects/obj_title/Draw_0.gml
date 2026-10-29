var _game_manager = global.game_manager, _game_color = global.gms_game_color;
// Counts shown are for the selected graphics mode; the logs unlock once a run has ended in any of them
var _history_record = get_stats_record_total(global.difficulty, global.graphics_mode);
var _run_count_string = (global.is_test_mode) ? "Runs Attempted: 99999" : _history_record.get_run_count_string();
var _death_count_string = (global.is_test_mode) ? "Deaths: 9999" : _history_record.get_death_count_string(), _win_count_string = (global.is_test_mode) ? "Victories: 9999" : _history_record.get_win_count_string();
var _can_view_logs = (global.is_test_mode || has_finished_a_run(global.difficulty));
var _title_y_pos = room_height*2, _blink = is_blink_frame();

draw_set_color(c_white);

// Draw Menu Specific Stuff
if (loading) { _title_y_pos = room_height*2; }
else if (prepare_screen) {
	var _player_x_pos = room_width/2, _left_hand_x_pos = _player_x_pos - (16*4), _right_hand_x_pos = _player_x_pos + (16*4);
	var _player_y_pos = (room_height/2)+16;
	
	// Draw Text
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	draw_set_font(ft_hud);
	draw_text(room_width/2, 31, get_difficulty_string(global.difficulty));
	var _best_count = array_length(hand_options);
	var _possible_count = array_length(global.available_items[global.difficulty]);
	draw_set_color(c_white);
	
	// Draw Player Visuals
	if (_best_count == _possible_count) { draw_sprite_ext(spr_crown, 0, _player_x_pos, _player_y_pos - (16*3), 3, 3, 0, c_white, (get_stats_record_total(global.difficulty, graphics_modes.unknown).wins > 0) ? INVERTED_COLORS_ALPHA_FLAG : 1); }
	draw_sprite_ext(spr_player, 1, _player_x_pos, _player_y_pos, 4, 4, 0, c_white, 1);
	if (global.graphics_mode == graphics_modes.farmer) { draw_sprite_ext(spr_player_farmer, 1, _player_x_pos, _player_y_pos, 4, 4, 0, c_white, 1); }
	draw_set_color(_game_color);
	draw_rectangle(_left_hand_x_pos-24, _player_y_pos-24, _left_hand_x_pos+24, _player_y_pos+24, false);
	draw_rectangle(_right_hand_x_pos-24, _player_y_pos-24, _right_hand_x_pos+24, _player_y_pos+24, false);
	draw_set_color(global.bg_color);
	draw_rectangle(_left_hand_x_pos-20, _player_y_pos-20, _left_hand_x_pos+20, _player_y_pos+20, false);
	draw_rectangle(_right_hand_x_pos-20, _player_y_pos-20, _right_hand_x_pos+20, _player_y_pos+20, false);
	draw_set_color(c_white);
	if (left_hand_selected) {
		if (!_game_manager.key_up) { draw_sprite_ext(spr_menu_arrow, 0, _left_hand_x_pos + 8, _player_y_pos - (16*3) + 4, 2, 2, 90, c_white, 1); }
		if (!_game_manager.key_down) { draw_sprite_ext(spr_menu_arrow, 0, _left_hand_x_pos + 8, _player_y_pos + (16*3) - 4, 2, 2, -90, c_white, 1); }
	}
	else if (!left_hand_selected) {
		if (!_game_manager.key_up) { draw_sprite_ext(spr_menu_arrow, 0, _right_hand_x_pos - 8, _player_y_pos - (16*3) + 4, -2, 2, -90, c_white, 1); }
		if (!_game_manager.key_down) { draw_sprite_ext(spr_menu_arrow, 0, _right_hand_x_pos - 8, _player_y_pos + (16*3) - 4, -2, 2, 90, c_white, 1); }
	}
	
	if (left_hand_pos != -1) {
		var _item = hand_options[left_hand_pos], _sprite_to_use = get_sprite_to_use(object_get_sprite(_item), true);
		var _item_y_offset = get_carried_item_draw_y_offset(_sprite_to_use);
		draw_sprite_ext(_sprite_to_use, 0, _left_hand_x_pos, _player_y_pos+(4*_item_y_offset), 4, 4, 0, c_white, 1);
		if (_sprite_to_use == spr_compass) { draw_sprite_ext(spr_compass_hands, 0, _left_hand_x_pos, _player_y_pos, 4, 4, 0, c_white, 1); }
		else if (_sprite_to_use == spr_clock) { draw_sprite_ext(spr_clock_sand, 0, _left_hand_x_pos, _player_y_pos, 4, 4, 0, c_white, 1); }
		else if (_sprite_to_use == spr_clock_farmer) { draw_sprite_ext(spr_clock_sand_farmer, 0, _left_hand_x_pos, _player_y_pos, 4, 4, 0, c_white, 1); }
	}
	if (right_hand_pos != -1) {
		var _item = hand_options[right_hand_pos], _sprite_to_use = get_sprite_to_use(object_get_sprite(_item), true)
		var _item_y_offset = get_carried_item_draw_y_offset(_sprite_to_use);
		draw_sprite_ext(_sprite_to_use, 0, _right_hand_x_pos, _player_y_pos+(4*_item_y_offset), -4, 4, 0, c_white, 1);
		if (_sprite_to_use == spr_compass) { draw_sprite_ext(spr_compass_hands, 0, _right_hand_x_pos, _player_y_pos, -4, 4, 0, c_white, 1); }
		else if (_sprite_to_use == spr_clock) { draw_sprite_ext(spr_clock_sand, 0, _right_hand_x_pos, _player_y_pos, -4, 4, 0, c_white, 1); }
		else if (_sprite_to_use == spr_clock_farmer) { draw_sprite_ext(spr_clock_sand_farmer, 0, _right_hand_x_pos, _player_y_pos, -4, 4, 0, c_white, 1); }
	}
}
else if (options_screen) {
	draw_set_valign(fa_top);
	draw_set_halign(fa_left);
	draw_set_font(ft_hud_small);
	
	var _y_pos = 64, _x_pos = room_width-64, _y_offset = 14, _text_x_pos = 32;
	
	// Draw Fullscreen Option
	if (_blink && options_pos == 0 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	var _is_full_screen = global.fullscreen;
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos, "Fullscreen: ");
	draw_set_halign(fa_center);
	draw_text(_x_pos, _y_pos, ((_is_full_screen) ? "ON" : "OFF"));
	if (_blink && options_pos == 0 && option_selected) {
		if (_is_full_screen) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+16, _y_pos+6, 1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-16, _y_pos+6, -1, -1, 0, c_white, 1); }
	}
	
	// Draw Screen Scale or Borderless Option
	_y_pos += _y_offset;
	if (_blink && options_pos == 1 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	if (!global.fullscreen || os_type != os_windows) {
		draw_set_halign(fa_left);
		draw_text(_text_x_pos, _y_pos, "Window Size: ");
		draw_set_halign(fa_center);
		draw_text(_x_pos, _y_pos, "x "+ string(global.window_scaling));
		if (_blink && options_pos == 1 && option_selected) {
			if (global.window_scaling < global.max_window_scaling) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+16, _y_pos+6, 1, 1, 0, c_white, 1); }
			if (global.window_scaling > 1) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-16, _y_pos+6, -1, 1, 0, c_white, 1); }
		}
	}
	else {
		draw_set_halign(fa_left);
		draw_text(_text_x_pos, _y_pos, "Window Border: ");
		draw_set_halign(fa_center);
		draw_text(_x_pos, _y_pos, ((global.window_border) ? "ON" : "OFF"));
		if (_blink && options_pos == 1 && option_selected) {
			if (global.window_border) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+16, _y_pos+6, 1, 1, 0, c_white, 1); }
			else { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-16, _y_pos+6, -1, -1, 0, c_white, 1); }
		}
	}
	
	// Draw Controls Option
	_y_pos += _y_offset;
	if (_blink && options_pos == 2 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos, "Controls: ");
	draw_set_halign(fa_center);
	draw_text(_x_pos, _y_pos, get_input_string());
	if (_blink && options_pos == 2 && option_selected) {
		if (global.input < 1 || (global.input == 1 && gamepad_is_connected(global.gamepad))) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+40, _y_pos+6, 1, 1, 0, c_white, 1); }
		if (global.input > 0) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-40, _y_pos+6, -1, 1, 0, c_white, 1); }
	}
	
	// Draw Player Outline
	_y_pos += _y_offset;
	if (_blink && options_pos == 3 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos, "Player Outline: ");
	draw_set_halign(fa_center);
	draw_text(_x_pos, _y_pos, ((global.player_outline) ? "ON" : "OFF"));
	if (_blink && options_pos == 3 && option_selected) {
		if (!global.player_outline) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-16, _y_pos+6, -1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+16, _y_pos+6, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Screen Flash Option
	_y_pos += _y_offset;
	if (_blink && options_pos == 4 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos, "Screen Flash: ");
	draw_set_halign(fa_center);
	draw_text(_x_pos, _y_pos, ((global.can_screen_flash) ? "ON" : "OFF"));
	if (_blink && options_pos == 4 && option_selected) {
		if (!global.can_screen_flash) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-16, _y_pos+6, -1, 1, 0, c_white, 1); }
		else { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+16, _y_pos+6, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Color Option
	_x_pos -= 16;
	_y_pos += _y_offset;
	if (_blink && options_pos == 5 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos, "Color: ");
	draw_set_halign(fa_center);
	var _new_color = get_gms_color_from_hex_string(global.game_color_string), _underscore_string = " ";
	for (var _i = 0; _i < 6; _i++) {
		_underscore_string += (_i == color_options_pos) ? "_" : " ";
	}
	if (_blink && options_pos == 5 && option_selected) { draw_text(_x_pos, _y_pos+2, _underscore_string); }
	draw_text(_x_pos, _y_pos, "#"+global.game_color_string);
	draw_sprite_ext(spr_box, 0, 216, _y_pos+6, 0.875, 0.875, 0, _new_color, 1);
	
	// Draw Minimum Fade Option
	_x_pos -= 4;
	_y_pos += _y_offset*2;
	if (_blink && options_pos == 6 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6-_y_offset/2, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos-_y_offset, "Minimum\nBrightness: ");
	draw_set_halign(fa_center);
	draw_text(_x_pos, _y_pos-_y_offset/2, get_percentage_string(global.game_color_fade));
	if (_blink && options_pos == 6 && option_selected) {
		if (global.game_color_fade < 100) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+60, _y_pos+6-_y_offset/2, 1, 1, 0, c_white, 1); }
		if (global.game_color_fade > 0) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-32, _y_pos+6-_y_offset/2, -1, 1, 0, c_white, 1); }
	}
	var _new_color_minimum_fade = make_color_rgb(global.game_color_fade/100.0 * color_get_red(_new_color), global.game_color_fade/100.0 * color_get_green(_new_color), global.game_color_fade/100.0 * color_get_blue(_new_color));
	draw_sprite_ext(spr_box, 0, 216, _y_pos+6-_y_offset/2, 0.875, 0.875, 0, _new_color_minimum_fade, 1);
	
	// Draw Lava Edge Type Option
	_y_pos += _y_offset;
	if (_blink && options_pos == 7 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_left);
	draw_text(_text_x_pos, _y_pos, "Lava Edge: ");
	draw_set_halign(fa_center);
	draw_text(_x_pos, _y_pos-_y_offset/2, get_lava_edge_type_string());
	if (_blink && options_pos == 7 && option_selected) {
		if (global.lava_edge_type < lava_edge_types.wavy_animated) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos+80-16-4, _y_pos+6, 1, 1, 0, c_white, 1); }
		if (global.lava_edge_type > lava_edge_types.none) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos-32, _y_pos+6, -1, -1, 0, c_white, 1); }
	}
	
	// Draw Reset to Defaults Option
	_y_pos += _y_offset*2;
	if (_blink && options_pos == 8 && !option_selected) {  draw_sprite_ext(spr_menu_arrow, 0, _text_x_pos-8, _y_pos+6, 1, 1, 0, c_white, 1); }
	draw_set_halign(fa_center);
	draw_set_color(_game_color);
	draw_text(room_width/2, _y_pos, "Reset to Default Settings");
	draw_set_color(c_white);
	draw_set_halign(fa_center);
}
else if (controls_screen) {
	draw_set_valign(fa_middle);
	draw_set_halign(fa_left);
	var _x_pos = room_width/3+16, _y_pos = 80-16, _y_offset = 32, _x_offset = (global.input != inputs.gamepad) ? -8 : -8;
	 _title_y_pos = room_height*2;

	// Draw Controls
	draw_set_font(ft_hud_small);
	draw_set_halign(fa_left);
	draw_text(_x_pos+_x_offset, _y_pos,"Move / Push / Open");
	draw_text(_x_pos+_x_offset, _y_pos+_y_offset*1, "Left Hand:\nPick Up / Drop");
	draw_text(_x_pos+_x_offset, _y_pos+_y_offset*2, "Right Hand:\nPick Up / Drop");
	draw_text(_x_pos+_x_offset, _y_pos+_y_offset*3, "Hold to View Map");
	draw_text(_x_pos+_x_offset, _y_pos+_y_offset*4, "Hold to Tiptoe");
	draw_text(_x_pos+_x_offset, _y_pos+_y_offset*5-8, "Pause / Unpause Game");
	
	_x_pos = _x_pos - 40;
	if (global.input != inputs.gamepad) {
		_x_pos -= 8;
		var _input_offset = (global.input == inputs.keyboard_wasd) ? 6 : 0;
		
		draw_sprite_ext(spr_small_key, 0+_input_offset ,_x_pos, _y_pos-8, 1, 1, 1, (_game_manager.key_up ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 1+_input_offset, _x_pos + 16, _y_pos+8, 1, 1, 1, (_game_manager.key_right ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 2+_input_offset, _x_pos, _y_pos+8, 1, 1, 1, (_game_manager.key_down ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 3+_input_offset, _x_pos - 16, _y_pos+8, 1, 1, 1, (_game_manager.key_left ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 4+_input_offset, _x_pos, _y_pos+_y_offset*1, 1, 1, 1, (_game_manager.key_z ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_key, 5+_input_offset, _x_pos,_y_pos+_y_offset*2, 1, 1, 1, (_game_manager.key_x ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_key, 0, _x_pos, _y_pos+_y_offset*3, 1, 1, 1, (_game_manager.key_space ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_key, 2, _x_pos, _y_pos+_y_offset*4, 1, 1, 1, (_game_manager.key_shift ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_key, 1, _x_pos,_y_pos+_y_offset*5-8, 1, 1, 1, (_game_manager.key_enter ? _game_color : c_white), 1);
	}
	else {
		_x_pos -= 4;
		var _d_pad = _game_manager.key_up || _game_manager.key_down || _game_manager.key_right || _game_manager.key_left;
		draw_sprite_ext(spr_dpad, 0,_x_pos, _y_pos, 1, 1, 0, (_d_pad ? _game_color : c_white), 1);
		
		draw_sprite_ext(spr_small_button, 2, _x_pos - 14, _y_pos+_y_offset, 1, 1, 0, (_game_manager.key_z ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, _x_pos - 4, _y_pos+_y_offset, 1, 1, 0, (_game_manager.key_z ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 4, _x_pos + 14, _y_pos+_y_offset, 1, 1, 0, (_game_manager.key_z ? _game_color : c_white), 1);
		
		draw_sprite_ext(spr_small_button, 0, _x_pos - 14, _y_pos+_y_offset*2, 1, 1, 0, (_game_manager.key_x ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, _x_pos - 4, _y_pos+_y_offset*2, 1, 1, 0, (_game_manager.key_x ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 2, _x_pos + 14, _y_pos+_y_offset*2, 1, 1, 0, (_game_manager.key_x ? _game_color : c_white), 1);
		
		draw_sprite_ext(spr_small_button, 3, _x_pos, _y_pos+_y_offset*3-8, 1, 1, 0, (_game_manager.key_space ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 5, _x_pos - 18, _y_pos+_y_offset*3+8, 1, 1, 0, (_game_manager.key_space ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, _x_pos, _y_pos+_y_offset*3+8, 1, 1, 0, (_game_manager.key_space ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 3, _x_pos + 18, _y_pos+_y_offset*3+8, 1, 1, 0, (_game_manager.key_space ? _game_color : c_white), 1);
		
		
		draw_sprite_ext(spr_small_button, 1, _x_pos, _y_pos+_y_offset*4, 1, 1, 0, (_game_manager.key_shift ? _game_color : c_white), 1);
		
		draw_sprite_ext(spr_large_button, 0, _x_pos - 18, _y_pos+_y_offset*5-8, 1, 1, 0, (_game_manager.key_enter ? _game_color : c_white), 1);
		draw_sprite_ext(spr_small_button, 4, _x_pos, _y_pos+_y_offset*5-8, 1, 1, 0, (_game_manager.key_enter ? _game_color : c_white), 1);
		draw_sprite_ext(spr_large_button, 1, _x_pos + 18, _y_pos+_y_offset*5-8, 1, 1, 0, (_game_manager.key_enter ? _game_color : c_white), 1);
	}
}
else if (death_log_screen) {
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	draw_set_font(ft_hud);
	_title_y_pos = room_height*2;
	
	// Draw Headers
	var _y_initial = 16+8, _x_initial = (room_width/4)-16, _y_pos = _y_initial, _x_pos = _x_initial-24+2;
	var _killed_x_pos = (_x_initial*2)-22, _deaths_x_pos = (_x_initial*3)-8, _last_x_pos = (_x_initial*4)+16;
	draw_text(room_width/2, 15, get_difficulty_string(global.difficulty));
	_y_pos += 16;
	_y_pos += 16;
	draw_set_font(ft_hud_small);
	draw_set_color((death_log_sort == 0) ? _game_color : c_white);
	draw_text(_killed_x_pos+1, _y_pos, "Kills:");
	draw_set_color((death_log_sort == 1) ? _game_color : c_white);
	draw_text(_deaths_x_pos, _y_pos, "Deaths:");
	draw_set_color((death_log_sort == 2) ? _game_color : c_white);
	draw_text(_last_x_pos, _y_pos, "Last Run\nEnded:");
	draw_set_font(ft_hud);
	draw_set_color(c_white);
	
	// Draw Arrow Keys
	_y_pos += 40;
	if ((_blink || !_game_manager.key_up) && death_log_pos > 0) { draw_sprite_ext(spr_menu_arrow, 0 , _x_pos, _y_pos-4, 1, 1, 90, c_white, 1); }
	if ((_blink || !_game_manager.key_down) && death_log_pos < array_length(deaths_to_display)-death_types_on_screen) { draw_sprite_ext(spr_menu_arrow, 0, _x_pos, room_height-44, 1, 1, -90, c_white, 1); }
	if (!_game_manager.key_left && global.difficulty > difficulties.easy) { draw_sprite_ext(spr_menu_arrow, 0 , 24, 16, 1, 1, 180, c_white, 1); }
	if (!_game_manager.key_right && global.difficulty < difficulties.ALL) { draw_sprite_ext(spr_menu_arrow, 0, room_width-24, 16, 1, 1, 0, c_white, 1); }
	_y_pos += 10;
	
	// Draw Deaths
	for (var _i = 0; _i < death_types_on_screen; _i++) {
		var _log_pos = death_log_pos + _i;
		if (_log_pos >= array_length(deaths_to_display)) { break; }
		else {
			var _death_to_display = deaths_to_display[_log_pos], _death_obj = _death_to_display[0], _death_count = _death_to_display[1], _kill_count = _death_to_display[2], _last_killed = _death_to_display[3] ;
			var _last_killed_ordinal = "th", _last_killed_final_digit = string_char_at(string(_last_killed), string_length(_last_killed));
			if (_last_killed != 11 && _last_killed_final_digit == "1") { _last_killed_ordinal = "st"; }
			if (_last_killed != 12 && _last_killed_final_digit == "2") { _last_killed_ordinal = "nd"; }
			if (_last_killed != 13 && _last_killed_final_digit == "3") { _last_killed_ordinal = "rd"; }
			draw_death_type_sprite(_x_pos, _y_pos, _death_obj);
			draw_text(_killed_x_pos, _y_pos, string(_kill_count));
			draw_text(_deaths_x_pos, _y_pos, string(_death_count));
			draw_text(_last_x_pos, _y_pos, (_last_killed == 0) ? "--" : (string(_last_killed) + _last_killed_ordinal));
			_y_pos += 18;
		}
	}
}
else if (evaluation_log_screen) {
	// Draw Traits: each achievement earned (see update_traits_to_display)
	var _surface_width = room_width-(16*3);
	var _x_pos = 24, _y_pos = 0-trait_surface_y_pos, _y_offset = (16*3.5)-4;
	for (var _trait_pos = 0; _trait_pos < array_length(traits_to_display); _trait_pos += 1) {
		var _trait = traits_to_display[_trait_pos][0], _earned_count = traits_to_display[_trait_pos][1];
		
		// Draw Title
		draw_set_valign(fa_top);
		draw_set_font(ft_hud);
		draw_set_halign(fa_left);
		draw_set_font(ft_trait_title);
		draw_set_color((_trait.is_negative) ? _game_color : c_white);
		draw_text(_x_pos, _y_pos+_y_offset, _trait.title);
		
		// Draw Value
		draw_set_halign(fa_right);
		draw_text(room_width-24, _y_pos+_y_offset, string(_earned_count));
		
		// Draw Description
		_y_pos += 14;
		draw_set_halign(fa_left);
		draw_set_color(c_white);
		draw_set_font(ft_trait_description);
		draw_text_ext(_x_pos, _y_pos+_y_offset, _trait.description, 10, _surface_width);
		_y_pos += string_height_ext(_trait.description, 10, _surface_width);
		_y_pos += 4;
	}
	trait_surface_y_max = _y_pos;
	// Draw Background
	draw_set_color(global.bg_color);
	draw_rectangle(0, 0, room_width, _y_offset, false);
	draw_rectangle(0, room_height-(16*3.5), room_width, room_height, false);
	
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	draw_set_font(ft_hud);
	_title_y_pos = room_height*2;
		
	// Draw Header
	draw_set_color(c_white);
	var _y_initial = 16+8, _x_initial = (room_width/4)-16;
	_y_pos = _y_initial;
	_x_pos = _x_initial-20;
	var _best_score_string = _history_record.get_best_score_string();
	draw_text(room_width/2, 15, get_difficulty_string(global.difficulty));
	
	// Draw Scores
	draw_set_font(ft_hud_small);
	draw_set_color(c_white);
	var _outcome_text = "";
	if (_win_count_string != "" && _death_count_string != "") { _outcome_text = _death_count_string+ "; "+_win_count_string; }
	else { _outcome_text = _death_count_string + _win_count_string; }
	if (_outcome_text != "") { draw_text(room_width/2, room_height-16-12-12, _outcome_text); }
	if (_best_score_string != noone) { draw_text(room_width/2, room_height-16-12, _best_score_string); }
	
	// Draw Arrow Keys
	_y_pos += 28;
	if ((_blink || !_game_manager.key_up) && trait_surface_y_pos > 0) { draw_sprite_ext(spr_menu_arrow, 0 , room_width/2, _y_pos-4, 1, 1, 90, c_white, 1); }
	if ((_blink || !_game_manager.key_down) && trait_surface_y_pos < trait_surface_y_max-(room_height-(16*7))) { draw_sprite_ext(spr_menu_arrow, 0, room_width/2, room_height-(16*3.5)+4, 1, 1, -90, c_white, 1); }
	if (!_game_manager.key_left && global.difficulty > difficulties.easy) { draw_sprite_ext(spr_menu_arrow, 0 , 24, 16, 1, 1, 180, c_white, 1); }
	if (!_game_manager.key_right && global.difficulty < difficulties.ALL) { draw_sprite_ext(spr_menu_arrow, 0, room_width-24, 16, 1, 1, 0, c_white, 1); }
}
else {
	// Draw Main Menu
	draw_set_valign(fa_middle);
	draw_set_halign(fa_left);
	_title_y_pos = room_height/4-16;
	
	// Draw Game Version
	draw_set_font(ft_hud_small);
	draw_set_halign(fa_center);
	draw_text(room_width/2, room_height-16, "v. " + string(GM_version));
	draw_set_font(ft_hud);
	
	// Draw farmer mode selection
	if (_blink && pos == -1) {
		if (global.graphics_mode != graphics_modes.standard) { draw_sprite_ext(spr_title_arrow, 0, room_width/4-32, _title_y_pos, 1, 1, 0, c_white, 1); }
		if (global.graphics_mode == graphics_modes.standard || (can_play_unknown_mode() && global.graphics_mode == graphics_modes.farmer)) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4+32, _title_y_pos, -1, 1, 0, c_white, 1); }
	}
	
	// Draw difficulty selection
	draw_set_halign(fa_center);
	draw_set_font(ft_hud_large);
	var _difficulty_y_pos = _title_y_pos + room_height/4 - 32 + 8;
	draw_text(room_width/2, _difficulty_y_pos, get_difficulty_string(global.difficulty));
	draw_set_font(ft_hud);
	if (_blink && pos == 0) {
		if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, 24, _difficulty_y_pos+2, 1, 1, 0, c_white, 1); }
		if (global.difficulty < get_max_difficulty()) { draw_sprite_ext(spr_title_arrow, 0, room_width - 24, _difficulty_y_pos+2, -1, 1, 0, c_white, 1); }
	}
	// Draw death count for current difficulty
	if (_run_count_string != noone) { draw_text(room_width/2, _difficulty_y_pos+20, _run_count_string); }
	
	// Draw remaining menu options
	var _message_y_pos = _difficulty_y_pos+16+24+16, _messages_y_offset = -1, _message_x_pos = 56;
	draw_set_halign(fa_left);
	draw_set_font(ft_hud);
	draw_text(_message_x_pos, _message_y_pos+_messages_y_offset, get_seed_option_string());
	draw_text(_message_x_pos, _message_y_pos+_messages_y_offset+32, "Options");
	draw_text(_message_x_pos, _message_y_pos+_messages_y_offset+48, "View Controls");
	if (_can_view_logs) { draw_text(_message_x_pos, _message_y_pos+_messages_y_offset+64, + "View Death Log"); }
	if (_can_view_logs) { draw_text(_message_x_pos, _message_y_pos+_messages_y_offset+80, + "View Earned Traits"); }
	var _arrow_y =-64;
	if (pos == 1) { _arrow_y = _message_y_pos; }
	else if (pos == 2) { _arrow_y = _message_y_pos+16; }
	else if (pos == 3) { _arrow_y = _message_y_pos+32; }
	else if (pos == 4) { _arrow_y = _message_y_pos+48; }
	else if (pos == 5) { _arrow_y = _message_y_pos+64; }
	else if (pos == 6) { _arrow_y = _message_y_pos+80; }
	
	// Draw seed
	if (global.seed_option == seed_options.specified) {
		draw_set_halign(fa_center);
		draw_text(room_width/2, _message_y_pos+_messages_y_offset+16, get_zero_padded_string(current_seed, 9)); 
		draw_set_halign(fa_left);
	}
	if (_blink) {
		if (pos == 1 && global.is_test_mode) {
			// Draw option arrows
			if (_blink) {
				if (global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) { draw_sprite_ext(spr_title_arrow, 0, _message_x_pos-16, _arrow_y, 1, 1, 0, c_white, 1); }
				if (global.seed_option < seed_options.specified) { draw_sprite_ext(spr_title_arrow, 0, _message_x_pos+64, _arrow_y, -1, 1, 0, c_white, 1); }
			}
		}
		else if (pos == 2) {
			if (current_seed < MAX_SEED) { draw_sprite_ext(spr_title_arrow, 0, room_width/2 - 40, _arrow_y, 1, 1, 0, c_white, 1); }
			if (current_seed > 0) { draw_sprite_ext(spr_title_arrow, 0, room_width/2 + 40, _arrow_y, -1, 1, 0, c_white, 1); }
		}
		else { draw_sprite_ext(spr_title_arrow, 0, _message_x_pos-16, _arrow_y, -1, 1, 0, c_white, 1); }
	}
}

// Draw General Submenu Info
draw_set_color(c_white);
draw_set_font(ft_hud);
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
var _submenu_title = "";

if (prepare_screen) { _submenu_title = "Prepare Yourself"; }
else if (options_screen) { _submenu_title = "Options"; }
else if (controls_screen) { _submenu_title = "View Controls"; }
else if (death_log_screen) { _submenu_title = "View Death Log"; }
if (options_screen || controls_screen || death_log_screen || evaluation_log_screen || prepare_screen) {
	draw_set_font(ft_hud);
	if (!death_log_screen && !evaluation_log_screen) { draw_text(room_width/2, 16, _submenu_title); }
	
	draw_set_font(ft_hud_small);
	draw_set_color(c_white);
	
	var _return_text = "";
	if (death_log_screen || evaluation_log_screen) { _return_text += get_input_z_key_string() + ": Change Sort; "; }
	else if (options_screen) { _return_text += get_input_z_key_string() + ": Select Option; "; }
	else if (prepare_screen) { _return_text += get_input_z_key_string() + ": Begin; "; }
	_return_text += get_input_x_key_string() + ": Return";
	
	draw_set_color(_game_color);
	draw_text(room_width/2, room_height-15, _return_text);
	draw_set_font(ft_hud);
}

// Draw Border
if (!loading) {
	var _main_menu = (!prepare_screen && !options_screen && !death_log_screen && !controls_screen && !evaluation_log_screen), _wall_sprite_color = merge_color(c_white, c_black, 0.5);
	// Draw Horizontal Border Lines
	for (var _border_x_pos = -8; _border_x_pos < room_width+16; _border_x_pos += 16;) {
		draw_sprite_ext(spr_wall, 0, _border_x_pos, 0, 1, 1, 0, _wall_sprite_color, 1);
		draw_sprite_ext(spr_wall, 0, _border_x_pos, room_height, 1, 1, 0, _wall_sprite_color, 1);
		
		if (_main_menu) {
			draw_sprite_ext(spr_wall, 0, _border_x_pos, (16*8), 1, 1, 0, _wall_sprite_color, 1);
			if (global.seed_option != seed_options.specified || _border_x_pos < room_width/2 - 48 || _border_x_pos > room_width/2 + 48) {  
				draw_sprite_ext(spr_wall, 0, _border_x_pos, room_height-(16*6), 1, 1, 0, _wall_sprite_color, 1); 
			}
		}
		else if (death_log_screen) {
			draw_sprite_ext(spr_wall, 0, _border_x_pos, (16*2), 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(spr_wall, 0, _border_x_pos, (16*5), 1, 1, 0, _wall_sprite_color, 1);
		draw_sprite_ext(spr_wall, 0, _border_x_pos, room_height-32, 1, 1, 0, _wall_sprite_color, 1);
		}
		else if (prepare_screen) {
			draw_sprite_ext(spr_wall, 0, _border_x_pos, (16*3), 1, 1, 0, _wall_sprite_color, 1);
		}
		else {
			draw_sprite_ext(spr_wall, 0, _border_x_pos, (16*2), 1, 1, 0, _wall_sprite_color, 1);
		}
	}
	// Draw Vertical Border Lines
	for (var _border_y_pos = -16; _border_y_pos < room_height+16; _border_y_pos += 16;) {
		draw_sprite_ext(spr_wall, 0, 8, _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
		if (_main_menu && (_border_y_pos < 16*1 || _border_y_pos > 16*7)) { 
			draw_sprite_ext(spr_wall, 0, 8+16, _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
			if (_border_y_pos < room_height) { draw_sprite_ext(spr_wall, 0, room_width-8-16, _border_y_pos, 1, 1, 0, _wall_sprite_color, 1); }
		}
		else if (death_log_screen && _border_y_pos > 8+(16*2) && _border_y_pos < room_height-(16*1)) {
			draw_sprite_ext(spr_wall, 0, -4+(16*3), _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(spr_wall, 0, -8+(16*7), _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
			draw_sprite_ext(spr_wall, 0, -8+(16*11), _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
		}
		draw_sprite_ext(spr_wall, 0, room_width-8, _border_y_pos, 1, 1, 0, _wall_sprite_color, 1);
	}
}

// Draw Logo
draw_set_valign(fa_middle);
draw_set_halign(fa_center);
draw_set_font(ft_hud_giant);
draw_set_color(_game_color);
draw_text(room_width/2, _title_y_pos, get_graphics_mode_string(global.graphics_mode));
