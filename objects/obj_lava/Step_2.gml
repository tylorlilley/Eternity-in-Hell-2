if (process_this_frame()) {
	if (!death_box && !death_boxes[0] && !death_boxes[1] && !death_boxes[2] && !death_boxes[3]) { 
		instance_destroy(); 
	}
}