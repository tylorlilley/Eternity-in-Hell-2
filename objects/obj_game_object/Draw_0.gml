if (sprite_index != -1) {
	var is_solid = (object_index == obj_solid || object_is_ancestor(object_index, obj_solid));
	var solid_at_quadrant = get_instance_at_each_quadrant(obj_solid);
	var covered_by_solid = ((is_existing_instance(solid_at_quadrant[0]) && solid_at_quadrant[0].visible) &&
							(is_existing_instance(solid_at_quadrant[1]) && solid_at_quadrant[1].visible) &&
							(is_existing_instance(solid_at_quadrant[2]) && solid_at_quadrant[2].visible) &&
							(is_existing_instance(solid_at_quadrant[3]) && solid_at_quadrant[3].visible))
							
	var is_bush = (object_index == obj_bush);
	var covered_by_bush = is_covered_at_each_quadrant_by(obj_bush);

	// Skip drawing sprite completely if covered by a bush or solid
    var covered = false;
	if ((!is_solid && !is_bush && covered_by_bush) || (!is_solid && covered_by_solid)) { covered = true; }
	
	// Draw box underneath solids to partially cover things under them
	// if (is_solid) { draw_sprite_ext(spr_box, 0, x, y, 1, 1, 0, global.bg_color, 1); }
	
	// Draw main sprite
	if (!covered) { 
		draw_self();
	}
}