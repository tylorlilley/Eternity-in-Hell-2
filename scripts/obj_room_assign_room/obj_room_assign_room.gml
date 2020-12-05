/// @description  obj_room_assign_room
function obj_room_assign_room() {

	var number_of_exits = obj_room_count_exits()
	var rand1 = (irandom(1) == 0);
	var rand2 = (irandom(1) == 0);

	switch (number_of_exits) {
	    case 1:
	        if (exits[0]) { flip_horizontal = rand1; flip_vertical = false; return obj_room_duplicate_room_from_list(exit_only_up_rooms); }
	        else if (exits[1]) { flip_horizontal = false; flip_vertical = rand1; return obj_room_duplicate_room_from_list(exit_only_right_rooms); }
	        else if (exits[2]) { flip_horizontal = rand1; flip_vertical = true; return obj_room_duplicate_room_from_list(exit_only_up_rooms); }
	        else { flip_horizontal = true; flip_vertical = rand1; return obj_room_duplicate_room_from_list(exit_only_right_rooms); }
	    case 2:
	        if (exits[0] && exits[1]) { flip_horizontal = false; flip_vertical = false; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	        else if (exits[0] && exits[2]) { flip_horizontal = rand1; flip_vertical = rand2; return obj_room_duplicate_room_from_list(exit_up_and_down_rooms); }
	        else if (exits[0] && exits[3]) {  flip_horizontal = true; flip_vertical = false; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	        else if (exits[1] && exits[2]) {  flip_horizontal = false; flip_vertical = true; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	        else if (exits[1] && exits[3]) {  flip_horizontal = rand1; flip_vertical = rand2; return obj_room_duplicate_room_from_list(exit_right_and_left_rooms); }
	        else {  flip_horizontal = true; flip_vertical = true; return obj_room_duplicate_room_from_list(exit_angled_rooms); }
	    case 3:
	        if (!exits[0]) { flip_horizontal = rand1; flip_vertical = false; return obj_room_duplicate_room_from_list(exit_not_up_rooms); }
	        else if (!exits[1]) { flip_horizontal = true; flip_vertical = rand1; return obj_room_duplicate_room_from_list(exit_not_left_rooms); }
	        else if (!exits[2]) {  flip_horizontal = rand1; flip_vertical = true; return obj_room_duplicate_room_from_list(exit_not_up_rooms); }
	        else { flip_horizontal = false; flip_vertical = rand1; return obj_room_duplicate_room_from_list(exit_not_left_rooms); }
	    case 4:
	        flip_horizontal = rand1; 
	        flip_vertical = rand2;
	        return obj_room_duplicate_room_from_list(exit_all_rooms);
	}



}
