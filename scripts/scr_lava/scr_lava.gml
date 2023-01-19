/// @function								convert_to_multiple_death_boxes();
function convert_to_multiple_death_boxes() {
	// Delete the existing death box
	with death_box { instance_destroy(); }
	death_box = noone;
	
	// Set up the death box for each quadrant of this lava
	death_boxes = [noone, noone, noone, noone];
	for (var i = 0; i <= 3; i+= 1;) {
		var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

		death_boxes[i] = instance_create_depth(x_pos, y_pos, 5, obj_death);
		death_boxes[i].image_xscale = 0.5;
		death_boxes[i].image_yscale = 0.5;
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
	var lava_at_quadrant = [noone, noone, noone, noone];
	
	// mark the lava as missing a death box if a player or hands is holding a staff at the quadrant position
	if (instance_place(x, y, global.player)) {
		with (global.player) { if (is_carrying_item(obj_staff)) { return lava_at_quadrant; } }
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
		if (lava != noone && lava.death_box == noone) {
			// mark the lava as not missing a death box if a death box is at the right quadrant position
			for (var j = 0; j <= 3; j++) {
				var death_box = lava.death_boxes[j]
				if (death_box != noone && death_box.x == x_pos && death_box.y == y_pos) { missing_death_box = false; break; }
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
			
			with lava_at_quadrant[i] { consumed = destroy_lava_at_position(x_pos, y_pos) || consumed; }
		}
		if (consumed) {
			play_sound(snd_splash, false);
			return true;
		}
	}
	return false;
}
