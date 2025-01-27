if (sprite_index != -1) {
	var is_solid = (object_index == obj_solid || object_is_ancestor(object_index, obj_solid));
	var solid_at_quadrant = get_instance_at_each_quadrant(obj_solid);
	var covered_by_solid = ((is_existing_instance(solid_at_quadrant[0]) && solid_at_quadrant[0].visible) &&
							(is_existing_instance(solid_at_quadrant[1]) && solid_at_quadrant[1].visible) &&
							(is_existing_instance(solid_at_quadrant[2]) && solid_at_quadrant[2].visible) &&
							(is_existing_instance(solid_at_quadrant[3]) && solid_at_quadrant[3].visible) &&
							depth > GIANT_WORM_DEPTH)
	
	var is_bush = (object_index == obj_bush);
	var covered_by_bush = (depth > BUSH_DEPTH && is_covered_at_each_quadrant_by(obj_bush));

	// Skip drawing sprite completely if covered by a bush or solid
    var covered = false;
	if ((!is_solid && !is_bush && covered_by_bush) || (!is_solid && covered_by_solid)) { covered = true; }

	// Draw main sprite
	if (!covered) { draw_self(); }
	
	// Draw Relfection in Mirrors
	if (!object_is_ancestor(object_index, obj_solid)) {
		for (var i = directions.up; i < directions.none; i++) {
			var x_pos = x, y_pos = y;
			switch (i) {
				case 0: { x_pos = 0; break; }
				case 1: { y_pos = 0; break; }
				case 2: { x_pos = room_width; break; }
				case 3: { y_pos = room_height; break; }
			}
			var potential_mirrors = ds_list_create();
			var num_of_objects = collision_rectangle_list(x-1, y-1, x_pos, y_pos, obj_solid, false, true, potential_mirrors, true);
			if (num_of_objects == 0) { ds_list_destroy(potential_mirrors); continue; }
			
			var minimum_distance_to_obj = 999, var closest_solids = array_create(0);
			for (var j = 0; j < num_of_objects; j++) {
				var current_object = ds_list_find_value(potential_mirrors, j), distance_to_obj = get_distance_to_instance(current_object)
				if (distance_to_obj < minimum_distance_to_obj) { closest_solids = array_create(0); }
				if (distance_to_obj <= minimum_distance_to_obj) { 
					minimum_distance_to_obj = distance_to_obj;
					array_push(closest_solids, current_object);
				}
			}
			for (var j = 0; j < array_length(closest_solids); j++) {
				var closest_solid = closest_solids[j];
				if (!is_existing_instance(closest_solid) || closest_solid.object_index != obj_mirror) { break; }

				var x_offset = 0, y_offset = 0, refl_width = abs(sprite_width), refl_height = abs(sprite_height);
				var x_pos = closest_solid.x-(image_xscale*abs(sprite_width))/2, y_pos = closest_solid.y-(image_yscale*abs(sprite_height))/2, x_dif = closest_solid.x-x, y_dif = closest_solid.y-y;
				var refl_blend = (colour_get_value(closest_solid.image_blend) < colour_get_value(image_blend)) ? closest_solid.image_blend : image_blend;

				if (abs(y_dif) < abs(closest_solid.sprite_height) && y < closest_solid.y) { refl_height /= 2; y_offset += refl_height; y_pos += (abs(sprite_width)-abs(closest_solid.sprite_width))/2; }
				else if (abs(y_dif) < abs(closest_solid.sprite_height) && y > closest_solid.y) { refl_height /= 2; y_pos += abs(closest_solid.sprite_height/2); }
				else if (abs(x_dif) < abs(closest_solid.sprite_width) && x < closest_solid.x) { 
					if (image_xscale == 1) { refl_width /= 2; x_offset += refl_width; x_pos += (abs(sprite_width)-abs(closest_solid.sprite_width))/2; }
					else { refl_width /= 2; x_pos -= abs(closest_solid.sprite_width/2); }
				}
				else if (abs(x_dif) < abs(closest_solid.sprite_width) && x > closest_solid.x) {
					if (image_xscale == -1) { refl_width /= 2; x_offset += refl_width; x_pos += (abs(sprite_width)-abs(closest_solid.sprite_width))/2; }
					else { refl_width /= 2; x_pos += abs(closest_solid.sprite_width/2); }
				}
				
				
				draw_sprite_part_ext(sprite_index, image_index, x_offset, y_offset, refl_width, refl_height, x_pos, y_pos, image_xscale, image_yscale, refl_blend, 1);
			}
			ds_list_destroy(potential_mirrors);
		}
	}
}