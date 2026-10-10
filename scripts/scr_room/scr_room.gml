/// @function GameRoom(_given_x, _given_y)
/// @description One room of the map: its cell on the map's grid and its exits, the layout it's built from and the
///	content rolled for it, what generation decorates it with, and its instances and path grids during play
/// @param {real} _given_x Its grid column
/// @param {real} _given_y Its grid row
function GameRoom(_given_x, _given_y) constructor {
	// Map Generation Values: its grid cell, its exit in each direction (see directions) or -1 for none, and how many
	// rooms it is from the start
	virtual_x = _given_x;
	virtual_y = _given_y;
	exits = [-1, -1, -1, -1, -1];
	distance_to_start = 9999;
	
	// Instance Positioning Values
	room_reference = -1;
	room_reference_difficulty_score = 0;
	
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
	has_portcullis_trap = false;
	has_hall_of_mirrors = false;
	is_special_room = false;
	is_start_room = false;
	is_heart_room = false;
	is_guaranteed_lit_room = false;			// Generation lit it so the map has at least one lit room (see is_lit)
	
	// What map generation decided for it
	layout = undefined;						// The cached layout this room is built from (see RoomLayout)
	key_in_chest = false;					// Its key, or the bomb standing in for it, is in a chest instead of on a key spot
	chest_on_stairs_spot = false;			// stairs_spot_obj goes on the stairs spot instead of the chest spot
	button_on_stairs_spot = false;			// The portcullis button goes on the stairs spot instead of a collectable spot
	button_spot = -1;						// Which collectable spot, in layout file order, the portcullis button takes
	key_spot = -1;							// Which collectable spot, in layout file order, the floor key takes
	mapgen_index = -1;						// Its place in its map's rooms, which the lock search's room bitmasks use (set by GameMap)
	special_room_type = undefined;			// The special room type it's reserved for, if it's a special room
	unlocked_chests_bitmask_index = -1;		// Its locked chest's bit in the lock search's chest bitmasks, or -1 if the chest doesn't matter to it
	mapgen_needs_layout = true;				// Its cardinal exits changed since its last layout pick
	
	// How likely the player is to arrive holding each counter, and to have light here
	chance_holding_staff = 0;
	chance_holding_sword = 0;
	chance_holding_special_sword = 0;
	chance_of_light = 0;
	
	// Its layout's orientation, so the layout's openings face its cardinal exits
	flip_horizontal = false;
	flip_vertical = false;
	rotate = noone;
	
	// The content rolled for its layout, along with lit above. Generation never edits it after rolling it; the room's
	// role decides which of it spawns, and apply_roles_to_content writes that into these fields once the map is finished
	// NOTE: This is the same, statistically, as if we only roll for them after deciding if the room is eligible
	has_eyes = false;
	has_phantom = false;
	has_floater = false;
	has_moving_collectable = false;
	replaced_column_fountain_count = 0;
	replaced_statue_fountain_count = 0;
	living_block_count = 0;
	initial_nose_count = 0;
	initial_fire_skeleton_count = 0;
	initial_mouth_count = 0;
	skeleton_types = [];
	mirror_directions = [];
	mirror_count = 0;
	
	// Room Content Values
	instances = [];
	solid_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	lava_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	empty_path_grid = mp_grid_create(0, 0, room_width/GRID_SIZE, room_height/GRID_SIZE, GRID_SIZE, GRID_SIZE);
	instances_at_map_positions = [[[], [], []], [[], [], []], [[], [], []]];
	
	/// @function destroy()
	/// @description Frees the room's path grids, once the room will never be built again
	function destroy() {
		// The mp_grids MUST be cleaned up manually or this will cause a memory leak
		mp_grid_destroy(solid_path_grid);
		mp_grid_destroy(lava_path_grid);
		mp_grid_destroy(empty_path_grid);
	}
	
	// =========
	// Map generation checks (see GameMap): what generation asks about this room. None of these change the room
	// =========
	
	/// @function can_become_special_room()
	/// @description Whether the room can be reserved as a special room
	/// @returns {bool}
	function can_become_special_room() {
		return !is_special_room && !has_exit(directions.stairs);
	}
	
	/// @function can_be_start()
	/// @description Whether the room can be the start: never a room with stairs or a special room
	/// @returns {bool}
	function can_be_start() {
		return !has_exit(directions.stairs) && !is_special_room;
	}

	/// @function can_be_heart(_start)
	/// @description Whether the room can be the heart for a given start: never the start itself or a special room, and
	///	never linked by a cardinal exit to the start or a hall of mirrors; stairs into it are fine
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
	/// @description Whether the room may still gain exits. A room only reached by stairs never gets a cardinal exit,
	///	and a special room's exits stay fixed once it's reserved, so its special room type's layouts keep fitting.
	/// @returns {bool}
	function can_gain_exits() {
		return !has_no_cardinal_exits && !is_special_room;
	}

	/// @function has_opposite_exits()
	/// @description Whether the room has cardinal exits on two opposite sides
	/// @returns {bool}
	function has_opposite_exits() {
		return (has_exit(directions.up) && has_exit(directions.down)) || (has_exit(directions.left) && has_exit(directions.right));
	}

	/// @function get_exit_type()
	/// @description The layout exit kind matching the room's real cardinal exits
	/// @returns {real} A layout_exit_types kind
	function get_exit_type() {
		return get_exit_type_for_count(get_cardinal_exits_count());
	}

	/// @function get_exit_type_for_count(_exit_count)
	/// @description The layout exit kind for a number of cardinal exits. For two exits, it uses whether the room's own
	///	cardinal exits are on opposite sides.
	/// @param {real} _exit_count How many cardinal exits, 0 to 4
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

	/// @function can_have_chest()
	/// @description Whether the room is allowed to have a chest added to it: not the start or heart room, with nothing on
	///	its stairs spot yet
	/// @returns {bool}
	function can_have_chest() {
		return (!is_start_room && !is_heart_room && stairs_spot_obj == -1);
	}

	/// @function can_have_special_item()
	/// @description Whether the room is allowed to have a special item added to it: it has none yet, and it is at least
	///	two rooms from the start
	/// @returns {bool}
	function can_have_special_item() {
		return (!has_special_item && distance_to_start >= 2);
	}
	
	/// @function can_have_special_exit_types()
	/// @description Whether the room can have illusion walls, portcullis traps and plain doors: it isn't only reached by
	///	stairs, isn't the start or heart room, and isn't a hall of mirrors or linked to one
	/// @returns {bool}
	function can_have_special_exit_types() {
		return (!has_no_cardinal_exits && !is_start_room && !is_heart_room && !is_connected_to_hall_of_mirrors());
	};
	
	/// @function can_have_portcullis_trap()
	/// @description Whether the room can become a portcullis trap room: it can have special exit types, none of its
	///	cardinal exits has a door or illusion walls or leads to another trap room, and it has a free spot for the button
	/// @returns {bool}
	function can_have_portcullis_trap() {
		if (!can_have_special_exit_types()) { return false; }
		
		// Check each of the room's cardinal exits
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			// Skip if there is no exit in this direction
			var _exit = exits[_dir];
			if (_exit == -1) { continue; }
			
			// Return false if any exit already has a door or illusion walls, or leads to another portcullis trap room
			if (_exit.has_door || _exit.has_illusion_walls > 0 || _exit.get_connected_room(self).has_portcullis_trap) { return false; }
		}
		
		// Return whether there is at least one spot for the button
		return array_length(get_portcullis_button_spots()) > 0;
	};

	/// @function has_chest()
	/// @description Whether the room holds a chest, hidden or not
	/// @returns {bool}
	function has_chest() {
		return stairs_spot_obj == obj_chest || stairs_spot_obj == obj_hidden_chest;
	}
	
	/// @function has_regular_item_chest()
	/// @description Whether the room has a chest with a regular item: not a special item, not a trap, and not a key or
	///	bomb placed for the locks
	/// @returns {bool}
	function has_regular_item_chest() {
		return (has_chest() && !has_special_item && !key_in_chest && !has_trap_chest());
	}

	/// @function has_basic_chest()
	/// @description Whether the room holds a visible chest that is neither locked nor holding a special item
	/// @returns {bool}
	function has_basic_chest() {
		return stairs_spot_obj == obj_chest && !has_locked_chest && !has_special_item;
	}

	/// @function has_trap_chest()
	/// @description Whether the room's chest holds a statue or fountain trap instead of an item
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
		if (is_stairs_spot_free() && layout.stairs_spot_is_clear) { array_push(_possible_spots, -1); }

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
	
	/// @function get_reachable_rooms_bitmask()
	/// @description Every room the player can reach from this one without opening a lock, through cardinal exits and
	///	stairs
	/// @returns {real} Bitmask of those rooms, this one included, by mapgen_index
	function get_reachable_rooms_bitmask() {
		// For each room in the queue, add to the queue all new rooms reachable from that room
		var _queue = [self], _reached_rooms_bitmask = 0;
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

	/// @function is_lit()
	/// @description Whether the room starts with its lanterns lit: it rolled lit, or generation lit it so the map has a lit room
	/// @returns {bool}
	function is_lit() {
		return lit || is_guaranteed_lit_room;
	}

	/// @function can_light_torch()
	/// @description Whether a torch can be lit in the room: its lanterns start lit, or something in it shoots fireballs that
	///	light a torch dropped in their way
	/// @returns {bool}
	function can_light_torch() {
		return is_lit() || (count_hazards_with_tags(get_hazard_counts(), hazard_tags.lights_torches) > 0);
	}

	/// @function spawns_phantom()
	/// @description Whether the room's rolled phantom spawns: never in the start room, a lit room or a portcullis trap room
	/// @returns {bool}
	function spawns_phantom() {
		return has_phantom && !is_start_room && !is_lit() && !has_portcullis_trap;
	}

	/// @function spawns_floater()
	/// @description Whether the room's rolled floater spawns: never in the start room or a portcullis trap room
	/// @returns {bool}
	function spawns_floater() {
		return has_floater && !is_start_room && !has_portcullis_trap;
	}

	/// @function get_spawned_skeleton_types()
	/// @description What spawns on the room's skeleton spots. The start room doesn't spawn its rolled dangers, so each
	///	dangerous type rolled for one of its spots, rolled eyes included, spawns as a basic skeleton instead.
	/// @returns {array} One object per skeleton spot; a new array for the start room, so the rolled types stay as rolled
	function get_spawned_skeleton_types() {
		if (!is_start_room) { return skeleton_types; }

		var _spawned_types = [];
		for (var _i = 0; _i < array_length(skeleton_types); _i++) {
			var _skeleton_type = skeleton_types[_i];
			var _is_dangerous = (_skeleton_type != obj_skeleton && _skeleton_type != obj_fast_skeleton && _skeleton_type != obj_cockroach && _skeleton_type != obj_fat_skeleton);
			array_push(_spawned_types, _is_dangerous ? obj_skeleton : _skeleton_type);
		}

		return _spawned_types;
	}

	/// @function get_hazard_counts([_with_role])
	/// @description How many of each hazard the room holds, from the layout and from spawned hazards. With its role, it also
	///	counts what the room's role and decorations change: the start room spawns none of its rolled dangers, lit and trap
	///	rooms no phantom, and chests and collectables add their own.
	/// @param {bool} [_with_role] False to count the rolled content just as it was rolled, while generation is still rolling it
	/// @returns {struct}
	function get_hazard_counts(_with_role = true) {
		var _counts = hazard_counts_copy(layout.hazard_counts);
		
		// Fill in what spawns on the skeleton spots
		var _skeleton_types = _with_role ? get_spawned_skeleton_types() : skeleton_types;
		for (var _i = 0; _i < array_length(_skeleton_types); _i++) {
			hazard_count_add(_counts, object_get_name(_skeleton_types[_i]), 1);
		}
		
		// Adjust counts based on what has been spawned. A fountain takes its statue's place, but a block that comes alive still
		// counts on its spot, since it can still be pushed. The extra mouths higher difficulties add to each placed one aren't counted
		if (!_with_role || !is_start_room) {
			hazard_count_add(_counts, "obj_fountain", replaced_column_fountain_count + replaced_statue_fountain_count);
			hazard_count_add(_counts, "obj_statue", -replaced_statue_fountain_count);
			hazard_count_add(_counts, "obj_living_block", living_block_count);
			hazard_count_add(_counts, "obj_nose", initial_nose_count);
			hazard_count_add(_counts, "obj_fire_skeleton", initial_fire_skeleton_count); // These are ones spawned in lava, in addition to any skeleton spots above
		}
		hazard_count_add(_counts, "obj_phantom", (((_with_role) ? spawns_phantom() : has_phantom) ? 1 : 0));
		hazard_count_add(_counts, "obj_floater", (((_with_role) ? spawns_floater() : has_floater) ? 1 : 0));
		if (_with_role) {
			hazard_count_add(_counts, "obj_chest", ((has_trap_chest()) ? 1 : 0));
			hazard_count_add(_counts, "obj_collectable", (((has_moving_collectable && has_collectables)) ? 1 : 0));
		}
		
		// Return the modified counts
		return _counts;
	}
	
	/// @function can_have_hazard_with_eyes(_hazard_name)
	/// @description Whether a hazard may be rolled for the room when it already has eyes
	/// @param {string} _hazard_name The hazard's name in the difficulty score table
	/// @returns {bool}
	function can_have_hazard_with_eyes(_hazard_name) {
		return !has_eyes || !hazard_has_tag(_hazard_name, TARGETS_PLAYER_TAGS);
	}
 
	/// @function get_floor_item_count()
	/// @description How many items lie on the room's floor for hands to come for: its key, unless the key is in a chest
	/// @returns {real}
	function get_floor_item_count() {
		return (has_key && !key_in_chest) ? 1 : 0;
	}
 
	/// @function get_potential_difficulty_score(_counts)
	/// @description The room's difficulty score for some hazard counts, without time. The counts hold what the layout spawns
	///	for sure and what generation actually rolled into the room, scored together since hazards make each other worse,
	///	and what spawns into it during play is added on average (see get_mid_game_spawns). Then the rest of the room counts:
	///	its collectables, its trap and its chest's item.
	/// @param {struct} _counts The hazard counts to use for this difficulty score
	/// @returns {real}
	function get_potential_difficulty_score(_counts) {
		var _difficulty_score = get_difficulty_score_with_spawns(_counts, get_mid_game_spawns(_counts, layout, get_floor_item_count()), self);
 
		// Collecting everything crosses the whole room, not just the way to one objective
		if (has_collectables) { _difficulty_score *= COLLECTABLES_EXPOSURE; }
 
		// Shut in until the button is pressed. One button opens every exit, so it counts once
		if (has_portcullis_trap) { _difficulty_score += get_difficulty_score_for_danger_level(PORTCULLIS_TRAP_DANGER); }
 
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
	/// @description The room's difficulty score as it is now: its hazards, with its role and decorations
	/// @returns {real}
	function get_current_difficulty_score() {
		return get_potential_difficulty_score(get_hazard_counts());
	}
 
	/// @function would_exceed_max_difficulty(_hazard_name, [_replaced_hazard_name])
	/// @description Whether one more of a hazard would take the threats rolled into the room past ROOM_DIFFICULTY_SCORE_MAX,
	///	so generation can skip that roll. What spawns into the room during play counts too, on average. The room is scored
	///	as a player holding nothing meets it, with light only if it rolled lit, and with no key on its floor: chests, keys
	///	and torches move between generation passes, but what's rolled into a room stays.
	/// @param {string} _hazard_name The hazard's name in the table
	/// @param {string} [_replaced_hazard_name] A hazard the new one takes the place of, like a skeleton spot's basic skeleton
	/// @returns {bool}
	function would_exceed_max_difficulty(_hazard_name, _replaced_hazard_name = undefined) {
		var _counts = get_hazard_counts(false);
		hazard_count_add(_counts, _hazard_name, 1);
		if (!is_undefined(_replaced_hazard_name)) { hazard_count_add(_counts, _replaced_hazard_name, -1); }
		
		return get_difficulty_score_with_spawns(_counts, get_mid_game_spawns(_counts, layout, 0), undefined, lit) > ROOM_DIFFICULTY_SCORE_MAX;
	}
 
	/// @function get_time_score()
	/// @description How much time the room's hazards cost, with what spawns into it during play on average: 0 for none,
	///	and about 1 for each very significant hold-up, like solving a special room's quest.
	/// @returns {real}
	function get_time_score() {
		var _counts = get_hazard_counts();
		var _time = get_time_score_with_spawns(_counts, get_mid_game_spawns(_counts, layout, get_floor_item_count()));
		if (spawns_phantom()) { _time += PHANTOM_TIME_PER_LANTERN * layout.get_object_count("obj_lantern"); } // Lanterns aren't in the difficulty score table
		return _time;
	}
 
	/// @function get_walk_entrances()
	/// @description The walk points a visit can start and end at: the layout's open sides, which the layout's
	///	orientation turned to face the room's real exits, and the stairs spot when the room has stairs or no open side.
	/// @returns {array} Walk point numbers
	function get_walk_entrances() {
		layout.ensure_walking();
		var _entrances = [];
		for (var _i = 0; _i < layout.walk_entrance_count; _i++) { array_push(_entrances, _i); }
		if ((has_exit(directions.stairs) || array_length(_entrances) == 0) && layout.walk_stairs_point >= 0) { array_push(_entrances, layout.walk_stairs_point); }
		return _entrances;
	}
 
	/// @function add_walk_target(_targets, _point)
	/// @description Adds a walk point to a list of targets, once
	/// @param {array} _targets The targets so far
	/// @param {real} _point A walk point number, or -1 for none
	function add_walk_target(_targets, _point) {
		if (_point >= 0 && !array_contains(_targets, _point)) { array_push(_targets, _point); }
	}
 
	/// @function get_walk_targets()
	/// @description The walk points a player must visit in the room: its visible chest or the heart, its key on the
	///	floor, its collectables, and its portcullis button, or every spot the button could be on while the room is dark
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
		if (has_portcullis_trap) {
			var _spots = is_lit() ? [button_on_stairs_spot ? -1 : button_spot] : get_portcullis_button_spots();
			for (var _j = 0; _j < array_length(_spots); _j++) {
				add_walk_target(_targets, (_spots[_j] == -1) ? layout.walk_stairs_point : layout.walk_collectable_points[_spots[_j]]);
			}
		}
		return _targets;
	}
 
	/// @function get_walk_route_steps(_from, _to, _targets)
	/// @description Steps from one walk point to another past every target, taking the nearest one next
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
	/// @description Steps a careful player walks in one visit: in by one entrance, past every target, and
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
	/// @description How much the room's hazards slow walking: 1, plus CAUTION_PER_DANGER_POINT for each
	///	point of their danger, what spawns during play included. Only the hazards count: the room's other scoring, like the
	///	reward for its chest's item, doesn't change how carefully it's walked.
	/// @returns {real}
	function get_caution_factor() {
		var _counts = get_hazard_counts();
		return 1 + CAUTION_PER_DANGER_POINT * max(0, get_difficulty_score_with_spawns(_counts, get_mid_game_spawns(_counts, layout, get_floor_item_count()), self));
	}
 
	/// @function get_crossing_time()
	/// @description Seconds to pass through the room with nothing to do in it, for trips through the map
	/// @returns {real}
	function get_crossing_time() {
		return ROOM_ENTRY_TIME + get_walk_steps([]) / PLAYER_STEPS_PER_SECOND * get_caution_factor();
	}
 
	/// @function get_time_needed()
	/// @description Seconds a careful novice needs for one visit: a moment on entering, the walk through
	///	the room slowed by its danger, and the hold-ups its hazards cause, like freezing for eyes or luring ears.
	/// @returns {real}
	function get_time_needed() {
		var _walk = get_walk_steps(get_walk_targets()) / PLAYER_STEPS_PER_SECOND;
		return ROOM_ENTRY_TIME + _walk * get_caution_factor() + HAZARD_FULL_TIME * get_time_score();
	}
 
	/// @function get_time_provided()
	/// @description The room's share of the run's time: the time it needs, times the difficulty's
	///	allowance. Trips between rooms are added once for the whole map (GameMap.get_backtracking_time).
	/// @returns {real} Seconds
	function get_time_provided() {
		return TIME_ALLOWANCE * get_time_needed();
	}

	// ==========
	// Map generation changes (see GameMap): what generation does to this room on its own
	// ==========
	
	/// @function assign_layout(_layout)
	/// @description Gives the room a layout: sets its room asset, its lanterns and its hall of mirrors from the layout,
	///	and marks it as no longer needing a layout
	/// @param {RoomLayout} _layout The layout
	function assign_layout(_layout) {
		layout = _layout;
		room_reference = layout.room_reference;
		has_lanterns = layout.has_lanterns;
		has_hall_of_mirrors = layout.has_hall_of_mirrors;
		mapgen_needs_layout = false;
	}
	
	/// @function determine_layout_exit_type()
	/// @description Picks the exit kind of the layouts the room can use: usually the kind of its real cardinal exits,
	///	but sometimes one with more or fewer openings, which makes its exits misleading
	/// @returns {real} A layout_exit_types kind
	function determine_layout_exit_type() {
		// Start with the real exit count for this room
		var _exit_count = get_cardinal_exits_count();
		
		if (get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) {
			// Pick whether the layout shows more or fewer exits than the room has
			var _step = get_coin_flip() ? 1 : -1;
			if (_exit_count == 0) { _step = 1; }
			if (_exit_count == 4) { _step = -1; }
			
			// Keep adding or removing exits, for a chance to be even more misleading
			while (_exit_count + _step >= 1 && _exit_count + _step <= 4) {
				_exit_count += _step;
				if (!get_random_chance_out_of(MISLEADING_EXITS_PROBABILITY)) { break; }
			}
		}
		
		// Return the exit kind for that many exits
		return get_exit_type_for_count(_exit_count);
	}

	/// @function determine_layout_orientation()
	/// @description Flips the room's layout at random, then picks a random rotation among those that put the most of its
	///	openings on the room's real cardinal exits
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
	
		// Keep the rotations that put the most openings on real cardinal exits, and pick one at random
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
	/// @description Rolls the random content for the room's layout, straight onto the room. It's rolled once per layout
	///	pick and never edited afterwards; the room's role decides which of it spawns. Any roll that would take the room past
	///	ROOM_DIFFICULTY_SCORE_MAX is skipped (see would_exceed_max_difficulty), so each one is checked against what the
	///	layout spawns for sure and everything rolled before it
	/// @param {Asset.GMObject} _same_skeleton_type The map's same skeleton type, or noone if that event is off
	function determine_random_room_content(_same_skeleton_type) {
		// Start from what the layout spawns for sure. Every skeleton spot holds a basic skeleton until its roll replaces it
		var _skeleton_spot_count = layout.get_object_count("obj_skeleton_spot"); // Skeleton spots aren't in the difficulty score table
		skeleton_types = array_create(_skeleton_spot_count, obj_skeleton);
		replaced_column_fountain_count = 0;
		replaced_statue_fountain_count = 0;
		living_block_count = 0;
		initial_fire_skeleton_count = 0;
		initial_nose_count = 0;
		has_phantom = false;
		has_floater = false;
		
		// Only lantern rooms that aren't special rooms can start lit
		lit = layout.has_lanterns && !is_special_room && get_random_chance_out_of(PRE_LIT_PROBABILITY);

		// Eyes the layout places stop the player in place, so nothing rolled below may chase or shoot at them
		has_eyes = (layout.get_hazard_count("obj_eyes") > 0);
		
		// Determine how many columns and how many statues to replace with fountains
		if (can_have_hazard_with_eyes("obj_fountain")) {
			for (var _column = 0; _column < layout.get_object_count("obj_column"); _column++) { // Columns aren't in the difficulty score table
				if (get_random_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY) && !would_exceed_max_difficulty("obj_fountain")) { replaced_column_fountain_count += 1; }
			}
			for (var _statue = 0; _statue < layout.get_hazard_count("obj_statue"); _statue++) {
				if (get_random_chance_out_of(STATUE_FOUNTAIN_PROBABILITY) && !would_exceed_max_difficulty("obj_fountain", "obj_statue")) { replaced_statue_fountain_count += 1; }
			}
		}

		// Determine how many of the blocks on block spots come alive
		for (var _block_spot = 0; _block_spot < layout.get_hazard_count("obj_block_spot"); _block_spot++) {
			if (get_random_chance_out_of(LIVING_BLOCK_PROBABILITY) && !would_exceed_max_difficulty("obj_living_block")) { living_block_count += 1; }
		}

		// Determine lava enemy spawns
		if (layout.get_hazard_count("obj_lava") > 0) {
			if (can_have_hazard_with_eyes("obj_fire_skeleton") && get_random_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY) && !would_exceed_max_difficulty("obj_fire_skeleton")) { initial_fire_skeleton_count = 1; }
			
			if (can_have_hazard_with_eyes("obj_nose")) {
				for (var _nose_chance = 0; _nose_chance < global.difficulty - 1; _nose_chance++) {
					if (get_random_chance_out_of(NOSE_PROBABILITY) && !would_exceed_max_difficulty("obj_nose")) { initial_nose_count += 1; }
				}
			}
		}
		
		// Determine skeleton spot enemies. A spot keeps its basic skeleton when its roll is skipped, or in a room with eyes,
		// when the rolled type would chase or shoot at the player
		for (var _spot = 0; _spot < _skeleton_spot_count; _spot++) {
			var _skeleton_type = (_same_skeleton_type == noone) ? get_skeleton_type() : _same_skeleton_type;
			var _skeleton_name = object_get_name(_skeleton_type);
			if (_skeleton_type != obj_skeleton && can_have_hazard_with_eyes(_skeleton_name) && !would_exceed_max_difficulty(_skeleton_name, "obj_skeleton")) { skeleton_types[_spot] = _skeleton_type; }
		}
		
		// Determine additional enemy spawns
		has_phantom = layout.has_lanterns && !lit && !is_special_room && can_have_hazard_with_eyes("obj_phantom") && get_random_chance_out_of(PHANTOM_PROBABILITY) && !would_exceed_max_difficulty("obj_phantom");
		has_floater = !has_phantom && !is_special_room && can_have_hazard_with_eyes("obj_floater") && get_random_chance_out_of(FLOATER_PROBABILITY) && !would_exceed_max_difficulty("obj_floater");
		has_moving_collectable = get_random_chance_out_of(MOVING_COLLECTABLE_PROBABILITY);
		initial_mouth_count = layout.get_hazard_count("obj_mouth") * (MOUTHS_PER_MOUTH - 1);
		
		// Eyes rolled onto a skeleton spot come last, so they only join a room where nothing chases or shoots at the player
		if (!has_eyes && _skeleton_spot_count > 0 && count_hazards_with_tags(get_hazard_counts(false), TARGETS_PLAYER_TAGS) == 0 && get_random_chance_out_of(EYES_PROBABILITY)) {
			var _eyes_spot = irandom(_skeleton_spot_count - 1);
			if (!would_exceed_max_difficulty("obj_eyes", object_get_name(skeleton_types[_eyes_spot]))) {
				has_eyes = true;
				skeleton_types[_eyes_spot] = obj_eyes;
			}
		}
		
		// The rules above should never let something that stops the player share the room with something that chases or
		// shoots at them, but flag it if they ever do
		var _rolled_counts = get_hazard_counts(false);
		if (count_hazards_with_tags(_rolled_counts, hazard_tags.stops_player_movement) > 0 && count_hazards_with_tags(_rolled_counts, TARGETS_PLAYER_TAGS) > 0) {
			write_debug_message("Generation rolled a hazard that stops the player into a room with one that chases or shoots at them: " + layout.name, debug_message_level.warning);
		}

		// A hall of mirrors' sequence of exits to take
		mirror_directions = [];
		if (layout.has_hall_of_mirrors) {
			for (var _mirror = 0; _mirror < 4; _mirror++) { array_push(mirror_directions, get_random_carindal_dir()); }
		}
	};

	/// @function reset_decorations()
	/// @description Clears the room's decorations and roles, so a new decoration pass can place them again. Its rolled
	///	content stays as it is, since decorations never change it.
	function reset_decorations() {
		is_start_room = false;
		is_heart_room = false;
		is_guaranteed_lit_room = false;
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
		has_portcullis_trap = false;
		button_on_stairs_spot = false;
		button_spot = -1;
		room_reference_difficulty_score = 0;
	}

	/// @function set_stairs_spot_object(_object)
	/// @description Places the room's stairs spot object (the cross, the encased heart, or a chest), and picks whether
	///	it goes on the stairs spot or the chest spot. The cross always goes on the stairs spot, and nothing else does in a
	///	room with stairs.
	/// @param {Asset.GMObject} _object What to place
	function set_stairs_spot_object(_object) {
		stairs_spot_obj = _object;
		chest_on_stairs_spot = (_object == obj_cross) || (!has_exit(directions.stairs) && get_random_chance_out_of(CHEST_ON_STAIRS_SPOT_PROBABILITY));
	}

	/// @function add_chest([_must_be_hidden])
	/// @description Puts a chest with no item yet in the room. Unless it must be hidden, a hidden chest can only appear in
	///	an unlit lantern room with no phantom.
	/// @param {bool} [_must_be_hidden] Whether the chest must be hidden (false by default)
	function add_chest(_must_be_hidden = false) {
		has_hidden_chest = _must_be_hidden || (has_lanterns && !is_lit() && !spawns_phantom() && get_random_chance_out_of(HIDDEN_CHEST_PROBABILITY));
		set_stairs_spot_object(has_hidden_chest ? obj_hidden_chest : obj_chest);
	}

	/// @function add_portcullis_trap()
	/// @description Traps the room: the portcullis on its side of each cardinal exit closes until the player presses its
	///	button. A trap room's phantom and floater don't spawn (see spawns_phantom and spawns_floater), and the button's
	///	spot is picked at random from all free spots, so building places it exactly there.
	function add_portcullis_trap() {
		// Set the portcullis flag, which also keeps the room's phantom and floater from spawning
		has_portcullis_trap = true;

		// Close the portcullis on the room's side of each cardinal exit
		for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
			var _exit = exits[_dir];
			if (_exit != -1) { _exit.set_portcullis_to_trigger_for_room(self, true); }
		}

		// Pick a spot to spawn the portcullis button
		var _spot = array_random_get(get_portcullis_button_spots());
		button_on_stairs_spot = (_spot == -1);
		button_spot = _spot;
	}

	/// @function apply_roles_to_content()
	/// @description Writes what the room spawns, given its role, into its content fields, which is what building the
	///	room reads. Only for a finished map: while generation is still deciding roles, it needs the content as rolled.
	function apply_roles_to_content() {
		lit = is_lit();
		has_phantom = spawns_phantom();
		has_floater = spawns_floater();
		skeleton_types = get_spawned_skeleton_types();
		if (is_start_room) {
			replaced_column_fountain_count = 0;
			replaced_statue_fountain_count = 0;
			living_block_count = 0;
			initial_nose_count = 0;
			initial_fire_skeleton_count = 0;
		}
	}

	/// @function has_visited_exit(_dir)
	/// @description Whether the room has an exit in a direction that the player has gone through
	/// @param {real} _dir A direction (see directions), stairs included
	/// @returns {bool}
	function has_visited_exit(_dir) {
		return (exits[_dir] != -1 && exits[_dir].visited);
	}
	
	/// @function has_exit(_dir)
	/// @description Whether the room has an exit in a direction
	/// @param {real} _dir A direction (see directions), stairs included
	/// @returns {bool}
	function has_exit(_dir) {
		return (exits[_dir] != -1);
	}
	
	/// @function get_cardinal_exits_count()
	/// @description How many cardinal exits the room has
	/// @returns {real}
	function get_cardinal_exits_count() {
		var _exit_count = 0;
		for (var _dir = directions.up; _dir < directions.stairs; _dir++;) { if (has_exit(_dir)) { _exit_count += 1; } }
		return _exit_count;
	}
	
	/// @function get_connected_room(_dir)
	/// @description The room an exit of this room leads to
	/// @param {real} _dir The exit's direction (see directions), stairs included
	/// @returns {GameRoom|real} The room, or -1 if there is no exit in that direction
	function get_connected_room(_dir) {
		if (_dir > directions.stairs) { return -1; }
		
		return ((exits[_dir] == -1) ? -1 : exits[_dir].get_connected_room(self));
	}

	/// @function rebuild_room_grids()
	/// @description Rebuilds the room's solid and lava path grids from the instances in it now: solids block both grids,
	///	and lava blocks the lava grid
	function rebuild_room_grids() {
		mp_grid_clear_all(solid_path_grid);
		mp_grid_clear_all(lava_path_grid);
		with (obj_lava_part) { mp_path_grid_add(other.lava_path_grid); }
		with (obj_solid) { mp_path_grid_add(other.solid_path_grid); mp_path_grid_add(other.lava_path_grid); }
	}
	
	/// @function add_to_instances_at_map_positions(_inst)
	/// @description Records an instance's object in the part of the room it's in, one of a three by three grid, so the
	///	map can draw it there
	/// @param {Id.Instance} _inst The instance
	function add_to_instances_at_map_positions(_inst) {
		var _room_map_pos = get_room_map_position(_inst);
		array_push(instances_at_map_positions[_room_map_pos[0]][_room_map_pos[1]], _inst.object_index);
	}

	/// @function remove_from_instances_at_map_positions(_inst)
	/// @description Removes an instance's object from the part of the room it's in, which add_to_instances_at_map_positions
	///	recorded for the map
	/// @param {Id.Instance} _inst The instance
	function remove_from_instances_at_map_positions(_inst) {
		var _room_map_pos = get_room_map_position(_inst);
		array_remove_first(instances_at_map_positions[_room_map_pos[0]][_room_map_pos[1]], _inst.object_index);
	}
	
	/// @function is_connected_to_hall_of_mirrors()
	/// @description Whether the room is a hall of mirrors, or is linked to one by a cardinal exit
	/// @returns {bool}
	function is_connected_to_hall_of_mirrors() {
		if (has_hall_of_mirrors) { return true; }
		
		for (var _dir = directions.up; _dir < directions.stairs; _dir++;) {
			var _next_exit = exits[_dir];
			if (_next_exit == -1) { continue; }
			
			var _next_room = _next_exit.get_connected_room(self);
			if (_next_room.has_hall_of_mirrors) { return true; }
		}
		
		return false;
	}
	
	/// @function initialize_from_room_reference()
	/// @description Creates the instances of the room's layout, the first time the room is built, and lists its
	///	collectable spots
	function initialize_from_room_reference() {
		var _reference_instances = layout.instances;
		collectable_spot_instances = [];
		
		for(var _i = 0; _i < array_length(_reference_instances); _i++) {
			var _ref = _reference_instances[_i];
			var _new_instance = instance_create(_ref.x, _ref.y, asset_get_index(_ref.name));
			if (_ref.name == "obj_collectable_spot") { array_push(collectable_spot_instances, _new_instance); }
		}
	}
	
	/// @function deactivate_room_instances()
	/// @description Lists the room's instances, other than persistent ones, and deactivates them, so they come back as
	///	they were when the player returns (see activate_room_instances)
	function deactivate_room_instances() {
		instances = [];
		collectable_spot_instances = [];
		
		with (obj_light_source) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_game_object) { if (!persistent) { array_push(other.instances, id); } }
		with (obj_placeholder) { if (!persistent) { array_push(other.instances, id); } }
		for (var _i = 0; _i < array_length(instances); _i++) { instance_deactivate_object(instances[_i]); }
	}

	/// @function activate_room_instances()
	/// @description Brings back the room's instances when the player enters it, creating them from its layout the
	///	first time
	function activate_room_instances() {
		if (array_length(instances) == 0) { initialize_from_room_reference(); }
		else {
			for (var _i = 0; _i < array_length(instances); _i++) {
				instance_activate_object(instances[_i]);
			}
		}
	}
	
	/// @function flip_room_contents_horizontally()
	/// @description Mirrors the room's instances, other than the player, from left to right, and turns the exit spots
	///	facing left or right to match
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

	/// @function flip_room_contents_vertically()
	/// @description Mirrors the room's instances, other than the player, from top to bottom, and turns the exit spots
	///	facing up or down to match
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

	/// @function rotate_room_contents_around_room_center(_direction_to_face)
	/// @description Rotates the room's instances, other than the player, around the room's center, and turns the exit
	///	spots to match
	/// @param {real} _direction_to_face The direction the room's top side faces once rotated (see directions)
	function rotate_room_contents_around_room_center(_direction_to_face) {
		var _angle = _direction_to_face * 90;
	
		with obj_game_object {
		    if (object_index != obj_player) { 
				image_angle = 0;
				var _x_prev = x - room_width/2;
				var _y_prev = y - room_height/2;
			
				x = ((_x_prev * dcos(_angle)) - (_y_prev * dsin(_angle))) + room_width/2;
				y = ((_y_prev * dcos(_angle)) + (_x_prev * dsin(_angle))) + room_height/2;
				if (!place_snapped(4, 4)) { move_snap(4, 4); }
			}
		}
		with obj_placeholder {
			image_angle = 0;
			var _x_prev = x - room_width/2;
			var _y_prev = y - room_height/2;
			
			x = ((_x_prev * dcos(_angle)) - (_y_prev * dsin(_angle))) + room_width/2;
			y = ((_y_prev * dcos(_angle)) + (_x_prev * dsin(_angle))) + room_height/2;
			if (!place_snapped(4, 4)) { move_snap(4, 4); }
		}
		with obj_exit_spot {
			if (_direction_to_face == directions.right) { exit_dir = get_turn_right_dir(exit_dir); }
			else if (_direction_to_face == directions.left) { exit_dir = get_turn_left_dir(exit_dir); }
			else if (_direction_to_face == directions.down) { exit_dir = get_opposite_dir(exit_dir); }
		}
	}
	
	/// @function draw_room(_x_pos, _y_pos)
	/// @description Draws the room on the map, once the player has visited it or holds the map: its box, its exits, and
	///	what's in it, as much as the player has seen or their map shows
	/// @param {real} _x_pos The x position to draw this room at
	/// @param {real} _y_pos The y position to draw this room at
	/// @returns {bool} False if the position is off screen, so nothing was drawn
	function draw_room(_x_pos, _y_pos) {
		// Only draw the room if the given position is on screen
		if (_x_pos < 0 || _x_pos > room_width || _y_pos < 0 || _y_pos > room_height) { return false; }
		
		// Only draw the room if the room has been visited at least once, or game is in test mode
		var _show_detailed_map = false, _show_collectables = false, _controller = global.controller, _is_test_mode_on = global.is_test_mode;
		with (global.player) {
			_show_detailed_map = (_is_test_mode_on || is_carrying_item(obj_map));
			_show_collectables = (_is_test_mode_on || is_carrying_special_item(obj_map));
		}
		
		if (_show_detailed_map || visited) {
			// Set up colors to draw this room with
			var _fade_amount = 0; //distance_to_current_room / controller.MAX_MAP_DRAW_DISTANCE;
			var _blink_frame = is_blink_frame();//modulo(global.game_manager.number_of_frames_since_game_began, 12) <= 5;
			var _bg_color = global.bg_color;
			var _white_color = merge_color(c_white, _bg_color, _fade_amount);
			var _red_color = merge_color(global.gms_game_color, _bg_color, _fade_amount);
		
			// Darken the colors of unvisited rooms on the map
			if (!visited) {
				_white_color = merge_color(_white_color, _bg_color, 0.66);
				_red_color = merge_color(_red_color, _bg_color, 0.66);
			}
			
		    // Draw Room on Map
			var _room_color = lit ? _red_color : _bg_color;
			var _inverse_color = lit ? _bg_color : _red_color;
		    if (_controller.current_room != self || !_blink_frame) {
				draw_sprite_ext(spr_box, 0, _x_pos, _y_pos, 0.875, 0.875, 0, _white_color, 1);
				draw_sprite_ext(spr_box, 0, _x_pos, _y_pos, 0.75, 0.75, 0, _room_color, 1);
			}

		    // Draw Room's Exits on Map
			for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
				if (!has_exit(_dir)) { continue; }
				
				var _exit_color = _bg_color;
				if (!_blink_frame) {
					if (exits[_dir].has_lock) { _exit_color = _red_color; }
					else if (exits[_dir].has_closed_portcullis_for_room(_controller.current_room)) { _exit_color = (_is_test_mode_on) ? c_fuchsia : _red_color; }
					else if (exits[_dir].has_illusion_walls > 0) { _exit_color = (_is_test_mode_on) ? c_teal : _bg_color; }
				}

				var _x_offset = 0, _y_offset = 0, _x_size = 0.25, _y_size = 0.25;
				switch (_dir) {
					case directions.up: { _y_offset = -8; _y_size += 0.125; break; } 
					case directions.right: { _x_offset = 8; _x_size += 0.125; break; } 
					case directions.down: { _y_offset = 8; _y_size += 0.125; break; } 
					case directions.left: { _x_offset = -8; _x_size += 0.125; break; } 
				}

			    if (has_visited_exit(_dir) || _show_detailed_map) { draw_sprite_ext(spr_box, 0, _x_pos+_x_offset, _y_pos+_y_offset, _x_size, _y_size, 0, _exit_color, 1); }
			}
			
			// Draw room's map position objects
			for (var _yy = 0; _yy < 3; _yy++) {
				for (var _xx = 0; _xx < 3; _xx++) {
					// Check if any map positions exist at this part of the map and draw them if so
					var _room_map_pos_array = instances_at_map_positions[_xx][_yy];
					if (array_length(_room_map_pos_array) > 0) {
						// Get color of instance to draw
						var _pos_color = -1, _pos_sprite = spr_box, _pos_image = 0, _pos_scale = 0.125;
						for (var _i = 0; _i < array_length(_room_map_pos_array); _i++) { 
							var _room_map_obj = _room_map_pos_array[_i];
				

							if (_room_map_obj == obj_cross) {
								if (_show_collectables) { _pos_color = _white_color; _pos_sprite = spr_map_cross; _pos_scale = 1; continue; }
							}
							else if (_room_map_obj == obj_encased_heart || _room_map_obj == obj_heart) {
								if (_show_collectables) { 
									_pos_image = (is_thump_frame()) ? 1 : 0;
									_pos_color = _inverse_color; 
									_pos_sprite = spr_map_heart; 
									_pos_scale = 1; 
									continue;
								}
							}
							else if (_pos_sprite == spr_box) {
								if (_room_map_obj == obj_stairs) {
									if (_show_detailed_map || has_visited_exit(directions.stairs)) { _pos_color = _white_color; continue; }
								}
								else if (_room_map_obj == obj_hole) { _pos_color = _white_color; continue; }
								else if (_is_test_mode_on && has_locked_chest && (_room_map_obj == obj_chest || _room_map_obj == obj_hidden_chest)) { _pos_color = c_aqua; continue; }
								else if (_is_test_mode_on && has_key && ((chest_obj == obj_key && (_room_map_obj == obj_chest || _room_map_obj == obj_hidden_chest)) || _room_map_obj == obj_key)) { _pos_color = c_lime; continue; }
								else if (_is_test_mode_on && has_hidden_chest && (_room_map_obj == obj_chest || _room_map_obj == obj_hidden_chest)) { _pos_color = c_yellow; continue; }
								else if (_pos_color == -1 && _show_detailed_map && (_show_collectables || _room_map_obj != obj_hidden_chest)) { _pos_color = _inverse_color; }
							}
						}
						
						// Draw obj at pos
						if (_pos_color != -1) {
							var _x_offset = 0, _y_offset = 0;
							if (_xx == 0) { _x_offset -= 3; }
							else if (_xx == 2) { _x_offset += 3; }
							if (_yy == 0) { _y_offset -= 3; }
							else if (_yy == 2) { _y_offset += 3; }
							draw_sprite_ext(_pos_sprite, _pos_image, _x_pos+_x_offset, _y_pos+_y_offset, _pos_scale, _pos_scale, 0, _pos_color, 1); 
						}
					}
				}
			}
		
			// Draw collectables if the map is special
		    if (_show_collectables && has_collectables && !_blink_frame) {
				draw_sprite_ext(spr_collectable, 0, _x_pos, _y_pos, 1, 1, 0, _white_color, 1); 
			}
    
		    // Draw distance information if testing
		    if (_is_test_mode_on && keyboard_check(vk_f1)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(_x_pos, _y_pos, string_hash_to_newline(string(distance_to_start)));
		    }
			
			// Draw difficulty information if testing
		    if (_is_test_mode_on && keyboard_check(vk_f2)) {
		       draw_set_color(c_lime);
		        draw_set_halign(fa_center);
		        draw_set_valign(fa_middle);
		        draw_text(_x_pos, _y_pos, string_hash_to_newline(string(room_reference_difficulty_score)));
		    }
			
		}
		
		return true;
	}
}

