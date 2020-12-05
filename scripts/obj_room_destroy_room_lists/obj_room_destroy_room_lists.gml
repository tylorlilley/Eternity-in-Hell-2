/// @description  obj_room_destroy_room_lists
function obj_room_destroy_room_lists() {

	ds_list_destroy(exit_only_up_rooms);
	ds_list_destroy(exit_only_right_rooms);
	ds_list_destroy(exit_angled_rooms);
	ds_list_destroy(exit_up_and_down_rooms);
	ds_list_destroy(exit_right_and_left_rooms);
	ds_list_destroy(exit_not_up_rooms);
	ds_list_destroy(exit_not_left_rooms);
	ds_list_destroy(exit_all_rooms);



}
