event_inherited();

if (process_this_frame()) {
	if (!carried && is_covered_at_each_quadrant_by(obj_lava) && (!is_carrying_item(obj_staff) || !is_instance_at_coordinates(x, y, global.player))) {
		instance_destroy();
		play_sound(snd_extinguish, true);
	}
}