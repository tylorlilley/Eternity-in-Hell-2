event_inherited();

// Consider each quadrant of the sprite and draw a blank square over it its corresponding death box has been destroyed
if (!is_existing_instance(death_box)) {
	var bg_color = global.bg_color;
	draw_set_color(bg_color);
	
	for (var i = 0; i <= 3; i +=1;) {
	    var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

	    if (!is_existing_instance(death_boxes[i])) {
	        draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, bg_color, 1);
	    }
	}
}

// Draw Quadrant lava edges
sprite_index = spr_collectable;
for (var quadrant = 0; quadrant < 4; quadrant++) {
	for (var dir = 0; dir < 4; dir++) {
		var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		switch (dir) {
			case directions.up: { y_pos -= 8; break; }
			case directions.right: { x_pos += 8; break; }
			case directions.down: { y_pos += 8; break; }
			case directions.left: { x_pos -= 8; break; }
		}
		
		if (!lava_edge_visible[quadrant][dir]) { continue; }
		
		draw_sprite_ext(spr_lava_edge, lava_edge_image_indexes[quadrant][dir], x_pos, y_pos, lava_edge_image_xscales[quadrant][dir], 1, dir*-90, image_blend, 1);
	}
}
sprite_index = spr_lava;