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
/// @description Creates a whole map for global.difficulty
/// @returns {GameMap} The finished map
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

	_map.calculate_collectables_and_items_lists();
	return _map;
}

/// @function mapgen_try_generate()
/// @description Makes one attempt at steps 2 to 13, everything but fitting items to the hands.
/// @returns {GameMap|undefined} The map, or undefined if a last resort failed (its rooms are freed)
function mapgen_try_generate() {
	// Step 1: create initial map using cached version of room layouts read from disk
	var _map = new GameMap();

	// Step 2: determime map-wide events, including sins and cursed items
	mapgen_roll_map_events(_map);

	// Step 3: grow the graph to the minimum room count, without assigning room layouts
	_map.create_room_at_map_position(0, 0);
	while (array_length(_map.rooms) < MINIMUM_NUMBER_OF_ROOMS) {
		if (is_undefined(mapgen_add_new_room(_map, true))) { return mapgen_fail(_map, "no room could grow"); }
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
		_map.calculate_map_difficulty_score();
		if (_map.difficulty_score >= MAP_SCORE_TARGET || array_length(_map.rooms) >= MAX_NUMBER_OF_ROOMS) { break; }
		if (is_undefined(mapgen_add_new_room(_map, true))) { break; }
		mapgen_add_side_links(_map);
		mapgen_pick_layouts(_map);
	}

	// Step 13: the time, from the last pass's scores
	_map.calculate_time_provided();
	return _map;
}

/// @function mapgen_decorate(_map)
/// @description Steps 7 to 12: one decoration pass over the current graph, starting from each room's
///	rolled content.
/// @param {GameMap} _map The map being generated
/// @returns {bool} False if a last resort failed
function mapgen_decorate(_map) {
	_map.reset_decorations();
	if (!mapgen_choose_start_and_heart(_map)) { return false; }		// Step 7
	mapgen_place_collectables(_map);								// Step 8
	mapgen_ensure_a_lit_room(_map);									// Step 8
	mapgen_place_chests(_map);										// Step 9
	if (!mapgen_place_locks_and_keys(_map)) { return false; }		// Steps 10 and 11
	mapgen_place_special_exits(_map);								// Step 12
	return true;
}

/// @function mapgen_fail(_map, _reason)
/// @description Logs a failed attempt and destroys the current map
/// @param {GameMap} _map The map that failed
/// @param {string} _reason What failed
/// @returns {undefined}
function mapgen_fail(_map, _reason) {
	write_debug_message("Map generation attempt failed, retrying on the same random stream: " + _reason, "WARNING");
	_map.destroy();
	return undefined;
}

// =====================================================================================================
// STEP 2: MAP-WIDE EVENTS, SINS AND CURSED ITEMS
// =====================================================================================================

/// @function mapgen_roll_map_events(_map)
/// @description Sets up everything that is decided on a per-map basis, before any room content is created or room references assigned
///	the run's sins, and how many cursed items spawn outside sin rooms.
/// @param {GameMap} _map The map being generated
function mapgen_roll_map_events(_map) {
	// Set Same Skeleton Type Event
	_map.long_and_straight_map = get_random_chance_out_of(SPECIAL_MAP_SHAPE_FREQUENCY); // TODO: Implement this and other shapes. Add eval messages
	_map.same_skeleton_type = get_random_chance_out_of(SAME_SKELETON_TYPE_FREQUENCY) ? get_skeleton_type(false) : noone; // TODO: Add eval messages

	// Set Number of Special Sin Rooms to Include
	var _sins_left = mapgen_copy_array(_map.available_sins), _sin_limit = SPECIAL_ROOM_LIMIT, _sin_count = 0;
	for (var _i = 0; _i < _sin_limit; _i++) {
		if (get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY)) { _sin_count += 1; }
	}
	_sin_count = min(_sin_count, array_length(_sins_left));
	
	// Include one room of a random sin type, for each sin in sin count
	for (var _i = 0; _i < _sin_count; _i++) {
		array_push(_map.included_sins, array_random_pop(_sins_left));
	}

	// Set Number of Additional Special Cursed Items to Spawn outside of Sin Rooms
	var _special_item_limit = SPECIAL_ITEM_LIMIT, _special_item_count = 0;
	for (var _i = _sin_count; _i < _special_item_limit; _i++) {
		if (get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { _special_item_count += 1; }
	}
	_map.cursed_item_count = _special_item_count;
}

