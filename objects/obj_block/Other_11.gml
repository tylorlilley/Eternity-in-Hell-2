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
					if (other.just_pushed) { update_kill_log(object_index, global.difficulty, object_index); }
				}
			}
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
	play_sound(snd_extinguish, true);
	instance_destroy();
}
