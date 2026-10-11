draw_self();

// Consider each quadrant of the sprite and draw a blank square over it its corresponding death box has been destroyed
var _bg_color = global.bg_color;
draw_set_color(_bg_color);

for (var _quadrant = 0; _quadrant < 4; _quadrant++;) {
	var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);

	if (is_existing_instance(parts[_quadrant]) && !parts[_quadrant].part_visible) {
	    draw_sprite_ext(spr_box, 0, _x_pos, _y_pos, 0.5, 0.5, 0, _bg_color, 1);
	}
}

// Draw Quadrant lava edges
for (var _quadrant = 0; _quadrant < 4; _quadrant++) {
			
	for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
		var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
		switch (_dir) {
			case directions.up: { _y_pos -= 6; break; }
			case directions.right: { _x_pos += 6; break; }
			case directions.down: { _y_pos += 6; break; }
			case directions.left: { _x_pos -= 6; break; }
		}
		
		if (!lava_edge_visible[_quadrant][_dir]) { continue; }
		
		draw_set_color(_bg_color);
		switch (_dir) {
			case directions.up: { draw_rectangle(_x_pos-4, _y_pos+2, _x_pos+3, _y_pos+3, false); break; }
			case directions.right: { draw_rectangle(_x_pos-4, _y_pos-4, _x_pos-3, _y_pos+3, false); break; }
			case directions.down: { draw_rectangle(_x_pos-4, _y_pos-4, _x_pos+3, _y_pos-3, false); break; }
			case directions.left: { draw_rectangle(_x_pos+2, _y_pos-4, _x_pos+3, _y_pos+3, false); break; }
		}
		
		if (!is_existing_instance(parts[_quadrant]) || !parts[_quadrant].part_visible) { continue; }
		if (global.lava_edge_type != lava_edge_types.none) { draw_sprite_ext(lava_edge_sprite_index, lava_edge_image_indexes[_quadrant][_dir], _x_pos, _y_pos, lava_edge_image_xscales[_quadrant][_dir], 1, _dir*-90, image_blend, 1); }
	}
		
	if (global.lava_edge_type != lava_edge_types.none) {
		var _x_pos = get_quadrant_x_pos(_quadrant), _y_pos = get_quadrant_y_pos(_quadrant);
		if (_quadrant == 0 && lava_edge_visible[_quadrant][directions.up] && lava_edge_visible[_quadrant][directions.left]) { draw_sprite_ext(spr_lava_corners,  lava_edge_image_indexes[_quadrant][directions.up], _x_pos-4, _y_pos-4, 1, 1, 0, _bg_color, 1); }
		if (_quadrant == 1 && lava_edge_visible[_quadrant][directions.up] && lava_edge_visible[_quadrant][directions.right]) { draw_sprite_ext(spr_lava_corners, lava_edge_image_indexes[_quadrant][directions.right], _x_pos+4, _y_pos-4, 1, 1, 270, _bg_color, 1); }
		if (_quadrant == 2 && lava_edge_visible[_quadrant][directions.down] && lava_edge_visible[_quadrant][directions.left]) { draw_sprite_ext(spr_lava_corners, lava_edge_image_indexes[_quadrant][directions.down], _x_pos-4, _y_pos+4, 1, 1, 90, _bg_color, 1); }
		if (_quadrant == 3 && lava_edge_visible[_quadrant][directions.down] && lava_edge_visible[_quadrant][directions.right]) { draw_sprite_ext(spr_lava_corners, lava_edge_image_indexes[_quadrant][directions.left], _x_pos+4, _y_pos+4, 1, 1, 180, _bg_color, 1); }
		/*
		if (quadrant == 0 && lava_edge_visible[quadrant][directions.up] && lava_edge_visible[quadrant][directions.left]) { draw_rectangle(x_pos-4, y_pos-2, x_pos-3, y_pos-5, false); }
		if (quadrant == 1 && lava_edge_visible[quadrant][directions.up] && lava_edge_visible[quadrant][directions.right]) { draw_rectangle(x_pos+2, y_pos-2, x_pos+3, y_pos-5, false); }
		if (quadrant == 2 && lava_edge_visible[quadrant][directions.down] && lava_edge_visible[quadrant][directions.left]) { draw_rectangle(x_pos-4, y_pos+2, x_pos-3, y_pos+3, false); }
		if (quadrant == 3 && lava_edge_visible[quadrant][directions.down] && lava_edge_visible[quadrant][directions.right]) { draw_rectangle(x_pos+2, y_pos+2, x_pos+3, y_pos+3, false); }
		*/
	}
}