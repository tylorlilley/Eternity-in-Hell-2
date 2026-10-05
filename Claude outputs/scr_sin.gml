/// @function Sin(_name, _layouts)
/// @description One of the sins a map can include, each with its own special room (see GameMap's layout cache):
///	its name and the layouts its room can use.
/// @param {string} _name Its name, like "pride"
/// @param {array} _layouts Its layouts: room assets in the layout cache's sin table, RoomLayouts once the cache is read
function Sin(_name, _layouts) constructor {
	name = _name;
	layouts = _layouts;

	/// @function has_layout_of_type(_exit_type)
	/// @description Whether one of the sin's layouts has a given exit kind.
	/// @param {real} _exit_type A mapgen_exit_types kind
	/// @returns {bool}
	static has_layout_of_type = function(_exit_type) {
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i].exit_type == _exit_type) { return true; }
		}
		return false;
	};

	/// @function get_layouts_of_type(_exit_type)
	/// @description The sin's layouts with a given exit kind.
	/// @param {real} _exit_type A mapgen_exit_types kind
	/// @returns {array}
	static get_layouts_of_type = function(_exit_type) {
		var _kept = [];
		for (var _i = 0; _i < array_length(layouts); _i++) {
			if (layouts[_i].exit_type == _exit_type) { array_push(_kept, layouts[_i]); }
		}
		return _kept;
	};
}