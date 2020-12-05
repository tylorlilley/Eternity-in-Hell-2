/// @description  obj_room_duplicate_room_from_list(list)
function obj_room_duplicate_room_from_list(argument0) {
	var list = argument0;

	ds_list_shuffle(list);
	var chosen_room = ds_list_find_value(list, 0);
	room_set_background_color(chosen_room, make_color_rgb(20, 20, 20), true);
	var new_room = room_duplicate(chosen_room);
	room_set_persistent(chosen_room, true);
	return room_duplicate(chosen_room);



}
