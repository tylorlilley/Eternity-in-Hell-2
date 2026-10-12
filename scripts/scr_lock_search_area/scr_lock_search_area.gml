/// @function LockSearchArea(_map, _reached_rooms, _relevant_locked_chests)
/// @description An area to be searched for the lock and key generation in GameMap
/// @param {GameMap} _map					The map this area is searching within
/// @param {real} _reached_rooms			Bitmask of the rooms the area reaches, by map_rooms_index
/// @param {real} _relevant_locked_chests	Bitmask of the locked chests that affect rooms reached, by relevant_locked_chests_index
function LockSearchArea(_map, _reached_rooms, _relevant_locked_chests) constructor {
	// ========================
	// Static Functions
	// ========================
	
	/// @function initialize_area()
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
			if (_room.has_locked_chest && _room.relevant_locked_chests_index == -1) { irrelevant_locked_chests_reached += 1; }

			// Count the room's chest content if the chest is not locked or is unlocked
			if ((_room.stairs_spot_obj == obj_chest) && (!_room.has_locked_chest || is_room_chest_unlocked(_room))) {
				switch (_room.chest_obj) {
					case obj_torch: {
						reached_torch = true;
						break;
					}
					case obj_bomb: {
						if (_room.has_special_item) { reached_special_bomb = true; }
						if (_room.key_in_chest) { bombs_reached += 1; }
						break;
					}
					case obj_key: {
						if (_room.has_special_item) { reached_special_key = true; }
						if (_room.key_in_chest) { keys_reached += 1; }
						break;
					}
				}
			}
		}
	};

	/// @function is_room_chest_unlocked(_room)
	/// @description Whether a given chest, by it's bitmask index, has been unlocked in this search area or not
	/// @param {GameRoom} _room The room to check for whether its chest is unlocked or not
	/// @returns {bool}
	static is_room_chest_unlocked = function(_room) {
		// Chests that don't affect whether we grow the search area aren't given a bitmask index at all
		if (_room.relevant_locked_chests_index == -1) { return false; }

		return ((relevant_locked_chests & (1 << _room.relevant_locked_chests_index)) != 0);
	};
	
	/// @function is_room_reached(_room)
	/// @description Whether a given room, by its bitmask index, has been reached in this search area or not
	/// @param {GameRoom} _room The room to check for whether it is reached or not
	/// @returns {bool}
	static is_room_reached = function(_room) {
		return ((reached_rooms & (1 << _room.map_rooms_index)) != 0);
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
	/// @description Gets the count of keys spent on chests in this search area
	/// @returns {real}
	static get_keys_spent_on_chests = function() {
		return irrelevant_locked_chests_reached + count_bits(relevant_locked_chests);
	};

	/// @function get_keys_spent_on_exits()
	/// @description Gets the count of keys spent on locked exits in this search area
	/// @returns {real}
	static get_keys_spent_on_exits = function() {
		// Loop through each of the maps locked exits and count the ones this search area has already unlocked;
		// This is not tracked separately since there are thousands of LockedSearchAreas created and only one Map
		var _unlocked_exits = 0;
		for (var _i = 0; _i < array_length(map.locked_exits); _i++) {
			// Count the exit if it has been unlocked
			var _possible_exit = map.locked_exits[_i];
			if (is_exit_unlocked(_possible_exit)) { _unlocked_exits += 1; }
		}
		return _unlocked_exits;
	};

	/// @function get_keys_remaining()
	/// @description The keys the area gives the player to spend: the keys reached, and the bombs too once they can be lit,
	///	minus the keys spent unlocking chests and exits.
	/// @returns {real}
	static get_keys_remaining = function() {
		var _bombs_as_keys = (can_use_bombs_as_keys() ? bombs_reached : 0);
		return (keys_reached + _bombs_as_keys - get_keys_spent_on_exits() - get_keys_spent_on_chests());
	};
	
	/// @function can_use_special_item()
	/// @description Whether a special key or special bomb that is usable has been reached
	/// @returns {bool}
	static can_use_special_item = function() {
		return (reached_special_key || (reached_special_bomb && can_use_bombs_as_keys()));
	};
	
	// ========================
	// Instance Variables
	// ========================
	
	map = _map;											// The map this search area is searching for
	reached_rooms = _reached_rooms;						// Bitmask of reached rooms in this search area
	relevant_locked_chests = _relevant_locked_chests;	// Bitmask of relevant chests unlocked in this search area

	keys_reached = 0;
	bombs_reached = 0;									// These are bombs standing in for keys. They can open locks once they can be lit
	irrelevant_locked_chests_reached = 0;				// Locked chests that aren't relevant to expanding the search area, but that the player spends a key on in the worst case
	reached_lit_room = false;
	reached_torch = false;
	reached_special_key = false;						// A special key is never used up, so it opens every lock
	reached_special_bomb = false;						// A special bomb is never used up, so it opens every lock once it can be lit
	
	initialize_search_area();
}

/// @function get_search_area_key(_reached_rooms, _relevant_locked_chests)
/// @description A key that two search areas share only when they reach the same rooms and have unlocked the same
///	chests. This will make the search areas functionally identical, so we should only check them once
/// @param {real} _reached_rooms Bitmask of the rooms the area reaches
/// @param {real} _relevant_locked_chests Bitmask of the chests that matter it has unlocked
/// @returns {string}
function get_search_area_key(_reached_rooms, _relevant_locked_chests) {
	return (string(_reached_rooms) + "," + string(_relevant_locked_chests));
}