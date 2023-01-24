with (obj_echo) { instance_destroy(id, false); }
with (obj_cross) {
	var item_type = get_random_item_type(true, true);
	array_push(global.controller.spawned_special_items, item_type);
	with (instance_create(x, y, item_type)) { make_item_special(); } 
}