// =====================================================================================================
// STEPS 3 AND 4: GROW THE GRAPH, ADD SIDE LINKS AND RESERVE SIN ROOMS
// =====================================================================================================

/// @function mapgen_add_new_room(_map, _allow_stairs)
/// @description Adds one room to the given map, joined to a random room by a side exit or, about 1 in 5 times, by stairs.
/// @param {GameMap} _map The map being generated
/// @param {bool} _allow_stairs False to always join by a side exit
/// @returns {GameRoom|undefined} The new room, or undefined if no room can grow
function mapgen_add_new_room(_map, _allow_stairs) {
	// Stairs never take the last room the start could use, since the start has no stairs
	var _stairs_allowed = _allow_stairs && (_map.count_possible_starts() > 1);
	var _existing_rooms = array_shuffle(_map.rooms), _linked_room = undefined;

	// Check all existing rooms for a room we can add an exit to
	for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
		var _potential_room = _existing_rooms[_i];
		if (!_potential_room.can_gain_exits()) { continue; }

		// Connect via Stairs
		if (_stairs_allowed && !_potential_room.has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			// Find a grid spot to generate the linking room at
			var _cell = mapgen_find_unoccupied_non_adjacent_cell(_map, _potential_room);
			
			// Create new room to link via stairs in that grid cell
			if (!is_undefined(_cell)) {
				_linked_room = _map.create_room_at_map_position(_cell[0], _cell[1]);
				_map.link_rooms(_potential_room, _linked_room, directions.stairs);

				// Set the room to be accessed by stairs only sometimes
				_linked_room.has_no_cardinal_exits = get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY);
			}
		}

		// Otherwise, connect via a cardinal direction
		if (is_undefined(_linked_room)) {
			var _dir = mapgen_find_unoccupied_adjacent_cell_direction(_map, _potential_room);
			if (_dir != -1) {
				var _linked_room = _map.create_room_at_map_position(_potential_room.virtual_x + get_dir_x_offset(_dir), _potential_room.virtual_y + get_dir_y_offset(_dir));
				_map.link_rooms(_potential_room, _linked_room, _dir);
			
				// Return the linked room
				return _linked_room;
			}
		}
		
		if (!is_undefined(_linked_room)) { break; }
	}
	
	// Unable to add new room to map
	return undefined;
}

/// @function mapgen_find_unoccupied_non_adjacent_cell(_map, _linked_room)
/// @description Finds a free grid cell to create a room in while creating a new room that is linked by stairs
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _linked_room The room the stairs leave from
/// @returns {array|undefined} The cell as [x, y], or undefined if there is none
function mapgen_find_unoccupied_non_adjacent_cell(_map, _linked_room) {
	var _existing_rooms = array_shuffle(_map.rooms);
	
	// Check each existing room for an empty adjacent cell 
	for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
		var _potential_room = _existing_rooms[_i];
		
		// Check each position adjacent to this room
		var _dirs = array_shuffle(_map.cardinal_exit_directions);
		for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
			var _x = _potential_room.virtual_x + get_dir_x_offset(_dirs[_dir]);
			var _y = _potential_room.virtual_y + get_dir_y_offset(_dirs[_dir]);
			var _is_adjacent_to_linked_room = (abs(_x - _linked_room.virtual_x) + abs(_y - _linked_room.virtual_y) == 1);
			var _cell_is_already_occupied = !is_undefined(_map.get_room_at(_x, _y));
			
			// Continue to next possible direction if this cell is occuppied or adjacent to the linked room
			if (_is_adjacent_to_linked_room || _cell_is_already_occupied) { continue; }
			
			// Return the current x and y position for making a new room in
			return [_x, _y];
		}
	}
	
	// return undefined if no possible spot is found
	return undefined;
}

/// @function mapgen_find_unoccupied_adjacent_cell_direction(_map, _room)
/// @description Returns a random direction from the given room that leads to an unoccupied adjacent cell
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {real} The direction, or -1 if every side is taken
function mapgen_find_unoccupied_adjacent_cell_direction(_map, _room) {
	// Check the map grid for each space adjacent to the given room
	var _dirs = array_shuffle(_map.cardinal_exit_directions);
	for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
		// If the map grid's cell is unoccupied at this space, return this direction
		if (is_undefined(_map.get_neighbor(_room, _dirs[_dir]))) { return _dirs[_dir]; }
	}
	
	// If no adjacent map grid cells are unoccupied, return -1
	return -1;
}

