/// @description Step
if (can_process_this_frame()) {
	var _dir = directions.none, _prev_image_index = image_index
	if (infectious) { 
		_dir = irandom(16) > 3 ? directions.none : move_towards_coordinates(global.player.x, global.player.y, false, false);
	}
	else { _dir = run_away_from_player(false, true, false); }
	
	switch (_dir) {
		case directions.up: { y += 4; break; }
		case directions.right: { x -= 4; break; }
		case directions.down: { y -= 4; break; }
		case directions.left: { x += 4; break; }
	}
	if (_dir != directions.none) { 
		image_angle = 90 * _dir; 
		image_index = _prev_image_index+1;
		if (image_index > 3) { image_index = 0; }
	}
	image_xscale = 1;

	event_inherited();
	var _crushed_by_player = get_distance_to_instance(global.player) <= 4;
	var _killed_by_lava = instance_place(x, y, obj_death);
	if (_crushed_by_player ||_killed_by_lava || is_solid_at_position(x, y)) {
		instance_destroy();
		if (!_killed_by_lava) { play_sound(snd_thud, false); }
		if (_crushed_by_player) {
			increment_run_stat("crushed_bugs");
		}
	}
}

