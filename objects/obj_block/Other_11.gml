/// @description Step
event_inherited();
	
var dir = get_direction_pushed_against();
just_pushed = false;

if (dir != directions.none) {
	if (can_move_in_direction(dir, false, true)) {
		play_sound(snd_thud, false);
		snap_player_to_position(dir);
		move_in_direction(dir, false);
		move_player(dir);
		just_pushed = true;
	}
	else { play_sound(snd_locked, false); }
}
	
if (just_pushed) {
	// Destroy self and/or enemy when pushed onto an enemy
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position);
		if (is_existing_instance(enemy) && enemy.activated) {
			var should_consume_block = enemy.consume_block && is_instance_at_coordinates(x, y, enemy), should_play_sound = enemy.object_index == obj_fire_skeleton;
			if (enemy.corporeal) {
				with enemy { 
					if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) {
						if (object_index == obj_nose) {
							global.controller.evaluation_manager.increment_evaluation_variable("nose_block_kill_count");
						}
						kill_enemy(snd_crunch, obj_block);
						global.controller.evaluation_manager.increment_evaluation_variable("block_kill_count");
						other.just_killed += 1;
					}
				}
			}
			if (should_consume_block) {
				if (should_play_sound) { play_sound(snd_extinguish, true); }
				instance_destroy();
			}
		}
	}
	
	// Destroy self and parts of lava if pushed onto lava
	if (consume_lava(true)) {
		//var dirt = instance_create(x, y, obj_dirt);
		//if (is_existing_instance(dirt)) { dirt.depth = DIRT_OVER_LAVA_DEPTH; }
		var tile = instance_create(x, y, obj_path);
		if (is_existing_instance(tile)) { 
			tile.depth = DIRT_OVER_LAVA_DEPTH; 
			tile.image_angle = image_angle;
			tile.image_xscale = image_xscale;
			tile.image_yscale = image_yscale;
		}
		
		global.controller.evaluation_manager.increment_evaluation_variable("blocks_pushed_into_lava");
		if (object_index == obj_living_block) {
			update_kill_log(obj_living_block, global.difficulty, (just_pushed) ? obj_player : obj_living_block);
		}
		play_sound(snd_extinguish, true);
		instance_destroy();
	}
}
