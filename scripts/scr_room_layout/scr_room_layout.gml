#macro LAYOUT_SIZE 256						// Every layout room is this many pixels square

// The six kinds of layout file, named after the cardinal exits they open
enum layout_exit_types {
	none,				// rm_no_exits_*: rooms reached only by stairs
	one,				// rm_one_exit_*
	two_opposite,		// rm_two_opposite_exits_*
	two_perpendicular,	// rm_two_perpendicular_exits_*
	three,				// rm_three_exits_*
	four,				// rm_four_exits_*
	count				// How many kinds there are
}

/// @function RoomLayout(_room_reference)
/// @description One room layout, read from its room and its layout file when GameMap builds the layout cache: its exit
///	kind and the lowest difficulty it appears on, the instances building creates, which spots a floor key or a
///	portcullis button can take, how many of each object it places, and its walking distances. A room that isn't a
///	usable layout gets is_usable = false, and GameMap leaves it out of the cache.
/// @param {Asset.GMRoom} _room_reference The Game Maker room this layout corresponds to
function RoomLayout(_room_reference) constructor {
	// ============================
	// Public Getter Functions - Called Outside of this file
	// ============================
	
	/// @function get_object_count(_object_name)
	/// @description How many of an object are included in the base layout, before modifying based on the destroying spots
	/// @param {string} _object_name The string name of the Game Maker object type
	/// @returns {real} The count, or 0 if the layout places none
	static get_object_count = function(_object_name) {
		return get_count_from_struct(instance_object_counts, _object_name);
	};
	
	/// @function get_open_cardinal_exits()
	/// @description The cardinal exits the room reference will start with open, before it is flipped or rotated
	/// @returns {array} Directions, in a new array each call so the caller can change it
	static get_open_cardinal_exits = function() {
		switch (exit_type) {
			case layout_exit_types.one: return [directions.up];
			case layout_exit_types.two_opposite: return [directions.up, directions.down];
			case layout_exit_types.two_perpendicular: return [directions.up, directions.right];
			case layout_exit_types.three: return [directions.up, directions.right, directions.down];
			case layout_exit_types.four: return [directions.up, directions.right, directions.down, directions.left];
			default: return [];
		}
	};
	
	/// @function get_spawned_hazard_counts([_mapgen_spawns])
	/// @description Get the count struct for all the hazards that spawn based on this layout. Estimated values for the mapgen
	/// spawns if not actual values are given, and then it adds the estimated midgame spawns on top of that.
	/// @param {struct} _mapgen_spawns The actual spawns from map generation; will use estimates by default
	/// @returns {struct} The count struct of actual spawn counts
	static get_spawned_hazard_counts = function(_mapgen_spawns = undefined) {
		// Use estimated mapgen spawn counts if no actual counts are given
		_mapgen_spawns ??= combine_count_structs(get_guaranteed_mapgen_spawns(), get_estimated_mapgen_spawns());
		return combine_count_structs(_mapgen_spawns, get_estimated_midgame_spawns(_mapgen_spawns));
	};
	
	// ============================
	// Private Estimation Functions
	// ============================
	
	/// @function get_guaranteed_mapgen_spawns()
	/// @description Everything that is guaranteed to spawn in this layout, aside from what spawns for sure
	/// @returns {struct} The count struct of guaranteed spawn counts
	static get_guaranteed_mapgen_spawns = function() {
		var _mapgen_counts = duplicate_count_struct(instance_object_counts);
		
		// Remove instances that could get destroyed during room generation
		for (var _i = 0; _i < array_length(covered_instances); _i++) {
			var _covered_instance = covered_instances[_i];
			_mapgen_counts[$ _covered_instance.object_name] -= 1;
		}
		
		return _mapgen_counts;
	};
	
	/// @function get_estimated_mapgen_spawns()
	/// @description Everything that might spawn during generation in this layout, but is not guaranteed, counted as a fraction based on probabilities
	/// You MUST keep this in sync with what the actual room generation does, and at what probabilities!!
	/// @returns {struct} The count struct of estimated spawn counts
	static get_estimated_mapgen_spawns = function() {
		var _mapgen_counts = {};
		
		// Add estimates for instances that could get destroyed during room generation
		var _layout_hazard_names = variable_struct_get_names(instance_object_counts);
		for (var _i = 0; _i < array_length(_layout_hazard_names); _i++) {
			var _hazard_name = _layout_hazard_names[_i];
			add_to_count_struct(_mapgen_counts, _hazard_name, get_estimated_object_count(_hazard_name));
		}
		
		// Estimate Room Exits
		// A no-exits layout is always reached by stairs. Otherwise each room added to the map joins by stairs at STAIRS_PROBABILITY,
		// and each stairs link gives two rooms a stairs exit, so a room has about twice that chance. Misleading exits shift up or down
		// the amount of exits by a coin flip, which averages out to be the same number of exits, so we don't need to consider those
		var _stairs_count = (exit_type == layout_exit_types.none) ? 1 : 2 * get_chance_out_of(STAIRS_PROBABILITY);
		add_to_count_struct(_mapgen_counts, "obj_exit_spot", array_length(get_open_cardinal_exits()) + _stairs_count);
		
		// Estimate Replaced Columns and Statues with Fountains
		if (can_have_hazard_with_eyes("obj_fountain")) {
			var _column_count = get_estimated_object_count("obj_column"), _statue_count = get_estimated_object_count("obj_statue");
			var _column_chance = get_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY), _statue_chance = get_chance_out_of(STATUE_FOUNTAIN_PROBABILITY);
			// Determine the estimate for columns and statues replaced
			var _replaced_column_count = get_expected_capped_successes(_column_count, _column_chance, MAX_REPLACED_FOUNTAINS);
			var _replaced_statue_count = get_expected_capped_successes(_statue_count, _statue_chance, MAX_REPLACED_FOUNTAINS - _replaced_column_count);

			// Modify the mapgen counts based on these estimates
			add_to_count_struct(_mapgen_counts, "obj_fountain", _replaced_column_count + _replaced_statue_count);
			add_to_count_struct(_mapgen_counts, "obj_statue", -_replaced_statue_count);
		}
		
		// Estimate Replace Blocks with Living Blocks
		var _living_block_count = get_estimated_object_count("obj_block_spot") * get_chance_out_of(LIVING_BLOCK_PROBABILITY);
		add_to_count_struct(_mapgen_counts, "obj_living_block", _living_block_count);
		
		// Estimate Lava Spawns
		if (get_object_count("obj_lava") > 0) {
			// Estimate Fire Skeletons
			if (can_have_hazard_with_eyes("obj_fire_skeleton")) {
				var _fire_skeleton_count = get_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_fire_skeleton", _fire_skeleton_count);
			}
			// Estimate Noses
			if (can_have_hazard_with_eyes("obj_nose")) {
				var _nose_count = (global.difficulty - 1) * get_chance_out_of(NOSE_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_nose", _nose_count);
			}
		}
		
		// Estimate Skeleton Spots
		var _skeleton_spot_count = get_estimated_object_count("obj_skeleton_spot"), _skeleton_type_counts = {};
		if (_skeleton_spot_count > 0) {
			var _skeleton_type_chances = get_skeleton_type_chances(), _total_type_chance = 0, _same_type_chance = get_chance_out_of(SAME_SKELETON_TYPE_PROBABILITY), _basic_skeleton_count = 1;
			// Add up the chances of all available skeleton types, to use if not including basic skeleton
			for (var _i = 0; _i < array_length(_skeleton_type_chances); _i++) { _total_type_chance += _skeleton_type_chances[_i].chance; }
			
			// For each skeleton type, add it's count to the struct
			for (var _i = 0; _i < array_length(_skeleton_type_chances); _i++) {
				// Skip types that can't coexist with eyes
				// We skip eyes here because in the actual generation, we replace anything that can't coexist with eyes with a basic skeleton instead
				var _skeleton_chance_type = _skeleton_type_chances[_i];
				var _skeleton_type = _skeleton_chance_type.type, _type_chance = _skeleton_chance_type.chance;
				var _type_name = object_get_name(_skeleton_type);
				if (!can_have_hazard_with_eyes(_type_name)) { continue; }
				
				// Adjust for types that only spawn in unlit rooms
				if (_type_name == "obj_invisible_skeleton") {
					// Adjust for regular replacements in lit rooms
					_basic_skeleton_count += _type_chance *  get_chance_out_of(PRE_LIT_PROBABILITY);
					_type_chance *= (1 - get_chance_out_of(PRE_LIT_PROBABILITY));
				}
				
				// Add this type to the count
				var _same_type_chance_for_type = _same_type_chance * (_type_chance / _total_type_chance);
				var _non_same_type_chance_for_type = (1 - _same_type_chance) * (_type_chance / SKELETON_TYPE_CHANCE_MAX);
				var _skeleton_type_count = (_same_type_chance_for_type + _non_same_type_chance_for_type);
				add_to_count_struct(_skeleton_type_counts, _type_name, _skeleton_type_count);
				_basic_skeleton_count -= _skeleton_type_count;
			}
			
			// Add any remaining chance type to the basic skeleton count
			add_to_count_struct(_skeleton_type_counts, "obj_skeleton", _basic_skeleton_count);
		}
		
		// Estimate Phantoms and Floaters
		var _phantom_count = 0;
		if (!is_special_room) {
			if (has_lanterns && can_have_hazard_with_eyes("obj_phantom")) {
				_phantom_count = (1 - get_chance_out_of(PRE_LIT_PROBABILITY)) * get_chance_out_of(PHANTOM_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_phantom", _phantom_count);
			}
			if (can_have_hazard_with_eyes("obj_floater")) {
				var _floater_count = (1 - _phantom_count) * get_chance_out_of(FLOATER_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_floater", _floater_count);
			}
		}
		
		// Eyes on a skeleton spot, only in a room where nothing chases or shoots at the player
		if (_skeleton_spot_count > 0 && get_object_count("obj_eyes") == 0 && count_hazards_with_tags(instance_object_counts, TARGETS_PLAYER_TAGS) == 0) {
			// Determine the chance for rolling targeting things that prevent the eyes from spawning
			var _expected_targeting_counts = 0, _hazard_names = variable_struct_get_names(_mapgen_counts);
			for (var _i = 0; _i < array_length(_hazard_names); _i++) { if (hazard_has_tag(_hazard_names[_i], TARGETS_PLAYER_TAGS)) { _expected_targeting_counts += max(0, _mapgen_counts[$ _hazard_names[_i]]); } }
			// Add skeleton types to the expected targeting counts
			_hazard_names = variable_struct_get_names(_skeleton_type_counts);
			for (var _i = 0; _i < array_length(_hazard_names); _i++) { if (hazard_has_tag(_hazard_names[_i], TARGETS_PLAYER_TAGS)) { _expected_targeting_counts += _skeleton_type_counts[$ _hazard_names[_i]] * _skeleton_spot_count; } }
			var _eyes_count = exp(-_expected_targeting_counts) * get_chance_out_of(EYES_PROBABILITY); // exp(−n) is the chance of none rolling when n are expected on average
			add_to_count_struct(_mapgen_counts, "obj_eyes", _eyes_count);
			_skeleton_spot_count -= _eyes_count; // Eyes take up a skeleton spot
		}
		
		// Add each skeleton type count to the final map, proportional to the remaining unoccupied skeleton spots
		var _skeleton_type_count_keys = variable_struct_get_names(_skeleton_type_counts);
		for (var _i = 0; _i < array_length(_skeleton_type_count_keys); _i++) {
			_skeleton_type_counts[$ _skeleton_type_count_keys[_i]] *= _skeleton_spot_count;
		}
		return combine_count_structs(_mapgen_counts, _skeleton_type_counts);
	};
	
	/// @function get_estimated_object_count(_object_name)
	/// @description How many of an object the layout places, adjusted for those removed by exit and chest spots during map generation
	/// @param {string} _object_name The string name of the Game Maker object type
	/// @returns {real}
	static get_estimated_object_count = function(_object_name) {
		// Start with the base object count, and subtract any covered instances by their chance to be removed
		var _count = get_object_count(_object_name);
		for (var _i = 0; _i < array_length(covered_instances); _i++) {
			// Skip any instances that aren't of the object type we are counting
			var _covered_instance = covered_instances[_i], _destroyed_chance = 0;
			if (_covered_instance.object_name != _object_name) { continue; }
			
			// Adjust the count by each spot that could destroy it
			for (var _j = 0; _j < array_length(_covered_instance.destroying_spots); _j++) {
				// TODO: Why is this max? Shouldn't we be combining the chance of each spot that can destroy this since having more spots increases the chances it gets destroyed?
				_destroyed_chance = max(_destroyed_chance, get_spot_destroyed_chance(destroying_spots[_covered_instance.destroying_spots[_j]]));
			}
			_count -= _destroyed_chance;
		}
		return _count;
	};
	
	/// @function get_spot_destroyed_chance(_destroying_spot)
	/// @description Returns how likely a room with this layout is to destroy what's under one of its exit or chest spots during map generation.
	/// The current difficulty effects this. The layout's openings are the room's exits unless its exits are
	///	misleading or exits are illusion walls, rolled from the rooms on both sides of an exit that isn't locked. The
	///	chest spot destroys if a chest spawns there instead of on the stairs spot, which never happens in a special room
	/// @param {struct} _destroying_spot One of the layout's destroying_spots
	/// @returns {real} From 0 to 1
	static get_spot_destroyed_chance = function(_destroying_spot) {
		// Return if the destroying spot is for a chest spot and not an exit direction
		if (_destroying_spot.exit_direction == -1) { return is_special_room ? 0 : get_chance_out_of(CHEST_PROBABILITY) * (1 - get_chance_out_of(CHEST_ON_STAIRS_SPOT_PROBABILITY)); }
		
		// How likely the spot's side is to be one of the room's exits
		var _open_exits = get_open_cardinal_exits(), _open_exit_count = array_length(_open_exits), _open_chance = undefined;
		var _misleading_chance = is_special_room ? 0 : get_chance_out_of(MISLEADING_EXITS_PROBABILITY) / 2;
		// TODO: Why is two opposite and two perpendicular exit types treated specially here? Why aren't they both just the same?
		if (array_contains(_open_exits, _destroying_spot.exit_direction)) { _open_chance = (exit_type == layout_exit_types.two_opposite) ? 1 : 1 - (_misleading_chance / _open_exit_count); }
		else { _open_chance = (exit_type == layout_exit_types.none || exit_type == layout_exit_types.two_perpendicular) ? 0 : _misleading_chance / (4 - _open_exit_count); }
		
		// An open exit destroys its blocked spots, a closed one its free spots, and illusion walls all of them
		if (_destroying_spot.blocked) { return _open_chance; }
		var _illusion_chance = 2 * get_chance_out_of(ILLUSION_WALL_PROBABILITY) * (1 - 2 * get_chance_out_of(LOCKED_DOOR_PROBABILITY));
		return 1 - (_open_chance * (1 - _illusion_chance));
	};
	
	/// @function can_have_hazard_with_eyes(_hazard_name)
	/// @description Whether generation can roll a hazard into a room with this layout: never one that chases or shoots at the
	///	player when the layout places eyes
	/// @param {string} _hazard_name The hazard's name in the difficulty score table
	/// @returns {bool}
	static can_have_hazard_with_eyes = function(_hazard_name) {
		// TODO: Remove this function and figure out eyes based on the real or estimated hazard count
		return get_estimated_object_count("obj_eyes") == 0 || !hazard_has_tag(_hazard_name, TARGETS_PLAYER_TAGS);
	};
	
	/// @function get_estimated_midgame_spawns()
	/// @description Everything that spawns during the game, and not just during map generation. Must be estimated based on probabilities. Uses the current global.difficulty.
	/// @param {struct} _mapgen_spawns The actual or estimated spawn counts from map generation
	/// @returns {struct} The count struct of estimated spawn counts
	static get_estimated_midgame_spawns = function(_mapgen_spawns) {
		// Setup object counts for potential spawn points, the ones building the room left
		var _bone_count = get_count_from_struct(_mapgen_spawns, "obj_bones"), _bush_count = get_count_from_struct(_mapgen_spawns, "obj_bush"), _corpse_count = get_count_from_struct(_mapgen_spawns, "obj_player_corpse");
		var _midgame_spawn_counts = {}, _average_room_visits = max(1, get_count_from_struct(_mapgen_spawns, "obj_exit_spot"));
		// Each room’s score is otherwise one visit’s danger. Spawns build up instead: by visit k, about k rolls’ worth have spawned
		var _average_visit_multiplier = (_average_room_visits + 1) / 2; 
		
		// Skeletons rising from trapped bones
		var _skeleton_count = _bone_count * get_chance_out_of(TRAP_BONES_PROBABILITY) * _average_visit_multiplier;
		add_to_count_struct(_midgame_spawn_counts, "obj_skeleton", _skeleton_count);
		
		// Red bugs from bones, bushes and corpses
		var _bug_count = ((_bone_count + _bush_count) * get_chance_out_of(BUG_PROBABILITY));
		// Corpses have a chance to destroy themselves on room entry, and if not, they spawn two bugs
		var _corpse_bug_count = (_corpse_count * (1 - get_chance_out_of(CORPSE_DISINTEGRATE_PROBABILITY)) * 2);
		var _red_bug_count = (_bug_count + _corpse_bug_count) * get_chance_out_of(RED_BUG_PROBABILITY) * _average_visit_multiplier;
		add_to_count_struct(_midgame_spawn_counts, "obj_bug", _red_bug_count);

		// A new nose or a fire skeleton from the lava
		if (get_object_count("obj_lava") > 0) {
			var _nose_chance = get_chance_out_of(MIDGAME_NOSE_PROBABILITY);
			add_to_count_struct(_midgame_spawn_counts, "obj_nose", _nose_chance * _average_visit_multiplier);
			
			var _no_fire_skeleton_chance = 1 - min(1, get_count_from_struct(_mapgen_spawns, "obj_fire_skeleton")); // They only spawn midgame if the room has no fire skeleton at all
			var _fire_skeleton_count = _no_fire_skeleton_chance * (1 - _nose_chance) * get_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY) * _average_visit_multiplier;
			add_to_count_struct(_midgame_spawn_counts, "obj_fire_skeleton", _fire_skeleton_count);
		}

		// Hands for the items on the floor
		var _floor_item_count = get_count_from_struct(_mapgen_spawns, "obj_item");
		var _hands_count = _floor_item_count * get_chance_out_of(HANDS_PROBABILITY) * _average_visit_multiplier;
		add_to_count_struct(_midgame_spawn_counts, "obj_hands", _hands_count);

		return _midgame_spawn_counts;
	};
	
	// ============================
	// Minimum Difficulty Functions
	// ============================
	
	/// @function setup_minimum_difficulty()
	/// @description Sets the lowest difficulty the layout appears on, based on it's hazard types, and the layout score and time limits.
	/// Called during map generation when GameMap calls it while building the layout cache, once the layout knows whether it's a special room.
	static setup_minimum_difficulty = function() {
		// The chance functions all read the global.difficulty, so we need to change that as we evaluate
		var _current_difficulty = global.difficulty, _hazard_minimum_difficulty = get_minimum_difficulty_from_hazards();
		
		// For each difficulty from the hazard minimum, check if it is gated by the layout difficulty and/or time score limits.
		// A layout that fits no limit below very hard is left on very hard
		minimum_difficulty = difficulties.very_hard;
		for (var _difficulty = _hazard_minimum_difficulty; _difficulty < difficulties.very_hard; _difficulty++) {
			global.difficulty = _difficulty;
			if (get_layout_difficulty_score() <= LAYOUT_DIFFICULTY_SCORE_LIMIT) { // TODO:  && get_layout_time_score() <= LAYOUT_TIME_SCORE_LIMIT) {
				minimum_difficulty = _difficulty;
				break;
			}
		}
		
		// Set the global difficulty back once we are done evaluating
		global.difficulty = _current_difficulty;
	};
	
	/// @function get_minimum_difficulty_from_hazards()
	/// @description The highest min_difficulty of the hazards the layout places, used to setup the layout's minimum difficulty
	/// @returns {real} A difficulties value
	static get_minimum_difficulty_from_hazards = function() {
		var _table = get_hazards_table(), _hazard_names = variable_struct_get_names(instance_object_counts), _minimum_difficulty = difficulties.easy;
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip object type if it is not in the hazards table
			var _hazard_table_entry = _table[$ _hazard_names[_i]];
			if (is_undefined(_hazard_table_entry)) { continue; }
			
			// Get the maximum of all present hazard difficulty levels
			_minimum_difficulty = max(_minimum_difficulty, _hazard_table_entry.min_difficulty);
		}
		return _minimum_difficulty;
	};
	
	/// @function get_layout_difficulty_score()
	/// @description How hard a room with this layout is at the current difficulty. This is the base difficulty score for what
	///	the layout definitely contains, plus an estimate of what it could spawn, based on their chances of spawning at the current difficulty.
	/// @returns {real}
	static get_layout_difficulty_score = function() {
		var _chance_starts_lit = (has_lanterns && !is_special_room) ? get_chance_out_of(PRE_LIT_PROBABILITY) : 0;
		var _player_chances = new HazardMitigation(0, 0, 0, _chance_starts_lit);
		return _player_chances.get_total_difficulty_score_for_spawn_counts(get_spawned_hazard_counts());
	};
	
	// TODO: Everything relating to time score
	/*
	/// @function get_layout_time_score()
	/// @description How much time a room with this layout costs at the current difficulty, on top of walking
	/// @returns {real}
	static get_layout_time_score = function() {
		var _counts = duplicate_count_struct(instance_object_counts), _spawns = get_spawned_hazard_counts(_counts);
		var _time_score = get_time_score_with_spawns(_counts, _spawns);
		
		// Banishing a phantom means lighting every lantern
		for (var _i = 0; _i < array_length(_spawns); _i++) {
			var _spawn = _spawns[_i];
			if (_spawn.hazard_name == "obj_phantom") { _time_score += _spawn.expected_count * PHANTOM_TIME_PER_LANTERN * get_object_count("obj_lantern"); }
		}
		
		return _time_score;
	};
 
	// ============================
	// Time Score Functions
	// ============================
	
	/// @function ensure_walking()
	/// @description Measures the layout's walking distances the first time a room asks, so loading stays
	///	quick and each layout is only measured once.
	static ensure_walking = function() {
		if (walk_measured) { return; }
		walk_measured = true;
		var _sides = ["obj_exit_spot_up", "obj_exit_spot_right", "obj_exit_spot_down", "obj_exit_spot_left"];
		var _open = get_open_cardinal_exits();
 
		// The walk points: each open cardinal exit's entrance (the middle of its exit spots on the room's edge), then the
		// stairs spot, the chest spot and every collectable spot in file order
		walk_points = [];
		for (var _s = 0; _s < array_length(_open); _s++) {
			var _side = _open[_s], _sum_x = 0, _sum_y = 0, _count = 0;
			for (var _i = 0; _i < array_length(instances_to_create); _i++) {
				var _inst = instances_to_create[_i];
				if (_inst.object_name != _sides[_side]) { continue; }
				var _across = (_side == directions.left || _side == directions.right) ? _inst.x : _inst.y;
				if (_across > 16 && _across < LAYOUT_SIZE - 16) { continue; }
				_sum_x += _inst.x;
				_sum_y += _inst.y;
				_count += 1;
			}
			if (_count > 0) { array_push(walk_points, { x: _sum_x / _count, y: _sum_y / _count }); }
		}
		walk_entrance_count = array_length(walk_points);
		walk_collectable_points = [];
		for (var _j = 0; _j < array_length(instances_to_create); _j++) {
			var _spot = instances_to_create[_j];
			if (_spot.object_name == "obj_stairs_spot") { walk_stairs_point = array_length(walk_points); }
			else if (_spot.object_name == "obj_chest_spot") { walk_chest_point = array_length(walk_points); }
			else if (_spot.object_name == "obj_collectable_spot") { array_push(walk_collectable_points, array_length(walk_points)); }
			else { continue; }
			array_push(walk_points, { x: _spot.x, y: _spot.y });
		}
 
		// The floor as building leaves it: the open cardinal exits' exit spots and the chest and stairs spots cleared,
		// and the closed ones' exit spots walled. Walls, columns, mirrors, statues, fountains, the red chest and the
		// giant eye's 3x3 body are in the way; push blocks aren't, since pushing one moves you along with it.
		// Lava is in the way too, unless nothing else reaches a point (then a block bridge or a staff is assumed)
		var _cells = LAYOUT_SIZE / 8 + 1;
		var _with_lava = mp_grid_create(-4, -4, _cells, _cells, 8, 8), _without_lava = mp_grid_create(-4, -4, _cells, _cells, 8, 8);
		for (var _edge = 0; _edge < _cells; _edge++) {
			mp_grid_add_cell(_with_lava, _edge, 0);				mp_grid_add_cell(_without_lava, _edge, 0);
			mp_grid_add_cell(_with_lava, _edge, _cells - 1);	mp_grid_add_cell(_without_lava, _edge, _cells - 1);
			mp_grid_add_cell(_with_lava, 0, _edge);				mp_grid_add_cell(_without_lava, 0, _edge);
			mp_grid_add_cell(_with_lava, _cells - 1, _edge);	mp_grid_add_cell(_without_lava, _cells - 1, _edge);
		}
		var _cleared = {};
		for (var _k = 0; _k < array_length(instances_to_create); _k++) {
			var _marker = instances_to_create[_k], _marker_side = -1;
			for (var _q = 0; _q < 4; _q++) { if (_marker.object_name == _sides[_q]) { _marker_side = _q; } }
			var _is_open = (_marker_side != -1) && array_contains(_open, _marker_side);
			if (_is_open || _marker.object_name == "obj_chest_spot" || _marker.object_name == "obj_stairs_spot") { _cleared[$ get_tile_key(_marker.x, _marker.y)] = true; }
			else if (_marker_side != -1) {
				block_walking_area(_with_lava, _marker.x, _marker.y, 8);
				block_walking_area(_without_lava, _marker.x, _marker.y, 8);
			}
		}
		for (var _m = 0; _m < array_length(instances_to_create); _m++) {
			var _obstacle = instances_to_create[_m];
			if (!is_undefined(_cleared[$ get_tile_key(_obstacle.x, _obstacle.y)])) { continue; }
			var _half = 0;
			switch (_obstacle.object_name) {
				case "obj_wall": case "obj_column": case "obj_mirror": case "obj_statue": case "obj_fountain": case "obj_red_chest": _half = 8; break;
				case "obj_giant_eye": _half = 24; break;
			}
			if (_half > 0) {
				block_walking_area(_with_lava, _obstacle.x, _obstacle.y, _half);
				block_walking_area(_without_lava, _obstacle.x, _obstacle.y, _half);
			}
			else if (_obstacle.object_name == "obj_lava") { block_walking_area(_with_lava, _obstacle.x, _obstacle.y, 8); }
		}
 
		// Steps between every pair of walk points
		var _count_points = array_length(walk_points), _path = path_add();
		walk_steps = array_create(_count_points);
		for (var _a = 0; _a < _count_points; _a++) {
			walk_steps[_a] = array_create(_count_points, -1);
			walk_steps[_a][_a] = 0;
		}
		for (var _from = 0; _from < _count_points; _from++) {
			for (var _to = _from + 1; _to < _count_points; _to++) {
				var _steps = measure_walk(_with_lava, _path, walk_points[_from], walk_points[_to]);
				if (_steps < 0) { _steps = measure_walk(_without_lava, _path, walk_points[_from], walk_points[_to]); }
				walk_steps[_from][_to] = _steps;
				walk_steps[_to][_from] = _steps;
			}
		}
		path_delete(_path);
		mp_grid_destroy(_with_lava);
		mp_grid_destroy(_without_lava);
	};
 
	/// @function block_walking_area(_grid, _x, _y, _half)
	/// @description Marks every player position whose 16-pixel body would overlap a square obstacle. The grids'
	///	cells are player positions 8 pixels apart, so a cell's centre is a position.
	/// @param {Id.MpGrid} _grid The grid
	/// @param {real} _x The obstacle's centre
	/// @param {real} _y The obstacle's centre
	/// @param {real} _half Half the obstacle's width, 8 for a tile
	static block_walking_area = function(_grid, _x, _y, _half) {
		mp_grid_add_rectangle(_grid, _x - _half - 3, _y - _half - 3, _x + _half + 3, _y + _half + 3);
	};
 
	/// @function measure_walk(_grid, _path, _from, _to)
	/// @description Steps on the shortest 4-way walk between two walk points.
	/// @param {Id.MpGrid} _grid The grid
	/// @param {Asset.GMPath} _path A spare path
	/// @param {struct} _from A walk point
	/// @param {struct} _to A walk point
	/// @returns {real} Steps, or -1 if there's no way
	static measure_walk = function(_grid, _path, _from, _to) {
		var _x1 = round(_from.x / 8) * 8, _y1 = round(_from.y / 8) * 8, _x2 = round(_to.x / 8) * 8, _y2 = round(_to.y / 8) * 8;
		if (!mp_grid_path(_grid, _path, _x1, _y1, _x2, _y2, false)) { return -1; }
		return round(path_get_length(_path) / 8);
	};
	*/
	
	// ============================
	// Initializer Setup Functions
	// ============================
	
	/// @function get_exit_type_from_name(_name)
	/// @description Reads a layout's exit kind from its room name, like rm_three_exits_12.
	/// @param {string} _name The room name
	/// @returns {real} A layout_exit_types kind, or -1 if the room is not a layout
	static get_exit_type_from_name = function(_name) {
		if (string_pos("no_exits", _name) != 0) { return layout_exit_types.none; }
		if (string_pos("one_exit", _name) != 0) { return layout_exit_types.one; }
		if (string_pos("two_opposite_exits", _name) != 0) { return layout_exit_types.two_opposite; }
		if (string_pos("two_perpendicular_exits", _name) != 0) { return layout_exit_types.two_perpendicular; }
		if (string_pos("three_exits", _name) != 0) { return layout_exit_types.three; }
		if (string_pos("four_exits", _name) != 0) { return layout_exit_types.four; }
		return -1;
	};
	
	/// @function get_instances_from_room_asset()
	/// @description Reads the instances this room spawns straight from its GameMaker room, in place of the layout file.
	///	Each is listed the way the layout file lists it, as { x, y, object_name }, with its position rounded to whole pixels.
	static get_instances_from_room_asset = function() {
		var _instances_in_room = [];
		if (is_usable) {
			// Read only the instances placed in the room. room_get_info gives 0 instead of an array for a room with none
			var _room_instances = room_get_info(room_reference, false, true, false, false, false).instances;
			if (is_array(_room_instances)) {
				for (var _i = 0; _i < array_length(_room_instances); _i++) {
					var _room_instance = _room_instances[_i];
					array_push(_instances_in_room, { x: round(_room_instance.x), y: round(_room_instance.y), object_name: _room_instance.object_index });
				}
			}
		}
		instances_to_create = _instances_in_room;
	};
	
	/// @function setup_instance_object_and_tile_counts()
	/// @description Sets up the counts by object type and by tile position for each instance in the file
	static setup_instance_object_and_tile_counts = function() {
		for (var _i = 0; _i < array_length(instances_to_create); _i++) {
			// Add 1 to the object count for this instance's object type
			var _instance = instances_to_create[_i];
			add_to_count_struct(instance_object_counts, _instance.object_name);
			
			// Add 1 to the number of objects overlapping this tile spot
			add_instance_to_tile(_instance);
		}
	};
	
	/// @function setup_destroying_spots()
	/// @description Finds the exit and chest spots, which can destroy everything under them when the room is built, and which of these spots cover each other instance
	static setup_destroying_spots = function() {
		var _exit_destroying_spot_names = ["obj_exit_spot_up", "obj_exit_spot_right", "obj_exit_spot_down", "obj_exit_spot_left"];
		
		// Add any destroying spots to the array of destroying spots
		for (var _i = 0; _i < array_length(instances_to_create); _i++) {
			var _instance = instances_to_create[_i], _exit_direction = array_get_index(_exit_destroying_spot_names, _instance.object_name);
			if (_exit_direction != -1 || _instance.object_name ==  "obj_chest_spot") {
				array_push(destroying_spots, { x: _instance.x, y: _instance.y, exit_direction: _exit_direction, blocked: false });
			}
		}
		
		// For each instance that is not a destroying spot, 
		for (var _i = 0; _i < array_length(instances_to_create); _i++) {
			// Skip instances that are a destroying spot themselves
			var _instance = instances_to_create[_i];
			if (_instance.object_name == "obj_chest_spot" || string_starts_with(_instance.object_name, "obj_exit_spot")) { continue; }
			
			// A block spot's block is already there when the exits are set up, so it blocks like a wall, a solid or lava. A
			// collectable spot is the only 8px instance, and overlaps a 16px spot when their centers are less than 12 pixels apart
			// on both axes; any other instance is 16px, so it overlaps when they are less than 16 pixels apart instead
			var _object_type = asset_get_index(_instance.object_name);
			var _is_blocker = (_instance.object_name == "obj_block_spot") || _object_type == obj_solid || object_is_ancestor(_object_type, obj_solid) || _object_type == obj_lava || object_is_ancestor(_object_type, obj_lava);
			var _overlap_radius = (_instance.object_name == "obj_collectable_spot") ? 12 : 16;
			
			// For each destroying spot, check if it destroys this instance, and add it to the covered instances array if so
			var _destroying_spots = [];
			for (var _j = 0; _j < array_length(destroying_spots); _j++) {
				// Skip spots that don't overlap this instance
				var _destroying_spot = destroying_spots[_j];
				if (abs(_instance.x - _destroying_spot.x) >= _overlap_radius || abs(_instance.y - _destroying_spot.y) >= _overlap_radius) { continue; }
				
				array_push(_destroying_spots, _j);
				if (_is_blocker) { _destroying_spot.blocked = true; }
			}
			if (array_length(_destroying_spots) > 0) { array_push(covered_instances, { instance: _instance, object_name: _instance.object_name, destroying_spots: _destroying_spots }); }
		}
	};
	
	/// @function setup_stairs_and_collectable_spots()
	/// @description Calculates which stairs and collectable spots are free.
	static setup_stairs_and_collectable_spots = function() {
		var _collectable_spot_number = 0;
		// Check each instances to find the available spots
		for (var _i = 0; _i < array_length(instances_to_create); _i++) {
			// Get the tile position and instance count at that position for each possible instance
			var _possible_spot_instance = instances_to_create[_i];
			var _spot_tile = get_tile_key(_possible_spot_instance.x, _possible_spot_instance.y);
			var _instance_is_alone = (array_length(get_instances_at_tile(_spot_tile)) == 1);
			
			// Check instance names to see what to count this instance as
			switch (_possible_spot_instance.object_name) {
				case "obj_stairs_spot": { stairs_spot_is_clear = _instance_is_alone; break; }
				case "obj_collectable_spot": {
					// Add the spot to key and button spot lists
					if (!is_instance_covered_by_destroying_spot(_possible_spot_instance)) {
						array_push(key_spots, _collectable_spot_number);
						if (_instance_is_alone) { array_push(button_spots, _collectable_spot_number); }
					}
					
					// Always count the spot, even if it can't be used, so we can later pull just the useable spots out of an array of all spots
					_collectable_spot_number += 1;
					
					break;
				}
			}
		}
	};
	
	/// @function is_instance_covered_by_destroying_spot(_instance)
	/// @description Whether building the room can destroy an instance
	/// @param {struct} _instance An instance to check
	/// @returns {bool}
	static is_instance_covered_by_destroying_spot = function(_instance) {
		// Check all covered instances to see if the given instance is included anywhere
		for (var _i = 0; _i < array_length(covered_instances); _i++) {
			if (covered_instances[_i].instance == _instance) { return true; }
		}
		return false;
	};
	
	/// @function validate_layout()
	/// @description Logs any way the layout breaks the expected spot rules generation relies on.
	/// @returns {bool} Whether the layout passes the check or not
	static validate_layout = function() {
		// Validate the various minimum expected spot locations
		var _problems = "";
		if (get_object_count("obj_chest_spot") != 1) { _problems += " needs exactly one chest spot;"; }
		if (get_object_count("obj_stairs_spot") != 1) { _problems += " needs exactly one stairs spot;"; }
		if (array_length(key_spots) < 2) { _problems += " needs at least two collectable spots off the exit and chest spots;"; }
		if (array_length(button_spots) == 0 && !stairs_spot_is_clear) { _problems += " needs at least one collectable or stairs spots where a button can be spawned;"; }
		if (count_hazards_with_tags(instance_object_counts, hazard_tags.stops_player_movement) > 0 && count_hazards_with_tags(instance_object_counts, TARGETS_PLAYER_TAGS) > 0) {
			_problems += " places a hazard that stops the player alongside one that chases or shoots at them;";
		}
		
		// Check every position that holds instances, including the ones placed half a tile off the grid
		var _tile_keys = variable_struct_get_names(instances_at_tile);
		for (var _i = 0; _i < array_length(_tile_keys); _i++) {
			var _tile_key = _tile_keys[_i], _tile_instances = get_instances_at_tile(_tile_key), _tile_object_names = [];
			for (var _j = 0; _j < array_length(_tile_instances); _j++) {
				var _instance = _tile_instances[_j];

				// Only one of each object type per tile, except spider spots, which can share one
				if (_instance.object_name != "obj_spider_spot") {
					if (array_contains(_tile_object_names, _instance.object_name)) { _problems += " has more than one " + _instance.object_name + " at " + _tile_key + ";"; }
					array_push(_tile_object_names, _instance.object_name);
				}

				// Skip remaining validations unless instance is part of a giant worm
				var _is_worm_head = (_instance.object_name == "obj_giant_worm_head");
				if (!_is_worm_head && _instance.object_name != "obj_giant_worm_body") { continue; }
				
				// Vaslidate worms are connected
				var _is_connected = false;
				for (var _dir = directions.up; _dir < directions.stairs; _dir++) {
					var _neighbor_key = get_tile_key(_instance.x + get_dir_x_offset(_dir) * 16, _instance.y + get_dir_y_offset(_dir) * 16);
					if (tile_has_object(_neighbor_key, "obj_giant_worm_body") || (!_is_worm_head && tile_has_object(_neighbor_key, "obj_giant_worm_head"))) { _is_connected = true; break; }
				}
				if (!_is_connected) { _problems += " has a detached " + _instance.object_name + " at " + _tile_key + ";"; }
			}
		}

		// Check every tile on the room's edge: the two doorway tiles in the middle of each side need that side's exit spot,
		// and every other edge tile needs a wall, or a mirror instead in a hall of mirrors room
		var _edge_low = 8, _edge_high = LAYOUT_SIZE - 8, _doorway_low = LAYOUT_SIZE / 2 - 8, _doorway_high = LAYOUT_SIZE / 2 + 8;
		for (var _x = _edge_low; _x <= _edge_high; _x += 16) {
			for (var _y = _edge_low; _y <= _edge_high; _y += 16) {
				// Skip tiles that aren't on the edge
				var _on_left = (_x == _edge_low), _on_right = (_x == _edge_high), _on_top = (_y == _edge_low), _on_bottom = (_y == _edge_high);
				if (!_on_left && !_on_right && !_on_top && !_on_bottom) { continue; }

				// A doorway tile needs its side's exit spot
				var _tile_key = get_tile_key(_x, _y);
				var _is_doorway_x = (_x == _doorway_low || _x == _doorway_high), _is_doorway_y = (_y == _doorway_low || _y == _doorway_high);
				var _exit_spot_name = "";
				if (_on_top && _is_doorway_x) { _exit_spot_name = "obj_exit_spot_up"; }
				else if (_on_bottom && _is_doorway_x) { _exit_spot_name = "obj_exit_spot_down"; }
				else if (_on_left && _is_doorway_y) { _exit_spot_name = "obj_exit_spot_left"; }
				else if (_on_right && _is_doorway_y) { _exit_spot_name = "obj_exit_spot_right"; }
				if (_exit_spot_name != "") {
					if (!tile_has_object(_tile_key, _exit_spot_name)) { _problems += " needs an " + _exit_spot_name + " at " + _tile_key + ";"; }
					continue;
				}

				// Any other edge tile needs a wall or a mirror
				var _wall_object = (has_hall_of_mirrors) ? "obj_mirror" : "obj_wall";
				if (!tile_has_object(_tile_key, _wall_object)) { _problems += " needs an edge wall or mirror at " + _tile_key + ";"; }
			}
		}
		
		// Passes or fails validation checks
		if (_problems != "") { write_debug_message("Layout " + room_name + _problems, debug_message_level.warning); return false; }
		return true;
	};
	
	// ============================
	// Initializer Tile Functions
	// ============================
	
	/// @function add_instance_to_tile(_instance)
	/// @description Adds an instance to those listed at its tile location
	/// @param {struct} _instance A struct with the instance's name and its x and y positions, to add to the map
	static add_instance_to_tile = function(_instance) {
		var _tile_key = get_tile_key(_instance.x, _instance.y);
		instances_at_tile[$ _tile_key] ??= [];
		array_push(instances_at_tile[$ _tile_key], _instance);
	};
	
	/// @function get_tile_key(_x, _y)
	/// @description The key a tile has in a struct of tiles, from the position of an instance on it.
	/// @param {real} _x The instance's x position
	/// @param {real} _y The instance's y position
	/// @returns {string}
	static get_tile_key = function(_x, _y) {
		return string(_x) + "," + string(_y);
	};
	
	/// @function tile_has_object(_tile_key, _object_name)
	/// @description Whether the layout places a given object at a given tile
	/// @param {string} _tile_key The tile's key
	/// @param {string} _object_name The object's name, like "obj_wall"
	/// @returns {bool}
	static tile_has_object = function(_tile_key, _object_name) {
		var _tile_instances = get_instances_at_tile(_tile_key);
		for (var _i = 0; _i < array_length(_tile_instances); _i++) {
			if (_tile_instances[_i].object_name == _object_name) { return true; }
		}
		return false;
	};
	
	/// @function get_instances_at_tile(_tile_key)
	/// @description Returns a list of instances present at that tile position, if any
	/// @param {string} _tile_key The string key of a tile position to check
	/// @returns {array} The instances present at that tile position, if any
	static get_instances_at_tile = function(_tile_key) {
		return (instances_at_tile[$ _tile_key] ?? []);
	};
	
	// ============================
	// Instance Variables
	// ============================

	// Defaults, set when GameMap room generation runs for the first time and builds the layout cache
	is_special_room = false;							// Set when GameMap builds the layout cache, from its table of special room types
	minimum_difficulty = difficulties.very_hard;		// The lowest difficulty it appears on, set when GameMap builds the layout cache
	
	// Set now, when the RoomLayout is initialized
	room_reference = _room_reference;
	room_name = room_get_name(_room_reference);
	exit_type = get_exit_type_from_name(room_name);									// The layout exit type (number of exits and their orientation)
	layout_cache_index = -1;														// Its position in the layout cache, set when GameMap builds the cache
	is_usable = (exit_type != -1) && !string_starts_with(room_name, "rm_unused");	// Only include usable rooms that match an exit type
	
	instances_to_create = [];							// The list of x, y, and object_type structs that will be created when this room gets built
	instance_object_counts = {};						// A map of each object type in the layout to the number of instances with that type in the layout
	instances_at_tile = {};								// A map of tiles in the layout to the instances present there, used when first setting up the layout
	destroying_spots = [];								// The exit and chest spots, as { x, y, exit_direction, blocked }: the direction an exit spot faces (-1 for the chest spot), and whether something under it blocks it
	covered_instances = [];								// Every other instance under any of them, as { instance, object_name, spots }: the indexes of the destroying spots over it
	
	key_spots = [];										// list of collectable spot numbers a floor key can take
	button_spots = [];									// list of collectable spot numbers a button can take
	stairs_spot_is_clear = false;						// Whether a button can take the stairs spot

	// Read the room reference into the above variables
	get_instances_from_room_asset();
	setup_instance_object_and_tile_counts();
	setup_destroying_spots();
	setup_stairs_and_collectable_spots();

	// Set flags for this layout based on the instance object counts
	has_lanterns = get_estimated_object_count("obj_lantern") > 0;
	has_hall_of_mirrors = get_estimated_object_count("obj_hall_of_mirrors") > 0;
 
	// Variables for determining walking distances used to calculate room layout time
	walk_measured = false;
	walk_points = [];									// { x, y }: the open cardinal exits' entrances, then the stairs, chest and collectable spots
	walk_entrance_count = 0;							// The first this many walk points are entrances
	walk_stairs_point = -1;
	walk_chest_point = -1;
	walk_collectable_points = [];						// The walk point of each collectable spot, by spot number
	walk_steps = [];									// walk_steps[a][b]: steps from walk point a to b, or -1 if there's no way
 
	// Verify this layout passes all the layout_rules, and mark it unusable if it does not
	if (is_usable) { is_usable = validate_layout(); }
	instances_at_tile = undefined; // Nothing needs this anymore after validation is completed
}

// ============================
// Global Room Layout Functions
// ============================

/// @function get_only_lantern_layouts(_layouts)
/// @description The layouts with lanterns among some layouts
/// @param {array} _layouts RoomLayouts
/// @returns {array} The ones with lanterns, in a new array
function get_only_lantern_layouts(_layouts) {
	var _kept = [];
	for (var _i = 0; _i < array_length(_layouts); _i++) {
		if (_layouts[_i].has_lanterns) { array_push(_kept, _layouts[_i]); }
	}
	return _kept;
}