if (can_process_this_frame()) {
	event_inherited();
	
	if (is_covered_at_each_quadrant_by(obj_solid)) {
		play_sound(snd_crunch, true);
		instance_destroy(); 
	}
}
