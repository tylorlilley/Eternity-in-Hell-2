if (can_process_this_frame()) {
	var dir = run_away_from_player(false, true, false);
	switch (dir) {
		case directions.up: { y += 4; break; }
		case directions.right: { x -= 4; break; }
		case directions.down: { y -= 4; break; }
		case directions.left: { x += 4; break; }
	}
	if (dir != directions.none) { image_angle = 90 * dir; }
	image_xscale = 1;

	event_inherited();
	
	if (get_distance_to_instance(global.player) <= 4 ||
		place_meeting(x, y, obj_death) ||
		place_meeting(x, y, obj_solid)) {
			instance_destroy();
			play_sound(snd_thud, false);
	}
}

