/// @function								convert_to_multiple_death_boxes();
function convert_to_multiple_death_boxes() {
	// Delete the existing death box
	with death_box { instance_destroy(); }
	death_box = noone;
	
	// Set up the death box for each quadrant of this lava
	death_boxes = [noone, noone, noone, noone];
	for (var i = 0; i <= 3; i+= 1;) {
		var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

		death_boxes[i] = instance_create(x_pos, y_pos, obj_death);
		death_boxes[i].image_xscale = 0.5;
		death_boxes[i].image_yscale = 0.5;
		death_boxes[i].creator = id;
	}
}

/// @function								destroy_lava_at_position(x_pos, y_pos);
/// @param		{real} x_pos				The x position of the quadrant to destroy
/// @param		{real} y_pos				The y position of the quadrant to destroy
function destroy_lava_at_position(x_pos, y_pos) {
	if death_box { convert_to_multiple_death_boxes(); }
	
	for (var i = 0; i <= 3; i+=1;) {
	    if (is_instance_at_coordinates(x_pos, y_pos, death_boxes[i])) {
	        with death_boxes[i] { instance_destroy(); }
			death_boxes[i] = noone;
			return true;
	    }
	}
	return false;
}

/// @function								get_lava_at_each_quadrant();
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
	for (var i = 0; i <= 3; i+= 1;) {
        var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
		lava_at_quadrant[i] = instance_position(x_pos, y_pos, obj_lava);
    }
	
	// Check each quadrant for death boxes
	for (var i = 0; i <= 3; i++) {
		var lava = lava_at_quadrant[i], missing_death_box = true, x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
		if (is_existing_instance(lava) && !is_existing_instance(lava.death_box)) {
			// mark the lava as not missing a death box if a death box is at the right quadrant position
			for (var j = 0; j <= 3; j++) {
				var death_box = lava.death_boxes[j]
				if (is_existing_instance(death_box) && death_box.x == x_pos && death_box.y == y_pos) { missing_death_box = false; break; }
			}
		
			// Override lava at this quadrant with noone if death box is missing
			if (missing_death_box) { lava_at_quadrant[i] = noone; }
		}
	}
		
	return lava_at_quadrant;
}

/// @ function								consume_lava(require_all);
/// @param		{bool} require_all			Only consume whole chunks of lava at once
function consume_lava(require_all) {
	var lava_at_quadrant = get_lava_at_each_quadrant();
	if (!require_all || is_covered_at_each_quadrant_by(obj_lava)) {
		var consumed = false;
		for (var i = 0; i <= 3; i++) {
			var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
			
			with lava_at_quadrant[i] { 
				consumed = destroy_lava_at_position(x_pos, y_pos) || consumed; 
				destroy_self_if_all_death_boxes_are_destroyed();
			}
		}
		
		if (consumed) {
			play_sound(snd_splash, false);
			with (obj_lava) {
				if (point_distance(x, y, other.x, other.y) <= 32) {
					set_up_lava_edge_visibility(false);
				}
			}
			return true;
		}
	}
	return false;
}

/// @ function								destroy_self_if_all_death_boxes_are_destroyed();
function destroy_self_if_all_death_boxes_are_destroyed() {
	if (!is_existing_instance(death_box) &&
		!is_existing_instance(death_boxes[0]) &&
		!is_existing_instance(death_boxes[1]) &&
		!is_existing_instance(death_boxes[2]) &&
		!is_existing_instance(death_boxes[3])) { 
			instance_destroy(); 
	}
}

/// @ function								set_up_lava_edge_visibility(require_all);
/// @param		{bool} visibility_only		Only change the visibility status
function set_up_lava_edge_visibility(first_time_setup) {
	sprite_index = spr_collectable;
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		for (var dir = 0; dir < 4; dir++) {
			if (first_time_setup) { 
				lava_edge_image_indexes[quadrant][dir] = irandom(7);
				lava_edge_image_xscales[quadrant][dir] = (get_coin_flip()) ? 1 : -1;
			
				// Skip edges within the lava object on first time setup
				var x_pos = get_quadrant_x_pos(quadrant), y_pos = get_quadrant_y_pos(quadrant);
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
