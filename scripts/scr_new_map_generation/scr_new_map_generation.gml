// The six kinds of layout file, named after the side exits they open
enum mapgen_exit_types {
	none,				// rm_no_exits_*: rooms reached only by stairs
	one,				// rm_one_exit_*
	two_opposite,		// rm_two_opposite_exits_*
	two_perpendicular,	// rm_two_perpendicular_exits_*
	three,				// rm_three_exits_*
	four,				// rm_four_exits_*
	count				// How many kinds there are
}

/// @function mapgen_generate()
/// @description Plans a whole map for global.difficulty from the current random stream (steps 1 to 13).
/// @returns {struct} The finished map (see mapgen_create_map)
function mapgen_generate() {
	// Generate maps up to 100 times before giving up. It should always work on the first try, this is here as a failsafe.
	// As a failsafe, switch to the next seed after 100 failures and try again.
	var _map = undefined;
	while (is_undefined(_map)) {
		// Attempt map generation on this seed up to 100 times
		var _failed_attempts = 0;
		do {
			_failed_attempts += 1;
			_map = mapgen_try_generate();
		}
		until (!is_undefined(_map) || _failed_attempts >= 100);
	
		// If map is still undefined give up and move on to next seed
		if (is_undefined(_map)) {
			write_debug_message("Map generation failed 100 times for seed: " + string(global.seed), "ERROR");
			global.seed += 1;
			random_set_seed(global.seed);
		}
	}
	
	// Once map generation has succeeded, deal with the starting hand items
	var _hands_seed = irandom(MAX_SEED), _build_seed = irandom(MAX_SEED);
	random_set_seed(_hands_seed);
	mapgen_adjust_items_for_hands(_map);
	random_set_seed(_build_seed);

	mapgen_list_collectables_and_items(_map);
	return _map;
}

/// @function mapgen_try_generate()
/// @description Makes one attempt at steps 2 to 13, everything but fitting items to the hands.
/// @returns {struct|undefined} The map, or undefined if a last resort failed (its rooms are freed)
function mapgen_try_generate() {
	// Step 1: create initial map using cached version of room layouts read from disk
	var _map = mapgen_create_map();

	// Step 2: map-wide events, the run's sins and how many other cursed items spawn
	mapgen_roll_run_events(_map);

	// Step 3: grow the graph to the minimum room count, with no layouts yet (R1)
	mapgen_create_room(_map, 0, 0);
	while (array_length(_map.rooms) < MINIMUM_NUMBER_OF_ROOMS) {
		if (is_undefined(mapgen_grow_room(_map, true))) { return mapgen_fail(_map, "no room could grow"); }
	}

	// Step 4: side links toward the average, then a room that fits each sin
	mapgen_add_side_links(_map);
	if (!mapgen_reserve_sin_rooms(_map)) { return mapgen_fail(_map, "no room could be shaped for a sin"); }

	// Step 5: every room's layout and rolled content
	mapgen_pick_layouts(_map);

	// Step 6: decorate and score the whole map. While the score is short of the target, add one room and
	// decorate again, so every point counted is something the map really has (R2)
	while (true) {
		if (!mapgen_decorate(_map)) { return mapgen_fail(_map, "the start and heart or the heart's keys could not be placed"); }
		_map.difficulty_score = mapgen_score_map(_map);
		if (_map.difficulty_score >= MAP_SCORE_TARGET || array_length(_map.rooms) >= MAX_NUMBER_OF_ROOMS) { break; }
		if (is_undefined(mapgen_grow_room(_map, true))) { break; }
		mapgen_add_side_links(_map);
		mapgen_pick_layouts(_map);
	}

	// Step 13: the time, from the last pass's scores
	_map.time_provided = mapgen_total_time(_map);
	return _map;
}

/// @function mapgen_decorate(_map)
/// @description Steps 7 to 12: one decoration pass over the current graph, starting from each room's
///	rolled content.
/// @param {struct} _map The map being generated
/// @returns {bool} False if a last resort failed
function mapgen_decorate(_map) {
	mapgen_reset_decorations(_map);
	if (!mapgen_choose_start_and_heart(_map)) { return false; }		// Step 7
	mapgen_place_collectables(_map);								// Step 8
	mapgen_ensure_a_lit_room(_map);									// Step 8
	mapgen_place_chests(_map);										// Step 9
	if (!mapgen_place_locks_and_keys(_map)) { return false; }		// Steps 10 and 11
	mapgen_place_special_exits(_map);								// Step 12
	return true;
}

/// @function mapgen_fail(_map, _reason)
/// @description Logs a failed attempt and frees its rooms' path grids (R60).
/// @param {struct} _map The map that failed
/// @param {string} _reason What failed
/// @returns {undefined}
function mapgen_fail(_map, _reason) {
	write_debug_message("Map generation attempt failed, retrying on the same random stream: " + _reason, "WARNING");
	for (var _i = 0; _i < array_length(_map.rooms); _i++) { _map.rooms[_i].destroy(); }
	return undefined;
}


// =====================================================================================================
// STEP 1: CACHE THE LAYOUTS (once per session)
// =====================================================================================================

/// @function mapgen_cache_layouts()
/// @description Reads every layout file once per session and keeps what generation and building need,
///	so no other step reads a file. Layout files never change while the game runs.
/// @returns {struct} { layouts: every layout record (see mapgen_read_layout), sins: the sin table with layout records }
function mapgen_cache_layouts() {
	// Every room asset named for its exits is a layout (rm_title, rm_start, rm_finish and rm_unused_* are not)
	var _layouts  = [] _sins = [
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


// =====================================================================================================
// THE MAP, ITS ROOMS AND THEIR LINKS
// =====================================================================================================

/// @function mapgen_create_map(_cache)
/// @description Starts an empty map for global.difficulty, keeping only the layouts and sins whose file
///	difficulty is at or below it (R19).
/// @param {struct} _cache The layout cache (see mapgen_cache_layouts)
/// @returns {struct} The map
function mapgen_create_map() {
	static _cache = mapgen_cache_layouts();
	
	var _map = {
		// Layouts this difficulty allows, sin layouts aside, by exit kind, and how many rooms use each (R20)
		layouts_by_exit_type: [],
		layout_use_counts: array_create(array_length(_cache.layouts), 0),
		// Sins with a layout this difficulty allows, each with those layouts
		
		// Map-wide events (step 2)
		same_skeleton_type: noone,
		cursed_item_count: 0,
		available_sins: [],
		sins: [],

		// The room graph (steps 3, 4 and 6)
		rooms: [],
		room_at_cell: {},						// Each room by its grid cell ("x,y"), so finding a neighbor needs no search
		side_links: [],							// Every exit joining two grid neighbors
		stairs_links: [],						// Every exit joining two rooms by stairs

		// Decorations, redone on every pass of step 6
		start_room: undefined,
		heart_room: undefined,
		guaranteed_chest_room: undefined,
		cursed_items: [],						// Each cursed item type placed so far
		difficulty_score: 0,

		// What the controller keeps once generation ends
		time_provided: 0,
		rooms_with_collectables: [],
		spawned_items: [],
		spawned_special_items: []
	};

	// Initialize layouts by exit type with blank arrays
	for (var _type = 0; _type < mapgen_exit_types.count; _type++) { array_push(_map.layouts_by_exit_type, []); }
	
	// Assign the cached layouts to their appropriate layout by exit type array, if difficulty allows
	for (var _i = 0; _i < array_length(_cache.layouts); _i++) {
		var _layout = _cache.layouts[_i];
		if (_layout.file_difficulty <= global.difficulty && !_layout.is_sin_room) {
			array_push(_map.layouts_by_exit_type[_layout.exit_type], _layout);
		}
	}
	
	// For each sin type, assign the layouts to the available sin types. if difficulty allows
	for (var _j = 0; _j < array_length(_cache.sins); _j++) {
		var _sin = _cache.sins[_j], _allowed_layouts = [];
		
		for (var _k = 0; _k < array_length(_sin.layouts); _k++) {
			if (_sin.layouts[_k].file_difficulty <= global.difficulty) { array_push(_allowed_layouts, _sin.layouts[_k]); }
		}
		if (array_length(_allowed_layouts) > 0) { array_push(_map.available_sins, { name: _sin.name, layouts: _allowed_layouts }); }
	}

	// Check that every exit type has at least one layout, and at least one layout with a lantern. This should always be true, but good to check.
	for (var _type_checked = 0; _type_checked < mapgen_exit_types.count; _type_checked++) {
		var _layouts_of_type = _map.layouts_by_exit_type[_type_checked];
		if (array_length(_layouts_of_type) == 0) {
			write_debug_message("No layout of exit kind " + string(_type_checked) + " at this difficulty.", "ERROR");
		}
		
		if (array_length(mapgen_select_lantern_layouts(_layouts_of_type)) == 0) {
			write_debug_message("No lantern layout of exit kind " + string(_type_checked) + " at this difficulty.", "WARNING");
		}
	}
	return _map;
}

/// @function mapgen_create_room(_map, _x, _y)
/// @description Adds a room on a free grid cell, with no exits or layout yet (R3).
/// @param {struct} _map The map being generated
/// @param {real} _x The grid column
/// @param {real} _y The grid row
/// @returns {GameRoom} The new room
function mapgen_create_room(_map, _x, _y) {
	var _room = new GameRoom(_x, _y);
	_room.mapgen_index = array_length(_map.rooms);	// Its position in _map.rooms
	_room.mapgen_sin = undefined;					// The sin reserved for it (step 4)
	_room.mapgen_needs_layout = true;				// Its side exits changed since its last layout pick (R16)
	_room.mapgen_content = undefined;				// What step 5 rolled for its layout
	_room.mapgen_chest_lock = -1;					// Its locked chest's number in the key check
	array_push(_map.rooms, _room);
	_map.room_at_cell[$ mapgen_cell_key(_x, _y)] = _room;
	return _room;
}

/// @function mapgen_link_rooms(_map, _room, _other_room, _dir)
/// @description Joins two rooms with a new exit, on a side or by stairs.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room One room
/// @param {GameRoom} _other_room The other room
/// @param {real} _dir The direction from _room to _other_room, or directions.stairs
/// @returns {RoomExit} The new exit
function mapgen_link_rooms(_map, _room, _other_room, _dir) {
	var _exit = new RoomExit(_room, _other_room);
	_room.exits[_dir] = _exit;
	_other_room.exits[get_opposite_dir(_dir)] = _exit;
	if (_dir == directions.stairs) {
		array_push(_map.stairs_links, _exit);
	}
	else {
		array_push(_map.side_links, _exit);
		// A layout depends on the room's side exits, so both rooms need a new one (R16)
		_room.mapgen_needs_layout = true;
		_other_room.mapgen_needs_layout = true;
	}
	return _exit;
}

/// @function mapgen_cell_key(_x, _y)
/// @description The key a grid cell has in a struct of cells, like the map's room_at_cell.
/// @param {real} _x The grid column, or x position
/// @param {real} _y The grid row, or y position
/// @returns {string}
function mapgen_cell_key(_x, _y) {
	return string(_x) + "," + string(_y);
}

/// @function mapgen_get_room_at(_map, _x, _y)
/// @description The room on a grid cell.
/// @param {struct} _map The map being generated
/// @param {real} _x The grid column
/// @param {real} _y The grid row
/// @returns {GameRoom|undefined} The room, or undefined if the cell is free
function mapgen_get_room_at(_map, _x, _y) {
	return _map.room_at_cell[$ mapgen_cell_key(_x, _y)];
}

/// @function mapgen_get_neighbor(_map, _room, _dir)
/// @description The room on the grid cell beside a room, linked to it or not.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @param {real} _dir A side direction
/// @returns {GameRoom|undefined} The neighbor, or undefined if the cell is free
function mapgen_get_neighbor(_map, _room, _dir) {
	return mapgen_get_room_at(_map, _room.virtual_x + get_dir_x_offset(_dir), _room.virtual_y + get_dir_y_offset(_dir));
}


// =====================================================================================================
// STEP 2: MAP-WIDE EVENTS, SINS AND CURSED ITEMS
// =====================================================================================================

/// @function mapgen_roll_run_events(_map)
/// @description Rolls everything decided once per run, before any room content (R21): the map-wide events,
///	the run's sins, and how many cursed items spawn outside sin rooms.
/// @param {struct} _map The map being generated
function mapgen_roll_run_events(_map) {
	// Every skeleton spot spawns the same variant this run (H 1 in 32, VH 1 in 24)
	_map.same_skeleton_type = get_random_chance_out_of(SAME_SKELETON_TYPE_FREQUENCY) ? get_skeleton_type(false) : noone;

	// The run's sins: how many at today's odds, then each picked with equal odds among the available
	// sins, never the same one twice (R23, R24)
	var _sins_left = mapgen_copy_array(_map.available_sins);
	var _sin_count = min(mapgen_roll_count(SIN_ROOM_COUNT_PERCENTAGES), array_length(_sins_left));
	for (var _i = 0; _i < _sin_count; _i++) {
		array_push(_map.sins, array_random_pop(_sins_left));
	}

	// Cursed items outside sin rooms, at today's odds, capped so the map holds at most 1/1/2/3 cursed
	// items counting the sin rooms' (R40)
	var _cursed_items_allowed = max(0, SPECIAL_ITEM_LIMIT - _sin_count);
	_map.cursed_item_count = min(mapgen_roll_count(CURSED_ITEM_COUNT_PERCENTAGES), _cursed_items_allowed);
}

/// @function mapgen_roll_count(_percentages)
/// @description Rolls how many of something a map gets, from the percent of maps that get exactly 1, 2,
///	3 and so on. The remaining maps get none.
/// @param {array} _percentages Percent of maps with exactly 1, 2, 3...
/// @returns {real}
function mapgen_roll_count(_percentages) {
	var _roll = random(100);
	for (var _i = 0; _i < array_length(_percentages); _i++) {
		_roll -= _percentages[_i];
		if (_roll < 0) { return _i + 1; }
	}
	return 0;
}


// =====================================================================================================
// STEPS 3 AND 4: GROW THE GRAPH, ADD SIDE LINKS AND RESERVE SIN ROOMS
// =====================================================================================================

/// @function mapgen_grow_room(_map, _allow_stairs)
/// @description Adds one room, joined to a random room by a side exit or, about 1 in 5 times, by stairs.
///	Steps 3, 4 and 6 all grow rooms this way, so every room comes from one process.
/// @param {struct} _map The map being generated
/// @param {bool} _allow_stairs False to always join by a side exit
/// @returns {GameRoom|undefined} The new room, or undefined if no room can grow
function mapgen_grow_room(_map, _allow_stairs) {
	// Stairs never take the last room the start could use, since the start has no stairs (R11)
	var _stairs_allowed = _allow_stairs && (mapgen_count_possible_starts(_map) > 1);
	var _parents = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_parents); _i++) {
		var _parent = _parents[_i];
		if (!mapgen_can_gain_exits(_parent)) { continue; }

		// About 1 in 5 growths use stairs, and a room has at most one stairs exit (R6, R7)
		if (_stairs_allowed && !_parent.has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			var _cell = mapgen_find_stairs_cell(_map, _parent);
			if (!is_undefined(_cell)) {
				var _stairs_room = mapgen_create_room(_map, _cell[0], _cell[1]);
				mapgen_link_rooms(_map, _parent, _stairs_room, directions.stairs);
				// 1 in 12/8/6/4 new stairs rooms are reached only by stairs, and never get a side exit (R7, R8)
				_stairs_room.has_no_cardinal_exits = get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY);
				return _stairs_room;
			}
		}

		var _dir = mapgen_pick_free_direction(_map, _parent);
		if (_dir != -1) {
			var _side_room = mapgen_create_room(_map, _parent.virtual_x + get_dir_x_offset(_dir), _parent.virtual_y + get_dir_y_offset(_dir));
			mapgen_link_rooms(_map, _parent, _side_room, _dir);
			return _side_room;
		}
	}
	return undefined;
}

