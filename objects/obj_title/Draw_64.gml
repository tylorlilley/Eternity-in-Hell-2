/// @description Insert description here
// You can write your code in this editor


draw_set_color(c_white);
draw_set_font(ft_hud);
draw_set_halign(fa_center);
draw_set_halign(fa_middle);
draw_text(room_height/2, room_width/2, difficulty_string());
if (blink) {
	if (global.difficulty > difficulties.easy) { draw_sprite_ext(spr_title_arrow, 0, room_width/4 - 16, room_height/2 + 8, 1, 1, 1, c_white, 1); }
	if (global.difficulty < difficulties.very_hard) { draw_sprite_ext(spr_title_arrow, 0, 3*room_width/4 + 16, room_height/2 + 8, -1, 1, 1, c_white, 1); }
}
