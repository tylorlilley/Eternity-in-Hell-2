var player = global.player;


if (is_blink_frame()) {
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
		var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		mask_index = spr_quadrant;
		
		var obj_is_here = place_meeting(x_pos, y_pos, player);
		// Check for enemies to break illusion
		if (!obj_is_here) {
			var enemies_at_pos = instance_place_all(x_pos, y_pos, obj_enemy);
			for (var i = 0; i < array_length(enemies_at_pos); i++) {
				if (is_existing_instance(enemies_at_pos[i]) && enemies_at_pos[i].corporeal) {
					obj_is_here = true;
					break;
				}
			}
		}
		// Check for blocks to break illusion
		if (!obj_is_here) {
			var blocks_at_pos = instance_place_all(x_pos, y_pos, obj_block);
			for (var i = 0; i < array_length(blocks_at_pos); i++) {
				if (is_existing_instance(blocks_at_pos[i])) {
					obj_is_here = true;
					break;
				}
			}
		}
		// Check for fireballs to break illusion
		if (!obj_is_here) {
			var fireball_at_pos = instance_place_all(x_pos, y_pos, obj_fireball);
			for (var i = 0; i < array_length(fireball_at_pos); i++) {
				if (is_existing_instance(fireball_at_pos[i])) {
					obj_is_here = true;
					break;
				}
			}
		}
		
		if (!obj_is_here) {
			var draw_left_pos = (quadrant % 2 == 0) ? 0 : 8, draw_top_pos = (quadrant < 2) ? 0 : 8;
			draw_sprite_part_ext(sprite_index, image_index, draw_left_pos, draw_top_pos, sprite_width/2, sprite_height/2, x_pos-4, y_pos-4, 1, 1, image_blend, image_alpha);
		}
		
		mask_index = sprite_index;
	}
}
else { event_inherited(); }
