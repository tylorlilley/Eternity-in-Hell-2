var _player = global.player
if (is_blink_frame() && (place_meeting(x, y, obj_hands) || place_meeting(x, y, _player))) {
	for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
		var _x_offset = 0, _y_offset = 0;
		switch (_quadrant) {
			case 0: { _y_offset = -8; _x_offset = -8; break; }
			case 1: { _y_offset = -8; _x_offset = 8; break; }
			case 2: { _y_offset = 8; _x_offset = -8; break; }
			case 3: { _y_offset = 8 _x_offset = 8; break; }
		}
		
		var _prev_sprite_index = sprite_index;
		if (!place_meeting(x+_x_offset, y+_y_offset, obj_hands) && !place_meeting(x+_x_offset, y+_y_offset, _player)) {
			var _draw_x_pos = (_x_offset < 0) ? -8 : 0, _draw_y_pos = (_y_offset < 0) ? -8 : 0, _sprite_x_pos = (_x_offset < 0) ? 0 : 8, _sprite_y_pos = (_y_offset < 0) ? 0 : 8;
			draw_sprite_general(_prev_sprite_index, image_index, _sprite_x_pos, _sprite_y_pos, sprite_width/2, sprite_height/2, x+_draw_x_pos, y+_draw_y_pos, image_xscale, image_yscale, image_angle, image_blend, image_blend, image_blend, image_blend, image_alpha);
		}
		sprite_index = _prev_sprite_index;
	}
}
else { event_inherited(); }
