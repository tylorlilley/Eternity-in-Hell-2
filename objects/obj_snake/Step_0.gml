if (can_process_this_frame()) {
	var move_speed = get_random_chance_out_of(SNAKE_MOVE_FREQUENCY) ? 2 : 1;
	
	move_snake(move_speed);
	
	if (get_random_chance_out_of(SNAKE_HISS_FREQUENCY)) { play_sound(snd_hiss, false); }
	
	event_inherited();
}
