var player = global.player;
if (is_blink_frame() && (place_meeting(x, y, obj_enemy) || place_meeting(x, y, player) || place_meeting(x, y, obj_fireball))) {
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
		var x_offset = 0, y_offset = 0;
		switch (quadrant) {
			case 0: { y_offset = -8; x_offset = -8; break; }
			case 1: { y_offset = -8; x_offset = 8; break; }
			case 2: { y_offset = 8; x_offset = -8; break; }
			case 3: { y_offset = 8 x_offset = 8; break; }
		}
		
		var prev_sprite_index = sprite_index;
		if (!place_meeting(x+x_offset, y+y_offset, obj_enemy) && !place_meeting(x+x_offset, y+y_offset, player) && !place_meeting(x+x_offset, y+y_offset, obj_fireball)) {
			var draw_x_pos = (x_offset < 0) ? -8 : 0, draw_y_pos = (y_offset < 0) ? -8 : 0, sprite_x_pos = (x_offset < 0) ? 0 : 8, sprite_y_pos = (y_offset < 0) ? 0 : 8;
			draw_sprite_general(prev_sprite_index, image_index, sprite_x_pos, sprite_y_pos, sprite_width/2, sprite_height/2, x+draw_x_pos, y+draw_y_pos, image_xscale, image_yscale, image_angle, image_blend, image_blend, image_blend, image_blend, image_alpha);
		}
		sprite_index = prev_sprite_index;
	}
}
else { event_inherited(); }
