/// @description Step
event_inherited();

var _enemies_at_position = instance_place_all(x, y, obj_enemy);
while (array_length(_enemies_at_position) > 0) {
	var _enemy = array_random_pop(_enemies_at_position);
	if (is_existing_instance(_enemy) && _enemy.activated) {

		if (_enemy.corporeal) {
			with _enemy { 
				if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) {
					kill_enemy(snd_crunch, obj_giant_worm_body);
					increment_run_stat("worm_kill_count");
				}
			}
		}

	}
}
	