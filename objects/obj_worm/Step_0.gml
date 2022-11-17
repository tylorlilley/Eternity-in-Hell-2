if (process_this_frame()) {
	move_snake(get_random_chance_out_of(4) ? 2 : 1);
	if (get_random_chance_out_of(32)) { play_sound(snd_hiss, false); }
	
	event_inherited();
}
