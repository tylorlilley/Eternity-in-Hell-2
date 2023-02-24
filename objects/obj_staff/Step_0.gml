event_inherited();

if (can_process_this_frame()) {
	if (is_existing_instance(other.holder)) {
		with (obj_lava_part) { flicker_sprite_under_instance(other.holder); }
		if (special) {
			with (obj_wall) { flicker_sprite_under_instance(other.holder); }
			with (obj_column) { flicker_sprite_under_instance(other.holder); }
		}
	}
}