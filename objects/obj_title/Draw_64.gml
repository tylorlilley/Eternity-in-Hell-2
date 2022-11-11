/// @description Insert description here
// You can write your code in this editor


draw_set_color(c_white);
draw_set_font(ft_hud);
draw_set_halign(fa_center);
draw_set_halign(fa_middle);

// Draw difficulty selection
draw_text(room_height/2, room_width/2, difficulty_string());
if (blink && pos == 0) {
	if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2 + 8, 1, 1, 1, c_white, 1); }
	if (global.difficulty < difficulties.very_hard) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2 + 8, -1, 1, 1, c_white, 1); }
}

// Draw seed selection
draw_text(room_height/2, room_width/2+16, seed_option_string(seed_option));
if (blink && pos == 1) {
	if (seed_option > seed_options.rand || (seed_option > seed_options.same && global.seed)) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2 + 24, 1, 1, 1, c_white, 1); }
	if (seed_option < seed_options.specified) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2 + 24, -1, 1, 1, c_white, 1); }
}

// Draw seed
if (seed_option == seed_options.specified) { draw_text(room_height/2, room_width/2+32, zero_padded_string(current_seed, 9)); }
if (blink && pos == 2) {
	if (current_seed < 99999999) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2 + 40, -1, 1, 1, c_white, 1); }
    if (current_seed > 0) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2 + 40, 1, 1, 1, c_white, 1); }
}