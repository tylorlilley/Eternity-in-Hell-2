if (process_this_frame()) {
	event_inherited();

	calculate_lighting(0.5);

	// Randomize visual
	rotate_sprite_to_random_angle();
	flip_sprite_at_random(true);
}