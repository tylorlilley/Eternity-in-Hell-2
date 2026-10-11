var _player = global.player;


// On blink frames, leave out each quarter of the wall that holds the player, a corporeal enemy, a block or a fireball,
// so what's inside the illusion wall blinks into view
if (is_blink_frame()) {
	for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
		var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
		// Check this quarter with a quarter-sized mask
		mask_index = spr_quadrant;
		
		var _obj_is_here = place_meeting(_x_pos, _y_pos, _player);
		// Check for enemies to break illusion
		if (!_obj_is_here) {
			var _enemies_at_pos = instance_place_all(_x_pos, _y_pos, obj_enemy);
			for (var _i = 0; _i < array_length(_enemies_at_pos); _i++) {
				if (is_existing_instance(_enemies_at_pos[_i]) && _enemies_at_pos[_i].corporeal) {
					_obj_is_here = true;
					break;
				}
			}
		}
		// Check for blocks to break illusion
		if (!_obj_is_here) {
			var _blocks_at_pos = instance_place_all(_x_pos, _y_pos, obj_block);
			for (var _i = 0; _i < array_length(_blocks_at_pos); _i++) {
				if (is_existing_instance(_blocks_at_pos[_i])) {
					_obj_is_here = true;
					break;
				}
			}
		}
		// Check for fireballs to break illusion
		if (!_obj_is_here) {
			var _fireball_at_pos = instance_place_all(_x_pos, _y_pos, obj_fireball);
			for (var _i = 0; _i < array_length(_fireball_at_pos); _i++) {
				if (is_existing_instance(_fireball_at_pos[_i])) {
					_obj_is_here = true;
					break;
				}
			}
		}
		
		// Draw the quarter only when nothing is in it
		if (!_obj_is_here) {
			var _draw_left_pos = (_quadrant % 2 == 0) ? 0 : 8, _draw_top_pos = (_quadrant < 2) ? 0 : 8;
			draw_sprite_part_ext(sprite_index, image_index, _draw_left_pos, _draw_top_pos, sprite_width/2, sprite_height/2, _x_pos-4, _y_pos-4, 1, 1, image_blend, image_alpha);
		}
		
		// Put the full mask back
		mask_index = sprite_index;
	}
}
else { event_inherited(); }
