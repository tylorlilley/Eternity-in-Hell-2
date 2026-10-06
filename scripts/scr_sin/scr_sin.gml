/// @function Sin(_name, _layouts)
/// @description One of the sins a map can include, each with a name and the layouts its room can use.
/// @param {string} _name Its name, like "pride"
/// @param {array} _layouts Its layouts: room assets in the layout cache's sin table, RoomLayouts once the cache is read
function Sin(_name, _layouts) constructor {
	name = _name;
	layouts = _layouts;

	/// @function has_layout_of_type(_exit_type)
	/// @description Cycle through each of the sin's RoomLayouts and return whether one of the given _exit_type is found
	/// @param {real} _exit_type A layout_exit_types kind
	/// @returns {bool}
	static has_layout_of_type = function(_exit_type) {
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i].exit_type == _exit_type) { return true; }
		}
		return false;
	};

	/// @function get_layouts_of_type(_exit_type)
	/// @description Cycle through each of the sin's RoomLayouts and return the ones of the given _exit_type
	/// @param {real} _exit_type A layout_exit_types kind
	/// @returns {array}
	static get_layouts_of_type = function(_exit_type) {
		var _kept = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i].exit_type == _exit_type) { array_push(_kept, layouts[_i]); }
		}
		return _kept;
	};

	/// @function get_exit_types()
	/// @description Cycle through each of the sin's RoomLayouts and return each exit kind they have, once
	/// @returns {array} layout_exit_types kinds
	static get_exit_types = function() {
		var _exit_types = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (!array_contains(_exit_types, layouts[_i].exit_type)) { array_push(_exit_types, layouts[_i].exit_type); }
		}
		return _exit_types;
	};
}