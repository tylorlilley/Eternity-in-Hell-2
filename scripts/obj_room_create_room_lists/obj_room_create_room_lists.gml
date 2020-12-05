/// @description  obj_room_create_room_lists
function obj_room_create_room_lists() {

	exit_only_up_rooms = ds_list_create(); 
	ds_list_add(exit_only_up_rooms, rm_up_only_1, rm_up_only_2, rm_up_only_3, rm_up_only_4, rm_up_only_5, rm_up_only_6);
	exit_only_right_rooms = ds_list_create(); 
	ds_list_add(exit_only_right_rooms, rm_right_only_1, rm_right_only_2, rm_right_only_3, rm_right_only_4, rm_right_only_5, rm_right_only_6);
	exit_angled_rooms = ds_list_create();
	ds_list_add(exit_angled_rooms, rm_angled_1, rm_angled_2, rm_angled_3, rm_angled_4, rm_angled_5, rm_angled_6, rm_angled_7, rm_angled_8, rm_angled_9, rm_angled_10, rm_angled_11, rm_angled_12);
	exit_up_and_down_rooms = ds_list_create(); 
	ds_list_add(exit_up_and_down_rooms, rm_up_and_down_1, rm_up_and_down_2, rm_up_and_down_3, rm_up_and_down_4, rm_up_and_down_5, rm_up_and_down_6);
	exit_right_and_left_rooms = ds_list_create(); 
	ds_list_add(exit_right_and_left_rooms, rm_right_and_left_1, rm_right_and_left_2, rm_right_and_left_3, rm_right_and_left_4, rm_right_and_left_5, rm_right_and_left_6);
	exit_not_up_rooms = ds_list_create(); 
	ds_list_add(exit_not_up_rooms, rm_not_up_1, rm_not_up_2, rm_not_up_3, rm_not_up_4, rm_not_up_5, rm_not_up_6);
	exit_not_left_rooms = ds_list_create(); 
	ds_list_add(exit_not_left_rooms, rm_not_left_1, rm_not_left_2, rm_not_left_3, rm_not_left_4, rm_not_left_5, rm_not_left_6);
	exit_all_rooms = ds_list_create(); 
	ds_list_add(exit_all_rooms, rm_all_8, rm_all_1, rm_all_2, rm_all_3, rm_all_4, rm_all_5, rm_all_6, rm_all_7, rm_all_9, rm_all_10, rm_all_11, rm_all_12);



}
