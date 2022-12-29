if (process_this_frame()) {
	if ((instance_number(object_index) > 0) && instance_find(object_index, 0).id != id) { instance_destroy(); }
	initialized = false;
	spawn_timer = 32;
	moves = array_create(0);
}