// Update input variables
if (instance_number(obj_title) > 0 || number_of_frames_since_game_began % FRAMES_TO_WAIT_BEFORE_PROCESSING == 0) { clear_inputs_for_next_frame(); }

// Update frame count
number_of_frames_since_game_began += 1;

set_up_inputs_for_next_frame();
