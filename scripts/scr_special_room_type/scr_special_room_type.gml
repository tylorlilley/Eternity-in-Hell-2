/// @function SpecialRoomType(_name, _room_references)
/// @description One type of special room a map can include, with its name and dedicated layouts
/// @param {string} _name						A name for the room type
/// @param {array} _room_references				Room assets for the special room layouts
function SpecialRoomType(_name, _room_references) constructor {
	// ========================
	// Static Functions
	// ========================
	
	/// @function has_layout_of_exit_type(_exit_type)
	/// @description Whether any of the special room type layouts have the given exit type
	/// @param {real} _exit_type A layout_exit_types enum value
	/// @returns {bool}
	static has_layout_of_exit_type = function(_exit_type) {
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i] != -1 && layouts[_i].exit_type == _exit_type) { return true; }
		}
		return false;
	};
	
	/// @function get_exit_types()
	/// @description Returns each exit type that is included among the layouts at least once
	/// @returns {array} An array of layout_exit_types enum values
	static get_exit_types = function() {
		var _exit_types = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i] == -1) { continue; }
			if (!array_contains(_exit_types, layouts[_i].exit_type)) { array_push(_exit_types, layouts[_i].exit_type); }
		}
		return _exit_types;
	};
	
	/// @function get_layouts_of_exit_type(_exit_type)
	/// @description Returns any layouts that match the given exit type
	/// @param {real} _exit_type A layout_exit_types enum value
	/// @returns {array} the matching RoomLayouts, in a new array
	static get_layouts_of_exit_type = function(_exit_type) {
		var _matching_exit_types = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i] != -1 && layouts[_i].exit_type == _exit_type) { array_push(_matching_exit_types, layouts[_i]); }
		}
		return _matching_exit_types;
	};
	
	// ========================
	// Instance Variables
	// ========================
	name = _name;
	room_references = _room_references;
	layouts = array_create(array_length(room_references), -1); // Assigned from the cache at runtime in the GameMap constructor
}