if (process_this_frame()) {
	calculate_lighting(1);
	if  (!persistent && position_is_outside_room(x, y)) { 
	    instance_destroy(); 
	}
}
