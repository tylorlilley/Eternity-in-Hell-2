image_xscale = (keyboard_check(ord("Z"))) ? -1 : 1;
image_yscale = (keyboard_check(ord("X"))) ? -1 : 1;
sprite_index = (keyboard_check(ord("C"))) ? spr_draw_tester_small : spr_draw_tester;

var mirror_x = x, mirror_y = y;
var mirror_width = 16, mirror_height = 16, surface_width = 12, surface_height = 12, spr_width = sprite_get_width(sprite_index), spr_height = sprite_get_height(sprite_index);
var border_x_offset = (spr_width - surface_width)/2, border_y_offset = (spr_height - surface_height)/2;
var left_offset = border_x_offset, top_offset = border_y_offset;

var x_pos = mirror_x+x_pos_dif-sprite_get_xoffset(sprite_index), y_pos = mirror_y+y_pos_dif-sprite_get_yoffset(sprite_index);
var refl_width = spr_width-abs(x_pos_dif), refl_height = spr_height-abs(y_pos_dif), refl_x_pos = x_pos, refl_y_pos = y_pos;
if (x_pos_dif < border_x_offset) { refl_width -= border_x_offset; refl_x_pos += border_x_offset; left_offset -= x_pos_dif; }
if (x_pos_dif+spr_width > mirror_width-border_x_offset) { refl_width -= border_x_offset; }
if (y_pos_dif < border_y_offset) { refl_height -= border_x_offset; refl_y_pos += border_x_offset; top_offset -= y_pos_dif; }
if (y_pos_dif+spr_width > mirror_height-border_y_offset) { refl_height -= border_x_offset; }

draw_sprite_part_ext(sprite_index, 0, 0, 0, refl_width, refl_height, refl_x_pos, refl_y_pos, 1, 1, c_white, 1);

draw_sprite(spr_highlight, 0, x+16, y+16);
draw_sprite(spr_highlight, 0, x+16, y);
draw_sprite(spr_highlight, 0, x+16, y-16);
draw_sprite(spr_highlight, 0, x, y+16);
draw_sprite(spr_highlight, 0, x, y-16);
draw_sprite(spr_highlight, 0, x-16, y+16);
draw_sprite(spr_highlight, 0, x-16, y);
draw_sprite(spr_highlight, 0, x-16, y-16);

/*
var mirror_width = 12, mirror_height = 12;
var border_x_offset = abs(sprite_width)/2 - mirror_width/2, border_y_offset = abs(sprite_height)/2 - mirror_height/2;
var inverse_border_x_offset = 0, inverse_border_y_offset = 0;
if (border_x_offset < 0) { inverse_border_x_offset = -border_x_offset; border_x_offset = 0; }
if (border_y_offset < 0) { inverse_border_y_offset = -border_y_offset; border_y_offset = 0; }
var refl_width = abs(sprite_width)-(2*border_x_offset), refl_height = abs(sprite_height)-(2*border_y_offset);
var neg_xscale_offset = ((refl_width/4)-(refl_width/4*image_xscale)), neg_yscale_offset = ((refl_height/4)-(refl_height/4*image_yscale));
var origin_x_offset = -image_xscale * (refl_width/2), origin_y_offset = -image_yscale * (refl_height/2);
//var mirror_x_offset = -image_xscale * origin_x_offset, mirror_y_offset = -image_yscale * origin_y_offset;
var mirror_x_offset = (image_xscale == 1) ? 0 : abs(sprite_width)/4;

if (keyboard_check(ord("Q"))) {
	// Left Half Displayed to the Right
	draw_sprite_part_ext(sprite_index, 0, neg_xscale_offset+mirror_x_offset, border_y_offset+neg_yscale_offset+0, refl_width/2, refl_height, x+origin_x_offset-neg_xscale_offset+6, y+origin_y_offset-neg_yscale_offset+0, image_xscale, image_yscale, c_white, 1);
}
else if (keyboard_check(ord("W"))) {
	// Top Half Displayed to the Bottom
	draw_sprite_part_ext(sprite_index, 0, border_x_offset+neg_xscale_offset+0, neg_yscale_offset+0, refl_width, refl_height/2, x+origin_x_offset-neg_xscale_offset+0, y+origin_y_offset-neg_yscale_offset+6, image_xscale, image_yscale, c_white, 1);
}
else if (keyboard_check(ord("A"))) {
	// Right Half Displayed to the Left
	draw_sprite_part_ext(sprite_index, 0, neg_xscale_offset+(refl_width/2)+border_x_offset, border_y_offset+neg_yscale_offset+0, refl_width/2+border_x_offset, refl_height, x+origin_x_offset-neg_xscale_offset-inverse_border_x_offset+0, y+origin_y_offset-neg_yscale_offset+0, image_xscale, image_yscale, c_white, 1);
}
else if (keyboard_check(ord("S"))) {
	// Bottom Half Displayed to the Top
	draw_sprite_part_ext(sprite_index, 0, border_x_offset+neg_xscale_offset+0, neg_yscale_offset+(refl_height/2)+border_y_offset, refl_width, refl_height/2+border_y_offset, x+origin_x_offset-neg_xscale_offset+0, y+origin_y_offset-neg_yscale_offset-inverse_border_y_offset+0, image_xscale, image_yscale, c_white, 1);
}
else {
	draw_sprite_part_ext(sprite_index, 0, border_x_offset, border_y_offset, refl_width, refl_height, x+origin_x_offset, y+origin_y_offset, image_xscale, image_yscale, c_white, 1);
}
*/
/*
if (keyboard_check(ord("Q"))) {
	draw_sprite_part_ext(sprite_index, 0, border_x_offset+neg_xscale_offset, border_y_offset+neg_yscale_offset, refl_width/2, refl_height/2, x+origin_x_offset-neg_xscale_offset, y+origin_y_offset-neg_yscale_offset, image_xscale, image_yscale, c_white, 1);
}
else if (keyboard_check(ord("W"))) {
	draw_sprite_part_ext(sprite_index, 0, border_x_offset+neg_xscale_offset, border_y_offset+neg_yscale_offset, refl_width/2, refl_height/2, x+origin_x_offset-neg_xscale_offset+mirror_x_offset, y+origin_y_offset-neg_yscale_offset, image_xscale, image_yscale, c_white, 1);
}
else if (keyboard_check(ord("A"))) {
	draw_sprite_part_ext(sprite_index, 0, border_x_offset+neg_xscale_offset, border_y_offset+neg_yscale_offset, refl_width/2, refl_height/2, x+origin_x_offset-neg_xscale_offset, y+origin_y_offset-neg_yscale_offset+mirror_y_offset, image_xscale, image_yscale, c_white, 1);
}
else if (keyboard_check(ord("S"))) {
	draw_sprite_part_ext(sprite_index, 0, border_x_offset+neg_xscale_offset, border_y_offset+neg_yscale_offset, refl_width/2, refl_height/2, x+origin_x_offset-neg_xscale_offset+mirror_x_offset, y+origin_y_offset-neg_yscale_offset+mirror_y_offset, image_xscale, image_yscale, c_white, 1);
}
else {
	draw_sprite_part_ext(sprite_index, 0, border_x_offset, border_y_offset, refl_width, refl_height, x+origin_x_offset, y+origin_y_offset, image_xscale, image_yscale, c_white, 1);
}
*/