/// @function mapgen_find_stairs_cell(_map, _parent)
/// @description Finds a free grid cell for a room reached by stairs from _parent: beside some room that is
///	neither the parent nor its grid neighbor, and never beside the parent itself, since stairs never join
///	grid neighbors (R6). Skipping the parent's neighbors, as today's code does, keeps stairs as common as
///	they are today.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _parent The room the stairs leave from
/// @returns {array|undefined} The cell as [x, y], or undefined if there is none
function mapgen_find_stairs_cell(_map, _parent) {
	var _anchors = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_anchors); _i++) {
		var _anchor = _anchors[_i];
		if (abs(_anchor.virtual_x - _parent.virtual_x) + abs(_anchor.virtual_y - _parent.virtual_y) <= 1) { continue; }

		var _dirs = array_shuffle(mapgen_get_side_directions());
		for (var _j = 0; _j < array_length(_dirs); _j++) {
			var _x = _anchor.virtual_x + get_dir_x_offset(_dirs[_j]);
			var _y = _anchor.virtual_y + get_dir_y_offset(_dirs[_j]);
			var _is_beside_parent = (abs(_x - _parent.virtual_x) + abs(_y - _parent.virtual_y) == 1);
			if (!_is_beside_parent && is_undefined(mapgen_get_room_at(_map, _x, _y))) { return [_x, _y]; }
		}
	}
	return undefined;
}

/// @function mapgen_pick_free_direction(_map, _room)
/// @description Picks a random side of a room whose grid cell is free.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {real} The direction, or -1 if every side is taken
function mapgen_pick_free_direction(_map, _room) {
	var _dirs = array_shuffle(mapgen_get_side_directions());
	for (var _i = 0; _i < array_length(_dirs); _i++) {
		if (is_undefined(mapgen_get_neighbor(_map, _room, _dirs[_i]))) { return _dirs[_i]; }
	}
	return -1;
}

/// @function mapgen_can_gain_exits(_room)
/// @description Whether a room may still gain exits. Stairs-only rooms never get a side exit (R8), and a
///	sin room's exits stay fixed once reserved, so its sin layout keeps fitting (step 6).
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_gain_exits(_room) {
	return !_room.has_no_cardinal_exits && !_room.is_special_room;
}

/// @function mapgen_add_side_links(_map)
/// @description Links grid neighbors until rooms average 20/9 side exits. It simply stops if no more links
///	fit, since the average is only a target (R4).
/// @param {struct} _map The map being generated
function mapgen_add_side_links(_map) {
	while (2 * array_length(_map.side_links) / array_length(_map.rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
		if (!mapgen_add_side_link(_map)) { return; }
	}
}

/// @function mapgen_add_side_link(_map)
/// @description Links a random room to one of its unlinked grid neighbors. Two rooms share one link at
///	most (R9), and side exits only join grid neighbors (R3).
/// @param {struct} _map The map being generated
/// @returns {bool} False if no more links fit
function mapgen_add_side_link(_map) {
	var _rooms = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (!mapgen_can_gain_exits(_room)) { continue; }

		var _dirs = array_shuffle(mapgen_get_side_directions());
		for (var _j = 0; _j < array_length(_dirs); _j++) {
			var _dir = _dirs[_j];
			if (_room.has_exit(_dir)) { continue; }
			var _neighbor = mapgen_get_neighbor(_map, _room, _dir);
			if (!is_undefined(_neighbor) && mapgen_can_gain_exits(_neighbor)) {
				mapgen_link_rooms(_map, _room, _neighbor, _dir);
				return true;
			}
		}
	}
	return false;
}

/// @function mapgen_reserve_sin_rooms(_map)
/// @description Reserves a room for each of the run's sins, one with no stairs whose real side exits fit one
///	of the sin's layouts (R23, R24). If no room fits, it shapes one.
/// @param {struct} _map The map being generated
/// @returns {bool} False if a sin got no room
function mapgen_reserve_sin_rooms(_map) {
	for (var _i = 0; _i < array_length(_map.sins); _i++) {
		var _sin = _map.sins[_i];
		var _room = mapgen_find_room_for_sin(_map, _sin);
		if (is_undefined(_room)) { _room = mapgen_shape_room_for_sin(_map, _sin); }
		if (is_undefined(_room)) { return false; }
		_room.is_special_room = true;
		_room.mapgen_sin = _sin;
	}

	// A sin room may have taken the last room the start could use (R11); if so, grow a new one
	if (mapgen_count_possible_starts(_map) == 0 && is_undefined(mapgen_grow_room(_map, false))) { return false; }
	return true;
}

/// @function mapgen_find_room_for_sin(_map, _sin)
/// @description Picks a random room that fits a sin: no stairs (R23), not reserved yet, and real side exits
///	that one of the sin's layouts has.
/// @param {struct} _map The map being generated
/// @param {struct} _sin The sin
/// @returns {GameRoom|undefined} The room, or undefined if none fits
function mapgen_find_room_for_sin(_map, _sin) {
	var _fitting_rooms = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (_room.is_special_room || _room.has_exit(directions.stairs)) { continue; }
		if (mapgen_sin_has_exit_type(_sin, mapgen_get_exit_type(_room))) { array_push(_fitting_rooms, _room); }
	}
	return (array_length(_fitting_rooms) > 0) ? array_random_get(_fitting_rooms) : undefined;
}

/// @function mapgen_shape_room_for_sin(_map, _sin)
/// @description Shapes a room for a sin that no room fits: a new dead end for a sin with a one-exit layout,
///	or else (the hall of mirrors) a room given four real exits.
/// @param {struct} _map The map being generated
/// @param {struct} _sin The sin
/// @returns {GameRoom|undefined} The room, or undefined if none could be shaped
function mapgen_shape_room_for_sin(_map, _sin) {
	if (mapgen_sin_has_exit_type(_sin, mapgen_exit_types.one)) {
		if (array_length(_map.rooms) >= MAX_NUMBER_OF_ROOMS) { return undefined; }
		return mapgen_grow_room(_map, false);
	}
	if (mapgen_sin_has_exit_type(_sin, mapgen_exit_types.four)) { return mapgen_build_four_exit_room(_map); }
	return undefined; // Today's sin table needs no other shape
}

