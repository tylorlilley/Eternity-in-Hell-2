if (sprite_index) {

	var is_solid = (object_index == obj_solid || object_is_ancestor(object_index, obj_solid));
	var solid_at_quadrant = get_instance_at_each_quadrant(obj_solid);
	var covered_by_solid = ((solid_at_quadrant[0] != noone && solid_at_quadrant[0].visible) &&
							(solid_at_quadrant[1] != noone && solid_at_quadrant[1].visible) &&
							(solid_at_quadrant[2] != noone && solid_at_quadrant[2].visible) &&
							(solid_at_quadrant[3] != noone && solid_at_quadrant[3].visible))
							
	var is_bush = (object_index == obj_bush);
	var covered_by_bush = is_covered_at_each_quadrant_by(obj_bush);

	// Skip drawing sprite completely if covered by a bush or solid
    var covered = false;
	if ((!is_solid && !is_bush && covered_by_bush) || (!is_solid && covered_by_solid)) { covered = true; }
	
	// Draw box underneath solids to partially cover things under them
	if (is_solid) { draw_sprite_ext(spr_box, 0, x, y, 1, 1, 0, global.controller.bg_color, 1); }
	
	if (!covered) { 
		// Draw main sprite
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
		
		// Check each quadrant for solid coverage
		/*
		var solid_at_quadrant = get_instance_at_each_quadrant(obj_solid);
		for (var i = 0; i <= 3; i += 1;) {
			// Draw box over quadrant to hide sprite
		    if (!is_solid && solid_at_quadrant[i] != noone && solid_at_quadrant[i].visible) {
				var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
				draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.5, 0.5, 0, global.controller.bg_color, 1);
			}
		}
		*/
	}
}