function GameRoom(given_x, given_y) constructor {
	// Map Generation Values
	virtual_x = given_x;
	virtual_y = given_y;
	exits = [-1, -1, -1, -1, -1];
	distance_to_start = 9999;
	
	// Instance Positioning Values
	room_reference = -1;
	room_reference_difficulty_score = 0;
	old_room_reference_difficulty_score = 0;
	
	// Room Initialization Values
	visited = false;
	lit = false;
	stairs_spot_obj = -1;
	chest_obj = -1;
	
	// Room Start Values
	has_key = false;
	has_lanterns = false;
	has_hidden_chest = false;
	has_locked_chest = false;
	has_special_item = false;
	has_collectables = false;
	has_no_cardinal_exits = false;
	has_portcullis_button = false;
	has_misleading_exits = false;
	has_hall_of_mirrors = false;
	is_special_room = false;
	is_start_room = false;
	is_heart_room = false;
	
	// New MapGen Values
	layout = undefined;						// The cached layout this room is built from (see RoomLayout)
	key_in_chest = false;					// The key step put this room's key, or the bomb standing in for it, in a chest (R48, R49)
	chest_on_stairs_spot = false;			// stairs_spot_obj goes on the stairs spot instead of the chest spot (L1, R57)
	button_on_stairs_spot = false;			// The portcullis button goes on the stairs spot instead of a collectable spot (R52, R57)
	button_spot = -1;						// Which collectable spot, in layout file order, the portcullis button takes (R52, R57)
	key_spot = -1;							// Which collectable spot, in layout file order, the floor key takes (R57)
	mapgen_index = -1;						// Its place in its map's rooms, which the key check's room bitmasks use (set by GameMap)
	mapgen_sin = undefined;					// The sin reserved for it (step 4)
	mapgen_content = undefined;				// What step 5 rolled for its layout
	mapgen_chest_lock = -1;					// Its locked chest's number in the key check
	mapgen_needs_layout = true;				// Its side exits changed since its last layout pick (R16)
	
	// Its layout's orientation, so the layout's openings face its side exits (step 5)
	flip_horizontal = false;
	flip_vertical = false;
	rotate = noone;
	
	// The content step 5 rolls for its layout, given back to it at the start of every decoration pass (step 6)
	has_eyes = false;
	has_phantom = false;
	has_floater = false;
	has_moving_collectable = false;
	replaced_column_fountain_count = 0;
	replaced_statue_fountain_count = 0;
	initial_nose_count = 0;
	initial_fire_skeleton_count = 0;
	initial_mouth_count = 0;
	skeleton_types = [];
	mirror_directions = [];
	mirror_count = 0;
	
	// Room Content Values
	instances = array_create(0);
	solid_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	empty_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];
	
	/// @function									destroy();
	function destroy() {
		// The mp_grids MUST be cleaned up manually or this will cause a memory leak
		mp_grid_destroy(solid_path_grid);
		mp_grid_destroy(lava_path_grid);
		mp_grid_destroy(empty_path_grid);
	}
	
	/// =========
	// Map generation checks (see GameMap): what generation asks about this room. None of these change the room
	/// =========
	
	/// @function can_become_special_room()
	/// @description Whether the room can be reserved as a special room
	/// @returns {bool}
	function can_become_special_room() {
		return !is_special_room && !has_exit(directions.stairs);
	}
	
	/// @function can_be_start()
	/// @description Whether a room can be the start: never a room with stairs or a sin room
	/// @returns {bool}
	function can_be_start() {
		return !has_exit(directions.stairs) && !is_special_room;
	}

	/// @function can_be_heart(_start)
	/// @description Whether the room can be the heart for a given start: never the start itself or a sin room,
	///	and never linked by a side exit to the start or a hall of mirrors; stairs into it are fine (R13).
	/// @param {GameRoom} _start The start candidate
	/// @returns {bool}
	function can_be_heart(_start) {
		if (self == _start || is_special_room) { return false; }
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _connected_room = get_connected_room(_dir);
			if (_connected_room != -1 && (_connected_room == _start || _connected_room.has_hall_of_mirrors)) { return false; }
		}
		return true;
	}

	/// @function can_gain_exits()
	/// @description Whether a room may still gain exits. Stairs-only rooms never get a side exit (R8), and a
	///	sin room's exits stay fixed once reserved, so its sin layout keeps fitting (step 6).
	/// @returns {bool}
	function can_gain_exits() {
		return !has_no_cardinal_exits && !is_special_room;
	}

	/// @function has_opposite_exits()
	/// @description Whether the room has side exits on two opposite sides.
	/// @returns {bool}
	function has_opposite_exits() {
		return (has_exit(directions.up) && has_exit(directions.down)) || (has_exit(directions.left) && has_exit(directions.right));
	}

	/// @function get_exit_type()
	/// @description The layout exit kind matching the room's real side exits.
	/// @returns {real} A layout_exit_types kind
	function get_exit_type() {
		return get_exit_type_for_count(get_cardinal_exits_count());
	}

	/// @function get_exit_type_for_count(_exit_count)
	/// @description The layout exit kind for a number of side exits. For two exits, it uses whether the room's own
	///	side exits are on opposite sides.
	/// @param {real} _exit_count 0 to 4
	/// @returns {real} A layout_exit_types kind
	function get_exit_type_for_count(_exit_count) {
		switch (_exit_count) {
			case 0: return layout_exit_types.none;
			case 1: return layout_exit_types.one;
			case 2: return has_opposite_exits() ? layout_exit_types.two_opposite : layout_exit_types.two_perpendicular;
			case 3: return layout_exit_types.three;
			default: return layout_exit_types.four;
		}
	}

	/// @function get_first_side(_with_exit)
	/// @description The first side direction, from up going clockwise, that has (or lacks) an exit.
	/// @param {bool} _with_exit True to find a side with an exit, false to find one without
	/// @returns {real} The direction, or -1 if there is none
	function get_first_side(_with_exit) {
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			if (has_exit(_dir) == _with_exit) { return _dir; }
		}
		return -1;
	}
	
	/// @function can_have_chest()
	/// @description Whether the room is allowed to have a chest added to it
	/// @returns {bool}
	function can_have_chest() {
		return (!is_start_room && !is_heart_room && stairs_spot_obj == -1);
	}

	/// @function can_have_special_item()
	/// @description Whether the room is allowed to have a special item added to it
	/// @returns {bool}
	function can_have_special_item() {
		return (!has_special_item && distance_to_start >= 2);
	}
	
	/// @function can_have_special_exit_types()
	/// @description Whether a room can have illusion walls, portcullis traps and plain doors
	/// @returns {bool}
	function can_have_special_exit_types() {
		return (!has_no_cardinal_exits && !is_start_room && !is_heart_room && !is_connected_to_hall_of_mirrors());
	};
	
	/// @function can_have_portcullis(_room)
	/// @description Whether a room can have a portcullis spawn in it
	/// @returns {bool}
	function can_have_portcullis() {
		if (!can_have_special_exit_types()) { return false; }
		
		// Check each of the rooms cardinal exits
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			// Skip if there is no exit in this direction
			var _exit = exits[_dir];
			if (_exit == -1) { continue; }
			
			// Return false if any exit already has a door, illusion wall, or button
			if (_exit.has_door || _exit.has_illusion_walls > 0 || _exit.get_connected_room(id).has_portcullis_button) { return false; }
		}
		
		// Return if there is at least one potential button spot
		return array_length(get_portcullis_button_spots()) > 0;
	};

	/// @function has_chest()
	/// @description Whether the room holds a chest, hidden or not.
	/// @returns {bool}
	function has_chest() {
		return stairs_spot_obj == obj_chest || stairs_spot_obj == obj_hidden_chest;
	}
	
	/// @function has_regular_item_chest()
	/// @description Whether the room has a chest with a regular item: not cursed, not a trap, and not a key-role item
	/// @returns {bool}
	function has_regular_item_chest() {
		return (has_chest() && !has_special_item && !key_in_chest && !has_trap_chest());
	}

	/// @function has_basic_chest()
	/// @description Whether the room holds a visible chest that is neither locked nor cursed.
	/// @returns {bool}
	function has_basic_chest() {
		return stairs_spot_obj == obj_chest && !has_locked_chest && !has_special_item;
	}

	/// @function has_trap_chest()
	/// @description Whether the room's chest holds a statue or fountain trap instead of an item (R41).
	/// @returns {bool}
	function has_trap_chest() {
		return chest_obj == obj_statue || chest_obj == obj_fountain;
	}

	/// @function is_stairs_spot_free()
	/// @description Whether nothing takes the room's stairs spot: no stairs, and no cross, heart or chest placed
	/// @returns {bool}
	function is_stairs_spot_free() {
		if (has_exit(directions.stairs)) { return false; }
		return stairs_spot_obj == -1 || !chest_on_stairs_spot;
	}

	/// @function get_portcullis_button_spots()
	/// @description The free spots the room's portcullis button could take; the stairs spot when
	///	nothing uses it, and each collectable spot the floor key doesn't take, as long as one stays free for the
	///	room's collectables. A spot only counts if nothing else shares its tile, since that could hold the
	///	button down. The chest spot never holds a button.
	/// @returns {array} Collectable spot numbers in layout file order, with -1 for the stairs spot
	function get_portcullis_button_spots() {
		// Add the stairs spot to the potential button spots
		var _possible_spots = [];
		if (is_stairs_spot_free() && layout.stairs_spot_is_clear) { array_push(_spots, -1); }

		// Add any unused key spots to the potential button spots
		var _spawned_keys = (key_spot != -1) ? 1 : 0;
		var _spots_left_by_key = array_length(layout.key_spots) - _spawned_keys;
		if (!has_collectables || _spots_left_by_key >= 2) {
			// Loop through all spots in the layout, and add them to the potential button spots
			for (var _i = 0; _i < array_length(layout.button_spots); _i++) {
				var _spot = layout.button_spots[_i];
				if (_spot != key_spot) { array_push(_possible_spots, _spot); }
			}
		}
		return _possible_spots;
	}
	
	/// @function add_reachable_rooms_to_bitmask(_start_room, _reached_rooms_bitmask)
	/// @description Returns a bitmask of all rooms reachable from this room through unlocked exits and stairs
	/// @returns {real} The new bitmask
	function get_reachable_rooms_bitmask() {
		// For each room in the queue, add to the queue all new rooms reachable from that room
		var _queue = [id], _reached_rooms_bitmask = 0;
		while (array_length(_queue) > 0) {
			// Get the next room in the queue and mark it as reached in the bitmask
			var _room = array_shift(_queue);
			_reached_rooms_bitmask |= (1 << _room.mapgen_index);
			
			// For each exit out of this room, including stairs, add new connecting rooms to the queue
			for (var _dir = directions.up; _dir <= directions.stairs; _dir++) {
				// Skip no or locked exits
				var _exit = _room.exits[_dir];
				if (_exit == -1 || _exit.has_lock) { continue; }
				
				// Skip if the room connected by this exit is already in the bitmask
				var _other_room = _exit.get_connected_room(_room);
				if (_other_room.is_in_bitmask(_reached_rooms_bitmask)) { continue; }
				
				// Otherwise, add the connecting room to the queue
				array_push(_queue, _other_room);
			}
		}

		return _reached_rooms_bitmask;
	};

	/// @function is_in_bitmask(_bitmask)
	/// @description Whether the room is in a bitmask of rooms
	/// @param {real} _bitmask Bitmask of rooms, by mapgen_index
	/// @returns {bool}
	function is_in_bitmask(_bitmask) {
		return (_bitmask & (1 << mapgen_index)) != 0;
	}

	/// @function get_skeleton_spot_score(_spawn)
	/// @description Scores a skeleton spot by what spawns there, each value replacing the basic skeleton's
	///	(R55). A spot holding eyes scores nothing here, since the room's eyes score once.
	/// @param {Asset.GMObject} _spawn What spawns on the spot
	/// @returns {real}
	function get_skeleton_spot_score(_spawn) {
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

	/// @function get_hazard_counts()
	/// @description How many of each hazard the room holds, from the layout and from spawned hazards
	/// @returns {struct}
	function get_hazard_counts() {
		var _counts = hazard_counts_copy(layout.hazard_counts);
		
		// Fill in what spawned on the skeleton spots
		for (var _i = 0; _i < array_length(skeleton_types); _i++) {
			hazard_count_add(_counts, object_get_name(skeleton_types[_i]), 1);
		}
 
		// Determine predictive spawn counts
		// TODO: Why is just this one calcualted based on probabilities instead of what has actually been spawned? We should move the spawning of these earlier in the flow so the difficulty score can work with what actually spawned and no probabilities like this
		var _living_block_count = (LIVING_BLOCK_PROBABILITY > 0) ? layout.get_hazard_count("obj_block_spot") / LIVING_BLOCK_PROBABILITY : 0;
		
		// Adjust counts based on what has been spawned
		hazard_count_add(_counts, "obj_living_block", _living_block_count);
		hazard_count_add(_counts, "obj_mouth", initial_mouth_count);
		hazard_count_add(_counts, "obj_fountain", replaced_column_fountain_count + replaced_statue_fountain_count);
		hazard_count_add(_counts, "obj_statue", -replaced_statue_fountain_count);
		hazard_count_add(_counts, "obj_nose", initial_nose_count);
		hazard_count_add(_counts, "obj_fire_skeleton", initial_fire_skeleton_count); // These are ones spawned in lava, in addition to any skeleton spots above
		hazard_count_add(_counts, "obj_phantom", ((has_phantom) ? 1 : 0));
		hazard_count_add(_counts, "obj_floater", ((has_floater) ? 1 : 0));
		hazard_count_add(_counts, "obj_chest", ((has_trap_chest()) ? 1 : 0));
		hazard_count_add(_counts, "obj_collectable", (((has_moving_collectable && has_collectables)) ? 1 : 0));
		
		// Return the modified counts
		return _counts;
	}
 
	/// @function get_potential_difficulty_score(_counts)
	/// @description Returnsthe difficulty score for this room for the given hazard counts. Scores only difficulty NOT time.
	/// @param {struct} _counts The hazard counts to use for this difficulty score
	/// @returns {real}
	function get_potential_difficulty_score(_counts) {
		var _difficulty_score = get_difficulty_score_for_hazard_counts(_counts);
 
		// Collecting everything crosses the whole room, not just the way to one objective
		if (has_collectables) { _difficulty_score *= COLLECTABLES_EXPOSURE; }
 
		// Shut in until the button is pressed. One button opens every exit, so it counts once
		// TODO: Convert PORTCULLIS_TRAP_DANGER to the difficulty score value so we don't need to call a function here
		if (has_portcullis_button) { _difficulty_score += get_difficulty_score_for_danger_level(PORTCULLIS_TRAP_DANGER); }
 
		// Items make the rest of the run easier
		if (has_special_item) { _difficulty_score += SPECIAL_ITEM_REWARD_POINTS; }
		else {
			switch (chest_obj) {
				case obj_rosary: { _difficulty_score += -1.5; break; }			// One extra life
				case obj_sword: { _difficulty_score += -1; break; }				// Kills most enemy types
				case obj_staff: { _difficulty_score += -1; break; }				// Lava, fireballs and beams can't kill you while you hold it
				case obj_meat: { _difficulty_score += -0.75; break; }			// The strongest counter, but you have to use it proactively
				case obj_bomb: { _difficulty_score += -0.5; break; }			// Can kill multiple enemies, but can also kill self
			}
		}
 
		return _difficulty_score;
	}
 
	/// @function get_current_difficulty_score()
	/// @description Returns how danegerous the room is with it's current hazard counts
	/// @returns {real}
	function get_current_difficulty_score() {
		return get_potential_difficulty_score(get_hazard_counts());
	}
 
	/// @function get_difficulty_score_with(_name, _count)
	/// @description The room's score if it also held _count more of a hazard, so generation can skip a roll that
	///	would make the room too dangerous.
	/// @param {string} _name The hazard's name in the table
	/// @param {real} _count How many more
	/// @returns {real}
	function get_difficulty_score_with(_name, _count) {
		var _counts = get_hazard_counts();
		hazard_count_add(_counts, _name, _count);
		return get_potential_difficulty_score(_counts);
	}
 
	/// @function get_time_score()
	/// @description How much time the room's hazards cost (R56): 0 for none, and about 1 for each very
	///	significant hold-up, like solving a sin's quest.
	/// @returns {real}
	function get_time_score() {
		var _time = get_time_score_for_hazard_counts(get_hazard_counts());
		if (has_phantom) { _time += PHANTOM_TIME_PER_LANTERN * layout.get_object_count("obj_lantern"); } // Lanterns aren't in the difficulty score table
		return _time;
	}
 
	/// @function get_walk_entrances()
	/// @description The walk points a visit can start and end at (R56): the layout's open sides, which the
	///	orientation step turned to face the room's real exits, and the stairs spot when the room has stairs.
	/// @returns {array} Walk point numbers
	function get_walk_entrances() {
		layout.ensure_walking();
		var _entrances = [];
		for (var _i = 0; _i < layout.walk_entrance_count; _i++) { array_push(_entrances, _i); }
		if ((has_exit(directions.stairs) || array_length(_entrances) == 0) && layout.walk_stairs_point >= 0) { array_push(_entrances, layout.walk_stairs_point); }
		return _entrances;
	}
 
	/// @function add_walk_target(_targets, _point)
	/// @description Adds a walk point to a list of targets, once.
	/// @param {array} _targets The targets so far
	/// @param {real} _point A walk point number, or -1 for none
	function add_walk_target(_targets, _point) {
		if (_point >= 0 && !array_contains(_targets, _point)) { array_push(_targets, _point); }
	}
 
	/// @function get_walk_targets()
	/// @description The list of places a player walking through the room must visit.
	/// @returns {array} Walk point numbers
	function get_walk_targets() {
		layout.ensure_walking();
		var _targets = [];
		if (stairs_spot_obj == obj_chest || stairs_spot_obj == obj_encased_heart) {
			add_walk_target(_targets, chest_on_stairs_spot ? layout.walk_stairs_point : layout.walk_chest_point);
		}
		if (has_key && !key_in_chest && key_spot != -1) { add_walk_target(_targets, layout.walk_collectable_points[key_spot]); }
		if (has_collectables) {
			for (var _i = 0; _i < array_length(layout.key_spots); _i++) {
				var _spot = layout.key_spots[_i];
				if (_spot != key_spot && _spot != button_spot) { add_walk_target(_targets, layout.walk_collectable_points[_spot]); }
			}
		}
		if (has_portcullis_button) {
			var _spots = lit ? [button_on_stairs_spot ? -1 : button_spot] : list_button_spots();
			for (var _j = 0; _j < array_length(_spots); _j++) {
				add_walk_target(_targets, (_spots[_j] == -1) ? layout.walk_stairs_point : layout.walk_collectable_points[_spots[_j]]);
			}
		}
		return _targets;
	}
 
	/// @function get_walk_route_steps(_from, _to, _targets)
	/// @description Steps from one walk point to another past every target, taking the nearest one next.
	/// @param {real} _from A walk point number
	/// @param {real} _to A walk point number
	/// @param {array} _targets Walk point numbers
	/// @returns {real}
	function get_walk_route_steps(_from, _to, _targets) {
		var _steps = layout.walk_steps, _left = array_create(array_length(_targets)), _here = _from, _total = 0;
		array_copy(_left, 0, _targets, 0, array_length(_targets));
		while (array_length(_left) > 0) {
			var _next = 0, _next_steps = infinity;
			for (var _i = 0; _i < array_length(_left); _i++) {
				var _try = _steps[_here][_left[_i]];
				if (_try >= 0 && _try < _next_steps) { _next = _i; _next_steps = _try; }
			}
			if (_next_steps != infinity) { _total += _next_steps; }
			_here = _left[_next];
			array_delete(_left, _next, 1);
		}
		return _total + max(0, _steps[_here][_to]);
	}
 
	/// @function get_walk_steps(_targets)
	/// @description Steps a careful player walks in one visit (R56): in by one entrance, past every target, and
	///	out by another (or back out, in a dead end), averaged over the ways through. A dead end with nothing to
	///	do still gets a look around, as far as its chest spot.
	/// @param {array} _targets Walk point numbers to reach; [] to just pass through
	/// @returns {real}
	function get_walk_steps(_targets) {
		var _entrances = get_walk_entrances(), _count = array_length(_entrances), _total = 0, _routes = 0;
		if (array_length(_targets) == 0 && _count == 1 && layout.walk_chest_point >= 0) { _targets = [layout.walk_chest_point]; }
		for (var _a = 0; _a < _count; _a++) {
			for (var _b = 0; _b < _count; _b++) {
				if (_a == _b && _count > 1) { continue; }
				_total += get_walk_route_steps(_entrances[_a], _entrances[_b], _targets);
				_routes += 1;
			}
		}
		return (_routes > 0) ? _total / _routes : 0;
	}
 
	/// @function get_caution_factor()
	/// @description How much the room's hazards slow walking (R56): 1, plus CAUTION_PER_DANGER_POINT for each
	///	point of their danger.
	/// @returns {real}
	function get_caution_factor() {
		return 1 + CAUTION_PER_DANGER_POINT * max(0, get_potential_difficulty_score(get_hazard_counts()));
	}
 
	/// @function get_crossing_time()
	/// @description Seconds to pass through the room with nothing to do in it, for trips through the map (R56).
	/// @returns {real}
	function get_crossing_time() {
		return ROOM_ENTRY_TIME + get_walk_steps([]) / PLAYER_STEPS_PER_SECOND * get_caution_factor();
	}
 
	/// @function get_time_needed()
	/// @description Seconds a careful novice needs for one visit (R56): a moment on entering, the walk through
	///	the room slowed by its danger, and the hold-ups its hazards cause, like freezing for eyes or luring ears.
	/// @returns {real}
	function get_time_needed() {
		var _walk = get_walk_steps(get_walk_targets()) / PLAYER_STEPS_PER_SECOND;
		return ROOM_ENTRY_TIME + _walk * get_caution_factor() + HAZARD_FULL_TIME * get_time_score();
	}
 
	/// @function get_time_provided()
	/// @description The room's share of the run's time (R56): the time it needs, times the difficulty's
	///	allowance. Trips between rooms are added once for the whole map (GameMap.get_backtracking_time).
	/// @returns {real} Seconds
	function get_time_provided() {
		return TIME_ALLOWANCE * get_time_needed();
	}

	// ==========
	// Map generation changes (see GameMap): what generation does to this room on its own
	// ==========
	
	/// @function assign_layout(_layout)
	/// @description Associates a room with a layout and set's it's related variables
	/// @param {struct} _layout The layout to assign to this room
	function assign_layout(_layout) {
		layout = _layout;
		room_reference = layout.room_reference;
		has_lanterns = layout.has_lanterns;
		has_hall_of_mirrors = layout.is_hall_of_mirrors;
		has_misleading_exits = (layout.exit_type != get_exit_type());
		mapgen_needs_layout = false;
	}
	
	/// @function determine_layout_exit_type()
	/// @description Returns what kind of exit type to use, including determining if it uses a misleading layout or not
	/// @returns {real} A layout_exit_types kind
	function determine_layout_exit_type() {
		// Start with the real exit count for this room
		var _exit_count = get_cardinal_exits_count();
		
		if (get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) {
			// Randomly determine if it should have more or less layouts than intended
			var _step = get_coin_flip() ? 1 : -1;
			if (_exit_count == 0) { _step = 1; }
			if (_exit_count == 4) { _step = -1; }
			
			// Keep adding/removing exits to become more or less misleading
			while (_exit_count + _step >= 1 && _exit_count + _step <= 4) {
				_exit_count += _step;
				if (!get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) { break; }
			}
		}
		
		// Return the calculated exit count
		return get_exit_type_for_count(_exit_count);
	}

	/// @function determine_layout_orientation()
	/// @description Determines how the room's layout is flipped and rotated
	function determine_layout_orientation() {
		flip_horizontal = get_coin_flip();
		flip_vertical = get_coin_flip();

		// Where the layout's openings end up once flipped
		var _open_dirs = layout.get_open_cardinal_exits();
		for (var _dir = 0; _dir < array_length(_open_dirs); _dir++) {
			var _open_dir = _open_dirs[_dir];
			if (flip_horizontal && (_open_dir == directions.left || _open_dir == directions.right)) { _open_dir = get_opposite_dir(_open_dir); }
			if (flip_vertical && (_open_dir == directions.up || _open_dir == directions.down)) { _open_dir = get_opposite_dir(_open_dir); }
			_open_dirs[_dir] = _open_dir;
		}
	
		// Keep the rotations that put the most openings on real side exits, and pick one at random
		var _best_rotations = [], _most_matches = -1;
		for (var _rotation = directions.up; _rotation < directions.stairs; _rotation++) {
			var _matches = 0;
			for (var _dir = 0; _dir < array_length(_open_dirs); _dir++) {
				if (has_exit(get_rotated_dir(_open_dirs[_dir], _rotation))) { _matches += 1; }
			}
			if (_matches > _most_matches) { _most_matches = _matches; _best_rotations = []; }
			if (_matches == _most_matches) { array_push(_best_rotations, _rotation); }
		}
		rotate = array_random_get(_best_rotations);
	}

	/// @function determine_random_room_content(_same_skeleton_type)
	/// @description Determines the randomly generated content for a room
	/// @param {Asset.GMObject} _same_skeleton_type The map's same skeleton type, or noone if that event is off
	function determine_random_room_content(_same_skeleton_type) {
		var _content = {
			lit: false,
			has_eyes: false,
			has_phantom: false,
			has_floater: false,
			has_moving_collectable: false,
			replaced_column_fountain_count: 0,
			replaced_statue_fountain_count: 0,
			initial_nose_count: 0,
			initial_fire_skeleton_count: 0,
			initial_mouth_count: 0,
			skeleton_types: [],
			mirror_directions: []
		};

		// Only lantern rooms that aren't special rooms can start lit
		_content.lit = layout.has_lanterns && !is_special_room && get_random_chance_out_of(PRE_LIT_PROBABILITY);

		// Determine how many columns and how many statues to replace with fountains
		for (var _column = 0; _column < layout.get_hazard_count("obj_column"); _column++) {
			if (get_random_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY)) { _content.replaced_column_fountain_count += 1; }
		}
		for (var _statue = 0; _statue < layout.get_hazard_count("obj_statue"); _statue++) {
			if (get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) { _content.replaced_statue_fountain_count += 1; }
		}

		// Determine lava enemy spawns
		if (layout.get_hazard_count("obj_lava") > 0) {
			if (get_random_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY)) { _content.initial_fire_skeleton_count = 1; }
			for (var _nose_chance = 0; _nose_chance < global.difficulty - 1; _nose_chance++) {
				if (get_random_chance_out_of(NOSE_PROBABILITY)) { _content.initial_nose_count += 1; }
			}
		}
		
		// Determine eyes enemy spawn
		var _skeleton_spot_count = layout.get_object_count("obj_skeleton_spot"), _skeleton_spot_with_eyes = -1; // Skeleton spots aren't in the difficulty score table
		_content.has_eyes = (layout.get_hazard_count("obj_eyes") > 0);
		if (!_content.has_eyes && _skeleton_spot_count > 0 && get_random_chance_out_of(EYES_PROBABILITY)) {
			_content.has_eyes = true;
			_skeleton_spot_with_eyes = irandom(_skeleton_spot_count - 1);
		}

		// Determine skeleton spot enemies
		for (var _spot = 0; _spot < _skeleton_spot_count; _spot++) {
			var _skeleton_type = (_same_skeleton_type == noone) ? get_skeleton_type() : _same_skeleton_type;
			if (_spot == _skeleton_spot_with_eyes) { _skeleton_type = obj_eyes; }
			
			array_push(_content.skeleton_types, _skeleton_type);
		}
		
		// Determine additional enemy spawns
		_content.has_phantom = layout.has_lanterns && !_content.lit && !_content.has_eyes && !is_special_room && get_random_chance_out_of(PHANTOM_PROBABILITY);
		_content.has_floater = !_content.has_phantom && !_content.has_eyes && !is_special_room && get_random_chance_out_of(FLOATER_PROBABILITY);
		_content.has_moving_collectable = get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY);
		_content.initial_mouth_count = layout.get_hazard_count("obj_mouth") * (MOUTHS_PER_MOUTH - 1);

		// A hall of mirrors' sequence of exits to take
		if (layout.is_hall_of_mirrors) {
			for (var _mirror = 0; _mirror < 4; _mirror++) { array_push(_content.mirror_directions, get_random_carindal_dir()); }
		}

		mapgen_content = _content;
	};

	/// @function reset_decorations()
	/// @description Gives the room back the content step 5 rolled for its layout, and clears its decorations.
	function reset_decorations() {
		// The rolled content
		// TODO: Why is this being reset - does this change later? Why keep mapgen_content around at all?
		var _content = mapgen_content;
		lit = _content.lit;
		has_eyes = _content.has_eyes;
		has_phantom = _content.has_phantom;
		has_floater = _content.has_floater;
		has_moving_collectable = _content.has_moving_collectable;
		replaced_column_fountain_count = _content.replaced_column_fountain_count;
		replaced_statue_fountain_count = _content.replaced_statue_fountain_count;
		initial_nose_count = _content.initial_nose_count;
		initial_fire_skeleton_count = _content.initial_fire_skeleton_count;
		initial_mouth_count = _content.initial_mouth_count;
		skeleton_types = array_get_duplicate(_content.skeleton_types);
		mirror_directions = array_get_duplicate(_content.mirror_directions);
		mirror_count = 0;

		// No decorations yet
		is_start_room = false;
		is_heart_room = false;
		distance_to_start = 9999;
		stairs_spot_obj = -1;
		chest_on_stairs_spot = false;
		chest_obj = -1;
		has_hidden_chest = false;
		has_locked_chest = false;
		has_special_item = false;
		has_key = false;
		key_in_chest = false;
		key_spot = -1;
		has_collectables = false;
		has_portcullis_button = false;
		button_on_stairs_spot = false;
		button_spot = -1;
		room_reference_difficulty_score = 0;
	}

	/// @function remove_random_room_content()
	/// @description Removes any randomly generated content from the room, limiting it to the static json version
	function remove_random_room_content() {
		// Replace any dangerous randomly rolled skeleton types with basic skeletons
		for (var _i = 0; _i < array_length(skeleton_types); _i++) {
			var _current_type = skeleton_types[_i]
			if (_current_type != obj_skeleton && _current_type != obj_fast_skeleton && _current_type != obj_cockroach && _current_type != obj_fat_skeleton) { skeleton_types[_i] = obj_skeleton; }
		}
		
		// Remove any other dangers generated for this room
		has_eyes = (layout.get_hazard_count("obj_eyes") > 0);
		has_phantom = false;
		has_floater = false;
		replaced_column_fountain_count = 0;
		replaced_statue_fountain_count = 0;
		initial_nose_count = 0;
		initial_fire_skeleton_count = 0;
	}

	/// @function set_stairs_spot_object(_object)
	/// @description Places the room's stairs-spot object (the cross, the encased heart, or a chest) and whether it appears on the chest or stairs spot.
	/// @param {Asset.GMObject} _object What to place
	function set_stairs_spot_object(_object) {
		stairs_spot_obj = _object;
		chest_on_stairs_spot = (_object == obj_cross) || (!has_exit(directions.stairs) && get_random_chance_out_of(CHEST_ON_STAIRS_SPOT_PROBABILITY));
	}

	/// @function add_chest()
	/// @description Puts a chest with no item yet in the room. Hidden chests can appear only in unlit lantern rooms with no phantom
	/// @param {bool} _must_be_hidden Whether to force a hidden chest to spawn or not
	function add_chest(_must_be_hidden) {
		has_hidden_chest = _must_be_hidden || (has_lanterns && !lit && !has_phantom && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY));
		set_stairs_spot_object(has_hidden_chest ? obj_hidden_chest : obj_chest);
	}

	/// @function add_portcullis_trap()
	/// @description Traps the room: the portcullis on its side of each side exit closes until the player presses
	///	its button. The room loses any phantom or floater, and the button's spot is picked at random from all
	///	free spots, so building places it exactly there (R52, R57).
	function add_portcullis_trap() {
		// Set portcullis flag and unset any flags that shouldn't spawn in portcullis rooms
		has_portcullis_button = true;
		has_phantom = false;
		has_floater = false;
		
		// Add portcullis trigger to each cardinal exit
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _exit = exits[_dir];
			if (_exit != -1) { _exit.set_portcullis_to_trigger_for_room(self, true); }
		}

		// Pick a spot to spawn the portcullis button
		var _spot = array_random_get(get_portcullis_button_spots());
		button_on_stairs_spot = (_spot == -1);
		button_spot = _spot;
	}

	/// @function									assign_room_ref(must_have_lantern, spawn_special_room);
	/// @param		{bool} must_have_lantern	Whether or not the room_reference must have lanterns in it
	/// @param		{bool} spawn_special_room	Whether or not the room_reference used should be a special room
	function assign_room_ref(must_have_lantern, spawn_special_room) {
		if (room_reference != -1) { array_remove_first(global.controller.room_references, room_reference); }
		
		set_room_reference(must_have_lantern, spawn_special_room);
		update_game_room_initialize_values();
		update_game_room_difficulty_old();
		update_game_room_difficulty();
	}
	
	/// @function									update_game_room_initialize_values();
	function update_game_room_initialize_values() {
		is_special_room = array_contains(global.special_rooms, room_reference);
		if (is_special_room) { write_debug_message("Generated special room: " + room_get_name(room_reference)); } 
		has_hall_of_mirrors = (get_room_reference_object_count(obj_hall_of_mirrors) > 0)
		if (has_hall_of_mirrors) { write_debug_message("Generated hall of mirrors: " + room_get_name(room_reference)); } 
		has_lanterns = get_room_reference_object_count(obj_lantern) > 0;
		lit = (has_lanterns && get_random_chance_out_of(PRE_LIT_PROBABILITY));
		has_eyes = (get_room_reference_object_count(obj_eyes) > 0 || get_random_chance_out_of(EYES_PROBABILITY));
		has_phantom = (has_lanterns && !lit && !has_eyes && get_random_chance_out_of(PHANTOM_PROBABILITY));
		has_floater = (!has_phantom && !has_eyes && get_random_chance_out_of(FLOATER_PROBABILITY));
		has_moving_collectable = get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY);
		
		replaced_column_fountain_count = 0
		replaced_statue_fountain_count = 0
		for (var i = 0; i < get_room_reference_object_count(obj_column); i++) {
			if (get_random_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY)) { replaced_column_fountain_count += 1; }
		}
		for (var i = 0; i < get_room_reference_object_count(obj_statue); i++) {
			if (get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) { replaced_statue_fountain_count += 1; }
		}
		
		initial_nose_count = 0;
		if (get_room_reference_object_count(obj_lava) > 0) {
			for (var i = 0; i < global.difficulty-1; i++;) {
				if (get_random_chance_out_of(NOSE_PROBABILITY)) { initial_nose_count += 1; }
			}
		}
		
		initial_fire_skeleton_count = 0;
		if (get_room_reference_object_count(obj_lava) > 0 && get_random_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY)) {
			initial_fire_skeleton_count += 1;
		}
		
		cockroach_count = 0;
		snake_count = 0;
		fast_skeleton_count = 0;
		fat_skeleton_count = 0;
		fire_skeleton_count = 0;
		cultist_count = 0;
		skeleton_types = array_create(0);
		for (var i = 0; i < get_room_reference_object_count(obj_skeleton_spot); i++;) {
			var skeleton_type = obj_skeleton;
			if (has_eyes && i == 0) { skeleton_type = obj_eyes; }
			else if (global.controller.same_skeleton_type != noone) { skeleton_type = global.controller.same_skeleton_type; }
			else { skeleton_type = get_skeleton_type(); }
			
			//skeleton_type = obj_fat_skeleton; // TODO: CHANGE HERE FOR TESTING
			
			switch (skeleton_type) {
				case obj_cockroach: { cockroach_count += 1; break; }
				case obj_fast_skeleton: { fast_skeleton_count += 1; break; }
				case obj_fat_skeleton: { fat_skeleton_count += 1; break; }
				case obj_fire_skeleton: { fire_skeleton_count += 1; break; }
				case obj_cultist: { cultist_count += 1; break; }
				case obj_snake: { snake_count += 1; break; }
			}
			array_push(skeleton_types, skeleton_type);
		}
		
		var initial_mouths = get_room_reference_object_count(obj_mouth);
		initial_mouth_count = (initial_mouths * MOUTHS_PER_MOUTH) - initial_mouths;
		
		if (has_hall_of_mirrors) {
			mirror_directions = array_create(0);
			for (var i = 0; i < 4; i++) {
				array_push(mirror_directions, get_random_carindal_dir())
			}
			mirror_count = 0;
		}
	}
	
	/// @function									update_game_room_difficulty();
	function update_game_room_difficulty() {
		// KEEP THESE VALUES IN LINE WITH THE RUBY ROOM CONVERTER SCRIPT VALUES
		
		// Reset initial room values
		if (global.controller.start_room == self) { 
			replaced_column_fountain_count = 0; 
			replaced_statue_fountain_count = 0;
			has_phantom = false;
			has_floater = false;
		}
		room_reference_difficulty_score = 0;
	
		// Add to difficulty for enemies
		var has_bumper = get_room_reference_object_count(obj_bumper_old) > 0;
		var has_ears = get_room_reference_object_count(obj_ears) > 0;
		var has_gudetama = get_room_reference_object_count(obj_gudetama) > 0;
		
		if (has_phantom) { room_reference_difficulty_score += 2; }
		if (has_floater) { room_reference_difficulty_score += 2; }
		if (has_bumper) { room_reference_difficulty_score += 1.25; }
		if (has_eyes) { room_reference_difficulty_score += 4.5; } //2.5
		if (has_ears) { room_reference_difficulty_score += 4.5; } //2.5
		if (has_gudetama) { room_reference_difficulty_score += 4.5; } //0.025
		
		room_reference_difficulty_score += get_room_reference_object_count(obj_mouth) * 1;
		room_reference_difficulty_score += initial_nose_count * 0.75;
		room_reference_difficulty_score += initial_fire_skeleton_count;
		room_reference_difficulty_score += (get_room_reference_object_count(obj_spider_spot) > 0) ? 1.5 : 0;
		room_reference_difficulty_score += get_room_reference_object_count(obj_spider) * 1.5;
		room_reference_difficulty_score += replaced_column_fountain_count * 0.5; //0.325
		room_reference_difficulty_score += replaced_statue_fountain_count * 0.25; //0.325
		room_reference_difficulty_score += (get_room_reference_object_count(obj_statue) - replaced_statue_fountain_count) * 0.25; //0.325
		room_reference_difficulty_score += get_room_reference_object_count(obj_fountain) * 0.5; //0.325
		room_reference_difficulty_score += (get_room_reference_object_count(obj_skeleton_spot) - fast_skeleton_count - fat_skeleton_count - snake_count - fire_skeleton_count - cultist_count - ((has_eyes) ? 1 : 0)) * 0.33; //0.25
		room_reference_difficulty_score += (get_room_reference_object_count(obj_snake) + snake_count) * 0.66 // 0.5
		room_reference_difficulty_score += fast_skeleton_count * 0.325;
		room_reference_difficulty_score += fat_skeleton_count * 0.325;
		room_reference_difficulty_score += cultist_count * 0.325;
		room_reference_difficulty_score += fire_skeleton_count * 0.5;
		room_reference_difficulty_score += ((get_room_reference_object_count(obj_giant_worm_head) * 0.1625) + (get_room_reference_object_count(obj_giant_worm_body) * 0.0625));
	
		// Add a base increase if any enemies were present
		if (room_reference_difficulty_score != 0) { room_reference_difficulty_score += 0.25; }		
		if (is_special_room) { room_reference_difficulty_score += 5; }
		
		// Add to difficulty for other objects
		if (has_hidden_chest) { room_reference_difficulty_score += 0.125; }
		if (!has_phantom && !has_hidden_chest && has_lanterns > 0) { room_reference_difficulty_score -= 0.125; }		
		if (has_lanterns && lit) { room_reference_difficulty_score -= 0.125; }
		if (has_locked_chest && !has_special_item) { room_reference_difficulty_score += 0.125; }
		if (has_no_cardinal_exits) { room_reference_difficulty_score += 0.125; }
		if (has_collectables) { room_reference_difficulty_score += 0.25; }
		if (has_misleading_exits) { room_reference_difficulty_score += 0.125; }
		if (chest_obj == obj_statue) { room_reference_difficulty_score += 0.325; }
		else if (chest_obj == obj_fountain) { room_reference_difficulty_score += 0.325; }
		else if (!has_key && chest_obj != -1) { room_reference_difficulty_score -= 0.25; }
		if (has_special_item) { room_reference_difficulty_score -= 2; }
		
		room_reference_difficulty_score += get_room_reference_object_count(obj_block_spot) * 0.080; //clamp(get_room_reference_object_count(obj_block_spot) * 0.01, 0, 0.25);
		room_reference_difficulty_score += get_room_reference_object_count(obj_lava) * 0.010; //clamp(get_room_reference_object_count(obj_lava) * 0.05, 0, 0.5);
		room_reference_difficulty_score += get_room_reference_object_count(obj_bones) * 0.050;
		room_reference_difficulty_score += get_room_reference_object_count(obj_player_corpse) * 0.050;
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) {
				if (next_exit.has_closed_portcullis_for_room(self)) { room_reference_difficulty_score += 0.325; }
				// These are all counted twice, once by each room the exit is connected to, and so should be halved
				if (next_exit.has_door) { room_reference_difficulty_score += 0.025; }
				if (next_exit.has_lock) { room_reference_difficulty_score += 0.125; }
				if (next_exit.has_illusion_walls > 0) { room_reference_difficulty_score += 0.25; }
			}
		}
	}
	
	/// @function									update_game_room_difficulty_old();
	function update_game_room_difficulty_old() {
		var has_bumper = get_room_reference_object_count(obj_bumper_old) > 0;
		var has_ears = get_room_reference_object_count(obj_ears) > 0;
		var has_gudetama = get_room_reference_object_count(obj_gudetama) > 0;
		var has_echo = get_room_reference_object_count(obj_inverted_cross) > 0;
		
		old_room_reference_difficulty_score = 0;
		
		if (get_room_reference_object_count(obj_lantern) > 0) { old_room_reference_difficulty_score += 1; }
		if (has_bumper) { old_room_reference_difficulty_score += 1.5; }
		if (has_echo) { old_room_reference_difficulty_score += 5; }
		if (get_room_reference_object_count(obj_eyes) > 0) { old_room_reference_difficulty_score += 4; }
		if (has_ears) { old_room_reference_difficulty_score += 4; }
		if (has_gudetama) { old_room_reference_difficulty_score += 4; }
		
		old_room_reference_difficulty_score += get_room_reference_object_count(obj_mouth);
		old_room_reference_difficulty_score += floor(get_room_reference_object_count(obj_block_spot) * 0.08);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_lava) * 0.01);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_bones) * 0.05);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_spider) * 1.5);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_player_corpse) * 0.05);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_statue) * 0.25);
		//old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_column) * 0.10);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_skeleton_spot) * 0.33);
		old_room_reference_difficulty_score += ceil(get_room_reference_object_count(obj_snake) * 0.66);
		old_room_reference_difficulty_score += ceil((get_room_reference_object_count(obj_giant_worm_head) * 0.25) + (get_room_reference_object_count(obj_giant_worm_body) * 0.10));
	}
	
	/// @function									calculate_distance_to_connected_rooms(start_distance);
	/// @param		{real}	start_distance			The distance already traveled before this room was reached
	function calculate_distance_to_connected_rooms(start_distance) {
		if (start_distance < distance_to_start) { 
			distance_to_start = start_distance;
			for (var dir = directions.up; dir <= directions.stairs; dir++;) {
				var connected_room = get_connected_room(dir);
				if (connected_room == -1) { continue; }
						
				connected_room.calculate_distance_to_connected_rooms(distance_to_start+1);
			}
		}
	}
	
	/// @function									has_visited_exit(dir);
	/// @param		{dir}	dir						The direction of the exit to check for visited status
	function has_visited_exit(dir) {
		return (exits[dir] != -1 && exits[dir].visited);
	}
	
	/// @function									has_exit(dir);
	/// @param		{dir}	dir						The direction of the exit to check for
	function has_exit(dir) {
		return (exits[dir] != -1);
	}
	
	/// @function									get_cardinal_exits_count();
	function get_cardinal_exits_count() {
		var exit_count = 0;
		for (var dir = directions.up; dir < directions.stairs; dir++;) { if (has_exit(dir)) { exit_count += 1; } }
		return exit_count;
	}
	
	/// @function									get_adjacent_room_directions();
	/// @param		{boolean} is_empty				Whether to return directions with adjacent rooms that do or don't exist
	function get_adjacent_room_directions(is_empty) {
		// Get which adjacent directions are empty
		var adjacent_room_directions = array_create(0);
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var adj_room = get_adjacent_room(dir);
			if (adj_room != -1 && adj_room.has_no_cardinal_exits) { continue; }
			if ((adj_room == -1) == is_empty) { array_push(adjacent_room_directions, dir); }
		}
		return adjacent_room_directions;
	}
	
	/// @function									get_connected_room_directions();
	/// @param		{boolean} is_empty				Whether to return directions with connected rooms that do or don't exist
	function get_connected_room_directions(is_empty) {
		// Get which connected directions are not empty
		var connected_room_directions = array_create(0);
		for (var dir = directions.up; dir <= directions.stairs; dir++;) {
			if ((get_connected_room(dir) == -1) == is_empty) { array_push(connected_room_directions, dir); }
		}
		return connected_room_directions;
	}
	
	/// @function									get_adjacent_room(dir);
	/// @param		{dir}	dir						The direction to check for an adjacent room in
	function get_adjacent_room(dir) {
		// Only cardinal directions can have adjacent rooms
		if (dir >= directions.stairs) { return -1; }
		
		// Sort the game rooms in order of their x and y positions
		var game_rooms = global.controller.game_rooms, adj_room = -1;
		array_sort(game_rooms, function(elm1, elm2)
		{
			if (elm1.virtual_x == elm2.virtual_x) { return elm1.virtual_y - elm2.virtual_y; }
			else { return elm1.virtual_x - elm2.virtual_x; }
		});
		
		// Check the existing game rooms for the desired x and y positions
		var x_pos = virtual_x + get_dir_x_offset(dir), y_pos = virtual_y + get_dir_y_offset(dir), 
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var game_room = game_rooms[i];
			// Skip to rooms with the x_pos we are looking for
			if (game_room.virtual_x < x_pos) { continue; }
			else if (game_room.virtual_x > x_pos) { break; }
			// Skip to rooms with the y_pos we are looking for
			if (game_room.virtual_y < y_pos) { continue; }
			else if (game_room.virtual_y > y_pos) { break; }
			else { adj_room = game_room; break; }
		}
		return adj_room;
	}
	
	/// @function									get_connected_room(dir);
	/// @param		{dir}	dir						The direction to check for a connected room in
	function get_connected_room(dir) {
		if (dir > directions.stairs) { return -1; }
		
		return ((exits[dir] == -1) ? -1 : exits[dir].get_connected_room(self));
	}
	
	/// @function									connect_room_with_new_exit(new_room, dir);
	/// @param		{GameRoom}	new_room			The room to connect with this one
	/// @param		{dir}		dir					The direction to connect these rooms in
	function connect_room_with_new_exit(new_room, dir) {
		var new_exit = new RoomExit(self, new_room);
		exits[dir] = new_exit;
		new_room.exits[get_opposite_dir(dir)] = new_exit;
		if (dir == directions.stairs && get_random_chance_out_of(NO_CARDINAL_EXIT_ROOM_PROBABILITY)) { new_room.has_no_cardinal_exits = true; }
		
		assign_room_ref(false, false);
		new_room.assign_room_ref(false, false);
		
		return new_exit;
	}
	
	/// @function									is_adjacent_room(tested_room);
	/// @param		{GameRoom}	tested_room			The room to test for adjacency
	function is_adjacent_room(tested_room) {
		var adjacent_room_directions = get_adjacent_room_directions(false);
		while (array_length(adjacent_room_directions) > 0) {
			var adj_dir = array_pop(adjacent_room_directions), adj_room = get_adjacent_room(adj_dir);
			if (adj_room == tested_room) { return true; }
		}
		return false;
	}
	
	/// @function									create_connected_room();
	function create_connected_room() {
		// Determine which direction to create a connecting room in
		var chosen_room = self, connected_dir = directions.stairs, adj_dir = -1, game_rooms = global.controller.game_rooms;
		// Sometimes connect rooms via stairs
		if (!has_exit(directions.stairs) && get_random_chance_out_of(STAIRS_PROBABILITY)) {
			// Create room adjacent to any existing room in any open direction
			array_shuffle_ext(game_rooms);
			for (var i = 0; i < array_length(game_rooms); i++) {
				chosen_room = game_rooms[i];
				if (chosen_room == self || is_adjacent_room(chosen_room)) { continue; }
				
				adj_dir = chosen_room.get_free_adjacent_room_direction();
				if (adj_dir != -1) { break; }
			}
		}
		// Determine an adjacent room to connect via cardinal exit
		if (adj_dir == -1) { 
			chosen_room = self;
			adj_dir = get_free_adjacent_room_direction(); 
			connected_dir = adj_dir;
			if (adj_dir == -1) { return -1; }
		}
		
		// Create connecting room in the chosen direction
		var x_pos = chosen_room.virtual_x + get_dir_x_offset(adj_dir), y_pos = chosen_room.virtual_y + get_dir_y_offset(adj_dir), new_room = new GameRoom(x_pos, y_pos);
		array_push(game_rooms, new_room);
		
		connect_room_with_new_exit(new_room, connected_dir);
		
		return connected_dir;
	}
	
	
	/// @function									get_free_adjacent_room_direction();
	function get_free_adjacent_room_direction() {
		// Get which adjacent directions are empty
		var empty_directions = get_adjacent_room_directions(true);
		if (array_length(empty_directions) == 0) { return -1; }
		
		// Choose a random empty adjacent direction and create a new room there
		array_shuffle_ext(empty_directions);
		return empty_directions[0];
	}
	
	/// @function									connect_adjacent_room();
	function connect_adjacent_room() {
		if (get_cardinal_exits_count() == 4) { return -1; }
		
		// Get which adjacent directions are empty
		var adjacent_room_directions = get_adjacent_room_directions(false), empty_connected_room_directions = get_connected_room_directions(true);
		var possible_directions = array_intersection(adjacent_room_directions, empty_connected_room_directions);
		if (array_length(possible_directions) == 0) { return -1; }
		
		// Choose a random empty adjacent direction and create a new room there
		array_shuffle_ext(possible_directions);
		var chosen_dir = possible_directions[0], chosen_room = get_adjacent_room(chosen_dir);
		connect_room_with_new_exit(chosen_room, chosen_dir);
		return chosen_room;
	}
	
	/// @function								rebuild_room_grids();
	function rebuild_room_grids() {
		mp_grid_clear_all(solid_path_grid);
		mp_grid_clear_all(lava_path_grid);
		with (obj_lava_part) { mp_path_grid_add(other.lava_path_grid); }
		with (obj_solid) { mp_path_grid_add(other.solid_path_grid); mp_path_grid_add(other.lava_path_grid); }
	}
	
	/// @function								add_to_instances_at_map_positions(inst);
	/// @param		{real} inst					The instance id to add to the room map position
	function add_to_instances_at_map_positions(inst) {
		var room_map_pos = get_room_map_position(inst);
		array_push(instances_at_map_positions[room_map_pos[0]][room_map_pos[1]], inst.object_index);
	}

	/// @function								remove_from_instances_at_map_positions(inst);
	/// @param		{real} inst					The instance id to remove from the room map position
	function remove_from_instances_at_map_positions(inst) {
		var room_map_pos = get_room_map_position(inst);
		array_remove_first(instances_at_map_positions[room_map_pos[0]][room_map_pos[1]], inst.object_index);
	}
	
	/// @function								add_key();
	function add_key() {
		var controller = global.controller;
		if (has_key) { return false; }

		if (controller.heart_room != self && controller.start_room != self && chest_obj == -1 && get_random_chance_out_of(KEY_IN_CHEST_PROBABILITY)) {
			var new_item_type = get_random_chance_out_of(BOMB_REPLACES_KEY_IN_CHEST_PROBABILITY) ? obj_bomb : obj_key;
			add_chest(true, new_item_type); 
		}
		has_key = true;
		array_push(controller.rooms_with_key, self);
		return true;
	}
	
	/// @function								add_collectables();
	function add_collectables() {
		var controller = global.controller;
		if (has_collectables || controller.start_room == self) { return false; }
		
		has_collectables = true;
		array_push(controller.rooms_with_collectables, self);
		return true;
	}
	
	/// @function								is_connected_to_hall_of_mirrors();
	function is_connected_to_hall_of_mirrors() {
		if (has_hall_of_mirrors) { return true; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit == -1) { continue; }
			
			var next_room = next_exit.get_connected_room(self);
			if (next_room.has_hall_of_mirrors) { return true; }
		}
		
		return false;
	}
	
	/// @function								add_illusion_walls();
	function add_illusion_walls() {
		var illusion_walls_added = false, controller = global.controller;
		if (controller.start_room == self) { return illusion_walls_added; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit == -1) { continue; }
			
			var next_room = next_exit.get_connected_room(self);
			if (next_room != controller.start_room && 
				!next_exit.has_door && 
				!next_exit.has_closed_portcullis_for_room(next_room) && 
				!next_exit.has_closed_portcullis_for_room(self) && 
				get_random_chance_out_of(ILLUSION_WALL_PROBABILITY)) {
					illusion_walls_added = true;
					next_exit.has_illusion_walls = 1;
			}
		}
		
		if (illusion_walls_added) { write_debug_message("Generated illusion walls: " + room_get_name(room_reference)); }
		return illusion_walls_added;
	}
	
	/// @function								add_portcullis();
	function add_portcullis() {
		if ((has_key && has_collectables && (stairs_spot_obj != -1 || exits[directions.stairs] != -1))) { return false; }
		
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1 && (next_exit.has_lock || next_exit.has_illusion_walls > 0 || next_exit.get_connected_room(self).has_portcullis_button)) { return false; }
		}
		
		if (!get_random_chance_out_of(PORTCULLIS_PROBABILITY)) { return false; }
		
		// Add portcullis to this room's side of each rooms non-stairs exits
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) { next_exit.set_portcullis_to_trigger_for_room(self, true); }
		}
		has_phantom = false;
		has_floater = false;
		has_portcullis_button = true;
		write_debug_message("Generated portcullis button: " + room_get_name(room_reference));
		return true;
	}
	
	/// @function								add_unlocked_doors();
	function add_unlocked_doors() {
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit == -1) { continue; }
			if (next_exit.has_lock || next_exit.has_illusion_walls > 0 || next_exit.get_connected_room(self).has_portcullis_button) { continue; }
			
			next_exit.has_door = get_random_chance_out_of(OPEN_DOOR_PROBABILITY*2);
			if (next_exit.has_door) { write_debug_message("Generated open door: " + room_get_name(room_reference)); }
		}
	}
	
	/// @function								remove_portcullis();
	function remove_portcullis() {
		// Remove portcullis to this room's side of each rooms non-stairs exits
		has_portcullis_button = false;
		for (var dir = directions.up; dir < directions.stairs; dir++;) {
			var next_exit = exits[dir];
			if (next_exit != -1) { next_exit.set_portcullis_to_trigger_for_room(self, false); }
		}
	}
	
	/// @function								add_chest();
	function add_chest(must_spawn, given_item_obj) {
		if (!must_spawn && !get_random_chance_out_of(CHEST_PROBABILITY) && !is_special_room) { return -1; }
		
		// Update room chest and item information
		var controller = global.controller;
		has_hidden_chest = is_special_room || (!lit && has_lanterns && !has_phantom && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY));
		has_special_item = is_special_room || (distance_to_start > 1 && array_length(controller.spawned_special_items) < SPECIAL_ITEM_LIMIT && (is_special_room || get_random_chance_out_of(SPECIAL_ITEM_PROBABILITY)));
		has_locked_chest = (!has_hidden_chest && (has_special_item || get_random_chance_out_of(LOCKED_CHEST_PROBABILITY)));
		var spawned_item_obj = (must_spawn) ? given_item_obj : get_random_item_obj(has_special_item, false);
		var spawned_item_array = (has_special_item) ? controller.spawned_special_items : controller.spawned_items;
		if (!must_spawn && !has_hidden_chest && !has_special_item && !has_locked_chest && get_random_chance_out_of(TRAP_CHEST_PROBABILITY)) { spawned_item_obj = (get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY)) ? obj_fountain : obj_statue; }
		
		// Set up chest information to spawn
		stairs_spot_obj = (has_hidden_chest) ? obj_hidden_chest : obj_chest;
		chest_obj = spawned_item_obj;
		array_push(spawned_item_array, spawned_item_obj);
		if (has_locked_chest) { array_push(controller.rooms_with_locked_chest, self); }
		write_debug_message("Generated" + ((has_special_item) ? " cursed " : " ") + object_get_name(spawned_item_obj) + " " + string(spawned_item_obj));
		
		return spawned_item_obj;
	}
	
	/// @function									initialize_from_room_reference();
	function initialize_from_room_reference() {
		var reference_instances = layout.instances;
		collectable_spot_instances = array_create(0);
		
		for(var i = 0; i < array_length(reference_instances); i++) {
			var ref = reference_instances[i];
			var new_instance = instance_create(ref.x, ref.y, asset_get_index(ref.name));
			if (ref.name == "obj_collectable_spot") { array_push(collectable_spot_instances, new_instance); }
		}
	}
	
	/// @function								get_room_reference_object_count();
	/// @param		{int} obj					The object index to check for the presence of
	function get_room_reference_object_count(obj) {
		// TODO: LEGACY FUNCTION to be replaced in all call sites with the below global version:
		return get_object_count_for_room_reference(room_reference, obj);
	}

	/// @function									deactivate_room_instances();
	function deactivate_room_instances() {
		instances = array_create(0);
		collectable_spot_instances = array_create(0);
		
		with (obj_light_source) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_game_object) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, id); } }
		for (var i = 0; i < array_length(instances); i++) { instance_deactivate_object(instances[i]); }
	}


	/// @function									activate_room_instances();
	function activate_room_instances() {
		if (array_length(instances) == 0) { initialize_from_room_reference(); }
		else {
			for (var i = 0; i < array_length(instances); i++) {
				instance_activate_object(instances[i]);
			}
		}
	}
	
	/// @function								set_room_reference(must_have_lantern, spawn_special_room);
	/// @param		{bool} must_have_lantern	Whether or not the room_reference must have lanterns in it
	/// @param		{bool} spawn_special_room	Whether or not the room_reference used should be a special room
	function set_room_reference(must_have_lantern, spawn_special_room) {
		var controller = global.controller, number_of_exits = get_cardinal_exits_count(), room_list_number_of_exits = number_of_exits, room_list = noone,
		var rand1 = get_coin_flip(), rand2 = get_coin_flip(), misleading_direction = (get_coin_flip()) ? 1 : -1;
		if (room_list_number_of_exits >= 4) { misleading_direction = -1; }
		else if (room_list_number_of_exits == 0) { misleading_direction = 1; }
		
		var make_exits_more_misleading = get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY);
		while(make_exits_more_misleading && (room_list_number_of_exits+misleading_direction) <= 4 && (room_list_number_of_exits+misleading_direction) >= 1) {
			has_misleading_exits = true;
			make_exits_more_misleading = get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY);
			room_list_number_of_exits += misleading_direction;
		}
		
		switch(room_list_number_of_exits) {
			case 0: 
				room_list = controller.rooms_with_no_exits; 
				break;
			case 1: 
				room_list = controller.rooms_with_one_exit; 
				break;
			case 2: 
				room_list = controller.rooms_with_two_perpendicular_exits;
				if ((has_exit(directions.up) && has_exit(directions.down)) || 
					(has_exit(directions.right) && has_exit(directions.left))) { room_list = controller.rooms_with_two_opposite_exits; }
				break;
			case 3: 
				room_list = controller.rooms_with_three_exits; 
				break;
			case 4: 
				room_list = controller.rooms_with_four_exits; 
				break;
		}
		
		flip_horizontal = false;
		flip_vertical = false;
		rotate = noone;
		
		switch (number_of_exits) {
			case 0: 
			    flip_horizontal = rand1; 
			    flip_vertical = rand2;
				rotate = get_random_carindal_dir();
				break;
			case 1:
				flip_horizontal = rand1;
				flip_vertical = false;
				for (var dir = directions.up; dir < directions.stairs; dir += 1) {
					if (has_exit(dir)) { rotate = dir; break; }
				}
				break;
			case 2:
			    if (has_exit(directions.up) && has_exit(directions.down)) { flip_horizontal = rand1; flip_vertical = rand2; }
			    else if (has_exit(directions.right) && has_exit(directions.left)) { flip_horizontal = rand1; flip_vertical = rand2; rotate = (get_coin_flip()) ? directions.right : directions.left; }
			    else if (has_exit(directions.up) && has_exit(directions.right)) { flip_horizontal = false; flip_vertical = false; }
			    else if (has_exit(directions.up) && has_exit(directions.left)) { flip_horizontal = true; flip_vertical = false; }
			    else if (has_exit(directions.right) && has_exit(directions.down)) { flip_horizontal = false; flip_vertical = true; }
			    else if (has_exit(directions.left) && has_exit(directions.down)){  flip_horizontal = true; flip_vertical = true; }
				break;
			case 3:
				flip_horizontal = false;
				flip_vertical = rand1;
				for (var dir = directions.up; dir < directions.stairs; dir += 1) {
					if (!has_exit(dir)) { rotate = (dir+1 > 4) ? 0 : dir+1; break; }
				}
				break;
			case 4:
			    flip_horizontal = rand1; 
			    flip_vertical = rand2;
				rotate = get_random_carindal_dir();
				break;
		}
		
		// Don't spawn duplicate room references unless necessary
		array_shuffle_ext(room_list);
		for (var i = 0; i < array_length(room_list); i++;) {
			var prev_room_reference = room_reference;
			room_reference = room_list[i];

			// Force using a special room or not
			if (!spawn_special_room && array_contains(global.special_rooms, room_reference)) {
				if (prev_room_reference != -1) { room_reference = prev_room_reference; }
				continue;
			}
			else if (spawn_special_room && !array_contains(global.special_rooms, room_reference)) {
				if (prev_room_reference != -1) { room_reference = prev_room_reference; }
				continue;
			}
			else if (get_room_reference_object_count(obj_hall_of_mirrors) > 0 &&
					(has_misleading_exits ||
					!has_exit(directions.up) || 
					!has_exit(directions.down) || 
					!has_exit(directions.left) || 
					!has_exit(directions.right))) {
				if (prev_room_reference != -1) { room_reference = prev_room_reference; }
				continue;
			}
			
			// Enforce Having a lantern
			if (must_have_lantern && get_room_reference_object_count(obj_lantern) == 0) { 
				if (prev_room_reference != -1) { room_reference = prev_room_reference; }
				continue;
			}
			
			// If room reference hasn't been used yet, select this room reference
			if (!array_contains(controller.room_references, room_reference)) { break; }
		}
		
		//if (has_misleading_exits) { write_debug_message("Generated with misleading exits: " + room_get_name(room_reference)); }
		array_push(controller.room_references, room_reference);
		//room_reference = rm_four_exits_6969;//rm_four_exits_23;// TODO: CHANGE ROOM HERE FOR TESTING
	}
	
	/// @function					flip_room_contents_horizontally();
	function flip_room_contents_horizontally() {
		with obj_game_object {
		    if (object_index != obj_player) { x = room_width - x; }
		}
		with obj_placeholder {
			x = room_width - x;
		}
		with obj_exit_spot {
			if (exit_dir == directions.right || exit_dir == directions.left) { exit_dir = get_opposite_dir(exit_dir); }
		}
	}

	/// @function				flip_room_contents_vertically();
	function flip_room_contents_vertically() {
		with obj_game_object {
		    if (object_index != obj_player) { y = room_height - y; }
		}
		with obj_placeholder {
			y = room_height - y;
		}
		with obj_exit_spot {
			if (exit_dir == directions.up || exit_dir == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
		}
	}

	/// @function									rotate_room_contents_around_room_center(direction_to_face);
	/// @param		{direction}	direction_to_face	The direction in which the room should face once rotated
	function rotate_room_contents_around_room_center(direction_to_face) {
		var angle = direction_to_face * 90;
	
		with obj_game_object {
		    if (object_index != obj_player) { 
				image_angle = 0;
				var x_prev = x - room_width/2;
				var y_prev = y - room_height/2;
			
				x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
				y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
				if (!place_snapped(4, 4)) { move_snap(4, 4); }
			}
		}
		with obj_placeholder {
			image_angle = 0;
			var x_prev = x - room_width/2;
			var y_prev = y - room_height/2;
			
			x = ((x_prev * dcos(angle)) - (y_prev * dsin(angle))) + room_width/2;
			y = ((y_prev * dcos(angle)) + (x_prev * dsin(angle))) + room_height/2;
			if (!place_snapped(4, 4)) { move_snap(4, 4); }
		}
		with obj_exit_spot {
			if (direction_to_face == directions.right) { exit_dir = get_turn_right_dir(exit_dir); }
			else if (direction_to_face == directions.left) { exit_dir = get_turn_left_dir(exit_dir); }
			else if (direction_to_face == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
		}
	}
	
	/// @function								draw_room(x_pos, y_pos)
	/// @param		{real}	x_pos				The x position to draw this room at
	/// @param		{real}	y_pos				The y position to draw this room at
	function draw_room(x_pos, y_pos) {
		// Only draw the room if the given position is on screen
		if (x_pos < 0 || x_pos > room_width || y_pos < 0 || y_pos > room_height) { return false; }
		
		// Only draw the room if the room has been visited at least once, or game is in test mode
		var show_detailed_map = false, show_collectables = false, controller = global.controller, is_test_mode_on = global.is_test_mode;
		with (global.player) {
			show_detailed_map = (is_test_mode_on || is_carrying_item(obj_map));
			show_collectables = (is_test_mode_on || is_carrying_special_item(obj_map));
		}
		
		if (show_detailed_map || visited) {
			// Set up colors to draw this room with
			var fade_amount = 0; //distance_to_current_room / controller.MAX_MAP_DRAW_DISTANCE;
			var blink_frame = is_blink_frame();//modulo(global.game_manager.number_of_frames_since_game_began, 12) <= 5;
			var bg_color = global.bg_color;
			var white_color = merge_color(c_white, bg_color, fade_amount);
			var red_color = merge_color(global.gms_game_color, bg_color, fade_amount);
		
			// Darken the colors of unvisited rooms on the map
			if (!visited) {
				white_color = merge_color(white_color, bg_color, 0.66);
				red_color = merge_color(red_color, bg_color, 0.66);
			}
			
		    // Draw Room on Map
			var room_color = lit ? red_color : bg_color;
			var inverse_color = lit ? bg_color : red_color;
		    if (controller.current_room != self || !blink_frame) {
				draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.875, 0.875, 0, white_color, 1);
				draw_sprite_ext(spr_box, 0, x_pos, y_pos, 0.75, 0.75, 0, room_color, 1);
			}

		    // Draw Room's Exits on Map
			for (var dir = directions.up; dir < directions.stairs; dir++) {
				if (!has_exit(dir)) { continue; }
				
				var exit_color = bg_color;
				if (!blink_frame) {
					if (exits[dir].has_lock) { exit_color = red_color; }
					else if (exits[dir].has_closed_portcullis_for_room(controller.current_room)) { exit_color = (is_test_mode_on) ? c_fuchsia : red_color; }
					else if (exits[dir].has_illusion_walls > 0) { exit_color = (is_test_mode_on) ? c_teal : bg_color; }
				}

				var x_offset = 0, y_offset = 0, x_size = 0.25, y_size = 0.25;
				switch (dir) {
					case directions.up: { y_offset = -8; y_size += 0.125; break; } 
					case directions.right: { x_offset = 8; x_size += 0.125; break; } 
					case directions.down: { y_offset = 8; y_size += 0.125; break; } 
					case directions.left: { x_offset = -8; x_size += 0.125; break; } 
				}

			    if (has_visited_exit(dir) || show_detailed_map) { draw_sprite_ext(spr_box, 0, x_pos+x_offset, y_pos+y_offset, x_size, y_size, 0, exit_color, 1); }
			}
			
			// Draw room's map position objects
			for (var yy = 0; yy < 3; yy++) {
				for (var xx = 0; xx < 3; xx++) {
					// Check if any map positions exist at this part of the map and draw them if so
					var room_map_pos_array = instances_at_map_positions[xx][yy];
					if (array_length(room_map_pos_array) > 0) {
						// Get color of instance to draw
						var pos_color = -1, pos_sprite = spr_box, pos_image = 0, pos_scale = 0.125;
						for (var i = 0; i < array_length(room_map_pos_array); i++) { 
							var room_map_obj = room_map_pos_array[i];
				

							if (room_map_obj == obj_cross) {
								if (show_collectables) { pos_color = white_color; pos_sprite = spr_map_cross; pos_scale = 1; continue; }
							}
							else if (room_map_obj == obj_encased_heart || room_map_obj == obj_heart) {
								if (show_collectables) { 
									pos_image = (is_thump_frame()) ? 1 : 0;
									pos_color = inverse_color; 
									pos_sprite = spr_map_heart; 
									pos_scale = 1; 
									continue;
								}
							}
							else if (pos_sprite == spr_box) {
								if (room_map_obj == obj_stairs) {
									if (show_detailed_map || has_visited_exit(directions.stairs)) { pos_color = white_color; continue; }
								}
								else if (room_map_obj == obj_hole) { pos_color = white_color; continue; }
								else if (is_test_mode_on && has_locked_chest && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) { pos_color = c_aqua; continue; }
								else if (is_test_mode_on && has_key && ((chest_obj == obj_key && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) || room_map_obj == obj_key)) { pos_color = c_lime; continue; }
								else if (is_test_mode_on && has_hidden_chest && (room_map_obj == obj_chest || room_map_obj == obj_hidden_chest)) { pos_color = c_yellow; continue; }
								else if (pos_color == -1 && show_detailed_map && (show_collectables || room_map_obj != obj_hidden_chest)) { pos_color = inverse_color; }
							}
						}
						
						// Draw obj at pos
						if (pos_color != -1) {
							var x_offset = 0, y_offset = 0;
							if (xx == 0) { x_offset -= 3; }
							else if (xx == 2) { x_offset += 3; }
							if (yy == 0) { y_offset -= 3; }
							else if (yy == 2) { y_offset += 3; }
							draw_sprite_ext(pos_sprite, pos_image, x_pos+x_offset, y_pos+y_offset, pos_scale, pos_scale, 0, pos_color, 1); 
						}
					}
				}
			}
		
			// Draw collectables if the map is special
		    if (show_collectables && has_collectables && !blink_frame) {
				draw_sprite_ext(spr_collectable, 0, x_pos, y_pos, 1, 1, 0, white_color, 1); 
			}
    
		    // Draw distance information if testing
		    if (is_test_mode_on && keyboard_check(vk_f1)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(x_pos, y_pos, string_hash_to_newline(string(distance_to_start)));
		    }
			
			// Draw difficulty information if testing
		    if (is_test_mode_on && keyboard_check(vk_f2)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(x_pos, y_pos, string_hash_to_newline(string(room_reference_difficulty_score)));
		    }
			
		}
		
		return true;
	}
}

