if (can_process_this_frame()) {
	with (obj_lava_part) { lava_visible = true; }
	if (special) {
		with (obj_wall) { visible = true; }
		with (obj_column) { visible = true; }
	}
}