/// @function mapgen_build_four_exit_room(_map)
/// @description Gives the room closest to four real side exits the rest: links its unlinked neighbors and
///	adds new rooms on its free sides (step 4, R27).
/// @param {struct} _map The map being generated
/// @returns {GameRoom|undefined} The room, or undefined if no room can reach four exits
function mapgen_build_four_exit_room(_map) {
	// The candidate missing the fewest exits, among rooms whose every missing side can open
	var _best_room = undefined, _fewest_missing = 5;
	var _rooms = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (_room.is_special_room || _room.has_exit(directions.stairs)) { continue; }
		var _missing = mapgen_count_openable_missing_sides(_map, _room);
		if (_missing != -1 && _missing < _fewest_missing) {
			_best_room = _room;
			_fewest_missing = _missing;
		}
	}
	if (is_undefined(_best_room)) { return undefined; }
	if (array_length(_map.rooms) + mapgen_count_free_sides(_map, _best_room) > MAX_NUMBER_OF_ROOMS) { return undefined; }

	// Link each missing side to its neighbor, or to a new room where the cell is free
	var _dirs = mapgen_get_side_directions();
	for (var _j = 0; _j < array_length(_dirs); _j++) {
		var _dir = _dirs[_j];
		if (_best_room.has_exit(_dir)) { continue; }
		var _neighbor = mapgen_get_neighbor(_map, _best_room, _dir);
		if (is_undefined(_neighbor)) {
			_neighbor = mapgen_create_room(_map, _best_room.virtual_x + get_dir_x_offset(_dir), _best_room.virtual_y + get_dir_y_offset(_dir));
		}
		mapgen_link_rooms(_map, _best_room, _neighbor, _dir);
	}
	return _best_room;
}

/// @function mapgen_count_openable_missing_sides(_map, _room)
/// @description Counts a room's sides without an exit, if each can get one: its cell is free, or its
///	neighbor can gain exits.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {real} How many sides are missing, or -1 if one of them can never open
function mapgen_count_openable_missing_sides(_map, _room) {
	var _missing = 0, _dirs = mapgen_get_side_directions();
	for (var _i = 0; _i < array_length(_dirs); _i++) {
		if (_room.has_exit(_dirs[_i])) { continue; }
		var _neighbor = mapgen_get_neighbor(_map, _room, _dirs[_i]);
		if (!is_undefined(_neighbor) && !mapgen_can_gain_exits(_neighbor)) { return -1; }
		_missing += 1;
	}
	return _missing;
}

/// @function mapgen_count_free_sides(_map, _room)
/// @description Counts the sides of a room whose grid cell is free.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {real}
function mapgen_count_free_sides(_map, _room) {
	var _free = 0, _dirs = mapgen_get_side_directions();
	for (var _i = 0; _i < array_length(_dirs); _i++) {
		if (is_undefined(mapgen_get_neighbor(_map, _room, _dirs[_i]))) { _free += 1; }
	}
	return _free;
}

/// @function mapgen_sin_has_exit_type(_sin, _exit_type)
/// @description Whether one of a sin's layouts has a given exit kind.
/// @param {struct} _sin The sin
/// @param {real} _exit_type A mapgen_exit_types kind
/// @returns {bool}
function mapgen_sin_has_exit_type(_sin, _exit_type) {
	for (var _i = 0; _i < array_length(_sin.layouts); _i++) {
		if (_sin.layouts[_i].exit_type == _exit_type) { return true; }
	}
	return false;
}


// =====================================================================================================
// STEP 5: LAYOUTS AND ROLLED CONTENT
// =====================================================================================================

/// @function mapgen_pick_layouts(_map)
/// @description Picks a layout, and rolls its content, for every room whose side exits changed since its
///	last pick, so each room picks once plus once per change (R16). Sin rooms pick first so their layouts
///	are reserved. If no other non-sin room has lanterns, the last pick must, which keeps a lantern room on
///	every map (R28).
/// @param {struct} _map The map being generated
function mapgen_pick_layouts(_map) {
	var _shuffled_rooms = array_shuffle(_map.rooms), _rooms_to_pick = [];
	for (var _i = 0; _i < array_length(_shuffled_rooms); _i++) {
		var _sin_room = _shuffled_rooms[_i];
		if (_sin_room.mapgen_needs_layout && _sin_room.is_special_room) { array_push(_rooms_to_pick, _sin_room); }
	}
	for (var _j = 0; _j < array_length(_shuffled_rooms); _j++) {
		var _other_room = _shuffled_rooms[_j];
		if (_other_room.mapgen_needs_layout && !_other_room.is_special_room) { array_push(_rooms_to_pick, _other_room); }
	}

	for (var _k = 0; _k < array_length(_rooms_to_pick); _k++) {
		var _room = _rooms_to_pick[_k];
		var _is_last_pick = (_k == array_length(_rooms_to_pick) - 1);
		var _needs_lanterns = _is_last_pick && !_room.is_special_room && !mapgen_has_other_lantern_room(_map, _room);
		mapgen_pick_layout(_map, _room, _needs_lanterns);
		mapgen_roll_room_content(_map, _room);
	}
}

/// @function mapgen_pick_layout(_map, _room, _needs_lanterns)
/// @description Picks a room's layout and how it is flipped and rotated. The layout matches the room's
///	real side exits (R17) unless misleading exits apply (R18), sin rooms use their sin's layout (R24),
///	and layouts repeat only when every fitting one is in use by another room (R20).
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @param {bool} _needs_lanterns Whether the layout must have lanterns
function mapgen_pick_layout(_map, _room, _needs_lanterns) {
	// Free the old layout, so it no longer counts as in use (R20)
	if (!is_undefined(_room.layout)) { _map.layout_use_counts[_room.layout.index] -= 1; }

	var _real_exit_type = mapgen_get_exit_type(_room), _candidates;
	if (_room.is_special_room) {
		// A sin room uses its sin's layout for its real exits, never a misleading one (R24, R27)
		_candidates = mapgen_keep_layouts_of_type(_room.mapgen_sin.layouts, _real_exit_type);
	}
	else {
		_candidates = _map.layouts_by_exit_type[mapgen_roll_layout_exit_type(_room)];
		if (_needs_lanterns) {
			var _lantern_layouts = mapgen_select_lantern_layouts(_candidates);
			if (array_length(_lantern_layouts) > 0) { _candidates = _lantern_layouts; }
		}
	}

	var _layout = mapgen_choose_unused_layout(_map, _candidates);
	_map.layout_use_counts[_layout.index] += 1;
	_room.layout = _layout;
	_room.room_reference = _layout.room_reference;
	_room.has_lanterns = _layout.has_lanterns;
	_room.has_hall_of_mirrors = _layout.is_hall_of_mirrors;
	_room.has_misleading_exits = (_layout.exit_type != _real_exit_type);	// Describes only the layout in use (R18)
	_room.mapgen_needs_layout = false;
	mapgen_roll_layout_orientation(_room);
}

/// @function mapgen_roll_layout_exit_type(_room)
/// @description Rolls which exit kind of layout a non-sin room uses. From M, 1 in 12/6/4 picks use a
///	misleading layout: the exit count steps one way, more or fewer, and keeps stepping while further rolls
///	succeed, always staying at 1 to 4 exits (R18).
/// @param {GameRoom} _room The room
/// @returns {real} A mapgen_exit_types kind
function mapgen_roll_layout_exit_type(_room) {
	var _exit_count = _room.get_cardinal_exits_count();
	if (get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) {
		var _step = get_coin_flip() ? 1 : -1;
		if (_exit_count == 0) { _step = 1; }
		if (_exit_count == 4) { _step = -1; }
		while (_exit_count + _step >= 1 && _exit_count + _step <= 4) {
			_exit_count += _step;
			if (!get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) { break; }
		}
	}
	return mapgen_get_exit_type_for_count(_exit_count, mapgen_has_opposite_exits(_room));
}

/// @function mapgen_choose_unused_layout(_map, _candidates)
/// @description Picks a random layout, preferring one no other room uses (R20).
/// @param {struct} _map The map being generated
/// @param {array} _candidates The layouts that fit
/// @returns {struct} The layout record
function mapgen_choose_unused_layout(_map, _candidates) {
	var _unused = [];
	for (var _i = 0; _i < array_length(_candidates); _i++) {
		if (_map.layout_use_counts[_candidates[_i].index] == 0) { array_push(_unused, _candidates[_i]); }
	}
	return array_random_get((array_length(_unused) > 0) ? _unused : _candidates);
}

/// @function mapgen_roll_layout_orientation(_room)
/// @description Rolls how a room's layout is flipped and rotated, so its openings face the room's real
///	side exits; the build step turns walls into openings to match.
/// @param {GameRoom} _room The room
function mapgen_roll_layout_orientation(_room) {
	var _up = _room.has_exit(directions.up), _right = _room.has_exit(directions.right);
	var _down = _room.has_exit(directions.down), _left = _room.has_exit(directions.left);
	_room.flip_horizontal = false;
	_room.flip_vertical = false;
	_room.rotate = noone;

	switch (_room.get_cardinal_exits_count()) {
		case 0:
		case 4:
			// Any orientation fits
			_room.flip_horizontal = get_coin_flip();
			_room.flip_vertical = get_coin_flip();
			_room.rotate = get_random_carindal_dir();
			break;
		case 1:
			// Turn the layout's one opening toward the one exit
			_room.flip_horizontal = get_coin_flip();
			_room.rotate = mapgen_get_first_side(_room, true);
			break;
		case 2:
			if (_up && _down) {
				_room.flip_horizontal = get_coin_flip();
				_room.flip_vertical = get_coin_flip();
			}
			else if (_left && _right) {
				_room.flip_horizontal = get_coin_flip();
				_room.flip_vertical = get_coin_flip();
				_room.rotate = get_coin_flip() ? directions.right : directions.left;
			}
			else {
				// The layout opens up and right; flip it onto the room's corner
				_room.flip_horizontal = _left;
				_room.flip_vertical = _down;
			}
			break;
		case 3:
			// Turn the layout's closed side toward the one missing exit
			_room.flip_vertical = get_coin_flip();
			_room.rotate = (mapgen_get_first_side(_room, false) + 1) % 4;
			break;
	}
}

