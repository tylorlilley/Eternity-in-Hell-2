with (obj_echo) { instance_destroy(id, false); }
with (obj_cross) {
	var item_type = noone;
	while (item_type == noone) {
		item_type = get_random_item_type(true);
		if (array_count_occurances(global.controller.spawned_special_items, item_type) >= 1) { item_type = noone; }
	}
	with (instance_create(x, y, item_type)) { make_item_special(); } 
}