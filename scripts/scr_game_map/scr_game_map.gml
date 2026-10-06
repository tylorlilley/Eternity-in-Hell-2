/// @function GameMap()
/// @description The plan for one map, and the steps that generate it (mapgen_generate makes a new GameMap and
///	calls try_generate): the layouts its difficulty allows, its rooms and the exits between them, its map-wide
///	events and decorations, and what the controller keeps once generation ends. Rooms and exits are only added
///	through its methods, so its lookups always match its rooms. It also reads every layout file once per session
///	(step 1), into the layout cache every map shares.
function GameMap() constructor {
	// Set up the game wide layout cache of room layout files
	static cardinal_exit_directions = [directions.up, directions.right, directions.down, directions.left];
	static layout_cache = undefined;
	if (is_undefined(layout_cache)) {
		var _layouts = [], _sins = [
			new Sin("pride", [rm_four_exits_23, rm_four_exits_24]),						// Hall of mirrors
			new Sin("envy", [rm_four_exits_22, rm_one_exit_27, rm_three_exits_30]),		// Giant eye
			new Sin("wrath", [rm_one_exit_22]),											// Inverted cross
			new Sin("greed", [rm_one_exit_30]),											// Red chest
			new Sin("sloth", [rm_one_exit_23])											// Gudetama
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

	// Layouts this difficulty allows for regular (non-sin) rooms by exit kind, and how many rooms use each
	layouts_by_exit_type = [];
	layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

	// Sins with a layout this difficulty allows, each with those layouts
	available_sins = [];

	// Map-wide events (step 2)
	long_and_straight_map = false;
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

	// What is passed to the controller on a successful map generation
	rooms_with_collectables = [];
	spawned_items = [];
	spawned_special_items = [];
	time_provided = 0;

	// Initialize list of layouts by exit type
	for (var _type = 0; _type < layout_exit_types.count; _type++) { array_push(layouts_by_exit_type, []); }

	// Assign the cached layouts to their exit type's array, if the difficulty allows
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
		if (array_length(_allowed_layouts) > 0) { array_push(available_sins, new Sin(_sin.name, _allowed_layouts)); }
	}

	// Check that every exit type has at least one layout, and at least one layout with a lantern. This should always be true, but good to check.
	for (var _type_checked = 0; _type_checked < layout_exit_types.count; _type_checked++) {
		var _layouts_of_type = layouts_by_exit_type[_type_checked];
		if (array_length(_layouts_of_type) == 0) {
			var _error_message = "No layout of exit kind " + string(_type_checked) + " at this difficulty: " + string(global.difficulty);
			write_debug_message(_error_message, "ERROR");
		}

		if (array_length(get_only_lantern_layouts(_layouts_of_type)) == 0) {
			var _error_message = "No lantern layout of exit kind " + string(_type_checked) + " at this difficulty."
			write_debug_message(_error_message, "ERROR");
		}
	}

	// =========
	// FUNCTIONS
	// =========

	/// @function try_generate()
	/// @description Makes one attempt at creating a possible map
	/// @returns {bool} False if a last resort failed
	static try_generate = function() {
		// determine map-wide events, including sins and cursed items
		roll_map_events();

		// grow the graph to the minimum room count, without assigning room layouts
		create_room_at_map_position(0, 0);
		while (array_length(rooms) < MINIMUM_NUMBER_OF_ROOMS) {
			if (is_undefined(add_new_room())) { return fail_generation("no room could grow"); }
		}

		// add additional room links, and reserve a room to be the sin room
		link_adjacent_rooms();
		if (!find_or_create_sin_rooms()) { return fail_generation("no room could be shaped for a sin"); }
		if (!find_or_create_starting_rooms()) { return fail_generation("no room could be created as a starting room"); }

		// Assign layouts to each room, and generate it's random orientation and room content
		assign_room_layouts();

		// Step 6: decorate and score the whole map. While the score is short of the target, add one room and
		// decorate again, so every point counted is something the map really has (R2)
		while (true) {
			if (!decorate()) { return fail_generation("the start and heart or the heart's keys could not be placed"); }
			calculate_map_difficulty_score();
			if (difficulty_score >= MAP_SCORE_TARGET || array_length(rooms) >= MAX_NUMBER_OF_ROOMS) { break; }
			if (is_undefined(add_new_room())) { break; }
			link_adjacent_rooms();
			assign_room_layouts();
		}

		// Step 13: the time, from the last pass's scores
		calculate_time_provided();
		return true;
	};

	/// @function roll_map_events()
	/// @description Sets up everything that is decided on a per-map basis, before any room content is created or room references assigned:
	///	the map-wide events, the map's sins, and how many cursed items spawn outside sin rooms.
	static roll_map_events = function() {
		// Set the Map Shape and Same Skeleton Type Events
		long_and_straight_map = get_random_chance_out_of(SPECIAL_MAP_SHAPE_FREQUENCY); // TODO: Implement this and other shapes. Add eval messages
		same_skeleton_type = get_random_chance_out_of(SAME_SKELETON_TYPE_FREQUENCY) ? get_skeleton_type(false) : noone; // TODO: Add eval messages

		// Set Number of Special Sin Rooms to Include
		var _sins_left = array_get_duplicate(available_sins), _sin_limit = SPECIAL_ROOM_LIMIT, _sin_count = 0;
		for (var _i = 0; _i < _sin_limit; _i++) {
			if (get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY)) { _sin_count += 1; }
		}
		_sin_count = min(_sin_count, array_length(_sins_left));
		
		// Include one room of a random sin type, for each sin in sin count
		for (var _i = 0; _i < _sin_count; _i++) {
			array_push(included_sins, array_random_pop(_sins_left));
		}

		// Set Number of Additional Special Cursed Items to Spawn outside of Sin Rooms
		var _special_item_limit = SPECIAL_ITEM_LIMIT, _special_item_count = 0;
		for (var _i = _sin_count; _i < _special_item_limit; _i++) {
			if (get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { _special_item_count += 1; }
		}
		cursed_item_count = _special_item_count;
	};

	/// @function create_room_at_map_position(_x, _y)
	/// @description Adds a room on a free grid cell, with no exits or layout yet (R3).
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom} The new room
	static create_room_at_map_position = function(_x, _y) {
		var _room = new GameRoom(_x, _y);
		
		// Add room to map's rooms array, and room_at_cell lookup table
		_room.mapgen_index = array_length(rooms);
		array_push(rooms, _room);
		room_at_cell[$ get_cell_key(_x, _y)] = _room;
		
		return _room;
	};

	/// @function link_rooms_with_new_exit(_room, _other_room, _dir)
	/// @description Joins two rooms with a new exit, on a side or by stairs.
	/// @param {GameRoom} _room One room
	/// @param {GameRoom} _other_room The other room
	/// @param {real} _dir The direction from _room to _other_room, or directions.stairs
	/// @returns {RoomExit} The new exit
	static link_rooms_with_new_exit = function(_room, _other_room, _dir) {
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
	/// @description Counts the rooms that could be the start
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
	
	/// @function decorate()
	/// @description Steps 7 to 12: one decoration pass over the current graph, starting from each room's
	///	rolled content.
	/// @returns {bool} False if a last resort failed
	static decorate = function() {
		reset_decorations();
		if (!choose_start_and_heart()) { return false; }		// Step 7
		place_collectables();								// Step 8
		ensure_a_lit_room();									// Step 8
		place_chests();										// Step 9
		if (!place_locks_and_keys()) { return false; }		// Steps 10 and 11
		place_special_exits();								// Step 12
		return true;
	};

	/// @function fail_generation(_reason)
	/// @description Logs a failed attempt and destroys this map
	/// @param {string} _reason What failed
	/// @returns {bool} Always false, so try_generate can return it
	static fail_generation = function(_reason) {
		write_debug_message("Map generation attempt failed, retrying on the same random stream: " + _reason, debug_message_level.warning);
		destroy();
		return false;
	};


	// =================================================================================================
	// STEPS 3 AND 4: GROW THE GRAPH, ADD SIDE LINKS AND RESERVE SIN ROOMS
	// =================================================================================================

	/// @function add_new_room(_allow_stairs)
	/// @description Adds one room to the map, joined to a random room by a side exit or stairs
	/// @param {bool} [_allow_stairs] False to always join by a side exit (true by default)
	/// @returns {GameRoom|undefined} The new room, or undefined if no room can grow
	static add_new_room = function(_allow_stairs = true) {
		// Stairs never take the last room the start could use, since the start has no stairs
		var _stairs_allowed = _allow_stairs && (count_possible_starts() > 1);
		var _existing_rooms = array_shuffle(rooms), _linked_room = undefined;

		// Check all existing rooms for a room we can add an exit to
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _potential_room = _existing_rooms[_i];
			if (!_potential_room.can_gain_exits()) { continue; }

			// Connect via Stairs
			if (_stairs_allowed && !_potential_room.has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
				// Find a grid spot to generate the linking room at
				var _cell = find_unoccupied_non_adjacent_cell(_potential_room);
				
				// Create new room to link via stairs in that grid cell
				if (!is_undefined(_cell)) {
					_linked_room = create_room_at_map_position(_cell[0], _cell[1]);
					link_rooms_with_new_exit(_potential_room, _linked_room, directions.stairs);

					// Set the room to be accessed by stairs only sometimes
					_linked_room.has_no_cardinal_exits = get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY);
				}
			}

			// Otherwise, connect via a cardinal direction
			if (is_undefined(_linked_room)) {
				var _dir = find_unoccupied_adjacent_cell_direction(_potential_room);
				if (_dir != -1) {
					_linked_room = create_room_at_map_position(_potential_room.virtual_x + get_dir_x_offset(_dir), _potential_room.virtual_y + get_dir_y_offset(_dir));
					link_rooms_with_new_exit(_potential_room, _linked_room, _dir);
				}
			}

			// Stop once a room has been added
			if (!is_undefined(_linked_room)) { break; }
		}

		// The new room, or undefined if no room could be added
		return _linked_room;
	};

	/// @function find_unoccupied_non_adjacent_cell(_linked_room)
	/// @description Finds a free grid cell to create a room in while creating a new room that is linked by stairs
	/// @param {GameRoom} _linked_room The room the stairs leave from
	/// @returns {array|undefined} The cell as [x, y], or undefined if there is none
	static find_unoccupied_non_adjacent_cell = function(_linked_room) {
		var _existing_rooms = array_shuffle(rooms);
		
		// Check each existing room for an empty adjacent cell 
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _potential_room = _existing_rooms[_i];
			
			// Check each position adjacent to this room
			var _dirs = array_shuffle(cardinal_exit_directions);
			for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
				var _x = _potential_room.virtual_x + get_dir_x_offset(_dirs[_dir]);
				var _y = _potential_room.virtual_y + get_dir_y_offset(_dirs[_dir]);
				var _is_adjacent_to_linked_room = (abs(_x - _linked_room.virtual_x) + abs(_y - _linked_room.virtual_y) == 1);
				var _cell_is_already_occupied = !is_undefined(get_room_at(_x, _y));
				
				// Continue to next possible direction if this cell is occuppied or adjacent to the linked room
				if (_is_adjacent_to_linked_room || _cell_is_already_occupied) { continue; }
				
				// Return the current x and y position for making a new room in
				return [_x, _y];
			}
		}
		
		// return undefined if no possible spot is found
		return undefined;
	};

	/// @function find_unoccupied_adjacent_cell_direction(_room)
	/// @description Returns a random direction from the given room that leads to an unoccupied adjacent cell
	/// @param {GameRoom} _room The room
	/// @returns {real} The direction, or -1 if every side is taken
	static find_unoccupied_adjacent_cell_direction = function(_room) {
		// Check the map grid for each space adjacent to the given room
		var _dirs = array_shuffle(cardinal_exit_directions);
		for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
			// If the map grid's cell is unoccupied at this space, return this direction
			if (is_undefined(get_neighbor(_room, _dirs[_dir]))) { return _dirs[_dir]; }
		}
		
		// If no adjacent map grid cells are unoccupied, return -1
		return -1;
	};

	/// @function link_adjacent_rooms()
	/// @description Links rooms that are grid neighbors via new exits until rooms reach the average target, stopping
	///	early if no more links fit, since the average is only a target (R4).
	static link_adjacent_rooms = function() {
		while (2 * array_length(side_links) / array_length(rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
			if (!add_adjacent_exit()) { return; }
		}
	};

	/// @function add_adjacent_exit()
	/// @description Links a random room to one of its unlinked grid neighbors
	/// @returns {bool} False if no more links fit
	static add_adjacent_exit = function() {
		var _existing_rooms = array_shuffle(rooms);
		
		// Loop through all rooms to find one that can add a new exit
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _potential_room = _existing_rooms[_i];
			if (!_potential_room.can_gain_exits()) { continue; }

			// Check each direction for one where an exit can be created
			var _dirs = array_shuffle(cardinal_exit_directions);
			for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
				// Continue if exit already exists in this direction
				if (_potential_room.has_exit(_dirs[_dir])) { continue; }
				
				// Continue if no neighboring room exists in the grid in this direction or it can't gain exits
				var _adjacent_room = get_neighbor(_potential_room, _dirs[_dir]);
				if (is_undefined(_adjacent_room) || !_adjacent_room.can_gain_exits()) { continue; }

				link_rooms_with_new_exit(_potential_room, _adjacent_room, _dirs[_dir]);
				return true;
			}
		}
		
		// Return false if no new exit can be added
		return false;
	};

	/// @function find_or_create_sin_rooms()
	/// @description Reserves a room for each included sin: one whose side exits already fit one of the sin's
	///	layouts, or else one found or built to fit (see add_room_for_sin)
	/// @returns {bool} False if a sin got no room
	static find_or_create_sin_rooms = function() {
		// Loop through each included sin
		for (var _i = 0; _i < array_length(included_sins); _i++) {
			var _sin = included_sins[_i];
			var _room = find_room_for_sin(_sin);
			
			// If a fitting room could not be found for the sin, create one instead:
			if (is_undefined(_room)) { _room = add_room_for_sin(_sin); }
			
			// If creating one failed, return false
			if (is_undefined(_room)) { return false; }
			
			// Otherwise, set up the chosen room to be a sin room.
			_room.is_special_room = true;
			_room.mapgen_sin = _sin;
		}
		
		return true;
	};
	
	/// @function find_or_create_starting_rooms()
	/// @description Creates a new room that can be the starting room, if none exist
	/// @returns {bool} False if no room could be added
	static find_or_create_starting_rooms = function() {
		// check if there is still any room where it is possible to start and add a new room if not.
		if (count_possible_starts() == 0 && is_undefined(add_new_room(false))) { return false; }

		return true;
	};

	/// @function find_room_for_sin(_sin)
	/// @description Picks a random room that fits a sin: no stairs, not reserved yet, and matching side exits
	/// @param {Sin} _sin The sin
	/// @returns {GameRoom|undefined} The room, or undefined if none fits
	static find_room_for_sin = function(_sin) {
		var _possible_rooms = [];
		
		// Check each existing room
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			
			// If room is already a sin room or has stairs, skip it
			if (_room.is_special_room || _room.has_exit(directions.stairs)) { continue; }
			
			// Add room to list of possibilities if one of the sin's layouts matches the room's exit type
			if (_sin.has_layout_of_type(_room.get_exit_type())) { array_push(_possible_rooms, _room); }
		}
		
		// Return a random matching room, or undefined
		return (array_length(_possible_rooms) > 0) ? array_random_get(_possible_rooms) : undefined;
	};

	/// @function add_room_for_sin(_sin)
	/// @description Makes a room for a sin that no room fits yet: tries each exit kind the sin's layouts have, in
	///	random order, until a room with that many side exits is found or built (see find_or_create_room_for_exit_count)
	/// @param {Sin} _sin The sin
	/// @returns {GameRoom|undefined} The room, or undefined if none could be made
	static add_room_for_sin = function(_sin) {
		var _exit_types = array_shuffle(_sin.get_exit_types());
		for (var _i = 0; _i < array_length(_exit_types); _i++) {
			// Find or build a room with the side exits this kind of layout opens
			var _room = undefined;
			switch (_exit_types[_i]) {
				case layout_exit_types.one: _room = find_or_create_room_for_exit_count(1); break;
				case layout_exit_types.two_opposite: _room = find_or_create_room_for_exit_count(2, true); break;
				case layout_exit_types.two_perpendicular: _room = find_or_create_room_for_exit_count(2, false); break;
				case layout_exit_types.three: _room = find_or_create_room_for_exit_count(3); break;
				case layout_exit_types.four: _room = find_or_create_room_for_exit_count(4); break;
			}

			// Return the first room that could be found or built
			if (!is_undefined(_room)) { return _room; }
		}

		// Return undefined if no kind of room could be found or built
		return undefined;
	};

	/// @function find_or_create_room_for_exit_count(_target_exit_count, [_needs_opposite_exits])
	/// @description Finds the room needing the fewest new side exits to have exactly the target number, and adds
	///	them: links to neighbors that can gain exits first, then new rooms on free cells. A room with one exit is
	///	always a new dead end, since exits are never removed.
	/// @param {real} _target_exit_count How many side exits the room needs, 1 to 4
	/// @param {bool} [_needs_opposite_exits] For two exits: true for opposite sides, false for a corner, undefined for either
	/// @returns {GameRoom|undefined} The room, or undefined if none could be found or built
	static find_or_create_room_for_exit_count = function(_target_exit_count, _needs_opposite_exits = undefined) {
		// Exits are never removed, so a room with one exit has to be a new dead end
		if (_target_exit_count == 1) {
			if (array_length(rooms) >= MAX_NUMBER_OF_ROOMS) { return undefined; }
			return add_new_room(false);
		}

		// Find the room that needs the fewest new exits to reach the target
		var _best_room = undefined, _best_sides = undefined;
		var _existing_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _possible_room = _existing_rooms[_i];

			// Skip rooms that are already special or have stairs
			// TODO: this only works because this function is currently only used for assigning sin rooms, and for sin rooms we don't want those
			if (_possible_room.is_special_room || _possible_room.has_exit(directions.stairs)) { continue; }

			// Skip rooms that can't reach the target, and keep the one needing the fewest new exits
			var _sides = get_openable_sides(_possible_room, _target_exit_count, _needs_opposite_exits);
			if (is_undefined(_sides)) { continue; }
			if (is_undefined(_best_sides) || _sides.exits_needed < _best_sides.exits_needed) {
				_best_room = _possible_room;
				_best_sides = _sides;
			}
		}

		// Return undefined if no room could be identified
		if (is_undefined(_best_room)) { return undefined; }

		// Otherwise, open sides that link an existing neighbor first, then free cells
		var _dirs = array_shuffle(_best_sides.linkable_sides);
		array_copy(_dirs, array_length(_dirs), array_shuffle(_best_sides.free_sides), 0, array_length(_best_sides.free_sides));
		for (var _dir = 0; _dir < _best_sides.exits_needed; _dir++) {
			// Create a new room if none exists
			var _neighbor_room = get_neighbor(_best_room, _dirs[_dir]);
			if (is_undefined(_neighbor_room)) { _neighbor_room = create_room_at_map_position(_best_room.virtual_x + get_dir_x_offset(_dirs[_dir]), _best_room.virtual_y + get_dir_y_offset(_dirs[_dir])); }

			// Create a new exit between the rooms
			link_rooms_with_new_exit(_best_room, _neighbor_room, _dirs[_dir]);
		}

		return _best_room;
	};

	/// @function get_openable_sides(_room, _target_exit_count, [_needs_opposite_exits])
	/// @description Sorts the sides a room could open to end up with exactly the target number of side exits:
	///	sides whose neighbor can gain exits, and sides on a free cell, where a new room would go.
	/// @param {GameRoom} _room The room
	/// @param {real} _target_exit_count How many side exits the room needs, 2 to 4
	/// @param {bool} [_needs_opposite_exits] For two exits: true for opposite sides, false for a corner, undefined for either
	/// @returns {struct|undefined} { exits_needed, linkable_sides, free_sides }, or undefined if the room can't reach the target
	static get_openable_sides = function(_room, _target_exit_count, _needs_opposite_exits = undefined) {
		// Exits are never removed, so the room can't already have more than the target
		var _exits_needed = _target_exit_count - _room.get_cardinal_exits_count();
		if (_exits_needed < 0) { return undefined; }

		// Two exits must be on opposite sides, or on a corner, when the layout needs it. A room with no side
		// exits has stairs, so it never needs both
		var _check_arrangement = (_target_exit_count == 2) && !is_undefined(_needs_opposite_exits);
		if (_check_arrangement && _exits_needed == 2) { return undefined; }
		if (_check_arrangement && _exits_needed == 0 && _room.has_opposite_exits() != _needs_opposite_exits) { return undefined; }

		// Sort the sides without an exit by what is beside them
		var _linkable_sides = [], _free_sides = [];
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			// Skip sides that already have exits
			if (_room.has_exit(_dir)) { continue; }

			// For two exits, skip a side that would put them in the wrong arrangement
			if (_check_arrangement && _room.has_exit(get_opposite_dir(_dir)) != _needs_opposite_exits) { continue; }

			// A free cell gets a new room, and a neighbor only links if it can gain exits
			var _neighbor_room = get_neighbor(_room, _dir);
			if (is_undefined(_neighbor_room)) { array_push(_free_sides, _dir); }
			else if (_neighbor_room.can_gain_exits()) { array_push(_linkable_sides, _dir); }
		}

		// Enough sides must open, and the new rooms needed must fit under the room limit
		if (array_length(_linkable_sides) + array_length(_free_sides) < _exits_needed) { return undefined; }
		if (array_length(rooms) + max(0, _exits_needed - array_length(_linkable_sides)) > MAX_NUMBER_OF_ROOMS) { return undefined; }

		return { exits_needed: _exits_needed, linkable_sides: _linkable_sides, free_sides: _free_sides };
	};


	// =================================================================================================
	// STEP 5: LAYOUTS AND ROLLED CONTENT
	// =================================================================================================

	/// @function assign_room_layouts()
	/// @description Assigns a room layout, and rolls its content, to every room in the map whose side exits have
	///	changed since its last layout (R16). If no other regular room has lanterns, the last regular room to get a
	///	layout gets one with lanterns, which keeps a lantern room on every map (R28). Sin rooms go last, since
	///	their layouts never compete with the regular ones.
	static assign_room_layouts = function() {
		// Create list of rooms that need a new room layout assigned to it
		var _existing_rooms = array_shuffle(rooms), _rooms_that_need_layouts = [], _special_rooms_that_need_layouts = [];
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _possible_room = _existing_rooms[_i];
			if (_possible_room.mapgen_needs_layout) { array_push(((_possible_room.is_special_room) ? _special_rooms_that_need_layouts : _rooms_that_need_layouts), _possible_room); }
		}
		
		// For each regular room that needs a layout, assign one
		for (var _i = 0; _i < array_length(_rooms_that_need_layouts); _i++) {
			var _possible_room = _rooms_that_need_layouts[_i], _is_last_pick = (_i == array_length(_rooms_that_need_layouts) - 1);
			// The last regular room keeps a lantern room on the map. Its own old layout doesn't count, since it is
			// about to be replaced
			var _needs_lanterns = _is_last_pick && !has_any_lantern_rooms(_possible_room);
			assign_layout_to_room(_possible_room, _needs_lanterns);
		}
		
		// For each special room that needs a layout, assign one
		for (var _i = 0; _i < array_length(_special_rooms_that_need_layouts); _i++) {
			var _possible_room = _special_rooms_that_need_layouts[_i];

			assign_layout_to_room(_possible_room);
		}
	};

	/// @function assign_layout_to_room(_room, [_needs_lanterns])
	/// @description Assigns a room's layout, including flips and rotations
	/// @param {GameRoom} _room The room
	/// @param {bool} [_needs_lanterns] Whether the layout must have lanterns (false by default; sin rooms ignore it)
	static assign_layout_to_room = function(_room, _needs_lanterns = false) {
		// Free the old layout, so it no longer counts as in use
		if (!is_undefined(_room.layout)) { layout_use_counts[_room.layout.index] -= 1; }

		// Assign a new minimally used layout for the room
		var _real_exit_type = _room.get_exit_type(), _possible_layouts, _layout;
		if (_room.is_special_room) {
			// Special rooms can't be misleading, can't be the pre-lit lantern room, and must be one of the chosen sin's layouts
			_possible_layouts = _room.mapgen_sin.get_layouts_of_type(_real_exit_type);
			_layout = choose_minimally_used_layout(_possible_layouts);
		}
		else {
			// If layout exit type is different from the real exit type, it is a room with misleading exits
			var _layout_exit_type = _room.determine_layout_exit_type();
			_possible_layouts = layouts_by_exit_type[_layout_exit_type];
			_layout = choose_minimally_used_layout(_possible_layouts, _needs_lanterns);
		}

		// Increase the layout use count
		layout_use_counts[_layout.index] += 1;
		
		// Update the room's variables based on the chosen static layout
		with (_room) {
			layout = _layout;
			room_reference = _layout.room_reference;
			has_lanterns = _layout.has_lanterns;
			has_hall_of_mirrors = _layout.is_hall_of_mirrors;
			has_misleading_exits = (_layout.exit_type != _real_exit_type);
			mapgen_needs_layout = false;
			
			// Decide the random room rotation from among possible options
			determine_layout_orientation();
			
			// Decide how to fill in the random room content for the chosen static layout
			determine_random_room_content(other.same_skeleton_type);
		}
		
	};

	/// @function choose_minimally_used_layout(_candidates)
	/// @description Picks a random layout, preferring ones that have been used the least
	/// @param {array} _candidates The layouts that fit
	/// @returns {struct} The layout record
	static choose_minimally_used_layout = function(_possible_layouts, _must_have_lanterns = false) {
		var _minimum_use_count = 0, _minimally_used_layouts = [];
		do {
			_minimally_used_layouts = [];
			for (var _i = 0; _i < array_length(_possible_layouts); _i++) {
				var _possible_layout = _possible_layouts[_i];
				if (_must_have_lanterns && !_possible_layout.has_lanterns) { continue; }
				
				if (layout_use_counts[_possible_layout.index] == _minimum_use_count) { array_push(_minimally_used_layouts, _possible_layout); }
			}
			_minimum_use_count += 1;
		}
		until (array_length(_minimally_used_layouts) > 0);
		
		return array_random_get(_minimally_used_layouts);
	};

	/// @function has_any_lantern_rooms([_ignored_room])
	/// @description Returns whether any regular (non-sin) room already has a layout with lanterns
	/// @param {GameRoom} [_ignored_room] A room not to count, like one about to get a new layout
	/// @returns {bool}
	static has_any_lantern_rooms = function(_ignored_room = undefined) {
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _possible_room = rooms[_i];
			if (_possible_room != _ignored_room && !_possible_room.is_special_room && _possible_room.has_lanterns) { return true; }
		}
		return false;
	};


	// =================================================================================================
	// STEP 6: START EACH DECORATION PASS FROM THE ROLLED CONTENT
	// =================================================================================================

	/// @function reset_decorations()
	/// @description Clears everything steps 7 to 12 placed, so each pass of step 6 decorates the current graph
	///	starting from each room's rolled content.
	static reset_decorations = function() {
		start_room = undefined;
		heart_room = undefined;
		guaranteed_chest_room = undefined;
		cursed_items = [];
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].reset_decorations(); }
		for (var _j = 0; _j < array_length(side_links); _j++) { side_links[_j].reset_decorations(); }
	};


	// =================================================================================================
	// STEP 7: START AND HEART
	// =================================================================================================

	/// @function choose_start_and_heart()
	/// @description Makes the start and heart the two ends of the longest path, including stairs. Then measures every room's distance from the start,
	/// places the cross and the encased heart, and makes the start safe.
	/// @returns {bool} False if no pair is allowed
	static choose_start_and_heart = function() {
		var _longest_distance = -1, _longest_pairs = [];
		
		// Loop through every existing room
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Check if this room can be the start room, and continue if not
			var _start_room = rooms[_i];
			if (!_start_room.can_be_start()) { continue; }
			
			// Measure distance to all rooms from this potential start room
			var _distances = measure_distances(_start_room);
			
			// Loop through every other existing room
			for (var _j = 0; _j < array_length(rooms); _j++) {
				// Check if this room can be the heart room, and continue if not
				var _heart_room = rooms[_j];
				if (!_heart_room.can_be_heart(_start_room)) { continue; }
				
				// If this path is longer than the longest distance, reset the list of possibilities
				var _distance = _distances[_heart_room.mapgen_index];
				if (_distance > _longest_distance) {
					_longest_distance = _distance;
					_longest_pairs = [];
				}
				
				// If this path is equal to the longest distance, add it to the list of possibilities
				if (_distance == _longest_distance) { array_push(_longest_pairs, [_start_room, _heart_room]); }
			}
		}
		
		// Return false if no possible paths were found
		if (array_length(_longest_pairs) == 0) { return false; }

		// Otherwise, select a random possible path to use
		var _pair = array_random_get(_longest_pairs);
		
		// Setup start and heart rooms
		start_room = _pair[0];
		start_room.set_spot_object(obj_cross);
		start_room.remove_random_room_content();
		heart_room = _pair[1];
		heart_room.set_spot_object(obj_encased_heart);
		
		// Assign distance from new start to all rooms
		var _distances_from_start = measure_distances(start_room);
		for (var _k = 0; _k < array_length(rooms); _k++) {
			var _room = rooms[_k];
			_room.distance_to_start = _distances_from_start[_room.mapgen_index];
		}
		
		// Return successful map generation
		return true;
	};


	// =================================================================================================
	// STEP 8: COLLECTABLES AND THE LIT ROOM
	// =================================================================================================

	/// @function place_collectables()
	/// @description The heart always has collectables (R15), every other room but the start rolls them at
	///	1 in 3/3/3/2, and at least ceil(rooms / 4) + 1 rooms get them (R34).
	static place_collectables = function() {
		var _rooms = array_shuffle(rooms), _collectables_rooms = 1;
		heart_room.has_collectables = true;
		for (var _i = 0; _i < array_length(_rooms); _i++) {
			var _room = _rooms[_i];
			if (_room != start_room && _room != heart_room && get_random_chance_out_of(COLLECTABLE_PROBABILITY)) {
				_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}

		var _minimum = ceil(array_length(rooms) / 4) + 1;
		for (var _j = 0; _j < array_length(_rooms) && _collectables_rooms < _minimum; _j++) {
			var _extra_room = _rooms[_j];
			if (_extra_room != start_room && !_extra_room.has_collectables) {
				_extra_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}
	};

	/// @function ensure_a_lit_room()
	/// @description At least one lantern room starts lit; if none rolled lit, lights a random non-sin lantern
	///	room and removes its phantom (R28, R29).
	static ensure_a_lit_room = function() {
		var _lantern_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (!_room.has_lanterns || _room.is_special_room) { continue; }
			if (_room.lit) { return; }
			array_push(_lantern_rooms, _room);
		}
		if (array_length(_lantern_rooms) == 0) {
			write_debug_message("Map has no lantern room to light.", debug_message_level.warning);
			return;
		}
		var _lit_room = array_random_get(_lantern_rooms);
		_lit_room.lit = true;
		_lit_room.has_phantom = false;
	};


	// =================================================================================================
	// STEP 9: CHESTS AND ITEMS
	// =================================================================================================

	/// @function place_chests()
	/// @description Places every chest and picks every item while ignoring the starting hands, so the key check
	///	knows where every torch and cursed key is; step 13 fits the items to the hands later. Only rooms other
	///	than the start and heart hold a chest, one at most (R35).
	static place_chests = function() {
		var _rooms = array_shuffle(rooms);

		// The guaranteed chest holds a map on E, or a map or compass from M. It may be hidden or locked but is
		// never cursed, so it never goes in a sin room (R36)
		for (var _i = 0; _i < array_length(_rooms); _i++) {
			var _guaranteed_room = _rooms[_i];
			if (!_guaranteed_room.is_special_room && can_hold_chest(_guaranteed_room)) {
				_guaranteed_room.place_chest();
				_guaranteed_room.chest_obj = (global.difficulty == difficulties.easy || get_coin_flip()) ? obj_map : obj_compass;
				guaranteed_chest_room = _guaranteed_room;
				break;
			}
		}

		// Each sin room holds a hidden chest with a cursed item, revealed in the sin's own way (R26)
		for (var _j = 0; _j < array_length(_rooms); _j++) {
			var _sin_room = _rooms[_j];
			if (!_sin_room.is_special_room) { continue; }
			_sin_room.set_spot_object(obj_hidden_chest);
			_sin_room.has_hidden_chest = true;
			_sin_room.has_special_item = true;
		}

		// Other rooms hold a chest 1 in 5/4/3/2 (R37)
		for (var _k = 0; _k < array_length(_rooms); _k++) {
			var _room = _rooms[_k];
			if (can_hold_chest(_room) && get_random_chance_out_of(CHEST_PROBABILITY)) { _room.place_chest(); }
		}

		place_cursed_items(_rooms);

		for (var _m = 0; _m < array_length(_rooms); _m++) {
			var _chest_room = _rooms[_m];

			// Visible chests lock 1 in 12/10/6 (M+), and always when the item is cursed (R39)
			if (_chest_room.stairs_spot_obj == obj_chest) {
				_chest_room.has_locked_chest = _chest_room.has_special_item || get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
			}

			// Plain chests (visible, unlocked and not cursed) hold a statue or fountain trap 1 in 8/4 (H+), but
			// never the guaranteed chest (R41)
			if (_chest_room != guaranteed_chest_room && _chest_room.has_plain_chest() && get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) {
				_chest_room.chest_obj = get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY) ? obj_fountain : obj_statue;
			}
		}

		// Every other chest gets an item (R42)
		for (var _n = 0; _n < array_length(_rooms); _n++) {
			var _item_room = _rooms[_n];
			if (_item_room.has_chest() && _item_room.chest_obj == -1) {
				_item_room.chest_obj = pick_item_type(_item_room.has_special_item, []);
			}
		}
	};

	/// @function place_cursed_items(_rooms)
	/// @description Marks exactly the step 2 count of cursed items outside sin rooms, each in a chest at least
	///	two rooms from the start, adding chests when too few exist (R40). The guaranteed chest is never
	///	cursed (R36).
	/// @param {array} _rooms The map's rooms, in random order
	static place_cursed_items = function(_rooms) {
		var _left_to_place = cursed_item_count;

		// Chests already placed
		for (var _i = 0; _i < array_length(_rooms) && _left_to_place > 0; _i++) {
			var _chest_room = _rooms[_i];
			if (_chest_room.has_chest() && !_chest_room.has_special_item && _chest_room != guaranteed_chest_room && _chest_room.distance_to_start >= 2) {
				_chest_room.has_special_item = true;
				_left_to_place -= 1;
			}
		}

		// New chests, when too few exist
		for (var _j = 0; _j < array_length(_rooms) && _left_to_place > 0; _j++) {
			var _empty_room = _rooms[_j];
			if (can_hold_chest(_empty_room) && _empty_room.distance_to_start >= 2) {
				_empty_room.place_chest();
				_empty_room.has_special_item = true;
				_left_to_place -= 1;
			}
		}

		if (_left_to_place > 0) { write_debug_message("No room left for " + string(_left_to_place) + " cursed item(s).", debug_message_level.warning); }
	};

	/// @function pick_item_type(_is_cursed, _hands)
	/// @description Picks an item uniformly among the types still allowed (R42). A cursed item can be any
	///	type, keys included, but each cursed type appears once at most. A regular item is never a key, and
	///	types at their cap, counting chests and the hands, drop out of the pool.
	/// @param {bool} _is_cursed Whether the item is cursed
	/// @param {array} _hands The starting hand items to count, or [] to ignore the hands
	/// @returns {Asset.GMObject}
	static pick_item_type = function(_is_cursed, _hands) {
		var _types = global.available_items[global.difficulty], _choices = [];
		for (var _i = 0; _i < array_length(_types); _i++) {
			var _type = _types[_i];
			if (_is_cursed) {
				if (!array_contains(cursed_items, _type)) { array_push(_choices, _type); }
			}
			else if (_type != obj_key && count_regular_items(_type, _hands) < get_item_cap(_type)) {
				array_push(_choices, _type);
			}
		}
		if (array_length(_choices) == 0) {
			write_debug_message("No item type left to pick, so a torch spawns instead.", debug_message_level.warning);
			return obj_torch;
		}

		var _item = array_random_get(_choices);
		if (_is_cursed) { array_push(cursed_items, _item); }
		return _item;
	};

	/// @function count_regular_items(_type, _hands)
	/// @description Counts the regular (non-cursed) copies of an item in chests and hands. Keys and bombs the
	///	key step placed don't count, and neither does a torch in the guaranteed chest, which may always go over
	///	the cap (step 13).
	/// @param {Asset.GMObject} _type The item
	/// @param {array} _hands The starting hand items to count
	/// @returns {real}
	static count_regular_items = function(_type, _hands) {
		var _count = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (_room == guaranteed_chest_room && _room.chest_obj == obj_torch) { continue; }
			if (_room.chest_obj == _type && !_room.has_special_item && !_room.key_in_chest) { _count += 1; }
		}
		for (var _j = 0; _j < array_length(_hands); _j++) {
			if (_hands[_j] == _type) { _count += 1; }
		}
		return _count;
	};

	/// @function get_item_cap(_item)
	/// @description How many regular copies of an item chests and starting hands may hold together (R42).
	/// @param {Asset.GMObject} _item The item
	/// @returns {real}
	static get_item_cap = function(_item) {
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
	};

	/// @function can_hold_chest(_room)
	/// @description Whether a room can take a chest: never the start or heart, and one chest per room (R35).
	/// @param {GameRoom} _room The room
	/// @returns {bool}
	static can_hold_chest = function(_room) {
		return _room != start_room && _room != heart_room && _room.stairs_spot_obj == -1;
	};


	// =================================================================================================
	// STEPS 10 AND 11: LOCKS AND KEYS
	// =================================================================================================

	/// @function place_locks_and_keys()
	/// @description Locks every heart side exit, then rolls a random lock on each other side exit, backing each
	///	lock with keys before the next is added (R14, R43, R50).
	/// @returns {bool} False if the heart locks could not be backed (a last resort, never expected)
	static place_locks_and_keys = function() {
		// Every side exit of the heart is locked; the map only needs enough keys to get in once (R14)
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _heart_exit = heart_room.exits[_dir];
			if (_heart_exit != -1) { _heart_exit.set_lock(true); }
		}
		if (!back_locks_with_keys(undefined)) { return false; }

		// Other side exits lock 1 in 8/6/5/4, one at a time (R43)
		var _exits = array_shuffle(side_links);
		for (var _i = 0; _i < array_length(_exits); _i++) {
			var _exit = _exits[_i];
			if (!can_lock_exit(_exit) || !get_random_chance_out_of(LOCKED_DOOR_PROBABILITY / 2)) { continue; }
			_exit.set_lock(true);
			if (!back_locks_with_keys(_exit)) { return false; }
		}
		return true;
	};

	/// @function back_locks_with_keys(_newest_lock)
	/// @description Runs the every-order key check, and wherever the player could get stuck adds a key-role
	///	item in the area they're stuck in, until no order of spending keys can strand them (R44, R50). If no
	///	room there can take one, the newest lock moves to another eligible exit, so the lock count stays as
	///	rolled; dropping it is the last resort, and heart locks never move.
	/// @param {RoomExit|undefined} _newest_lock The random lock just added, or undefined for the heart locks
	/// @returns {bool} False if a lock no key can back cannot move either
	static back_locks_with_keys = function(_newest_lock) {
		var _tried_exits = [_newest_lock];
		while (true) {
			var _stuck_area = check_key_orders();
			if (is_undefined(_stuck_area)) { return true; }
			if (add_key_role_item(_stuck_area)) { continue; }

			// No room in the stuck area can take another key, so move the newest lock
			if (is_undefined(_newest_lock)) {
				write_debug_message("No room could take a key for a lock that cannot move.", debug_message_level.warning);
				return false;
			}
			_newest_lock.set_lock(false);
			_newest_lock = pick_untried_lockable_exit(_tried_exits);
			if (is_undefined(_newest_lock)) {
				write_debug_message("Dropped a lock that no key could back (R50).", debug_message_level.warning);
				continue;
			}
			_newest_lock.set_lock(true);
			array_push(_tried_exits, _newest_lock);
		}
	};

	/// @function add_key_role_item(_stuck_area)
	/// @description Adds a key-role item in a random room of a stuck area that can take one: on a random
	///	collectable spot, or 1 in 3 in a new plain chest when the room has no chest (R47, R48, R57). From M a
	///	bomb can stand in for a chest key, but only where it counts as one (R46, R49).
	/// @param {struct} _stuck_area Where the player is stuck (see check_key_orders)
	/// @returns {bool} False if no room there can take one
	static add_key_role_item = function(_stuck_area) {
		// A room holds at most one key-role item, and the heart holds none (R47)
		var _candidates = [];
		for (var _i = 0; _i < array_length(_stuck_area.rooms); _i++) {
			var _candidate = _stuck_area.rooms[_i];
			if (_candidate != heart_room && !_candidate.has_key && array_length(_candidate.layout.key_spots) > 0) { array_push(_candidates, _candidate); }
		}
		if (array_length(_candidates) == 0) { return false; }

		var _room = array_random_get(_candidates);
		_room.has_key = true;
		if (can_hold_chest(_room) && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) {
			// The chest is never locked, hidden or cursed (R48)
			_room.key_in_chest = true;
			_room.set_spot_object(obj_chest);
			var _use_bomb = _stuck_area.can_use_bombs && get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY);
			_room.chest_obj = _use_bomb ? obj_bomb : obj_key;
		}
		else {
			_room.key_spot = array_random_get(_room.layout.key_spots);
		}
		return true;
	};

	/// @function can_lock_exit(_exit)
	/// @description Whether a random lock can go on a side exit: never on a start-room exit or an exit into a
	///	hall of mirrors (R43, R27), and never twice.
	/// @param {RoomExit} _exit A side exit
	/// @returns {bool}
	static can_lock_exit = function(_exit) {
		var _room_1 = _exit.room_1, _room_2 = _exit.room_2;
		return !_exit.has_lock
			&& _room_1 != start_room && _room_2 != start_room
			&& !_room_1.has_hall_of_mirrors && !_room_2.has_hall_of_mirrors;
	};

	/// @function pick_untried_lockable_exit(_tried_exits)
	/// @description Picks a random side exit a lock can move to, among those not tried yet (R50).
	/// @param {array} _tried_exits Exits this lock already tried
	/// @returns {RoomExit|undefined} The exit, or undefined if none is left
	static pick_untried_lockable_exit = function(_tried_exits) {
		var _candidates = [];
		for (var _i = 0; _i < array_length(side_links); _i++) {
			var _exit = side_links[_i];
			if (can_lock_exit(_exit) && !array_contains(_tried_exits, _exit)) { array_push(_candidates, _exit); }
		}
		return (array_length(_candidates) > 0) ? array_random_get(_candidates) : undefined;
	};

	/// @function check_key_orders()
	/// @description The every-order key check (R44 to R46): looks for any order of spending keys, on locked doors
	///	and locked chests alike, that leaves rooms unreached and no key in hand.
	///	The search moves through areas: the rooms the player can reach, plus which locked chests that matter
	///	they have opened. In the worst order, they spend a key on every lock in the area that leads nowhere new
	///	(each locked door inside it, the ones they opened to get there among them, and each locked chest that
	///	doesn't matter), as well as on each chest that matters they opened. If that leaves them no key while
	///	rooms remain unreached, they are stuck. Otherwise they still hold a key in every order, so they can open
	///	a locked door at the area's edge or a chest that matters, and each choice leads to a new area to check.
	///	Areas are checked in the order found, so the first stuck area is one near the start.
	/// @returns {struct|undefined} Where the player is stuck, as { rooms, can_use_bombs }, or undefined when
	///	every key order reaches every room
	static check_key_orders = function() {
		// A locked chest matters if what it holds can change the outcome: a cursed key, or a torch while bombs
		// stand in for keys. Opening any other locked chest only uses up a key, like a locked door inside the area
		var _bombs_stand_in = false;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			if (rooms[_i].has_key && rooms[_i].key_in_chest && rooms[_i].chest_obj == obj_bomb) { _bombs_stand_in = true; }
		}
		var _locked_doors = [], _chests_that_matter = [];
		for (var _j = 0; _j < array_length(side_links); _j++) {
			if (side_links[_j].has_lock) { array_push(_locked_doors, side_links[_j]); }
		}
		for (var _k = 0; _k < array_length(rooms); _k++) {
			var _room = rooms[_k];
			var _holds_cursed_key = (_room.chest_obj == obj_key && _room.has_special_item);
			var _holds_needed_torch = (_room.chest_obj == obj_torch && _bombs_stand_in);
			_room.mapgen_chest_lock = -1;
			if (_room.has_locked_chest && (_holds_cursed_key || _holds_needed_torch)) {
				_room.mapgen_chest_lock = array_length(_chests_that_matter);
				array_push(_chests_that_matter, _room);
			}
		}

		var _every_room = (1 << array_length(rooms)) - 1;
		var _areas = [], _queued = {};
		queue_key_order_area(_areas, _queued, reach_rooms(0, start_room), 0);
		for (var _next = 0; _next < array_length(_areas); _next++) {
			var _area = _areas[_next];
			var _haul = count_haul(_area);

			// Nothing left to get stuck on: every room is reached, or a cursed key opens every lock from here (R45)
			if (_area.reached == _every_room || _haul.has_cursed_key) { continue; }

			// The worst order's keys left: the keys collected, minus a key for every lock inside the area and every
			// chest that matters opened. Bombs count as keys only with a lit room and a torch chest in reach (R46)
			var _locks_inside = _haul.locked_chests_that_dont_matter;
			for (var _door = 0; _door < array_length(_locked_doors); _door++) {
				var _door_exit = _locked_doors[_door];
				if (_door_exit.room_1.is_in_bitmask(_area.reached) && _door_exit.room_2.is_in_bitmask(_area.reached)) { _locks_inside += 1; }
			}
			var _can_use_bombs = _haul.has_lit_room && _haul.has_torch_chest;
			var _keys_collected = _haul.keys + (_can_use_bombs ? _haul.bombs : 0);
			var _keys_left = _keys_collected - _locks_inside - count_bits(_area.opened_chests);
			if (_keys_left <= 0) { return { rooms: list_reached_rooms(_area.reached), can_use_bombs: _can_use_bombs }; }

			// A key opens a locked door at the edge of the area, reaching the rooms behind it...
			for (var _edge = 0; _edge < array_length(_locked_doors); _edge++) {
				var _edge_exit = _locked_doors[_edge];
				var _room_1_reached = _edge_exit.room_1.is_in_bitmask(_area.reached);
				var _room_2_reached = _edge_exit.room_2.is_in_bitmask(_area.reached);
				if (_room_1_reached == _room_2_reached) { continue; }
				var _far_room = _room_1_reached ? _edge_exit.room_2 : _edge_exit.room_1;
				queue_key_order_area(_areas, _queued, reach_rooms(_area.reached, _far_room), _area.opened_chests);
			}
			// ...or a locked chest that matters, in the area
			for (var _chest = 0; _chest < array_length(_chests_that_matter); _chest++) {
				var _opened_chests = _area.opened_chests | (1 << _chest);
				if (_opened_chests == _area.opened_chests || !_chests_that_matter[_chest].is_in_bitmask(_area.reached)) { continue; }
				queue_key_order_area(_areas, _queued, _area.reached, _opened_chests);
			}
		}
		return undefined;
	};

	/// @function queue_key_order_area(_areas, _queued, _reached, _opened_chests)
	/// @description Adds an area to the key check's search, unless the same area was already added.
	/// @param {array} _areas The areas to check, in order
	/// @param {struct} _queued Every area added so far, by its key
	/// @param {real} _reached Bitmask of the rooms reached, by mapgen_index
	/// @param {real} _opened_chests Bitmask of the locked chests that matter opened
	static queue_key_order_area = function(_areas, _queued, _reached, _opened_chests) {
		var _key = string(_reached) + "," + string(_opened_chests);
		if (!is_undefined(_queued[$ _key])) { return; }
		_queued[$ _key] = true;
		array_push(_areas, { reached: _reached, opened_chests: _opened_chests });
	};

	/// @function reach_rooms(_reached, _from_room)
	/// @description Adds a room, and every room walkable from it through unlocked exits and stairs, to a set of
	///	reached rooms.
	/// @param {real} _reached Bitmask of the rooms already reached, by mapgen_index
	/// @param {GameRoom} _from_room The room to walk from
	/// @returns {real} The new bitmask
	static reach_rooms = function(_reached, _from_room) {
		var _queue = [_from_room];
		_reached |= (1 << _from_room.mapgen_index);
		for (var _next = 0; _next < array_length(_queue); _next++) {
			var _room = _queue[_next];
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				var _exit = _room.exits[_dir];
				if (_exit == -1 || _exit.has_lock) { continue; }
				var _other_room = _exit.get_connected_room(_room);
				if (_other_room.is_in_bitmask(_reached)) { continue; }
				_reached |= (1 << _other_room.mapgen_index);
				array_push(_queue, _other_room);
			}
		}
		return _reached;
	};

	/// @function count_haul(_area)
	/// @description Counts what the player can collect in an area of the key check. Key-role items lie on the
	///	floor or in plain chests, so reaching their room is enough. A chest's item counts only if the chest is
	///	visible, and unlocked or opened; hidden chests never count.
	/// @param {struct} _area The area (see queue_key_order_area)
	/// @returns {struct} { keys, bombs, has_lit_room, has_torch_chest, has_cursed_key, locked_chests_that_dont_matter }
	static count_haul = function(_area) {
		var _haul = { keys: 0, bombs: 0, has_lit_room: false, has_torch_chest: false, has_cursed_key: false, locked_chests_that_dont_matter: 0 };
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (!_room.is_in_bitmask(_area.reached)) { continue; }

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
	};

	/// @function list_reached_rooms(_reached)
	/// @description The rooms in a bitmask of reached rooms.
	/// @param {real} _reached Bitmask of rooms, by mapgen_index
	/// @returns {array}
	static list_reached_rooms = function(_reached) {
		var _rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			if (rooms[_i].is_in_bitmask(_reached)) { array_push(_rooms, rooms[_i]); }
		}
		return _rooms;
	};


	// =================================================================================================
	// STEP 12: ILLUSION WALLS, PORTCULLIS TRAPS AND PLAIN DOORS
	// =================================================================================================

	/// @function place_special_exits()
	/// @description Adds illusion walls, portcullis traps and plain doors, room by room in random order, as
	///	today's code does. An exit holds at most one of them, so each room rolls its illusion walls first, then
	///	maybe a trap, then its doors, and what an earlier room placed rules out later rolls on the same exit.
	///	None of them change which rooms the player can reach, so they come after the keys. Stairs-only rooms,
	///	the start, the heart, halls of mirrors and their neighbors never roll any of them themselves (R54).
	static place_special_exits = function() {
		var _rooms = array_shuffle(rooms), _door_rolled_exits = [];
		for (var _i = 0; _i < array_length(_rooms); _i++) {
			var _room = _rooms[_i];
			if (!can_roll_special_exits(_room)) { continue; }

			// Illusion walls (H+): 1 in 32/16 for each side exit, never on a door, a lock, a portcullis or an exit
			// into the start (R51)
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				var _exit = _room.exits[_dir];
				if (_exit == -1 || _exit.has_door || _exit.room_1_has_closed_portcullis || _exit.room_2_has_closed_portcullis) { continue; }
				if (_exit.get_connected_room(_room) == start_room) { continue; }
				if (get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) { _exit.has_illusion_walls = 1; }
			}

			// A portcullis trap (M+): 1 in 12/8/6 (R52)
			if (can_take_portcullis(_room) && get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { _room.add_portcullis_trap(); }

			// Plain doors: 1 in 64/48/24/16, rolled once per side exit, never on a lock, an illusion wall or a
			// portcullis exit (R53). A room next to the start can still put one on the exit they share
			for (var _door_dir = directions.up; _door_dir < directions.stairs; _door_dir++) {
				var _door_exit = _room.exits[_door_dir];
				if (_door_exit == -1 || array_contains(_door_rolled_exits, _door_exit)) { continue; }
				if (_door_exit.has_lock || _door_exit.has_illusion_walls > 0) { continue; }
				if (_room.has_portcullis_button || _door_exit.get_connected_room(_room).has_portcullis_button) { continue; }
				array_push(_door_rolled_exits, _door_exit);
				if (get_random_chance_out_of(OPEN_DOOR_PROBABILITY * 2)) { _door_exit.has_door = true; }
			}
		}
	};

	/// @function can_roll_special_exits(_room)
	/// @description Whether a room rolls illusion walls, portcullis traps and plain doors itself (R54).
	/// @param {GameRoom} _room The room
	/// @returns {bool}
	static can_roll_special_exits = function(_room) {
		return !_room.has_no_cardinal_exits && _room != start_room && _room != heart_room
			&& !_room.is_connected_to_hall_of_mirrors();
	};

	/// @function can_take_portcullis(_room)
	/// @description Whether a room can take a portcullis trap (R52, R53): it rolls special exits itself (which
	///	rules out the start, heart and stairs-only rooms), none of its side exits has a door (locked or plain) or
	///	an illusion wall, no neighbor has a trap, and its button has a free spot.
	/// @param {GameRoom} _room The room
	/// @returns {bool}
	static can_take_portcullis = function(_room) {
		if (!can_roll_special_exits(_room)) { return false; }
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _exit = _room.exits[_dir];
			if (_exit == -1) { continue; }
			if (_exit.has_door || _exit.has_illusion_walls > 0 || _exit.get_connected_room(_room).has_portcullis_button) { return false; }
		}
		return array_length(_room.list_button_spots()) > 0;
	};


	// =================================================================================================
	// STEP 13: THE STARTING HANDS
	// Each room's score and time are GameRoom methods (get_difficulty_score, get_time_provided), which
	// the calculations below add up
	// =================================================================================================

	/// @function adjust_items_for_hands()
	/// @description The very last step, once the map is final (step 13): fits the chest items to the starting
	///	hands. The guaranteed chest becomes the map, compass or torch the hands call for (R36), and any regular
	///	item over its cap once the hands count is re-picked (R42), unless that would strand the player, like
	///	taking the torch a bomb needs to stand in for a key (R46). Nothing else changes; the map never relies on
	///	the starting items (R45). Runs in its own random stream (see mapgen_generate).
	static adjust_items_for_hands = function() {
		var _hands = [global.player_left_hand_item, global.player_right_hand_item];
		var _brings_map = array_contains(_hands, obj_map), _brings_compass = array_contains(_hands, obj_compass);
		var _guaranteed = guaranteed_chest_room;
		if (!is_undefined(_guaranteed)) {
			if (_brings_map && _brings_compass) { _guaranteed.chest_obj = obj_torch; }
			else if (_brings_compass) { _guaranteed.chest_obj = obj_map; }
			else if (_brings_map) { _guaranteed.chest_obj = (global.difficulty == difficulties.easy) ? obj_torch : obj_compass; }
		}

		var _rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_rooms); _i++) {
			var _room = _rooms[_i];
			if (_room == _guaranteed || !_room.holds_regular_item()) { continue; }
			if (count_regular_items(_room.chest_obj, _hands) > get_item_cap(_room.chest_obj)) {
				var _item = _room.chest_obj;
				_room.chest_obj = -1;
				_room.chest_obj = pick_item_type(false, _hands);

				// The item stays, over its cap, if the map needs it to stay winnable (R46)
				if (!is_undefined(check_key_orders())) { _room.chest_obj = _item; }
			}
		}
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