/// @description Step
event_inherited();

// Meat that nobody holds is crushed, leaving bones, when solids cover all four of its quadrants
if (!is_existing_instance(holder)) {
	if (is_covered_at_each_quadrant_by(obj_solid)) {
		instance_destroy();
		play_sound(snd_crunch, true);
		instance_create(x, y, obj_bones);
	}
}