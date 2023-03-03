draw_self();

// Draw Quadrant lava edges
if (global.lava_edge_type != lava_edge_types.none) {
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		for (var dir = directions.up; dir < directions.stairs; dir++) {
			var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
			switch (dir) {
				case directions.up: { y_pos -= 8; break; }
				case directions.right: { x_pos += 8; break; }
				case directions.down: { y_pos += 8; break; }
				case directions.left: { x_pos -= 8; break; }
			}
		
			if (!lava_edge_visible[quadrant][dir]) { continue; }
			if (!parts[quadrant].part_visible) { continue; }
			
			draw_sprite_ext(lava_edge_sprite_index, lava_edge_image_indexes[quadrant][dir], x_pos, y_pos, lava_edge_image_xscales[quadrant][dir], 1, dir*-90, image_blend, 1);
		}
	}
}