/// @function								mark_room_for_grid_update();
function mark_current_room_for_grid_update() {
	global.controller.grid_update_timer = 1;
}

function get_object_count_for_room_reference(room_reference, obj) {
	// Return the cached value if one exists
	static cache = ds_map_create();
	if (!ds_map_exists(cache, room_reference)) { cache[? room_reference] = ds_map_create(); }
	var room_cache = cache[? room_reference];
	if (ds_map_exists(room_cache, obj)) { return room_cache[? obj]; }
		
	// Return 0 if the file fails to open
	var reference_instances = instances_for_room_reference(room_reference);
	if (reference_instances == -1) { return 0; }
		
	// Return the count in the file if it opens and save it to the cache
	var count = 0;
	for (var i = 0; i < array_length(reference_instances); i++) {
	    if (asset_get_index(reference_instances[i].name) == obj) { count += 1; }
	}
	room_cache[? obj] = count;
	return count;
}

function create_game_map() {
	var created_cardinal_exits = 0, target_rooms = MINIMUM_NUMBER_OF_ROOMS;// + irandom(MAX_NUMBER_OF_ROOMS - MINIMUM_NUMBER_OF_ROOMS);
	
	// Set up initial game room and game rooms array
	game_rooms = array_create(0);
	var initial_room = new GameRoom(0, 0);
	initial_room.assign_room_ref(false, false);
	array_push(game_rooms, initial_room);
	
	// Add rooms to map until target is reached
	while (array_length(game_rooms) < target_rooms) {
		var new_exit_dir = -1;
		array_shuffle_ext(game_rooms);
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_connected_room_for = game_rooms[i];
			var new_exit_dir = room_to_create_connected_room_for.create_connected_room();
			if (new_exit_dir != -1) { 
				if (new_exit_dir != directions.stairs) { created_cardinal_exits += 1; }
				break; 
			}
		}
		
		if (new_exit_dir == -1) {
			// SHOULD NEVER REACH THIS POINT
			write_debug_message("Couldn't create connected room for any room.", debug_message_level.warning);
			return -1;
		}
	}
	
	// Add random additional cardinal exits to rooms
	while ((created_cardinal_exits*2)/(target_rooms) < AVERAGE_NUMBER_OF_ROOM_EXITS) {
		created_cardinal_exits += 1;
		array_shuffle_ext(game_rooms);
		var connected_room = -1;
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_exit_for = game_rooms[i];
			connected_room = room_to_create_exit_for.connect_adjacent_room();
			if (connected_room != -1) { break; }
		}		
		if (connected_room == -1) {
			// SHOULD NEVER REACH THIS POINT
			write_debug_message("Couldn't create new exit for any room", debug_message_level.warning);
			return -1;
			break;
		}
	}
}

