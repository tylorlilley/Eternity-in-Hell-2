if (process_this_frame()) {
	var prev_dir = (dir == -1) ? irandom(3) : dir;
	for (var i = 0; i < 2; i +=1) {
		if (dir != -1 && can_move_in_direction(dir, false, true)) { move_in_direction(dir, true); }
		else { dir = -1; break; }
	}
	if (dir == -1) {
		var new_directions = array_create(0);
		array_push(new_directions, opposite_dir(prev_dir), dir_turn_right(prev_dir), dir_turn_left(prev_dir));
		while (array_length(new_directions) > 0) {
			var new_dir = array_random_pop(new_directions);
			if (can_move_in_direction(new_dir, false, true)) { dir = new_dir; break; }
		}
		if (dir != -1) { audio_play_sound( snd_hiss, 10, false ); image_speed = 1; }
		else { image_speed = 0; }
		//ds_list_destroy(new_directions);
	}
	
	event_inherited();
}
