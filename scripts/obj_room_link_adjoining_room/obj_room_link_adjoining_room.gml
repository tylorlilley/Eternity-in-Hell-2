/// @description  obj_room_link_adjoining_room(adjoining_room, dir)
function obj_room_link_adjoining_room(argument0, argument1) {
	var adjoining_room = argument0, dir = argument1;

	adj_rooms[dir] = adjoining_room;
	exits[dir] = true;
	with adjoining_room {
	    adj_rooms[opposite_dir(dir)] = other;
	    exits[opposite_dir(dir)] = true;
	}



}
