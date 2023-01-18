// Draw box over lava or staff solids
if (get_carried_item_of_type(obj_staff) != noone) {
	var lava_at_quadrant = get_instance_at_each_quadrant(obj_lava), wall_at_quadrant = get_instance_at_each_quadrant(obj_wall), column_at_quadrant = get_instance_at_each_quadrant(obj_column);
	for (var i = 0; i <= 3; i +=1;) {
		var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

		if (lava_at_quadrant[i] != noone || wall_at_quadrant[i] != noone || column_at_quadrant[i] != noone) {
		    draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
		}
	}
}

// Draw main sprite
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

