// Update input variables
if (instance_number(obj_title) > 0 || number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) { 
	clear_inputs_for_next_frame(); 
	with (obj_player) { moved_by = noone; }
}

// Update frame count
number_of_frames_since_game_began += 1;
if (resize_timer > 0) {
	resize_timer -= 1;
	if (resize_timer == 0) {
		// Resize the drawing surface
		var window_scaling = global.window_scaling;
		var draw_surface_width = (room_width*window_scaling), draw_surface_height = (room_height*window_scaling)
		window_set_size(draw_surface_width, draw_surface_height);
	}
}
set_up_inputs_for_next_frame();
