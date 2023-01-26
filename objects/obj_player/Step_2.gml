if (can_process_this_frame()) {
	if (!is_existing_instance(moved_by)) {
		with (obj_echo_spot) { 
			if (array_length(moves) > 0) { array_push(moves, directions.none); } 
		}
	}
}