/// @function mapgen_add_side_links(_map)
/// @description Links grid neighbors until rooms average 20/9 side exits. It simply stops if no more links
///	fit, since the average is only a target (R4).
/// @param {GameMap} _map The map being generated
function mapgen_add_side_links(_map) {
	while (2 * array_length(_map.side_links) / array_length(_map.rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
		if (!mapgen_add_side_link(_map)) { return; }
	}
}

/// @function mapgen_add_side_link(_map)
/// @description Links a random room to one of its unlinked grid neighbors. Two rooms share one link at
///	most (R9), and side exits only join grid neighbors (R3).
/// @param {GameMap} _map The map being generated
/// @returns {bool} False if no more links fit
function mapgen_add_side_link(_map) {
	var _rooms = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (!_room.can_gain_exits()) { continue; }

		var _dirs = array_shuffle(_map.cardinal_exit_directions);
		for (var _j = 0; _j < array_length(_dirs); _j++) {
			var _dir = _dirs[_j];
			if (_room.has_exit(_dir)) { continue; }
			var _neighbor = _map.get_neighbor(_room, _dir);
			if (!is_undefined(_neighbor) && _neighbor.can_gain_exits()) {
				_map.link_rooms(_room, _neighbor, _dir);
				return true;
			}
		}
	}
	return false;
}

/// @function mapgen_reserve_sin_rooms(_map)
/// @description Reserves a room for each of the run's sins, one with no stairs whose real side exits fit one
///	of the sin's layouts (R23, R24). If no room fits, it shapes one.
/// @param {GameMap} _map The map being generated
/// @returns {bool} False if a sin got no room
function mapgen_reserve_sin_rooms(_map) {
	for (var _i = 0; _i < array_length(_map.included_sins); _i++) {
		var _sin = _map.included_sins[_i];
		var _room = mapgen_find_room_for_sin(_map, _sin);
		if (is_undefined(_room)) { _room = mapgen_shape_room_for_sin(_map, _sin); }
		if (is_undefined(_room)) { return false; }
		_room.is_special_room = true;
		_room.mapgen_sin = _sin;
	}

	// A sin room may have taken the last room the start could use (R11); if so, grow a new one
	if (_map.count_possible_starts() == 0 && is_undefined(mapgen_add_new_room(_map, false))) { return false; }
	return true;
}

/// @function mapgen_find_room_for_sin(_map, _sin)
/// @description Picks a random room that fits a sin: no stairs (R23), not reserved yet, and real side exits
///	that one of the sin's layouts has.
/// @param {GameMap} _map The map being generated
/// @param {struct} _sin The sin
/// @returns {GameRoom|undefined} The room, or undefined if none fits
function mapgen_find_room_for_sin(_map, _sin) {
	var _fitting_rooms = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (_room.is_special_room || _room.has_exit(directions.stairs)) { continue; }
		if (mapgen_sin_has_exit_type(_sin, _room.get_exit_type())) { array_push(_fitting_rooms, _room); }
	}
	return (array_length(_fitting_rooms) > 0) ? array_random_get(_fitting_rooms) : undefined;
}

/// @function mapgen_shape_room_for_sin(_map, _sin)
/// @description Shapes a room for a sin that no room fits: a new dead end for a sin with a one-exit layout,
///	or else (the hall of mirrors) a room given four real exits.
/// @param {GameMap} _map The map being generated
/// @param {struct} _sin The sin
/// @returns {GameRoom|undefined} The room, or undefined if none could be shaped
function mapgen_shape_room_for_sin(_map, _sin) {
	if (mapgen_sin_has_exit_type(_sin, mapgen_exit_types.one)) {
		if (array_length(_map.rooms) >= MAX_NUMBER_OF_ROOMS) { return undefined; }
		return mapgen_add_new_room(_map, false);
	}
	if (mapgen_sin_has_exit_type(_sin, mapgen_exit_types.four)) { return mapgen_build_four_exit_room(_map); }
	return undefined; // Today's sin table needs no other shape
}

