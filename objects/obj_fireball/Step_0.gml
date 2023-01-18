if (process_this_frame()) {
	event_inherited();
	
	image_xscale = 1;
	image_angle = direction+270;
	if (instance_exists(torch)) { torch.image_xscale = 0.5; }
	
	// Destroy meat when collding with it
	//var dropped_meat = instance_place(x, y, obj_meat);
	//with dropped_meat { if (carried == noone) { play_sound(snd_extinguish, true); instance_destroy(); instance_create_depth(x, y, 5, obj_bones); } }
	
	// Destroy self when colliding with solid, enemy, or player with staff
	var enemy = instance_place(x, y, obj_enemy)
	if (instance_place(x, y, obj_solid) != noone) { play_sound(snd_fuse, false); instance_destroy(); }
	else if (enemy != noone && enemy.activated) { play_sound(snd_fuse, true); instance_destroy(); }
	else if (instance_place(x, y, global.player)) {
		var carried_staff = get_carried_item_of_type(obj_staff);
		if (carried_staff != noone) { play_sound(snd_fuse, true); instance_destroy(); }
	}
}