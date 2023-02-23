with (obj_echo) { 
	instance_destroy();
	if (global.player.dead) { play_sound(snd_impact, false); }
}
if (is_existing_instance(global.player) && !global.player.dead) {
	with (obj_cross) {
		var controller = global.controller;
		var item_obj = get_random_item_obj(true, true);
		array_push(controller.spawned_special_items, item_obj);
		with (instance_create(x, y, item_obj)) { make_item_special(); }
		screen_flash();
	}
}