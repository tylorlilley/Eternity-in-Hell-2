/// @description End Step
event_inherited();

// Determine Closest Objects
if (can_process_this_frame()) {
	var closest_objects = array_create(0);
	for (var i = directions.up; i < directions.none; i++) {
		var x_pos = x, y_pos = y;
		switch (i) {
			case 0: { x_pos = 0; break; }
			case 1: { y_pos = 0; break; }
			case 2: { x_pos = room_width; break; }
			case 3: { y_pos = room_height; break; }
		}
		var reflected_objects = ds_list_create(), num_of_objects = collision_rectangle_list(x-1, y-1, x_pos, y_pos, obj_game_object, false, true, reflected_objects, true);
		for (var j = 0; j < num_of_objects; j++) { 
			var obj = ds_list_find_value(reflected_objects, j);
			if (!object_is_ancestor(obj.object_index, obj_solid)) { array_push(closest_objects, obj); }
		}
		ds_list_destroy(reflected_objects);
	}
	var minimum_distance_to_obj = 999, var closest_object = noone;
	for (var i = 0; i < array_length(closest_objects); i++) {
		var current_object = closest_objects[i], distance_to_obj = get_distance_to_instance(current_object)
		if (distance_to_obj < minimum_distance_to_obj) { 
			minimum_distance_to_obj = distance_to_obj;
			closest_object = current_object;
		}
		else if (distance_to_obj == minimum_distance_to_obj) {
			if (current_object.depth < closest_object.depth) { closest_object = current_object; }
			else if (current_object.depth == closest_object.depth) {
				if (current_object.id < closest_object.id) { closest_object = current_object; }
			}
		}
	}
	
	// Create Sprite for Reflection
	if (instance_exists(closest_object)) {
		var seen_objects = ds_list_create(), num_of_objects = collision_line_list(x, y, closest_object.x, closest_object.y, obj_solid, false, true, seen_objects, true);
		if (num_of_objects == 0 || seen_objects[| 0] == closest_object) {

			// Draw Holder and not held Item
			if (object_is_ancestor(closest_object.object_index, obj_item) && is_existing_instance(closest_object.holder)) { closest_object = closest_object.holder; }

			var x_pos = closest_object.x-8, y_pos = closest_object.y-8;
			refl_blend = (colour_get_value(closest_object.image_blend) > colour_get_value(image_blend)) ? image_blend : closest_object.image_blend;
			if (closest_object.x < x) { x_pos += 8; }
			if (closest_object.x > x) { x_pos -= 8; }
			if (closest_object.y < y) { y_pos += 8; }
			if (closest_object.y > y) { y_pos -= 8; }
			if (spr != noone) { sprite_delete(spr); }
			spr = sprite_create_from_surface(application_surface, x_pos, y_pos, 16, 16, false, false, 8, 8);
		}
		ds_list_destroy(seen_objects);
	}
}

