with (obj_echo) { instance_destroy(id, false); }
with (obj_cross) { with (instance_create_depth(x, y, 0, get_random_item_type())) { make_item_special(); } }