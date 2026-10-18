// ===== MAP SIZE =====
#macro MINIMUM_NUMBER_OF_ROOMS get_probability_for_difficulty([4, 8, 12, 15, 18])
#macro MAX_NUMBER_OF_ROOMS get_probability_for_difficulty([8, 12, 18, 22, 24]) //[12, 16, 24, 28, 32])
#macro MAP_DIFFICULTY_SCORE_TARGET get_probability_for_difficulty([0, 2, 10, 22, 36]) // Rooms are added until the map's difficulty score reaches this, up to MAX_NUMBER_OF_ROOMS. It's about what a map of MINIMUM_NUMBER_OF_ROOMS scores on average, so about half of maps stop at the minimum and a map of easier rooms grows toward the maximum
#macro AVERAGE_NUMBER_OF_ROOM_EXITS (20/9)

// ===== MAP CONTENT =====
#macro SPECIAL_MAP_SHAPE_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 0])
#macro SPECIAL_ROOM_LIMIT get_probability_for_difficulty([0, 0, 0, 1, 2])
//#macro SPECIAL_ROOM_PROBABILITY get_probability_for_difficulty([0, 0, 0, 64, 32])
#macro SPECIAL_ROOM_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 6])
#macro SPECIAL_ITEM_LIMIT get_probability_for_difficulty([0, 1, 1, 2, 3])
//#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 9, 8, 7, 6]) // This is only called after a room has a chest, so this is combined with that probability. It's also affected by the special item limit
#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 7, 3, 3, 2])
#macro NO_CARDINAL_EXIT_ROOM_PROBABILITY get_probability_for_difficulty([0, 12, 8, 6, 4]) // This happens only after the stairs probability succeeds, so its combined with 1/5
#macro COLLECTABLE_PROBABILITY get_probability_for_difficulty([4, 3, 3, 3, 2]) 
#macro LOCKED_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 12, 10, 6])
#macro TRAP_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 4])  // This happens only after the chest probability succeeds, so its combined with that probability.
#macro KEY_IN_CHEST_PROBABILITY 3
#macro BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 8, 2, 1])
#macro PORTCULLIS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 8, 6]) 
#macro OPEN_DOOR_PROBABILITY get_probability_for_difficulty([0, 32, 24, 12, 8])
#macro MAP_ENCOUNTER_CHANCE_MULTIPLIER 3	// How likely the player is to have something, per share of the map's rooms holding it: one sword chest in fifteen rooms gives a 0.2 chance of holding a sword

