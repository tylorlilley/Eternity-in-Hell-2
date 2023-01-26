if (can_process_this_frame()) {
	if (!is_existing_instance(death_box) &&
		!is_existing_instance(death_boxes[0]) &&
		!is_existing_instance(death_boxes[1]) &&
		!is_existing_instance(death_boxes[2]) &&
		!is_existing_instance(death_boxes[3])) { 
			instance_destroy(); 
	}
}