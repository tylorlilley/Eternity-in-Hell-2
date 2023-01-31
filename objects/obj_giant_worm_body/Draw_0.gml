var bg_color = global.bg_color;

if (image_blend != bg_color) {
	event_inherited();
}

// Draw extra tile when changing direction for tail
if (corner_blend != bg_color && head && head.x != x && head.y != y) {
	draw_sprite_ext(sprite_index, 2, corner_x, corner_y, corner_x_scale, corner_y_scale, 0, corner_blend, image_alpha);
}