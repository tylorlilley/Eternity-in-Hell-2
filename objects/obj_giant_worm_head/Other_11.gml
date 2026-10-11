/// @description Step
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
		var _new_directions = [directions.up, directions.right, directions.down, directions.left];
		while (array_length(_new_directions) > 0) {
			var _new_dir = array_random_pop(_new_directions);
			var _target = get_dropped_meat();
			if (!is_existing_instance(_target)) { _target = global.player; }
			if (is_direction_free(_new_dir, false, true)) { 
				if (dir == directions.none || is_direction_towards(_new_dir, _target)) { dir = _new_dir; }
			}
		}
		if (dir != directions.none) { play_sound(snd_thud, false); }
	}
}
	
set_segment_images();
event_inherited();