/// @description End Step
if (can_process_this_frame()) {
	// Set lighting variables
	image_blend = get_image_blend();
	
	if  (!persistent && is_outside_room(x, y)) { 
	    instance_destroy(); 
	}
}
