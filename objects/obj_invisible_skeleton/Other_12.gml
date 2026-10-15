/// @description End Step
event_inherited();

/// Invert Lighting Effects
if (can_process_this_frame() && !get_random_chance_out_of(INVISIBLE_SKELETON_FLASH_FREQUENCY)) {
	// Set inverted lighting variables, so it shows up in darkness but not light
	image_blend = merge_color(global.bg_color, c_white, 1-get_greatest_lighting());
}