/// @function									setup_start_and_end_rooms();
function setup_start_and_end_rooms() {
	// Choose random start room
	array_shuffle_ext(game_rooms);
	start_room = -1;
	for(var i = 0; i < array_length(game_rooms); i++) {
		var next_room = game_rooms[i];
		if (!next_room.has_exit(directions.stairs) && (global.is_test_mode || !next_room.is_special_room)) { 
			start_room = next_room; break; 
		}
	}
	if (start_room == -1) {
		// SHOULD NEVER REACH THIS POINT
		write_debug_message("Couldn't pick a start room because all rooms had stairs.", debug_message_level.warning);
		return -1;
	}
	
	// Calculate distance to start room for each other room
	start_room.calculate_distance_to_connected_rooms(0);
	
	// Choose random end_room from among the furthest away
	array_sort(game_rooms, function(elm1, elm2)
	{
		if (elm1.distance_to_start == elm2.distance_to_start) { return (get_coin_flip() ? 1 : -1); }
		else { return elm2.distance_to_start - elm1.distance_to_start; }
	});
	
	// Set up start and end rooms
	heart_room = game_rooms[0];
	heart_room.add_collectables();
	heart_room.stairs_spot_obj = obj_encased_heart;
	heart_room.is_heart_room = true;
	start_room.stairs_spot_obj = obj_cross;
	start_room.is_start_room = true;
	current_room = start_room;
}

