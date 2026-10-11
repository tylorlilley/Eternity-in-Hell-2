/// @description Step
if (spawn_timer > 0) { spawn_timer -= 1; }
else {
	// Determine if room is dark and if cockroach is currently in a bright light
	var _in_dark_room = false, _in_light = false, _current_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
	var _greatest_lighting_range = PLAYER_LIGHT_RANGE;
	with obj_light_source {
		if (lighting_range > _greatest_lighting_range) { _greatest_lighting_range = lighting_range; }
	}
	_in_dark_room = (_greatest_lighting_range <= PLAYER_LIGHT_RANGE);
	_in_light = (_current_lighting > 0);
	
	// Determine movement speed
	if (_in_dark_room && !is_game_lost()) { skeleton_speed = COCKROACH_HUNT_MOVE_FREQUENCY; }
	else if (_in_light) { skeleton_speed = FAST_SKELETON_MOVE_FREQUENCY; }
	else { skeleton_speed = SKELETON_MOVE_FREQUENCY; }
	
	// Determine if movement happens this frame
	var _dir = irandom(skeleton_speed), _moved = false, _current_x_scale = image_xscale;
	if (is_cardinal_direction(_dir)) {
		// Hunt meat and hunt players in the dark
		if (is_existing_instance(get_dropped_meat()) || _in_dark_room) {
			_dir = move_towards_meat_or_player(false, false);
			_moved = (_dir != directions.none);
		}
		else { end_target_path(); }
		
		// Find a direction with the least light if possible
		if (!_moved && _in_light) {
			var _current_x = x, _current_y = y, _start_pos = irandom(3), _least_lighting = _current_lighting;
		
			for (var _i = 0; _i < directions.stairs; _i++) {
				var _target_dir = (_i + _start_pos) % 4
				if (_target_dir == directions.up) { y -= 8; } 
				else if (_target_dir == directions.right) { x += 8; }
				else if (_target_dir == directions.down) { y += 8; }
				else if (_target_dir == directions.left) { x -= 8; }
				var _target_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
				if (_target_lighting < _least_lighting && can_move_in_direction(_target_dir, false, false)) { 
					_dir = _target_dir; _least_lighting = _target_lighting; 
				}
				x = _current_x;
				y = _current_y;
			}
		}
		
		// Move in chosen direction
		if (!_moved && can_move_in_direction(_dir, false, false)) { _moved = (move_in_direction(_dir, true) != directions.none); }
	}
	
	// Update Graphics
	if (_moved) { 
		image_angle = _dir * -90;
		image_xscale = -_current_x_scale;
	}
	else if (get_random_chance_out_of(skeleton_speed/4)) {
		image_xscale = -_current_x_scale;
	}
	if (_in_dark_room && !made_noise) { play_sound(snd_cockroach, false); made_noise = true; }
	image_index = (_in_dark_room) ? 0 : 1;
}

event_inherited();
