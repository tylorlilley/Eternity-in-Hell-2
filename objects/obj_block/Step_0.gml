if (can_process_this_frame()) {
	event_inherited();
	
	var dir = noone;

	if global.controller.key_up && !global.controller.key_down && (global.controller.key_up_pressed || !global.controller.key_up_released) { dir = directions.up; }
	else if global.controller.key_down && !global.controller.key_up && (global.controller.key_down_pressed || !global.controller.key_down_released) { dir = directions.down; }
	else if global.controller.key_left && !global.controller.key_right && (global.controller.key_left_pressed || !global.controller.key_left_released) { dir = directions.left; }
	else if global.controller.key_right && !global.controller.key_left && (global.controller.key_right_pressed || !global.controller.key_right_released) { dir = directions.right; }
		
	if (!global.player.moved_by_self && !global.player.moved_by_other_object && dir != noone && get_direction_pushed_against() == dir && can_move_in_direction(dir, false, true)) { 
		play_sound(snd_thud, false);
		snap_player_to_position(dir);
		move_in_direction(dir, false); 
		move_player(dir);
	}
	
	// Destroy self and/or enemy when pushed onto an enemy
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position);
		if (enemy != noone && enemy.activated && is_instance_at_coordinates(x, y, enemy)) {
			if (enemy.consume_block) { instance_destroy(); }
			if (enemy.corporeal) {
				with enemy { 
					if (object_index != obj_hands || !is_carrying_special_item(obj_staff)) {
						kill_enemy(snd_crunch); 
					}
				}
			}
		}
	}
	
	// Destroy self and parts of lava if pushed onto lava
	if (consume_lava(true)) {
		var dirt = instance_create(x, y, obj_dirt);
		dirt.depth = 8;
		play_sound(snd_extinguish, true);
		instance_destroy();
	}
}