/// @function mapgen_roll_room_content(_map, _room)
/// @description Rolls a room's content for its layout, once per layout pick (R33): lighting, enemies,
///	fountains, skeleton spots, extra mouths, moving collectables and a hall's mirror sequence. Each pass of
///	step 6 starts from this content (see mapgen_reset_room).
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
function mapgen_roll_room_content(_map, _room) {
	var _layout = _room.layout, _is_sin_room = _room.is_special_room;
	var _content = {
		lit: false,
		has_rolled_eyes: false,
		has_eyes: false,
		has_phantom: false,
		has_floater: false,
		has_moving_collectable: false,
		initial_fountain_count: 0,
		initial_statue_fountain_count: 0,
		initial_nose_count: 0,
		initial_fire_skeleton_count: 0,
		initial_mouth_count: 0,
		skeleton_types: [],
		mirror_directions: []
	};

	// Only lantern rooms can start lit (1 in 4/6/8/12), never sin rooms (R28, L6)
	_content.lit = _layout.has_lanterns && !_is_sin_room && get_random_chance_out_of(PRE_LIT_PROBABILITY);

	// Rolled eyes (VH 1 in 40) stand on a skeleton spot (R31); a layout can also place eyes
	_content.has_rolled_eyes = (_layout.skeleton_spot_count > 0) && get_random_chance_out_of(EYES_PROBABILITY);
	_content.has_eyes = _content.has_rolled_eyes || (_layout.eyes_count > 0);

	// Eyes attack whenever the player moves, and phantoms and floaters force the player to move, so they
	// never share a room. Phantoms haunt unlit lantern rooms; neither spawns in sin rooms (R30, L7)
	_content.has_phantom = _layout.has_lanterns && !_content.lit && !_content.has_eyes && !_is_sin_room && get_random_chance_out_of(PHANTOM_PROBABILITY);
	_content.has_floater = !_content.has_phantom && !_content.has_eyes && !_is_sin_room && get_random_chance_out_of(FLOATER_PROBABILITY);
	_content.has_moving_collectable = get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY);

	// Columns and statues sometimes turn into fountains
	for (var _column = 0; _column < _layout.column_count; _column++) {
		if (get_random_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY)) { _content.initial_fountain_count += 1; }
	}
	for (var _statue = 0; _statue < _layout.statue_count; _statue++) {
		if (get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) { _content.initial_statue_fountain_count += 1; }
	}

	// Noses (M+, 1/2/3 rolls) and fire skeletons (H+) rise only from lava (R32)
	if (_layout.lava_count > 0) {
		for (var _nose_roll = 0; _nose_roll < global.difficulty - 1; _nose_roll++) {
			if (get_random_chance_out_of(NOSE_PROBABILITY)) { _content.initial_nose_count += 1; }
		}
		if (get_random_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY)) { _content.initial_fire_skeleton_count = 1; }
	}

	// Each skeleton spot spawns a skeleton or a rolled variant (L5); rolled eyes take the first spot
	for (var _spot = 0; _spot < _layout.skeleton_spot_count; _spot++) {
		var _spawn = (_spot == 0 && _content.has_rolled_eyes) ? obj_eyes : mapgen_roll_skeleton_type(_map);
		array_push(_content.skeleton_types, _spawn);
	}

	// Each placed mouth brings difficulty-many more
	_content.initial_mouth_count = _layout.mouth_count * (MOUTHS_PER_MOUTH - 1);

	// A hall of mirrors' sequence of exits to take
	if (_layout.is_hall_of_mirrors) {
		for (var _mirror = 0; _mirror < 4; _mirror++) { array_push(_content.mirror_directions, get_random_carindal_dir()); }
	}

	_room.mapgen_content = _content;
}

/// @function mapgen_roll_skeleton_type(_map)
/// @description Rolls what spawns on a skeleton spot: the run's one skeleton type if that event is on,
///	otherwise a skeleton or a variant at this difficulty's odds.
/// @param {struct} _map The map being generated
/// @returns {Asset.GMObject}
function mapgen_roll_skeleton_type(_map) {
	return (_map.same_skeleton_type != noone) ? _map.same_skeleton_type : get_skeleton_type();
}

/// @function mapgen_has_other_lantern_room(_map, _room)
/// @description Whether any non-sin room besides _room has a lantern layout (R28).
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room to leave out
/// @returns {bool}
function mapgen_has_other_lantern_room(_map, _room) {
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _other_room = _map.rooms[_i];
		if (_other_room != _room && !_other_room.is_special_room && !is_undefined(_other_room.layout) && _other_room.layout.has_lanterns) { return true; }
	}
	return false;
}

/// @function mapgen_keep_layouts_of_type(_layouts, _exit_type)
/// @description The layouts with a given exit kind.
/// @param {array} _layouts Layout records
/// @param {real} _exit_type A mapgen_exit_types kind
/// @returns {array}
function mapgen_keep_layouts_of_type(_layouts, _exit_type) {
	var _kept = [];
	for (var _i = 0; _i < array_length(_layouts); _i++) {
		if (_layouts[_i].exit_type == _exit_type) { array_push(_kept, _layouts[_i]); }
	}
	return _kept;
}

/// @function mapgen_select_lantern_layouts(_layouts)
/// @description Returns only the layouts with lanterns from the given layouts
/// @param {array} _layouts Layout records
/// @returns {array}
function mapgen_select_lantern_layouts(_layouts) {
	var _kept = [];
	for (var _i = 0; _i < array_length(_layouts); _i++) {
		if (_layouts[_i].has_lanterns) { array_push(_kept, _layouts[_i]); }
	}
	return _kept;
}


// =====================================================================================================
// STEP 6: START EACH DECORATION PASS FROM THE ROLLED CONTENT
// =====================================================================================================

/// @function mapgen_reset_decorations(_map)
/// @description Clears everything steps 7 to 12 placed, so each pass decorates the current graph starting
///	from each room's rolled content.
/// @param {struct} _map The map being generated
function mapgen_reset_decorations(_map) {
	_map.start_room = undefined;
	_map.heart_room = undefined;
	_map.guaranteed_chest_room = undefined;
	_map.cursed_items = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) { mapgen_reset_room(_map.rooms[_i]); }
	for (var _j = 0; _j < array_length(_map.side_links); _j++) { mapgen_reset_exit(_map.side_links[_j]); }
}

/// @function mapgen_reset_room(_room)
/// @description Gives a room back the content step 5 rolled for its layout, and clears its decorations.
/// @param {GameRoom} _room The room
function mapgen_reset_room(_room) {
	// The rolled content
	var _content = _room.mapgen_content;
	_room.lit = _content.lit;
	_room.has_eyes = _content.has_eyes;
	_room.has_phantom = _content.has_phantom;
	_room.has_floater = _content.has_floater;
	_room.has_moving_collectable = _content.has_moving_collectable;
	_room.initial_fountain_count = _content.initial_fountain_count;
	_room.initial_statue_fountain_count = _content.initial_statue_fountain_count;
	_room.initial_nose_count = _content.initial_nose_count;
	_room.initial_fire_skeleton_count = _content.initial_fire_skeleton_count;
	_room.initial_mouth_count = _content.initial_mouth_count;
	_room.skeleton_types = mapgen_copy_array(_content.skeleton_types);
	_room.mirror_directions = mapgen_copy_array(_content.mirror_directions);
	_room.mirror_count = 0;

	// No decorations yet
	_room.distance_to_start = 9999;
	_room.stairs_spot_obj = -1;
	_room.chest_on_stairs_spot = false;
	_room.chest_obj = -1;
	_room.has_hidden_chest = false;
	_room.has_locked_chest = false;
	_room.has_special_item = false;
	_room.has_key = false;
	_room.key_in_chest = false;
	_room.key_spot = -1;
	_room.has_collectables = false;
	_room.has_portcullis_button = false;
	_room.button_on_stairs_spot = false;
	_room.button_spot = -1;
	_room.room_reference_difficulty = 0;
}

/// @function mapgen_reset_exit(_exit)
/// @description Clears an exit's lock, door, illusion walls and portcullis.
/// @param {RoomExit} _exit The exit
function mapgen_reset_exit(_exit) {
	_exit.has_lock = false;
	_exit.has_door = false;
	_exit.has_illusion_walls = 0;
	_exit.has_portcullis = false;
	_exit.room_1_has_closed_portcullis = false;
	_exit.room_2_has_closed_portcullis = false;
}


// =====================================================================================================
// STEP 7: START AND HEART
// =====================================================================================================

/// @function mapgen_choose_start_and_heart(_map)
/// @description Makes the start and heart the two ends of the longest path, among the pairs the rules
///	allow (R10, R11, R13). A pair's distance is its quickest route, a stairs trip being one step. Then
///	measures every room's distance from the start, places the cross and the encased heart, and makes the
///	start safe (R12).
/// @param {struct} _map The map being generated
/// @returns {bool} False if no pair is allowed
function mapgen_choose_start_and_heart(_map) {
	var _longest = -1, _longest_pairs = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _start = _map.rooms[_i];
		if (!mapgen_can_be_start(_start)) { continue; }
		var _distances = mapgen_measure_distances(_map, _start);
		for (var _j = 0; _j < array_length(_map.rooms); _j++) {
			var _heart = _map.rooms[_j];
			if (!mapgen_can_be_heart(_heart, _start)) { continue; }
			var _distance = _distances[_heart.mapgen_index];
			if (_distance > _longest) {
				_longest = _distance;
				_longest_pairs = [];
			}
			if (_distance == _longest) { array_push(_longest_pairs, [_start, _heart]); }
		}
	}
	if (array_length(_longest_pairs) == 0) { return false; }

	var _pair = array_random_get(_longest_pairs);
	_map.start_room = _pair[0];
	_map.heart_room = _pair[1];
	var _distances_from_start = mapgen_measure_distances(_map, _map.start_room);
	for (var _k = 0; _k < array_length(_map.rooms); _k++) {
		var _room = _map.rooms[_k];
		_room.distance_to_start = _distances_from_start[_room.mapgen_index];
	}
	mapgen_set_spot_object(_map.start_room, obj_cross);
	mapgen_set_spot_object(_map.heart_room, obj_encased_heart);
	mapgen_make_start_room_safe(_map);
	return true;
}

/// @function mapgen_can_be_start(_room)
/// @description Whether a room can be the start: never a room with stairs or a sin room (R11).
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_be_start(_room) {
	return !_room.has_exit(directions.stairs) && !_room.is_special_room;
}

/// @function mapgen_count_possible_starts(_map)
/// @description Counts the rooms that could be the start (R11).
/// @param {struct} _map The map being generated
/// @returns {real}
function mapgen_count_possible_starts(_map) {
	var _count = 0;
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		if (mapgen_can_be_start(_map.rooms[_i])) { _count += 1; }
	}
	return _count;
}

/// @function mapgen_can_be_heart(_heart, _start)
/// @description Whether a room can be the heart for a given start: never a sin room, and never linked by a
///	side exit to the start or a hall of mirrors; stairs into it are fine (R13).
/// @param {GameRoom} _heart The heart candidate
/// @param {GameRoom} _start The start candidate
/// @returns {bool}
function mapgen_can_be_heart(_heart, _start) {
	if (_heart == _start || _heart.is_special_room) { return false; }
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _neighbor = _heart.get_connected_room(_dir);
		if (_neighbor != -1 && (_neighbor == _start || _neighbor.has_hall_of_mirrors)) { return false; }
	}
	return true;
}

/// @function mapgen_measure_distances(_map, _from_room)
/// @description Counts the steps from one room to every other by the quickest route, a stairs trip being
///	one step, ignoring locks.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _from_room The room to measure from
/// @returns {array} Steps to each room, by mapgen_index
function mapgen_measure_distances(_map, _from_room) {
	var _distances = array_create(array_length(_map.rooms), -1);
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
}

/// @function mapgen_make_start_room_safe(_map)
/// @description Removes every generated hazard that could hurt a player who hasn't acted yet from the
///	start room: phantoms, floaters, fountains, rolled eyes, noses and lava fire skeletons. Hazards placed
///	in its layout file stay for now (R12).
/// @param {struct} _map The map being generated
function mapgen_make_start_room_safe(_map) {
	var _start = _map.start_room;
	_start.has_phantom = false;
	_start.has_floater = false;
	_start.initial_fountain_count = 0;
	_start.initial_statue_fountain_count = 0;
	_start.initial_nose_count = 0;
	_start.initial_fire_skeleton_count = 0;
	if (_start.mapgen_content.has_rolled_eyes) {
		// The eyes' skeleton spot gets what would otherwise spawn there
		_start.has_eyes = (_start.layout.eyes_count > 0);
		_start.skeleton_types[0] = mapgen_roll_skeleton_type(_map);
	}
}


