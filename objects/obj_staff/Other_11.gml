/// @description Step
event_inherited();

if (is_existing_instance(holder)) {
	with (obj_lava_part) { flicker_sprite_under_instance(other.holder); }
	if (special) {
		with (obj_solid_part) { flicker_sprite_under_instance(other.holder); }
	}
}