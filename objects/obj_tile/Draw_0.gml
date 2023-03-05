for (var quadrant = 0; quadrant < 4; quadrant++;) {
	var x_offset = 0, y_offset = 0;
	switch (quadrant) {
		case 0: { y_offset = -8; x_offset = -8; break; }
		case 1: { y_offset = -8; x_offset = 8; break; }
		case 2: { y_offset = 8; x_offset = -8; break; }
		case 3: { y_offset = 8 x_offset = 8; break; }
	}
		
	var prev_sprite_index = sprite_index;
	if (is_existing_instance(parts[quadrant]) && parts[quadrant].part_visible) {
		var draw_x_pos = (x_offset < 0) ? -8 : 0, draw_y_pos = (y_offset < 0) ? -8 : 0, sprite_x_pos = (x_offset < 0) ? 0 : 8, sprite_y_pos = (y_offset < 0) ? 0 : 8;
		draw_sprite_general(prev_sprite_index, image_index, sprite_x_pos, sprite_y_pos, sprite_width/2, sprite_height/2, x+draw_x_pos, y+draw_y_pos, 1, 1, 0, image_blend, image_blend, image_blend, image_blend, image_alpha);
	}
	sprite_index = prev_sprite_index;
}
