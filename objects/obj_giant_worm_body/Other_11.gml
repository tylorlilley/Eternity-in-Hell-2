/// @description Step
event_inherited();

// Crush the enemies it moves onto
var _enemies_at_position = instance_place_all(x, y, obj_enemy);
while (array_length(_enemies_at_position) > 0) {
	var _enemy = array_random_pop(_enemies_at_position);
	if (is_existing_instance(_enemy) && _enemy.activated) {

		// A corporeal enemy dies once solids cover all four of its quadrants, except a hand carrying the special staff,
		// which can pass through solids
		if (_enemy.corporeal) {
			with _enemy { 
				if (is_covered_at_each_quadrant_by(obj_solid) && (object_index != obj_hands || !is_carrying_special_item(obj_staff))) {
					kill_enemy(snd_crunch, obj_block);
					global.controller.evaluation_manager.increment_evaluation_variable("worm_kill_count");
				}
			}
		}

	}
}
	