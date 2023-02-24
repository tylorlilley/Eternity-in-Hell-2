/// @function								new RoomExit(room, dir);
/// @param		{real}	given_room			The room to create an exit for
/// @param		{dir}	dir					The cardinal direction of the connected room to link via this exit
function RoomExit(current_room, linked_room) constructor {
	// Linked Rooms Info
	room_1 = current_room;
	room_2 = linked_room;
	room_1_stairs = noone;
	room_2_stairs = noone;
	
	// Lock Type
	has_door =  get_random_chance_out_of(OPEN_DOOR_PROBABILITY);
	has_lock = false;
	room_1_has_portcullis = false;
	room_2_has_portcullis = false;
	has_illusion_walls = false;
	destroyed = false;
	visited = false;
	
	function set_portcullis_for_room(given_room, has_portcullis) {
		if (given_room == room_1) { room_1_has_portcullis = has_portcullis; }
		else if (given_room == room_2) { room_2_has_portcullis = has_portcullis; }
	}
	
	function has_portcullis_for_room(given_room) {
		if (given_room == room_1) { return room_1_has_portcullis; }
		else if (given_room == room_2) { return room_2_has_portcullis; }
		
		return false;
	}
	
	function add_stairs_for_room(given_room, stairs) {
		if (given_room == room_1 && room_1_stairs == noone) { room_1_stairs = stairs; }
		else if (given_room == room_2 && room_2_stairs == noone) { room_2_stairs = stairs; }
	}
	
	function get_connected_stairs(given_stairs) {
		if (given_stairs == room_1_stairs) { return room_2_stairs; }
		else if (given_stairs == room_2_stairs) { return room_1_stairs; }
		
		return noone;
	}
	
	function get_connected_room(given_room) {
		if (given_room == room_1) { return room_2; }
		else if (given_room == room_2) { return room_1; }
		
		return -1;
	}
	
	function lock() {
		if (has_lock) { return 0; }
		
		has_lock = true;
		has_door = true;
		has_illusion_walls = false;
		return 1;
	}
	
	function destroy() { 
		destroyed = true; 
		has_lock = false;
	}
	
	function unlock() { has_lock = false; }
}