/// @function									add_rooms_to_reach_target_difficulty();
function add_rooms_to_reach_target_difficulty() {
	var total_difficulty = 0, added_rooms = 0, target_difficulty = AVERAGE_ROOM_DIFFICULTY * MINIMUM_NUMBER_OF_ROOMS;
	for (var i = 0; i < array_length(game_rooms); i++;) {
		var next_room = game_rooms[i];
		with (next_room) {
			update_game_room_difficulty();
			total_difficulty += room_reference_difficulty_score;
		}
	}
		
	while (total_difficulty < target_difficulty && array_length(game_rooms) < MAX_NUMBER_OF_ROOMS) {
		var new_exit_dir = -1;
		array_shuffle_ext(game_rooms);
		for (var i = 0; i < array_length(game_rooms); i++;) {
			var room_to_create_connected_room_for = game_rooms[i];
			// Skip adding exits to rooms with portcullis
			if (room_to_create_connected_room_for.has_portcullis_button) { continue; }
			var new_exit_dir = room_to_create_connected_room_for.create_connected_room();
			if (new_exit_dir != -1) { break; }
		}
		
		// Update difficulty tally
		total_difficulty= 0;
		added_rooms += 1;
		for (var i = 0; i < array_length(game_rooms); i++;) { total_difficulty += game_rooms[i].room_reference_difficulty_score; }
		
		if (new_exit_dir == -1) {
			// SHOULD NEVER REACH THIS POINT
			write_debug_message("Couldn't create connected room for any room.", debug_message_level.warning);
			return -1;
		}
	}
}

