with (obj_echo) { 
	instance_destroy();
	if (global.player.dead) { play_sound(snd_stairs, false); }
}
with (obj_cross) {
	if (!global.controller.entered_from_stairs) {
		var item_obj = get_random_item_obj(true, true);
		array_push(global.controller.spawned_special_items, item_obj);
		with (instance_create(x, y, item_obj)) { make_item_special(); } 
	}
}