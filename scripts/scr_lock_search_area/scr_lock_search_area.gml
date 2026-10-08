/// @function									new LockSearchArea(_reached_rooms, _unlocked_chests);
/// @param		{bitmask}	_reached_rooms		The bitmask of rooms this area can reach
/// @param		{bitmask}	_unlocked_chests		The bitmask of significant chests opened in this area
function LockSearchArea(_reached_rooms, _unlocked_chests) constructor {
	reached_rooms = _reached_rooms;
	unlocked_chests = _unlocked_chests;
	keys_reached = 0;
	bombs_reached = 0;
	useless_locked_chests_reached = 0;
	reached_lit_room = false;
	reached_torch = false;
	reached_special_key = false;
	
	/// @function get_key(_area)
	/// @description Returns the unique key for this search area
	static get_key = function() {
		return (string(reached_rooms) + "," + string(unlocked_chests));
	}
	
	/// @function count_haul(_area)
	/// @description Initializes the values for what can be reached within this search area
	function initialize_area() {
		// Check every room to see what can be found within the area
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip room if it is not in the reached area
			var _room = rooms[_i];
			if (!_room.is_in_bitmask(reached_rooms)) { continue; }

			// Otherwise, add update reached rooms and items
			if (_room.has_key) {
				if (_room.key_in_chest && _room.chest_obj == obj_bomb) { bombs_reached += 1; }
				else { keys_reached += 1; }
			}
			if (_room.is_lit()) { reached_lit_room = true; }
			if (_room.has_locked_chest && _room.mapgen_chest_lock == -1) { useless_locked_chests_reached += 1; } // TODO: What is mapgen_chest_lock for?
			
			// If the room has a lockless or unlocked chest
			if ((_room.stairs_spot_obj == obj_chest) && (!_room.has_locked_chest || is_locked_chest_opened(_room))) {
				if (_room.chest_obj == obj_torch) { has_torch_chest = true; }
				else if (_room.chest_obj == obj_key && _room.has_special_item) { has_cursed_key = true; }
			}
		}
	}
	
	/// @function is_chest_opened(_room)
	/// @description Whether a room has an open chest or not
	/// @param {struct} _room The room to check for an open chest
	/// @returns {bool} Whether a room has an open chest or not
	function is_locked_chest_opened(_room) {
		if (_room.mapgen_chest_lock == -1) { return false; }
		return (unlocked_chests & (1 << _room.mapgen_chest_lock) != 0)
	}
	
	/// @function is_locked_door_opened(_room)
	/// @description Whether an exit within the search area has been unlocked
	/// @param {struct} _room The exit to check both sides for reachability
	/// @returns {bool} Whether an exit within the area has been unlocked or not
	function is_locked_door_opened(_exit) {
		return (_exit.room_1.is_in_bitmask(reached_rooms) && _exit.room_2.is_in_bitmask(reached_rooms));
	}
	
	/// @function can_use_bombs_as_keys()
	/// @description Whether whether this area has access to the tools needed to use bombs as keys
	/// @returns {bool} Whether bombs can be used as keys
	function can_use_bombs_as_keys() {
		return (reached_lit_room && reached_torch);
	}
	
	function keys_collected() {
		// This doesn't account for the keys spent on locked doors within the area
		var _keys_collected = (can_use_bombs_as_keys() ? (keys_reached + bombs_reached) : keys_reached);
		var _keys_used = count_bits(unlocked_chests)
		return _keys_collected - _keys_used;
	}
	
	initialize_area();
}