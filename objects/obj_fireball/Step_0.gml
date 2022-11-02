if (process_this_frame()) {
	event_inherited();
	
	image_angle = direction+270;
	if (instance_place(x, y, obj_block)) { play_sound(snd_thud, false); instance_destroy(); }
}