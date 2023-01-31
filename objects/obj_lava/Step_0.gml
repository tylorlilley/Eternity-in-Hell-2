if (can_process_this_frame()) {
	event_inherited();
	
	// Randomize visual
	rotate_sprite_to_random_angle();
	flip_sprite_at_random(true);
	destroy_self_if_all_death_boxes_are_destroyed();
}