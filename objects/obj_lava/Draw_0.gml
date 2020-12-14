event_inherited();

// Consider each quadrant of the sprite and draw a blank square over it its corresponding death box has been destroyed
if !death_box {
	draw_set_color(global.controller.bg_color);
	
	for (var i = 0; i <= 3; i +=1;) {
	    var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

	    if (!death_boxes[i]) {
	        draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
	    }
	}
}