/// @function mapgen_build_four_exit_room(_map)
/// @description Gives the room closest to four real side exits the rest: links its unlinked neighbors and
///	adds new rooms on its free sides (step 4, R27).
/// @param {GameMap} _map The map being generated
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
	var _dirs = _map.cardinal_exit_directions;
	for (var _j = 0; _j < array_length(_dirs); _j++) {
		var _dir = _dirs[_j];
		if (_best_room.has_exit(_dir)) { continue; }
		var _neighbor = _map.get_neighbor(_best_room, _dir);
		if (is_undefined(_neighbor)) {
			_neighbor = _map.create_room_at_map_position(_best_room.virtual_x + get_dir_x_offset(_dir), _best_room.virtual_y + get_dir_y_offset(_dir));
		}
		_map.link_rooms(_best_room, _neighbor, _dir);
	}
	return _best_room;
}

/// @function mapgen_count_openable_missing_sides(_map, _room)
/// @description Counts a room's sides without an exit, if each can get one: its cell is free, or its
///	neighbor can gain exits.
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {real} How many sides are missing, or -1 if one of them can never open
function mapgen_count_openable_missing_sides(_map, _room) {
	var _missing = 0, _dirs = _map.cardinal_exit_directions;
	for (var _i = 0; _i < array_length(_dirs); _i++) {
		if (_room.has_exit(_dirs[_i])) { continue; }
		var _neighbor = _map.get_neighbor(_room, _dirs[_i]);
		if (!is_undefined(_neighbor) && !_neighbor.can_gain_exits()) { return -1; }
		_missing += 1;
	}
	return _missing;
}

/// @function mapgen_count_free_sides(_map, _room)
/// @description Counts the sides of a room whose grid cell is free.
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {real}
function mapgen_count_free_sides(_map, _room) {
	var _free = 0, _dirs = _map.cardinal_exit_directions;
	for (var _i = 0; _i < array_length(_dirs); _i++) {
		if (is_undefined(_map.get_neighbor(_room, _dirs[_i]))) { _free += 1; }
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @param {bool} _needs_lanterns Whether the layout must have lanterns
function mapgen_pick_layout(_map, _room, _needs_lanterns) {
	// Free the old layout, so it no longer counts as in use (R20)
	if (!is_undefined(_room.layout)) { _map.layout_use_counts[_room.layout.index] -= 1; }

	var _real_exit_type = _room.get_exit_type(), _candidates;
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
	return mapgen_get_exit_type_for_count(_exit_count, _room.has_opposite_exits());
}

/// @function mapgen_choose_unused_layout(_map, _candidates)
/// @description Picks a random layout, preferring one no other room uses (R20).
/// @param {GameMap} _map The map being generated
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
			_room.rotate = _room.get_first_side(true);
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
			_room.rotate = (_room.get_first_side(false) + 1) % 4;
			break;
	}
}

/// @function mapgen_roll_room_content(_map, _room)
/// @description Rolls a room's content for its layout, once per layout pick (R33): lighting, enemies,
///	fountains, skeleton spots, extra mouths, moving collectables and a hall's mirror sequence. Each pass of
///	step 6 starts from this content (see mapgen_reset_room).
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
/// @returns {Asset.GMObject}
function mapgen_roll_skeleton_type(_map) {
	return (_map.same_skeleton_type != noone) ? _map.same_skeleton_type : get_skeleton_type();
}

/// @function mapgen_has_other_lantern_room(_map, _room)
/// @description Whether any non-sin room besides _room has a lantern layout (R28).
/// @param {GameMap} _map The map being generated
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


// =====================================================================================================
// STEP 7: START AND HEART
// =====================================================================================================

