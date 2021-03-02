if (process_this_frame()) {
	var prev_dir = (dir == -1) ? irandom(3) : dir;
	for (var i = 0; i < 2; i +=1) {
		if (dir != -1 && can_move_in_direction(dir, false, true)) { move_in_direction(dir, true); }
		else { dir = -1; break; }
	}
	if (dir == -1) {
		var new_directions = ds_list_create();
		ds_list_add(new_directions, opposite_dir(prev_dir), dir_turn_right(prev_dir), dir_turn_left(prev_dir));
		while (ds_list_size(new_directions) > 0) {
			var new_dir = ds_list_pop_random_value(new_directions);
			if (can_move_in_direction(new_dir, false, true)) { dir = new_dir; break; }
		}
		if (dir != -1) { audio_play_sound( snd_hiss, 10, false ); image_speed = 1; }
		else { image_speed = 0; }
		ds_list_destroy(new_directions);
	}
	
	event_inherited();
}
