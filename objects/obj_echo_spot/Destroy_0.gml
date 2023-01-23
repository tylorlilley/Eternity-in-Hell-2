with (obj_echo) { instance_destroy(id, false); }
with (obj_cross) {
	var item_type = get_random_item_type(true, true);
	with (instance_create(x, y, item_type)) { make_item_special(); } 
}