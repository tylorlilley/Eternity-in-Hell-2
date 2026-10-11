/// @description End Step
var _dir = get_direction_pushed_against();
var _target = get_dropped_meat(), _time_to_peek = 8;
if (!is_existing_instance(_target)) { _target = global.player; }

if (_dir == directions.none) {
	move_timer -= 1;
	if (move_timer > _time_to_peek && get_distance_to_instance(_target) <= TRAP_RANGE+16) { move_timer -= 3; }
	if (move_timer <= 0) {
		var _move_dir = directions.none, _possible_directions = [];
		if (get_distance_to_instance(_target) <= TRAP_RANGE+16) {
			// Choose random possible direction that is towards the player
			if (is_direction_towards(directions.up, _target) && can_move_in_direction(directions.up, false, true)) { array_push(_possible_directions, directions.up); }
			if (is_direction_towards(directions.right, _target) && can_move_in_direction(directions.right, false, true)) { array_push(_possible_directions, directions.right); }
			if (is_direction_towards(directions.down, _target) && can_move_in_direction(directions.down, false, true)) { array_push(_possible_directions, directions.down); }
			if (is_direction_towards(directions.left, _target) && can_move_in_direction(directions.left, false, true)) { array_push(_possible_directions, directions.left); }
		}
		if (array_length(_possible_directions) == 0) {
			// Choose random possible direction
			if (can_move_in_direction(directions.up, false, true)) { array_push(_possible_directions, directions.up); }
			if (can_move_in_direction(directions.right, false, true)) { array_push(_possible_directions, directions.right); }
			if (can_move_in_direction(directions.down, false, true)) { array_push(_possible_directions, directions.down); }
			if (can_move_in_direction(directions.left, false, true)) { array_push(_possible_directions, directions.left); }
		}
		// Move in chosen direction
		_move_dir = array_random_get(_possible_directions);
		if (_move_dir != directions.none) {
			move_in_direction(_move_dir, false);
			play_sound(snd_thud, false);
		}
		image_index = 0;
		move_timer = irandom_range(128, 256);
	}
}
if (move_timer <= _time_to_peek) { image_index = 2; }
else { image_index = 0; }

event_inherited();
	