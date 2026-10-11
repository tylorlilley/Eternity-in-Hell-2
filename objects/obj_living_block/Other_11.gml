/// @description Step
// A living block that nobody is pushing moves by itself now and then: towards its target (the dropped meat, or else
// the player) once that is close, and in random directions otherwise. _time_to_peek is how many steps before a move
// it shows its peeking frame
var _dir = get_direction_pushed_against();
var _target = get_dropped_meat(), _time_to_peek = 8;
if (!is_existing_instance(_target)) { _target = global.player; }

if (_dir == directions.none) {
	// Count down to the next move, four times as fast while its target is close, except through the steps it peeks
	move_timer -= 1;
	if (move_timer > _time_to_peek && get_distance_to_instance(_target) <= TRAP_RANGE+16) { move_timer -= 3; }
	if (move_timer <= 0) {
		var _move_dir = directions.none, _possible_directions = [];
		if (get_distance_to_instance(_target) <= TRAP_RANGE+16) {
			// Close to its target, the directions it can move in that are towards it (lava doesn't stop it)
			if (is_direction_towards(directions.up, _target) && can_move_in_direction(directions.up, false, true)) { array_push(_possible_directions, directions.up); }
			if (is_direction_towards(directions.right, _target) && can_move_in_direction(directions.right, false, true)) { array_push(_possible_directions, directions.right); }
			if (is_direction_towards(directions.down, _target) && can_move_in_direction(directions.down, false, true)) { array_push(_possible_directions, directions.down); }
			if (is_direction_towards(directions.left, _target) && can_move_in_direction(directions.left, false, true)) { array_push(_possible_directions, directions.left); }
		}
		if (array_length(_possible_directions) == 0) {
			// Otherwise any direction it can move in
			if (can_move_in_direction(directions.up, false, true)) { array_push(_possible_directions, directions.up); }
			if (can_move_in_direction(directions.right, false, true)) { array_push(_possible_directions, directions.right); }
			if (can_move_in_direction(directions.down, false, true)) { array_push(_possible_directions, directions.down); }
			if (can_move_in_direction(directions.left, false, true)) { array_push(_possible_directions, directions.left); }
		}
		// Move in one of the possible directions at random, then wait a random time for the next move
		_move_dir = array_random_get(_possible_directions);
		if (_move_dir != directions.none) {
			move_in_direction(_move_dir, false);
			play_sound(snd_thud, false);
		}
		image_index = 0;
		move_timer = irandom_range(128, 256);
	}
}
// Peek during the steps before it moves
if (move_timer <= _time_to_peek) { image_index = 2; }
else { image_index = 0; }

// The inherited Step handles the player pushing it
event_inherited();
	