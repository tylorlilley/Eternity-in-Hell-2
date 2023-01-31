if (can_process_this_frame()) {
	event_inherited();
	
	for (var quadrant = 0; quadrant < 4; quadrant++) {
		for (var dir = 0; dir < 4; dir++) {
			lava_edge_image_indexes[quadrant][dir] = irandom(7);
			lava_edge_image_xscales[quadrant][dir] = (get_coin_flip()) ? 1 : -1;
		}
	}
	
	// Randomize visual
	rotate_sprite_to_random_angle();
	flip_sprite_at_random(true);
	destroy_self_if_all_death_boxes_are_destroyed();
}