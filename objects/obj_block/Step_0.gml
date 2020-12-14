if (process_this_frame()) {
	event_inherited();
	
	var dir = noone;

	if global.controller.key_up && !global.controller.key_down && (global.controller.key_up_pressed || !global.controller.key_up_released) { dir = directions.up; }
	else if global.controller.key_down && !global.controller.key_up && (global.controller.key_down_pressed || !global.controller.key_down_released) { dir = directions.down; }
	else if global.controller.key_left && !global.controller.key_right && (global.controller.key_left_pressed || !global.controller.key_left_released) { dir = directions.left; }
	else if global.controller.key_right && !global.controller.key_left && (global.controller.key_right_pressed || !global.controller.key_right_released) { dir = directions.right; }
		
	if (pushed_against_by_player(false) == dir && can_move_in_direction(dir, false, true)) { 
		audio_play_sound(snd_thud, 10, false);
		move_in_direction(dir); 
		move_player(dir);
	}
	
	// Destroy self and lava when pushed into it
	var death = instance_place(x, y, obj_death);
	if (death && instance_at_coordinates(x, y, death)) {
		if death.consume_block { instance_destroy(); }
		if death.consumed_by_block { with death { instance_destroy(); } audio_play_sound(death.death_sound, 10, false); }
	}
	
}
