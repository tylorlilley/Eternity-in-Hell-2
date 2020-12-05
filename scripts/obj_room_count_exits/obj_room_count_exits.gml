/// @description  obj_room_count_exits
function obj_room_count_exits() {

	var number_of_exits = 0;

	for (var i = 0; i < 4; i++) {
	    if (exits[i]) { number_of_exits += 1; }
	}

	return number_of_exits;



}
