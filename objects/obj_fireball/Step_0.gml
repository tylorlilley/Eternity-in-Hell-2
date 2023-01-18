if (process_this_frame()) {
	event_inherited();
	
	image_xscale = 1;
	image_angle = direction+270;
	if (instance_exists(torch)) { torch.image_xscale = 0.5; }
	
	// Destroy self and/or other when colliding with solid, enemy, or player
	var destroyed = false;
	if (place_meeting(x, y, obj_solid)) { destroyed = true; }
	if (place_meeting(x, y, global.player)) {
		var carried_staff = get_carried_item_of_type(obj_staff);
		if (carried_staff != noone) { destroyed = true; }
	}
	var enemies_at_position = instance_place_all(x, y, obj_enemy);
	while (array_length(enemies_at_position) > 0) {
		var enemy = array_random_pop(enemies_at_position);
		if (enemy.activated && enemy.corporeal) { destroyed = true; break; }
	}
	if (destroyed) { play_sound(snd_fuse, true); instance_destroy(); }
}