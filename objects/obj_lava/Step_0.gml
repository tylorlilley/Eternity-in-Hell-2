if (process_this_frame()) {
	event_inherited();

	calculate_lighting(1);

	// Randomize visual
	rotate_sprite_to_random_angle();
	flip_sprite_at_random(true);
	
	if (instance_number(death_box) < 1) { instance_destroy(); }
	
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