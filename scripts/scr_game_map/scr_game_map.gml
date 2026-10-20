// ===== MAP SIZE =====
#macro MIN_NUMBER_OF_ROOMS get_probability_for_difficulty([4, 8, 12, 15, 18])
#macro MAX_NUMBER_OF_ROOMS get_probability_for_difficulty([8, 12, 18, 22, 24]) //[12, 16, 24, 28, 32])
#macro MAP_DIFFICULTY_SCORE_TARGET get_probability_for_difficulty([0, 2, 10, 22, 36]) // Rooms are added until the map's difficulty score reaches this, up to MAX_NUMBER_OF_ROOMS.
#macro AVERAGE_NUMBER_OF_ROOM_EXITS (20/9)

// ===== MAP CONTENT =====
#macro SPECIAL_MAP_SHAPE_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 0])
#macro SPECIAL_ROOM_LIMIT get_probability_for_difficulty([0, 0, 0, 1, 2])
#macro SPECIAL_ROOM_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 6])
#macro SPECIAL_ITEM_LIMIT get_probability_for_difficulty([0, 1, 1, 2, 3])
#macro SPECIAL_ITEM_PROBABILITY get_probability_for_difficulty([0, 7, 3, 3, 2])
#macro NO_CARDINAL_EXIT_ROOM_PROBABILITY get_probability_for_difficulty([0, 12, 8, 6, 4]) // This happens only after the stairs probability succeeds, so its combined with 1/5
#macro DUPLICATE_LAYOUT_DURING_ASSIGNMENT_PROBABILITY get_probability_for_difficulty([0, 0, 0, 0, 64]) 
#macro COLLECTABLE_PROBABILITY get_probability_for_difficulty([4, 3, 3, 3, 2]) 
#macro LOCKED_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 12, 10, 6])
#macro TRAP_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 0, 8, 4])  // This happens only after the chest probability succeeds, so its combined with that probability.
#macro KEY_IN_CHEST_PROBABILITY 3
#macro BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY get_probability_for_difficulty([0, 0, 8, 2, 1])
#macro PORTCULLIS_PROBABILITY get_probability_for_difficulty([0, 0, 12, 8, 6]) 
#macro OPEN_DOOR_PROBABILITY get_probability_for_difficulty([0, 32, 24, 12, 8])
#macro MAP_ENCOUNTER_CHANCE_MULTIPLIER 3 // How likely the player is to encounter a specific room, per share of the map's rooms that count: one sword chest in fifteen rooms gives a 0.2 chance of holding a sword


// ===== TIME =====
// Seconds a careful novice needs on top of every room's first visit
#macro LOCKED_DOOR_TIME 20 // Getting a key for each locked door: usually one is held by then, otherwise it's a few rooms back
#macro ILLUSION_WALL_TIME 20 // Finding each illusion wall, which looks like any other wall
#macro TIME_DIFFICULTY_MULTIPLIER get_probability_for_difficulty([0, 1.3, 1.1, 1, 0.95]) // The run's time, as a multiple of the time a careful novice needs for the map

