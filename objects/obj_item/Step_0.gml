event_inherited();

if (can_process_this_frame()) {
	if (holder == noone && is_covered_at_each_quadrant_by(obj_lava)) {
		instance_destroy();
		play_sound(snd_extinguish, true);
	}
}