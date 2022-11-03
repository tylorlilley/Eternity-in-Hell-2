if (process_this_frame()) {
	move_snake(2);
	if (get_random_chance_out_of(16)) { play_sound(snd_hiss, true); }
	
	event_inherited();
}
