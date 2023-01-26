if (can_process_this_frame()) {
	event_inherited();
	
	if (!is_existing_instance(holder) && is_covered_at_each_quadrant_by(obj_lava)) {
		instance_destroy();
		play_sound(snd_extinguish, true);
	}
}