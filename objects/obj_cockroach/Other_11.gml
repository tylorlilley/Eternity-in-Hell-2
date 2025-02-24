/// @description Step
if (spawn_timer > 0) { spawn_timer -= 1; }
else {
	var dir = irandom(skeleton_speed);
	var dropped_meat = get_dropped_meat();
	var current_x_scale = image_xscale, current_y_scale = image_yscale, prev_angle = image_angle;
	if (is_cardinal_direction(dir)) {
		// Try to set up path toward dropped meat
		if (is_existing_instance(dropped_meat)) {
			target_x = dropped_meat.x;
			target_y = dropped_meat.y;
			set_automatic_target_path();
		}
		else { end_target_path(); }
		
		// Move Away from Light
		var current_x = x, current_y = y, current_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
		if (dir == directions.up) { y -= 8; } 
		else if (dir == directions.right) { x += 8; }
		else if (dir == directions.down) { y += 8; }
		else if (dir == directions.left) { x -= 8; }
		var target_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
		x = current_x;
		y = current_y;
		if (target_lighting > current_lighting) {
			var new_dir = get_opposite_dir(dir);
			if (new_dir == directions.up) { y -= 8; } 
			else if (new_dir == directions.right) { x += 8; }
			else if (new_dir == directions.down) { y += 8; }
			else if (new_dir == directions.left) { x -= 8; }
			var new_target_lighting = get_greatest_lighting(PLAYER_LIGHT_RANGE);
			if (current_lighting > new_target_lighting) { dir = new_dir; skeleton_speed = FAST_SKELETON_MOVE_FREQUENCY; }
			x = current_x;
			y = current_y;
		}
		
		// Move toward point
		var moved = false;
		if (target_path != noone) {  dir = move_towards_coordinates_on_path(false, false, 1); moved = true; }
		else {
			// Move towards player in darkness and random direction otherwise
			var greatest_lighting_range = PLAYER_LIGHT_RANGE;
			with obj_light_source {
				if (lighting_range > greatest_lighting_range) { greatest_lighting_range = lighting_range; }
			}
			if (greatest_lighting_range <= PLAYER_LIGHT_RANGE) { dir = move_toward_player(false, false, 3); moved = true; skeleton_speed = SKELETON_MOVE_FREQUENCY; }
			else if (can_move_in_direction(dir, false, false)) { move_in_direction(dir, true); moved = true; skeleton_speed = SKELETON_MOVE_FREQUENCY; }
		}
		
		// Update Graphics
		if moved || get_random_chance_out_of(skeleton_speed/4) { 
			image_angle = dir * -90;
			image_xscale = current_x_scale;
			image_yscale = current_y_scale;
			if (image_angle != prev_angle) { image_xscale = 1; image_yscale = 1; }
			//else if (dir == directions.up || dir == directions.down) { image_xscale = current_x_scale * -1; }
			//else if (dir == directions.left || dir == directions.right) { image_yscale = current_y_scale * -1; }
		}
	}
}

event_inherited();