/// @function									get_earlier_room_without_key(target_dist);
/// @param		{real}	target_dist				The maximum distance from start of the keyless room to return
function get_earlier_room_without_key(target_dist) {
	var possible_rooms = array_create(0);
	for (var pos = 0; pos < array_length(game_rooms); pos++;) {
		var next_room = game_rooms[pos];
		if (!next_room.has_key && next_room.distance_to_start < target_dist && (next_room != start_room || target_dist <= 1)) { array_push(possible_rooms, next_room); }
	}
	if (array_length(possible_rooms) == 0) { return -1; }
	
	return array_shuffle(possible_rooms)[0];
}

/// @function									create_locked_exits_and_keys();
function create_locked_exits_and_keys() {
	// Add keys and locks to rooms
	var exits_to_create_lock_and_key_for = array_create(0), attempted_exits = array_create(0), extra_locks = -1;
	
	for (var pos = 0; pos < array_length(game_rooms); pos++;) {
		var next_room = game_rooms[pos], is_heart_room_exit = (next_room == heart_room), is_start_room_exit = (next_room == start_room);
		
		// Figure out which exits to lock
		var possible_directions = game_rooms[pos].get_connected_room_directions(false);
		for (var i = 0; i < array_length(possible_directions); i++;) {
			var dir = possible_directions[i], next_exit = next_room.exits[dir];
			
			// Skip stairs and previously visited exits since you can't lock those
			if (dir == directions.stairs || array_contains(attempted_exits, next_exit)) { continue; }
			array_push(attempted_exits, next_exit);
			
			// Check to see if this exit should be locked
			var connected_room = next_exit.get_connected_room(next_room);
			if (connected_room == heart_room) { is_heart_room_exit = true; }
			if (connected_room == start_room || next_room.has_hall_of_mirrors || connected_room.has_hall_of_mirrors) { is_start_room_exit = true; }
			if (!is_start_room_exit && (is_heart_room_exit || get_random_chance_out_of(LOCKED_DOOR_PROBABILITY/2))) {
				// Set this exit up to be locked
				if (is_heart_room_exit) { extra_locks += 1; }
				array_push(exits_to_create_lock_and_key_for, [next_room, dir]);
			}
		}
		
		// Figure out which chests are locked
		if (next_room.has_locked_chest && next_room.chest_obj != obj_key && next_room.chest_obj != obj_bomb) { // TODO: AFTER RED STAFF UPDATE && (!next_room.has_special_item || next_room.chest_obj != obj_staff))) { 
			array_push(exits_to_create_lock_and_key_for, [next_room, -1]); 
		}
	}
	if (extra_locks < 0) { extra_locks = 0; }
	
	// Sort the keys and locks to create by ascending distance from start room
	array_sort(exits_to_create_lock_and_key_for, function(elm1, elm2)
	{
		var dist1 = elm1[0].distance_to_start, dist2 = elm2[0].distance_to_start;
		return (dist1 == dist2) ? get_coin_flip() : dist1 - dist2;
	});
		
	// Create keys and lock exits
	var extra_lock_threshold = array_length(exits_to_create_lock_and_key_for)-extra_locks;
	for(var i = 0; i < array_length(exits_to_create_lock_and_key_for); i++;) {
		var just_lock = (i >= extra_lock_threshold), next_combo = exits_to_create_lock_and_key_for[i], room_to_lock = next_combo[0], lock_dir = next_combo[1];
		
		// If we are only locking or we have found a room to add a key to
		var key_room = get_earlier_room_without_key(room_to_lock.distance_to_start);
		if (just_lock || key_room != -1) {
			// Create key
			var new_key_created = (just_lock || key_room.add_key());
			if (new_key_created) {
				// Lock exit unless key is for a locked chest
				if (lock_dir != -1) { room_to_lock.exits[lock_dir].lock(); }
			}
			else { key_room = -1; }
		}
		
		// If key room couldn't be found or couldn't be locked
		if (key_room == -1) {
			// Unlock chest if key was for a locked chest
			if (lock_dir == -1) { room_to_lock.has_locked_chest = false; }
			// Skip locking any exit
			write_debug_message("Couldn't add key for room at (" + string(room_to_lock.virtual_x) + ", " + string(room_to_lock.virtual_y) + ") with dist: " + string(room_to_lock.distance_to_start), debug_message_level.warning); 
		}
	}
}