/// @function GameMap()
/// @description The plan for one map, and the methods that generate it: the layouts its difficulty allows, its rooms
///	and the exits between them, its map-wide events, what each pass places, and what the controller keeps once generation
///	ends. Rooms and exits are only added through its methods, so its lookups always match its rooms. The first map of
///	a session also reads every room asset into the layout cache that every map shares.
function GameMap() constructor {
	// =========
	// FUNCTIONS
	// =========

	/// @function try_generate()
	/// @description Makes one attempt at generating the map. It randomly determines the map-wide events and the layouts the
	///	map must include, and grows the map to one room short of MINIMUM_NUMBER_OF_ROOMS. Then each pass adds a room and
	///	links, places the start and heart, reserves a room for each required layout and gives every room a new layout, then
	///	places the chests, locks, special exit types and collectables, determines every room's content, and scores the whole
	///	map, until the score reaches MAP_DIFFICULTY_SCORE_TARGET or the map has MAX_NUMBER_OF_ROOMS rooms. A pass where a
	///	required layout has no room of its own ends early, and the next pass's new room grows toward it. A failed attempt
	///	destroys the map.
	/// @returns {bool} False if the attempt failed, so a new map has to be tried
	static try_generate = function() {
		// Randomly determine the map-wide events, including the special room types and special items, and the layouts the
		// map must include
		determine_random_map_events();
		determine_required_layouts();

		// Grow the map to one room short of the minimum, since each pass adds a room first
		create_room_at_cell(0, 0);
		while (array_length(rooms) < MINIMUM_NUMBER_OF_ROOMS - 1) {
			if (is_undefined(add_new_room())) { return fail_generation("no room could grow"); }
		}

		// Each pass adds a room, places everything again and scores the map, until it scores enough or has as many rooms as allowed
		var _pass_scored = false;
		do {
			// Add another room. If none can be added, the map ends as the last pass left it, unless that pass ended early
			if (is_undefined(add_new_room())) {
				if (_pass_scored) { break; }
				return fail_generation("no room could grow");
			}
			
			// Reset what the last pass placed. Then link more adjacent rooms, up to the average number of exits a room should
			// have, and then to give a room the exit kind of any required layout that no room can take
			reset_last_pass();
			link_adjacent_rooms();
			link_rooms_for_missing_layouts();
			
			// Place the start and heart, then check that each required layout still has a room of its own. If one doesn't, the
			// pass ends here, and the next pass's new room grows toward it, unless the map already has as many rooms as allowed
			if (!determine_start_and_heart_rooms()) { return fail_generation("the start and heart could not be placed"); }
			missing_required_layout = get_missing_required_layout();
			_pass_scored = is_undefined(missing_required_layout);
			if (_pass_scored) {
				// Reserve a room for each required layout, give every room a new layout, and place everything else
				reserve_rooms_for_required_layouts();
				assign_room_layouts();
				create_chests();
				if (!create_locked_exits_and_keys()) { return fail_generation("the locks and keys could not be placed"); }
				determine_special_exit_types();
				determine_collectables_rooms();
				determine_room_contents();
			
				// Score the map, from how likely the player is to arrive at each room holding the items that mitigate its hazards
				calculate_item_chances();
				calculate_map_difficulty_score();
			}
			else if (array_length(rooms) >= MAX_NUMBER_OF_ROOMS) { return fail_generation("a required layout got no room of its own"); }
		}
		until (_pass_scored && (difficulty_score >= MAP_DIFFICULTY_SCORE_TARGET || array_length(rooms) >= MAX_NUMBER_OF_ROOMS));
	
		// Calculate the time provided for the final map
		calculate_time_provided();
		return true;
	};

	/// @function determine_random_map_events()
	/// @description Randomly determines what is decided once per map, before any room exists: the map-wide events, the
	///	special room types the map includes, and how many special items spawn outside special rooms
	static determine_random_map_events = function() {
		// Set the Map Shape and Same Skeleton Type Events
		long_and_straight_map = get_random_chance_out_of(SPECIAL_MAP_SHAPE_PROBABILITY); // TODO: Implement this and other shapes. Add eval messages
		same_skeleton_type = get_random_chance_out_of(SAME_SKELETON_TYPE_PROBABILITY) ? get_skeleton_type(false) : noone; // TODO: Add eval messages

		// Randomly determine how many special rooms to include, at most one for each special room type the difficulty allows
		var _special_room_types_left = array_get_duplicate(available_special_room_types), _special_room_limit = SPECIAL_ROOM_LIMIT, _special_room_count = 0;
		for (var _i = 0; _i < _special_room_limit; _i++) {
			if (get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY)) { _special_room_count += 1; }
		}
		_special_room_count = min(_special_room_count, array_length(_special_room_types_left));
		
		// Include that many special room types, picked at random
		for (var _i = 0; _i < _special_room_count; _i++) {
			array_push(included_special_room_types, array_random_pop(_special_room_types_left));
		}

		// Randomly determine how many special items spawn outside special rooms. Each special room holds one, which counts toward the limit
		var _special_item_limit = SPECIAL_ITEM_LIMIT, _special_item_count = 0;
		for (var _i = _special_room_count; _i < _special_item_limit; _i++) {
			if (get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { _special_item_count += 1; }
		}
		special_item_count = _special_item_count;
	};

	/// @function determine_required_layouts()
	/// @description Randomly picks the layouts the map must include, in the order rooms are reserved for them: one layout of
	///	each included special room type, the hall of mirrors first, then one regular lantern layout, whose room always starts
	///	lit. The rooms each one can take are among the rooms every later one with the same exit kind can take, so reserving
	///	rooms in this order never takes the only room a later one could use.
	static determine_required_layouts = function() {
		// One random layout of each included special room type. The hall of mirrors goes first, since the fewest rooms can take it
		for (var _i = 0; _i < array_length(included_special_room_types); _i++) {
			var _special_room_type = included_special_room_types[_i];
			var _required_layout = { layout: array_random_get(_special_room_type.layouts), special_room_type: _special_room_type };
			if (_required_layout.layout.has_hall_of_mirrors) { array_insert(required_layouts, 0, _required_layout); }
			else { array_push(required_layouts, _required_layout); }
		}

		// Then one random regular lantern layout, of any exit kind, which goes last, since any room with its exit kind can take it
		var _lantern_layouts = [];
		for (var _type = 0; _type < layout_exit_types.count; _type++) {
			var _type_lantern_layouts = get_only_lantern_layouts(layouts_by_exit_type[_type]);
			array_copy(_lantern_layouts, array_length(_lantern_layouts), _type_lantern_layouts, 0, array_length(_type_lantern_layouts));
		}
		array_push(required_layouts, { layout: array_random_get(_lantern_layouts), special_room_type: undefined });
	};

	/// @function create_room_at_cell(_x, _y)
	/// @description Adds a room on a free grid cell, with no exits or layout yet
	/// @param {real} _x The grid column
	/// @param {real} _y The grid row
	/// @returns {GameRoom} The new room
	static create_room_at_cell = function(_x, _y) {
		var _room = new GameRoom(_x, _y);
		
		// Add room to map's rooms array, and room_at_cell lookup table
		_room.map_rooms_index = array_length(rooms);
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
		
		// A cardinal exit joins the map's cardinal exits
		if (_dir != directions.stairs) { array_push(cardinal_exits, _exit); }
		
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
	/// @returns {array} The count to each room, by map_rooms_index
	static measure_distances = function(_from_room) {
		var _distances = array_create(array_length(rooms), -1);
		var _queue = [_from_room];
		_distances[_from_room.map_rooms_index] = 0;
		for (var _next = 0; _next < array_length(_queue); _next++) {
			var _room = _queue[_next];
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				var _other_room = _room.get_connected_room(_dir);
				if (_other_room == -1 || _distances[_other_room.map_rooms_index] != -1) { continue; }
				_distances[_other_room.map_rooms_index] = _distances[_room.map_rooms_index] + 1;
				array_push(_queue, _other_room);
			}
		}
		return _distances;
	};

	/// @function fail_generation(_reason)
	/// @description Logs a failed attempt and destroys this map
	/// @param {string} _reason What failed
	/// @returns {bool} Always false, so the failed attempt can return it
	static fail_generation = function(_reason) {
		write_debug_message("Map generation attempt failed, retrying on the same random stream: " + _reason, debug_message_level.warning);
		destroy();
		return false;
	};

	/// @function add_new_room()
	/// @description Adds one room to the map. A required layout with no exits that no room could take last pass gets a new
	///	room only reached by stairs. Otherwise, the new room is sometimes joined to a random room by stairs, and otherwise by a
	///	cardinal exit, where it brings the rooms' exit kinds closest to exit_type_mix. When a required layout had no room of its
	///	own last pass, the new room is never joined by stairs at random, and a place that gives a room its exit kind comes first.
	/// @returns {GameRoom|undefined} The new room, or undefined if no room can grow
	static add_new_room = function() {
		// Stairs never take one of the last three rooms that could be the start or heart, since neither has stairs. No three
		// cells of the grid are all beside each other, so two of those rooms are never linked, and can always be the start and heart
		var _stairs_allowed = (count_possible_starts() > 3);

		// A required layout with no exits needs a new room only reached by stairs
		if (_stairs_allowed && !is_undefined(missing_required_layout) && missing_required_layout.layout.exit_type == layout_exit_types.none) {
			var _stairs_only_room = add_stairs_room(true);
			if (!is_undefined(_stairs_only_room)) { return _stairs_only_room; }
		}

		// Otherwise, unless the new room has to grow toward a missing required layout, sometimes join it by stairs, and sometimes
		// it can only ever be reached by stairs
		if (_stairs_allowed && is_undefined(missing_required_layout) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			var _stairs_room = add_stairs_room(get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY));
			if (!is_undefined(_stairs_room)) { return _stairs_room; }
		}

		// Otherwise, find the free cells beside rooms that can gain exits where a new room gives a room the missing required
		// layout's exit kind, if any do, and brings the rooms' exit kinds closest to exit_type_mix
		var _exit_type_counts = get_exit_type_counts(), _best_places = [], _best_fits_missing_layout = false, _best_deficit = infinity;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (!_room.can_gain_exits()) { continue; }

			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				// Skip sides whose cell is taken
				if (!is_undefined(get_adjacent_room(_room, _dir))) { continue; }

				// Keep the places that fit the missing required layout without taking a room another one needs, if any do, then the
				// ones closest to exit_type_mix
				var _new_exit_type_counts = get_exit_type_counts_after_link(_exit_type_counts, _room, _dir, undefined);
				var _fits_missing_layout = !is_undefined(missing_required_layout) && would_link_fit_required_layout(missing_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, undefined)
					&& keeps_rooms_for_required_layouts(_exit_type_counts, _new_exit_type_counts);
				var _deficit = get_exit_mix_deficit(_new_exit_type_counts);
				if (_fits_missing_layout > _best_fits_missing_layout || (_fits_missing_layout == _best_fits_missing_layout && _deficit < _best_deficit)) {
					_best_fits_missing_layout = _fits_missing_layout;
					_best_deficit = _deficit;
					_best_places = [];
				}
				if (_fits_missing_layout == _best_fits_missing_layout && _deficit == _best_deficit) { array_push(_best_places, { room: _room, dir: _dir }); }
			}
		}

		// Return undefined if no room can grow
		if (array_length(_best_places) == 0) { return undefined; }

		// Otherwise, add the new room at one of the best places, picked at random
		var _place = array_random_get(_best_places);
		var _new_room = create_room_at_cell(_place.room.virtual_x + get_dir_x_offset(_place.dir), _place.room.virtual_y + get_dir_y_offset(_place.dir));
		link_rooms_with_new_exit(_place.room, _new_room, _place.dir);
		return _new_room;
	};

	/// @function add_stairs_room(_is_stairs_only)
	/// @description Adds a room joined by stairs to a random room without stairs, on a free cell beside another room but not
	///	beside that one
	/// @param {bool} _is_stairs_only Whether the new room can only ever be reached by stairs
	/// @returns {GameRoom|undefined} The new room, or undefined if no room can take stairs
	static add_stairs_room = function(_is_stairs_only) {
		var _existing_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			// Skip rooms that already have stairs, or have no free cell for the new room
			var _room = _existing_rooms[_i];
			if (_room.has_exit(directions.stairs)) { continue; }
			var _cell = find_unoccupied_non_adjacent_cell(_room);
			if (is_undefined(_cell)) { continue; }

			// Create the new room in that cell, and link it to this room with stairs
			var _new_room = create_room_at_cell(_cell[0], _cell[1]);
			link_rooms_with_new_exit(_room, _new_room, directions.stairs);
			_new_room.has_no_cardinal_exits = _is_stairs_only;
			return _new_room;
		}

		// Return undefined if no room can take stairs
		return undefined;
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

	/// @function get_exit_type_counts()
	/// @description How many rooms have each exit kind, by their real cardinal exits
	/// @returns {array} Room counts, by layout_exit_types kind
	static get_exit_type_counts = function() {
		var _exit_type_counts = array_create(layout_exit_types.count, 0);
		for (var _i = 0; _i < array_length(rooms); _i++) { _exit_type_counts[rooms[_i].get_exit_type()] += 1; }
		return _exit_type_counts;
	};

	/// @function get_exit_type_counts_after_link(_exit_type_counts, _room, _dir, _other_room)
	/// @description How many rooms would have each exit kind once a room gains a cardinal exit to an adjacent room, or to a
	///	new room, which has just that exit
	/// @param {array} _exit_type_counts Room counts by exit kind now
	/// @param {GameRoom} _room The room that gains the exit
	/// @param {real} _dir The exit's direction from the room
	/// @param {GameRoom|undefined} _other_room The adjacent room it links to, or undefined for a new room
	/// @returns {array} Room counts, by layout_exit_types kind, in a new array
	static get_exit_type_counts_after_link = function(_exit_type_counts, _room, _dir, _other_room) {
		var _new_exit_type_counts = array_get_duplicate(_exit_type_counts);
		_new_exit_type_counts[_room.get_exit_type()] -= 1;
		_new_exit_type_counts[_room.get_exit_type_with_new_exit(_dir)] += 1;
		if (is_undefined(_other_room)) { _new_exit_type_counts[layout_exit_types.one] += 1; }
		else {
			_new_exit_type_counts[_other_room.get_exit_type()] -= 1;
			_new_exit_type_counts[_other_room.get_exit_type_with_new_exit(get_opposite_dir(_dir))] += 1;
		}
		return _new_exit_type_counts;
	};

	/// @function would_link_fit_required_layout(_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, _other_room)
	/// @description Whether a new cardinal exit would give one of its rooms a required layout's exit kind, so that more rooms
	///	have that kind than before
	/// @param {struct} _required_layout The required layout, as { layout, special_room_type }
	/// @param {array} _exit_type_counts Room counts by exit kind now
	/// @param {array} _new_exit_type_counts Room counts by exit kind with the new exit
	/// @param {GameRoom} _room The room that gains the exit
	/// @param {real} _dir The exit's direction from the room
	/// @param {GameRoom|undefined} _other_room The adjacent room it links to, or undefined for a new room, which has one exit
	/// @returns {bool}
	static would_link_fit_required_layout = function(_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, _other_room) {
		// The exit kind has to gain a room overall: a dead end that a new dead end grows from stops being one itself
		var _layout = _required_layout.layout;
		var _other_room_fits = is_undefined(_other_room) ? (_layout.exit_type == layout_exit_types.one) : _other_room.would_fit_layout_with_new_exit(get_opposite_dir(_dir), _layout);
		var _adds_room_of_exit_type = (_new_exit_type_counts[_layout.exit_type] > _exit_type_counts[_layout.exit_type]);
		return (_room.would_fit_layout_with_new_exit(_dir, _layout) || _other_room_fits) && _adds_room_of_exit_type;
	};

	/// @function keeps_rooms_for_required_layouts(_exit_type_counts, _new_exit_type_counts)
	/// @description Whether new room counts by exit kind leave each required layout's exit kind as many rooms as it has now,
	///	up to how many required layouts have that exit kind
	/// @param {array} _exit_type_counts Room counts by exit kind now
	/// @param {array} _new_exit_type_counts Room counts by exit kind after a change
	/// @returns {bool}
	static keeps_rooms_for_required_layouts = function(_exit_type_counts, _new_exit_type_counts) {
		var _needed_counts = array_create(layout_exit_types.count, 0);
		for (var _i = 0; _i < array_length(required_layouts); _i++) { _needed_counts[required_layouts[_i].layout.exit_type] += 1; }
		for (var _type = 0; _type < layout_exit_types.count; _type++) {
			if (min(_new_exit_type_counts[_type], _needed_counts[_type]) < min(_exit_type_counts[_type], _needed_counts[_type])) { return false; }
		}
		return true;
	};

	/// @function get_exit_mix_deficit(_exit_type_counts)
	/// @description How far room counts by exit kind are from exit_type_mix: for each kind, its count minus its share of the
	///	rooms with cardinal exits, squared, all added up. Rooms with no cardinal exits are left out, since stairs decide those.
	/// @param {array} _exit_type_counts Room counts by exit kind
	/// @returns {real}
	static get_exit_mix_deficit = function(_exit_type_counts) {
		// Add up the mix's weights and the rooms with cardinal exits
		var _mix_total = 0, _room_count = 0;
		for (var _type = layout_exit_types.one; _type < layout_exit_types.count; _type++) {
			_mix_total += exit_type_mix[_type];
			_room_count += _exit_type_counts[_type];
		}
		
		// Add up how far each exit kind's count is from its share
		var _deficit = 0;
		for (var _type = layout_exit_types.one; _type < layout_exit_types.count; _type++) {
			_deficit += sqr(_exit_type_counts[_type] - _room_count * exit_type_mix[_type] / _mix_total);
		}
		return _deficit;
	};

	/// @function reset_last_pass()
	/// @description Resets what the last pass placed, so the next pass can place it again: every room's map roles and spot
	///	objects, every exit's lock or special exit type, and the map's start and heart rooms, guaranteed items, special
	///	item types and extra key. The rooms and their exits stay as they are, and the pass gives every room a new layout.
	static reset_last_pass = function() {
		start_room = undefined;
		heart_room = undefined;
		guaranteed_items = [];
		special_item_types = [];
		extra_key_placed = false;
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].reset_map_roles_and_spot_objects(); }
		for (var _j = 0; _j < array_length(cardinal_exits); _j++) { cardinal_exits[_j].reset_exit_type(); }
	};

	/// @function link_adjacent_rooms()
	/// @description Links adjacent rooms with new cardinal exits until the rooms average AVERAGE_NUMBER_OF_ROOM_EXITS
	///	cardinal exits each, stopping early if no more links fit, since the average is only a target
	static link_adjacent_rooms = function() {
		while (2 * array_length(cardinal_exits) / array_length(rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
			if (!add_adjacent_exit()) { return; }
		}
	};

	/// @function add_adjacent_exit([_required_layout])
	/// @description Links a room to an adjacent room it isn't linked to yet, where that brings the rooms' exit kinds closest to
	///	exit_type_mix, but never where it takes a room a required layout needs. For a required layout no room can take, only
	///	a link that gives one of its rooms that layout's exit kind counts.
	/// @param {struct} [_required_layout] The required layout, as { layout, special_room_type } (undefined by default, for any link)
	/// @returns {bool} False if no link fits
	static add_adjacent_exit = function(_required_layout = undefined) {
		// Find the links that fit the required layout, if one is given, and bring the rooms' exit kinds closest to exit_type_mix
		var _exit_type_counts = get_exit_type_counts(), _best_links = [], _best_deficit = infinity;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (!_room.can_gain_exits()) { continue; }
		
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				// Skip sides that already have an exit, or have no adjacent room that can gain exits
				if (_room.has_exit(_dir)) { continue; }
				var _adjacent_room = get_adjacent_room(_room, _dir);
				if (is_undefined(_adjacent_room) || !_adjacent_room.can_gain_exits()) { continue; }

				// Skip links that take a room a required layout needs, or don't fit the required layout
				var _new_exit_type_counts = get_exit_type_counts_after_link(_exit_type_counts, _room, _dir, _adjacent_room);
				if (!keeps_rooms_for_required_layouts(_exit_type_counts, _new_exit_type_counts)) { continue; }
				if (!is_undefined(_required_layout) && !would_link_fit_required_layout(_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, _adjacent_room)) { continue; }

				// Keep the links closest to exit_type_mix
				var _deficit = get_exit_mix_deficit(_new_exit_type_counts);
				if (_deficit < _best_deficit) { _best_deficit = _deficit; _best_links = []; }
				if (_deficit == _best_deficit) { array_push(_best_links, { room: _room, dir: _dir, adjacent_room: _adjacent_room }); }
			}
		}
		
		// Return false if no new exit can be added
		if (array_length(_best_links) == 0) { return false; }

		// Otherwise, add one of the best links, picked at random
		var _link = array_random_get(_best_links);
		link_rooms_with_new_exit(_link.room, _link.adjacent_room, _link.dir);
		return true;
	};

	/// @function link_rooms_for_missing_layouts()
	/// @description Links adjacent rooms while a required layout has no room of its own to take it, each link giving a room
	///	its exit kind, until no link can. The start and heart aren't placed yet, so they can still take a room counted here.
	static link_rooms_for_missing_layouts = function() {
		var _missing_required_layout = get_missing_required_layout();
		while (!is_undefined(_missing_required_layout) && add_adjacent_exit(_missing_required_layout)) {
			_missing_required_layout = get_missing_required_layout();
		}
	};

	/// @function get_missing_required_layout()
	/// @description The first required layout left with no room of its own to take it, once each required layout before it
	///	takes a room. Required layouts are in an order where it never matters which room an earlier one takes.
	/// @returns {struct|undefined} The required layout, as { layout, special_room_type }, or undefined if each one has a room
	static get_missing_required_layout = function() {
		var _taken_rooms = [];
		for (var _i = 0; _i < array_length(required_layouts); _i++) {
			var _possible_rooms = get_rooms_for_required_layout(required_layouts[_i], _taken_rooms);
			if (array_length(_possible_rooms) == 0) { return required_layouts[_i]; }
			array_push(_taken_rooms, _possible_rooms[0]);
		}
		return undefined;
	};

	/// @function get_rooms_for_required_layout(_required_layout, _taken_rooms)
	/// @description The rooms that can take a required layout: their real cardinal exits match its exit kind, since a required
	///	layout's exits are never misleading, and a special layout's room must be allowed to become a special room
	/// @param {struct} _required_layout The required layout, as { layout, special_room_type }
	/// @param {array} _taken_rooms Rooms other required layouts took, which it can't take
	/// @returns {array} The rooms
	static get_rooms_for_required_layout = function(_required_layout, _taken_rooms) {
		var _layout = _required_layout.layout, _possible_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (array_contains(_taken_rooms, _room) || _room.get_exit_type() != _layout.exit_type) { continue; }
			if (_layout.is_special_room && !_room.can_become_special_room(_layout)) { continue; }
			array_push(_possible_rooms, _room);
		}
		return _possible_rooms;
	};

	/// @function determine_start_and_heart_rooms()
	/// @description Makes the start and heart rooms the two ends of the longest route through the map, stairs included,
	///	among the rooms each is allowed to be. Then places the cross and the encased heart, and measures every room's
	///	distance from the start. They're placed before any room gets a layout, so special layouts keep away from them.
	/// @returns {bool} False if no pair is allowed (never expected, since stairs always leave three rooms that could be either)
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
				var _distance = _distances[_heart_room.map_rooms_index];
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
			_room.distance_to_start = _distances_from_start[_room.map_rooms_index];
		}
		
		// Return success
		return true;
	};

	/// @function reserve_rooms_for_required_layouts()
	/// @description Reserves a random room for each required layout, among the rooms it can take that no earlier one took.
	///	Only called once no required layout is missing, so each one always gets a room.
	static reserve_rooms_for_required_layouts = function() {
		var _reserved_rooms = [];
		for (var _i = 0; _i < array_length(required_layouts); _i++) {
			var _room = array_random_get(get_rooms_for_required_layout(required_layouts[_i], _reserved_rooms));
			_room.required_layout = required_layouts[_i];
			array_push(_reserved_rooms, _room);
		}
	};

	/// @function assign_room_layouts()
	/// @description Gives every room a new layout, with a random orientation and lighting: each reserved room its required
	///	layout first, then every other room, in random order, the least used layout of the exit kind it shows, which differs
	///	from its real one when its exits are misleading
	static assign_room_layouts = function() {
		// Every room gets a new layout, so no layout is in use yet
		layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

		// Give each reserved room its required layout first, so the other rooms' least used layouts count them
		var _other_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i], _required_layout = _room.required_layout;
			if (is_undefined(_required_layout)) { array_push(_other_rooms, _room); }
			else { assign_layout_to_room(_room, _required_layout.layout, _required_layout.special_room_type); }
		}
		
		// Then give every other room the least used layout of the exit kind it shows
		_other_rooms = array_shuffle(_other_rooms);
		for (var _j = 0; _j < array_length(_other_rooms); _j++) {
			var _other_room = _other_rooms[_j];
			assign_layout_to_room(_other_room, choose_minimally_used_layout(layouts_by_exit_type[_other_room.determine_layout_exit_type()]), undefined);
		}
	};

	/// @function assign_layout_to_room(_room, _layout, _special_room_type)
	/// @description Gives a room a layout and counts it as used, then randomly determines the room's orientation and lighting.
	///	The required lantern layout is the only required layout of no special room type, and its room always starts lit.
	/// @param {GameRoom} _room The room
	/// @param {RoomLayout} _layout The layout
	/// @param {SpecialRoomType|undefined} _special_room_type The special room type the layout belongs to, or undefined for a regular layout
	static assign_layout_to_room = function(_room, _layout, _special_room_type) {
		var _is_guaranteed_lit_room = !is_undefined(_room.required_layout) && is_undefined(_special_room_type);
		_room.assign_layout(_layout, _special_room_type, _is_guaranteed_lit_room);
		layout_use_counts[_layout.layout_cache_index] += 1;
		_room.determine_layout_orientation();
		_room.determine_lighting();
	};

	/// @function choose_minimally_used_layout(_possible_layouts)
	/// @description Picks a random layout among the ones that fit and have been used the least
	/// @param {array} _possible_layouts The layouts that fit
	/// @returns {RoomLayout} The layout
	static choose_minimally_used_layout = function(_possible_layouts) {
		var _minimum_use_count = 0, _minimally_used_layouts = [];
		do {
			_minimally_used_layouts = [];
			for (var _i = 0; _i < array_length(_possible_layouts); _i++) {
				var _possible_layout = _possible_layouts[_i];
				if (layout_use_counts[_possible_layout.layout_cache_index] == _minimum_use_count) { array_push(_minimally_used_layouts, _possible_layout); }
			}
			_minimum_use_count += 1;
		}
		until (array_length(_minimally_used_layouts) > 0);
		
		return array_random_get(_minimally_used_layouts);
	};

	/// @function create_chests()
	/// @description Creates and assigns all the chests and their contents: each special room's own chest, a locked chest for
	///	each other special item, then the guaranteed items, and random chests, some locked and some traps
	static create_chests = function() {
		// Create each special room's chest and assign its content, a random special item type. Greed's chest holds it as a
		// regular item, which the room's red chest can make special
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms that aren't special rooms
			var _special_room = rooms[_i];
			if (!_special_room.is_special_room) { continue; }

			// Assign chest content to be a random special item type
			_special_room.add_special_room_chest();
			_special_room.chest_obj = pick_item_type(true);
		}

		// Create and Assign Special Chest Content for the special items outside the special rooms
		var _possible_rooms = array_shuffle(rooms), _special_items_left = special_item_count;
		for (var _i = 0; _i < array_length(_possible_rooms) && _special_items_left > 0; _i++) {
			// Skip rooms that can't have a chest with a special item
			var _special_item_room = _possible_rooms[_i];
			if (!_special_item_room.can_have_chest() || !_special_item_room.can_have_special_item()) { continue; }
			
			// Assign chest content to be a random special item type
			_special_item_room.add_chest();
			_special_item_room.has_special_item = true;
			_special_item_room.has_locked_chest = true;
			_special_item_room.chest_obj = pick_item_type(true);
			_special_items_left -= 1;
		}
		if (_special_items_left > 0) {
			// This should NEVER happen
			write_debug_message("No room left for " + string(_special_items_left) + " special item(s).", debug_message_level.warning);
		}
		
		// Determine number of Guaranteed Item Chests; This depends on results from the special chests for the gudetama item
		var _map_item = (global.difficulty == difficulties.easy || get_coin_flip()) ? obj_map : obj_compass;
		var _gudetama_item = get_coin_flip() ? obj_sword : obj_bomb;
		guaranteed_items = [];
		array_push(guaranteed_items, obj_torch); // Guarantee at least one torch; replaced later if torch is in hand
		array_push(guaranteed_items, _map_item); // Guarantee at least one map item; replaced later if it is in hand
		if (map_needs_gudetama_item()) { array_push(guaranteed_items, _gudetama_item); } // Guarantee at least one item that can defeat the gudetama
		
		// Create and Assign Regular Chests, including GUaranteed Items
		_possible_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			// Skip rooms that can't have a chest
			var _regular_chest_room = _possible_rooms[_i];
			if (!_regular_chest_room.can_have_chest()) { continue; }
			
			// Create Guaranteed Item Chests first, then random chests after that
			var _guaranteed_chest = (array_length(guaranteed_items) > 0), _create_chest = (_guaranteed_chest || get_random_chance_out_of(CHEST_PROBABILITY));
			if (_create_chest) {
				_regular_chest_room.add_chest();
				
				if (_guaranteed_chest) {
					_regular_chest_room.chest_obj = array_random_pop(guaranteed_items);
					_regular_chest_room.has_guaranteed_item = true;
				}
				else {
					// Lock random chests
					_regular_chest_room.has_locked_chest = get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
					
					// Trap random unlocked chests. A fountain shoots at the player, so a room whose layout has eyes only gets the statue trap
					var _chest_content = undefined;
					if (_regular_chest_room.has_basic_chest() && get_random_chance_out_of(TRAP_CHEST_PROBABILITY) && !_regular_chest_room.would_exceed_max_difficulty("obj_chest")) { 
						_chest_content = (_regular_chest_room.get_object_count_from_layout("obj_eyes") == 0 && get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) ? obj_fountain : obj_statue;
					}
					
					// Assign random item to chest
					_regular_chest_room.chest_obj = _chest_content ?? pick_item_type(false);

				}
			}
		}
		
		// Check that all guaranteed chests were spawned
		for (var _i = 0; _i < array_length(guaranteed_items); _i++) {
			// This should NEVER happen
			write_debug_message("No room left for " + string(get_object_name(guaranteed_items[_i])) + " guaranteed item.", debug_message_level.warning);
		}
	};

	/// @function pick_item_type(_is_special_item, [_items_in_hands])
	/// @description Picks an item type at random among the types still allowed. A special item can be any type the
	///	difficulty allows, keys included, but each type is a special item once at most. A regular item is never a key,
	///	or a type at its cap, counting the chests and the given starting hand items.
	/// @param {bool} _is_special_item Whether the item is a special item
	/// @param {array} [_items_in_hands] The starting hand items to count ([] by default, to ignore the hands)
	/// @returns {Asset.GMObject}
	static pick_item_type = function(_is_special_item, _items_in_hands = []) {
		// Loop through all possible item types to see which are still possible to spawn
		var _available_item_types = global.available_items[global.difficulty], _possible_item_types = [];
		for (var _i = 0; _i < array_length(_available_item_types); _i++) {
			var _item_type = _available_item_types[_i];
			if (_is_special_item) {
				// Add any type that isn't a special item yet to the list of possibilities
				if (!array_contains(special_item_types, _item_type)) { array_push(_possible_item_types, _item_type); }
			}
			else if (_item_type != obj_key && count_regular_items(_item_type, _items_in_hands) < get_item_cap(_item_type)) {
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
			// Count it if the chest holds the type, and it's neither a special item nor a key or bomb placed for the locks
			var _room = rooms[_i];
			if (_room.chest_obj == _item_type && !_room.has_special_item && !_room.key_in_chest) { _count += 1; }
		}
		
		// Loop through the given hand items and add those item types to the count
		for (var _j = 0; _j < array_length(_hands); _j++) {
			if (_hands[_j] == _item_type) { _count += 1; }
		}
		
		// Return the count
		return _count;
	};

	/// @function get_item_cap(_item)
	/// @description How many regular copies of an item the chests and starting hands may hold together
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
				return 2;
			case obj_torch:
				return 3;
			default:
				return infinity;
		}
	};

	/// @function map_needs_gudetama_item()
	/// @description Returns whether we need to spawn an item that can kill a gudetama or not
	/// @returns {bool} True if an item is needed, false otherwise
	static map_needs_gudetama_item = function() {
		// Find the room with the gudetama, if the map has one. Return false if it doesn't
		var _gudetama_room = undefined;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			if (rooms[_i].layout.get_object_count("obj_gudetama") > 0) { _gudetama_room = rooms[_i]; break; }
		}
		if (is_undefined(_gudetama_room)) { return false; }

		// Find a chest in another room that already holds a gudetama item, and return false if one is found
		for (var _j = 0; _j < array_length(rooms); _j++) {
			var _room = rooms[_j];
			if (_room == _gudetama_room) { continue; }
			if (_room.holds_gudetama_item()) { return false; }
		}

		// Otherwise, return true to ensure an item is spawned
		return true;
	};

	/// @function create_locked_exits_and_keys()
	/// @description Locks every cardinal exit of the heart room, then randomly locks other cardinal exits that can be
	///	locked, and backs each lock with keys before the next one is added
	/// @returns {bool} False if the heart locks could not be backed (a last resort, never expected)
	static create_locked_exits_and_keys = function() {
		// First, lock every exit of the heart room and add its keys
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _heart_exit = heart_room.exits[_dir];
			if (_heart_exit != -1) { _heart_exit.exit_type = exit_types.locked_doors; }
		}
		if (!create_keys_for_locks()) { return false; }

		// Lock other exits at random, and add keys for each
		var _exits = array_shuffle(cardinal_exits);
		for (var _i = 0; _i < array_length(_exits); _i++) {
			var _exit = _exits[_i];
			if (!_exit.can_be_locked() || !get_random_chance_out_of(LOCKED_DOOR_PROBABILITY / 2)) { continue; }

			_exit.exit_type = exit_types.locked_doors;
			if (!create_keys_for_locks(_exit)) { return false; }
		}
		
		// Return success
		return true;
	};

	/// @function create_keys_for_locks([_newest_lock])
	/// @description Checks every order the player could spend keys on locks in, and adds a key to the area where an
	///	order gets them stuck, until no order does. If no room there can take
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
			_newest_lock.exit_type = exit_types.none;
			_newest_lock = get_untried_lockable_exit(_tried_exits);
			
			// Continue with map generation without locking an exit, if no lockable exit could be found
			if (is_undefined(_newest_lock)) {
				// This should NEVER happen
				write_debug_message("Dropped a lock that no key could unlock.", debug_message_level.warning);
				break;
			}
			
			// Otherwise, lock the new exit and try again.
			_newest_lock.exit_type = exit_types.locked_doors;
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
			if (!_stuck_area.is_room_reached(_possible_room)) { continue; }

			if (!_possible_room.is_heart_room && !_possible_room.has_key && !_possible_room.has_extra_key && array_length(_possible_room.layout.key_spots) > 0) { array_push(_possible_rooms, _possible_room); }
		}
		if (array_length(_possible_rooms) == 0) { return false; }

		// Select a random room out of the possible rooms to add the key to
		var _room = array_random_get(_possible_rooms), _key_is_bomb = false;
		if (_room.can_have_chest() && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) {
			// The chest is never locked or hidden, and never holds a special item
			_room.key_in_chest = true;
			_room.set_stairs_spot_object(obj_chest);
			_key_is_bomb = _stuck_area.can_use_bombs_as_keys() && get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY);
			_room.chest_obj = _key_is_bomb ? obj_bomb : obj_key;
		}
		else { _room.key_spot = array_random_get(_room.layout.key_spots); }
		_room.has_key = true;

		// The first bomb standing in for a key on the map also brings an extra key to the same area
		if (_key_is_bomb && !extra_key_placed) { add_extra_key_to_area(_stuck_area); }

		// Return true for successful key placement
		return true;
	};

	/// @function add_extra_key_to_area(_stuck_area)
	/// @description Puts an extra key on a free key spot of a random room in a search area, for the first bomb that
	///	stands in for a key there. The room's has_key stays as it is, so the lock search never counts the extra key: it's
	///	a spare on top of the keys and bombs the locks need.
	/// @param {LockSearchArea} _stuck_area The search area the bomb went to
	static add_extra_key_to_area = function(_stuck_area) {
		// Rooms in the area with no key on their key spots yet, which the bomb's own room always is
		var _possible_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _possible_room = rooms[_i];
			if (!_stuck_area.is_room_reached(_possible_room)) { continue; }

			if (!_possible_room.is_heart_room && _possible_room.key_spot == -1 && array_length(_possible_room.layout.key_spots) > 0) { array_push(_possible_rooms, _possible_room); }
		}
		if (array_length(_possible_rooms) == 0) {
			// This should NEVER happen, since the bomb's own room always has a free key spot
			write_debug_message("No room could take the extra key a bomb brings.", debug_message_level.warning);
			return;
		}

		// Put the extra key on a random key spot of a random one of them
		var _room = array_random_get(_possible_rooms);
		_room.has_extra_key = true;
		_room.key_spot = array_random_get(_room.layout.key_spots);
		extra_key_placed = true;
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

	/// @function get_locked_exits()
	/// @description Gets a list of all locked exits in the map
	/// @returns {array} The list of locked exits
	static get_locked_exits = function() {
		// Loop through every map cardinal exit to find locked exits
		var _locked_exits = [];
		for (var _i = 0; _i < array_length(cardinal_exits); _i++) {
			// Skip exits that aren't locked
			var _possible_exit = cardinal_exits[_i];
			if (_possible_exit.exit_type != exit_types.locked_doors) { continue; }
			
			// Add the exit to the list of locked exits
			array_push(_locked_exits, _possible_exit);
		}
		return _locked_exits;
	};

	/// @function get_relevant_locked_chest_rooms()
	/// @description Gets a list of all rooms with a relevant locked chest in the map
	/// @returns {array} The list of relevant locked chest rooms
	static get_relevant_locked_chest_rooms = function() {
		// Loop through every map room exit to find relevant locked chests
		var _relevant_locked_chest_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms with unlocked chests
			var _room = rooms[_i];
			if (!_room.has_locked_chest) { continue; }
			
			// Check if room is relevant
			var _holds_special_key = (_room.chest_obj == obj_key && _room.has_special_item);
			var _holds_special_bomb = (_room.chest_obj == obj_bomb && _room.has_special_item);
			var _holds_needed_torch = (_room.chest_obj == obj_torch);
			
			// Reset the chest index, then add the chest if it is relevant and assign its new index
			_room.relevant_locked_chests_index = -1;
			if (_holds_special_key || _holds_needed_torch || _holds_special_bomb) {
				_room.relevant_locked_chests_index = array_length(_relevant_locked_chest_rooms);
				array_push(_relevant_locked_chest_rooms, _room);
			}
		}
		return _relevant_locked_chest_rooms;
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
		// Setup the relevant lists for this map that LockSearchAreas will interact with. We do this here once since it doesn't change with
		// each LockSearchArea, and we create thousands of those and only one GameMap per map generation cycle, speeding up map generation
		relevant_locked_chest_rooms = get_relevant_locked_chest_rooms();
		locked_exits = get_locked_exits();
		
		// Set up the initial queue of areas to check, map of area check queue keys, and initial area
		var _all_rooms_reached_bitmask = (1 << array_length(rooms)) - 1, _reached_rooms_bitmask = start_room.get_reachable_rooms_bitmask(), _relevant_locked_chests_bitmask = 0;
		var _initial_search_area = new LockSearchArea(self, _reached_rooms_bitmask, _relevant_locked_chests_bitmask), _search_area_check_queue = [_initial_search_area];
		var _search_areas_in_queue_map = {};
		_search_areas_in_queue_map[$ get_search_area_key(_reached_rooms_bitmask, _relevant_locked_chests_bitmask)] = true;
		
		// Iterate through the searched area queue, checking that each one is possible
		while (array_length(_search_area_check_queue) > 0) {
			// Get the next area to search, along with what the player finds in it
			var _search_area = array_shift(_search_area_check_queue);
			
			// Skip checking area if it reached all rooms or can use a special item to unlock all future exits
			if (_search_area.reached_rooms == _all_rooms_reached_bitmask || _search_area.can_use_special_item()) { continue; }
			
			// Otherwise, the player is stuck here if the worst order leaves them no key
			if (_search_area.get_keys_remaining() <= 0) { return _search_area; }

			// Otherwise, spend a key to open a locked door at the edge of the area, reaching the rooms behind it...
			for (var _i = 0; _i < array_length(locked_exits); _i++) {
				// Skip unlocking the exit if already unlocked (both sides reached) OR exit is unreachable (neither side reached yet)
				var _locked_exit = locked_exits[_i];
				var _room_1_reached =_search_area.is_room_reached(_locked_exit.room_1);
				var _room_2_reached =_search_area.is_room_reached(_locked_exit.room_2);
				if (_room_1_reached == _room_2_reached) { continue; }
				
				// Add a new area to the queue of areas to check, which is the same as the old area, plus this new room
				var _new_room = (_room_1_reached) ? _locked_exit.room_2 :  _locked_exit.room_1;
				
				var _new_reached_rooms = _search_area.reached_rooms | _new_room.get_reachable_rooms_bitmask();
				add_search_area_to_queue_if_unique(_search_area_check_queue, _search_areas_in_queue_map, _new_reached_rooms, _search_area.relevant_locked_chests);
			}
			
			// ...or a locked chest that matters, in the area
			for (var _chest = 0; _chest < array_length(relevant_locked_chest_rooms); _chest++) {
				// Skip unlocking chests that are already unlocked in this area
				var _new_relevant_locked_chests = _search_area.relevant_locked_chests | (1 << _chest);
				if (_new_relevant_locked_chests == _search_area.relevant_locked_chests) { continue; }
				
				// Skip unlocking chests in rooms that haven't been reached yet
				var _room_with_chest = relevant_locked_chest_rooms[_chest];
				if (!_search_area.is_room_reached(_room_with_chest)) { continue; }
				
				// Otherwise, add a new area to the queue of areas to check, which is this same area with the new chest unlocked
				add_search_area_to_queue_if_unique(_search_area_check_queue, _search_areas_in_queue_map, _search_area.reached_rooms, _new_relevant_locked_chests);
			}
		}
		
		return undefined;
	};

	/// @function add_search_area_to_queue_if_unique(_search_area_check_queue, _search_areas_in_queue_map, _reached_rooms, _relevant_locked_chests)
	/// @description Adds an area to the lock search's queue, unless the same area was already queued
	/// @param {array} _search_area_check_queue		The queue of areas to check, in order
	/// @param {struct} _search_areas_in_queue_map	Every area queued so far, by its search area key
	/// @param {real} _reached_rooms				Bitmask of the rooms the new area reaches
	/// @param {real} _relevant_locked_chests		Bitmask of the chests that matter the new area has unlocked
	static add_search_area_to_queue_if_unique = function(_search_area_check_queue, _search_areas_in_queue_map, _reached_rooms, _relevant_locked_chests) {
		// Skip adding to the queue if this area was already queued
		var _area_key = get_search_area_key(_reached_rooms, _relevant_locked_chests);
		if (!is_undefined(_search_areas_in_queue_map[$ _area_key])) { return; }
		
		// Mark the area as queued, and add it to the queue
		var _search_area = new LockSearchArea(self, _reached_rooms, _relevant_locked_chests);
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

			// Otherwise, give each of its cardinal exits its own chance at a special exit type
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				// Skip exits that don't exist, or already have a special type assigned
				var _exit = _possible_room.exits[_dir];
				if (_exit == -1 ||_exit.exit_type != exit_types.none) { continue; }

				// Sometimes give the exit illusion walls, unless it leads to the start room
				if (!_exit.get_connected_room(_possible_room).is_start_room && get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) { _exit.exit_type = exit_types.illusion_walls; continue; }
				
				// Otherwise, sometimes give the exit plain doors
				if (get_random_chance_out_of(OPEN_DOOR_PROBABILITY * 2)) { _exit.exit_type = exit_types.unlocked_doors; continue; }
			}
		}
	};

	/// @function determine_collectables_rooms()
	/// @description Gives collectables to the heart room and to random other rooms, never the start, then to more random
	///	rooms until at least a quarter of the rooms, plus one, have them. A room only gets them when its floor key and
	///	portcullis button leave a collectable spot free, or the button can move to make one free.
	static determine_collectables_rooms = function() {
		var _possible_rooms = array_shuffle(rooms), _collectables_rooms = 1;
		heart_room.has_collectables = true; // The heart room never has a key or a button

		// Add collectables to heart room and other rooms at random
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			var _possible_room = _possible_rooms[_i];
			if (!_possible_room.is_start_room && !_possible_room.is_heart_room && get_random_chance_out_of(COLLECTABLE_PROBABILITY) && _possible_room.make_room_for_collectables()) {
				_possible_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}

		// Add to more random rooms to meet the minimum if needed
		var _minimum_collectable_rooms = ceil(array_length(rooms) / 4) + 1;
		for (var _j = 0; _j < array_length(_possible_rooms) && _collectables_rooms < _minimum_collectable_rooms; _j++) {
			var _extra_room = _possible_rooms[_j];
			if (!_extra_room.is_start_room && !_extra_room.has_collectables && _extra_room.make_room_for_collectables()) {
				_extra_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}
	};

	/// @function determine_room_contents()
	/// @description Randomly determines every room's content, now that each room's layout, map roles, spot objects and
	///	special exit types decide which of its layout's instances survive
	static determine_room_contents = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].determine_room_content(same_skeleton_type); }
	};

	/// @function adjust_items_for_hands()
	/// @description Swaps chest contents for the items the player starts with in their hands, once the map is final: the
	///	guaranteed chest's map or compass, and any regular item the hands take past its cap
	static adjust_items_for_hands = function() {
		// Setup variables based on the items the player chose to start with
		var _hand_items = [global.player_left_hand_item, global.player_right_hand_item];
		var _map_in_hand = array_contains(_hand_items, obj_map), _compass_in_hand = array_contains(_hand_items, obj_compass), _torch_in_hand = array_contains(_hand_items, obj_torch)
		var _sword_in_hand = array_contains(_hand_items, obj_sword), _bomb_in_hand = array_contains(_hand_items, obj_bomb);
		
		// Loop through each room to determine if it has a guaranteed item  that needs replaced
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms without guaranteed items
			_guaranteed_item_room = rooms[_i];
			if (!_guaranteed_item_room.has_guaranteed_item) { continue; }
				
			// Swap out the guaranted item if it matches an item in the player's hands
			var _map_replacement_item = _guaranteed_item_room.chest_obj;
			switch (_guaranteed_item_room.chest_obj) {
				case obj_map:
				case obj_compass: {
					if (_map_in_hand && _compass_in_hand) { _map_replacement_item = pick_item_type(false, _hand_items); }
					else if (_map_in_hand && _guaranteed_item_room.chest_obj == obj_map) { _map_replacement_item = obj_compass; }
					else if (_map_in_hand && _guaranteed_item_room.chest_obj == obj_compass) { _map_replacement_item = obj_map; }
					break;
				}
				case obj_torch: {
					if (_torch_in_hand) { _map_replacement_item = pick_item_type(false, _hand_items); }
					break;
				}
				case obj_bomb:
				case obj_sword: {
					if (_sword_in_hand || _bomb_in_hand) { _map_replacement_item = pick_item_type(false, _hand_items); }
					break;
				}
			}
			_guaranteed_item_room.chest_obj = _map_replacement_item;
		}
	};

	// =================================================================================================
	// CALCULATIONS TO PASS OFF TO CONTROLLER
	// Each room works out its own difficulty score and time, which the calculations below add up
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
			var _hazard_mitigation = _room.hazard_mitigation;
			_hazard_mitigation.chance_holding_staff = _staff_chance;
			_hazard_mitigation.chance_holding_sword = _sword_chance;
			_hazard_mitigation.chance_holding_special_sword = _special_sword_chance;
			
			// Set its lit room chances
			if (_room.is_lit()) { _hazard_mitigation.chance_of_light = 1; }
			else if (_room.can_light_torch()) { _hazard_mitigation.chance_of_light = _torch_chance; }
			else { _hazard_mitigation.chance_of_light = _lit_torch_chance; }
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
		time_provided += TIME_ALLOWANCE; // * get_backtracking_time();
	};

	/// @function measure_travel_times(_from_room, _skip_exit, _crossing)
	/// @description Seconds from one room to every other by the quickest way, through cardinal exits and stairs
	///	with locks ignored, counting the crossing time of each room entered.
	/// @param {GameRoom} _from_room Where to start
	/// @param {RoomExit|undefined} _skip_exit An exit not to use, or undefined
	/// @param {array} _crossing Each room's crossing time, by map_rooms_index
	/// @returns {array} Seconds to each room by map_rooms_index, or -1 where it can't be reached
	static measure_travel_times = function(_from_room, _skip_exit, _crossing) {
		var _count = array_length(rooms), _times = array_create(_count, -1), _settled = array_create(_count, false);
		_times[_from_room.map_rooms_index] = 0;
		repeat (_count) {
			var _room = undefined, _best = infinity;
			for (var _i = 0; _i < _count; _i++) {
				var _index = rooms[_i].map_rooms_index;
				if (!_settled[_index] && _times[_index] >= 0 && _times[_index] < _best) { _best = _times[_index]; _room = rooms[_i]; }
			}
			if (is_undefined(_room)) { break; }
			_settled[_room.map_rooms_index] = true;
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				var _exit = _room.exits[_dir];
				if (_exit == -1 || _exit == _skip_exit) { continue; }
				var _other = _exit.get_connected_room(_room);
				var _time = _best + _crossing[_other.map_rooms_index];
				if (!_settled[_other.map_rooms_index] && (_times[_other.map_rooms_index] < 0 || _time < _times[_other.map_rooms_index])) { _times[_other.map_rooms_index] = _time; }
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
		for (var _i = 0; _i < array_length(rooms); _i++) { _crossing[rooms[_i].map_rooms_index] = rooms[_i].get_crossing_time(); }
 
		// The finish: the heart has to be carried back to the start cross, from the far end of the map
		var _heart_times = measure_travel_times(heart_room, undefined, _crossing);
		var _to_finish = _heart_times[start_room.map_rooms_index];
		if (_to_finish > 0) { _extra += _to_finish; }
 
		for (var _j = 0; _j < array_length(cardinal_exits); _j++) {
			var _exit = cardinal_exits[_j];
			if (_exit.exit_type != exit_types.locked_doors && _exit.exit_type != exit_types.illusion_walls) { continue; }
 
			// The player reaches the side nearer the start first
			var _near = (_from_start[_exit.room_2.map_rooms_index] < _from_start[_exit.room_1.map_rooms_index]) ? _exit.room_2 : _exit.room_1;
			var _times = measure_travel_times(_near, _exit, _crossing);
 
			// A lock met before its key: the trip from it to the nearest key on its near side, and back
			if (_exit.exit_type == exit_types.locked_doors) {
				var _nearest = infinity;
				for (var _k = 0; _k < array_length(rooms); _k++) {
					var _to_key = _times[rooms[_k].map_rooms_index];
					if ((rooms[_k].has_key || rooms[_k].has_extra_key) && _to_key >= 0) { _nearest = min(_nearest, _to_key); }
				}
				if (_nearest != infinity) { _extra += LOCK_BACKTRACK_SHARE * 2 * _nearest; }
			}
 
			// An illusion wall taken for a dead end: the trip back to it once everything else on its side is done
			// (on average the mean trip from those rooms), and the search
			if (_exit.exit_type == exit_types.illusion_walls) {
				var _sum = 0, _rooms_on_side = 0;
				for (var _m = 0; _m < array_length(rooms); _m++) {
					var _back = _times[rooms[_m].map_rooms_index];
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
			var _to_start = _wrath_times[start_room.map_rooms_index];
			if (_to_start > 0) { _extra += 2 * _to_start; }
		}
		return _extra;
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

	// TODO: Is this unused? Can we remove it?
	/// @function destroy()
	/// @description Frees every room's path grids. Only for a map that will never be played, like a failed
	///	attempt; the controller frees a played map's rooms itself.
	static destroy = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].destroy(); }
	};

	// ============================
	// Instance Variables
	// ============================

	// The four directions a cardinal exit can face
	static cardinal_exit_directions = [directions.up, directions.right, directions.down, directions.left];

	// How often each exit kind came up in the old Ruby layout script, by layout_exit_types kind, which growth steers the rooms
	// with cardinal exits toward. Rooms with no exits are left out, since stairs decide those
	static exit_type_mix = [0, 6, 4, 8, 6, 3];

	// Set up the layout cache every map shares, the first time a map is made
	static layout_cache = undefined;
	if (is_undefined(layout_cache)) {
		var _cached_layouts = [], _special_room_types = [
			new SpecialRoomType("pride", [rm_four_exits_23, rm_four_exits_24]),						// Hall of mirrors
			new SpecialRoomType("envy", [rm_four_exits_22, rm_one_exit_27, rm_three_exits_30]),		// Giant eye
			new SpecialRoomType("wrath", [rm_one_exit_22]),											// Inverted cross
			new SpecialRoomType("greed", [rm_one_exit_30]),											// Red chest
			new SpecialRoomType("sloth", [rm_one_exit_23])											// Gudetama
		];

		// Read each room asset as a layout, and keep the usable ones
		for (var _room_asset = room_first; _room_asset != -1; _room_asset = room_next(_room_asset)) {
			// Skip unusable layouts
			var _layout = new RoomLayout(_room_asset);
			if (!_layout.is_usable) { continue; }
			
			// Add layout to the list of layouts to cache
			_layout.layout_cache_index = array_length(_cached_layouts);
	
			// Handle setup for layouts that a special room types uses
			for (var _i = 0; _i < array_length(_special_room_types); _i++) {
				var _special_room_type = _special_room_types[_i];

				for (var _j = 0; _j < array_length(_special_room_type.room_references); _j++) {
					var _special_room_reference = _special_room_type.room_references[_j];

					// Mark the room layout as a special room layout, and add it to the SpecialRoomType's layouts
					if (_special_room_reference == _layout.room_reference) {
						_layout.is_special_room = true;
						_special_room_type.layouts[_j] = _layout;
						break;
					}
				}
			}

			// Work out the lowest difficulty it appears on, now that it knows whether it's a special room
			_layout.setup_minimum_difficulty();
			array_push(_cached_layouts, _layout);
		}
		layout_cache = { layouts: _cached_layouts, special_room_types: _special_room_types };
	}

	// Layouts this difficulty allows for regular (not special) rooms by exit kind, and how many rooms use each
	layouts_by_exit_type = [];
	layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

	// Special room types with a layout this difficulty allows, each with only those layouts
	available_special_room_types = [];

	// Map-wide events, randomly determined once per map
	long_and_straight_map = false;
	same_skeleton_type = noone;
	special_item_count = 0;
	included_special_room_types = [];
	required_layouts = [];					// The layouts the map must include, as { layout, special_room_type }, in the order rooms are reserved for them
	missing_required_layout = undefined;	// The first required layout the last pass left with no room of its own, which the next new room grows toward

	// The rooms, and the exits between them
	rooms = [];
	room_at_cell = {};						// Each room by its grid cell ("x,y"), so finding an adjacent room needs no search
	cardinal_exits = [];					// Every exit joining two adjacent rooms, which is every exit but the stairs
	locked_exits = [];						// Each locked cardinal exit, reset during lock and key search
	relevant_locked_chest_rooms = [];		// Each room with a locked chest that affects the lock and key search, reset during the search

	// What each pass places and scores, placed again each time map generation adds a room
	start_room = undefined;
	heart_room = undefined;
	guaranteed_items = [];
	special_item_types = [];				// Each item type placed as a special item so far
	extra_key_placed = false;				// Whether the first bomb standing in for a key has brought its extra key yet
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
		var _special_room_type = layout_cache.special_room_types[_j], _allowed_room_references = [], _allowed_layouts = [];

		for (var _k = 0; _k < array_length(_special_room_type.layouts); _k++) {
			var _special_layout = _special_room_type.layouts[_k];
			if (is_struct(_special_layout) && _special_layout.minimum_difficulty <= global.difficulty) {
				array_push(_allowed_room_references, _special_layout.room_reference);
				array_push(_allowed_layouts, _special_layout);
			}
		}
		if (array_length(_allowed_layouts) == 0) { continue; }

		// A new special room type only has its room assets, so give it the allowed layouts straight from the cache
		var _available_special_room_type = new SpecialRoomType(_special_room_type.name, _allowed_room_references);
		_available_special_room_type.layouts = _allowed_layouts;
		array_push(available_special_room_types, _available_special_room_type);
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
}

