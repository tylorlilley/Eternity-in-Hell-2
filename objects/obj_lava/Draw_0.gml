draw_self();

// Consider each quadrant of the sprite and draw a blank square over it its corresponding death box has been destroyed
var bg_color = global.bg_color;
draw_set_color(bg_color);

for (var quadrant = 0; quadrant < 4; quadrant++;) {
	var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);

	if (is_existing_instance(parts[quadrant]) && !parts[quadrant].part_visible) {
	    draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, bg_color, 1);
	}
}

// Draw Quadrant lava edges
if (global.lava_edge_type != lava_edge_types.none) {
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		if (!parts[quadrant].part_visible) { continue; }
			
		for (var dir = directions.up; dir < directions.stairs; dir++) {
			var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
			switch (dir) {
				case directions.up: { y_pos -= 6; break; }
				case directions.right: { x_pos += 6; break; }
				case directions.down: { y_pos += 6; break; }
				case directions.left: { x_pos -= 6; break; }
			}
		
			if (!lava_edge_visible[quadrant][dir]) { continue; }
			
			draw_set_color(bg_color);
			switch (dir) {
				case directions.up: { draw_rectangle(x_pos-4, y_pos+2, x_pos+3, y_pos+3, false); break; }
				case directions.right: { draw_rectangle(x_pos-4, y_pos-4, x_pos-3, y_pos+3, false); break; }
				case directions.down: { draw_rectangle(x_pos-4, y_pos-4, x_pos+3, y_pos-3, false); break; }
				case directions.left: { draw_rectangle(x_pos+2, y_pos-4, x_pos+3, y_pos+3, false); break; }
			}
			
			draw_sprite_ext(lava_edge_sprite_index, lava_edge_image_indexes[quadrant][dir], x_pos, y_pos, lava_edge_image_xscales[quadrant][dir], 1, dir*-90, image_blend, 1);
		}
		
		var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		if (quadrant == 0 && lava_edge_visible[quadrant][directions.up] && lava_edge_visible[quadrant][directions.left]) { draw_sprite_ext(spr_lava_corners,  lava_edge_image_indexes[quadrant][0], x_pos-4, y_pos-4, 1, 1, 0, bg_color, 1); }
		if (quadrant == 1 && lava_edge_visible[quadrant][directions.up] && lava_edge_visible[quadrant][directions.right]) { draw_sprite_ext(spr_lava_corners, lava_edge_image_indexes[quadrant][1], x_pos+4, y_pos-4, 1, 1, 270, bg_color, 1); }
		if (quadrant == 2 && lava_edge_visible[quadrant][directions.down] && lava_edge_visible[quadrant][directions.left]) { draw_sprite_ext(spr_lava_corners, lava_edge_image_indexes[quadrant][2], x_pos-4, y_pos+4, 1, 1, 90, bg_color, 1); }
		if (quadrant == 3 && lava_edge_visible[quadrant][directions.down] && lava_edge_visible[quadrant][directions.right]) { draw_sprite_ext(spr_lava_corners, lava_edge_image_indexes[quadrant][3], x_pos+4, y_pos+4, 1, 1, 180, bg_color, 1); }
		/*
		if (quadrant == 0 && lava_edge_visible[quadrant][directions.up] && lava_edge_visible[quadrant][directions.left]) { draw_rectangle(x_pos-4, y_pos-2, x_pos-3, y_pos-5, false); }
		if (quadrant == 1 && lava_edge_visible[quadrant][directions.up] && lava_edge_visible[quadrant][directions.right]) { draw_rectangle(x_pos+2, y_pos-2, x_pos+3, y_pos-5, false); }
		if (quadrant == 2 && lava_edge_visible[quadrant][directions.down] && lava_edge_visible[quadrant][directions.left]) { draw_rectangle(x_pos-4, y_pos+2, x_pos-3, y_pos+3, false); }
		if (quadrant == 3 && lava_edge_visible[quadrant][directions.down] && lava_edge_visible[quadrant][directions.right]) { draw_rectangle(x_pos+2, y_pos+2, x_pos+3, y_pos+3, false); }
		*/
	}
}