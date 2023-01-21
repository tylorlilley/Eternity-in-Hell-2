event_inherited();

// Destroy self if completely covered by solids
if (holder == noone) {
	if (is_covered_at_each_quadrant_by(obj_solid)) {
		instance_destroy();
		play_sound(snd_crunch, true);
		instance_create_depth(x, y, 0, obj_bones);
	}
}