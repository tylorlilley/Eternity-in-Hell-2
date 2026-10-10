/// @function GameMap()
/// @description The plan for one map, and the methods that generate it: the layouts its difficulty allows, its rooms
///	and the exits between them, its map-wide events and decorations, and what the controller keeps once generation
///	ends. Rooms and exits are only added through its methods, so its lookups always match its rooms. The first map of
///	a session also reads every room asset's layout file into the layout cache that every map shares.
function GameMap() constructor {
	// The four directions a cardinal exit can face
	static cardinal_exit_directions = [directions.up, directions.right, directions.down, directions.left];

	// Set up the layout cache every map shares, the first time a map is made
	static layout_cache = undefined;
	if (is_undefined(layout_cache)) {
		var _layouts = [], _special_room_types = [
			new SpecialRoomType("pride", [rm_four_exits_23, rm_four_exits_24]),						// Hall of mirrors
			new SpecialRoomType("envy", [rm_four_exits_22, rm_one_exit_27, rm_three_exits_30]),		// Giant eye
			new SpecialRoomType("wrath", [rm_one_exit_22]),											// Inverted cross
			new SpecialRoomType("greed", [rm_one_exit_30]),											// Red chest
			new SpecialRoomType("sloth", [rm_one_exit_23])											// Gudetama
		];

		// Read each room asset as a layout, and keep the usable ones (see RoomLayout)
		for (var _room_asset = room_first; _room_asset != -1; _room_asset = room_next(_room_asset)) {
			var _layout = new RoomLayout(_room_asset);
			if (!_layout.is_usable) { continue; }
			_layout.index = array_length(_layouts);

			// Mark the layout as a special room if a special room type uses it, swapping it in for the type's room asset
			for (var _i = 0; _i < array_length(_special_room_types); _i++) {
				var _special_room_type = _special_room_types[_i];

				for (var _j = 0; _j < array_length(_special_room_type.layouts); _j++) {
					var _special_room_layout = _special_room_type.layouts[_j];

					if (_special_room_layout == _layout.room_reference) {
						_layout.is_special_room = true;
						_special_room_type.layouts[_j] = _layout;
						break;
					}
				}
			}

			// Work out the lowest difficulty it appears on, now that it knows whether it's a special room
			_layout.determine_minimum_difficulty();
			array_push(_layouts, _layout);
		}
		layout_cache = { layouts: _layouts, special_room_types: _special_room_types };
	}

	// Layouts this difficulty allows for regular (not special) rooms by exit kind, and how many rooms use each
	layouts_by_exit_type = [];
	layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

	// Special room types with a layout this difficulty allows, each with only those layouts
	available_special_room_types = [];

	// Map-wide events (see roll_map_events)
	long_and_straight_map = false;
	same_skeleton_type = noone;
	special_item_count = 0;
	included_special_room_types = [];

	// The rooms, and the exits between them
	rooms = [];
	room_at_cell = {};						// Each room by its grid cell ("x,y"), so finding an adjacent room needs no search
	cardinal_exits = [];						// Every exit joining two adjacent rooms, which is every exit but the stairs

	// Decorations, cleared and placed again each time try_generate adds a room (see reset_decorations)
	start_room = undefined;
	heart_room = undefined;
	guaranteed_chest_room = undefined;
	special_item_types = [];						// Each item type placed as a special item so far
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
		if (_layout.minimum_difficulty <= global.difficulty && !_layout.is_special_room) {
			array_push(layouts_by_exit_type[_layout.exit_type], _layout);
		}
	}

	// For each special room type, keep the layouts the difficulty allows, and the type itself if any are left
	for (var _j = 0; _j < array_length(layout_cache.special_room_types); _j++) {
		var _special_room_type = layout_cache.special_room_types[_j], _allowed_layouts = [];

		for (var _k = 0; _k < array_length(_special_room_type.layouts); _k++) {
			if (is_struct(_special_room_type.layouts[_k]) && _special_room_type.layouts[_k].minimum_difficulty <= global.difficulty) { array_push(_allowed_layouts, _special_room_type.layouts[_k]); }
		}
		if (array_length(_allowed_layouts) > 0) { array_push(available_special_room_types, new SpecialRoomType(_special_room_type.name, _allowed_layouts)); }
	}

	// Check that every exit type has at least one layout, and at least one layout with a lantern. This should always be true, but good to check.
	for (var _type_checked = 0; _type_checked < layout_exit_types.count; _type_checked++) {
		var _layouts_of_type = layouts_by_exit_type[_type_checked];
		if (array_length(_layouts_of_type) == 0) {
			var _error_message = "No layout of exit kind " + string(_type_checked) + " at this difficulty: " + string(global.difficulty);
			write_debug_message(_error_message, debug_message_level.error);
		}

		if (array_length(get_only_lantern_layouts(_layouts_of_type)) == 0) {
			var _error_message = "No lantern layout of exit kind " + string(_type_checked) + " at this difficulty."
			write_debug_message(_error_message, debug_message_level.error);
		}
	}

	// =========
	// FUNCTIONS
	// =========

	/// @function try_generate()
	/// @description Makes one attempt at generating the map. It rolls the map-wide events and adds rooms until the map has
	///	MINIMUM_NUMBER_OF_ROOMS, then keeps adding one room at a time. After each room from the minimum on, it assigns
	///	layouts to the rooms that need them, then decorates and scores the whole map, until the score reaches
	///	MAP_DIFFICULTY_SCORE_TARGET or the map has MAX_NUMBER_OF_ROOMS rooms. A failed attempt destroys the map.
	/// @returns {bool} False if the attempt failed, so a new map has to be tried
	static try_generate = function() {
		// Roll the map-wide events, including the special room types and special items
		roll_map_events();

		// Grow the map to one room short of the minimum, without assigning layouts, since the loop below adds a room first
		create_room_at_cell(0, 0);
		while (array_length(rooms) < MINIMUM_NUMBER_OF_ROOMS - 1) {
			if (is_undefined(add_new_room())) { return fail_generation("no room could grow"); }
		}

		// Add a room, assign layouts, then decorate and score the map, until it scores enough or has as many rooms as allowed
		var _first_pass = true;
		do {
			// Add another room. If none can be added, the first pass fails, and a later pass ends the map as the last pass left it
			if (is_undefined(add_new_room())) {
				if (!_first_pass) break;
				else { return fail_generation("no room could grow"); }
			}
			
			// Link more adjacent rooms, up to the average number of exits a room should have
			link_adjacent_rooms();
			
			// On the first pass, also reserve a room for each special room type, then make sure a room can still be the start.
			// This only happens once, since the special rooms can add rooms and exits to the map, which are never removed. The
			// start check only needs to happen here too, in case a special room took the last room that could have been the start.
			if (_first_pass) {
				_first_pass = false;
				if (!find_or_create_special_rooms()) { return fail_generation("no room could be shaped for a special room"); }
				if (!find_or_create_starting_rooms()) { return fail_generation("no room could be created as a starting room"); }
			}
			
			// Assign a layout to each room whose cardinal exits changed, with its random orientation and content
			assign_room_layouts();
			
			// Clear the last pass's decorations, and place them again
			reset_decorations();
			if (!determine_start_and_heart_rooms()) { return fail_generation("the start and heart could not be placed"); }
			determine_collectables_rooms();
			find_or_set_one_lit_room();
			create_chests();
			assign_or_create_special_item_chests();
			assign_chest_contents();
			if (!create_locked_exits_and_keys()) { return fail_generation("the locks and keys could not be placed"); }
			determine_special_exit_types();
			
			// Score the map, from how likely the player is to arrive at each room holding the items that counter its hazards
			calculate_item_chances();
			calculate_map_difficulty_score();
		}
		until (difficulty_score >= MAP_DIFFICULTY_SCORE_TARGET || array_length(rooms) >= MAX_NUMBER_OF_ROOMS);
	
		// Calculate the time provided for the final map
		calculate_time_provided();
		return true;
	};

	/// @function roll_map_events()
	/// @description Rolls what is decided once per map, before any room exists: the map-wide events, the special room
	///	types the map includes, and how many special items spawn outside special rooms
	static roll_map_events = function() {
		// Set the Map Shape and Same Skeleton Type Events
		long_and_straight_map = get_random_chance_out_of(SPECIAL_MAP_SHAPE_PROBABILITY); // TODO: Implement this and other shapes. Add eval messages
		same_skeleton_type = get_random_chance_out_of(SAME_SKELETON_TYPE_PROBABILITY) ? get_skeleton_type(false) : noone; // TODO: Add eval messages

		// Roll how many special rooms to include, at most one for each special room type the difficulty allows
		var _special_room_types_left = array_get_duplicate(available_special_room_types), _special_room_limit = SPECIAL_ROOM_LIMIT, _special_room_count = 0;
		for (var _i = 0; _i < _special_room_limit; _i++) {
			if (get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY)) { _special_room_count += 1; }
		}
		_special_room_count = min(_special_room_count, array_length(_special_room_types_left));
		
		// Include that many special room types, picked at random
		for (var _i = 0; _i < _special_room_count; _i++) {
			array_push(included_special_room_types, array_random_pop(_special_room_types_left));
		}

		// Roll how many special items spawn outside special rooms. Each special room holds one, which counts toward the limit
		var _special_item_limit = SPECIAL_ITEM_LIMIT, _special_item_count = 0;
		for (var _i = _special_room_count; _i < _special_item_limit; _i++) {
			if (get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { _special_item_count += 1; }
		}
		special_item_count = _special_item_count;
	};

	/// @function create_room_at_cell(_x, _y)
	/// @description Adds a room on a free grid cell, with no exits or layout yet
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom} The new room
	static create_room_at_cell = function(_x, _y) {
		var _room = new GameRoom(_x, _y);
		
		// Add room to map's rooms array, and room_at_cell lookup table
		_room.mapgen_index = array_length(rooms);
		array_push(rooms, _room);
		room_at_cell[$ get_cell_key(_x, _y)] = _room;
		
		return _room;
	};

	/// @function link_rooms_with_new_exit(_room, _other_room, _dir)
	/// @description Joins two rooms with a new exit, a cardinal exit or stairs
	/// @param {GameRoom} _room One room
	/// @param {GameRoom} _other_room The other room
	/// @param {real} _dir The direction from _room to _other_room, or directions.stairs
	/// @returns {RoomExit} The new exit
	static link_rooms_with_new_exit = function(_room, _other_room, _dir) {
		// Create the exit, and add it to each room's exits, in the direction of the other room
		var _exit = new RoomExit(_room, _other_room);
		_room.exits[_dir] = _exit;
		_other_room.exits[get_opposite_dir(_dir)] = _exit;
		
		// A cardinal exit joins the map's cardinal exits, and both rooms need a new layout that opens onto it
		if (_dir != directions.stairs) {
			array_push(cardinal_exits, _exit);
			_room.mapgen_needs_layout = true;
			_other_room.mapgen_needs_layout = true;
		}
		
		return _exit;
	};

	/// @function get_cell_key(_x, _y)
	/// @description The key a grid cell has in room_at_cell
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {string}
	static get_cell_key = function(_x, _y) {
		return string(_x) + "," + string(_y);
	};

	/// @function get_room_at(_x, _y)
	/// @description The room on a grid cell
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom|undefined} The room, or undefined if the cell is free
	static get_room_at = function(_x, _y) {
		return room_at_cell[$ get_cell_key(_x, _y)];
	};

	/// @function get_adjacent_room(_room, _dir)
	/// @description The room on the grid cell beside a room, linked to it or not
	/// @param {GameRoom} _room The room
	/// @param {real} _dir A cardinal direction
	/// @returns {GameRoom|undefined} The adjacent room, or undefined if the cell is free
	static get_adjacent_room = function(_room, _dir) {
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
	/// @description Counts how many exits the player goes through from one room to every other, by the quickest route
	///	through cardinal exits and stairs, ignoring locks
	/// @param {GameRoom} _from_room The room to measure from
	/// @returns {array} The count to each room, by mapgen_index
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

	/// @function fail_generation(_reason)
	/// @description Logs a failed attempt and destroys this map
	/// @param {string} _reason What failed
	/// @returns {bool} Always false, so try_generate can return it
	static fail_generation = function(_reason) {
		write_debug_message("Map generation attempt failed, retrying on the same random stream: " + _reason, debug_message_level.warning);
		destroy();
		return false;
	};

	/// @function add_new_room([_allow_stairs])
	/// @description Adds one room to the map, joined to a random room by a cardinal exit or stairs
	/// @param {bool} [_allow_stairs] False to always join by a cardinal exit (true by default)
	/// @returns {GameRoom|undefined} The new room, or undefined if no room can grow
	static add_new_room = function(_allow_stairs = true) {
		// Stairs never take the last room the start could use, since the start has no stairs
		var _stairs_allowed = _allow_stairs && (count_possible_starts() > 1);
		var _existing_rooms = array_shuffle(rooms), _linked_room = undefined;

		// Check all existing rooms for a room we can add an exit to
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _potential_room = _existing_rooms[_i];
			if (!_potential_room.can_gain_exits()) { continue; }

			// Sometimes join the new room by stairs, if this room has none yet
			if (_stairs_allowed && !_potential_room.has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
				// Find a free grid cell for the new room, not beside this one
				var _cell = find_unoccupied_non_adjacent_cell(_potential_room);
				
				// Create new room to link via stairs in that grid cell
				if (!is_undefined(_cell)) {
					_linked_room = create_room_at_cell(_cell[0], _cell[1]);
					link_rooms_with_new_exit(_potential_room, _linked_room, directions.stairs);

					// Sometimes the new room can only ever be reached by stairs
					_linked_room.has_no_cardinal_exits = get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY);
				}
			}

			// Otherwise, connect via a cardinal direction
			if (is_undefined(_linked_room)) {
				var _dir = find_unoccupied_adjacent_cell_direction(_potential_room);
				if (_dir != -1) {
					_linked_room = create_room_at_cell(_potential_room.virtual_x + get_dir_x_offset(_dir), _potential_room.virtual_y + get_dir_y_offset(_dir));
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
	/// @description Finds a free grid cell for a new room that stairs will link to a given room: a cell beside a random
	///	room of the map, but not beside the given room
	/// @param {GameRoom} _linked_room The room the stairs leave from
	/// @returns {array|undefined} The cell as [x, y], or undefined if there is none
	static find_unoccupied_non_adjacent_cell = function(_linked_room) {
		var _existing_rooms = array_shuffle(rooms);
		
		// Check each existing room for a free adjacent cell
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			var _potential_room = _existing_rooms[_i];
			
			// Check each position adjacent to this room
			var _dirs = array_shuffle(cardinal_exit_directions);
			for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
				var _x = _potential_room.virtual_x + get_dir_x_offset(_dirs[_dir]);
				var _y = _potential_room.virtual_y + get_dir_y_offset(_dirs[_dir]);
				var _is_adjacent_to_linked_room = (abs(_x - _linked_room.virtual_x) + abs(_y - _linked_room.virtual_y) == 1);
				var _cell_is_already_occupied = !is_undefined(get_room_at(_x, _y));
				
				// Continue to the next direction if this cell is taken, or beside the linked room
				if (_is_adjacent_to_linked_room || _cell_is_already_occupied) { continue; }
				
				// Return the current x and y position for making a new room in
				return [_x, _y];
			}
		}
		
		// Return undefined if no free cell is found
		return undefined;
	};

	/// @function find_unoccupied_adjacent_cell_direction(_room)
	/// @description Picks a random cardinal direction from a room whose adjacent grid cell is free
	/// @param {GameRoom} _room The room
	/// @returns {real} The direction, or -1 if every side is taken
	static find_unoccupied_adjacent_cell_direction = function(_room) {
		// Check the map grid for each space adjacent to the given room
		var _dirs = array_shuffle(cardinal_exit_directions);
		for (var _dir = 0; _dir < array_length(_dirs); _dir++) {
			// If the map grid's cell is unoccupied at this space, return this direction
			if (is_undefined(get_adjacent_room(_room, _dirs[_dir]))) { return _dirs[_dir]; }
		}
		
		// If no adjacent map grid cells are unoccupied, return -1
		return -1;
	};

	/// @function link_adjacent_rooms()
	/// @description Links adjacent rooms with new cardinal exits until the rooms average AVERAGE_NUMBER_OF_ROOM_EXITS
	///	cardinal exits each, stopping early if no more links fit, since the average is only a target
	static link_adjacent_rooms = function() {
		while (2 * array_length(cardinal_exits) / array_length(rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
			if (!add_adjacent_exit()) { return; }
		}
	};

	/// @function add_adjacent_exit()
	/// @description Links a random room to an adjacent room it isn't linked to yet
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
				
				// Continue if no adjacent room exists in this direction, or it can't gain exits
				var _adjacent_room = get_adjacent_room(_potential_room, _dirs[_dir]);
				if (is_undefined(_adjacent_room) || !_adjacent_room.can_gain_exits()) { continue; }

				link_rooms_with_new_exit(_potential_room, _adjacent_room, _dirs[_dir]);
				return true;
			}
		}
		
		// Return false if no new exit can be added
		return false;
	};

	/// @function find_or_create_special_rooms()
	/// @description Reserves a room for each included special room type: one whose cardinal exits already fit one of
	///	the type's layouts, or else one found or built to fit (see add_room_for_special_room_type)
	/// @returns {bool} False if a special room type got no room
	static find_or_create_special_rooms = function() {
		// Loop through each included special room type
		for (var _i = 0; _i < array_length(included_special_room_types); _i++) {
			var _special_room_type = included_special_room_types[_i];
			var _room = find_room_for_special_room_type(_special_room_type);
			
			// If no room fits the type yet, find or build one
			if (is_undefined(_room)) { _room = add_room_for_special_room_type(_special_room_type); }
			
			// If creating one failed, return false
			if (is_undefined(_room)) { return false; }
			
			// Otherwise, make the room a special room of that type
			_room.is_special_room = true;
			_room.special_room_type = _special_room_type;
		}
		
		return true;
	};
	
	/// @function find_or_create_starting_rooms()
	/// @description Adds a new room joined by a cardinal exit, which can be the start, if no room can be the start yet
	/// @returns {bool} False if no room could be added
	static find_or_create_starting_rooms = function() {
		// Check if any room can still be the start, and add a new room if not
		if (count_possible_starts() == 0 && is_undefined(add_new_room(false))) { return false; }

		return true;
	};

	/// @function find_room_for_special_room_type(_special_room_type)
	/// @description Picks a random room that fits a special room type: no stairs, not reserved yet, and cardinal exits
	///	that match one of the type's layouts
	/// @param {SpecialRoomType} _special_room_type The special room type
	/// @returns {GameRoom|undefined} The room, or undefined if none fits
	static find_room_for_special_room_type = function(_special_room_type) {
		var _possible_rooms = [];
		
		// Check each existing room
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			
			// If room can't become a special room, skip it
			if (!_room.can_become_special_room()) { continue; }
			
			// Add room to list of possibilities if one of the type's layouts matches the room's exit kind
			if (_special_room_type.has_layout_of_type(_room.get_exit_type())) { array_push(_possible_rooms, _room); }
		}
		
		// Return a random matching room, or undefined
		return (array_length(_possible_rooms) > 0) ? array_random_get(_possible_rooms) : undefined;
	};

	/// @function add_room_for_special_room_type(_special_room_type)
	/// @description Makes a room for a special room type that no room fits yet: tries each exit kind the type's layouts
	///	have, in random order, until a room with those cardinal exits is found or built (see
	///	find_or_create_room_for_exit_count)
	/// @param {SpecialRoomType} _special_room_type The special room type
	/// @returns {GameRoom|undefined} The room, or undefined if none could be made
	static add_room_for_special_room_type = function(_special_room_type) {
		var _exit_types = array_shuffle(_special_room_type.get_exit_types());
		for (var _i = 0; _i < array_length(_exit_types); _i++) {
			// Find or build a room with the cardinal exits this kind of layout opens
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
	/// @description Finds the room needing the fewest new cardinal exits to have exactly the target number, and adds
	///	them: links to adjacent rooms that can gain exits first, then to new rooms on free cells. A room with one exit
	///	is always a new dead end, since exits are never removed.
	/// @param {real} _target_exit_count How many cardinal exits the room needs, 1 to 4
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

			// Skip rooms that cannot become special rooms
			// NOTE: this only works because this function is currently only used for assigning special rooms
			if (!_possible_room.can_become_special_room()) { continue; }

			// Skip rooms that can't reach the target, and keep the one needing the fewest new exits
			var _sides = get_openable_cardinal_exits(_possible_room, _target_exit_count, _needs_opposite_exits);
			if (is_undefined(_sides)) { continue; }
			if (is_undefined(_best_sides) || _sides.exits_needed < _best_sides.exits_needed) {
				_best_room = _possible_room;
				_best_sides = _sides;
			}
		}

		// Return undefined if no room could be identified
		if (is_undefined(_best_room)) { return undefined; }

		// Otherwise, open the sides with an adjacent room first, then the sides on free cells
		var _dirs = array_shuffle(_best_sides.linkable_sides);
		array_copy(_dirs, array_length(_dirs), array_shuffle(_best_sides.free_sides), 0, array_length(_best_sides.free_sides));
		for (var _dir = 0; _dir < _best_sides.exits_needed; _dir++) {
			// Create a new room if none exists
			var _adjacent_room = get_adjacent_room(_best_room, _dirs[_dir]);
			if (is_undefined(_adjacent_room)) { _adjacent_room = create_room_at_cell(_best_room.virtual_x + get_dir_x_offset(_dirs[_dir]), _best_room.virtual_y + get_dir_y_offset(_dirs[_dir])); }

			// Create a new exit between the rooms
			link_rooms_with_new_exit(_best_room, _adjacent_room, _dirs[_dir]);
		}

		return _best_room;
	};

	/// @function get_openable_cardinal_exits(_room, _target_exit_count, [_needs_opposite_exits])
	/// @description Sorts the sides a room could open to end up with exactly the target number of cardinal exits:
	///	sides whose adjacent room can gain exits, and sides on a free cell, where a new room would go
	/// @param {GameRoom} _room The room
	/// @param {real} _target_exit_count How many cardinal exits the room needs, 2 to 4
	/// @param {bool} [_needs_opposite_exits] For two exits: true for opposite sides, false for a corner, undefined for either
	/// @returns {struct|undefined} { exits_needed, linkable_sides, free_sides }, or undefined if the room can't reach the target
	static get_openable_cardinal_exits = function(_room, _target_exit_count, _needs_opposite_exits = undefined) {
		// Exits are never removed, so the room can't already have more than the target
		var _exits_needed = _target_exit_count - _room.get_cardinal_exits_count();
		if (_exits_needed < 0) { return undefined; }

		// Two exits must be on opposite sides, or on a corner, when the layout needs it. A room with no cardinal exits
		// has stairs, so it never needs both
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

			// A free cell gets a new room, and an adjacent room only links if it can gain exits
			var _adjacent_room = get_adjacent_room(_room, _dir);
			if (is_undefined(_adjacent_room)) { array_push(_free_sides, _dir); }
			else if (_adjacent_room.can_gain_exits()) { array_push(_linkable_sides, _dir); }
		}

		// Enough sides must open, and the new rooms needed must fit under the room limit
		if (array_length(_linkable_sides) + array_length(_free_sides) < _exits_needed) { return undefined; }
		if (array_length(rooms) + max(0, _exits_needed - array_length(_linkable_sides)) > MAX_NUMBER_OF_ROOMS) { return undefined; }

		return { exits_needed: _exits_needed, linkable_sides: _linkable_sides, free_sides: _free_sides };
	};

	/// @function assign_room_layouts()
	/// @description Assigns a layout, and rolls its content, to every room whose cardinal exits have changed since its
	///	last layout. If no other regular room has lanterns, the last regular room to get a layout gets one with
	///	lanterns, which keeps a lantern room on every map. Special rooms go last, since their layouts never compete with
	///	the regular ones.
	static assign_room_layouts = function() {
		// List the regular rooms and the special rooms that need a new layout, in random order
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
			assign_room_content(_possible_room, _needs_lanterns);
		}
		
		// For each special room that needs a layout, assign one
		for (var _i = 0; _i < array_length(_special_rooms_that_need_layouts); _i++) {
			var _possible_room = _special_rooms_that_need_layouts[_i];

			assign_room_content(_possible_room);
		}
	};

	/// @function assign_room_content(_room, [_needs_lanterns])
	/// @description Gives a room a new layout, then rolls the layout's orientation and random content
	/// @param {GameRoom} _room The room
	/// @param {bool} [_needs_lanterns] Whether the layout must have lanterns (false by default; special rooms ignore it)
	static assign_room_content = function(_room, _needs_lanterns = false) {
		// Pick a room layout for this room
		var _layout = assign_layout_to_room(_room, _needs_lanterns);
		_room.assign_layout(_layout);
			
		// Decide how the room gets randomly flipped and rotated
		_room.determine_layout_orientation();
			
		// Decide how to fill in the random room content for the chosen static layout
		_room.determine_random_room_content(same_skeleton_type);
	};

	/// @function assign_layout_to_room(_room, [_needs_lanterns])
	/// @description Picks a new layout for a room among the least used ones that fit it, and frees its old one. A
	///	special room picks among its type's layouts with its exit kind, and a regular room among the layouts with the
	///	exit kind it shows, which differs from its real one when its exits are misleading.
	/// @param {GameRoom} _room The room
	/// @param {bool} [_needs_lanterns] Whether the layout must have lanterns (false by default; special rooms ignore it)
	/// @returns {RoomLayout} The new layout
	static assign_layout_to_room = function(_room, _needs_lanterns = false) {
		// Free the old layout, so it no longer counts as in use
		if (!is_undefined(_room.layout)) { layout_use_counts[_room.layout.index] -= 1; }

		// Assign a new minimally used layout for the room
		var _real_exit_type = _room.get_exit_type(), _possible_layouts, _layout;
		if (_room.is_special_room) {
			// Special rooms can't have misleading exits, can't be the guaranteed lantern room, and must use one of their type's layouts
			_possible_layouts = _room.special_room_type.get_layouts_of_type(_real_exit_type);
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
		
		return _layout;
	};

	/// @function choose_minimally_used_layout(_possible_layouts, [_must_have_lanterns])
	/// @description Picks a random layout among the ones that fit and have been used the least
	/// @param {array} _possible_layouts The layouts that fit
	/// @param {bool} [_must_have_lanterns] Whether only layouts with lanterns can be picked (false by default)
	/// @returns {RoomLayout} The layout
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
	/// @description Whether any regular (not special) room already has a layout with lanterns
	/// @param {GameRoom} [_ignored_room] A room not to count, like one about to get a new layout
	/// @returns {bool}
	static has_any_lantern_rooms = function(_ignored_room = undefined) {
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _possible_room = rooms[_i];
			if (_possible_room != _ignored_room && !_possible_room.is_special_room && _possible_room.has_lanterns) { return true; }
		}
		return false;
	};

	/// @function reset_decorations()
	/// @description Clears every decoration the last pass placed: the start and heart, collectables, the guaranteed lit
	///	room, chests and their contents, special items, keys and locks, and special exit types. Each pass then decorates
	///	the current rooms starting from their rolled content, which decorations never change.
	static reset_decorations = function() {
		start_room = undefined;
		heart_room = undefined;
		guaranteed_chest_room = undefined;
		special_item_types = [];
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].reset_decorations(); }
		for (var _j = 0; _j < array_length(cardinal_exits); _j++) { cardinal_exits[_j].reset_decorations(); }
	};

	/// @function determine_start_and_heart_rooms()
	/// @description Makes the start and heart rooms the two ends of the longest route through the map, stairs included,
	///	among the rooms each is allowed to be. Then places the cross and the encased heart, and measures every room's
	///	distance from the start. Being the start keeps the room's rolled hazards from spawning.
	/// @returns {bool} False if no pair is allowed
	static determine_start_and_heart_rooms = function() {
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
		start_room.is_start_room = true;
		start_room.set_stairs_spot_object(obj_cross);
		heart_room = _pair[1];
		heart_room.is_heart_room = true;
		heart_room.set_stairs_spot_object(obj_encased_heart);
		
		// Assign distance from new start to all rooms
		var _distances_from_start = measure_distances(start_room);
		for (var _k = 0; _k < array_length(rooms); _k++) {
			var _room = rooms[_k];
			_room.distance_to_start = _distances_from_start[_room.mapgen_index];
		}
		
		// Return success
		return true;
	};

	/// @function determine_collectables_rooms()
	/// @description Gives collectables to the heart room and to random other rooms, never the start, then to more random
	///	rooms until at least a quarter of the rooms, plus one, have them
	static determine_collectables_rooms = function() {
		var _possible_rooms = array_shuffle(rooms), _collectables_rooms = 1;
		heart_room.has_collectables = true;
		
		// Add collectables to heart room and other rooms at random
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			var _possible_room = _possible_rooms[_i];
			if (!_possible_room.is_start_room && !_possible_room.is_heart_room && (_possible_room.is_heart_room || get_random_chance_out_of(COLLECTABLE_PROBABILITY))) {
				_possible_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}

		// Add to more random rooms to meet the minimum if needed
		var _minimum_collectable_rooms = ceil(array_length(rooms) / 4) + 1;
		for (var _j = 0; _j < array_length(_possible_rooms) && _collectables_rooms < _minimum_collectable_rooms; _j++) {
			var _extra_room = _possible_rooms[_j];
			if (!_extra_room.is_start_room && !_extra_room.has_collectables) {
				_extra_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}
	};

	/// @function find_or_set_one_lit_room()
	/// @description Ensures at least one lantern room starts lit; if none rolled lit, makes a random regular lantern room
	///	the guaranteed lit room. Being lit keeps that room's phantom from spawning (see GameRoom.spawns_phantom).
	static find_or_set_one_lit_room = function() {
		// Check every room for a lantern room that is already lit, and list the ones that could be lit
		var _lantern_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms without lanterns and special rooms
			var _room = rooms[_i];
			if (!_room.has_lanterns || _room.is_special_room) { continue; }
			
			// Return if a lantern room is already lit
			if (_room.is_lit()) { return; }
			
			// Otherwise, add to array of lightable lantern rooms
			array_push(_lantern_rooms, _room);
		}
		
		// Return if no lantern room exists
		if (array_length(_lantern_rooms) == 0) {
			// This should NEVER happen
			write_debug_message("Map has no lantern room to light.", debug_message_level.warning);
			return;
		}
		
		// Otherwise, light one of them at random
		var _lit_room = array_random_get(_lantern_rooms);
		_lit_room.is_guaranteed_lit_room = true;
	};

	/// @function create_chests()
	/// @description Places the chests: a hidden chest with a special item in each special room, the guaranteed chest,
	///	which holds a map or compass, in a random regular room, and a regular chest in other rooms by chance. The other
	///	chests get their items later (see assign_chest_contents).
	static create_chests = function() {
		// Loop through all rooms in a random order and add chests to them
		var _possible_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			var _possible_room = _possible_rooms[_i];
			// Skip rooms that can't have a chest spawn in them
			if (!_possible_room.can_have_chest()) { continue; }
			
			if (_possible_room.is_special_room) {
				// Special rooms always have a special item in a hidden chest
				_possible_room.add_chest(true);
				_possible_room.has_special_item = true;
			}
			else if (is_undefined(guaranteed_chest_room)) {
				// Spawn the guaranteed chest, which holds a map on Easy, and a map or compass from Medium up. It may be hidden
				// or locked, but never holds a special item, so it's never in a special room
				_possible_room.add_chest();
				_possible_room.chest_obj = (global.difficulty == difficulties.easy || get_coin_flip()) ? obj_map : obj_compass;
				guaranteed_chest_room = _possible_room;
			}
			else if (get_random_chance_out_of(CHEST_PROBABILITY)) {
				// For all other rooms, place a regular chest
				_possible_room.add_chest();
			}
		}
	};
	
	/// @function assign_chest_contents()
	/// @description Locks every visible chest with a special item and some other visible chests, turns some basic chests
	///	into traps, and picks an item for each chest still empty
	static assign_chest_contents = function() {
		var _possible_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			var _chest_room = _possible_rooms[_i];
			if (!_chest_room.has_chest()) { continue; }

			// Lock special item chests and some other chests
			if (_chest_room.stairs_spot_obj == obj_chest) {
				_chest_room.has_locked_chest = _chest_room.has_special_item || get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
			}

			// Add traps in some chests, unless the trap would take the room past its max difficulty
			if (_chest_room != guaranteed_chest_room && _chest_room.has_basic_chest() && get_random_chance_out_of(TRAP_CHEST_PROBABILITY) && !_chest_room.would_exceed_max_difficulty("obj_chest")) {
				// A fountain shoots at the player, so a room with eyes only gets the statue trap
				_chest_room.chest_obj = (!_chest_room.has_eyes && get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) ? obj_fountain : obj_statue;
			}
			
			// Add items to remaining chests
			if (_chest_room.chest_obj == -1) {
				_chest_room.chest_obj = pick_item_type(_chest_room.has_special_item);
			}
		}
	};

	/// @function assign_or_create_special_item_chests()
	/// @description Puts the special items rolled for outside special rooms into random chests already placed, other
	///	than the guaranteed one, then adds new chests for any left over
	static assign_or_create_special_item_chests = function() {
		var _possible_rooms = array_shuffle(rooms), _special_items_to_assign = special_item_count;

		// Assign to already placed chests
		for (var _i = 0; _i < array_length(_possible_rooms) && _special_items_to_assign > 0; _i++) {
			// Skip rooms with no chest, the guaranteed chest, and rooms that can't have a special item
			var _chest_room = _possible_rooms[_i];
			if (!_chest_room.has_chest() || _chest_room == guaranteed_chest_room || !_chest_room.can_have_special_item()) { continue; }

			// Make the room's chest hold a special item
			_chest_room.has_special_item = true;
			_special_items_to_assign -= 1;
		}

		// Create new chests as needed
		for (var _j = 0; _j < array_length(_possible_rooms) && _special_items_to_assign > 0; _j++) {
			var _empty_room = _possible_rooms[_j];
			if (!_empty_room.can_have_chest() || !_empty_room.can_have_special_item()) { continue; }

			// Create a new chest to hold the special item in this room
			_empty_room.add_chest();
			_empty_room.has_special_item = true;
			_special_items_to_assign -= 1;
		}

		if (_special_items_to_assign > 0) {
			// This should NEVER happen
			write_debug_message("No room left for " + string(_special_items_to_assign) + " special item(s).", debug_message_level.warning);
		}
	};

	/// @function pick_item_type(_is_special_item, [_items_in_hands])
	/// @description Picks an item type at random among the types still allowed. A special item can be any type the
	///	difficulty allows, keys included, but each type is a special item once at most. A regular item is never a key,
	///	or a type at its cap (see get_item_cap), counting the chests and the given starting hand items.
	/// @param {bool} _is_special_item Whether the item is a special item
	/// @param {array} [_items_in_hands] The starting hand items to count ([] by default, to ignore the hands)
	/// @returns {Asset.GMObject}
	static pick_item_type = function(_is_special_item, _items_in_hands = []) {
		// Get the count of extra torches being brought in
		var _torches_in_hand = 0;
		for (var _i = 0; _i < array_length(_items_in_hands); _i++) {
			if (_items_in_hands[_i] == obj_torch) { _torches_in_hand += 1; }
		}
		
		// Loop through all possible item types to see which are still possible to spawn
		var _available_item_types = global.available_items[global.difficulty], _possible_item_types = [];
		for (var _i = 0; _i < array_length(_available_item_types); _i++) {
			var _item_type = _available_item_types[_i];
			if (_is_special_item) {
				// Add any type that isn't a special item yet to the list of possibilities
				if (!array_contains(special_item_types, _item_type)) { array_push(_possible_item_types, _item_type); }
			}
			else if (_item_type != obj_key && count_regular_items(_item_type, _items_in_hands) < get_item_cap(_item_type, _torches_in_hand)) {
				// Add any type other than the key that isn't at its cap yet to the list of possibilities
				array_push(_possible_item_types, _item_type);
			}
		}
		
		// Default to returning a torch if no other possibilities are found
		if (array_length(_possible_item_types) == 0) {
			// This should NEVER happen
			write_debug_message("No item type left to pick, so a torch spawns instead.", debug_message_level.warning);
			return obj_torch;
		}

		// Select a random type from among the possible ones, and remember it if it's a special item
		var _item = array_random_get(_possible_item_types);
		if (_is_special_item) { array_push(special_item_types, _item); }
		return _item;
	};

	/// @function count_regular_items(_item_type, _hands)
	/// @description Counts the regular (not special) copies of an item type in the map's chests and in the given starting
	///	hand items. The keys and bombs placed for the locks don't count, and neither does a torch in the guaranteed chest,
	///	which it only holds in place of a map or compass the hands already hold.
	/// @param {Asset.GMObject} _item_type The item type
	/// @param {array} _hands The starting hand items to count
	/// @returns {real}
	static count_regular_items = function(_item_type, _hands) {
		// Loop through all rooms and count the regular items of this type
		var _count = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip the guaranteed chest room if it contains a fallback torch
			var _room = rooms[_i];
			if (_room == guaranteed_chest_room && _room.chest_obj == obj_torch) { continue; }
			
			// Count it if the chest holds the type, and it's neither a special item nor a key or bomb placed for the locks
			if (_room.chest_obj == _item_type && !_room.has_special_item && !_room.key_in_chest) { _count += 1; }
		}
		
		// Loop through the given hand items and add those item types to the count
		for (var _j = 0; _j < array_length(_hands); _j++) {
			if (_hands[_j] == _item_type) { _count += 1; }
		}
		
		// Return the count
		return _count;
	};

	/// @function get_item_cap(_item, [_torches_in_hands])
	/// @description How many regular copies of an item the chests and starting hands may hold together
	/// @param {Asset.GMObject} _item The item
	/// @param {real} [_torches_in_hands] How many torches the player starts with, each of which raises the torch cap by one
	/// @returns {real}
	static get_item_cap = function(_item, _torches_in_hands = 0) {
		switch (_item) {
			case obj_map:
			case obj_compass:
			case obj_staff:
			case obj_clock:
				return 1;
			case obj_shovel:
				return 2;
			case obj_torch:
				return 2 + _torches_in_hands;
			default:
				return infinity;
		}
	};

	/// @function create_locked_exits_and_keys()
	/// @description Locks every cardinal exit of the heart room, then rolls a lock for each other cardinal exit that can
	///	be locked, and backs each lock with keys before the next one is added (see create_keys_for_locks)
	/// @returns {bool} False if the heart locks could not be backed (a last resort, never expected)
	static create_locked_exits_and_keys = function() {
		// First, lock every exit of the heart room and add its keys
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _heart_exit = heart_room.exits[_dir];
			if (_heart_exit != -1) { _heart_exit.set_lock(true); }
		}
		if (!create_keys_for_locks()) { return false; }

		// Lock other exits at random, and add keys for each
		var _exits = array_shuffle(cardinal_exits);
		for (var _i = 0; _i < array_length(_exits); _i++) {
			var _exit = _exits[_i];
			if (!_exit.can_be_locked() || !get_random_chance_out_of(LOCKED_DOOR_PROBABILITY / 2)) { continue; }

			_exit.set_lock(true);
			if (!create_keys_for_locks(_exit)) { return false; }
		}
		
		// Return success
		return true;
	};

	/// @function create_keys_for_locks([_newest_lock])
	/// @description Checks every order the player could spend keys on locks in, and adds a key to the area where an
	///	order gets them stuck, until no order does (see get_failing_lock_and_key_search_area). If no room there can take
	///	a key, the newest lock moves to an exit it hasn't tried yet, and is only dropped as a last resort.
	/// @param {RoomExit|undefined} [_newest_lock] The random lock just added, or undefined for the heart locks
	/// @returns {bool} False if a lock no key can back cannot move either
	static create_keys_for_locks = function(_newest_lock = undefined) {
		var _tried_exits = [_newest_lock];
		while (true) {
			// If no order gets the player stuck, return success
			var _stuck_area = get_failing_lock_and_key_search_area();
			if (is_undefined(_stuck_area)) { return true; }
			
			// Otherwise, add a key to the area where they get stuck, and check again
			if (add_key_to_area(_stuck_area)) { continue; }

			// Otherwise, fail if the lock can't move, as for the heart room's locks
			if (is_undefined(_newest_lock)) {
				// This should NEVER happen
				write_debug_message("No room could take a key for a lock that cannot move.", debug_message_level.warning);
				return false;
			}
			
			// Otherwise, unlock this exit and pick a different exit to try locking
			_newest_lock.set_lock(false);
			_newest_lock = get_untried_lockable_exit(_tried_exits);
			
			// Continue with map generation without locking an exit, if no lockable exit could be found
			if (is_undefined(_newest_lock)) {
				// This should NEVER happen
				write_debug_message("Dropped a lock that no key could unlock.", debug_message_level.warning);
				break;
			}
			
			// Otherwise, lock the new exit and try again.
			_newest_lock.set_lock(true);
			array_push(_tried_exits, _newest_lock);
		}
		
		return true;
	};

	/// @function add_key_to_area(_stuck_area)
	/// @description Adds a key to a random room of the stuck search area that can hold one: on one of its key spots, or
	///	sometimes in a new chest, where a bomb can stand in for the key if the area lets the player light bombs
	/// @param {LockSearchArea} _stuck_area The search area where the player got stuck
	/// @returns {bool} False if no room there can take one
	static add_key_to_area = function(_stuck_area) {
		// Construct a list of all possible rooms we could add a key to. If none are left, return false
		var _possible_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _possible_room = rooms[_i];
			if (!_possible_room.is_in_bitmask(_stuck_area.reached_rooms)) { continue; }

			if (!_possible_room.is_heart_room && !_possible_room.has_key && array_length(_possible_room.layout.key_spots) > 0) { array_push(_possible_rooms, _possible_room); }
		}
		if (array_length(_possible_rooms) == 0) { return false; }

		// Select a random room out of the possible rooms to add the key to
		var _room = array_random_get(_possible_rooms);
		if (_room.can_have_chest() && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) {
			// The chest is never locked or hidden, and never holds a special item
			_room.key_in_chest = true;
			_room.set_stairs_spot_object(obj_chest);
			_room.chest_obj = (_stuck_area.can_use_bombs_as_keys() && get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY)) ? obj_bomb : obj_key;
			// TODO: The first time on a map we use a bomb instead of a key, we should also add another extra key to the map. This extra key should NOT count towards the lock checking algorithm as it will count the bomb instead; this is purely additive
		}
		else { _room.key_spot = array_random_get(_room.layout.key_spots); }
		
		// Return true for successful key placement
		_room.has_key = true;
		return true;
	};

	/// @function get_untried_lockable_exit(_tried_exits)
	/// @description Picks a random cardinal exit a lock can move to, among those not tried yet
	/// @param {array} _tried_exits Exits this lock already tried
	/// @returns {RoomExit|undefined} The exit, or undefined if none is left
	static get_untried_lockable_exit = function(_tried_exits) {
		var _possible_exits = [];
		for (var _i = 0; _i < array_length(cardinal_exits); _i++) {
			var _exit = cardinal_exits[_i];
			if (_exit.can_be_locked() && !array_contains(_tried_exits, _exit)) { array_push(_possible_exits, _exit); }
		}
		return (array_length(_possible_exits) > 0) ? array_random_get(_possible_exits) : undefined;
	};

	/// @function get_failing_lock_and_key_search_area()
	/// @description Checks every order the player could spend keys in, on locked doors and chests, for one that leaves
	///	them stuck with rooms unreached.
	///	The search moves through areas: the rooms the player can reach, plus which locked chests that matter
	///	they have opened. In the worst order, they spend a key on every lock in the area that leads nowhere new
	///	(each locked door inside it, the ones they opened to get there among them, and each locked chest that
	///	doesn't matter), as well as on each chest that matters they opened. If that leaves them no key while
	///	rooms remain unreached, they are stuck. Otherwise they still hold a key in every order, so they can open
	///	a locked door at the area's edge or a chest that matters, and each choice leads to a new area to check.
	///	Areas are checked in the order found, so the first stuck area is one near the start.
	/// @returns {LockSearchArea|undefined} The first area where the player gets stuck, or undefined if they never do
	static get_failing_lock_and_key_search_area = function() {
		// Check if any key chest holds a bomb instead. If so, bombs stand in for keys
		var _bombs_stand_in = false;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			if (rooms[_i].has_key && rooms[_i].key_in_chest && rooms[_i].chest_obj == obj_bomb) { _bombs_stand_in = true; }
		}
		
		// Gather each locked exit in the map
		var _locked_exits = [], _chests_that_matter = [];
		for (var _j = 0; _j < array_length(cardinal_exits); _j++) {
			if (cardinal_exits[_j].has_lock) { array_push(_locked_exits, cardinal_exits[_j]); }
		}
		
		// Gather the locked chests that matter: those holding the special key, which opens every lock, and those holding a
		// torch when bombs stand in for keys
		for (var _k = 0; _k < array_length(rooms); _k++) {
			var _room = rooms[_k];
			var _holds_special_key = (_room.chest_obj == obj_key && _room.has_special_item);
			var _holds_needed_torch = (_room.chest_obj == obj_torch && _bombs_stand_in);
			_room.unlocked_chests_bitmask_index = -1;
			// Add the chest to those that matter
			if (_room.has_locked_chest && (_holds_special_key || _holds_needed_torch)) {
				_room.unlocked_chests_bitmask_index = array_length(_chests_that_matter);
				array_push(_chests_that_matter, _room);
			}
		}

		// Set up the initial queue of areas to check, map of area check queue keys, and initial area
		var _all_rooms_reached_bitmask = (1 << array_length(rooms)) - 1, _reached_rooms_bitmask = start_room.get_reachable_rooms_bitmask(), _unlocked_chests_bitmask = 0;
		var _initial_search_area = new LockSearchArea(_reached_rooms_bitmask, _unlocked_chests_bitmask, rooms), _search_area_check_queue = [_initial_search_area];
		var _search_areas_in_queue_map = {};
		_search_areas_in_queue_map[$ get_search_area_key(_reached_rooms_bitmask, _unlocked_chests_bitmask)] = true;
		
		// Iterate through the searched area queue, checking that each one is possible
		while (array_length(_search_area_check_queue) > 0) {
			// Get the next area to search, along with what the player finds in it
			var _search_area = array_shift(_search_area_check_queue);
			
			// Skip checking area if it reached all rooms or the special key
			if (_search_area.reached_rooms == _all_rooms_reached_bitmask || _search_area.reached_special_key) { continue; }
			
			// Otherwise, count the locks inside the area: its locked chests that don't matter, and each locked door with both
			// sides reached
			var _locks_inside_area = _search_area.other_locked_chests_reached;
			for (var _i = 0; _i < array_length(_locked_exits); _i++) {
				if (_search_area.is_exit_unlocked(_locked_exits[_i])) { _locks_inside_area += 1; }
			}
			
			// The player is stuck here if the worst order leaves them no key
			var _keys_remaining = _search_area.count_usable_keys() - _locks_inside_area;
			if (_keys_remaining <= 0) { return _search_area; }

			// Otherwise, spend a key to open a locked door at the edge of the area, reaching the rooms behind it...
			for (var _i = 0; _i < array_length(_locked_exits); _i++) {
				// Skip unlocking the exit if both sides or neither side of it have been reached yet
				var _locked_exit = _locked_exits[_i];
				var _room_1_reached = _locked_exit.room_1.is_in_bitmask(_search_area.reached_rooms);
				var _room_2_reached = _locked_exit.room_2.is_in_bitmask(_search_area.reached_rooms);
				if (_room_1_reached == _room_2_reached) { continue; }
				
				// Add a new area to the queue of areas to check, which is the same area plus the new unlock of this exit
				var _new_room = (_room_1_reached) ? _locked_exit.room_2 :  _locked_exit.room_1;
				
				var _new_reached_rooms = _search_area.reached_rooms | _new_room.get_reachable_rooms_bitmask();
				add_search_area_to_queue_if_unique(_search_area_check_queue, _search_areas_in_queue_map, _new_reached_rooms, _search_area.unlocked_chests);
			}
			
			// ...or a locked chest that matters, in the area
			for (var _chest = 0; _chest < array_length(_chests_that_matter); _chest++) {
				// Skip unlocking chests that are already unlocked in this area
				var _new_unlocked_chests = _search_area.unlocked_chests | (1 << _chest);
				if (_new_unlocked_chests == _search_area.unlocked_chests) { continue; }
				
				// Skip unlocking chests in rooms that haven't been reached yet
				if (!_chests_that_matter[_chest].is_in_bitmask(_search_area.reached_rooms)) { continue; }
				
				// Otherwise, add a new area to the queue of areas to check, which is this same area with the new chest unlocked
				add_search_area_to_queue_if_unique(_search_area_check_queue, _search_areas_in_queue_map, _search_area.reached_rooms, _new_unlocked_chests);
			}
		}
		
		return undefined;
	};

	/// @function add_search_area_to_queue_if_unique(_search_area_check_queue, _search_areas_in_queue_map, _new_reached_rooms, _new_unlocked_chests)
	/// @description Adds an area to the lock search's queue, unless the same area was already queued
	/// @param {array} _search_area_check_queue The queue of areas to check, in order
	/// @param {struct} _search_areas_in_queue_map Every area queued so far, by get_search_area_key
	/// @param {real} _new_reached_rooms Bitmask of the rooms the new area reaches
	/// @param {real} _new_unlocked_chests Bitmask of the chests that matter the new area has unlocked
	static add_search_area_to_queue_if_unique = function(_search_area_check_queue, _search_areas_in_queue_map, _new_reached_rooms, _new_unlocked_chests) {
		// Skip adding to the queue if this area was already queued
		var _area_key = get_search_area_key(_new_reached_rooms, _new_unlocked_chests);
		if (!is_undefined(_search_areas_in_queue_map[$ _area_key])) { return; }
		
		// Mark the area as queued, and add it to the queue
		var _search_area = new LockSearchArea(_new_reached_rooms, _new_unlocked_chests, rooms);
		_search_areas_in_queue_map[$ _area_key] = true;
		array_push(_search_area_check_queue, _search_area);
	};

	/// @function determine_special_exit_types()
	/// @description Turns random rooms into portcullis traps, and adds illusion walls and plain doors to random cardinal
	///	exits of the other rooms
	static determine_special_exit_types = function() {
		// Loop through all the existing rooms, in random order
		var _possible_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			// Skip any ineligible rooms
			var _possible_room = _possible_rooms[_i];
			if (!_possible_room.can_have_special_exit_types()) { continue; }
			
			// Chance to add portcullis trap
			if (_possible_room.can_have_portcullis_trap() && get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { _possible_room.add_portcullis_trap();  continue; }

			// Otherwise, loop through cardinal exits to decorate them individually
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				// Skip exits that don't exist, or already have a door, illusion walls, or a closed portcullis on either side
				var _exit = _possible_room.exits[_dir];
				if (_exit == -1 || _exit.has_door || _exit.room_1_has_closed_portcullis || _exit.room_2_has_closed_portcullis || _exit.has_illusion_walls) { continue; }

				// Sometimes give the exit illusion walls, unless it leads to the start room
				if (!_exit.get_connected_room(_possible_room).is_start_room && get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) { _exit.has_illusion_walls = 1; continue; }
				
				// Otherwise, sometimes give the exit plain doors
				if (get_random_chance_out_of(OPEN_DOOR_PROBABILITY * 2)) { _exit.has_door = true; continue; }
			}
		}
	};

	/// @function adjust_items_for_hands()
	/// @description Swaps chest contents for the items the player starts with in their hands, once the map is final: the
	///	guaranteed chest's map or compass, and any regular item the hands take past its cap
	static adjust_items_for_hands = function() {
		// Setup variables based on the items the player chose to start with
		var _hand_items = [global.player_left_hand_item, global.player_right_hand_item];
		var _map_in_hand = array_contains(_hand_items, obj_map), _compass_in_hand = array_contains(_hand_items, obj_compass);
		
		// Get the count of extra torches being brought in
		var _torches_in_hand = 0;
		for (var _i = 0; _i < array_length(_hand_items); _i++) {
			if (_hand_items[_i] == obj_torch) { _torches_in_hand += 1; }
		}

		// Swap out items in the guaranteed chest room
		if (!is_undefined(guaranteed_chest_room)) {
			if (_map_in_hand && _compass_in_hand) { guaranteed_chest_room.chest_obj = obj_torch; }
			else if (_compass_in_hand) { guaranteed_chest_room.chest_obj = obj_map; }
			else if (_map_in_hand) { guaranteed_chest_room.chest_obj = (global.difficulty == difficulties.easy) ? obj_torch : obj_compass; }
		}

		// Swap out items in other rooms
		var _existing_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			// Skip rooms without a regular item and skip the guaranteed room
			var _room = _existing_rooms[_i];
			if (_room == guaranteed_chest_room || !_room.has_regular_item_chest()) { continue; }
			
			// Replace the item if it is over the item cap
			if (count_regular_items(_room.chest_obj, _hand_items) > get_item_cap(_room.chest_obj, _torches_in_hand)) {
				// Empty the chest before picking, so the pick doesn't count the item it's replacing
				var _item = _room.chest_obj;
				_room.chest_obj = -1;
				_room.chest_obj = pick_item_type(false, _hand_items);

				// The item stays, over its cap, if the map needs it to stay winnable
				if (!is_undefined(get_failing_lock_and_key_search_area())) {
					// This should NEVER happen
					write_debug_message("Item type was over cap but allowed to stay: " + object_get_name(_item), debug_message_level.warning);
					_room.chest_obj = _item;
				}
			}
		}
	};

	// =================================================================================================
	// CALCULATIONS TO PASS OFF TO CONTROLLER
	// Each room's score and time are GameRoom methods (get_current_difficulty_score, get_time_provided),
	// which the calculations below add up
	// =================================================================================================


	/// @function calculate_item_chances()
	/// @description Determines how likely a player is to have an item (or encounter a lit room) for the difficulty scoring.
	///	The starting hand items are left out, so the map never depends on them.
	static calculate_item_chances = function() {
		// Count the rooms a torch can be lit in
		var _torch_lighting_room_count = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			if (rooms[_i].can_light_torch()) { _torch_lighting_room_count += 1; }
		}
		var _torch_chance = get_carry_chance(obj_torch);
		var _lit_torch_chance = _torch_chance * get_map_encounter_chance(_torch_lighting_room_count);

		// Loop through each room and set its holding chances
		var _staff_chance = get_carry_chance(obj_staff), _sword_chance = get_carry_chance(obj_sword, false), _special_sword_chance = get_carry_chance(obj_sword, true);
		for (var _j = 0; _j < array_length(rooms); _j++) {
			var _room = rooms[_j];
			
			// Set item holding chances
			_room.chance_holding_staff = _staff_chance;
			_room.chance_holding_sword = _sword_chance;
			_room.chance_holding_special_sword = _special_sword_chance;
			
			// Set its lit room chances
			if (_room.is_lit()) { _room.chance_of_light = 1; }
			else if (_room.can_light_torch()) { _room.chance_of_light = _torch_chance; }
			else { _room.chance_of_light = _lit_torch_chance; }
		}
	};

	/// @function get_carry_chance(_item, [_is_special])
	/// @description How likely the player is to be holding an item, from how many of the map's chests hold it
	/// @param {Asset.GMObject} _item The item
	/// @param {bool|undefined} [_is_special] True to count only special items, false only regular ones, undefined for both
	/// @returns {real}
	static get_carry_chance = function(_item, _is_special = undefined) {
		// Count the chests that hold the item, leaving out the keys and bombs placed for the locks
		var _chests_with_item = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms whose chest doesn't hold the item, or holds a key or bomb placed for the locks
			var _room = rooms[_i];
			if (!_room.has_chest() || _room.chest_obj != _item || _room.key_in_chest) { continue; }
			
			// Skip special items when counting only regular ones, and regular items when counting only special ones
			if (!is_undefined(_is_special) && _room.has_special_item != _is_special) { continue; }
			
			_chests_with_item += 1;
		}

		return get_map_encounter_chance(_chests_with_item);
	};

	/// @function get_map_encounter_chance(_room_count)
	/// @description How likely the player is to have come across something some of the map's rooms hold: the share of the map's
	///	rooms that hold it, times MAP_ENCOUNTER_CHANCE_MULTIPLIER, at most 1
	/// @param {real} _room_count How many rooms hold it
	/// @returns {real}
	static get_map_encounter_chance = function(_room_count) {
		return min(1, (_room_count / array_length(rooms)) * MAP_ENCOUNTER_CHANCE_MULTIPLIER);
	};

	/// @function calculate_map_difficulty_score()
	/// @description Scores every room and sets difficulty_score to their total
	static calculate_map_difficulty_score = function() {
		difficulty_score = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];

			_room.room_reference_difficulty_score = _room.get_current_difficulty_score();
			difficulty_score += _room.room_reference_difficulty_score;
		}
	};

	/// @function calculate_time_provided()
	/// @description Sets time_provided, the run's total time: every room's share, plus the difficulty's allowance for
	///	the trips between rooms the map adds (see get_backtracking_time)
	static calculate_time_provided = function() {
		time_provided = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) { time_provided += rooms[_i].get_time_provided(); }
		time_provided += TIME_ALLOWANCE * get_backtracking_time();
	};
 
	/// @function measure_travel_times(_from_room, _skip_exit, _crossing)
	/// @description Seconds from one room to every other by the quickest way, through cardinal exits and stairs
	///	with locks ignored, counting the crossing time of each room entered.
	/// @param {GameRoom} _from_room Where to start
	/// @param {RoomExit|undefined} _skip_exit An exit not to use, or undefined
	/// @param {array} _crossing Each room's crossing time, by mapgen_index
	/// @returns {array} Seconds to each room by mapgen_index, or -1 where it can't be reached
	static measure_travel_times = function(_from_room, _skip_exit, _crossing) {
		var _count = array_length(rooms), _times = array_create(_count, -1), _settled = array_create(_count, false);
		_times[_from_room.mapgen_index] = 0;
		repeat (_count) {
			var _room = undefined, _best = infinity;
			for (var _i = 0; _i < _count; _i++) {
				var _index = rooms[_i].mapgen_index;
				if (!_settled[_index] && _times[_index] >= 0 && _times[_index] < _best) { _best = _times[_index]; _room = rooms[_i]; }
			}
			if (is_undefined(_room)) { break; }
			_settled[_room.mapgen_index] = true;
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				var _exit = _room.exits[_dir];
				if (_exit == -1 || _exit == _skip_exit) { continue; }
				var _other = _exit.get_connected_room(_room);
				var _time = _best + _crossing[_other.mapgen_index];
				if (!_settled[_other.mapgen_index] && (_times[_other.mapgen_index] < 0 || _time < _times[_other.mapgen_index])) { _times[_other.mapgen_index] = _time; }
			}
		}
		return _times;
	};
 
	/// @function get_backtracking_time()
	/// @description Seconds of walking between rooms on top of each room's own visit: carrying the heart
	///	back to the start cross, going back for a key when a lock comes first, coming back to an illusion wall
	///	taken for a dead end, and the wrath quest's trip to the start cross and back. Trips take the quickest way
	///	through the rooms, stairs included, so shortcuts shorten them.
	/// @returns {real}
	static get_backtracking_time = function() {
		var _crossing = array_create(array_length(rooms), 0), _from_start = measure_distances(start_room), _extra = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) { _crossing[rooms[_i].mapgen_index] = rooms[_i].get_crossing_time(); }
 
		// The finish: the heart has to be carried back to the start cross, from the far end of the map
		var _heart_times = measure_travel_times(heart_room, undefined, _crossing);
		var _to_finish = _heart_times[start_room.mapgen_index];
		if (_to_finish > 0) { _extra += _to_finish; }
 
		for (var _j = 0; _j < array_length(cardinal_exits); _j++) {
			var _exit = cardinal_exits[_j];
			if (!_exit.has_lock && _exit.has_illusion_walls <= 0) { continue; }
 
			// The player reaches the side nearer the start first
			var _near = (_from_start[_exit.room_2.mapgen_index] < _from_start[_exit.room_1.mapgen_index]) ? _exit.room_2 : _exit.room_1;
			var _times = measure_travel_times(_near, _exit, _crossing);
 
			// A lock met before its key: the trip from it to the nearest key on its near side, and back
			if (_exit.has_lock) {
				var _nearest = infinity;
				for (var _k = 0; _k < array_length(rooms); _k++) {
					var _to_key = _times[rooms[_k].mapgen_index];
					if (rooms[_k].has_key && _to_key >= 0) { _nearest = min(_nearest, _to_key); }
				}
				if (_nearest != infinity) { _extra += LOCK_BACKTRACK_SHARE * 2 * _nearest; }
			}
 
			// An illusion wall taken for a dead end: the trip back to it once everything else on its side is done
			// (on average the mean trip from those rooms), and the search
			if (_exit.has_illusion_walls > 0) {
				var _sum = 0, _rooms_on_side = 0;
				for (var _m = 0; _m < array_length(rooms); _m++) {
					var _back = _times[rooms[_m].mapgen_index];
					if (_back > 0) { _sum += _back; _rooms_on_side += 1; }
				}
				if (_rooms_on_side > 0) { _extra += ILLUSION_WALL_MISS_CHANCE * _sum / _rooms_on_side; }
				_extra += ILLUSION_WALL_SEARCH_TIME;
			}
		}
 
		// The wrath special room: the trip to the start cross to lift its curse, and back for its chest
		for (var _n = 0; _n < array_length(rooms); _n++) {
			var _room = rooms[_n];
			if (_room.layout.get_object_count("obj_inverted_cross") == 0) { continue; }
			var _wrath_times = measure_travel_times(_room, undefined, _crossing);
			var _to_start = _wrath_times[start_room.mapgen_index];
			if (_to_start > 0) { _extra += 2 * _to_start; }
		}
		return _extra;
	};

	/// @function apply_room_roles()
	/// @description Has every room write what it spawns, given its role, into the content fields building reads. Only for the finished map.
	static apply_room_roles = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].apply_roles_to_content(); }
	};

	/// @function calculate_collectables_and_items_lists()
	/// @description Lists what the controller tracks during play: the rooms with collectables, and the
	///	regular and special items in chests.
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

