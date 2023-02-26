/// @description Step
event_inherited();

// Destroy self if completely covered by solids
if (!is_existing_instance(holder)) {
	if (is_covered_at_each_quadrant_by(obj_solid)) {
		instance_destroy();
		play_sound(snd_crunch, true);
		instance_create(x, y, obj_bones);
	}
}