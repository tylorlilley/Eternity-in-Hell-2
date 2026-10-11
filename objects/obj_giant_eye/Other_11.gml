/// @description Step
if (can_process_this_frame()) {
	// Look at dropped meat if there is any, and at the player otherwise
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	var _dir = point_direction(x, y, _target.x, _target.y);

	if (dying == 0) {
		// Update pupil position, counting how far it has moved since it last stood still
		var _prev_x = pupil_x, _prev_y = pupil_y;
		pupil_x = x + lengthdir_x(16, _dir);
		pupil_y = y + lengthdir_y(16, _dir);
		if (_prev_x != pupil_x || _prev_y != pupil_y) { spin_counter += point_distance(pupil_x, pupil_y, _prev_x, _prev_y); }
		else { spin_counter = 0; }
		
		// Start dying once the pupil has moved 512 pixels without stopping, as it does when the player circles the eye
		if (spin_counter > 512 || spin_counter < -512) { dying = 32; }
		else {
			// Shoot a magic beam at the target from the pupil
			if (shoot_timer > 0) { shoot_timer -= 1; }
			else {
				var _beam = shoot_magic_beam(_target, 12);
				_beam.x = pupil_x;
				_beam.y = pupil_y;
				shoot_timer = irandom_range(12,32);
			}
		}
	}
	else {
		// While dying, shoot magic beams in random directions
		var _dir = irandom_range(1,360), _x_pos = x + lengthdir_x(8, _dir), _y_pos = y + lengthdir_y(8, _dir);
		var _beam = shoot_projectile(_x_pos, _y_pos, false, obj_magic_beam);
		
		// Animate death: at random, one step in four, the eye parts flash to their second set of frames with a burst sound
		dying -= 1;
		if (get_random_chance_out_of(4)) { 
			play_sound(snd_eyeball_explosion, true); image_index = 1;
			for (var _i = 0; _i < GIANT_EYE_PARTS_COUNT; _i++) {
				var _eye_part = eye_parts[_i];
				_eye_part.image_index = _i+9;
			}
		}
		else {
			for (var _i = 0; _i < GIANT_EYE_PARTS_COUNT; _i++) {
				var _eye_part = eye_parts[_i];
				_eye_part.image_index = _i;
			}
		}
		
		// Roll the pupil up and shake it
		pupil_x = x + (-2 + irandom(4));
		pupil_y = y - 16;
		// At the end of the animation, burst into blood, and count the kill and the solved giant eye room
		if dying == 0 { 
			play_sound(snd_explosion, true); 
			screen_flash();
			for (var _i = 0; _i < 3; _i ++) {
				var _x_pos = x + (8 * (-2 + irandom(4))), _y_pos = y + (8 * (-2 + irandom(4)));
				instance_create(_x_pos, _y_pos, obj_blood);
			}
			instance_destroy();
			update_kill_log(object_index, global.difficulty, object_index);
			global.controller.evaluation_manager.increment_evaluation_variable("giant_eye_room_solved");
		}
	}
}