/// @function GameMap()
/// @description The plan for one map, and the methods that generate it: the layouts its difficulty allows, its rooms
///	and the exits between them, its map-wide events, what each pass spawns, and what the controller keeps once generation
///	ends. Rooms and exits are only added through its methods, so its lookups always match its rooms. The first map of
///	a session also reads every room asset into the layout cache that every map shares.
function GameMap() constructor {
	// ============================
	// Public Functions
	// ============================

	/// @function try_generate()
	/// @description Makes one attempt at generating the map. It randomly determines the map-wide events and the special room
	///	layouts the map must include, and grows the map to one room short of MIN_NUMBER_OF_ROOMS. Then each pass adds a room
	///	and links, places the start and heart, links more rooms for any required layout with no room of its own, reserves a
	///	room for each required layout, picks the guaranteed lit room and gives every room a new layout. Then it places the
	///	chests, locks, special exit types and collectables, determines every room's content, and scores the whole map, until
	///	the score reaches MAP_DIFFICULTY_SCORE_TARGET or the map has MAX_NUMBER_OF_ROOMS rooms. A pass where a required layout
	///	still has no room of its own ends early, and the next pass's new room grows toward it. A failed attempt destroys the map.
	/// @returns {bool} False if the attempt failed, so a new map has to be tried
	static try_generate = function() {
		determine_random_map_events();
		determine_required_layouts();
		if (!grow_map_to_minimum_size()) { return false; }
		if (!grow_map_to_finished_size()) { return false; }
		calculate_time_provided();
		return true;
	};

	// ============================
	// Map Generation Steps
	// ============================

	/// @function determine_random_map_events()
	/// @description Randomly determines what is decided once per map, before any room exists: the map-wide events, the
	///	special room types the map includes, and how many special items spawn outside special rooms
	static determine_random_map_events = function() {
		// Set the Map Shape and Same Skeleton Type Events
		long_and_straight_map = get_random_chance_out_of(SPECIAL_MAP_SHAPE_PROBABILITY); // TODO: Implement this and other shapes. Add eval messages
		same_skeleton_type = get_random_chance_out_of(SAME_SKELETON_TYPE_PROBABILITY) ? get_skeleton_type(false) : noone; // TODO: Add eval messages

		// Randomly determine how many special rooms to include, at most one for each special room type the difficulty allows
		var _special_room_types_left = variable_clone(available_special_room_types, 0), _special_room_count = 0;
		for (var _i = 0; _i < SPECIAL_ROOM_LIMIT; _i++) {
			if (get_random_chance_out_of(SPECIAL_ROOM_PROBABILITY)) { _special_room_count += 1; }
		}
		_special_room_count = min(_special_room_count, array_length(_special_room_types_left));
		
		// Include that many special room types, picked at random
		for (var _i = 0; _i < _special_room_count; _i++) {
			array_push(included_special_room_types, array_random_pop(_special_room_types_left));
		}

		// Randomly determine how many special items spawn outside special rooms. Each special room holds one, which counts toward the limit
		var _other_special_item_count = 0;
		for (var _i = _special_room_count; _i < SPECIAL_ITEM_LIMIT; _i++) {
			if (get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)) { _other_special_item_count += 1; }
		}
		other_special_item_count = _other_special_item_count;
	};

	/// @function determine_required_layouts()
	/// @description Randomly picks the special room layouts the map must include, one of each included special room type, in
	///	the order rooms are reserved for them. The rooms each one can take are among the rooms every later one with the same
	///	exit kind can take, so reserving rooms in this order never takes the only room a later one could use. The guaranteed
	///	lit room isn't one of them, since any room can take a lantern layout of the exit kind it shows.
	static determine_required_layouts = function() {
		// One random layout of each included special room type
		for (var _i = 0; _i < array_length(included_special_room_types); _i++) {
			var _special_room_type = included_special_room_types[_i];
			var _required_layout = { layout: array_random_get(_special_room_type.layouts), special_room_type: _special_room_type };
			// The hall of mirrors goes first, since the fewest rooms can take it; otherwise it is added to the end
			if (_required_layout.layout.has_hall_of_mirrors) { array_insert(required_layouts, 0, _required_layout); }
			else { array_push(required_layouts, _required_layout); }
		}
	};

	/// @function grow_map_to_minimum_size()
	/// @description Creates a new room and grows the map from there to the minimum size
	/// @returns {bool} False if the attempt failed, so a new map has to be tried
	static grow_map_to_minimum_size = function() {
		create_room_at_cell(0, 0);
		while (array_length(rooms) < MIN_NUMBER_OF_ROOMS - 1) {
			if (is_undefined(add_new_room())) { return fail_generation("no room could grow during minimum map size setup"); }
		}
		return true;
	};

	/// @function grow_map_to_finished_size()
	/// @description Adds a room at a time until the map's difficulty score reaches MAP_DIFFICULTY_SCORE_TARGET, or the map has
	///	MAX_NUMBER_OF_ROOMS rooms
	/// @returns {bool} False if the attempt failed, so a new map has to be tried
	static grow_map_to_finished_size = function() {
		var _missing_required_layout = get_next_missing_required_layout(), _map_difficulty_score = 0;
		while (_map_difficulty_score < MAP_DIFFICULTY_SCORE_TARGET) {
			// Add another room
			if (is_undefined(add_new_room(_missing_required_layout))) { return fail_generation("no room could grow during map shaping for required layouts"); }
			
			// Set up the map to deal with the added room
			reset_last_pass();
			link_adjacent_rooms();
			if (!determine_start_and_heart_rooms()) { return fail_generation("the start and heart could not be placed"); }
			
			// Shape map to include missing required layouts, if possible, and continue to adding another room if not, unless the
			// map already has as many rooms as allowed
			_missing_required_layout = link_adjacent_rooms_for_required_layouts();
			if (!is_undefined(_missing_required_layout)) {
				if (array_length(rooms) >= MAX_NUMBER_OF_ROOMS) { return fail_generation("a required layout got no room of its own"); }
				continue;
			}
			
			// Complete the map and score its difficulty. A map with as many rooms as allowed ends here, whatever its score
			set_room_distances_from_start();
			if (!assign_layouts_and_determine_room_content()) { return false; }
			_map_difficulty_score = calculate_map_difficulty_score();
			if (array_length(rooms) >= MAX_NUMBER_OF_ROOMS) { break; }
		}
		return true;
	};

	/// @function get_next_missing_required_layout()
	/// @description The first required layout left with no room of its own to take it.
	/// @returns {struct|undefined} The required layout, as { layout, special_room_type }, or undefined if each one has a room
	static get_next_missing_required_layout = function() {
		// Loop through each required layout
		var _used_rooms = [];
		for (var _i = 0; _i < array_length(required_layouts); _i++) {
			// Get list of rooms that can take this layout. If none can, return this as the missing layout
			var _required_layout = required_layouts[_i];
			var _possible_rooms = get_possible_rooms_for_required_layout(_required_layout, _used_rooms);
			if (array_length(_possible_rooms) == 0) { return _required_layout; }
			// Otherwise, add the first of the returned possible rooms to those taken by this layout
			// Note we re-randomized among all possible rooms later at assign time, so just taking the first here works
			array_push(_used_rooms, _possible_rooms[0]);
		}
		// If no required layout is missing, return undefined
		return undefined;
	};

	/// @function get_possible_rooms_for_required_layout(_required_layout, _used_rooms)
	/// @description The rooms that can take a required layout: rooms that can become its special room, whose real cardinal
	///	exits match its exit kind, since a special room's exits are never misleading
	/// @param {struct} _required_layout The required layout, as { layout, special_room_type }
	/// @param {array} _used_rooms Rooms other required layouts took, which it can't take
	/// @returns {array} The rooms
	static get_possible_rooms_for_required_layout = function(_required_layout, _used_rooms) {
		// Loop through all rooms to find one that can fit this required layout
		var _layout = _required_layout.layout, _possible_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip any rooms that this required layout can't use
			var _room = rooms[_i];
			if (array_contains(_used_rooms, _room) || _room.get_exit_type() != _layout.exit_type || !_room.can_become_special_room(_layout)) { continue; }
			array_push(_possible_rooms, _room);
		}
		return _possible_rooms;
	};

	/// @function reset_last_pass()
	/// @description Resets what the last pass placed, so the next pass can place it again: every room's map roles and spot
	///	objects, every exit's lock or special exit type, and the map's start, heart and guaranteed lit rooms, guaranteed items,
	///	special item types and extra key. The rooms and their exits stay as they are, and the pass gives every room a new layout.
	static reset_last_pass = function() {
		reset_map_variables();
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].reset_map_generation_pass(); }
		for (var _j = 0; _j < array_length(cardinal_exits); _j++) { cardinal_exits[_j].reset_exit_type(); }
	};

	/// @function reset_map_variables()
	/// @description Resets the map-wide variables that are set during each pass
	static reset_map_variables = function() {
		start_room = undefined;
		heart_room = undefined;
		gudetama_room = undefined;
		guaranteed_lit_room = undefined;		// The room that always starts lit, so the map has a lit room, with a lantern layout of the exit kind it shows
		guaranteed_items = [];					// The item types we must spawn somewhere in the map
		spawned_special_items = [];				// Each item type placed as a special item so far
		extra_key_placed = false;				// Whether the first bomb standing in for a key has brought its extra key yet
	};

	/// @function link_adjacent_rooms()
	/// @description Links adjacent rooms with new cardinal exits until the rooms average AVERAGE_NUMBER_OF_ROOM_EXITS
	///	cardinal exits each, stopping early if no more links fit, since the average is only a target
	static link_adjacent_rooms = function() {
		while (2 * array_length(cardinal_exits) / array_length(rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
			if (!add_adjacent_exit()) { return; }
		}
	};

	/// @function determine_start_and_heart_rooms()
	/// @description Makes the start and heart rooms the two ends of the longest route through the map, stairs included,
	///	among the rooms each is allowed to be, and places the cross and the encased heart. They're placed before the links for
	///	missing required layouts, which never shorten the way between them, and before any room gets a layout, so special
	///	layouts keep away from them.
	/// @returns {bool} False if no pair is allowed (never expected, since stairs always leave three rooms that could be either)
	static determine_start_and_heart_rooms = function() {
		var _longest_distance = -1, _longest_pairs = [];
		
		// Loop through every existing room
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Check if this room can be the start room, and continue if not
			var _start_room = rooms[_i];
			if (!_start_room.can_be_start()) { continue; }
			
			// Measure distance to all rooms from this potential start room
			var _distances_from_start = get_distances_from_room(_start_room);
			
			// Loop through every other existing room
			for (var _j = 0; _j < array_length(rooms); _j++) {
				// Check if this room can be the heart room, and continue if not
				var _heart_room = rooms[_j];
				if (!_heart_room.can_be_heart(_start_room)) { continue; }
				
				// If this path is longer than the longest distance, reset the list of possibilities
				var _distance = _distances_from_start[_heart_room.map_rooms_index];
				if (_distance > _longest_distance) {
					_longest_distance = _distance;
					_longest_pairs = [];
				}
				
				// If this path is equal to the longest distance, add it to the list of possibilities
				if (_distance == _longest_distance) { array_push(_longest_pairs, [_start_room, _heart_room]); }
			}
		}
		
		// Return false if no possible paths were found
		if (array_length(_longest_pairs) == 0) {
			// This should NEVER happen
			return false;
		}

		// Otherwise, select a random possible path to use
		var _pair = array_random_get(_longest_pairs);
		
		// Setup start and heart rooms
		start_room = _pair[0];
		start_room.is_start_room = true;
		start_room.set_chest_or_stairs_spot_object(obj_cross);
		heart_room = _pair[1];
		heart_room.is_heart_room = true;
		heart_room.set_chest_or_stairs_spot_object(obj_encased_heart);
		
		// Return success
		return true;
	};

	/// @function link_adjacent_rooms_for_required_layouts()
	/// @description Adds exits between adjacent rooms to try to fit the required layout into the map
	/// @returns {struct|undefined} The required layout that failed to fit, as { layout, special_room_type }, or undefined
	static link_adjacent_rooms_for_required_layouts = function() {
		// Try to fit in the next missing required layout, if one exists
		var _missing_required_layout = get_next_missing_required_layout();
		// If a missing required layout still exists and we can still add exits for it, add exits and check for a missing layout again
		var _can_add_adjacent_exits = true;
		while (!is_undefined(_missing_required_layout) && _can_add_adjacent_exits) {
			_can_add_adjacent_exits = add_adjacent_exit(_missing_required_layout);
			_missing_required_layout = get_next_missing_required_layout();
		}
		
		// Return whatever the last next missing required layout is, or undefined if there is none
		return _missing_required_layout;
	};

	/// @function set_room_distances_from_start()
	/// @description Sets every room's distance from the start, once the pass's links are final
	static set_room_distances_from_start = function() {
		var _distances_from_start = get_distances_from_room(start_room);
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			_room.distance_to_start = _distances_from_start[_room.map_rooms_index];
		}
	};

	/// @function assign_layouts_and_determine_room_content()
	/// @description Finishes the map by assigning layouts and room contents
	/// @returns {bool} False if the lock and key generation fails, so a new map has to be tried
	static assign_layouts_and_determine_room_content = function() {
		reserve_rooms_for_required_layouts();
		reserve_room_guaranteed_lit_room();
		assign_room_layouts();
		create_chests();
		if (!create_locked_exits_and_keys()) { return fail_generation("lock and key generation failed"); }
		determine_special_exit_types();
		determine_collectables_rooms();
		determine_room_contents();
		calculate_hazard_mitigations();
		return true;
	};

	// ============================
	// Assign Layout Functions
	// ============================

	/// @function reserve_rooms_for_required_layouts()
	/// @description Reserves a random room for each required layout, among the rooms it can take that no earlier one took.
	///	Only called once no required layout is missing, so each one always gets a room.
	static reserve_rooms_for_required_layouts = function() {
		var _reserved_rooms = [];
		for (var _i = 0; _i < array_length(required_layouts); _i++) {
			var _room = array_random_get(get_possible_rooms_for_required_layout(required_layouts[_i], _reserved_rooms));
			_room.required_layout = required_layouts[_i];
			array_push(_reserved_rooms, _room);
		}
	};

	/// @function reserve_room_guaranteed_lit_room()
	/// @description Picks a random room no required layout reserved as the guaranteed lit room
	static reserve_room_guaranteed_lit_room = function() {
		// Any room that isn't reserved for a required layout can be the guaranteed lit room, since every exit kind has lantern layouts
		// Note we will filter by the layouts that have lanterns later, when the layouts are assigned
		var _possible_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _possible_room = rooms[_i];
			if (is_undefined(_possible_room.required_layout)) { array_push(_possible_rooms, _possible_room); }
		}
		guaranteed_lit_room = array_random_get(_possible_rooms);
	};

	/// @function assign_room_layouts()
	/// @description Gives every room a new layout, with a random orientation and lighting: each reserved room its required
	///	layout first, then the guaranteed lit room a lantern layout of the exit kind it shows, then every other room, in
	///	random order, a layout of the exit kind it shows, each usually one of the least used. The exit kind a room shows
	///	differs from its real one when its exits are misleading, which the guaranteed lit room's can be too.
	static assign_room_layouts = function() {
		// Keep track of how often each layout is used to minimize duplicates
		layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

		// Assign layouts to reserved rooms first
		var _unreserved_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i], _required_layout = _room.required_layout;
			// Assign the reserved layout now, if room has one
			if (!is_undefined(_required_layout)) {
				var _layout = _required_layout.layout, _special_room_type = _required_layout.special_room_type;
				assign_layout_to_room(_room, _layout, _special_room_type);
				if (_special_room_type.name == "sloth") { gudetama_room = _room; }
				
			}
			// If the room is not the guaranteed lit room, add it to the list of unreserved rooms
			else if (_room != guaranteed_lit_room) { array_push(_unreserved_rooms, _room); }
		}
		
		// Assign the reserved guaranteed lit room its layout
		var _lantern_layouts = get_only_lantern_layouts(layouts_by_exit_type[guaranteed_lit_room.determine_layout_exit_type()]);
		var _chosen_layout = choose_regular_room_layout(_lantern_layouts);
		assign_layout_to_room(guaranteed_lit_room, _chosen_layout);

		// Then give every other room the least used layout of the exit kind it shows
		_unreserved_rooms = array_shuffle(_unreserved_rooms);
		for (var _j = 0; _j < array_length(_unreserved_rooms); _j++) {
			var _unreserved_room = _unreserved_rooms[_j];
			var _possible_layouts = layouts_by_exit_type[_unreserved_room.determine_layout_exit_type()];
			var _chosen_layout = choose_regular_room_layout(_possible_layouts);
			assign_layout_to_room(_unreserved_room, _chosen_layout);
		}
	};

	/// @function assign_layout_to_room(_room, _layout, _special_room_type)
	/// @description Gives a room a layout and counts it as used, then randomly determines the room's orientation and lighting.
	///	The guaranteed lit room always starts lit.
	/// @param {GameRoom} _room The room
	/// @param {RoomLayout} _layout The layout
	/// @param {SpecialRoomType|undefined} _special_room_type The special room type the layout belongs to, or undefined for a regular layout
	static assign_layout_to_room = function(_room, _layout, _special_room_type = undefined) {
		// Count the layout as used, assign it to the room, and determine its orientation and lighting
		layout_use_counts[_layout.layout_cache_index] += 1;
		_room.assign_layout(_layout, _special_room_type, _room == guaranteed_lit_room);
		_room.determine_layout_orientation();
		_room.determine_lighting();
	};

	/// @function choose_regular_room_layout(_possible_layouts)
	/// @description Picks a random layout among the ones that fit and have been used the least, or sometimes the most, which
	///	repeats a layout on purpose
	/// @param {array} _possible_layouts The layouts that fit
	/// @returns {RoomLayout} The layout
	static choose_regular_room_layout = function(_possible_layouts) {
		// Randomly decide to use duplicate layouts sometimes
		var _choose_duplicate_layout = get_random_chance_out_of(DUPLICATE_LAYOUT_DURING_ASSIGNMENT_PROBABILITY);
		var _target_use_count = 0, _target_layouts = [];
		// Find the maximum layout count to duplicate
		if (_choose_duplicate_layout) {
			for (var _i = 0; _i < array_length(_possible_layouts); _i++) {
				var _possible_layout = _possible_layouts[_i];
				_target_use_count = max(_target_use_count, layout_use_counts[_possible_layout.layout_cache_index]);
			}
		}
		
		// Find a layout that closely matches the target
		do {
			_target_layouts = [];
			for (var _i = 0; _i < array_length(_possible_layouts); _i++) {
				var _possible_layout = _possible_layouts[_i];
				if (layout_use_counts[_possible_layout.layout_cache_index] == _target_use_count) { array_push(_target_layouts, _possible_layout); }
			}
			_target_use_count += (_choose_duplicate_layout) ? -1 : 1;
		}
		until (array_length(_target_layouts) > 0);
		
		return array_random_get(_target_layouts);
	};

	// ============================
	// Create Chest Functions
	// ============================

	/// @function create_chests()
	/// @description Creates and assigns all the chests and their contents: each special room's own chest, a locked chest for
	///	each other special item, then the guaranteed items, and random chests, some hidden, some locked and some traps
	static create_chests = function() {
		// Create each special room's chest and assign its content, a random special item type.
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms that aren't special rooms
			var _special_room = rooms[_i];
			if (!_special_room.is_special_room) { continue; }

			// Assign chest content to be a random special item type
			_special_room.add_special_room_chest();
			_special_room.chest_content_object_type = pick_item_type(true);
		}

		// Create and Assign Special Chest Content for the special items outside the special rooms
		var _possible_rooms = array_shuffle(rooms), _special_items_left = other_special_item_count;
		for (var _i = 0; _i < array_length(_possible_rooms) && _special_items_left > 0; _i++) {
			// Skip rooms that can't have a chest with a special item
			var _special_item_room = _possible_rooms[_i];
			if (!_special_item_room.can_have_special_item()) { continue; }
			
			// Assign chest content to be a random special item type
			_special_item_room.has_special_item = true;
			_special_item_room.has_locked_chest = true;
			_special_item_room.add_hidden_or_regular_chest();
			_special_item_room.chest_content_object_type = pick_item_type(true);
			_special_items_left -= 1;
		}
		
		if (_special_items_left > 0) {
			// This should NEVER happen, due to the smallest minimum map size leaving room
			write_debug_message("No room left for " + string(_special_items_left) + " special item(s).", debug_message_level.warning);
		}
		
		// Determine the guaranteed items: a torch, a map or compass, and an item that gets the player past the gudetama when the map needs one
		var _map_item = (global.difficulty == difficulties.easy || get_coin_flip()) ? obj_map : obj_compass;
		var _gudetama_item = get_coin_flip() ? obj_sword : obj_bomb;
		guaranteed_items = [];
		array_push(guaranteed_items, obj_torch); // Guarantee at least one torch; replaced later if torch is in hand
		array_push(guaranteed_items, _map_item); // Guarantee at least one map item; replaced later if it is in hand
		if (map_needs_gudetama_item()) { array_push(guaranteed_items, _gudetama_item); } // Guarantee at least one item that can defeat the gudetama
		
		// Create and assign regular chests, including guaranteed items, to roomsin a random order
		_possible_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			// Skip rooms that can't have a chest
			var _regular_chest_room = _possible_rooms[_i];
			if (!_regular_chest_room.can_have_chest()) { continue; }
			
			// Create Guaranteed Item Chests first, then random chests after that
			var _guaranteed_chest = (array_length(guaranteed_items) > 0), _create_chest = (_guaranteed_chest || get_random_chance_out_of(CHEST_PROBABILITY));
			if (_create_chest) {
				if (_guaranteed_chest) {
					var _guaranteed_item = array_random_pop(guaranteed_items);
					_regular_chest_room.has_guaranteed_item = true;
					_regular_chest_room.chest_content_object_type = _guaranteed_item;
					// A guaranteed chest can be locked, and it can be hidden, except the torch's
					_regular_chest_room.has_locked_chest = get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
					if (_guaranteed_item == obj_torch) { _regular_chest_room.set_chest_or_stairs_spot_object(obj_chest); }
					else { _regular_chest_room.add_hidden_or_regular_chest(); }
				}
				else {
					// Create a random chest, which can be hidden or locked
					_regular_chest_room.add_hidden_or_regular_chest();
					_regular_chest_room.has_locked_chest = get_random_chance_out_of(LOCKED_CHEST_PROBABILITY);
					
					// Trap random unlocked chests. A fountain shoots at the player, so a room whose layout has eyes only gets the statue trap
					var _chest_content = undefined;
					if (_regular_chest_room.has_basic_chest() && get_random_chance_out_of(TRAP_CHEST_PROBABILITY) && !_regular_chest_room.would_exceed_max_difficulty("obj_chest")) { 
						_chest_content = (_regular_chest_room.get_object_count_from_layout("obj_eyes") == 0 && get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) ? obj_fountain : obj_statue;
					}
					
					// Assign random item to chest if it is not trapped
					_regular_chest_room.chest_content_object_type = _chest_content ?? pick_item_type(false);
				}
			}
		}
		
		// Check that all guaranteed chests were spawned
		for (var _i = 0; _i < array_length(guaranteed_items); _i++) {
			// This should NEVER happen, due to the smallest minimum map size leaving room
			write_debug_message("No room left for " + object_get_name(guaranteed_items[_i]) + " guaranteed item.", debug_message_level.warning);
		}
	};

	/// @function pick_item_type(_is_special_item, [_items_in_hands], [_can_be_key])
	/// @description Picks an item type at random among the types still allowed. A special item can be any type the
	///	difficulty allows, keys included, that hasn't been used as a special item yet. A regular item is only a key when
	///	the flag is passed in, and never a type at its cap, counting the chests, what the blocks hide, and the starting hand items.
	/// @param {bool} _is_special_item Whether the item is a special item
	/// @param {bool} [_can_be_key] Whether a regular item can be a key (false by default)
	/// @param {array} [_items_in_hands] The starting hand items to count ([] by default, to ignore the hands)
	/// @returns {Asset.GMObject}
	static pick_item_type = function(_is_special_item, _can_be_key = false, _items_in_hands = []) {
		// Loop through all possible item types to see which are still possible to spawn
		var _available_item_types = global.available_items[global.difficulty], _possible_item_types = [];
		for (var _i = 0; _i < array_length(_available_item_types); _i++) {
			var _item_type = _available_item_types[_i];
			if (_is_special_item) {
				// Add any type that isn't a special item yet to the list of possibilities
				if (!array_contains(spawned_special_items, _item_type)) { array_push(_possible_item_types, _item_type); }
			}
			else if ((_can_be_key || _item_type != obj_key) && count_spawned_regular_items(_item_type, _items_in_hands) < get_item_cap(_item_type)) {
				// Add any type that isn't at its cap yet to the list of possibilities, the key only when it can be one
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
		var _chosen_item_type = array_random_get(_possible_item_types);
		if (_is_special_item) { array_push(spawned_special_items, _chosen_item_type); }
		return _chosen_item_type;
	};

	/// @function count_spawned_regular_items(_item_type, _hands)
	/// @description Counts the regular copies of an item type in the map's spawned items. The keys and bombs placed for the locks don't count.
	/// @param {Asset.GMObject} _item_type The item type
	/// @param {array} _hands The starting hand items to count
	/// @returns {real}
	static count_spawned_regular_items = function(_item_type, _hands) {
		// Loop through all rooms and count the regular items of this type
		var _count = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Count it if the chest holds the type, and it's neither a special item nor a key or bomb placed for the locks
			var _room = rooms[_i];
			if (_room.chest_content_object_type == _item_type && !_room.has_special_item && !_room.has_chest_key) { _count += 1; }
		}
		
		// Add the regular items of this type the blocks hide
		_count += array_count_occurrences(regular_items_under_blocks, _item_type);
		
		// Loop through the given hand items and add those item types to the count
		for (var _i = 0; _i < array_length(_hands); _i++) {
			if (_hands[_i] == _item_type) { _count += 1; }
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
				return (global.difficulty < difficulties.very_hard) ? 1 : 2;
			case obj_torch:
				return 3;
			default:
				// bombs
				// meat
				// swords
				// rosaries
				// keys
				return infinity;
		}
	};

	/// @function map_needs_gudetama_item()
	/// @description Returns whether we need to spawn an item that can kill a gudetama or not: the map has a gudetama
	/// @returns {bool} True if an item is needed, false otherwise
	static map_needs_gudetama_item = function() {
		// Find the room with the gudetama, if the map has one. Return false if it doesn't;
		if (is_undefined(gudetama_room)) { return false; }

		// Find a chest in another room that already holds a gudetama item, and return false if one is found
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (_room == gudetama_room) { continue; }
			if (_room.has_gudetama_item()) { return false; }
		}

		// Otherwise, return true to ensure an item is spawned
		return true;
	};

	// ============================
	// Lock and Key Search Functions
	// ============================

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

	/// @function get_relevant_locked_chest_rooms()
	/// @description Gets a list of all rooms with a relevant locked chest in the map: one that holds a special key or bomb,
	///	a torch, or a special sword or staff that can get the player past the map's gudetama to the chest behind it
	/// @returns {array} The list of relevant locked chest rooms
	static get_relevant_locked_chest_rooms = function() {
		// Loop through every map room to find relevant locked chests
		var _relevant_locked_chest_rooms = [], _gudetama_room = gudetama_room;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms with unlocked chests
			var _room = rooms[_i];
			if (!_room.has_locked_chest) { continue; }
			
			// Check if room is relevant
			var _holds_special_key = (_room.chest_content_object_type == obj_key && _room.has_special_item);
			var _holds_special_bomb = (_room.chest_content_object_type == obj_bomb && _room.has_special_item);
			var _holds_needed_torch = (_room.chest_content_object_type == obj_torch);
			var _holds_gudetama_item = (!is_undefined(_gudetama_room) && _room != _gudetama_room && _room.has_special_item && (_room.chest_content_object_type == obj_sword || _room.chest_content_object_type == obj_staff));
			
			// Reset the chest index, then add the chest if it is relevant and assign its new index
			_room.relevant_locked_chests_index = -1;
			if (_holds_special_key || _holds_needed_torch || _holds_special_bomb || _holds_gudetama_item) {
				_room.relevant_locked_chests_index = array_length(_relevant_locked_chest_rooms);
				array_push(_relevant_locked_chest_rooms, _room);
			}
		}
		return _relevant_locked_chest_rooms;
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

	/// @function add_key_to_area(_stuck_area)
	/// @description Adds a key to a random room of the stuck search area that can hold one: on its floor, where building
	///	picks the collectable spot, or sometimes in a new chest, where a bomb can stand in for the key if the area lets the
	///	player light bombs
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
			_room.has_chest_key = true;
			_room.set_chest_or_stairs_spot_object(obj_chest);
			_key_is_bomb = _stuck_area.can_use_bombs_as_keys() && get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY);
			_room.chest_content_object_type = _key_is_bomb ? obj_bomb : obj_key;
		}
		_room.has_key = true;

		// The first bomb standing in for a key on the map also brings an extra key to the same area
		if (_key_is_bomb && !extra_key_placed) { add_extra_key_to_area(_stuck_area); }

		// Return true for successful key placement
		return true;
	};

	/// @function add_extra_key_to_area(_stuck_area)
	/// @description Puts an extra key on the floor of a random room in a search area, for the first bomb that stands in
	///	for a key there. The room's has_key stays as it is, so the lock search never counts the extra key: it's a spare
	///	on top of the keys and bombs the locks need.
	/// @param {LockSearchArea} _stuck_area The search area the bomb went to
	static add_extra_key_to_area = function(_stuck_area) {
		// Rooms in the area with no key on their floor yet, which the bomb's own room always is
		var _possible_rooms = [];
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _possible_room = rooms[_i];
			if (!_stuck_area.is_room_reached(_possible_room)) { continue; }

			if (!_possible_room.is_heart_room && !_possible_room.has_floor_key() && array_length(_possible_room.layout.key_spots) > 0) { array_push(_possible_rooms, _possible_room); }
		}
		if (array_length(_possible_rooms) == 0) {
			// This should NEVER happen, since the bomb's own room always has a free key spot
			write_debug_message("No room could take the extra key a bomb brings.", debug_message_level.warning);
			return;
		}

		// Put the extra key on the floor of a random one of them, where building picks its collectable spot
		var _room = array_random_get(_possible_rooms);
		_room.has_extra_key = true;
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

	// ============================
	// Room Content Functions
	// ============================

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
	///	portcullis button leave a collectable spot free.
	static determine_collectables_rooms = function() {
		var _possible_rooms = array_shuffle(rooms), _collectables_rooms = 1;
		heart_room.has_collectables = true; // The heart room never has a key or a button

		// Add collectables to heart room and other rooms at random
		for (var _i = 0; _i < array_length(_possible_rooms); _i++) {
			var _possible_room = _possible_rooms[_i];
			if (!_possible_room.is_start_room && !_possible_room.is_heart_room && get_random_chance_out_of(COLLECTABLE_PROBABILITY) && _possible_room.can_have_collectables()) {
				_possible_room.has_collectables = true;
				_collectables_rooms += 1;
			}
		}

		// Add to more random rooms to meet the minimum if needed
		var _minimum_collectable_rooms = ceil(array_length(rooms) / 4) + 1;
		for (var _j = 0; _j < array_length(_possible_rooms) && _collectables_rooms < _minimum_collectable_rooms; _j++) {
			var _extra_room = _possible_rooms[_j];
			if (!_extra_room.is_start_room && !_extra_room.has_collectables && _extra_room.can_have_collectables()) {
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

	// ============================
	// Helper Functions - Used at Multiple Map Generation Steps
	// ============================

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

	/// @function get_distances_from_room(_from_room)
	/// @description Counts how many exits the player goes through from one room to every other, by the quickest route
	///	through cardinal exits and stairs, ignoring locks
	/// @param {GameRoom} _from_room The room to measure from
	/// @returns {array} An array where the index is the room's map rooms index and the value is its distance from this room
	static get_distances_from_room = function(_from_room) {
		var _distances = array_create(array_length(rooms), -1);
		var _rooms_to_visit = [_from_room];
		_distances[_from_room.map_rooms_index] = 0;
		for (var _i = 0; _i < array_length(_rooms_to_visit); _i++) {
			var _room = _rooms_to_visit[_i];
			
			// Check each exit direction, including stairs, for rooms to measure
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				// Skip rooms that were already measured earlier or don't have an exit
				var _other_room = _room.get_connected_room(_dir);
				if (_other_room == -1 || _distances[_other_room.map_rooms_index] != -1) { continue; }
				// Set the distance value equal to the current distance plus 1 and mark it measured
				_distances[_other_room.map_rooms_index] = _distances[_room.map_rooms_index] + 1;
				array_push(_rooms_to_visit, _other_room);
			}
		}
		return _distances;
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
		var _new_exit_type_counts = variable_clone(_exit_type_counts, 0);
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
	/// @description Whether a new cardinal exit would let one of its rooms take a required layout, by giving it the layout's
	///	exit kind, so that more rooms have that kind than before
	/// @param {struct} _required_layout The required layout, as { layout, special_room_type }
	/// @param {array} _exit_type_counts Room counts by exit kind now
	/// @param {array} _new_exit_type_counts Room counts by exit kind with the new exit
	/// @param {GameRoom} _room The room that gains the exit
	/// @param {real} _dir The exit's direction from the room
	/// @param {GameRoom|undefined} _other_room The adjacent room it links to, or undefined for a new room, which has one exit
	/// @returns {bool}
	static would_link_fit_required_layout = function(_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, _other_room) {
		// The exit kind has to gain a room overall: a dead end that a new dead end grows from stops being one itself. A new room
		// can't take a special layout beside the start or heart room
		var _layout = _required_layout.layout;
		var _other_room_fits = is_undefined(_other_room) ? (_layout.exit_type == layout_exit_types.one && !_room.is_start_room && !_room.is_heart_room) : _other_room.would_fit_layout_with_new_exit(get_opposite_dir(_dir), _layout, _room);
		var _adds_room_of_exit_type = (_new_exit_type_counts[_layout.exit_type] > _exit_type_counts[_layout.exit_type]);
		return (_room.would_fit_layout_with_new_exit(_dir, _layout, _other_room) || _other_room_fits) && _adds_room_of_exit_type;
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
	/// @description How far room counts by exit kind are from exit_type_targets: for each kind, its count minus its share of the
	///	rooms with cardinal exits, squared, all added up. Rooms with no cardinal exits are left out, since stairs decide those.
	/// @param {array} _exit_type_counts Room counts by exit kind
	/// @returns {real}
	static get_exit_mix_deficit = function(_exit_type_counts) {
		// Add up the mix's weights and the rooms with cardinal exits
		var _mix_total = 0, _room_count = 0;
		for (var _type = layout_exit_types.one; _type < layout_exit_types.count; _type++) {
			_mix_total += exit_type_targets[_type];
			_room_count += _exit_type_counts[_type];
		}
		
		// Add up how far each exit kind's count is from its share
		var _deficit = 0;
		for (var _type = layout_exit_types.one; _type < layout_exit_types.count; _type++) {
			_deficit += sqr(_exit_type_counts[_type] - _room_count * exit_type_targets[_type] / _mix_total);
		}
		return _deficit;
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

	/// @function destroy()
	/// @description Frees every room's path grids. Only for a map that will never be played, like a failed
	///	attempt; the controller frees a played map's rooms itself.
	static destroy = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) { rooms[_i].destroy(); }
	};

	// ============================
	// Adjacent Exit Creation Functions - Used to add new links between existing adjacent rooms during map generation
	// ============================

	/// @function add_adjacent_exit([_required_layout])
	/// @description Links a room to an adjacent room it isn't linked to yet, where that brings the rooms' exit kinds closest to
	///	exit_type_targets, but never where it takes a room a required layout needs. For a required layout no room can take, only
	///	a link that lets one of its rooms take that layout counts, and since the start and heart are placed by then, never one
	///	that shortens the way between them, which also keeps the heart from being linked to the start.
	/// @param {struct} [_required_layout] The required layout, as { layout, special_room_type } (undefined by default, for any link)
	/// @returns {bool} False if no link fits
	static add_adjacent_exit = function(_required_layout = undefined) {
		// Find the links that fit the required layout, if one is given, and bring the rooms' exit kinds closest to exit_type_targets
		var _exit_type_counts = get_exit_type_counts(), _best_links = [], _best_deficit = infinity;
		var _distances_from_start = is_undefined(_required_layout) ? [] : get_distances_from_room(start_room);
		var _distances_from_heart = is_undefined(_required_layout) ? [] : get_distances_from_room(heart_room);
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (!_room.can_gain_exits()) { continue; }
		
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				// Skip sides that already have an exit, or have no adjacent room that can gain exits
				if (_room.has_exit(_dir)) { continue; }
				var _adjacent_room = get_adjacent_room(_room, _dir);
				if (is_undefined(_adjacent_room) || !_adjacent_room.can_gain_exits()) { continue; }

				// Skip links that take a room a required layout needs, or don't fit the required layout, or shorten the way from
				// the start to the heart
				var _new_exit_type_counts = get_exit_type_counts_after_link(_exit_type_counts, _room, _dir, _adjacent_room);
				if (!keeps_rooms_for_required_layouts(_exit_type_counts, _new_exit_type_counts)) { continue; }
				if (!is_undefined(_required_layout)) {
					if (!would_link_fit_required_layout(_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, _adjacent_room)) { continue; }
					if (would_link_shorten_way_to_heart(_distances_from_start, _distances_from_heart, _room, _adjacent_room)) { continue; }
				}

				// Keep the links closest to exit_type_targets
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

	/// @function would_link_shorten_way_to_heart(_distances_from_start, _distances_from_heart, _room, _other_room)
	/// @description Whether a new cardinal exit between two rooms would make the way from the start to the heart shorter
	/// @param {array} _distances_from_start Each room's distance from the start, by map_rooms_index
	/// @param {array} _distances_from_heart Each room's distance from the heart, by map_rooms_index
	/// @param {GameRoom} _room One room the exit joins
	/// @param {GameRoom} _other_room The other room it joins
	/// @returns {bool}
	static would_link_shorten_way_to_heart = function(_distances_from_start, _distances_from_heart, _room, _other_room) {
		var _room_index = _room.map_rooms_index, _other_room_index = _other_room.map_rooms_index;
		var _way_through_link = 1 + min(_distances_from_start[_room_index] + _distances_from_heart[_other_room_index], _distances_from_start[_other_room_index] + _distances_from_heart[_room_index]);
		return _way_through_link < _distances_from_start[heart_room.map_rooms_index];
	};

	// ============================
	// Room Creation Functions - Used to add new rooms to the map during generation
	// ============================

	/// @function add_new_room([_missing_required_layout])
	/// @description Adds one room to the map. A required layout with no exits that no room could take last pass gets a new
	///	room only reached by stairs. Otherwise, the new room is sometimes joined to a random room by stairs, and otherwise by a
	///	cardinal exit, where it brings the rooms' exit kinds closest to exit_type_targets. When a required layout had no room of its
	///	own last pass, the new room is never joined by stairs at random, and a place that gives a room its exit kind comes first.
	/// @param {struct} [_missing_required_layout] The required layout no room could take last pass, as { layout, special_room_type }, to grow toward (undefined by default)
	/// @returns {GameRoom|undefined} The new room, or undefined if no room can grow
	static add_new_room = function(_missing_required_layout = undefined) {
		// Stairs never take one of the last three rooms that could be the start or heart, since neither has stairs. No three
		// cells of the grid are all beside each other, so two of those rooms are never linked, and can always be the start and heart
		var _stairs_allowed = (count_possible_starts() > 3);

		// A required layout with no exits needs a new room only reached by stairs
		if (_stairs_allowed && !is_undefined(_missing_required_layout) && _missing_required_layout.layout.exit_type == layout_exit_types.none) {
			var _stairs_only_room = add_stairs_room(true);
			if (!is_undefined(_stairs_only_room)) { return _stairs_only_room; }
		}

		// Otherwise, unless the new room has to grow toward a missing required layout, sometimes join it by stairs, and sometimes
		// it can only ever be reached by stairs
		if (_stairs_allowed && is_undefined(_missing_required_layout) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			var _stairs_room = add_stairs_room(get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY));
			if (!is_undefined(_stairs_room)) { return _stairs_room; }
		}

		// Otherwise, find the free cells beside rooms that can gain exits where a new room gives a room the missing required
		// layout's exit kind, if any do, and brings the rooms' exit kinds closest to exit_type_targets
		var _exit_type_counts = get_exit_type_counts(), _best_places = [], _best_fits_missing_layout = false, _best_deficit = infinity;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			if (!_room.can_gain_exits()) { continue; }

			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				// Skip sides whose cell is taken
				if (!is_undefined(get_adjacent_room(_room, _dir))) { continue; }

				// Keep the places that fit the missing required layout without taking a room another one needs, if any do, then the
				// ones closest to exit_type_targets
				var _new_exit_type_counts = get_exit_type_counts_after_link(_exit_type_counts, _room, _dir, undefined);
				var _fits_missing_layout = !is_undefined(_missing_required_layout) && would_link_fit_required_layout(_missing_required_layout, _exit_type_counts, _new_exit_type_counts, _room, _dir, undefined)
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

	/// @function add_stairs_room(_is_stairs_only)
	/// @description Adds a room joined by stairs to a random room without stairs, on a free cell beside another room but not
	///	beside that one
	/// @param {bool} _is_stairs_only Whether the new room can only ever be reached by stairs
	/// @returns {GameRoom|undefined} The new room, or undefined if no room can take stairs
	static add_stairs_room = function(_is_stairs_only) {
		var _existing_rooms = array_shuffle(rooms);
		for (var _i = 0; _i < array_length(_existing_rooms); _i++) {
			// Skip rooms that already have stairs
			var _room = _existing_rooms[_i];
			if (_room.has_exit(directions.stairs)) { continue; }
			
			// Skip rooms that have no free cell to add to
			var _cell = find_unoccupied_non_adjacent_cell(_room);
			if (is_undefined(_cell)) { continue; }

			// Create the new room in that cell, and link it to this room with stairs
			var _new_room = create_room_at_cell(_cell[0], _cell[1]);
			link_rooms_with_new_exit(_room, _new_room, directions.stairs);
			_new_room.has_no_cardinal_exits = _is_stairs_only;
			_new_room.stairs_spot_object_type = obj_stairs;
			_room.stairs_spot_object_type = obj_stairs;
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

	// ============================
	// Difficulty Score Calculation Functions
	// ============================

	/// @function calculate_hazard_mitigations()
	/// @description Determines how likely a player is to have an item (or encounter a lit room) for the difficulty scoring.
	///	The starting hand items are left out, so the map never depends on them.
	static calculate_hazard_mitigations = function() {
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
			if (!_room.has_chest() || _room.chest_content_object_type != _item || _room.has_chest_key) { continue; }
			
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
	/// @description Scores every room and returns their total
	/// @returns {real}
	static calculate_map_difficulty_score = function() {
		var _difficulty_score = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];

			_room.room_difficulty_score = _room.get_current_difficulty_score();
			_difficulty_score += _room.room_difficulty_score;
		}
		return _difficulty_score;
	};

	// ============================
	// Time Provided Calculation Functions
	// ============================

	/// @function calculate_time_provided()
	/// @description Sets time_provided, the run's calculated needed time, multiplied by a difficulty multiplier
	static calculate_time_provided = function() {
		time_provided = TIME_DIFFICULTY_MULTIPLIER * get_time_needed();
	};

	/// @function get_time_needed()
	/// @description Seconds a careful novice needs for the map: every room's first visit, getting through its locked doors and
	///	illusion walls, the wrath quest's trip to the start cross and back, and carrying the heart back to the start cross
	/// @returns {real}
	static get_time_needed = function() {
		// Sum the time needed for each individual room, plus the trip to the start and back for the wrath case
		var _time_needed = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			_time_needed += _room.get_time_needed();
			if (_room.is_wrath_room()) { _time_needed += 2 * get_trip_to_start_time(_room); }
		}
		
		// Sum the time needed for each individual exit
		for (var _i = 0; _i < array_length(cardinal_exits); _i++) {
			var _exit_type = cardinal_exits[_i].exit_type;
			if (_exit_type == exit_types.locked_doors) { _time_needed += LOCKED_DOOR_TIME; }
			else if (_exit_type == exit_types.illusion_walls) { _time_needed += ILLUSION_WALL_TIME; }
		}
		
		// Return the sum plus the trip time back to the start from the heart room
		return _time_needed + get_trip_to_start_time(heart_room);
	};

	/// @function get_trip_to_start_time(_from_room)
	/// @description Seconds to walk from the given room to the start cross by the quickest way, crossing each room on the way again
	/// @param {GameRoom} _from_room The room the trip starts from
	/// @returns {real} The total time of each room passed through along this path
	static get_trip_to_start_time = function(_from_room) {
		// Start at the given room
		var _room = _from_room, _trip_time = 0;
		while (_room.distance_to_start > 0) {
			// Find which exit leads us closer to the start room by the shortest path, including stairs
			var _closer_rooms = [], _distance_saved = 0;
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				var _linked_room = _room.get_connected_room(_dir);
				if (_linked_room == -1) { continue; }
				
				var _distance_saved_by_linked_room = _room.distance_to_start - _linked_room.distance_to_start;
				if (_distance_saved_by_linked_room > _distance_saved) { _distance_saved = _distance_saved_by_linked_room; _closer_rooms = []; }
				if (_distance_saved_by_linked_room == _distance_saved) { array_push(_closer_rooms, _linked_room); }
			}
			_room = array_random_get(_closer_rooms);
			_trip_time += _room.get_trip_time();
		}
		return _trip_time;
	};

	// ============================
	// Completed Map Functions
	// ============================

	/// @function adjust_items_for_hands()
	/// @description Fits the chests to the player's starting hand items, once the map is final. A guaranteed map or compass
	///	the hands hold becomes the other one, or a random regular item when the hands hold both or the difficulty has no
	///	other one. The guaranteed torch becomes a random regular item when the hands hold a torch, and the gudetama item
	///	does when they hold a sword or bomb. Then any other regular item the hands take past its cap becomes a random one
	static adjust_items_for_hands = function() {
		// Setup variables based on the items the player chose to start with
		var _hand_items = [global.player_left_hand_item, global.player_right_hand_item];
		var _torch_in_hand = array_contains(_hand_items, obj_torch), _gudetama_item_in_hand = array_contains(_hand_items, obj_sword) || array_contains(_hand_items, obj_bomb);
		
		// Loop through each room to determine if it has a guaranteed item that needs replaced
		for (var _i = 0; _i < array_length(rooms); _i++) {
			// Skip rooms without guaranteed items
			var _guaranteed_item_room = rooms[_i];
			if (!_guaranteed_item_room.has_guaranteed_item) { continue; }
			
			// Work out whether the hands make the guaranteed item redundant, and what replaces it
			var _guaranteed_item = _guaranteed_item_room.chest_content_object_type, _replacement_item = _guaranteed_item, _pick_random_item = false;
			switch (_guaranteed_item) {
				case obj_map:
				case obj_compass: {
					// Don't replace unless the item type is in the hands
					if (!array_contains(_hand_items, _guaranteed_item)) { break; }
					
					// Replace one map item with the other, if both are available and the other is missing from the hands
					var _other_map_item = (_guaranteed_item == obj_map) ? obj_compass : obj_map;
					if (!array_contains(_hand_items, _other_map_item) && array_contains(global.available_items[global.difficulty], _other_map_item)) { _replacement_item = _other_map_item; }
					// Otherwise, pick a random item to replace it
					else { _pick_random_item = true; }
					break;
				}
				case obj_torch: {
					_pick_random_item = _torch_in_hand;
					break;
				}
				case obj_bomb:
				case obj_sword: {
					_pick_random_item = _gudetama_item_in_hand;
					break;
				}
			}
			
			// Empty the chest before picking a random regular item, so the pick doesn't count the item it's replacing
			if (_pick_random_item) {
				_guaranteed_item_room.chest_content_object_type = -1;
				_replacement_item = pick_item_type(false, _hand_items);
			}
			_guaranteed_item_room.chest_content_object_type = _replacement_item;
		}
		
		// Loop through each room again, in a random order, to re-pick any other regular items that the hands take past its cap
		var _existing_rooms = array_shuffle(rooms);
		for (var _j = 0; _j < array_length(_existing_rooms); _j++) {
			// Skip the guaranteed items, which already fit the hands, and chests without a regular item
			var _room = _existing_rooms[_j];
			if (_room.has_guaranteed_item || !_room.has_regular_item_chest()) { continue; }
			
			// Empty the chest before picking, so the pick doesn't count the item it's replacing
			if (count_spawned_regular_items(_room.chest_content_object_type, _hand_items) > get_item_cap(_room.chest_content_object_type)) {
				_room.chest_content_object_type = -1;
				_room.chest_content_object_type = pick_item_type(false, _hand_items);
			}
		}
	};

	/// @function calculate_collectables_and_items_lists()
	/// @description Lists what the controller tracks during play: the rooms with collectables, and the regular items in chests.
	///	The special items are already listed, since each one is listed as it's picked.
	static calculate_collectables_and_items_lists = function() {
		for (var _i = 0; _i < array_length(rooms); _i++) {
			var _room = rooms[_i];
			
			// Calculate collectables list
			if (_room.has_collectables) { array_push(rooms_with_collectables, _room); }
			
			// Calculate the regular items list
			if (_room.has_chest() && !_room.has_trap_chest() && !_room.has_special_item) { array_push(spawned_items, _room.chest_content_object_type); }
		}
	};

	// ============================
	// Instance Variables
	// ============================

	// The four directions a cardinal exit can face
	static cardinal_exit_directions = [directions.up, directions.right, directions.down, directions.left];

	// How often each exit type should come up, on average, for a completed map. Used to steer map generation towards this mix of room exit types.
	static exit_type_targets = [0, 6, 4, 8, 6, 3];

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

	// Set up map-wide layout and room type counts
	available_special_room_types = [];
	layouts_by_exit_type = [];
	layout_use_counts = array_create(array_length(layout_cache.layouts), 0);

	// Map-wide events, randomly determined once per map
	long_and_straight_map = false;
	same_skeleton_type = noone;
	other_special_item_count = 0;
	included_special_room_types = [];
	required_layouts = [];					// The special room layouts the map must include, as { layout, special_room_type }, in the order rooms are reserved for them

	// The rooms, and the exits between them
	rooms = [];
	room_at_cell = {};						// Each room by its grid cell ("x,y"), so finding an adjacent room needs no search
	cardinal_exits = [];					// Every exit joining two adjacent rooms, which is every exit but the stairs
	locked_exits = [];						// Each locked cardinal exit, reset during lock and key search
	relevant_locked_chest_rooms = [];		// Each room with a locked chest that affects the lock and key search, reset during the search

	// Variables calculated at the end, and passed off to the controller object. They stay on the map until then, so a failed
	// attempt never touches the controller, and building can take a room out of rooms_with_collectables first
	rooms_with_collectables = [];
	spawned_items = [];
	time_provided = 0;

	// Map-wide variables during room building events
	special_item_under_block = -1;			// The special item type a block hides, once one does. A map has one at most
	regular_items_under_blocks = [];		// Each regular item type a block hides, which the item caps count
	
	// Map generation pass values, reset at the start of every pass
	reset_map_variables();

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

/// @function build_rooms()
/// @description Builds every room, in a random order so that any room's blocks are as likely to hide the special item.
///	Each room's instances are put away before the next room is built, as when the player leaves a room, and the
///	controller points at the room being built, since instances read its room when they're created
/// @param {GameMap} _map The finished map
function build_rooms(_map) {
	// Loop through all rooms in a random order
	var _controller = global.controller, _rooms_to_build = array_shuffle(_map.rooms);
	for (var _i = 0; _i < array_length(_rooms_to_build); _i++) {
		// Build the room's instances, then deactivate them all
		var _room = _rooms_to_build[_i];
		_controller.current_room = _room;
		_room.build(_map);
		_room.deactivate_room_instances();
	}
}

/// @function get_skeleton_type([_include_basic_skeleton])
/// @description Determines what a skeleton spot holds at the current difficulty
/// @param {bool} [_include_basic_skeleton] Whether the function should be able to return a basic skeleton
/// @returns {Asset.GMObject}
function get_skeleton_type(_include_basic_skeleton = true) {
	// Add up the chances of all available skeleton types, to use if not including basic skeleton
	var _skeleton_type_chances = get_skeleton_type_chances(), _total_type_chance = 0;
	for (var _i = 0; _i < array_length(_skeleton_type_chances); _i++) { _total_type_chance += _skeleton_type_chances[_i].chance; }
	
	// Pick a random number out of 100, or out of the types' total chance without basic skeletons, then go through the
	// skeleton types in order, stopping to return the type it lands on
	var _random_number = irandom_range(1, _include_basic_skeleton ? SKELETON_TYPE_CHANCE_MAX : _total_type_chance), _current_type_chance_max = 0;
	for (var _i = 0; _i < array_length(_skeleton_type_chances); _i++) {
		var _skeleton_type_chance = _skeleton_type_chances[_i];
		_current_type_chance_max += _skeleton_type_chance.chance;
		if (_random_number <= _current_type_chance_max) { return _skeleton_type_chance.type; }
	}
	
	return obj_skeleton;
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