/// @function generate_map()
/// @description Creates a valid map for global.difficulty
/// @returns {GameMap} The finished map
function generate_map() {
	// Generates maps up to 100 times before giving up and trying the next seed. It should always work on the first try, this is here as a failsafe
	var _map = undefined;
	while (is_undefined(_map)) {
		// Attempt map generation on this seed up to 100 times
		var _failed_attempts = 0;
		do {
			_failed_attempts += 1;
			_map = new GameMap();
			if (!_map.try_generate()) { _map = undefined; }
		}
		until (!is_undefined(_map) || _failed_attempts >= 100);

		// If map is still undefined give up and move on to next seed
		if (is_undefined(_map)) {
			write_debug_message("Map generation failed 100 times for seed: " + string(global.seed), debug_message_level.warning);
			global.seed += 1;
			random_set_seed(global.seed);
		}
	}

	// Once map generation has succeeded, deal with the starting hand items
	var _hands_seed = irandom(MAX_SEED), _build_seed = irandom(MAX_SEED);
	random_set_seed(_hands_seed);
	_map.adjust_items_for_hands();
	
	// Pass the necessary variables onto the controller
	random_set_seed(_build_seed);
	_map.apply_room_roles();
	_map.calculate_collectables_and_items_lists();

	return _map;
}