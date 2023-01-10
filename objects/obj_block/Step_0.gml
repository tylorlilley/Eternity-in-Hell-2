if (process_this_frame()) {
	event_inherited();
	
	var dir = noone;

	if global.controller.key_up && !global.controller.key_down && (global.controller.key_up_pressed || !global.controller.key_up_released) { dir = directions.up; }
	else if global.controller.key_down && !global.controller.key_up && (global.controller.key_down_pressed || !global.controller.key_down_released) { dir = directions.down; }
	else if global.controller.key_left && !global.controller.key_right && (global.controller.key_left_pressed || !global.controller.key_left_released) { dir = directions.left; }
	else if global.controller.key_right && !global.controller.key_left && (global.controller.key_right_pressed || !global.controller.key_right_released) { dir = directions.right; }
		
	if (dir != noone && pushed_against_by_player(true) == dir && can_move_in_direction(dir, false, true)) { 
		play_sound(snd_thud, false);
		move_in_direction(dir, false); 
		move_player(dir);
	}
	
	// Destroy self and/or enemy when pushed onto an enemy
	var enemy = instance_place(x, y, obj_enemy);
	if (enemy != noone && enemy.visible && instance_at_coordinates(x, y, enemy)) {
		if enemy.consume_block { instance_destroy(); }
		if enemy.consumed_by_block { with enemy { kill_enemy(); } }
	}
	
	// Destroy self and parts of lava if pushed onto lava
	if (consume_lava(true)) {
		play_sound(snd_extinguish, true);
		instance_destroy();
	}
}
