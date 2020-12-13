if (process_this_frame()) {
	calculate_lighting(1);
	if  (!persistent && (x < 0 || x > room_width || y < 0 || y > room_height)) { 
	    instance_destroy(); 
	}
}
