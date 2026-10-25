/// @description Step

var _dropped_meat = get_dropped_meat();
	
if (!is_existing_instance(_dropped_meat) || !is_instance_at_coordinates(x, y, _dropped_meat)) {
	if (array_length(generator.moves) > move_pos) {
		var _dir = generator.moves[move_pos]
		if (_dir != directions.none) {
			move_in_direction(_dir, false);
			play_sound(snd_walk, false);
			image_index = modulo(image_index + modulo(move_pos, 2), 2);
		}
		move_pos += 1;
	}
}

event_inherited();
