if (process_this_frame()) {
	var move_speed = get_random_chance_out_of(4) ? 2 : 1;
	var dropped_meat = noone;
	with (obj_meat) { if (carried == noone) { dropped_meat = self; } }
	if (dropped_meat && get_random_possible_direction(dropped_meat.x, dropped_meat.y, false, true) != noone) { 
		move_towards_coordinates(dropped_meat.x, dropped_meat.y, false, true);
		if (move_speed == 2) { move_towards_coordinates(dropped_meat.x, dropped_meat.y, false, true); }
	}
	else { move_snake(move_speed); }
	if (get_random_chance_out_of(32)) { play_sound(snd_hiss, false); }
	
	event_inherited();
}
