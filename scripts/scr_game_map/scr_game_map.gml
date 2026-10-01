/// @function GameMap()
/// @description The plan for one map (see scr_new_map_generation): the layouts its difficulty allows, its rooms
///	and the exits between them, its map-wide events and decorations, and what the controller keeps once
///	generation ends. Rooms and exits are only added through its methods, so its lookups always match its rooms.
function GameMap() constructor {
	// Every layout file, read once per session and shared by every map (see mapgen_cache_layouts)
	static layout_cache = mapgen_cache_layouts();

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
	stairs_links = [];						// Every exit joining two rooms by stairs

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
			var _error_message = "No layout of exit kind " + string(_type_checked) + " at this difficulty: " + global.difficulty;
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
		room_at_cell[$ mapgen_cell_key(_x, _y)] = _room;
		
		return _room;
	};

	/// @function link_rooms(_room, _other_room, _dir)
	/// @description Joins two rooms with a new exit, on a side or by stairs.
	/// @param {GameRoom} _room One room
	/// @param {GameRoom} _other_room The other room
	/// @param {real} _dir The direction from _room to _other_room, or directions.stairs
	/// @returns {RoomExit} The new exit
	static link_rooms = function(_room, _other_room, _dir) {
		var _exit = new RoomExit(_room, _other_room);
		_room.exits[_dir] = _exit;
		_other_room.exits[get_opposite_dir(_dir)] = _exit;
		if (_dir == directions.stairs) {
			array_push(stairs_links, _exit);
		}
		else {
			array_push(side_links, _exit);
			// A layout depends on the room's side exits, so both rooms need a new one (R16)
			_room.mapgen_needs_layout = true;
			_other_room.mapgen_needs_layout = true;
		}
		return _exit;
	};

	/// @function get_room_at(_x, _y)
	/// @description The room on a grid cell.
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom|undefined} The room, or undefined if the cell is free
	static get_room_at = function(_x, _y) {
		return room_at_cell[$ mapgen_cell_key(_x, _y)];
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
			if (mapgen_can_be_start(rooms[_i])) { _count += 1; }
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
		for (var _j = 0; _j < array_length(side_links); _j++) { mapgen_reset_exit(side_links[_j]); }
	};
	
	// =================================================================================================
	// CALCULATIONS TO PASS OFF TO CONTROLLER
	// =================================================================================================


	/// @function score_rooms()
	/// @description Sets the total _difficulty_score by summing all rooms
	static calculate_map_difficulty_score = function() {
		_difficulty_score = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];

			_room.room_reference_difficulty = mapgen_score_room(_room);
			_difficulty_score += _room.room_reference_difficulty;
		}
	};

	/// @function calculate_time_provided()
	/// @description Calculates the run's total time: every room's time added up, from the rooms' scores.
	static calculate_time_provided = function() {
		_time_provided  = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) { _time_provided += mapgen_get_room_time(rooms[_i]); }
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
			if (mapgen_has_chest(_room) && !mapgen_is_trap(_room.chest_obj)) {
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

// =====================================================================================================
// STEP 1: CACHE THE LAYOUTS (once per session)
// =====================================================================================================

/// @function mapgen_cache_layouts()
/// @description Reads every layout file and keeps what generation and building need, so no other step
///	reads a file. GameMap calls this once per session and shares the result as its layout_cache, since
///	layout files never change while the game runs.
/// @returns {struct} { layouts: every layout record (see mapgen_read_layout), sins: the sin table with layout records }
function mapgen_cache_layouts() {
	// Every room asset named for its exits is a layout (rm_title, rm_start, rm_finish and rm_unused_* are not)
	var _layouts = [], _sins = [
		{ name: "pride", layouts: [rm_four_exits_23, rm_four_exits_24] },					// Hall of mirrors
		{ name: "envy", layouts: [rm_four_exits_22, rm_one_exit_27, rm_three_exits_30] },	// Giant eye
		{ name: "wrath", layouts: [rm_one_exit_22] },										// Inverted cross
		{ name: "greed", layouts: [rm_one_exit_30] },										// Red chest
		{ name: "sloth", layouts: [rm_one_exit_23] }										// Gudetama
	];
	
	// Loop through each room asset and read its corresponding layout file
	for (var _room_asset = room_first; _room_asset != -1; _room_asset = room_next(_room_asset)) {
		var _name = room_get_name(_room_asset);
		var _exit_type = mapgen_get_exit_type_from_name(_name);
		if (_exit_type == -1 || string_starts_with(_name, "rm_unused")) { continue; }

		var _layout = mapgen_read_layout(_room_asset, _exit_type, array_length(_layouts));
		if (!is_undefined(_layout)) {
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
	}
	
	return { layouts: _layouts, sins: _sins };
}

/// @function mapgen_read_layout(_room_asset, _exit_type, _index)
/// @description Reads one layout file: line 1 holds the file difficulty written by room_converter.rb, and
///	line 2 the placed instances. Counts the objects generation cares about, and notes which spots share
///	their tile with nothing else.
/// @param {Asset.GMRoom} _room_asset The layout's room
/// @param {real} _exit_type The layout's mapgen_exit_types kind
/// @param {real} _index The layout's position in the cache
/// @returns {struct|undefined} The layout record, or undefined if its file is missing
function mapgen_read_layout(_room_asset, _exit_type, _index) {
	var _name = room_get_name(_room_asset);
	var _file = file_text_open_read(_name + ".json");
	if (_file == -1) {
		write_debug_message("Missing layout file, so the layout is never used: " + _name + ".json", "WARNING");
		return undefined;
	}
	var _file_difficulty = real(string_digits(file_text_read_string(_file)));
	file_text_readln(_file);
	var _instances = json_parse(file_text_read_string(_file));
	file_text_close(_file);

	// How many of each object the layout places, by object name, how many instances share each tile, and
	// which tiles building may clear: an exit spot's, when its side closes, and the chest spot's
	var _counts = {}, _instances_on_tile = {}, _cleared_tiles = {};
	for (var _i = 0; _i < array_length(_instances); _i++) {
		var _instance = _instances[_i];
		var _tile = mapgen_cell_key(_instance.x, _instance.y);
		_counts[$ _instance.name] = mapgen_get_count(_counts, _instance.name) + 1;
		_instances_on_tile[$ _tile] = mapgen_get_count(_instances_on_tile, _tile) + 1;
		if (string_starts_with(_instance.name, "obj_exit_spot") || _instance.name == "obj_chest_spot") { _cleared_tiles[$ _tile] = true; }
	}

	// Collectable spots are numbered in file order, so building can find the ones generation picks (R57). A
	// floor key can take any spot building never clears. A portcullis button needs a spot alone on its tile,
	// since anything else there, like an enemy or a block, could hold it down (R52)
	var _key_spots = [], _button_spots = [], _stairs_spot_is_clear = false, _spot_number = 0;
	for (var _j = 0; _j < array_length(_instances); _j++) {
		var _spot = _instances[_j];
		var _spot_tile = mapgen_cell_key(_spot.x, _spot.y);
		var _is_alone = (mapgen_get_count(_instances_on_tile, _spot_tile) == 1);
		if (_spot.name == "obj_stairs_spot") { _stairs_spot_is_clear = _is_alone; }
		if (_spot.name != "obj_collectable_spot") { continue; }
		if (is_undefined(_cleared_tiles[$ _spot_tile])) { array_push(_key_spots, _spot_number); }
		if (_is_alone) { array_push(_button_spots, _spot_number); }
		_spot_number += 1;
	}

	var _layout = {
		index: _index,
		room_reference: _room_asset,
		name: _name,
		exit_type: _exit_type,
		file_difficulty: _file_difficulty,
		instances: _instances,											// What building the room creates
		is_sin_room: false,												// Set later, from the sin table

		// Spots and lanterns (L1 to L6)
		key_spots: _key_spots,											// Collectable spot numbers a floor key can take
		button_spots: _button_spots,									// Collectable spot numbers a button can take
		stairs_spot_is_clear: _stairs_spot_is_clear,					// Whether a button can take the stairs spot
		collectable_spot_count: mapgen_get_count(_counts, "obj_collectable_spot"),
		skeleton_spot_count: mapgen_get_count(_counts, "obj_skeleton_spot"),
		has_lanterns: mapgen_get_count(_counts, "obj_lantern") > 0,
		is_hall_of_mirrors: mapgen_get_count(_counts, "obj_hall_of_mirrors") > 0,

		// Placed objects that rolled content builds on
		column_count: mapgen_get_count(_counts, "obj_column"),
		statue_count: mapgen_get_count(_counts, "obj_statue"),
		lava_count: mapgen_get_count(_counts, "obj_lava"),
		mouth_count: mapgen_get_count(_counts, "obj_mouth"),
		eyes_count: mapgen_get_count(_counts, "obj_eyes"),

		// Other placed objects the score counts (R55)
		ears_count: mapgen_get_count(_counts, "obj_ears"),
		gudetama_count: mapgen_get_count(_counts, "obj_gudetama"),
		bumper_count: mapgen_get_count(_counts, "obj_bumper_old"),
		spider_spot_count: mapgen_get_count(_counts, "obj_spider_spot"),
		spider_count: mapgen_get_count(_counts, "obj_spider"),
		fountain_count: mapgen_get_count(_counts, "obj_fountain"),
		snake_count: mapgen_get_count(_counts, "obj_snake"),
		worm_head_count: mapgen_get_count(_counts, "obj_giant_worm_head"),
		worm_body_count: mapgen_get_count(_counts, "obj_giant_worm_body"),
		block_spot_count: mapgen_get_count(_counts, "obj_block_spot"),
		bones_count: mapgen_get_count(_counts, "obj_bones"),
		corpse_count: mapgen_get_count(_counts, "obj_player_corpse")
	};
	mapgen_check_layout_rules(_layout, _counts);
	return _layout;
}

/// @function mapgen_check_layout_rules(_layout, _counts)
/// @description Logs any way a layout file breaks the spot rules generation relies on (L1 to L4).
/// @param {struct} _layout The layout record
/// @param {struct} _counts How many of each object the layout places, by object name
function mapgen_check_layout_rules(_layout, _counts) {
	// Enforeces that the room is valid. The ruby script also does this so it should be redundant and never warn, but good to have as a failsafe.
	var _problems = "";
	if (mapgen_get_count(_counts, "obj_chest_spot") != 1) { _problems += " needs exactly one chest spot (L1);"; }
	if (mapgen_get_count(_counts, "obj_stairs_spot") != 1) { _problems += " needs exactly one stairs spot (L2);"; }
	if (array_length(_layout.key_spots) < 2) { _problems += " needs at least two collectable spots off the exit and chest spots (L3);"; }
	if (mapgen_get_count(_counts, "obj_exit_spot_up") == 0 || mapgen_get_count(_counts, "obj_exit_spot_right") == 0 ||
		mapgen_get_count(_counts, "obj_exit_spot_down") == 0 || mapgen_get_count(_counts, "obj_exit_spot_left") == 0) {
		_problems += " needs an exit spot on every side (L4);";
	}
	if (_problems != "") { write_debug_message("Layout " + _layout.name + _problems, "WARNING"); }
}

/// @function mapgen_get_exit_type_from_name(_name)
/// @description Reads a layout's exit kind from its room name, like rm_three_exits_12.
/// @param {string} _name The room name
/// @returns {real} A mapgen_exit_types kind, or -1 if the room is not a layout
function mapgen_get_exit_type_from_name(_name) {
	if (string_pos("no_exits", _name) != 0) { return mapgen_exit_types.none; }
	if (string_pos("one_exit", _name) != 0) { return mapgen_exit_types.one; }
	if (string_pos("two_opposite_exits", _name) != 0) { return mapgen_exit_types.two_opposite; }
	if (string_pos("two_perpendicular_exits", _name) != 0) { return mapgen_exit_types.two_perpendicular; }
	if (string_pos("three_exits", _name) != 0) { return mapgen_exit_types.three; }
	if (string_pos("four_exits", _name) != 0) { return mapgen_exit_types.four; }
	return -1;
}

/// @function mapgen_get_count(_counts, _key)
/// @description A count kept in a struct of counts, like how many of an object a layout places.
/// @param {struct} _counts Counts by key
/// @param {string} _key The key, like an object's name
/// @returns {real} The count, or 0 if the key has none
function mapgen_get_count(_counts, _key) {
	var _count = _counts[$ _key];
	return is_undefined(_count) ? 0 : _count;
}
