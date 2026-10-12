/// @function LockSearchArea(_reached_rooms, _unlocked_chests, _rooms)
/// @description An area to be searched for the lock and key generation in GameMap
/// @param {real} _reached_rooms	Bitmask of the rooms the area reaches, by mapgen_index
/// @param {real} _unlocked_chests	Bitmask of the chests that matter unlocked in the area, by unlocked_chests_bitmask_index
function LockSearchArea(_map, _reached_rooms, _unlocked_chests) constructor {
	/// @function initialize_area(_rooms)
	/// @description Sets up variables based on what a player finds within the search area
	static initialize_search_area = function() {
		// Check every room to see what can be found within the area
		var _rooms = map.rooms;
		for (var _i = 0; _i < array_length(_rooms); _i++) {
			// Skip room if it is not in the reached area
			var _room = _rooms[_i];
			if (!is_room_reached(_room)) {continue; }

			// Count the room's non-chest content: An available key or bomb, its light, its torch, and any locked chest
			if (_room.has_key && !_room.key_in_chest) { keys_reached += 1; }
			if (_room.is_lit()) { reached_lit_room = true; }
			if (_room.has_locked_chest && _room.unlocked_chests_bitmask_index == -1) { other_locked_chests_reached += 1; }

			// Count the room's chest content if the chest is not locked or is unlocked
			if ((_room.stairs_spot_obj == obj_chest) && (!_room.has_locked_chest || is_room_chest_unlocked(_room))) {
				switch (_room.chest_obj) {
					case obj_torch: { reached_torch = true; break; }
					case obj_bomb: {
						if (_room.has_special_item) { reached_special_bomb = true; }
						if (_room.has_key_in_chest) { keys_reached += 1; }
						break;
					}
					case obj_key: {
						if (_room.has_special_item) { reached_special_key = true; }
						if (_room.has_key_in_chest) { keys_reached += 1; }
						break;
					}
				}
			}
		}
		
		// Check every exit to see what can be found within the area
		var _exits = map.cardinal_exits;
		for (var _i = 0; _i < array_length(map.cardinal_exits); _i++) {
			// Skip exits that aren't locked
			var _possible_exit = _exits[_i];
			if (!_possible_exit.has_lock) { continue; }
			
			// Add the exit to the locked array and count it if it has been unlocked in this area
			array_push(locked_exits, _possible_exit);
			if (is_exit_unlocked(_possible_exit)) { unlocked_exits += 1; }
		}
	};

	/// @function is_chest_unlocked(_room)
	/// @description Whether a given chest, by it's bitmask index, has been unlocked in this search area or not
	/// @param {GameRoom} _room The room to check for whether it's chest is unlocked or not
	/// @returns {bool}
	static is_room_chest_unlocked = function(_room) {
		// Chests that don't affect whether we grow the search area aren't given a bitmask index at all
		if (_room.unlocked_chests_bitmask_index == -1) { return false; }

		return ((unlocked_chests & (1 << _room.unlocked_chests_bitmask_index)) != 0);
	};
	
	/// @function is_room_reached(_room)
	/// @description Whether a given room, by it's bitmask index, has been reached in this search area or not
	/// @param {GameRoom} _room The room to check for whether it is reached or not
	/// @returns {bool}
	static is_room_reached = function(_room) {
		// TODO: Is the room mapgen_index used for anything else or can we rename this to _reached_rooms_bitmask_index?
		return ((reached_rooms & (1 << _room.mapgen_index)) != 0);
	};

	/// @function is_exit_unlocked(_exit)
	/// @description Whether the exit is unlocked. Since we account for worst case scenario, this is always true if we've reached both sides
	/// @param {RoomExit} _exit The locked exit
	/// @returns {bool}
	static is_exit_unlocked = function(_exit) {
		return (is_room_reached(_exit.room_1) && is_room_reached(_exit.room_2));
	};

	/// @function can_use_bombs_as_keys()
	/// @description Whether bombs can stand in for keys in this search area: it has a torch, and a lit room to light it in
	/// @returns {bool}
	static can_use_bombs_as_keys = function() {
		return (reached_lit_room && reached_torch);
	};
	
	/// @function get_keys_spent_on_chests()
	/// @description Gets the count of keys spent on important chests in this search area
	/// @returns {real}
	static get_keys_spent_on_chests = function() {
		return other_locked_chests_reached + count_bits(unlocked_chests);
	}

	/// @function get_keys_remaining()
	/// @description The keys the area gives the player to spend: the keys reached, and the bombs too once they can be lit,
	///	minus the keys spent unlocking chests and exits.
	/// @returns {real}
	static get_keys_remaining = function() {
		var _bombs_as_keys = (can_use_bombs_as_keys() ? bombs_reached : 0);
		return (keys_reached + _bombs_as_keys - unlocked_exits - get_keys_spent_on_chests());
	};
	
	/// @function can_use_special_item()
	/// @description Whether a special key or special bomb that is usable has been reached
	/// @returns {bool}
	static can_use_special_item = function() {
		return (reached_special_key || (reached_special_bomb && can_use_bombs_as_keys()));
	};
	
	map = _map									// The map this search area is searching for
	reached_rooms = _reached_rooms;
	unlocked_chests = _unlocked_chests;
	locked_exits = [];
	
	unlocked_exits = 0;
	keys_reached = 0;
	bombs_reached = 0;							// These are bombs standing in for keys. They can open locks once they can be lit
	other_locked_chests_reached = 0;			// Locked chests that don't matter but the player spends a key on in the worst case
	reached_lit_room = false;
	reached_torch = false;
	reached_special_key = false;				// A special key is never used up, so it opens every lock
	reached_special_bomb = false;				// A special bomb is never used up, so it opens every lock once it can be lit
	
	initialize_search_area();
}

/// @function get_search_area_key(_reached_rooms, _unlocked_chests)
/// @description A key that two search areas share only when they reach the same rooms and have unlocked the same
///	chests. This will make the search areas functionally identical, so we should ony check them once
/// @param {real} _reached_rooms Bitmask of the rooms the area reaches
/// @param {real} _unlocked_chests Bitmask of the chests that matter it has unlocked
/// @returns {string}
function get_search_area_key(_reached_rooms, _unlocked_chests) {
	return (string(_reached_rooms) + "," + string(_unlocked_chests));
}