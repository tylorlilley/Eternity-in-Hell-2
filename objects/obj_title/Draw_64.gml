/// @description Insert description here
// You can write your code in this editor
var death_count_string = get_death_count_string(global.difficulty);

if keyboard_check(vk_space) {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	
	// Draw Controls
	draw_set_halign(fa_left);
	draw_text(room_width/4-4, room_height/2-16,"Move / Push / Open");
	draw_text(room_width/4-4, room_height/2+16+8, "Left Hand - Take / Drop");
	draw_text(room_width/4-4, room_height/2+16+16+8, "Right Hand - Take / Drop");
	draw_text(room_width/4-4, room_height/2+16+16+24+8, "Hold to Look at Map");
	draw_text(room_width/4-4, room_height/2+16+16+24+24+8, "Return to Title Screen");
	
	draw_sprite(spr_small_key, 0, room_width/4 - 36, room_height/2-16-8);
	draw_sprite(spr_small_key, 1,  room_width/4 - 36 + 16, room_height/2-8);
	draw_sprite(spr_small_key, 2, room_width/4 - 36, room_height/2-8);
	draw_sprite(spr_small_key, 3, room_width/4 - 36 - 16, room_height/2-8);
	draw_sprite(spr_small_key, 4, room_width/4 - 36, room_height/2+32-8);
	draw_sprite(spr_small_key, 5, room_width/4 - 36, room_height/2+32+16-8);
	draw_sprite(spr_large_key, 0, room_width/4 - 36, room_height/2+32+16+24-8);
	draw_sprite(spr_large_key, 1, room_width/4 - 36, room_height/2+32+16+24+24-8);
	
	// Draw Game Version
	draw_set_halign(fa_right);
	draw_text(room_width, 16, "v." + string(GM_version));
}
else if (keyboard_check(ord("Z")) && death_count_string != noone) {
	draw_set_color(c_black);
	draw_rectangle(0, 0, room_width, room_height, false);
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	
	// Draw General Log Info
	draw_set_halign(fa_center);
	
	var win_count_string = get_win_count_string(global.difficulty), best_score_string = get_best_score_string(global.difficulty);
	draw_text(room_width/2, 16, "Death Log for " + get_difficulty_string(global.difficulty));
	if (death_count_string != noone) { draw_text(room_width/2, 16*2, death_count_string); }
	if (win_count_string != noone) { draw_text(room_width/2, room_height-8, win_count_string); }
	if (best_score_string != noone) { draw_text(room_width/2, room_height-8-16, best_score_string); }
	
	// Create list of all deaths to display
	var death_types = get_death_types(), deaths_to_display = array_create(0),
	
	while (array_length(death_types) > 0) {
		var death_type = array_pop(death_types);
		
		var death_count = get_death_count(death_type, global.difficulty);
		if (death_count > 0) { array_push(deaths_to_display, [death_type, death_count]); }
	}
	
	// Cycle through deaths to display
	draw_set_halign(fa_left);
	var y_initial = (16*3)+14, x_columns = (array_length(deaths_to_display) <= 9) ? 3 : 5, x_initial = room_width/x_columns, y_pos = y_initial, x_pos = x_initial;
	while (array_length(deaths_to_display) > 0) {
		var death_to_display = array_pop(deaths_to_display), death_object = death_to_display[0], death_count = death_to_display[1];
		
		// Draw Death Sprite and Count
		draw_death_type_sprite(x_pos, y_pos, death_object);
		draw_text(x_pos+x_initial, y_pos, string(death_count));
		
		// Increase Draw Position
		y_pos += 18;
		if (y_pos > (y_initial+(18*8))) { y_pos = y_initial; x_pos = x_initial*4; }
	}
}
else {
	draw_set_color(c_white);
	draw_set_font(ft_hud);
	draw_set_valign(fa_middle);
	draw_set_halign(fa_center);
	
	// Draw farmer mode selection
	if (blink && pos == -1) {
		if (global.FARM_MODE) { draw_sprite_ext(spr_title_arrow, 0, room_width/4, room_height/4, 1, 1, 0, c_white, 1); }
		if (!global.FARM_MODE) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4, room_height/4, -1, 1, 0, c_white, 1); }
	}
	var title_background = layer_background_get_id("background");
	layer_background_sprite(title_background, (global.FARM_MODE) ? bg_title_farmer : bg_title)
	
	// Draw death count for current difficulty
	if (death_count_string != noone) { draw_text(room_width/2, (room_height/2)-16, death_count_string); }
	
	// Draw difficulty selection
	draw_text(room_width/2, room_height/2, get_difficulty_string(global.difficulty));
	if (blink && pos == 0) {
		if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2, 1, 1, 0, c_white, 1); }
		if (global.difficulty < difficulties.very_hard) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2, -1, 1, 0, c_white, 1); }
	}

	// Draw seed selection
	draw_text(room_width/2, room_height/2+16, get_seed_option_string());
	if (blink && pos == 1) {
		if (global.seed_option > seed_options.rand || (global.seed_option > seed_options.same && global.seed)) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2 + 16, 1, 1, 0, c_white, 1); }
		if (global.seed_option < seed_options.specified) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2 + 16, -1, 1, 0, c_white, 1); }
	}

	// Draw seed
	if (global.seed_option == seed_options.specified) { draw_text(room_width/2, room_height/2+32, get_zero_padded_string(current_seed, 9)); }
	if (blink && pos == 2) {
		if (current_seed < 99999999) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2 + 32, -1, 1, 0, c_white, 1); }
	    if (current_seed > 0) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2 + 32, 1, 1, 0, c_white, 1); }
	}
	
	// Draw Settings Switch Messages
	if (death_count_string != noone) { draw_text(room_width/2, room_height/2+32+32-16, "Hold Z Key to view death log"); }
	draw_text(room_width/2, room_height/2+32+32, "Hold Space Key to view controls");
	draw_text(room_width/2, room_height/2+32+32+16, "Press Enter Key to begin");
}