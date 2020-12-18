/// @function								convert_to_multiple_death_boxes();
function convert_to_multiple_death_boxes() {
	// Delete the existing death box
	with death_box { instance_destroy(); }
	death_box = noone;
	
	// Set up the death box for each quadrant of this lava
	death_boxes = array(noone, noone, noone, noone);
	for (var i = 0; i <= 3; i+= 1;) {
		var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);

		death_boxes[i] = instance_create_depth(x_pos, y_pos, 5, obj_death);
		death_boxes[i].death_sound = snd_torchlight;
		death_boxes[i].image_xscale = 0.5;
		death_boxes[i].image_yscale = 0.5;
		death_boxes[i].stopped_by_special_rosary = true;
	}
}

/// @function								destroy_lava_at_position(x_pos, y_pos);
/// @param		{real} x_pos				The x position of the quadrant to destroy
/// @param		{real} y_pos				The y position of the quadrant to destroy
function destroy_lava_at_position(x_pos, y_pos) {
	if death_box { convert_to_multiple_death_boxes(); }
	
	for (var i = 0; i <= 3; i+=1;) {
	    if (instance_at_coordinates(x_pos, y_pos, death_boxes[i])) {
	        with death_boxes[i] { instance_destroy(); }
			death_boxes[i] = noone;
	    }
	}
}