// =====================================================================================================
// STEP 8: COLLECTABLES AND THE LIT ROOM
// =====================================================================================================

/// @function mapgen_place_collectables(_map)
/// @description The heart always has collectables (R15), every other room but the start rolls them at
///	1 in 3/3/3/2, and at least ceil(rooms / 4) + 1 rooms get them (R34).
/// @param {struct} _map The map being generated
function mapgen_place_collectables(_map) {
	var _rooms = array_shuffle(_map.rooms), _collectables_rooms = 1;
	_map.heart_room.has_collectables = true;
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (_room != _map.start_room && _room != _map.heart_room && get_random_chance_out_of(COLLECTABLE_PROBABILITY)) {
			_room.has_collectables = true;
			_collectables_rooms += 1;
		}
	}

	var _minimum = ceil(array_length(_map.rooms) / 4) + 1;
	for (var _j = 0; _j < array_length(_rooms) && _collectables_rooms < _minimum; _j++) {
		var _extra_room = _rooms[_j];
		if (_extra_room != _map.start_room && !_extra_room.has_collectables) {
			_extra_room.has_collectables = true;
			_collectables_rooms += 1;
		}
	}
}

/// @function mapgen_ensure_a_lit_room(_map)
/// @description At least one lantern room starts lit; if none rolled lit, lights a random non-sin lantern
///	room and removes its phantom (R28, R29).
/// @param {struct} _map The map being generated
function mapgen_ensure_a_lit_room(_map) {
	var _lantern_rooms = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (!_room.has_lanterns || _room.is_special_room) { continue; }
		if (_room.lit) { return; }
		array_push(_lantern_rooms, _room);
	}
	if (array_length(_lantern_rooms) == 0) {
		write_debug_message("Map has no lantern room to light.", "WARNING");
		return;
	}
	var _lit_room = array_random_get(_lantern_rooms);
	_lit_room.lit = true;
	_lit_room.has_phantom = false;
}


// =====================================================================================================
// STEP 9: CHESTS AND ITEMS
// =====================================================================================================

/// @function mapgen_place_chests(_map)
/// @description Places every chest and picks every item while ignoring the starting hands, so the key check
///	knows where every torch and cursed key is; step 13 fits the items to the hands later. Only rooms other
///	than the start and heart hold a chest, one at most (R35).
/// @param {struct} _map The map being generated
function mapgen_place_chests(_map) {
	var _rooms = array_shuffle(_map.rooms);

	// The guaranteed chest holds a map on E, or a map or compass from M. It may be hidden or locked but is
	// never cursed, so it never goes in a sin room (R36)
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _guaranteed_room = _rooms[_i];
		if (!_guaranteed_room.is_special_room && mapgen_can_hold_chest(_map, _guaranteed_room)) {
			mapgen_add_chest(_guaranteed_room);
			_guaranteed_room.chest_obj = (global.difficulty == difficulties.easy || get_coin_flip()) ? obj_map : obj_compass;
			_map.guaranteed_chest_room = _guaranteed_room;
			break;
		}
	}

	// Each sin room holds a hidden chest with a cursed item, revealed in the sin's own way (R26)
	for (var _j = 0; _j < array_length(_rooms); _j++) {
		var _sin_room = _rooms[_j];
		if (!_sin_room.is_special_room) { continue; }
		mapgen_set_spot_object(_sin_room, obj_hidden_chest);
		_sin_room.has_hidden_chest = true;
		_sin_room.has_special_item = true;
	}

	// Other rooms hold a chest 1 in 5/4/3/2 (R37)
	for (var _k = 0; _k < array_length(_rooms); _k++) {
		var _room = _rooms[_k];
		if (mapgen_can_hold_chest(_map, _room) && get_random_chance_out_of(CHEST_PROBABILITY)) { mapgen_add_chest(_room); }
	}

	mapgen_place_cursed_items(_map, _rooms);

	for (var _m = 0; _m < array_length(_rooms); _m++) {
		var _chest_room = _rooms[_m];

		// Visible chests lock 1 in 12/10/6 (M+), and always when the item is cursed (R39)
		if (_chest_room.stairs_spot_obj == obj_chest) {
			_chest_room.has_locked_chest = _chest_room.has_special_item || get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
		}

		// Plain chests (visible, unlocked and not cursed) hold a statue or fountain trap 1 in 8/4 (H+), but
		// never the guaranteed chest (R41)
		if (_chest_room != _map.guaranteed_chest_room && mapgen_is_plain_chest(_chest_room) && get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) {
			_chest_room.chest_obj = get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY) ? obj_fountain : obj_statue;
		}
	}

	// Every other chest gets an item (R42)
	for (var _n = 0; _n < array_length(_rooms); _n++) {
		var _item_room = _rooms[_n];
		if (mapgen_has_chest(_item_room) && _item_room.chest_obj == -1) {
			_item_room.chest_obj = mapgen_pick_item_type(_map, _item_room.has_special_item, []);
		}
	}
}

/// @function mapgen_place_cursed_items(_map, _rooms)
/// @description Marks exactly the step 2 count of cursed items outside sin rooms, each in a chest at least
///	two rooms from the start, adding chests when too few exist (R40). The guaranteed chest is never
///	cursed (R36).
/// @param {struct} _map The map being generated
/// @param {array} _rooms The map's rooms, in random order
function mapgen_place_cursed_items(_map, _rooms) {
	var _left_to_place = _map.cursed_item_count;

	// Chests already placed
	for (var _i = 0; _i < array_length(_rooms) && _left_to_place > 0; _i++) {
		var _chest_room = _rooms[_i];
		if (mapgen_has_chest(_chest_room) && !_chest_room.has_special_item && _chest_room != _map.guaranteed_chest_room && _chest_room.distance_to_start >= 2) {
			_chest_room.has_special_item = true;
			_left_to_place -= 1;
		}
	}

	// New chests, when too few exist
	for (var _j = 0; _j < array_length(_rooms) && _left_to_place > 0; _j++) {
		var _empty_room = _rooms[_j];
		if (mapgen_can_hold_chest(_map, _empty_room) && _empty_room.distance_to_start >= 2) {
			mapgen_add_chest(_empty_room);
			_empty_room.has_special_item = true;
			_left_to_place -= 1;
		}
	}

	if (_left_to_place > 0) { write_debug_message("No room left for " + string(_left_to_place) + " cursed item(s).", "WARNING"); }
}

/// @function mapgen_add_chest(_room)
/// @description Puts a chest with no item yet in a room. Hidden chests appear only in unlit lantern rooms
///	without a phantom (1 in 2/2/1/1), where lighting every lantern reveals them (R38, L7).
/// @param {GameRoom} _room The room
function mapgen_add_chest(_room) {
	_room.has_hidden_chest = _room.has_lanterns && !_room.lit && !_room.has_phantom && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY);
	mapgen_set_spot_object(_room, _room.has_hidden_chest ? obj_hidden_chest : obj_chest);
}

/// @function mapgen_set_spot_object(_room, _object)
/// @description Places a room's stairs-spot object (the cross, the encased heart or a chest) and rolls which
///	spot it takes, so building never has to (L1, R57). The cross always takes the stairs spot; anything
///	else takes the chest spot, or 1 in 16/8/4/3 the stairs spot when the room has no stairs.
/// @param {GameRoom} _room The room
/// @param {Asset.GMObject} _object What to place
function mapgen_set_spot_object(_room, _object) {
	_room.stairs_spot_obj = _object;
	_room.chest_on_stairs_spot = (_object == obj_cross) || (!_room.has_exit(directions.stairs) && get_random_chance_out_of(CHEST_ON_STAIRS_SPOT_PROBABILITY));
}

/// @function mapgen_pick_item_type(_map, _is_cursed, _hands)
/// @description Picks an item uniformly among the types still allowed (R42). A cursed item can be any
///	type, keys included, but each cursed type appears once at most. A regular item is never a key, and
///	types at their cap, counting chests and the hands, drop out of the pool.
/// @param {struct} _map The map being generated
/// @param {bool} _is_cursed Whether the item is cursed
/// @param {array} _hands The starting hand items to count, or [] to ignore the hands
/// @returns {Asset.GMObject}
function mapgen_pick_item_type(_map, _is_cursed, _hands) {
	var _types = global.available_items[global.difficulty], _choices = [];
	for (var _i = 0; _i < array_length(_types); _i++) {
		var _type = _types[_i];
		if (_is_cursed) {
			if (!array_contains(_map.cursed_items, _type)) { array_push(_choices, _type); }
		}
		else if (_type != obj_key && mapgen_count_regular_items(_map, _type, _hands) < mapgen_get_item_cap(_type)) {
			array_push(_choices, _type);
		}
	}
	if (array_length(_choices) == 0) {
		write_debug_message("No item type left to pick, so a torch spawns instead.", "WARNING");
		return obj_torch;
	}

	var _item = array_random_get(_choices);
	if (_is_cursed) { array_push(_map.cursed_items, _item); }
	return _item;
}

/// @function mapgen_count_regular_items(_map, _type, _hands)
/// @description Counts the regular (non-cursed) copies of an item in chests and hands. Keys and bombs the
///	key step placed don't count, and neither does the torch a player gets for bringing a map and a compass,
///	which may go over the cap (step 13).
/// @param {struct} _map The map being generated
/// @param {Asset.GMObject} _type The item
/// @param {array} _hands The starting hand items to count
/// @returns {real}
function mapgen_count_regular_items(_map, _type, _hands) {
	var _count = 0;
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (_room == _map.guaranteed_chest_room && _map.guaranteed_torch_ignores_cap) { continue; }
		if (_room.chest_obj == _type && !_room.has_special_item && !_room.key_in_chest) { _count += 1; }
	}
	for (var _j = 0; _j < array_length(_hands); _j++) {
		if (_hands[_j] == _type) { _count += 1; }
	}
	return _count;
}

/// @function mapgen_get_item_cap(_item)
/// @description How many regular copies of an item chests and starting hands may hold together (R42).
/// @param {Asset.GMObject} _item The item
/// @returns {real}
function mapgen_get_item_cap(_item) {
	switch (_item) {
		case obj_map:
		case obj_compass:
		case obj_staff:
		case obj_clock:
			return 1;
		case obj_shovel:
		case obj_torch:
			return 2;
		default:
			return infinity;
	}
}

/// @function mapgen_can_hold_chest(_map, _room)
/// @description Whether a room can take a chest: never the start or heart, and one chest per room (R35).
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_hold_chest(_map, _room) {
	return _room != _map.start_room && _room != _map.heart_room && _room.stairs_spot_obj == -1;
}

/// @function mapgen_has_chest(_room)
/// @description Whether a room holds a chest, hidden or not.
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_has_chest(_room) {
	return _room.stairs_spot_obj == obj_chest || _room.stairs_spot_obj == obj_hidden_chest;
}

/// @function mapgen_is_plain_chest(_room)
/// @description Whether a room holds a visible chest that is neither locked nor cursed.
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_is_plain_chest(_room) {
	return _room.stairs_spot_obj == obj_chest && !_room.has_locked_chest && !_room.has_special_item;
}

