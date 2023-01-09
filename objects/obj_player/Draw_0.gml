event_inherited();
// Draw Carried items
with (carried_items[directions.left]) { draw_sprite_ext(sprite_index, image_index, x-8, y+draw_y_offset, image_xscale, image_yscale, image_angle, image_blend, image_alpha); } 
with (carried_items[directions.right]) { draw_sprite_ext(sprite_index, image_index, x+8, y+draw_y_offset, image_xscale, image_yscale, image_angle, image_blend, image_alpha); } 

// Draw Hands
if ((image_xscale == 1 && carried_items[directions.left] != noone) || (image_xscale == -1 && carried_items[directions.right] != noone)) {
	draw_sprite_ext(spr_player_left_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}
if ((image_xscale == -1 && carried_items[directions.left] != noone) || (image_xscale == 1 && carried_items[directions.right] != noone)) {
	draw_sprite_ext(spr_player_right_hand, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
}
	
if (global.controller.FARM_MODE) { draw_sprite_ext(spr_player_farmer, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }

