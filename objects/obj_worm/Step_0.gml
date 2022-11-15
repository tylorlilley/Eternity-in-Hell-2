if (process_this_frame()) {
	move_snake(get_random_chance_out_of(4) ? 2 : 1);
	if (get_random_chance_out_of(16)) { play_sound(snd_hiss, true); }
	
	event_inherited();
}