/// @function mapgen_is_trap(_chest_obj)
/// @description Whether a chest holds a trap instead of an item (R41).
/// @param {Asset.GMObject} _chest_obj What the chest holds
/// @returns {bool}
function mapgen_is_trap(_chest_obj) {
	return _chest_obj == obj_statue || _chest_obj == obj_fountain;
}


// =====================================================================================================
// STEPS 10 AND 11: LOCKS AND KEYS
// =====================================================================================================

/// @function mapgen_place_locks_and_keys(_map)
/// @description Locks every heart side exit, then rolls a random lock on each other side exit, backing each
///	lock with keys before the next is added (R14, R43, R50).
/// @param {struct} _map The map being generated
/// @returns {bool} False if the heart locks could not be backed (a last resort, never expected)
function mapgen_place_locks_and_keys(_map) {
	// Every side exit of the heart is locked; the map only needs enough keys to get in once (R14)
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _heart_exit = _map.heart_room.exits[_dir];
		if (_heart_exit != -1) { mapgen_set_lock(_heart_exit, true); }
	}
	if (!mapgen_back_locks_with_keys(_map, undefined)) { return false; }

	// Other side exits lock 1 in 8/6/5/4, one at a time (R43)
	var _exits = array_shuffle(_map.side_links);
	for (var _i = 0; _i < array_length(_exits); _i++) {
		var _exit = _exits[_i];
		if (!mapgen_can_lock_exit(_map, _exit) || !get_random_chance_out_of(LOCKED_DOOR_PROBABILITY / 2)) { continue; }
		mapgen_set_lock(_exit, true);
		if (!mapgen_back_locks_with_keys(_map, _exit)) { return false; }
	}
	return true;
}

/// @function mapgen_back_locks_with_keys(_map, _newest_lock)
/// @description Runs the every-order key check, and wherever the player could get stuck adds a key-role
///	item in the area they're stuck in, until no order of spending keys can strand them (R44, R50). If no
///	room there can take one, the newest lock moves to another eligible exit, so the lock count stays as
///	rolled; dropping it is the last resort, and heart locks never move.
/// @param {struct} _map The map being generated
/// @param {RoomExit|undefined} _newest_lock The random lock just added, or undefined for the heart locks
/// @returns {bool} False if a lock no key can back cannot move either
function mapgen_back_locks_with_keys(_map, _newest_lock) {
	var _tried_exits = [_newest_lock];
	while (true) {
		var _stuck_area = mapgen_check_key_orders(_map);
		if (is_undefined(_stuck_area)) { return true; }
		if (mapgen_add_key_role_item(_map, _stuck_area)) { continue; }

		// No room in the stuck area can take another key, so move the newest lock
		if (is_undefined(_newest_lock)) {
			write_debug_message("No room could take a key for a lock that cannot move.", "WARNING");
			return false;
		}
		mapgen_set_lock(_newest_lock, false);
		_newest_lock = mapgen_pick_untried_lockable_exit(_map, _tried_exits);
		if (is_undefined(_newest_lock)) {
			write_debug_message("Dropped a lock that no key could back (R50).", "WARNING");
			continue;
		}
		mapgen_set_lock(_newest_lock, true);
		array_push(_tried_exits, _newest_lock);
	}
}

/// @function mapgen_add_key_role_item(_map, _stuck_area)
/// @description Adds a key-role item in a random room of a stuck area that can take one: on a random
///	collectable spot, or 1 in 3 in a new plain chest when the room has no chest (R47, R48, R57). From M a
///	bomb can stand in for a chest key, but only where it counts as one (R46, R49).
/// @param {struct} _map The map being generated
/// @param {struct} _stuck_area Where the player is stuck (see mapgen_check_key_orders)
/// @returns {bool} False if no room there can take one
function mapgen_add_key_role_item(_map, _stuck_area) {
	// A room holds at most one key-role item, and the heart holds none (R47)
	var _candidates = [];
	for (var _i = 0; _i < array_length(_stuck_area.rooms); _i++) {
		var _candidate = _stuck_area.rooms[_i];
		if (_candidate != _map.heart_room && !_candidate.has_key && array_length(_candidate.layout.key_spots) > 0) { array_push(_candidates, _candidate); }
	}
	if (array_length(_candidates) == 0) { return false; }

	var _room = array_random_get(_candidates);
	_room.has_key = true;
	if (mapgen_can_hold_chest(_map, _room) && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) {
		// The chest is never locked, hidden or cursed (R48)
		_room.key_in_chest = true;
		mapgen_set_spot_object(_room, obj_chest);
		var _use_bomb = _stuck_area.can_use_bombs && get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY);
		_room.chest_obj = _use_bomb ? obj_bomb : obj_key;
	}
	else {
		_room.key_spot = array_random_get(_room.layout.key_spots);
	}
	return true;
}

/// @function mapgen_can_lock_exit(_map, _exit)
/// @description Whether a random lock can go on a side exit: never on a start-room exit or an exit into a
///	hall of mirrors (R43, R27), and never twice.
/// @param {struct} _map The map being generated
/// @param {RoomExit} _exit A side exit
/// @returns {bool}
function mapgen_can_lock_exit(_map, _exit) {
	var _room_1 = _exit.room_1, _room_2 = _exit.room_2;
	return !_exit.has_lock
		&& _room_1 != _map.start_room && _room_2 != _map.start_room
		&& !_room_1.has_hall_of_mirrors && !_room_2.has_hall_of_mirrors;
}

/// @function mapgen_pick_untried_lockable_exit(_map, _tried_exits)
/// @description Picks a random side exit a lock can move to, among those not tried yet (R50).
/// @param {struct} _map The map being generated
/// @param {array} _tried_exits Exits this lock already tried
/// @returns {RoomExit|undefined} The exit, or undefined if none is left
function mapgen_pick_untried_lockable_exit(_map, _tried_exits) {
	var _candidates = [];
	for (var _i = 0; _i < array_length(_map.side_links); _i++) {
		var _exit = _map.side_links[_i];
		if (mapgen_can_lock_exit(_map, _exit) && !array_contains(_tried_exits, _exit)) { array_push(_candidates, _exit); }
	}
	return (array_length(_candidates) > 0) ? array_random_get(_candidates) : undefined;
}

/// @function mapgen_set_lock(_exit, _is_locked)
/// @description Locks or unlocks a side exit. A locked exit has a door, and plain doors come later
///	(step 12), so unlocking removes the door too.
/// @param {RoomExit} _exit A side exit
/// @param {bool} _is_locked Whether to lock it
function mapgen_set_lock(_exit, _is_locked) {
	_exit.has_lock = _is_locked;
	_exit.has_door = _is_locked;
}

/// @function mapgen_check_key_orders(_map)
/// @description The every-order key check (R44 to R46): looks for any order of spending keys, on locked doors
///	and locked chests alike, that leaves rooms unreached and no key in hand.
///	The search moves through areas: the rooms the player can reach, plus which locked chests that matter
///	they have opened. In the worst order, they spend a key on every lock in the area that leads nowhere new
///	(each locked door inside it, the ones they opened to get there among them, and each locked chest that
///	doesn't matter), as well as on each chest that matters they opened. If that leaves them no key while
///	rooms remain unreached, they are stuck. Otherwise they still hold a key in every order, so they can open
///	a locked door at the area's edge or a chest that matters, and each choice leads to a new area to check.
///	Areas are checked in the order found, so the first stuck area is one near the start.
/// @param {struct} _map The map being generated
/// @returns {struct|undefined} Where the player is stuck, as { rooms, can_use_bombs }, or undefined when
///	every key order reaches every room
function mapgen_check_key_orders(_map) {
	// A locked chest matters if what it holds can change the outcome: a cursed key, or a torch while bombs
	// stand in for keys. Opening any other locked chest only uses up a key, like a locked door inside the area
	var _bombs_stand_in = false;
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		if (_map.rooms[_i].has_key && _map.rooms[_i].key_in_chest && _map.rooms[_i].chest_obj == obj_bomb) { _bombs_stand_in = true; }
	}
	var _locked_doors = [], _chests_that_matter = [];
	for (var _j = 0; _j < array_length(_map.side_links); _j++) {
		if (_map.side_links[_j].has_lock) { array_push(_locked_doors, _map.side_links[_j]); }
	}
	for (var _k = 0; _k < array_length(_map.rooms); _k++) {
		var _room = _map.rooms[_k];
		var _holds_cursed_key = (_room.chest_obj == obj_key && _room.has_special_item);
		var _holds_needed_torch = (_room.chest_obj == obj_torch && _bombs_stand_in);
		_room.mapgen_chest_lock = -1;
		if (_room.has_locked_chest && (_holds_cursed_key || _holds_needed_torch)) {
			_room.mapgen_chest_lock = array_length(_chests_that_matter);
			array_push(_chests_that_matter, _room);
		}
	}

	var _every_room = (1 << array_length(_map.rooms)) - 1;
	var _areas = [], _queued = {};
	mapgen_queue_key_order_area(_areas, _queued, mapgen_reach_rooms(_map, 0, _map.start_room), 0);
	for (var _next = 0; _next < array_length(_areas); _next++) {
		var _area = _areas[_next];
		var _haul = mapgen_count_haul(_map, _area);

		// Nothing left to get stuck on: every room is reached, or a cursed key opens every lock from here (R45)
		if (_area.reached == _every_room || _haul.has_cursed_key) { continue; }

		// The worst order's keys left: the keys collected, minus a key for every lock inside the area and every
		// chest that matters opened. Bombs count as keys only with a lit room and a torch chest in reach (R46)
		var _locks_inside = _haul.locked_chests_that_dont_matter;
		for (var _door = 0; _door < array_length(_locked_doors); _door++) {
			var _door_exit = _locked_doors[_door];
			if (mapgen_is_room_reached(_area.reached, _door_exit.room_1) && mapgen_is_room_reached(_area.reached, _door_exit.room_2)) { _locks_inside += 1; }
		}
		var _can_use_bombs = _haul.has_lit_room && _haul.has_torch_chest;
		var _keys_collected = _haul.keys + (_can_use_bombs ? _haul.bombs : 0);
		var _keys_left = _keys_collected - _locks_inside - mapgen_count_bits(_area.opened_chests);
		if (_keys_left <= 0) { return { rooms: mapgen_list_reached_rooms(_map, _area.reached), can_use_bombs: _can_use_bombs }; }

		// A key opens a locked door at the edge of the area, reaching the rooms behind it...
		for (var _edge = 0; _edge < array_length(_locked_doors); _edge++) {
			var _edge_exit = _locked_doors[_edge];
			var _room_1_reached = mapgen_is_room_reached(_area.reached, _edge_exit.room_1);
			var _room_2_reached = mapgen_is_room_reached(_area.reached, _edge_exit.room_2);
			if (_room_1_reached == _room_2_reached) { continue; }
			var _far_room = _room_1_reached ? _edge_exit.room_2 : _edge_exit.room_1;
			mapgen_queue_key_order_area(_areas, _queued, mapgen_reach_rooms(_map, _area.reached, _far_room), _area.opened_chests);
		}
		// ...or a locked chest that matters, in the area
		for (var _chest = 0; _chest < array_length(_chests_that_matter); _chest++) {
			var _opened_chests = _area.opened_chests | (1 << _chest);
			if (_opened_chests == _area.opened_chests || !mapgen_is_room_reached(_area.reached, _chests_that_matter[_chest])) { continue; }
			mapgen_queue_key_order_area(_areas, _queued, _area.reached, _opened_chests);
		}
	}
	return undefined;
}

