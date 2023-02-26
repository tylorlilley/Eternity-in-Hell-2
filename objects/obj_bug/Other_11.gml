if (can_process_this_frame()) {
	var dir = directions.none;
	if (infectious) { dir = move_toward_player(false, false, 16); }
	else { dir = run_away_from_player(false, true, false); }
	
	switch (dir) {
		case directions.up: { y += 4; break; }
		case directions.right: { x -= 4; break; }
		case directions.down: { y -= 4; break; }
		case directions.left: { x += 4; break; }
	}
	if (dir != directions.none) { 
		image_angle = 90 * dir; 
		image_index += 1;
		if (image_index > 3) { image_index = 0; }
	}
	image_xscale = 1;

	event_inherited();
	if (get_distance_to_instance(global.player) <= 4 || instance_place(x, y, obj_death) || is_solid_at_position(x, y)) {
			instance_destroy();
			play_sound(snd_thud, false);
	}
}