// ============================
// Global Map Generation Functions
// ============================

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
	_map.calculate_collectables_and_items_lists();

	return _map;
}

/// @function get_skeleton_type_chances()
/// @description What a skeleton spot can hold at the current difficulty, aside from a basic skeleton, with it's chance out of SKELETON_TYPE_CHANCE_MAX
/// @returns {array} The ordered array of each type as { type, chance }
function get_skeleton_type_chances() {
	switch (global.difficulty) {
		case difficulties.easy: return [{ type: obj_cockroach, chance: 3 }];
		case difficulties.medium: return [{ type: obj_cockroach, chance: 6 }, { type: obj_fast_skeleton, chance: 6 }, { type: obj_fat_skeleton, chance: 4 }, { type: obj_invisible_skeleton, chance: 2 }];
		case difficulties.hard: return [{ type: obj_cockroach, chance: 10 }, { type: obj_invisible_skeleton, chance: 8 }, { type: obj_fat_skeleton, chance: 8 }, { type: obj_fast_skeleton, chance: 8 }, { type: obj_cultist, chance: 4 }, { type: obj_fire_skeleton, chance: 4 }];
		case difficulties.very_hard: return [{ type: obj_fat_skeleton, chance: 15 }, { type: obj_fast_skeleton, chance: 15 }, { type: obj_cockroach, chance: 12 }, { type: obj_invisible_skeleton, chance: 12 }, { type: obj_fire_skeleton, chance: 10 }, { type: obj_cultist, chance: 10 }, { type: obj_snake, chance: 4 }];
		default: return [];
	}
}
