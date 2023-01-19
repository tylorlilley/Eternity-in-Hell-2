if (process_this_frame()) {
	var move_speed = get_random_chance_out_of(global.controller.SNAKE_MOVE_FREQUENCY) ? 2 : 1;
	var dropped_meat = get_dropped_meat();
	if (dropped_meat && get_random_possible_direction(dropped_meat.x, dropped_meat.y, false, true) != noone) { 
		move_towards_coordinates(dropped_meat.x, dropped_meat.y, false, true);
		if (move_speed == 2) { move_towards_coordinates(dropped_meat.x, dropped_meat.y, false, true); }
	}
	else { move_snake(move_speed); }
	if (get_random_chance_out_of(global.controller.SNAKE_HISS_FREQUENCY)) { play_sound(snd_hiss, false); }
	
	event_inherited();
}