/// @function mark_current_room_for_grid_update()
/// @description Has the controller rebuild the current room's path grids on its next update
function mark_current_room_for_grid_update() {
	global.controller.grid_update_timer = 1;
}

/// @function get_skeleton_type_chances()
/// @description What a skeleton spot can hold at the current difficulty besides a basic skeleton, each with its chance out of
///	100. Whatever's left of the 100 is a basic skeleton. Rolling (get_skeleton_type) and the layout's expected rolls
///	(RoomLayout.get_expected_map_generation_spawns) both read it.
/// @returns {array} Each type as { type, chance }, in the order they're rolled
function get_skeleton_type_chances() {
	switch (global.difficulty) {
		case difficulties.easy: return [{ type: obj_cockroach, chance: 3 }];
		case difficulties.medium: return [{ type: obj_cockroach, chance: 6 }, { type: obj_fast_skeleton, chance: 6 }, { type: obj_fat_skeleton, chance: 4 }];
		case difficulties.hard: return [{ type: obj_cockroach, chance: 12 }, { type: obj_fat_skeleton, chance: 8 }, { type: obj_fast_skeleton, chance: 8 }, { type: obj_cultist, chance: 6 }, { type: obj_fire_skeleton, chance: 6 }];
		case difficulties.very_hard: return [{ type: obj_cockroach, chance: 15 }, { type: obj_fat_skeleton, chance: 20 }, { type: obj_fast_skeleton, chance: 15 }, { type: obj_cultist, chance: 12 }, { type: obj_fire_skeleton, chance: 13 }, { type: obj_snake, chance: 5 }];
		default: return [];
	}
}

/// @function get_skeleton_type([_include_basic_skeleton])
/// @description Rolls what a skeleton spot holds at the current difficulty (see get_skeleton_type_chances)
/// @param {bool} [_include_basic_skeleton] False to roll only between the types besides a basic skeleton, as the map's same skeleton type event does
/// @returns {Asset.GMObject}
function get_skeleton_type(_include_basic_skeleton = true) {
	var _type_chances = get_skeleton_type_chances(), _total_type_chance = 0;
	for (var _i = 0; _i < array_length(_type_chances); _i++) { _total_type_chance += _type_chances[_i].chance; }
	
	// Roll out of 100, where whatever the types leave is a basic skeleton, or only over the types
	var _roll = irandom_range(1, _include_basic_skeleton ? 100 : _total_type_chance), _chance_so_far = 0;
	for (var _j = 0; _j < array_length(_type_chances); _j++) {
		_chance_so_far += _type_chances[_j].chance;
		if (_roll <= _chance_so_far) { return _type_chances[_j].type; }
	}
	
	return obj_skeleton;
}