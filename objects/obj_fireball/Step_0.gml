if (process_this_frame()) {
	event_inherited();
	
	image_xscale = 1;
	image_angle = direction+270;
	if (instance_exists(torch)) { torch.image_xscale = 0.5; }
	if (instance_place(x, y, obj_solid)) { play_sound(snd_thud, false); instance_destroy(); }
	var enemy = instance_place(x, y, obj_enemy);
	with enemy { if (consumed_by_lava && visible) { play_sound(snd_extinguish, true); kill_enemy(); } }
}