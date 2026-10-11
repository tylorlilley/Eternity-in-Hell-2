/// @description Step
// Move every fourth step, pulling the body segments after it
timer += 1;
if (timer >= 4) { 
	if (dir != directions.none) { prev_dir = dir; }
	timer = 0;
	// Keep going the same way while it's free, and stop once it's blocked
	if (dir != directions.none && is_direction_free(dir, false, true)) { 
		move_in_direction(dir, false);
		play_sound(snd_walk, false)
		with (tail) { 
			move_segments(other.dir); 
		}
	}
	else { dir = directions.none; }
		
	// Once stopped, turn a random free way, preferring one toward dropped meat, or toward the player if there's none
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
	
// Fit each segment's sprite to the worm's new shape
set_segment_images();
// Run the body segments' Step too, which crushes enemies under the head
event_inherited();