if (process_this_frame()) {
	if (global.controller.key_up_pressed || global.controller.key_down_pressed || global.controller.key_right_pressed || global.controller.key_left_pressed) {
	    obj_eyes_teleport_near_player();
	}

	// Make sprite flicker and infrequently switch to another image
	visible = (global.controller.number_of_frames_since_game_began mod 12 == 0);
	image_index = (irandom(15) == 0);
	obj_game_object_turn_to_face_player();

	event_inherited();
}

