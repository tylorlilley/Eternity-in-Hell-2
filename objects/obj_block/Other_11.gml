/// @description End Step
event_inherited();
	
var dir = get_direction_pushed_against();
just_pushed = false;

if (dir != directions.none && can_move_in_direction(dir, false, true)) {
	play_sound(snd_thud, false);
	snap_player_to_position(dir);
	move_in_direction(dir, false);
	move_player(dir);
	just_pushed = true;
}
	
if (just_pushed) {
	// Destroy self and/or enemy when pushed onto an enemy
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position), should_consume_block = enemy.consume_block;
		if (is_existing_instance(enemy) && enemy.activated) {
			if (enemy.corporeal) {
				with enemy { 
					if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) {
						kill_enemy(snd_crunch, obj_block);
						global.controller.block_kill_count += 1;
						write_debug_message("block_kill_count += 1", "Eval");
					}
				}
			}
			if (should_consume_block) { instance_destroy(); }
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
		global.controller.blocks_pushed_into_lava += 1;
		write_debug_message("blocks_pushed_into_lava += 1", "Eval");
		play_sound(snd_extinguish, true);
		instance_destroy();
	}
}
