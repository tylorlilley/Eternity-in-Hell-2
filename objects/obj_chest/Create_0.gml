event_inherited();
var controller = global.controller;

closed = true;
contents_obj = controller.current_room.chest_obj;

while (contents_obj == -1) {
	var array_to_check = (controller.current_room.has_special_item) ? controller.spawned_special_items : controller.spawned_items;
	contents_obj = array_random_pop(array_to_check);
	if (contents_obj == obj_key) { contents_obj = -1; }
}
