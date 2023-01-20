if (sprite_index) {
    draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
    
    // Consider each quadrant of the sprite and draw a blank square over it if it is behind another object that should cover it
    draw_set_color(global.controller.bg_color);
	var bush_at_quadrant = get_instance_at_each_quadrant(obj_bush);
	var solid_at_quadrant = get_instance_at_each_quadrant(obj_solid);
	var covered_by_bush = is_covered_at_each_quadrant_by(obj_bush);
	
    for (var i = 0; i <= 3; i += 1;) {
        var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

        var bush = bush_at_quadrant[i];
        var solid_obj = solid_at_quadrant[i];
		if (solid_obj && (solid_obj.object_index == obj_giant_worm_head || solid_obj.object_index == obj_giant_worm_body)) { solid_obj = noone; }
        if (covered_by_bush && bush != noone && bush != id) {
			if (bush.depth <= depth) { draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1); }
			// TODO: Draw box over bush else { draw_sprite_ext(spr_box, 0, x+x_pos, y+y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);}
		}
        if (solid_obj && solid_obj.visible && solid_obj != id && depth > -100) {
            if (!bush || bush != id) { draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1); }
        }
    }
	
	
    if (object_index == obj_player) { draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha); }
}