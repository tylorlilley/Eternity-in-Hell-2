if (process_this_frame()) {
	event_inherited();

	obj_game_object_calculate_lighting(0.5);

	// Randomize visual
	image_angle = irandom(3)*90;
	if (irandom(0) == 0) image_xscale *= -1;
	if (irandom(0) == 0) image_yscale *= -1;

	/*
	if (irandom(8)) {
	    lighting_range += -1 + irandom(2);
	    if lighting_range > 4 lighting_range = 4;
	    else if lighting_range < 1 lighting_range = 1;
	}
	*/

	/* */
	/*  */
}