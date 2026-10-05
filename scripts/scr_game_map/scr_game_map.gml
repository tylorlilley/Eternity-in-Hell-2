/// @function GameMap()
/// @description The plan for one map (see scr_new_map_generation): the layouts its difficulty allows, its rooms
///	and the exits between them, its map-wide events and decorations, and what the controller keeps once
///	generation ends. Rooms and exits are only added through its methods, so its lookups always match its rooms.
///	It also reads every layout file once per session (step 1), into the layout cache every map shares.
function GameMap() constructor {
	// =================================================================================================
	// SHARED BY EVERY MAP
	// =================================================================================================

	// Every layout file, read once per session, when the first map is made (step 1). A static's line runs only
	// on the first call, but the rest of the constructor runs for every map, so the files are read only while
	// the cache is empty. It comes first, since layout_use_counts needs it
	static layout_cache = undefined;
	if (is_undefined(layout_cache)) {
		var _layouts = [], _sins = [
			{ name: "pride", layouts: [rm_four_exits_23, rm_four_exits_24] },					// Hall of mirrors
			{ name: "envy", layouts: [rm_four_exits_22, rm_one_exit_27, rm_three_exits_30] },	// Giant eye
			{ name: "wrath", layouts: [rm_one_exit_22] },										// Inverted cross
			{ name: "greed", layouts: [rm_one_exit_30] },										// Red chest
			{ name: "sloth", layouts: [rm_one_exit_23] }										// Gudetama
		];

		// Read each room asset as a layout, and keep the usable ones (see RoomLayout)
		for (var _room_asset = room_first; _room_asset != -1; _room_asset = room_next(_room_asset)) {
			var _layout = new RoomLayout(_room_asset);
			if (!_layout.is_usable) { continue; }
			_layout.index = array_length(_layouts);

			// Mark the layout as a sin room
			for (var _i = 0; _i < array_length(_sins); _i++) {
				var _sin = _sins[_i];

				for (var _j = 0; _j < array_length(_sin.layouts); _j++) {
					var _sin_layout = _sin.layouts[_j];

					if (_sin_layout == _layout.room_reference) {
						_layout.is_sin_room = true;
						_sin.layouts[_j] = _layout;
						break;
					}
				}
			}

			array_push(_layouts, _layout);
		}
		layout_cache = { layouts: _layouts, sins: _sins };
	}

	// The four side directions, clockwise from up. Every map shares this one array, so nothing may change
	// it; array_shuffle returns a shuffled copy, so shuffling it is fine
	static cardinal_exit_directions = [directions.up, directions.right, directions.down, directions.left];


	// =================================================================================================
	// THE MAP
	// =================================================================================================

	// Layouts this difficulty allows, sin layouts aside, by exit kind, and how many rooms use each (R20)
	layouts_by_exit_type = [];
	layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

	// Sins with a layout this difficulty allows, each with those layouts
	available_sins = [];

	// Map-wide events (step 2)
	same_skeleton_type = noone;
	cursed_item_count = 0;
	included_sins = [];

	// The room graph (steps 3, 4 and 6)
	rooms = [];
	room_at_cell = {};						// Each room by its grid cell ("x,y"), so finding a neighbor needs no search
	side_links = [];						// Every exit joining two grid neighbors

	// Decorations, redone on every pass of step 6
	start_room = undefined;
	heart_room = undefined;
	guaranteed_chest_room = undefined;
	cursed_items = [];						// Each cursed item type placed so far
	difficulty_score = 0;

	// What the controller keeps once generation ends
	time_provided = 0;
	rooms_with_collectables = [];
	spawned_items = [];
	spawned_special_items = [];

	// Initialize layouts by exit type with blank arrays
	for (var _type = 0; _type < mapgen_exit_types.count; _type++) { array_push(layouts_by_exit_type, []); }

	// Assign the cached layouts to their exit type's array, if the difficulty allows them
	for (var _i = 0; _i < array_length(layout_cache.layouts); _i++) {
		var _layout = layout_cache.layouts[_i];
		if (_layout.file_difficulty <= global.difficulty && !_layout.is_sin_room) {
			array_push(layouts_by_exit_type[_layout.exit_type], _layout);
		}
	}

	// For each sin, keep the layouts the difficulty allows, and the sin itself if any are left
	for (var _j = 0; _j < array_length(layout_cache.sins); _j++) {
		var _sin = layout_cache.sins[_j], _allowed_layouts = [];

		for (var _k = 0; _k < array_length(_sin.layouts); _k++) {
			if (_sin.layouts[_k].file_difficulty <= global.difficulty) { array_push(_allowed_layouts, _sin.layouts[_k]); }
		}
		if (array_length(_allowed_layouts) > 0) { array_push(available_sins, { name: _sin.name, layouts: _allowed_layouts }); }
	}

	// Check that every exit type has at least one layout, and at least one layout with a lantern. This should always be true, but good to check.
	for (var _type_checked = 0; _type_checked < mapgen_exit_types.count; _type_checked++) {
		var _layouts_of_type = layouts_by_exit_type[_type_checked];
		if (array_length(_layouts_of_type) == 0) {
			var _error_message = "No layout of exit kind " + string(_type_checked) + " at this difficulty: " + string(global.difficulty);
			write_debug_message(_error_message, "ERROR");
			show_error(_error_message, true);
		}

		if (array_length(mapgen_select_lantern_layouts(_layouts_of_type)) == 0) {
			write_debug_message("No lantern layout of exit kind " + string(_type_checked) + " at this difficulty.", "WARNING");
		}
	}

	// =================================================================================================
	// ROOMS AND THE EXITS BETWEEN THEM
	// =================================================================================================

	/// @function create_room_at_map_position(_x, _y)
	/// @description Adds a room on a free grid cell, with no exits or layout yet (R3).
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom} The new room
	static create_room_at_map_position = function(_x, _y) {
		var _room = new GameRoom(_x, _y);
		
		// Initialize room mapgen variables
		// TODO: move these into GameRoom constructor instead of setting them here
		_room.mapgen_sin = undefined;					// The sin reserved for it (step 4)
		_room.mapgen_content = undefined;				// What step 5 rolled for its layout
		_room.mapgen_chest_lock = -1;					// Its locked chest's number in the key check
		_room.mapgen_needs_layout = true;				// Its side exits changed since its last layout pick (R16)
		
		// Add room to map's rooms array, and room_at_cell lookup table
		_room.mapgen_index = array_length(rooms);
		array_push(rooms, _room);
		room_at_cell[$ get_cell_key(_x, _y)] = _room;
		
		return _room;
	};

	/// @function link_rooms(_room, _other_room, _dir)
	/// @description Joins two rooms with a new exit, on a side or by stairs.
	/// @param {GameRoom} _room One room
	/// @param {GameRoom} _other_room The other room
	/// @param {real} _dir The direction from _room to _other_room, or directions.stairs
	/// @returns {RoomExit} The new exit
	static link_rooms = function(_room, _other_room, _dir) {
		// Create a new Exit to Link the rooms With
		var _exit = new RoomExit(_room, _other_room);
		_room.exits[_dir] = _exit;
		_other_room.exits[get_opposite_dir(_dir)] = _exit;
		
		// Add the exit to the side links, and mark both linked rooms as needing a new room layout
		if (_dir != directions.stairs) {
			array_push(side_links, _exit);
			_room.mapgen_needs_layout = true;
			_other_room.mapgen_needs_layout = true;
		}
		
		return _exit;
	};

	/// @function get_cell_key(_x, _y)
	/// @description The key a grid cell has in room_at_cell.
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {string}
	static get_cell_key = function(_x, _y) {
		return string(_x) + "," + string(_y);
	};

	/// @function get_room_at(_x, _y)
	/// @description The room on a grid cell.
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom|undefined} The room, or undefined if the cell is free
	static get_room_at = function(_x, _y) {
		return room_at_cell[$ get_cell_key(_x, _y)];
	};

	/// @function get_neighbor(_room, _dir)
	/// @description The room on the grid cell beside a room, linked to it or not.
	/// @param {GameRoom} _room The room
	/// @param {real} _dir A side direction
	/// @returns {GameRoom|undefined} The neighbor, or undefined if the cell is free
	static get_neighbor = function(_room, _dir) {
		return get_room_at(_room.virtual_x + get_dir_x_offset(_dir), _room.virtual_y + get_dir_y_offset(_dir));
	};

	/// @function count_possible_starts()
	/// @description Counts the rooms that could be the start (R11).
	/// @returns {real}
	static count_possible_starts = function() {
		var _count = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			if (rooms[_i].can_be_start()) { _count += 1; }
		}
		return _count;
	};
	
	/// @function measure_distances(_from_room)
	/// @description Counts the steps from one room to every other by the quickest route, a stairs trip being
	///	one step, ignoring locks.
	/// @param {GameRoom} _from_room The room to measure from
	/// @returns {array} Steps to each room, by mapgen_index
	static measure_distances = function(_from_room) {
		var _distances = array_create(array_length(rooms), -1);
		var _queue = [_from_room];
		_distances[_from_room.mapgen_index] = 0;
		for (var _next = 0; _next < array_length(_queue); _next++) {
			var _room = _queue[_next];
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				var _other_room = _room.get_connected_room(_dir);
				if (_other_room == -1 || _distances[_other_room.mapgen_index] != -1) { continue; }
				_distances[_other_room.mapgen_index] = _distances[_room.mapgen_index] + 1;
				array_push(_queue, _other_room);
			}
		}
		return _distances;
	};


	// =================================================================================================
	// WHOLE-MAP PASSES
	// =================================================================================================

	/// @function reset_decorations()
	/// @description Clears everything steps 7 to 12 placed, so each pass of step 6 decorates the current graph
	///	starting from each room's rolled content.
	static reset_decorations = function() {
		start_room = undefined;
		heart_room = undefined;
		guaranteed_chest_room = undefined;
		cursed_items = [];
		for (var _i = 0; _i < array_length(rooms); _i++) { mapgen_reset_room(rooms[_i]); }
		for (var _j = 0; _j < array_length(side_links); _j++) { side_links[_j].reset_decorations(); }
	};
	
	// =================================================================================================
	// CALCULATIONS TO PASS OFF TO CONTROLLER
	// =================================================================================================


	/// @function calculate_map_difficulty_score()
	/// @description Scores every room and sets difficulty_score to their total (R2, R55).
	static calculate_map_difficulty_score = function() {
		difficulty_score = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];

			_room.room_reference_difficulty = _room.get_difficulty_score();
			difficulty_score += _room.room_reference_difficulty;
		}
	};

	/// @function calculate_time_provided()
	/// @description Calculates the run's total time: every room's time added up, from the rooms' scores.
	static calculate_time_provided = function() {
		time_provided = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) { time_provided += rooms[_i].get_time_provided(); }
	};

	/// @function calculate_collectables_and_items_lists()
	/// @description Lists what the controller tracks during play: the rooms with collectables, and the
	///	regular and cursed items in chests.
	static calculate_collectables_and_items_lists = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			
			// Calculate collectables list
			if (_room.has_collectables) { array_push(rooms_with_collectables, _room); }
			
			// Calculate item lists
			if (_room.has_chest() && !_room.has_trap_chest()) {
				array_push(_room.has_special_item ? spawned_special_items : spawned_items, _room.chest_obj);
			}
		}
	};

	/// @function destroy()
	/// @description Frees every room's path grids. Only for a map that will never be played, like a failed
	///	attempt; the controller frees a played map's rooms with destroy_all_game_rooms.
	static destroy = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].destroy(); }
	};
}