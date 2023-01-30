if (can_process_this_frame()) {
	if (walk_timer > 0) { walk_timer -= 1; }
	else {
		walk_timer = 2;
		if (array_length(generator.moves) > move_pos) {
			var dir = generator.moves[move_pos]
			if (dir != directions.none) {
				move_in_direction(dir, false);
				play_sound(snd_walk, false);
				image_index = modulo(move_pos, 2);
			}
			move_pos += 1;
		}
	}

	event_inherited();
}
