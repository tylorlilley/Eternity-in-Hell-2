if (process_this_frame()) {
	timer += 1;
	if (timer >= 4) { 
		timer = 0;
		if (dir != -1 && can_move_worm_in_direction(dir, false, true)) { 
			move_in_direction(dir, true);
			with tail { move_segments(other.dir); }
		}
		else { dir = -1; }
		
		if (dir == -1) {
			var new_directions = array_create(0);
			array_push(new_directions, 0, 1, 2, 3);
			while (array_length(new_directions) > 0) {
				var new_dir = array_random_pop(new_directions);
				if (can_move_worm_in_direction(new_dir, false, true)) { dir = new_dir; break; }
			}
			if (dir != -1) { audio_play_sound( snd_thud, 10, false ); }
		}
	}
	
	set_segment_images();
	event_inherited();
}