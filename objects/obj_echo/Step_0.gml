if (process_this_frame()) {
	if (walk_timer > 0) { walk_timer -= 1; }
	else {
		walk_timer = 2;
		if (array_length(generator.moves) > move_pos) {
			var dir = generator.moves[move_pos]
			move_in_direction(dir, true);
			move_pos += 1;
			image_index = move_pos mod 2;
		}
	}

	event_inherited();
}
