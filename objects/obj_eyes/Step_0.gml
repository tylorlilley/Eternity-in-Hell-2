if (process_this_frame()) {
	if (global.controller.key_up_pressed || global.controller.key_down_pressed || global.controller.key_right_pressed || global.controller.key_left_pressed) {
	    teleport_near_player();
	}

	// Make sprite infrequently switch to another image
	//image_index = (get_random_chance_out_of(16));
	turn_to_face_player();

	event_inherited();
}

