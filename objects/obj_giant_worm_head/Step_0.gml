if (can_process_this_frame()) {
	timer += 1;
	if (timer >= 4) { 
		if (dir != -1) { prev_dir = dir; }
		timer = 0;
		if (dir != -1 && is_direction_free(dir, false, true)) { 
			move_in_direction(dir, false);
			play_sound(snd_walk, false)
			with tail { move_segments(other.dir); }
		}
		else { dir = -1; }
		
		// Turn in a new available direction
		if (dir == -1) {
			var new_directions = array_create(0);
			array_push(new_directions, 0, 1, 2, 3);
			while (array_length(new_directions) > 0) {
				var new_dir = array_random_pop(new_directions);
				var target = get_dropped_meat();
				if (target == noone) { target = global.player; }
				if (is_direction_free(new_dir, false, true)) { 
					if (dir == -1 || is_direction_toward(new_dir, target)) { dir = new_dir; }
				}
			}
			if (dir != -1) { play_sound(snd_thud, false); }
		}
	}
	
	set_segment_images();
	event_inherited();
}