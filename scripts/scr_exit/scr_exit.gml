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
	has_door = false;
	has_lock = false;
	has_portcullis = false;
	room_1_has_closed_portcullis = false;
	room_2_has_closed_portcullis = false;
	has_illusion_walls = 0;
	destroyed = false;
	visited = false;
	
	/// @function								set_portcullis_to_trigger_for_room(given_room, given_value);
	///	@param		{GameRoom} given_room		The connected game room to set the closed portcullis value for
	///	@param		{bool} given_value			The value to set to
	function set_portcullis_to_trigger_for_room(given_room, given_value) {
		if (given_room == room_1) { room_1_has_closed_portcullis = given_value; }
		else if (given_room == room_2) { room_2_has_closed_portcullis = given_value; }
	}
	
	/// @function								has_closed_portcullis_for_room(given_room);
	///	@param		{GameRoom} given_room		The connected game room to check the closed portcullis value for
	function has_closed_portcullis_for_room(given_room) {
		if (given_room == room_1) { return room_1_has_closed_portcullis; }
		else if (given_room == room_2) { return room_2_has_closed_portcullis; }
		
		return false;
	}
	
	/// @function								open_portcullis();
	function open_portcullis() {
		has_portcullis = true;
		room_1_has_closed_portcullis = false;
		room_2_has_closed_portcullis = false;
	}
	
	/// @function								close_portcullis();
	function close_portcullis() {
		has_portcullis = true;
		room_1_has_closed_portcullis = true;
		room_2_has_closed_portcullis = true;
	}
	
	/// @function								add_stairs_for_room(given_room, stairs);
	///	@param		{GameRoom} given_room		The connected game room to set the stairs value for
	///	@param		{id} stairs					The instance id of the stairs object to add
	function add_stairs_for_room(given_room, stairs) {
		if (given_room == room_1 && room_1_stairs == noone) { room_1_stairs = stairs; }
		else if (given_room == room_2 && room_2_stairs == noone) { room_2_stairs = stairs; }
	}
	
	/// @function								get_connected_stairs(given_stairs);
	///	@param		{id} given_stairs			The instance id of the stairs object to get the connected stairs for
	function get_connected_stairs(given_stairs) {
		if (given_stairs == room_1_stairs) { return room_2_stairs; }
		else if (given_stairs == room_2_stairs) { return room_1_stairs; }
		
		return noone;
	}
	
	/// @function								get_connected_room(given_room);
	///	@param		{GameRoom} given_room		The game room to set the connected game room for
	function get_connected_room(given_room) {
		if (given_room == room_1) { return room_2; }
		else if (given_room == room_2) { return room_1; }
		
		return -1;
	}
	
	/// @function								lock();
	function lock() {
		if (has_lock) { return false; }
		
		has_lock = true;
		has_door = true;
		has_illusion_walls = 0;
		return true;
	}
	
	/// @function								destroy();
	function destroy() { 
		destroyed = true; 
		has_lock = false;
	}
	
	/// @function								unlock();
	function unlock() { has_lock = false; }
}
