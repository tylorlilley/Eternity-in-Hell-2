if (can_process_this_frame()) {
	event_inherited();
	
	var dir = get_direction_pushed_against();
	
	if (!is_existing_instance(global.player.moved_by) && dir != directions.none && can_move_in_direction(dir, false, true)) { 
		play_sound(snd_thud, false);
		snap_player_to_position(dir);
		move_in_direction(dir, false); 
		move_player(dir);
	}
	
	// Destroy self and/or enemy when pushed onto an enemy
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position);
		if (is_existing_instance(enemy) && enemy.activated && is_instance_at_coordinates(x, y, enemy)) {
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
		dirt.depth = 11;
		play_sound(snd_extinguish, true);
		instance_destroy();
	}
}
