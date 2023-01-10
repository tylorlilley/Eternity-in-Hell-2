if (process_this_frame()) {
	event_inherited();
	
	image_xscale = 1;
	image_angle = direction+270;
	if (instance_exists(torch)) { torch.image_xscale = 0.5; }
	if (instance_place(x, y, obj_solid)) { play_sound(snd_fuse, false); instance_destroy(); }
	
	// Destroy self and enemy when colliding with enemy
	var enemy = instance_place(x, y, obj_enemy);
	with enemy { if (consumed_by_fireball && visible) { play_sound(snd_extinguish, true); kill_enemy(); } }
	
	// Destroy meat when collding with it
	var dropped_meat = instance_place(x, y, obj_meat);
	with dropped_meat { if (carried == noone) { play_sound(snd_extinguish, true); instance_destroy(); instance_create_depth(x, y, 5, obj_bones); } }
	
	// Destroy self when colliding with player with amulet
	if (instance_place(x, y, global.player)) {
		var carried_amulet = get_carried_item_of_type(obj_amulet);
		if (carried_amulet != noone) { play_sound(snd_fuse, true); instance_destroy(); }
	}
}