event_inherited();

// Destroy self if completely covered by solids
if (carried == noone) {
	var solid_at_quadrant = get_presence_at_each_quadrant(obj_solid);
	if (solid_at_quadrant[0] && solid_at_quadrant[1] && solid_at_quadrant[2] && solid_at_quadrant[3]) {
		instance_destroy();
		play_sound(snd_crunch, true);
		instance_create_depth(x, y, depth, obj_bones);
	}
}