/// @function									instances_for_room_reference()
function instances_for_room_reference(room_reference) {
	static cache = ds_map_create();
	if (ds_map_exists(cache, room_reference)) { return cache[? room_reference]; }
	
	var filename = room_get_name(room_reference) + ".json";
	var file = file_text_open_read(filename);
	if (file == -1) {
		write_debug_message("Failed to open file for instances_for_room_reference.", debug_message_level.warning);
		return -1;
	}
	
	var file_difficulty_content = file_text_read_string(file);
	file_text_readln(file);
	var file_instances_content = file_text_read_string(file);
	var decoded_content = json_parse(file_instances_content);          
	file_text_close(file);
	
	cache[? room_reference] = decoded_content;
	return decoded_content;
}

/// @function								difficulty_for_room_reference();
function difficulty_for_room_reference(room_reference) {
	// This difficulty is added to the room reference file by the ruby script.
	// It is used to determine if the room layout should be included at a given difficulty,
	// without considering any extra randomly determined difficulty additions.
	var filename = room_get_name(room_reference) + ".json";
	var file = file_text_open_read(filename);
	if (file == -1) {
		write_debug_message("Failed to open file for difficulty_for_room_reference.", debug_message_level.warning);
		return -1;
	}
	
	var file_difficulty_content = file_text_read_string(file);
	file_text_readln(file);
	var decoded_content = string_digits(file_difficulty_content);          
	file_text_close(file);
	return real(decoded_content);
}

