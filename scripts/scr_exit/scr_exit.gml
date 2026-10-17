// The different kinds of exits this can represent, depending on which objects are spawned at the exit
enum exit_types {
	none,
	unlocked_doors,
	locked_doors,
	opened_portcullis,
	closed_portcullis,
	illusion_walls,
	count
}

/// @function RoomExit(_current_room, _linked_room)
/// @description A link between two rooms of the map, through a side or by stairs, and whatever type of exit it is:
///	a door, illusion wall, or a one-sided portcullis. Map generation sets its values, and they are modified during gameplay.
/// Additional exits are also created by the shovel during gameplay.
/// @param {GameRoom} _current_room One of the rooms it links
/// @param {GameRoom} _linked_room The other room it links
function RoomExit(_current_room, _linked_room) constructor {
	// ========================
	// Public Getter Functions - Called outside of the map generation scripts
	// ========================

	/// @function get_connected_room(_room)
	/// @description The room on the other side of the exit for a given room
	/// @param {GameRoom} _room The room on one side
	/// @returns {GameRoom|real} The room on the other side, or -1 if the exit doesn't link the given room
	static get_connected_room = function(_room) {
		if (_room == room_1) { return room_2; }
		else if (_room == room_2) { return room_1; }

		return -1;
	};

	// ========================
	// Map Generation Functions
	// ========================

	/// @function reset_exit_type()
	/// @description Resets the exit's type and related variables
	static reset_exit_type = function() {
		exit_type = exit_types.none;
		room_1_has_closed_portcullis = false;
		room_2_has_closed_portcullis = false;
	};

	/// @function can_be_locked()
	/// @description Whether generation can lock this exit: it has no exit type yet, and neither room it links is the start room or a hall of mirrors
	/// @returns {bool}
	static can_be_locked = function() {
		return exit_type == exit_types.none
			&& !room_1.is_start_room && !room_2.is_start_room
			&& !room_1.has_hall_of_mirrors && !room_2.has_hall_of_mirrors;
	};

	/// @function add_portcullis_for_room(_room)
	/// @description Adds a closed portcullis exit for the given trapped room
	/// @param {GameRoom} _room The trapped room whose side gets the closed portcullis
	/// @returns {bool} False if the exit already has a special exit type or doesn't link the room
	static add_portcullis_for_room = function(_room) {
		if (exit_type != exit_types.none) { return false; }
			
		var _portcullis_set = false;
		if (_room == room_1) { room_1_has_closed_portcullis = true; _portcullis_set = true; }
		else if (_room == room_2) { room_2_has_closed_portcullis = true;  _portcullis_set = true; }
		if (_portcullis_set) { exit_type = exit_types.closed_portcullis; }
		
		return _portcullis_set;
	};

	// ========================
	// Gameplay Functions
	// ========================

	/// @function get_door_type_for_room(_room)
	/// @description Returns what door object type, if any, this exit has in this room
	/// @param {GameRoom} _room The given room to check
	/// @returns {Asset.GMObject} The door object type, or noone
	static get_door_type_for_room = function(_room) {
		if (has_closed_portcullis_for_room(_room)) { return obj_portcullis; }
		else if (exit_type == exit_types.unlocked_doors || exit_type == exit_types.locked_doors) { return obj_door; }
		
		else return noone;
	};

	/// @function has_closed_portcullis_for_room(_room)
	/// @description Whether the portcullis on the given room's side of the exit will close
	/// @param {GameRoom} _room The room whose side to check
	/// @returns {bool} False for a room the exit doesn't link
	static has_closed_portcullis_for_room = function(_room) {
		if (exit_type != exit_types.closed_portcullis) { return false; }

		if (_room == room_1) { return room_1_has_closed_portcullis; }
		else if (_room == room_2) { return room_2_has_closed_portcullis; }

		return false;
	};

	/// @function open_portcullis()
	/// @description Opens the portcullis on both sides of the exit, if the portcullis is closed
	/// @returns {bool} False if the exit is not a closed portcullis
	static open_portcullis = function() {
		if (exit_type != exit_types.closed_portcullis) { return false; }
		
		exit_type = exit_types.opened_portcullis;
		is_portcullis_triggered = true;
		room_1_has_closed_portcullis = false;
		room_2_has_closed_portcullis = false;
		return true;
	};

	/// @function close_portcullis()
	/// @description Closes the portcullis on both sides of the exit
	/// @returns {bool} False if the exit is not a closed portcullis
	static close_portcullis = function() {
		if (exit_type != exit_types.closed_portcullis) { return false; }

		is_portcullis_triggered = true;
		room_1_has_closed_portcullis = true;
		room_2_has_closed_portcullis = true;
		return true;
	};

	/// @function add_stairs_for_room(_room, _stairs)
	/// @description Links the given stairs instance to the given room for this exit
	/// @param {GameRoom} _room The room the stairs are in
	/// @param {Id.Instance} _stairs The stairs instance
	static add_stairs_for_room = function(_room, _stairs) {
		if (_room == room_1 && room_1_stairs == noone) { room_1_stairs = _stairs; }
		else if (_room == room_2 && room_2_stairs == noone) { room_2_stairs = _stairs; }
	};

	/// @function get_connected_stairs(_stairs)
	/// @description The stairs instance on the other side of the exit from a given one
	/// @param {Id.Instance} _stairs The stairs instance on one side
	/// @returns {Id.Instance} The stairs on the other side, or noone if the given stairs aren't this exit's
	static get_connected_stairs = function(_stairs) {
		if (_stairs == room_1_stairs) { return room_2_stairs; }
		else if (_stairs == room_2_stairs) { return room_1_stairs; }

		return noone;
	};

	/// @function destroy_doors()
	/// @description Marks the exit's door as destroyed during play, which removes the exit type entirely
	static destroy_doors = function() {
		destroyed = true;
		exit_type = exit_types.none;
	};

	/// @function unlock()
	/// @description Removes the exit's lock during play, once the player opens it with a key
	static unlock = function() { exit_type = exit_types.unlocked_doors; };

	// ========================
	// Instance Variables
	// ========================

	// The rooms it links, and what kind of exit links these rooms
	room_1 = _current_room;
	room_2 = _linked_room;
	exit_type = exit_types.none;
	room_1_has_closed_portcullis = false;			// Whether the portcullis on room_1's side is closed, trapping the player in room_1
	room_2_has_closed_portcullis = false;			// Whether the portcullis on room_2's side is closed, trapping the player in room_2

	// How the exit has been interacted with, during play
	has_discovered_illusion_walls = false;			// Whether the player has moved through the illusion walls or not
	is_portcullis_triggered = false;				// Whether the exit has spawned a portcullis during play
	destroyed = false;								// Whether its door was destroyed during play
	visited = false;								// Whether the player has gone through this exit, for the map
	room_1_stairs = noone;							// The stairs instance linked to this exit in room_1
	room_2_stairs = noone;							// The stairs instance linked to this exit in room_2
}