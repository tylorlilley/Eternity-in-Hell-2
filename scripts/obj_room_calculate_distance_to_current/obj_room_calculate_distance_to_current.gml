/// @description  obj_room_calculate_distance_to_current(distance)
function obj_room_calculate_distance_to_current(argument0) {
	var distance = argument0;

	if (distance < distance_to_current_room) { distance_to_current_room = distance; }
	for (var i = 0; i < 4; i++) {
	    if (adj_rooms[i]) {
	        if (distance+1 < adj_rooms[i].distance_to_current_room) with adj_rooms[i] { obj_room_calculate_distance_to_current(distance+1); }
	    }
	}



}
