/// @description End Step
var dir = get_direction_pushed_against();
var target = get_dropped_meat(), time_to_peek = 8;
if (!is_existing_instance(target)) { target = global.player; }

if (dir == directions.none) {
	move_timer -= 1;
	if (move_timer > time_to_peek && get_distance_to_instance(target) <= TRAP_RANGE+16) { move_timer -= 3; }
	if (move_timer <= 0) {
		var move_dir = directions.none, possible_directions = array_create(0);
		if (get_distance_to_instance(target) <= TRAP_RANGE+16) {
			// Choose random possible direction that is towards the player
			if (is_direction_towards(directions.up, target) && can_move_in_direction(directions.up, false, true)) { array_push(possible_directions, directions.up); }
			if (is_direction_towards(directions.right, target) && can_move_in_direction(directions.right, false, true)) { array_push(possible_directions, directions.right); }
			if (is_direction_towards(directions.down, target) && can_move_in_direction(directions.down, false, true)) { array_push(possible_directions, directions.down); }
			if (is_direction_towards(directions.left, target) && can_move_in_direction(directions.left, false, true)) { array_push(possible_directions, directions.left); }
		}
		if (array_length(possible_directions) == 0) {
			// Choose random possible direction
			if (can_move_in_direction(directions.up, false, true)) { array_push(possible_directions, directions.up); }
			if (can_move_in_direction(directions.right, false, true)) { array_push(possible_directions, directions.right); }
			if (can_move_in_direction(directions.down, false, true)) { array_push(possible_directions, directions.down); }
			if (can_move_in_direction(directions.left, false, true)) { array_push(possible_directions, directions.left); }
		}
		// Move in chosen direction
		move_dir = array_random_get(possible_directions);
		if (move_dir != directions.none) {
			move_in_direction(move_dir, false);
			play_sound(snd_thud, false);
		}
		image_index = 0;
		move_timer = irandom_range(128, 256);
	}
}
if (move_timer <= time_to_peek) { image_index = 2; }
else { image_index = 0; }

event_inherited();
	