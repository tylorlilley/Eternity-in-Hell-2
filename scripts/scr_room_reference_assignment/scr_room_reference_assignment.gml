/// @function								create_room_lists();
function create_room_lists() {
	global.rooms_with_one_exit = ds_list_create(); 
	ds_list_add(global.rooms_with_one_exit, rm_one_exit_1, rm_one_exit_2, rm_one_exit_3, rm_one_exit_4, rm_one_exit_5, rm_one_exit_6, rm_one_exit_7, rm_one_exit_8, rm_one_exit_9, rm_one_exit_10, rm_one_exit_11, rm_one_exit_12, rm_one_exit_13);
	global.rooms_with_two_opposite_exits = ds_list_create();
	ds_list_add(global.rooms_with_two_opposite_exits, rm_two_opposite_exits_1, rm_two_opposite_exits_2, rm_two_opposite_exits_3, rm_two_opposite_exits_4, rm_two_opposite_exits_5, rm_two_opposite_exits_6, rm_two_opposite_exits_7, rm_two_opposite_exits_8, rm_two_opposite_exits_9, rm_two_opposite_exits_10, rm_two_opposite_exits_11, rm_two_opposite_exits_12, rm_two_opposite_exits_13, rm_two_opposite_exits_14);
	global.rooms_with_two_perpendicular_exits = ds_list_create(); 
	ds_list_add(global.rooms_with_two_perpendicular_exits, rm_two_perpendicular_exits_1, rm_two_perpendicular_exits_2, rm_two_perpendicular_exits_3, rm_two_perpendicular_exits_4, rm_two_perpendicular_exits_5, rm_two_perpendicular_exits_6, rm_two_perpendicular_exits_7, rm_two_perpendicular_exits_8, rm_two_perpendicular_exits_9, rm_two_perpendicular_exits_10, rm_two_perpendicular_exits_11, rm_two_perpendicular_exits_12, rm_two_perpendicular_exits_13);
	global.rooms_with_three_exits = ds_list_create(); 
	ds_list_add(global.rooms_with_three_exits, rm_three_exits_1, rm_three_exits_2, rm_three_exits_3, rm_three_exits_4, rm_three_exits_5, rm_three_exits_6, rm_three_exits_7, rm_three_exits_8, rm_three_exits_9, rm_three_exits_10, rm_three_exits_11, rm_three_exits_12, rm_three_exits_13);
	global.rooms_with_four_exits = ds_list_create(); 
	ds_list_add(global.rooms_with_four_exits, rm_four_exits_1, rm_four_exits_2, rm_four_exits_3, rm_four_exits_4, rm_four_exits_5, rm_four_exits_6, rm_four_exits_7, rm_four_exits_8, rm_four_exits_9, rm_four_exits_10, rm_four_exits_11, rm_four_exits_12, rm_four_exits_13);
}

/// @function								get_room_from_room_lists();
function get_room_from_room_lists() {
	var number_of_exits = count_exits()
	var rand1 = get_random_chance_out_of(2);
	var rand2 = get_random_chance_out_of(2);
	var room_list = noone;

	switch (number_of_exits) {
	    case 1:
			room_list = global.rooms_with_one_exit;
			flip_horizontal = rand1;
			flip_vertical = false;
			for (var i = 0; i < 4; i+= 1) {
				if (exits[i]) { rotate = i; break; }
			}
			break;
		case 2:
			room_list = global.rooms_with_two_perpendicular_exits; 
	        if (exits[0] && exits[2]) { flip_horizontal = rand1; flip_vertical = rand2; room_list = global.rooms_with_two_opposite_exits; }
	        else if (exits[1] && exits[3]) { flip_horizontal = rand1; flip_vertical = rand2; rotate = (get_random_chance_out_of(2)) ? 1 : 3; room_list = global.rooms_with_two_opposite_exits; }
	        else if (exits[0] && exits[1]) { flip_horizontal = false; flip_vertical = false; }
	        else if (exits[0] && exits[3]) { flip_horizontal = true; flip_vertical = false; }
	        else if (exits[1] && exits[2]) { flip_horizontal = false; flip_vertical = true; }
	        else {  flip_horizontal = true; flip_vertical = true; }
			break;
	    case 3:
			room_list = global.rooms_with_three_exits; 
			flip_horizontal = false;
			flip_vertical = rand1;
			for (var i = 0; i < 4; i+= 1) {
				if (!exits[i]) { rotate = (i+1 > 4) ? 0 : i+1; break; }
			}
			break;
	    case 4:
			room_list = global.rooms_with_four_exits; 
	        flip_horizontal = rand1; 
	        flip_vertical = rand2;
			rotate = irandom(3);
			break;
	}
	
	return duplicate_room_from_list(room_list);
}

/// @function								duplicate_room_from_list(list);
/// @param		{index} list				List of rooms to duplicate one of at random
function duplicate_room_from_list(list) {
	ds_list_shuffle(list);
	var chosen_room = ds_list_find_value(list, 0);
	var new_room = room_duplicate(chosen_room);
	room_set_persistent(new_room, true);
	
	return room_duplicate(new_room);
}

/// @function								destroy_room_lists();
function destroy_room_lists() {
	ds_list_destroy(global.rooms_with_one_exit);
	ds_list_destroy(global.rooms_with_two_opposite_exits);
	ds_list_destroy(global.rooms_with_three_exits);
	ds_list_destroy(global.rooms_with_two_perpendicular_exits);
	ds_list_destroy(global.rooms_with_four_exits);
}
