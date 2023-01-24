event_inherited();

closed = true;
contents = global.controller.current_room.item_type;
special = global.controller.current_room.has_special_item;

if (contents == noone) {
	var array_to_check = (special) ? global.controller.spawned_special_items : global.controller.spawned_items;
	contents = array_random_pop(array_to_check);
}
