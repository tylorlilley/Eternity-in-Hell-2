/// @function SpecialRoomType(_name, _layouts)
/// @description One type of special room a map can include, with the layouts a room of that type can use
/// @param {string} _name Its name, like "pride"
/// @param {array} _layouts Its layouts: room assets in GameMap's table of special room types, then RoomLayouts once the
///	layout cache is built
function SpecialRoomType(_name, _layouts) constructor {
	name = _name;
	layouts = _layouts;

	/// @function has_layout_of_type(_exit_type)
	/// @description Whether one of the type's layouts has a given exit kind
	/// @param {real} _exit_type A layout_exit_types kind
	/// @returns {bool}
	static has_layout_of_type = function(_exit_type) {
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i].exit_type == _exit_type) { return true; }
		}
		return false;
	};

	/// @function get_layouts_of_type(_exit_type)
	/// @description The type's layouts that have a given exit kind
	/// @param {real} _exit_type A layout_exit_types kind
	/// @returns {array} RoomLayouts, in a new array
	static get_layouts_of_type = function(_exit_type) {
		var _kept = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i].exit_type == _exit_type) { array_push(_kept, layouts[_i]); }
		}
		return _kept;
	};

	/// @function get_exit_types()
	/// @description Each exit kind the type's layouts have, once
	/// @returns {array} layout_exit_types kinds
	static get_exit_types = function() {
		var _exit_types = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (!array_contains(_exit_types, layouts[_i].exit_type)) { array_push(_exit_types, layouts[_i].exit_type); }
		}
		return _exit_types;
	};
}