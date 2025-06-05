/// @description Step
if (spawn_timer > 0) { spawn_timer -= 1; }
else {
	// Determine if room is dark
	var in_dark_room = false, in_light = false, current_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
	var greatest_lighting_range = PLAYER_LIGHT_RANGE;
	with obj_light_source {
		if (lighting_range > greatest_lighting_range) { greatest_lighting_range = lighting_range; }
	}
	in_dark_room = (greatest_lighting_range <= PLAYER_LIGHT_RANGE);
	in_light = (current_lighting > 0);
	
	// Determine movement speed
	skeleton_speed = ((in_dark_room && !is_game_lost()) || in_light) ? FAST_SKELETON_MOVE_FREQUENCY : SKELETON_MOVE_FREQUENCY;
	
	// Determine if movement happens this frame
	var dir = irandom(skeleton_speed), moved = false, current_x_scale = image_xscale;
	if (is_cardinal_direction(dir)) {
		// Hunt meat and hunt players in the dark
		if (is_existing_instance(get_dropped_meat()) || in_dark_room) {
			dir = move_towards_meat_or_player(false, false);
			moved = (dir != directions.none);
		}
		else { end_target_path(); }
		
		// Find a direction with the least light if possible
		if (!moved && in_light) {
			var current_x = x, current_y = y, start_pos = irandom(3), least_lighting = current_lighting;
		
			for (var i = 0; i < directions.stairs; i++) {
				var target_dir = (i + start_pos) % 4
				if (target_dir == directions.up) { y -= 8; } 
				else if (target_dir == directions.right) { x += 8; }
				else if (target_dir == directions.down) { y += 8; }
				else if (target_dir == directions.left) { x -= 8; }
				var target_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
				if (target_lighting < least_lighting && can_move_in_direction(target_dir, false, false)) { 
					dir = target_dir; least_lighting = target_lighting; 
				}
				x = current_x;
				y = current_y;
			}
		}
		
		// Move in chosen direction
		if (!moved && can_move_in_direction(dir, false, false)) { moved = (move_in_direction(dir, true) != directions.none); }
	}
	
	// Update Graphics
	if (moved) { 
		image_angle = dir * -90;
		image_xscale = -current_x_scale;
	}
	else if (get_random_chance_out_of(skeleton_speed/4)) {
		image_xscale = -current_x_scale;
	}
}

event_inherited();
