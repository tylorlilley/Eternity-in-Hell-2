/// @function RoomExit(_current_room, _linked_room)
/// @description A link between two rooms of the map, through a side or by stairs, and whatever stands in it: a lock, a
///	door, illusion walls, or a portcullis that closes on one room's side. Generation decorates it, and play opens,
///	closes and destroys what stands in it.
/// @param {GameRoom} _current_room One of the rooms it links
/// @param {GameRoom} _linked_room The other room it links
function RoomExit(_current_room, _linked_room) constructor {
	// The rooms it links, and each room's stairs instance once that room is built, for an exit by stairs
	room_1 = _current_room;
	room_2 = _linked_room;
	room_1_stairs = noone;
	room_2_stairs = noone;

	// What stands in it
	has_door = false;
	has_lock = false;
	has_portcullis = false;							// Whether it has a portcullis in play, once a trap room's portcullis has closed or opened
	room_1_has_closed_portcullis = false;			// Whether the portcullis on room_1's side is closed, trapping the player in room_1
	room_2_has_closed_portcullis = false;			// Whether the portcullis on room_2's side is closed, trapping the player in room_2
	has_illusion_walls = 0;							// 0 for none, 1 for illusion walls, and 2 once the player has come through them
	destroyed = false;								// Whether its door was destroyed during play
	visited = false;								// Whether the player has gone through it, for the map

	/// @function set_portcullis_to_trigger_for_room(_given_room, _given_value)
	/// @description Sets whether the portcullis on one room's side of the exit is closed, which traps the player in that
	///	room until they press its button
	/// @param {GameRoom} _given_room The room whose side to set
	/// @param {bool} _given_value Whether that side's portcullis is closed
	function set_portcullis_to_trigger_for_room(_given_room, _given_value) {
		if (_given_room == room_1) { room_1_has_closed_portcullis = _given_value; }
		else if (_given_room == room_2) { room_2_has_closed_portcullis = _given_value; }
	}

	/// @function has_closed_portcullis_for_room(_given_room)
	/// @description Whether the portcullis on one room's side of the exit is closed
	/// @param {GameRoom} _given_room The room whose side to check
	/// @returns {bool} False for a room the exit doesn't link
	function has_closed_portcullis_for_room(_given_room) {
		if (_given_room == room_1) { return room_1_has_closed_portcullis; }
		else if (_given_room == room_2) { return room_2_has_closed_portcullis; }

		return false;
	}

	/// @function open_portcullis()
	/// @description Opens the portcullis on both sides of the exit, once the player presses the trap room's button
	function open_portcullis() {
		has_portcullis = true;
		room_1_has_closed_portcullis = false;
		room_2_has_closed_portcullis = false;
	}

	/// @function close_portcullis()
	/// @description Closes the portcullis on both sides of the exit
	function close_portcullis() {
		has_portcullis = true;
		room_1_has_closed_portcullis = true;
		room_2_has_closed_portcullis = true;
	}

	/// @function add_stairs_for_room(_given_room, _stairs)
	/// @description Remembers the stairs instance on one room's side of the exit, the first time that room is built
	/// @param {GameRoom} _given_room The room the stairs are in
	/// @param {Id.Instance} _stairs The stairs instance
	function add_stairs_for_room(_given_room, _stairs) {
		if (_given_room == room_1 && room_1_stairs == noone) { room_1_stairs = _stairs; }
		else if (_given_room == room_2 && room_2_stairs == noone) { room_2_stairs = _stairs; }
	}

	/// @function get_connected_stairs(_given_stairs)
	/// @description The stairs instance on the other side of the exit from a given one
	/// @param {Id.Instance} _given_stairs The stairs instance on one side
	/// @returns {Id.Instance} The stairs on the other side, or noone if the given stairs aren't this exit's
	function get_connected_stairs(_given_stairs) {
		if (_given_stairs == room_1_stairs) { return room_2_stairs; }
		else if (_given_stairs == room_2_stairs) { return room_1_stairs; }

		return noone;
	}

	/// @function get_connected_room(_given_room)
	/// @description The room on the other side of the exit from a given room
	/// @param {GameRoom} _given_room The room on one side
	/// @returns {GameRoom|real} The room on the other side, or -1 if the exit doesn't link the given room
	function get_connected_room(_given_room) {
		if (_given_room == room_1) { return room_2; }
		else if (_given_room == room_2) { return room_1; }

		return -1;
	}

	/// @function destroy()
	/// @description Marks the exit's door as destroyed during play, which takes its lock with it
	function destroy() {
		destroyed = true;
		has_lock = false;
	}

	/// @function unlock()
	/// @description Removes the exit's lock during play, once the player opens it with a key
	function unlock() { has_lock = false; }

	// Map generation (see GameMap)

	/// @function set_lock(_is_locked)
	/// @description Locks or unlocks the exit while the map is generated. A locked exit has a door, and plain doors are
	///	added after the locks, so unlocking removes the door too, unlike unlock().
	/// @param {bool} _is_locked Whether to lock it
	function set_lock(_is_locked) {
		has_lock = _is_locked;
		has_door = _is_locked;
	}

	/// @function can_be_locked()
	/// @description Whether generation can lock this exit: it isn't locked yet, and neither room it links is the start
	///	room or a hall of mirrors
	/// @returns {bool}
	static can_be_locked = function() {
		return !has_lock
			&& !room_1.is_start_room && !room_2.is_start_room
			&& !room_1.has_hall_of_mirrors && !room_2.has_hall_of_mirrors;
	};

	/// @function reset_decorations()
	/// @description Clears the exit's lock, door, illusion walls and portcullis, so each generation pass can decorate it
	///	again
	function reset_decorations() {
		has_lock = false;
		has_door = false;
		has_illusion_walls = 0;
		has_portcullis = false;
		room_1_has_closed_portcullis = false;
		room_2_has_closed_portcullis = false;
	}
}