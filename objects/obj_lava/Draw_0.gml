event_inherited();

// Consider each quadrant of the sprite and draw a blank square over it its corresponding death box has been destroyed
if !death_box {
	draw_set_color(global.controller.bg_color);
	
	for (var i = 0; i <= 3; i +=1;) {
	    var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i), top_pos = get_quadrant_top_pos(i), left_pos = get_quadrant_left_pos(i);

	    if (!death_boxes[i]) {
	        draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
			//draw_sprite_part_ext(sprite_index, image_index, left_pos, top_pos, 8, 8, x_pos-4, y_pos-4, image_xscale, image_yscale, image_blend, image_alpha);
	    }
	}
}