/// @function mapgen_choose_start_and_heart(_map)
/// @description Makes the start and heart the two ends of the longest path, among the pairs the rules
///	allow (R10, R11, R13). A pair's distance is its quickest route, a stairs trip being one step. Then
///	measures every room's distance from the start, places the cross and the encased heart, and makes the
///	start safe (R12).
/// @param {GameMap} _map The map being generated
/// @returns {bool} False if no pair is allowed
function mapgen_choose_start_and_heart(_map) {
	var _longest = -1, _longest_pairs = [];
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _start = _map.rooms[_i];
		if (!_start.can_be_start()) { continue; }
		var _distances = _map.measure_distances(_start);
		for (var _j = 0; _j < array_length(_map.rooms); _j++) {
			var _heart = _map.rooms[_j];
			if (!_heart.can_be_heart(_start)) { continue; }
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
	var _distances_from_start = _map.measure_distances(_map.start_room);
	for (var _k = 0; _k < array_length(_map.rooms); _k++) {
		var _room = _map.rooms[_k];
		_room.distance_to_start = _distances_from_start[_room.mapgen_index];
	}
	mapgen_set_spot_object(_map.start_room, obj_cross);
	mapgen_set_spot_object(_map.heart_room, obj_encased_heart);
	mapgen_make_start_room_safe(_map);
	return true;
}

/// @function mapgen_make_start_room_safe(_map)
/// @description Removes every generated hazard that could hurt a player who hasn't acted yet from the
///	start room: phantoms, floaters, fountains, rolled eyes, noses and lava fire skeletons. Hazards placed
///	in its layout file stay for now (R12).
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
		if (_chest_room != _map.guaranteed_chest_room && _chest_room.has_plain_chest() && get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) {
			_chest_room.chest_obj = get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY) ? obj_fountain : obj_statue;
		}
	}

	// Every other chest gets an item (R42)
	for (var _n = 0; _n < array_length(_rooms); _n++) {
		var _item_room = _rooms[_n];
		if (_item_room.has_chest() && _item_room.chest_obj == -1) {
			_item_room.chest_obj = mapgen_pick_item_type(_map, _item_room.has_special_item, []);
		}
	}
}

