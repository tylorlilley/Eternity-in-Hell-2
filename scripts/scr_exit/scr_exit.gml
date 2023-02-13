/// @function								new RoomExit(room, dir);
/// @param		{real}	given_room			The room to create an exit for
/// @param		{dir}	dir					The cardinal direction of the adjoining room to link via this exit
function RoomExit(given_room, dir) constructor {
	has_door = false;
	illusion_walls = false;
	locked = false;	
	destroyed = false;
	room_1 = given_room;
	room_1_dir = dir;
	room_2 = given_room.adj_rooms[dir];
	room_2_dir = get_opposite_dir(dir);
	id = get_new_id();
	
	function destroy() { destroyed = true; }
	function unlock() { locked = false; }
	function remove() {
		room_1.exits[room_1_dir] = noone;
		room_2.exits[room_2_dir] = noone;
	}
	function get_room_in_direction(dir) {
		if (dir == room_1_dir) { return room_1; }
		else if (dir == room_2_dir) { return room_2; }
		
		return noone;
	}
}