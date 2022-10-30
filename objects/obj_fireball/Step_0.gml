if (process_this_frame()) {
	event_inherited();
	image_blend = c_red;
	if (instance_place(x, y, obj_block)) { instance_destroy(); audio_play_sound(snd_thud, 10, false); }
}