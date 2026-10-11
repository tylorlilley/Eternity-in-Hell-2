var _bg_color = global.bg_color;

// Draw it only when it's lit (an unlit one is blended to the background color)
if (image_blend != _bg_color) {
	event_inherited();
}

// Where the worm turns, fill the corner with an extra tile (placed in End Step), when that spot is lit
if (corner_blend != _bg_color && head && head.x != x && head.y != y) {
	draw_sprite_ext(sprite_index, 2, corner_x, corner_y, corner_x_scale, corner_y_scale, 0, corner_blend, image_alpha);
}