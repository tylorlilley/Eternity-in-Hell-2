/// @function								obj_room_create_room_lists();
function obj_room_create_room_lists() {
	exit_only_one_rooms = ds_list_create(); 
	ds_list_add(exit_only_one_rooms, rm_up_only_1, rm_up_only_2, rm_up_only_3, rm_up_only_4, rm_up_only_5, rm_up_only_6, rm_right_only_1, rm_right_only_2, rm_right_only_3, rm_right_only_4, rm_right_only_5, rm_right_only_6);
	exit_angled_rooms = ds_list_create();
	ds_list_add(exit_angled_rooms, rm_angled_1, rm_angled_2, rm_angled_3, rm_angled_4, rm_angled_5, rm_angled_6, rm_angled_7, rm_angled_8, rm_angled_9, rm_angled_10, rm_angled_11, rm_angled_12);
	exit_only_two_rooms = ds_list_create(); 
	ds_list_add(exit_only_two_rooms, rm_up_and_down_1, rm_up_and_down_2, rm_up_and_down_3, rm_up_and_down_4, rm_up_and_down_5, rm_up_and_down_6, rm_right_and_left_1, rm_right_and_left_2, rm_right_and_left_3, rm_right_and_left_4, rm_right_and_left_5, rm_right_and_left_6);
	exit_only_three_rooms = ds_list_create(); 
	ds_list_add(exit_only_three_rooms, rm_not_up_1, rm_not_up_2, rm_not_up_3, rm_not_up_4, rm_not_up_5, rm_not_up_6, rm_not_left_1, rm_not_left_2, rm_not_left_3, rm_not_left_4, rm_not_left_5, rm_not_left_6);
	exit_all_rooms = ds_list_create(); 
	ds_list_add(exit_all_rooms, rm_all_8, rm_all_1, rm_all_2, rm_all_3, rm_all_4, rm_all_5, rm_all_6, rm_all_7, rm_all_9, rm_all_10, rm_all_11, rm_all_12);
}

/// @function								obj_room_assign_room();
function obj_room_assign_room() {
	var number_of_exits = obj_room_count_exits()
	var rand1 = (irandom(1) == 0);
	var rand2 = (irandom(1) == 0);

	switch (number_of_exits) {
	    case 1:
			flip_horizontal = rand1;
			flip_vertical = false;
			for (var i = 0; i < 4; i+= 1) {
				if (exits[i]) { rotate = i; return obj_room_duplicate_room_from_list(exit_only_one_rooms); }
			}
		case 2:
	        if (exits[0] && exits[2]) { flip_horizontal = rand1; flip_vertical = rand2; return obj_room_duplicate_room_from_list(exit_only_two_rooms); }
	        else if (exits[1] && exits[3]) { flip_horizontal = rand1; flip_vertical = rand2; rotate = (irandom(1) == 0) ? 1 : 3; return obj_room_duplicate_room_from_list(exit_only_two_rooms); }
	        else if (exits[0] && exits[1]) { flip_horizontal = false; flip_vertical = false; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	        else if (exits[0] && exits[3]) { flip_horizontal = true; flip_vertical = false; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	        else if (exits[1] && exits[2]) { flip_horizontal = false; flip_vertical = true; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	        else {  flip_horizontal = true; flip_vertical = true; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	    case 3:
			flip_horizontal = false;
			flip_vertical = rand1;
			for (var i = 0; i < 4; i+= 1) {
				if (!exits[i]) { rotate = (i+1 > 4) ? 0 : i+1; return obj_room_duplicate_room_from_list(exit_only_three_rooms); }
			}
	    case 4:
	        flip_horizontal = rand1; 
	        flip_vertical = rand2;
			rotate = irandom(3);
	        return obj_room_duplicate_room_from_list(exit_all_rooms);
	}
}

/// @function								obj_room_duplicate_room_from_list(list);
/// @param		{index} list				List of rooms to duplicate one of at random
function obj_room_duplicate_room_from_list(list) {
	ds_list_shuffle(list);
	var chosen_room = ds_list_find_value(list, 0);
	room_set_background_color(chosen_room, make_color_rgb(20, 20, 20), true);
	var new_room = room_duplicate(chosen_room);
	room_set_persistent(new_room, true);
	
	return room_duplicate(new_room);
}

/// @function								obj_room_destroy_room_lists();
function obj_room_destroy_room_lists() {
	ds_list_destroy(exit_only_one_rooms);
	ds_list_destroy(exit_only_two_rooms);
	ds_list_destroy(exit_only_three_rooms);
	ds_list_destroy(exit_angled_rooms);
	ds_list_destroy(exit_all_rooms);
}
