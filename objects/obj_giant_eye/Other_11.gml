/// @description Step
if (can_process_this_frame()) {
	var target = get_dropped_meat();
	if (!is_existing_instance(target)) { target = global.player; }
	var dir = point_direction(x, y, target.x, target.y);

	if (dying == 0) {
		// Update Pupil Position
		var prev_x = pupil_x, prev_y = pupil_y;
		pupil_x = x + lengthdir_x(16, dir);
		pupil_y = y + lengthdir_y(16, dir);
		if (prev_x != pupil_x || prev_y != pupil_y) { spin_counter += point_distance(pupil_x, pupil_y, prev_x, prev_y); }
		else { spin_counter = 0; }
		
		// Kill Self
		if (spin_counter > 512 || spin_counter < -512) { dying = 32; }
		else {
			// Shoot Beam
			if (shoot_timer > 0) { shoot_timer -= 1; }
			else {
				var beam = shoot_magic_beam(target, 12);
				beam.x = pupil_x;
				beam.y = pupil_y;
				shoot_timer = irandom_range(12,32);
			}
		}
	}
	else {
		// Shoot Randomly 
		var dir = irandom_range(1,360), x_pos = x + lengthdir_x(8, dir), y_pos = y + lengthdir_y(8, dir);
		var beam = shoot_projectile(x_pos, y_pos, false, obj_magic_beam);
		
		// Animate Death
		dying -= 1;
		if (get_random_chance_out_of(4)) { 
			play_sound(snd_eyeball_explosion, true); image_index = 1;
			for (var i = 0; i < 9; i++) {
				var eye_part = eye_parts[i];
				eye_part.image_index = i+9;
			}
		}
		else {
			for (var i = 0; i < 9; i++) {
				var eye_part = eye_parts[i];
				eye_part.image_index = i;
			}
		}
		
		pupil_x = x + (-2 + irandom(4));
		pupil_y = y - 16;
		if dying == 0 { 
			play_sound(snd_explosion, true); 
			screen_flash();
			for (var i = 0; i < 3; i ++) {
				var x_pos = x + (8 * (-2 + irandom(4))), y_pos = y + (8 * (-2 + irandom(4)));
				instance_create(x_pos, y_pos, obj_blood);
			}
			instance_destroy();
			update_kill_log(object_index, global.difficulty, object_index);
			global.controller.giant_eye_room_solved += 1;
			write_debug_message("giant_eye_room_solved += 1", "Eval");
			global.controller.kill_count += 1;
			write_debug_message("kill_count += 1", "Eval");
		}
	}
}




