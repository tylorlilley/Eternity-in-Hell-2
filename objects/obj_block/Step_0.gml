if (process_this_frame()) {
	event_inherited();
	
	var dir = noone;

	if global.controller.key_up && !global.controller.key_down && (global.controller.key_up_pressed || !global.controller.key_up_released) { dir = directions.up; }
	else if global.controller.key_down && !global.controller.key_up && (global.controller.key_down_pressed || !global.controller.key_down_released) { dir = directions.down; }
	else if global.controller.key_left && !global.controller.key_right && (global.controller.key_left_pressed || !global.controller.key_left_released) { dir = directions.left; }
	else if global.controller.key_right && !global.controller.key_left && (global.controller.key_right_pressed || !global.controller.key_right_released) { dir = directions.right; }
		
	if (pushed_against_by_player(true) == dir && can_move_in_direction(dir, false, true)) { 
		audio_play_sound(snd_thud, 10, false);
		move_in_direction(dir, false); 
		move_player(dir);
	}
	
	// Destroy self and/or enemy when pushed onto an enemy
	var enemy = instance_place(x, y, obj_enemy);
	if (enemy && instance_at_coordinates(x, y, enemy)) {
		if enemy.consume_block { instance_destroy(); }
		if enemy.consumed_by_block { with enemy { kill_enemy(); } }
	}
	
	// Destroy self and parts of lava if pushed onto lava
	var lava_at_quadrant = get_presence_at_each_quadrant(obj_lava);
	if (lava_at_quadrant[0] && lava_at_quadrant[1] && lava_at_quadrant[2] && lava_at_quadrant[3]) {
		var death_boxes = get_presence_at_each_quadrant(obj_death);
		if (death_boxes[0] && death_boxes[1] && death_boxes[2] && death_boxes[3]) {
			for (var i = 0; i <= 3; i++) {
				var x_pos = get_quadrant_x_pos(i), y_pos = get_quadrant_y_pos(i);
			
				with lava_at_quadrant[i] { destroy_lava_at_position(x_pos, y_pos); }
		    }
			instance_destroy();
			audio_play_sound(snd_extinguish, 10, false);
		}
	}
}
