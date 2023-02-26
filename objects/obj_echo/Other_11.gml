/// @description Step

var dropped_meat = get_dropped_meat();
	
if (walk_timer > 0) { walk_timer -= 1; }
if (!is_existing_instance(dropped_meat) || !is_instance_at_coordinates(x, y, dropped_meat)) {
	walk_timer = 1;
	if (array_length(generator.moves) > move_pos) {
		var dir = generator.moves[move_pos]
		if (dir != directions.none) {
			move_in_direction(dir, false);
			play_sound(snd_walk, false);
			image_index += modulo(move_pos, 2);
		}
		move_pos += 1;
	}
}

event_inherited();
