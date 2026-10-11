/// @description Step
event_inherited();
	
var _dir = get_direction_pushed_against();
just_pushed = false;

if (_dir != directions.none) {
	if (can_move_in_direction(_dir, false, true)) {
		play_sound(snd_thud, false);
		snap_player_to_position(_dir);
		move_in_direction(_dir, false);
		move_player(_dir);
		just_pushed = true;
	}
	else { play_sound(snd_locked, false); }
}
	
if (just_pushed) {
	// Destroy self and/or enemy when pushed onto an enemy
	var _enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(_enemies_at_position) > 0) {
		var _enemy = array_random_pop(_enemies_at_position);
		if (is_existing_instance(_enemy) && _enemy.activated) {
			var _should_consume_block = _enemy.consume_block && is_instance_at_coordinates(x, y, _enemy), _should_play_sound = _enemy.object_index == obj_fire_skeleton;
			if (_enemy.corporeal) {
				with _enemy { 
					if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) {
						if (object_index == obj_nose) {
							increment_run_stat("nose_block_kill_count");
						}
						kill_enemy(snd_crunch, obj_block);
						increment_run_stat("block_kill_count");
						other.just_killed += 1;
					}
				}
			}
			if (_should_consume_block) {
				if (_should_play_sound) { play_sound(snd_extinguish, true); }
				instance_destroy();
			}
		}
	}
	
	// Destroy self and parts of lava if pushed onto lava
	if (consume_lava(true)) {
		//var dirt = instance_create(x, y, obj_dirt);
		//if (is_existing_instance(dirt)) { dirt.depth = DIRT_OVER_LAVA_DEPTH; }
		var _tile = instance_create(x, y, obj_path);
		if (is_existing_instance(_tile)) { 
			_tile.depth = DIRT_OVER_LAVA_DEPTH; 
			_tile.image_angle = image_angle;
			_tile.image_xscale = image_xscale;
			_tile.image_yscale = image_yscale;
		}
		
		increment_run_stat("blocks_pushed_into_lava");
		if (object_index == obj_living_block) {
			record_run_kill(obj_living_block, (just_pushed) ? obj_player : obj_living_block);
		}
		play_sound(snd_extinguish, true);
		instance_destroy();
	}
}
