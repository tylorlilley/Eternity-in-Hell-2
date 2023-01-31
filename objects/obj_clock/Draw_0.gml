var controller = global.controller;
var sand_sprite_index = (special) ? spr_sand_red : spr_sand;
var time_elapsed = controller.time_provided - controller.time_remaining;
var time_per_grain = (time_elapsed / controller.time_provided)
var sand_image_index = floor(abs((time_per_grain*8) - (time_per_grain*3/4)));
var sand_y = y, sand_x = x;
if (is_existing_instance(holder)) {
	sand_y += draw_y_offset;
	sand_x += (holder.right_hand_item == id) ? 8 : -8;
}

draw_sprite_ext(sand_sprite_index, sand_image_index, sand_x, sand_y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
    
event_inherited();