/// @function mapgen_place_cursed_items(_map, _rooms)
/// @description Marks exactly the step 2 count of cursed items outside sin rooms, each in a chest at least
///	two rooms from the start, adding chests when too few exist (R40). The guaranteed chest is never
///	cursed (R36).
/// @param {GameMap} _map The map being generated
/// @param {array} _rooms The map's rooms, in random order
function mapgen_place_cursed_items(_map, _rooms) {
	var _left_to_place = _map.cursed_item_count;

	// Chests already placed
	for (var _i = 0; _i < array_length(_rooms) && _left_to_place > 0; _i++) {
		var _chest_room = _rooms[_i];
		if (_chest_room.has_chest() && !_chest_room.has_special_item && _chest_room != _map.guaranteed_chest_room && _chest_room.distance_to_start >= 2) {
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
/// @param {GameMap} _map The map being generated
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
///	key step placed don't count, and neither does a torch in the guaranteed chest, which may always go over
///	the cap (step 13).
/// @param {GameMap} _map The map being generated
/// @param {Asset.GMObject} _type The item
/// @param {array} _hands The starting hand items to count
/// @returns {real}
function mapgen_count_regular_items(_map, _type, _hands) {
	var _count = 0;
	for (var _i = 0; _i < array_length(_map.rooms); _i++) {
		var _room = _map.rooms[_i];
		if (_room == _map.guaranteed_chest_room && _room.chest_obj == obj_torch) { continue; }
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
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_hold_chest(_map, _room) {
	return _room != _map.start_room && _room != _map.heart_room && _room.stairs_spot_obj == -1;
}


// =====================================================================================================
// STEPS 10 AND 11: LOCKS AND KEYS
// =====================================================================================================

/// @function mapgen_place_locks_and_keys(_map)
/// @description Locks every heart side exit, then rolls a random lock on each other side exit, backing each
///	lock with keys before the next is added (R14, R43, R50).
/// @param {GameMap} _map The map being generated
/// @returns {bool} False if the heart locks could not be backed (a last resort, never expected)
function mapgen_place_locks_and_keys(_map) {
	// Every side exit of the heart is locked; the map only needs enough keys to get in once (R14)
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _heart_exit = _map.heart_room.exits[_dir];
		if (_heart_exit != -1) { _heart_exit.set_lock(true); }
	}
	if (!mapgen_back_locks_with_keys(_map, undefined)) { return false; }

	// Other side exits lock 1 in 8/6/5/4, one at a time (R43)
	var _exits = array_shuffle(_map.side_links);
	for (var _i = 0; _i < array_length(_exits); _i++) {
		var _exit = _exits[_i];
		if (!mapgen_can_lock_exit(_map, _exit) || !get_random_chance_out_of(LOCKED_DOOR_PROBABILITY / 2)) { continue; }
		_exit.set_lock(true);
		if (!mapgen_back_locks_with_keys(_map, _exit)) { return false; }
	}
	return true;
}

/// @function mapgen_back_locks_with_keys(_map, _newest_lock)
/// @description Runs the every-order key check, and wherever the player could get stuck adds a key-role
///	item in the area they're stuck in, until no order of spending keys can strand them (R44, R50). If no
///	room there can take one, the newest lock moves to another eligible exit, so the lock count stays as
///	rolled; dropping it is the last resort, and heart locks never move.
/// @param {GameMap} _map The map being generated
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
		_newest_lock.set_lock(false);
		_newest_lock = mapgen_pick_untried_lockable_exit(_map, _tried_exits);
		if (is_undefined(_newest_lock)) {
			write_debug_message("Dropped a lock that no key could back (R50).", "WARNING");
			continue;
		}
		_newest_lock.set_lock(true);
		array_push(_tried_exits, _newest_lock);
	}
}

/// @function mapgen_add_key_role_item(_map, _stuck_area)
/// @description Adds a key-role item in a random room of a stuck area that can take one: on a random
///	collectable spot, or 1 in 3 in a new plain chest when the room has no chest (R47, R48, R57). From M a
///	bomb can stand in for a chest key, but only where it counts as one (R46, R49).
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
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
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_roll_special_exits(_map, _room) {
	return !_room.has_no_cardinal_exits && _room != _map.start_room && _room != _map.heart_room
		&& !_room.is_connected_to_hall_of_mirrors();
}

/// @function mapgen_can_take_portcullis(_map, _room)
/// @description Whether a room can take a portcullis trap (R52, R53): it rolls special exits itself (which
///	rules out the start, heart and stairs-only rooms), none of its side exits has a door (locked or plain) or
///	an illusion wall, no neighbor has a trap, and its button has a free spot.
/// @param {GameMap} _map The map being generated
/// @param {GameRoom} _room The room
/// @returns {bool}
function mapgen_can_take_portcullis(_map, _room) {
	if (!mapgen_can_roll_special_exits(_map, _room)) { return false; }
	for (var _dir = directions.up; _dir <= directions.left; _dir++) {
		var _exit = _room.exits[_dir];
		if (_exit == -1) { continue; }
		if (_exit.has_door || _exit.has_illusion_walls > 0 || _exit.get_connected_room(_room).has_portcullis_button) { return false; }
	}
	return array_length(_room.list_button_spots()) > 0;
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

	var _spot = array_random_get(_room.list_button_spots());
	_room.button_on_stairs_spot = (_spot == -1);
	_room.button_spot = _spot;
}


// =====================================================================================================
// STEP 13: THE STARTING HANDS
// Each room's score and time are GameRoom methods (get_difficulty_score, get_time_provided), which GameMap
// adds up
// =====================================================================================================

/// @function mapgen_adjust_items_for_hands(_map)
/// @description The very last step, once the map is final (step 13): fits the chest items to the starting
///	hands. The guaranteed chest becomes the map, compass or torch the hands call for (R36), and any regular
///	item over its cap once the hands count is re-picked (R42), unless that would strand the player, like
///	taking the torch a bomb needs to stand in for a key (R46). Nothing else changes; the map never relies on
///	the starting items (R45). Runs in its own random stream (see mapgen_generate).
/// @param {GameMap} _map The finished map
function mapgen_adjust_items_for_hands(_map) {
	var _hands = [global.player_left_hand_item, global.player_right_hand_item];
	var _brings_map = array_contains(_hands, obj_map), _brings_compass = array_contains(_hands, obj_compass);
	var _guaranteed = _map.guaranteed_chest_room;
	if (!is_undefined(_guaranteed)) {
		if (_brings_map && _brings_compass) { _guaranteed.chest_obj = obj_torch; }
		else if (_brings_compass) { _guaranteed.chest_obj = obj_map; }
		else if (_brings_map) { _guaranteed.chest_obj = (global.difficulty == difficulties.easy) ? obj_torch : obj_compass; }
	}

	var _rooms = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_rooms); _i++) {
		var _room = _rooms[_i];
		if (_room == _guaranteed || !_room.holds_regular_item()) { continue; }
		if (mapgen_count_regular_items(_map, _room.chest_obj, _hands) > mapgen_get_item_cap(_room.chest_obj)) {
			var _item = _room.chest_obj;
			_room.chest_obj = -1;
			_room.chest_obj = mapgen_pick_item_type(_map, false, _hands);

			// The item stays, over its cap, if the map needs it to stay winnable (R46)
			if (!is_undefined(mapgen_check_key_orders(_map))) { _room.chest_obj = _item; }
		}
	}
}


// =====================================================================================================
// SMALL HELPERS
// =====================================================================================================

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