if (can_process_this_frame()) {
	var controller = global.controller;
	if (controller.key_up_pressed || 
		controller.key_down_pressed || 
		controller.key_right_pressed || 
		controller.key_left_pressed) {
	    teleport_near_player();
	}

	turn_to_face_player();

	event_inherited();
}

