/// @description End Step
if (can_process_this_frame()) {
	// Shade the sprite by how brightly lit its spot is
	image_blend = get_image_blend();
	
	// Destroy anything that ends up outside the room, unless it's persistent
	if  (!persistent && is_outside_room(x, y)) { 
	    instance_destroy(); 
	}
}
