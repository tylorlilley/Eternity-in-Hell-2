if (process_this_frame()) {
	image_blend = get_image_blend(1);
	if  (!persistent && is_outside_room(x, y)) { 
	    instance_destroy(); 
	}
}