/// @function mapgen_queue_key_order_area(_areas, _queued, _reached, _opened_chests)
/// @description Adds an area to the key check's search, unless the same area was already added.
/// @param {array} _areas The areas to check, in order
/// @param {struct} _queued Every area added so far, by its key
/// @param {real} _reached Bitmask of the rooms reached, by mapgen_index
/// @param {real} _opened_chests Bitmask of the locked chests that matter opened
function mapgen_queue_key_order_area(_areas, _queued, _reached, _opened_chests) {
	var _key = string(_reached) + "," + string(_opened_chests);
	if (!is_undefined(_queued[$ _key])) { return; }
	_queued[$ _key] = true;
	array_push(_areas, { reached: _reached, opened_chests: _opened_chests });
}

/// @function mapgen_reach_rooms(_map, _reached, _from_room)
/// @description Adds a room, and every room walkable from it through unlocked exits and stairs, to a set of
///	reached rooms.
/// @param {struct} _map The map being generated
/// @param {real} _reached Bitmask of the rooms already reached, by mapgen_index
/// @param {GameRoom} _from_room The room to walk from
/// @returns {real} The new bitmask
function mapgen_reach_rooms(_map, _reached, _from_room) {
	var _queue = [_from_room];
	_reached |= (1 << _from_room.mapgen_index);
	for (var _next = 0; _next < array_length(_queue); _next++) {
		var _room = _queue[_next];
		for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
			var _exit = _room.exits[_dir];
			if (_exit == -1 || _exit.has_lock) { continue; }
			var _other_room = _exit.get_connected_room(_room);
			if (mapgen_is_room_reached(_reached, _other_room)) { continue; }
			_reached |= (1 << _other_room.mapgen_index);
			array_push(_queue, _other_room);
		}
	}
	return _reached;
}

/// @function mapgen_count_haul(_map, _area)
/// @description Counts what the player can collect in an area of the key check. Key-role items lie on the
///	floor or in plain chests, so reaching their room is enough. A chest's item counts only if the chest is
///	visible, and unlocked or opened; hidden chests never count.
/// @param {struct} _map The map being generated
/// @param {struct} _area The area (see mapgen_queue_key_order_area)
/// @returns {struct} { keys, bombs, has_lit_room, has_torch_chest, has_cursed_key, locked_chests_that_dont_matter }
function mapgen_count_haul(_map, _area) {
	var _haul = { keys: 0, bombs: 0, has_lit_room: false, has_torch_chest: false, has_cursed_key: false, locked_chests_that_dont_matter: 0 };
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (!mapgen_is_room_reached(_area.reached, _room)) { continue; }

		if (_room.has_key) {
			if (_room.key_in_chest && _room.chest_obj == obj_bomb) { _haul.bombs += 1; }
			else { _haul.keys += 1; }
		}
		if (_room.lit) { _haul.has_lit_room = true; }
		if (_room.has_locked_chest && _room.mapgen_chest_lock == -1) { _haul.locked_chests_that_dont_matter += 1; }
		var _is_chest_opened = (_room.mapgen_chest_lock != -1) && ((_area.opened_chests & (1 << _room.mapgen_chest_lock)) != 0);
		var _is_chest_open = (_room.stairs_spot_obj == obj_chest) && (!_room.has_locked_chest || _is_chest_opened);
		if (_is_chest_open && _room.chest_obj == obj_torch) { _haul.has_torch_chest = true; }
		if (_is_chest_open && _room.chest_obj == obj_key && _room.has_special_item) { _haul.has_cursed_key = true; }
	}
	return _haul;
}

/// @function mapgen_is_room_reached(_reached, _room)
/// @description Whether a room is in a bitmask of reached rooms.
/// @param {real} _reached Bitmask of rooms, by mapgen_index
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_is_room_reached(_reached, _room) {
	return (_reached & (1 << _room.mapgen_index)) != 0;
}

/// @function mapgen_list_reached_rooms(_map, _reached)
/// @description The rooms in a bitmask of reached rooms.
/// @param {struct} _map The map being generated
/// @param {real} _reached Bitmask of rooms, by mapgen_index
/// @returns {array}
function mapgen_list_reached_rooms(_map, _reached) {
	var _rooms = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		if (mapgen_is_room_reached(_reached, _map.rooms[_i])) { array_push(_rooms, _map.rooms[_i]); }
	}
	return _rooms;
}

/// @function mapgen_count_bits(_bitmask)
/// @description How many bits are set in a bitmask.
/// @param {real} _bitmask The bitmask
/// @returns {real}
function mapgen_count_bits(_bitmask) {
	var _count = 0;
	while (_bitmask != 0) {
		_bitmask &= _bitmask - 1;	// Clears the lowest set bit
		_count += 1;
	}
	return _count;
}


// =====================================================================================================
// STEP 12: ILLUSION WALLS, PORTCULLIS TRAPS AND PLAIN DOORS
// =====================================================================================================

/// @function mapgen_place_special_exits(_map)
/// @description Adds illusion walls, portcullis traps and plain doors, room by room in random order, as
///	today's code does. An exit holds at most one of them, so each room rolls its illusion walls first, then
///	maybe a trap, then its doors, and what an earlier room placed rules out later rolls on the same exit.
///	None of them change which rooms the player can reach, so they come after the keys. Stairs-only rooms,
///	the start, the heart, halls of mirrors and their neighbors never roll any of them themselves (R54).
/// @param {struct} _map The map being generated
function mapgen_place_special_exits(_map) {
	var _rooms = array_shuffle(_map.rooms), _door_rolled_exits = [];
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (!mapgen_can_roll_special_exits(_map, _room)) { continue; }

		// Illusion walls (H+): 1 in 32/16 for each side exit, never on a door, a lock, a portcullis or an exit
		// into the start (R51)
		for (var _dir = directions.up; _dir <= directions.left; _dir++) {
			var _exit = _room.exits[_dir];
			if (_exit == -1 || _exit.has_door || _exit.room_1_has_closed_portcullis || _exit.room_2_has_closed_portcullis) { continue; }
			if (_exit.get_connected_room(_room) == _map.start_room) { continue; }
			if (get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) { _exit.has_illusion_walls = 1; }
		}

		// A portcullis trap (M+): 1 in 12/8/6 (R52)
		if (mapgen_can_take_portcullis(_map, _room) && get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { mapgen_add_portcullis(_room); }

		// Plain doors: 1 in 64/48/24/16, rolled once per side exit, never on a lock, an illusion wall or a
		// portcullis exit (R53). A room next to the start can still put one on the exit they share
		for (var _door_dir = directions.up; _door_dir <= directions.left; _door_dir++) {
			var _door_exit = _room.exits[_door_dir];
			if (_door_exit == -1 || array_contains(_door_rolled_exits, _door_exit)) { continue; }
			if (_door_exit.has_lock || _door_exit.has_illusion_walls > 0) { continue; }
			if (_room.has_portcullis_button || _door_exit.get_connected_room(_room).has_portcullis_button) { continue; }
			array_push(_door_rolled_exits, _door_exit);
			if (get_random_chance_out_of(OPEN_DOOR_PROBABILITY * 2)) { _door_exit.has_door = true; }
		}
	}
}

/// @function mapgen_can_roll_special_exits(_map, _room)
/// @description Whether a room rolls illusion walls, portcullis traps and plain doors itself (R54).
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_roll_special_exits(_map, _room) {
	return !_room.has_no_cardinal_exits && _room != _map.start_room && _room != _map.heart_room
		&& !_room.has_hall_of_mirrors && !mapgen_is_next_to_hall_of_mirrors(_room);
}

/// @function mapgen_is_next_to_hall_of_mirrors(_room)
/// @description Whether a side exit joins a room to a hall of mirrors.
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_is_next_to_hall_of_mirrors(_room) {
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _neighbor = _room.get_connected_room(_dir);
		if (_neighbor != -1 && _neighbor.has_hall_of_mirrors) { return true; }
	}
	return false;
}

/// @function mapgen_can_take_portcullis(_map, _room)
/// @description Whether a room can take a portcullis trap (R52, R53): it rolls special exits itself (which
///	rules out the start, heart and stairs-only rooms), none of its side exits has a door (locked or plain) or
///	an illusion wall, no neighbor has a trap, and its button has a free spot.
/// @param {struct} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_take_portcullis(_map, _room) {
	if (!mapgen_can_roll_special_exits(_map, _room)) { return false; }
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _exit = _room.exits[_dir];
		if (_exit == -1) { continue; }
		if (_exit.has_door || _exit.has_illusion_walls > 0 || _exit.get_connected_room(_room).has_portcullis_button) { return false; }
	}
	return array_length(mapgen_list_button_spots(_room)) > 0;
}

/// @function mapgen_add_portcullis(_room)
/// @description Traps a room: the portcullis on its side of each side exit closes until the player presses
///	its button. The room loses any phantom or floater, and the button's spot is picked at random from all
///	free spots, so building places it exactly there (R52, R57).
/// @param {GameRoom} _room The room
function mapgen_add_portcullis(_room) {
	_room.has_portcullis_button = true;
	_room.has_phantom = false;
	_room.has_floater = false;
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _exit = _room.exits[_dir];
		if (_exit != -1) { _exit.set_portcullis_to_trigger_for_room(_room, true); }
	}

	var _spot = array_random_get(mapgen_list_button_spots(_room));
	_room.button_on_stairs_spot = (_spot == -1);
	_room.button_spot = _spot;
}

/// @function mapgen_list_button_spots(_room)
/// @description The free spots a room's portcullis button could take (R52, L3): the stairs spot when nothing
///	uses it, and each collectable spot the floor key doesn't take, as long as one stays free for the room's
///	collectables. A spot only counts if nothing else shares its tile, since that could hold the button
///	down. The chest spot never holds a button.
/// @param {GameRoom} _room The room
/// @returns {array} Collectable spot numbers in layout file order, with -1 for the stairs spot
function mapgen_list_button_spots(_room) {
	var _layout = _room.layout, _spots = [];
	if (mapgen_is_stairs_spot_free(_room) && _layout.stairs_spot_is_clear) { array_push(_spots, -1); }

	var _spots_left_by_key = array_length(_layout.key_spots) - ((_room.key_spot != -1) ? 1 : 0);
	if (!_room.has_collectables || _spots_left_by_key >= 2) {
		for (var _i = 0; _i < array_length(_layout.button_spots); _i++) {
			var _spot = _layout.button_spots[_i];
			if (_spot != _room.key_spot) { array_push(_spots, _spot); }
		}
	}
	return _spots;
}

/// @function mapgen_is_stairs_spot_free(_room)
/// @description Whether nothing takes a room's stairs spot: no stairs, and no cross, heart or chest placed
///	on it (L1, L2).
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_is_stairs_spot_free(_room) {
	if (_room.has_exit(directions.stairs)) { return false; }
	return _room.stairs_spot_obj == -1 || !_room.chest_on_stairs_spot;
}


