if (can_process_this_frame()) {
	if (global.controller.key_up_pressed || 
		global.controller.key_down_pressed || 
		global.controller.key_right_pressed || 
		global.controller.key_left_pressed) {
	    teleport_near_player();
	}

	turn_to_face_player();

	event_inherited();
}

