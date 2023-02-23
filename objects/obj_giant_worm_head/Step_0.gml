if (can_process_this_frame()) {
	timer += 1;
	if (timer >= 4) { 
		if (dir != directions.none) { prev_dir = dir; }
		timer = 0;
		if (dir != directions.none && is_direction_free(dir, false, true)) { 
			move_in_direction(dir, false);
			play_sound(snd_walk, false)
			with (tail) { 
				move_segments(other.dir); 
			}
		}
		else { dir = directions.none; }
		
		// Turn in a new available direction
		if (dir == directions.none) {
			var new_directions = [directions.up, directions.right, directions.down, directions.left];
			while (array_length(new_directions) > 0) {
				var new_dir = array_random_pop(new_directions);
				var target = get_dropped_meat();
				if (!is_existing_instance(target)) { target = global.player; }
				if (is_direction_free(new_dir, false, true)) { 
					if (dir == directions.none || is_direction_toward(new_dir, target)) { dir = new_dir; }
				}
			}
			if (dir != directions.none) { play_sound(snd_thud, false); }
		}
	}
	
	set_segment_images();
	event_inherited();
}