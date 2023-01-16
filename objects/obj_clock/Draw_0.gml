var sand_sprite_index = (special) ? spr_sand_red : spr_sand;
var time_elapsed = global.controller.time_provided - global.controller.time_remaining;
var time_per_grain = (time_elapsed / global.controller.time_provided)
var sand_image_index = floor(abs((time_per_grain*8) - (time_per_grain*3/4)));
var sand_y = y, sand_x = x;
if (carried != noone) {
	sand_y += draw_y_offset;
	sand_x += (carried == directions.right) ? 8 : -8;
}

draw_sprite_ext(sand_sprite_index, sand_image_index, sand_x, sand_y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
    
event_inherited();

