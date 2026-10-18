/// @function LockSearchArea(_map, _reached_rooms, _relevant_locked_chests)
/// @description An area to be searched for the lock and key generation in GameMap
/// @param {GameMap} _map					The map this area is searching within
/// @param {real} _reached_rooms			Bitmask of the rooms the area reaches, by map_rooms_index
/// @param {real} _relevant_locked_chests	Bitmask of the locked chests that affect rooms reached, by relevant_locked_chests_index
function LockSearchArea(_map, _reached_rooms, _relevant_locked_chests) constructor {
	// ========================
	// Static Functions
	// ========================

	/// @function initialize_search_area()
	/// @description Sets up variables based on what a player finds within the search area. A hidden chest outside a special
	///	room only counts once the area lets the player light its room, and the gudetama chest only once a gudetama item is
	///	reached, so those are counted last
	static initialize_search_area = function() {
		// Check every room to see what can be found within the area, setting aside the chests that wait on what the others hold
		var _hidden_chest_rooms = [], _gudetama_room = undefined;
		for (var _i = 0; _i < array_length(map.rooms); _i++) {
			// Skip room if it is not in the reached area
			var _room = map.rooms[_i];
			if (!is_room_reached(_room)) { continue; }
			
			// Count the room's non-chest content: An available key, its light, and any locked chest
			if (_room.has_key && !_room.key_in_chest) { keys_reached += 1; }
			if (_room.is_lit()) { reached_lit_room = true; }
			if (_room.has_locked_chest && _room.relevant_locked_chests_index == -1) { irrelevant_locked_chests_reached += 1; }

			// Count the room's chest content, unless the chest waits on a gudetama item or on light
			if (_room.is_special_room && _room.special_room_type.name == "sloth") { _gudetama_room = _room; }
			else if (_room.stairs_spot_obj == obj_hidden_chest && !_room.is_special_room) { array_push(_hidden_chest_rooms, _room); }
			else if (_room.stairs_spot_obj == obj_chest) { count_chest_content(_room); }
		}
		
		// A hidden chest shows once its room is lit, which takes a torch and a lit room to light it in, as lighting bombs does.
		// A special room's hidden chest shows once the room is solved instead, so it never counts
		if (can_use_bombs_as_keys()) {
			for (var _j = 0; _j < array_length(_hidden_chest_rooms); _j++) { count_chest_content(_hidden_chest_rooms[_j]); }
		}
		
		// The gudetama chest can only be opened once a gudetama item has been reached
		if (!is_undefined(_gudetama_room) && reached_gudetama_item) { count_chest_content(_gudetama_room); }
	};

	/// @function is_room_reached(_room)
	/// @description Whether a given room, by its bitmask index, has been reached in this search area or not
	/// @param {GameRoom} _room The room to check for whether it is reached or not
	/// @returns {bool}
	static is_room_reached = function(_room) {
		return ((reached_rooms & (1 << _room.map_rooms_index)) != 0);
	};

	/// @function count_chest_content(_room)
	/// @description Counts what a reached room's chest gives the player, if the chest isn't locked or the area unlocked it
	/// @param {GameRoom} _room The room whose chest to count
	static count_chest_content = function(_room) {
		// Skip the chest if it is still locked
		if (_room.has_locked_chest && !is_room_chest_unlocked(_room)) { return; }
		
		switch (_room.chest_obj) {
			case obj_torch: {
				reached_torch = true;
				break;
			}
			case obj_bomb: {
				if (_room.has_special_item) { reached_special_bomb = true; }
				if (_room.key_in_chest) { bombs_reached += 1; }
				else { reached_gudetama_item = true; }
				break;
			}
			case obj_key: {
				if (_room.has_special_item) { reached_special_key = true; }
				if (_room.key_in_chest) { keys_reached += 1; }
				break;
			}
			case obj_sword: {
				reached_gudetama_item = true;
				break;
			}
			case obj_staff: {
				if (_room.has_special_item) { reached_gudetama_item = true; }
				break;
			}
		}
	};

	/// @function is_room_chest_unlocked(_room)
	/// @description Whether a given chest, by its bitmask index, has been unlocked in this search area or not
	/// @param {GameRoom} _room The room to check for whether its chest is unlocked or not
	/// @returns {bool}
	static is_room_chest_unlocked = function(_room) {
		// Chests that don't affect whether we grow the search area aren't given a bitmask index at all
		if (_room.relevant_locked_chests_index == -1) { return false; }

		return ((relevant_locked_chests & (1 << _room.relevant_locked_chests_index)) != 0);
	};

	/// @function can_use_special_item()
	/// @description Whether a special key or special bomb that is usable has been reached
	/// @returns {bool}
	static can_use_special_item = function() {
		return (reached_special_key || (reached_special_bomb && can_use_bombs_as_keys()));
	};

	/// @function can_use_bombs_as_keys()
	/// @description Whether bombs can stand in for keys in this search area: it has a torch, and a lit room to light it in
	/// @returns {bool}
	static can_use_bombs_as_keys = function() {
		return (reached_lit_room && reached_torch);
	};

	/// @function get_keys_remaining()
	/// @description The keys the area gives the player to spend: the keys reached, and the bombs too once they can be lit,
	///	minus the keys spent unlocking chests and exits.
	/// @returns {real}
	static get_keys_remaining = function() {
		var _bombs_as_keys = (can_use_bombs_as_keys() ? bombs_reached : 0);
		return (keys_reached + _bombs_as_keys - get_keys_spent_on_exits() - get_keys_spent_on_chests());
	};

	/// @function get_keys_spent_on_exits()
	/// @description Gets the count of keys spent on locked exits in this search area
	/// @returns {real}
	static get_keys_spent_on_exits = function() {
		// Loop through each of the maps locked exits and count the ones this search area has already unlocked;
		// This is not tracked separately since there are thousands of LockSearchAreas created and only one Map
		var _unlocked_exits = 0;
		for (var _i = 0; _i < array_length(map.locked_exits); _i++) {
			// Count the exit if it has been unlocked
			var _possible_exit = map.locked_exits[_i];
			if (is_exit_unlocked(_possible_exit)) { _unlocked_exits += 1; }
		}
		return _unlocked_exits;
	};

	/// @function is_exit_unlocked(_exit)
	/// @description Whether the exit is unlocked. Since we account for worst case scenario, this is always true if we've reached both sides
	/// @param {RoomExit} _exit The locked exit
	/// @returns {bool}
	static is_exit_unlocked = function(_exit) {
		return (is_room_reached(_exit.room_1) && is_room_reached(_exit.room_2));
	};

	/// @function get_keys_spent_on_chests()
	/// @description Gets the count of keys spent on chests in this search area
	/// @returns {real}
	static get_keys_spent_on_chests = function() {
		return irrelevant_locked_chests_reached + count_bits(relevant_locked_chests);
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
	reached_gudetama_item = false;						// A special staff, sword, or (non-key) bomb
	
	initialize_search_area();
}

// ========================
// Global Search Area Functions
// ========================

/// @function get_search_area_key(_reached_rooms, _relevant_locked_chests)
/// @description A key that two search areas share only when they reach the same rooms and have unlocked the same
///	chests. This will make the search areas functionally identical, so we should only check them once
/// @param {real} _reached_rooms Bitmask of the rooms the area reaches
/// @param {real} _relevant_locked_chests Bitmask of the chests that matter it has unlocked
/// @returns {string}
function get_search_area_key(_reached_rooms, _relevant_locked_chests) {
	return (string(_reached_rooms) + "," + string(_relevant_locked_chests));
}