/// @function									get_skeleton_type();
function get_skeleton_type(include_basic_skeleton = true) {
	// Determine range to use based on skeleton inclusion
	var rand_range_max = 100;
	if (!include_basic_skeleton) {
		switch (global.difficulty) {
			case difficulties.easy: { rand_range_max = 3; break; }
			case difficulties.medium: { rand_range_max = 16; break; }
			case difficulties.hard: { rand_range_max = 40; break; }
			case difficulties.very_hard: { rand_range_max = 80; break; }
		}
	}
	
	// Determine what to spawn in this skeleton spot
	var rand = irandom_range(1, rand_range_max), skeleton_type = obj_skeleton;
	switch (global.difficulty) {
		case difficulties.DO_NOT_USE: { break; }
		case difficulties.easy: {
			if rand <= 3 { skeleton_type = obj_cockroach; }
			break;
		}
		case difficulties.medium: {
			if rand <= 6 { skeleton_type = obj_cockroach; }
			else if rand <= 12 { skeleton_type = obj_fast_skeleton; }
			else if rand <= 16 { skeleton_type = obj_fat_skeleton; }
			//else if rand <= 20 { skeleton_type = obj_cultist; }
			break;
		}
		case difficulties.hard: {
			if rand <= 12 { skeleton_type = obj_cockroach; }
			else if rand <= 20 { skeleton_type = obj_fat_skeleton; }
			else if rand <= 28 { skeleton_type = obj_fast_skeleton; }
			else if rand <= 34 { skeleton_type = obj_cultist; }
			else if rand <= 40 { skeleton_type = obj_fire_skeleton; }
			//else if rand <= 42 { skeleton_type = obj_snake; }
			break;
		}
		case difficulties.very_hard: {
			if rand <= 15 { skeleton_type = obj_cockroach; }
			else if rand <= 35 { skeleton_type = obj_fat_skeleton; }
			else if rand <= 50 { skeleton_type = obj_fast_skeleton; }
			else if rand <= 62 { skeleton_type = obj_cultist; }
			else if rand <= 75 { skeleton_type = obj_fire_skeleton; }
			else if rand <= 80 { skeleton_type = obj_snake; }
			break;
		}
	}
	return skeleton_type;
}