// =====================================================================================================
// STEP 13: SCORE, TIME AND THE STARTING HANDS
// =====================================================================================================

/// @function mapgen_score_map(_map)
/// @description Scores every room and totals the scores (R2, R55).
/// @param {struct} _map The map being generated
/// @returns {real} The map's full score
function mapgen_score_map(_map) {
	var _total_score = 0;
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		_room.room_reference_difficulty = mapgen_score_room(_room);
		_total_score += _room.room_reference_difficulty;
	}
	return _total_score;
}

/// @function mapgen_score_room(_room)
/// @description Scores a room (R55): its layout file's contents, its rolled and placed contents, and its
///	exits. Higher means harder. room_converter.rb weighs layout contents separately to set each file's
///	difficulty.
/// @param {GameRoom} _room The room
/// @returns {real}
function mapgen_score_room(_room) {
	var _layout = _room.layout;

	// Enemies, statues and fountains
	var _score = 0;
	if (_room.has_phantom) { _score += 2; }
	if (_room.has_floater) { _score += 2; }
	if (_room.has_eyes) { _score += 4.5; }												// Placed or rolled
	if (_layout.ears_count > 0) { _score += 4.5; }
	if (_layout.gudetama_count > 0) { _score += 4.5; }
	if (_layout.bumper_count > 0) { _score += 1.25; }
	_score += _layout.mouth_count * 1;													// Placed mouths; the extra ones they bring don't count
	_score += _room.initial_nose_count * 0.75;
	_score += _room.initial_fire_skeleton_count * 1;									// Lava fire skeletons
	if (_layout.spider_spot_count > 0) { _score += 1.5; }
	_score += _layout.spider_count * 1.5;
	_score += (_layout.fountain_count + _room.initial_fountain_count) * 0.5;			// Placed, or turned from columns
	_score += _layout.statue_count * 0.25;												// Plain, or turned fountain
	for (var _i = 0; _i < array_length(_room.skeleton_types); _i++) {
		_score += mapgen_score_skeleton_spot(_room.skeleton_types[_i]);
	}
	_score += _layout.snake_count * 0.66;												// Placed snakes
	_score += (_layout.worm_head_count * 0.1625) + (_layout.worm_body_count * 0.0625);
	if (_score > 0) { _score += 0.25; }													// Any of the above

	// The room's other contents
	if (_room.is_special_room) { _score += 5; }
	if (_room.has_hidden_chest) { _score += 0.125; }
	if (_room.has_lanterns && !_room.has_phantom && !_room.has_hidden_chest) { _score -= 0.125; }
	if (_room.lit) { _score -= 0.125; }
	if (_room.has_locked_chest && !_room.has_special_item) { _score += 0.125; }
	if (_room.has_no_cardinal_exits) { _score += 0.125; }
	if (_room.has_collectables) { _score += 0.25; }
	if (_room.has_misleading_exits) { _score += 0.125; }
	if (mapgen_is_trap(_room.chest_obj)) { _score += 0.325; }
	else if (_room.chest_obj != -1 && !_room.has_key) { _score -= 0.25; }				// A chest with no key-role item
	if (_room.has_special_item) { _score -= 2; }
	_score += (_layout.block_spot_count * 0.08) + (_layout.lava_count * 0.01) + (_layout.bones_count * 0.05) + (_layout.corpse_count * 0.05);

	// Its side exits; each room an exit joins counts it
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _exit = _room.exits[_dir];
		if (_exit == -1) { continue; }
		if (_exit.has_closed_portcullis_for_room(_room)) { _score += 0.325; }
		if (_exit.has_door) { _score += 0.025; }
		if (_exit.has_lock) { _score += 0.125; }
		if (_exit.has_illusion_walls > 0) { _score += 0.25; }
	}
	return _score;
}

/// @function mapgen_score_skeleton_spot(_spawn)
/// @description Scores a skeleton spot by what spawns there, each value replacing the basic skeleton's
///	(R55). A spot holding eyes scores nothing here, since the room's eyes score once.
/// @param {Asset.GMObject} _spawn What spawns on the spot
/// @returns {real}
function mapgen_score_skeleton_spot(_spawn) {
	switch (_spawn) {
		case obj_skeleton: return 0.125;
		case obj_cockroach: return 0.25;
		case obj_fast_skeleton:
		case obj_fat_skeleton:
		case obj_cultist: return 0.325;
		case obj_fire_skeleton: return 0.5;
		case obj_snake: return 0.66;
		default: return 0;
	}
}

/// @function mapgen_total_time(_map)
/// @description The run's time (R56): every room's time added up.
/// @param {struct} _map The map being generated
/// @returns {real} Seconds
function mapgen_total_time(_map) {
	var _time = 0;
	for (var _i = 0; _i < array_length(_map.rooms); _i++) { _time += mapgen_get_room_time(_map.rooms[_i]); }
	return _time;
}

/// @function mapgen_get_room_time(_room)
/// @description A room's share of the run's time (R56): the larger of 12 s and its share by score (a negative
///	score counting as zero), plus time for collectables and for each locked or illusion side exit. A lock
///	or illusion wall counts once in each room it joins, and a portcullis only in its trap room.
/// @param {GameRoom} _room The room, already scored
/// @returns {real} Seconds
function mapgen_get_room_time(_room) {
	var _score_time = TIME_PROVIDED_PER_ROOM * max(0, _room.room_reference_difficulty) / AVERAGE_ROOM_DIFFICULTY;
	var _time = max(MINIMUM_TIME_PROVIDED_PER_ROOM, _score_time);
	if (_room.has_collectables) { _time += TIME_PROVIDED_PER_COLLECTABLE; }
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _exit = _room.exits[_dir];
		if (_exit == -1) { continue; }
		if (_exit.has_lock) { _time += TIME_PROVIEDED_PER_LOCK; }
		if (_exit.has_illusion_walls > 0) { _time += TIME_PROVIEDED_PER_ILLUSION_WALL; }
		if (_exit.has_closed_portcullis_for_room(_room)) { _time += TIME_PROVIEDED_PER_PORTCULLIS; }
	}
	return _time;
}

/// @function mapgen_adjust_items_for_hands(_map)
/// @description The very last step, once the map is final (step 13): fits the chest items to the starting
///	hands. The guaranteed chest becomes the map, compass or torch the hands call for (R36), and any regular
///	item over its cap once the hands count is re-picked (R42). Nothing else changes; the map never relies on
///	the starting items (R45). Runs in its own random stream (see mapgen_generate).
/// @param {struct} _map The finished map
function mapgen_adjust_items_for_hands(_map) {
	var _hands = [global.player_left_hand_item, global.player_right_hand_item];
	var _brings_map = array_contains(_hands, obj_map), _brings_compass = array_contains(_hands, obj_compass);
	var _guaranteed = _map.guaranteed_chest_room;
	if (!is_undefined(_guaranteed)) {
		if (_brings_map && _brings_compass) {
			// This torch may go over the torch cap, so no torch chest a bomb relies on is re-picked because of it
			_guaranteed.chest_obj = obj_torch;
			_map.guaranteed_torch_ignores_cap = true;
		}
		else if (_brings_compass) { _guaranteed.chest_obj = obj_map; }
		else if (_brings_map) { _guaranteed.chest_obj = (global.difficulty == difficulties.easy) ? obj_torch : obj_compass; }
	}

	var _rooms = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (_room == _guaranteed || !mapgen_holds_regular_item(_room)) { continue; }
		if (mapgen_count_regular_items(_map, _room.chest_obj, _hands) > mapgen_get_item_cap(_room.chest_obj)) {
			_room.chest_obj = -1;
			_room.chest_obj = mapgen_pick_item_type(_map, false, _hands);
		}
	}
}

/// @function mapgen_holds_regular_item(_room)
/// @description Whether a room's chest holds a regular item: not cursed, not a trap, and not a key-role
///	item the key step placed.
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_holds_regular_item(_room) {
	return mapgen_has_chest(_room) && !_room.has_special_item && !_room.key_in_chest && !mapgen_is_trap(_room.chest_obj);
}

/// @function mapgen_list_collectables_and_items(_map)
/// @description Lists what the controller tracks during play: the rooms with collectables, and the
///	regular and cursed items in chests.
/// @param {struct} _map The finished map
function mapgen_list_collectables_and_items(_map) {
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (_room.has_collectables) { array_push(_map.rooms_with_collectables, _room); }
		if (mapgen_has_chest(_room) && !mapgen_is_trap(_room.chest_obj)) {
			array_push(_room.has_special_item ? _map.spawned_special_items : _map.spawned_items, _room.chest_obj);
		}
	}
}


// =====================================================================================================
// SMALL HELPERS
// =====================================================================================================

/// @function mapgen_get_side_directions()
/// @description The four side directions, as a new array that is safe to shuffle.
/// @returns {array}
function mapgen_get_side_directions() {
	return [directions.up, directions.right, directions.down, directions.left];
}

/// @function mapgen_get_first_side(_room, _with_exit)
/// @description The first side direction, from up going clockwise, that has (or lacks) an exit.
/// @param {GameRoom} _room The room
/// @param {bool} _with_exit True to find a side with an exit, false to find one without
/// @returns {real} The direction, or -1 if there is none
function mapgen_get_first_side(_room, _with_exit) {
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		if (_room.has_exit(_dir) == _with_exit) { return _dir; }
	}
	return -1;
}

/// @function mapgen_has_opposite_exits(_room)
/// @description Whether a room has side exits on two opposite sides.
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_has_opposite_exits(_room) {
	return (_room.has_exit(directions.up) && _room.has_exit(directions.down))
		|| (_room.has_exit(directions.left) && _room.has_exit(directions.right));
}

/// @function mapgen_get_exit_type(_room)
/// @description The layout exit kind matching a room's real side exits.
/// @param {GameRoom} _room The room
/// @returns {real} A mapgen_exit_types kind
function mapgen_get_exit_type(_room) {
	return mapgen_get_exit_type_for_count(_room.get_cardinal_exits_count(), mapgen_has_opposite_exits(_room));
}

/// @function mapgen_get_exit_type_for_count(_exit_count, _has_opposite_exits)
/// @description The layout exit kind for a number of side exits.
/// @param {real} _exit_count 0 to 4
/// @param {bool} _has_opposite_exits For two exits, whether they are on opposite sides
/// @returns {real} A mapgen_exit_types kind
function mapgen_get_exit_type_for_count(_exit_count, _has_opposite_exits) {
	switch (_exit_count) {
		case 0: return mapgen_exit_types.none;
		case 1: return mapgen_exit_types.one;
		case 2: return _has_opposite_exits ? mapgen_exit_types.two_opposite : mapgen_exit_types.two_perpendicular;
		case 3: return mapgen_exit_types.three;
		default: return mapgen_exit_types.four;
	}
}

/// @function mapgen_copy_array(_array)
/// @description A shallow copy of an array.
/// @param {array} _array The array
/// @returns {array}
function mapgen_copy_array(_array) {
	var _copy = array_create(array_length(_array));
	array_copy(_copy, 0, _array, 0, array_length(_array));
	return _copy;
}