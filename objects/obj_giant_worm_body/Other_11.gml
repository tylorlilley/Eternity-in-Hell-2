/// @description Step
event_inherited();

var enemies_at_position = instance_place_all(x, y, obj_enemy);
while (array_length(enemies_at_position) > 0) {
	var enemy = array_random_pop(enemies_at_position);
	if (is_existing_instance(enemy) && enemy.activated) {
		var should_consume_block = enemy.consume_block, should_play_sound = enemy.object_index == obj_fire_skeleton;
		if (enemy.corporeal) {
			with enemy { 
				if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) {
					kill_enemy(snd_crunch, obj_block);
					global.controller.evaluation_manager.increment_evaluation_variable("worm_kill_count");
				}
			}
		}
		if (should_consume_block && is_instance_at_coordinates(x, y, enemy)) {
			if (should_play_sound) { play_sound(snd_extinguish, true); }
			instance_destroy();
		}
	}
}
	