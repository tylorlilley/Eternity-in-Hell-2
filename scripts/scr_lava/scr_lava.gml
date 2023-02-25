/// @function								initialize_lava();
function initialize_lava() { 
	// Set up the death box for each quadrant of this lava
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
		var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);

		death_boxes[quadrant] = instance_create(x_pos, y_pos, obj_lava_part);
		with (death_boxes[quadrant]) { creator = other.id; }
	}
	
	// Update the room's grid
	//global.controller.grid_update_timer = 1;
	
	// Create light_source
	/*
	if (array_length(instance_place_all(x-16, y, obj_lava)) > 0 &&
		array_length(instance_place_all(x+16, y, obj_lava)) > 0 &&
		array_length(instance_place_all(x, y-16, obj_lava)) > 0 &&
		array_length(instance_place_all(x, y+16, obj_lava)) > 0) {
			light = instance_create(x, y, obj_light_source);
			light.lighting_range = LAVA_LIGHT_RANGE;
			light.intensity = 0.45;
			light.creator = id;
		}
	*/
}

/// @function								destroy_lava_at_position(x_pos, y_pos);
/// @param		{real} x_pos				The x position of the quadrant to destroy
/// @param		{real} y_pos				The y position of the quadrant to destroy
function destroy_lava_at_position(x_pos, y_pos) {
	var lava_grid = global.controller.current_room.lava_grid;
	
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
	    if (is_instance_at_coordinates(x_pos, y_pos, death_boxes[quadrant])) {
	        with death_boxes[quadrant] {
				mp_grid_remove(lava_grid);
				instance_destroy(); 
			}
			death_boxes[quadrant] = noone;
			return true;
	    }
	}
	return false;
}

/// @function								get_lava_at_each_quadrant();
/*
function get_lava_at_each_quadrant() {
	// Get the actual lava objects at each lava quadrant
	var lava_at_quadrant = [noone, noone, noone, noone], player = global.player;
	
	// mark the lava as missing a death box if a player or hands is holding a staff at the quadrant position
	if (instance_place(x, y, player)) {
		with (player) { if (is_carrying_item(obj_staff)) { return lava_at_quadrant; } }
	}
	var hands = instance_place_all(x, y, obj_hands);
	while (array_length(hands) > 0) { 
		var hand = array_pop(hands);
		if (instance_place(x, y, hand)) {
			with (hand) { if (is_carrying_item(obj_staff)) { return lava_at_quadrant; } }
		}
	}
	
	// Get the lava object at each quadrant
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
        var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		lava_at_quadrant[quadrant] = instance_position(x_pos, y_pos, obj_lava);
    }
	
	// Check each quadrant for death boxes
	for (var quadrant = 0; quadrant < 4; quadrant++;) {
		var lava = lava_at_quadrant[quadrant], missing_death_box = true, x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
		if (is_existing_instance(lava) && !is_existing_instance(lava.death_box)) {
			// mark the lava as not missing a death box if a death box is at the right quadrant position
			for (var other_quadrant = 0; other_quadrant < 4; other_quadrant++) {
				var death_box = lava.death_boxes[other_quadrant]
				if (is_existing_instance(death_box) && death_box.x == x_pos && death_box.y == y_pos) { missing_death_box = false; break; }
			}
		
			// Override lava at this quadrant with noone if death box is missing
			if (missing_death_box) { lava_at_quadrant[quadrant] = noone; }
		}
	}
		
	return lava_at_quadrant;
}
*/

/// @ function								consume_lava(require_all);
/// @param		{bool} require_all			Only consume whole chunks of lava at once
function consume_lava(require_all) {
	var lava_at_quadrant = get_instance_at_each_quadrant(obj_lava_part);
	if (!require_all || is_covered_at_each_quadrant_by(obj_lava)) {
		var consumed = false;
		for (var quadrant = 0; quadrant < 4; quadrant++) {
			var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
			
			with lava_at_quadrant[quadrant].creator { 
				consumed = destroy_lava_at_position(x_pos, y_pos) || consumed;
			}
		}
		
		if (consumed) {
			play_sound(snd_splash, false);
			with (obj_lava) {
				if (get_distance_to_instance(other) <= 32) {
					set_up_lava_edge_visibility(false);
				}
			}
			return true;
		}
	}
	return false;
}

/// @ function								destroy_self_if_all_death_boxes_are_destroyed();
/*
function destroy_self_if_all_death_boxes_are_destroyed() {
	if (!is_existing_instance(death_box) &&
		!is_existing_instance(death_boxes[0]) &&
		!is_existing_instance(death_boxes[1]) &&
		!is_existing_instance(death_boxes[2]) &&
		!is_existing_instance(death_boxes[3])) { 
			mp_grid_remove(global.controller.current_room.lava_grid);
			instance_destroy(); 
	}
}
*/

/// @ function								set_up_lava_edge_visibility(require_all);
/// @param		{bool} visibility_only		Only change the visibility status
function set_up_lava_edge_visibility(first_time_setup) {
	var edge_type = global.lava_edge_type, is_wavy_edge_type = (edge_type == lava_edge_types.wavy_still || edge_type == lava_edge_types.wavy_animated)
	if (edge_type == lava_edge_types.none) { lava_edge_visible = [[false, false, false, false], [false, false, false, false], [false, false, false, false], [false, false, false, false]]; return; }
	else if (first_time_setup) { lava_edge_sprite_index = (is_wavy_edge_type) ? spr_lava_edge3 : spr_lava_edge; }
	
	sprite_index = spr_collectable;
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		for (var dir = directions.up; dir < directions.stairs; dir++) {
			if (first_time_setup) { 
				var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
				
				if (!is_wavy_edge_type) {
					lava_edge_image_indexes[quadrant][dir] = irandom(7);
					lava_edge_image_xscales[quadrant][dir] = (get_coin_flip()) ? 1 : -1;
				}
				else {
					lava_edge_image_indexes[quadrant][dir] = (((x_pos-4)/8) % 4) + (((y_pos-4)/8) % 4) % 7;
					lava_edge_image_xscales[quadrant][dir] = 1;
				}
			
				// Skip edges within the lava object on first time setup
				if ((quadrant == 0 && (dir == directions.right || dir == directions.down)) ||
					(quadrant == 1 && (dir == directions.left || dir == directions.down)) ||
					(quadrant == 2 && (dir == directions.right || dir == directions.up)) ||
					(quadrant == 3 && (dir == directions.left || dir == directions.up))) {
					continue; 
				}
			}
			
			var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
			switch (dir) {
				case directions.up: { y_pos -= 8; break; }
				case directions.right: { x_pos += 8; break; }
				case directions.down: { y_pos += 8; break; }
				case directions.left: { x_pos -= 8; break; }
			}
			
			lava_edge_visible[quadrant][dir] = !is_lava_at_position(x_pos, y_pos);
			if (!is_existing_instance(death_box) && !is_existing_instance(death_boxes[quadrant])) { lava_edge_visible[quadrant][dir] = false; }
		}
	}
	sprite_index = spr_lava;
}
