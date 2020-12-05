/// @description  obj_room_count_adjacent_rooms
function obj_room_count_adjacent_rooms() {

	var number_of_rooms = 0;

	for (var i = 0; i < 4; i++) {
	    if (obj_room_get_adjacent(i)) { number_of_rooms += 1; }
	}
	return number_of_rooms;



}
