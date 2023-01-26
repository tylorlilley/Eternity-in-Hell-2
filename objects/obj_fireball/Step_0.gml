if (can_process_this_frame()) {
	event_inherited();
	
	image_xscale = 1;
	image_angle = direction+270;
	if (is_existing_instance(torch)) { torch.image_xscale = 0.5; }
}