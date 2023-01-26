event_inherited();

closed = true;
contents_obj = global.controller.current_room.chest_obj;

while (contents_obj == noone) {
	var array_to_check = (global.controller.current_room.has_special_item) ? global.controller.spawned_special_items : global.controller.spawned_items;
	contents_obj = array_random_pop(array_to_check);
	if (contents_obj == obj_key) { contents_obj = noone; }
}
