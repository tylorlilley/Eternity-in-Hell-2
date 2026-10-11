for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
	var _x_offset = 0, _y_offset = 0;
	switch (_quadrant) {
		case 0: { _y_offset = -8; _x_offset = -8; break; }
		case 1: { _y_offset = -8; _x_offset = 8; break; }
		case 2: { _y_offset = 8; _x_offset = -8; break; }
		case 3: { _y_offset = 8 _x_offset = 8; break; }
	}
		
	var _prev_sprite_index = sprite_index;
	if (is_existing_instance(parts[_quadrant]) && parts[_quadrant].part_visible) {
		var _draw_x_pos = (_x_offset < 0) ? -8 : 0, _draw_y_pos = (_y_offset < 0) ? -8 : 0, _sprite_x_pos = (_x_offset < 0) ? 0 : 8, _sprite_y_pos = (_y_offset < 0) ? 0 : 8;
		draw_sprite_general(_prev_sprite_index, image_index, _sprite_x_pos, _sprite_y_pos, sprite_width/2, sprite_height/2, x+_draw_x_pos, y+_draw_y_pos, 1, 1, 0, image_blend, image_blend, image_blend, image_blend, image_alpha);
	}
	sprite_index = _prev_sprite_index;
}
