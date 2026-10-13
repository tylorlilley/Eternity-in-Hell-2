/// @description Step
if (can_process_this_frame()) {
	var _target = get_dropped_meat();
	if (!is_existing_instance(_target)) { _target = global.player; }
	var _dir = point_direction(x, y, _target.x, _target.y);

	if (dying == 0) {
		// Update Pupil Position
		var _prev_x = pupil_x, _prev_y = pupil_y;
		pupil_x = x + lengthdir_x(16, _dir);
		pupil_y = y + lengthdir_y(16, _dir);
		if (_prev_x != pupil_x || _prev_y != pupil_y) { spin_counter += point_distance(pupil_x, pupil_y, _prev_x, _prev_y); }
		else { spin_counter = 0; }
		
		// Kill Self
		if (spin_counter > 512 || spin_counter < -512) { dying = 32; killed_by = obj_player; }
		else {
			// Shoot Beam
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
		// Shoot Randomly 
		_dir = irandom_range(1,360);
		var _x_pos = x + lengthdir_x(8, _dir), _y_pos = y + lengthdir_y(8, _dir);
		var _beam = shoot_projectile(_x_pos, _y_pos, false, obj_magic_beam);
		
		// Animate Death
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
		
		pupil_x = x + (-2 + irandom(4));
		pupil_y = y - 16;
		if dying == 0 { 
			play_sound(snd_explosion, true); 
			screen_flash();
			for (var _i = 0; _i < 3; _i ++) {
				var _blood_x_pos = x + (8 * (-2 + irandom(4))), _blood_y_pos = y + (8 * (-2 + irandom(4)));
				instance_create(_blood_x_pos, _blood_y_pos, obj_blood);
			}
			instance_destroy();
			if (killed_by != noone) { record_run_kill(object_index, killed_by); }
			increment_run_stat("giant_eye_room_solved");
		}
	}
}




