/// @function LockSearchArea(_reached_rooms, _unlocked_chests, _rooms)
/// @description One state of the lock search (see GameMap.get_failing_lock_and_key_search_area): the rooms the player
///	can reach, the chests that matter they've unlocked, and what they've found in those rooms
/// @param {real} _reached_rooms Bitmask of the rooms the area reaches, by mapgen_index
/// @param {real} _unlocked_chests Bitmask of the chests that matter unlocked in the area, by unlocked_chests_bitmask_index
/// @param {array} _rooms Every room of the map
function LockSearchArea(_reached_rooms, _unlocked_chests, _rooms) constructor {
	reached_rooms = _reached_rooms;
	unlocked_chests = _unlocked_chests;
	keys_reached = 0;
	bombs_reached = 0;							// Bombs standing in for keys
	other_locked_chests_reached = 0;			// Locked chests that don't matter to the search, which the player might still spend a key on
	reached_lit_room = false;
	reached_torch = false;
	reached_special_key = false;				// A special key is never used up, so it opens every lock

	/// @function initialize_area(_rooms)
	/// @description Counts what the player finds in the area's rooms: keys and bombs, a lit room, locked chests that don't
	///	matter, and a torch or special key in a chest they can open
	/// @param {array} _rooms Every room of the map
	function initialize_area(_rooms) {
		// Check every room to see what can be found within the area
		for (var _i = 0; _i < array_length(_rooms); _i++) {
			// Skip room if it is not in the reached area
			var _room = _rooms[_i];
			if (!_room.is_in_bitmask(reached_rooms)) { continue; }

			// Count its key or bomb, its light, and a locked chest that doesn't matter
			if (_room.has_key) {
				if (_room.key_in_chest && _room.chest_obj == obj_bomb) { bombs_reached += 1; }
				else { keys_reached += 1; }
			}
			if (_room.is_lit()) { reached_lit_room = true; }
			if (_room.has_locked_chest && _room.unlocked_chests_bitmask_index == -1) { other_locked_chests_reached += 1; }

			// A torch or special key in a chest that isn't locked, or that the area has unlocked
			if ((_room.stairs_spot_obj == obj_chest) && (!_room.has_locked_chest || is_chest_unlocked(_room))) {
				if (_room.chest_obj == obj_torch) { reached_torch = true; }
				else if (_room.chest_obj == obj_key && _room.has_special_item) { reached_special_key = true; }
			}
		}
	}

	/// @function is_chest_unlocked(_room)
	/// @description Whether a room's locked chest is one of the chests that matter, and the area has unlocked it
	/// @param {GameRoom} _room The room with the chest
	/// @returns {bool}
	function is_chest_unlocked(_room) {
		if (_room.unlocked_chests_bitmask_index == -1) { return false; }
		return ((unlocked_chests & (1 << _room.unlocked_chests_bitmask_index)) != 0);
	}

	/// @function is_exit_unlocked(_exit)
	/// @description Whether the area has opened a locked exit: both rooms it links are reached
	/// @param {RoomExit} _exit The locked exit
	/// @returns {bool}
	function is_exit_unlocked(_exit) {
		return (_exit.room_1.is_in_bitmask(reached_rooms) && _exit.room_2.is_in_bitmask(reached_rooms));
	}

	/// @function can_use_bombs_as_keys()
	/// @description Whether bombs can stand in for keys in the area: it has a torch, and a lit room to light it in
	/// @returns {bool}
	function can_use_bombs_as_keys() {
		return (reached_lit_room && reached_torch);
	}

	/// @function count_usable_keys()
	/// @description The keys the area gives the player to spend: the keys reached, and the bombs too once they can be lit,
	///	less the keys spent unlocking the chests that matter. The keys its locked exits took aren't taken off here.
	/// @returns {real}
	function count_usable_keys() {
		var _usable_keys = (can_use_bombs_as_keys() ? (keys_reached + bombs_reached) : keys_reached);
		var _keys_used = count_bits(unlocked_chests);
		return _usable_keys - _keys_used;
	}

	initialize_area(_rooms);
}

/// @function get_search_area_key(_reached_rooms, _unlocked_chests)
/// @description A key that two search areas share only when they reach the same rooms and have unlocked the same
///	chests, so the search checks each state once
/// @param {real} _reached_rooms Bitmask of the rooms the area reaches
/// @param {real} _unlocked_chests Bitmask of the chests that matter it has unlocked
/// @returns {string}
function get_search_area_key(_reached_rooms, _unlocked_chests) {
	return (string(_reached_rooms) + "," + string(_unlocked_chests));
}