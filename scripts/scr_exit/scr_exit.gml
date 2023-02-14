/// @function								new RoomExit(room, dir);
/// @param		{real}	given_room			The room to create an exit for
/// @param		{dir}	dir					The cardinal direction of the adjoining room to link via this exit
function RoomExit(current_room, linked_room, linked_room_dir) constructor {
	// Linked Rooms Info
	room_1 = current_room;
	room_2 = linked_room;
	room_1_dir = get_opposite_dir(linked_room_dir);
	room_2_dir = linked_room_dir;
	
	// Lock Type
	has_door = false;
	has_lock = false;
	has_portcullis = false;
	has_illusion_walls = get_random_chance_out_of(ILLUSION_WALL_PROBABILITY);
	destroyed = false;
	
	function get_room_in_direction(dir) {
		if (dir == room_1_dir) { return room_1; }
		else if (dir == room_2_dir) { return room_2; }
		
		return -1;
	}
	
	function lock() {
		if (has_lock) { return 0; }
		
		has_lock = true;
		has_door = true;
		has_illusion_walls = false;
		return 1;
	}
	
	function destroy() { destroyed = true; }
	
	function unlock() { has_lock = false; }
}
