#macro LAYOUT_SIZE 256						// Every layout room is this many pixels square
#macro LAYOUT_DIFFICULTY_SCORE_LIMIT get_probability_for_difficulty([0, 1.5, 2.5, 3.5, infinity]) // A layout appears from the lowest difficulty whose limits its difficulty and time scores fit in. These keep about as many layouts on each difficulty as the ruby script's difficulties did
#macro LAYOUT_TIME_SCORE_LIMIT get_probability_for_difficulty([0, 0.35, 0.85, infinity, infinity])
#macro LAYOUT_TIME_SCORE_PER_COLUMN 0.025		// 0.75 seconds for each column, only in a layout's time score. Columns barely slow the player, but the ruby script counted them, and this keeps layouts full of them on about the difficulties it gave them

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
/// @description One room layout, read from its GameMaker room when GameMap builds the layout cache: its exit
///	kind and the lowest difficulty it appears on, the instances building creates, which spots a floor key or a
///	portcullis button can take, and how many of each object it places. A room that isn't a usable layout gets
///	is_usable = false, and GameMap leaves it out of the cache.
/// @param {Asset.GMRoom} _room_reference The Game Maker room this layout corresponds to
function RoomLayout(_room_reference) constructor {
	// ============================
	// Public Getter Functions - Called Outside of this file
	// ============================

	/// @function get_object_count(_object_name)
	/// @description How many instances of an object type the layout places, before any destroying spot destroys them
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

	/// @function get_spawned_object_counts([_mapgen_spawns])
	/// @description How many instances of each object type spawn in a room with this layout: the given map generation spawn
	///	counts, or estimates of them when none are given, plus the estimated midgame spawns
	/// @param {struct} _mapgen_spawns The actual spawn counts from map generation; estimates are used by default
	/// @returns {struct} The count struct of spawn counts
	static get_spawned_object_counts = function(_mapgen_spawns = undefined) {
		// Use estimated mapgen spawn counts if no actual counts are given
		_mapgen_spawns ??= combine_count_structs(get_guaranteed_mapgen_spawns(), get_estimated_mapgen_spawns());
		return combine_count_structs(_mapgen_spawns, get_estimated_midgame_spawns(_mapgen_spawns));
	};

	// ============================
	// Private Estimation Functions
	// ============================

	/// @function get_guaranteed_mapgen_spawns()
	/// @description How many instances of each object type a room with this layout always spawns: what the layout places, minus every instance a destroying spot could destroy
	/// @returns {struct} The count struct of guaranteed spawn counts
	static get_guaranteed_mapgen_spawns = function() {
		var _mapgen_counts = duplicate_count_struct(instance_object_counts);
		
		// Remove the instances a destroying spot could destroy when the room is built
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

		// Add back each instance a destroying spot could destroy when the room is built, by its chance to be left
		for (var _i = 0; _i < array_length(covered_instances); _i++) {
			var _covered_instance = covered_instances[_i];
			add_to_count_struct(_mapgen_counts, _covered_instance.object_name, 1 - get_destroyed_chance(_covered_instance));
		}
		
		// Estimate Room Exits
		// A no-exits layout is always reached by stairs. Otherwise each room added to the map joins by stairs at STAIRS_PROBABILITY,
		// and each stairs link gives two rooms a stairs exit, so a room has about twice that chance. Misleading exits show more or
		// fewer openings than the room has exits about equally often, which averages out to the same number of exits, so we don't need to consider those
		var _stairs_count = (exit_type == layout_exit_types.none) ? 1 : 2 * get_chance_out_of(STAIRS_PROBABILITY);
		add_to_count_struct(_mapgen_counts, "obj_exit_spot", array_length(get_open_cardinal_exits()) + _stairs_count);
		
		// Estimate Replaced Columns and Statues with Fountains
		if (can_have_hazard_with_estimated_eyes("obj_fountain")) {
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
			if (can_have_hazard_with_estimated_eyes("obj_fire_skeleton")) {
				var _fire_skeleton_count = get_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_fire_skeleton", _fire_skeleton_count);
			}
			// Estimate Noses
			if (can_have_hazard_with_estimated_eyes("obj_nose")) {
				var _nose_count = (global.difficulty - 1) * get_chance_out_of(NOSE_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_nose", _nose_count);
			}
		}
		
		// Estimate Skeleton Spots
		var _skeleton_spot_count = get_estimated_object_count("obj_skeleton_spot"), _skeleton_type_counts = {};
		if (_skeleton_spot_count > 0) {
			var _skeleton_type_chances = get_skeleton_type_chances(), _total_type_chance = 0, _same_type_chance = get_chance_out_of(SAME_SKELETON_TYPE_PROBABILITY), _basic_skeleton_count = 1;
			var _chance_starts_lit = (has_lanterns && !is_special_room) ? get_chance_out_of(PRE_LIT_PROBABILITY) : 0;
			// Add up the chances of all available skeleton types, to use if not including basic skeleton
			for (var _i = 0; _i < array_length(_skeleton_type_chances); _i++) { _total_type_chance += _skeleton_type_chances[_i].chance; }
			
			// For each skeleton type, add it's count to the struct
			for (var _i = 0; _i < array_length(_skeleton_type_chances); _i++) {
				// Skip types that can't coexist with eyes
				// We skip eyes here because in the actual generation, we replace anything that can't coexist with eyes with a basic skeleton instead
				var _skeleton_chance_type = _skeleton_type_chances[_i];
				var _skeleton_type = _skeleton_chance_type.type, _type_chance = _skeleton_chance_type.chance;
				var _type_name = object_get_name(_skeleton_type);
				if (!can_have_hazard_with_estimated_eyes(_type_name)) { continue; }
				
				// Invisible skeletons only spawn in unlit rooms. A lit room's spot keeps its basic skeleton, which the basic
				// skeleton count picks up below
				if (_type_name == "obj_invisible_skeleton") { _type_chance *= (1 - _chance_starts_lit); }
				
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
		
		// Estimate Phantoms and Floaters. A phantom only joins an unlit room without a hidden chest
		var _phantom_count = 0;
		if (!is_special_room) {
			if (has_lanterns && can_have_hazard_with_estimated_eyes("obj_phantom")) {
				var _hidden_chest_chance = get_chance_out_of(CHEST_PROBABILITY) * get_chance_out_of(HIDDEN_CHEST_PROBABILITY);
				_phantom_count = (1 - get_chance_out_of(PRE_LIT_PROBABILITY)) * (1 - _hidden_chest_chance) * get_chance_out_of(PHANTOM_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_phantom", _phantom_count);
			}
			if (can_have_hazard_with_estimated_eyes("obj_floater")) {
				var _floater_count = (1 - _phantom_count) * get_chance_out_of(FLOATER_PROBABILITY);
				add_to_count_struct(_mapgen_counts, "obj_floater", _floater_count);
			}
		}
		
		// Eyes on a skeleton spot, which are determined before any other random content, so only what the layout places can keep
		// them out of the room: anything that chases or shoots at the player
		if (_skeleton_spot_count > 0 && get_object_count("obj_eyes") == 0 && count_hazards_with_tags(instance_object_counts, TARGETS_PLAYER_TAGS) == 0) {
			var _eyes_count = get_chance_out_of(EYES_PROBABILITY);
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

	/// @function get_destroyed_chance(_covered_instance)
	/// @description How likely building a room with this layout is to destroy an instance under its exit or chest spots. Spots
	///	facing the same side open and close together, so they destroy together, unless one is blocked and another free, since
	///	one of those always destroys. Different sides, and the chest spot, destroy independently
	/// @param {struct} _covered_instance One of the layout's covered_instances
	/// @returns {real} From 0 to 1
	static get_destroyed_chance = function(_covered_instance) {
		// Find the chance each side, or the chest spot, destroys the instance
		var _side_chances = {};
		for (var _i = 0; _i < array_length(_covered_instance.destroying_spots); _i++) {
			var _destroying_spot = destroying_spots[_covered_instance.destroying_spots[_i]], _side = string(_destroying_spot.exit_direction);
			if (is_undefined(_side_chances[$ _side])) { _side_chances[$ _side] = { chance: get_spot_destroyed_chance(_destroying_spot), blocked: _destroying_spot.blocked }; }
			else if (_side_chances[$ _side].blocked != _destroying_spot.blocked) { _side_chances[$ _side].chance = 1; }
		}

		// The instance is only left if no side destroys it
		var _sides = variable_struct_get_names(_side_chances), _left_chance = 1;
		for (var _i = 0; _i < array_length(_sides); _i++) { _left_chance *= 1 - _side_chances[$ _sides[_i]].chance; }
		return 1 - _left_chance;
	};

	/// @function get_spot_destroyed_chance(_destroying_spot)
	/// @description Returns how likely a room with this layout is to destroy what's under one of its exit or chest spots when the room is built.
	/// The current difficulty affects this. The layout's openings are the room's exits unless its exits are
	///	misleading or exits are illusion walls, which generation randomly gives an exit that isn't locked, once for each room it links. The
	///	chest spot destroys if a chest spawns there instead of on the stairs spot, which never happens in a special room
	/// @param {struct} _destroying_spot One of the layout's destroying_spots
	/// @returns {real} From 0 to 1
	static get_spot_destroyed_chance = function(_destroying_spot) {
		// Return if the destroying spot is for a chest spot and not an exit direction
		if (_destroying_spot.exit_direction == -1) { return is_special_room ? 0 : get_chance_out_of(CHEST_PROBABILITY) * (1 - get_chance_out_of(CHEST_ON_STAIRS_SPOT_PROBABILITY)); }

		// How likely the spot's side is to be one of the room's exits. A misleading layout shows either more or fewer openings
		// than its room has exits, each about half the time, so one of its openings may have no exit behind it, or one of its
		// closed sides may hide one. A no exits layout is never misleading, since a misleading room always shows an opening
		var _open_exits = get_open_cardinal_exits(), _open_exit_count = array_length(_open_exits), _open_chance = undefined;
		var _misleading_chance = is_special_room ? 0 : get_chance_out_of(MISLEADING_EXITS_PROBABILITY) / 2;
		if (array_contains(_open_exits, _destroying_spot.exit_direction)) { _open_chance = 1 - (_misleading_chance / _open_exit_count); }
		else { _open_chance = (exit_type == layout_exit_types.none) ? 0 : _misleading_chance / (4 - _open_exit_count); }

		// An open exit destroys its blocked spots, a closed one its free spots, and illusion walls all of them
		if (_destroying_spot.blocked) { return _open_chance; }
		var _illusion_chance = 2 * get_chance_out_of(ILLUSION_WALL_PROBABILITY) * (1 - 2 * get_chance_out_of(LOCKED_DOOR_PROBABILITY));
		return 1 - (_open_chance * (1 - _illusion_chance));
	};

	/// @function can_have_hazard_with_estimated_eyes(_hazard_name)
	/// @description Whether generation can randomly add a hazard to a room with this layout: never one that chases or shoots at the
	///	player when there's any chance the layout's eyes spawn
	/// @param {string} _hazard_name The hazard's name in the hazards table
	/// @returns {bool}
	static can_have_hazard_with_estimated_eyes = function(_hazard_name) {
		// This is good enough for an estimate; calculating the real chance of spawning eyes would change this less than 1% of the time
		return get_estimated_object_count("obj_eyes") == 0 || !hazard_has_tag(_hazard_name, TARGETS_PLAYER_TAGS);
	};

	/// @function get_estimated_object_count(_object_name)
	/// @description How many instances of an object type the layout places, minus the chance an exit or chest spot destroys each one when the room is built
	/// @param {string} _object_name The string name of the Game Maker object type
	/// @returns {real}
	static get_estimated_object_count = function(_object_name) {
		// Start with the base object count, and subtract each covered instance of the object type by its chance to be destroyed
		var _count = get_object_count(_object_name);
		for (var _i = 0; _i < array_length(covered_instances); _i++) {
			var _covered_instance = covered_instances[_i];
			if (_covered_instance.object_name == _object_name) { _count -= get_destroyed_chance(_covered_instance); }
		}
		return _count;
	};

	/// @function get_estimated_midgame_spawns()
	/// @description Everything that spawns during the game, and not just during map generation. Must be estimated based on probabilities. Uses the current global.difficulty.
	/// @param {struct} _mapgen_spawns The actual or estimated spawn counts from map generation
	/// @returns {struct} The count struct of estimated spawn counts
	static get_estimated_midgame_spawns = function(_mapgen_spawns) {
		// Setup object counts for potential spawn points, the ones building the room left
		var _bone_count = get_count_from_struct(_mapgen_spawns, "obj_bones"), _bush_count = get_count_from_struct(_mapgen_spawns, "obj_bush"), _corpse_count = get_count_from_struct(_mapgen_spawns, "obj_player_corpse");
		var _midgame_spawn_counts = {}, _average_room_visits = max(1, get_count_from_struct(_mapgen_spawns, "obj_exit_spot"));
		// Each room's difficulty score is otherwise one visit's worth. Spawns build up instead: each visit gives them another chance to spawn, so by visit k, about k visits' worth have spawned
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
	/// @description Sets the lowest difficulty the layout appears on, based on its hazard types, and the layout score and time limits.
	/// Called during map generation when GameMap calls it while building the layout cache, once the layout knows whether it's a special room.
	static setup_minimum_difficulty = function() {
		// The chance functions all read the global.difficulty, so we need to change that as we evaluate
		var _current_difficulty = global.difficulty, _hazard_minimum_difficulty = get_minimum_difficulty_from_hazards();
		
		// For each difficulty from the hazard minimum, check if it is gated by the layout difficulty and/or time score limits.
		// A layout that fits no limit below very hard is left on very hard
		minimum_difficulty = difficulties.very_hard;
		for (var _difficulty = _hazard_minimum_difficulty; _difficulty < difficulties.very_hard; _difficulty++) {
			global.difficulty = _difficulty;
			if (get_layout_difficulty_score() <= LAYOUT_DIFFICULTY_SCORE_LIMIT && get_layout_time_score() <= LAYOUT_TIME_SCORE_LIMIT) {
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
		var _table = get_hazards_table(), _object_names = variable_struct_get_names(instance_object_counts), _minimum_difficulty = difficulties.easy;
		for (var _i = 0; _i < array_length(_object_names); _i++) {
			// Skip object type if it is not in the hazards table
			var _hazard_table_entry = _table[$ _object_names[_i]];
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
		var _hazard_mitigation = new HazardMitigation(0, 0, 0, _chance_starts_lit);
		return _hazard_mitigation.get_total_difficulty_score_for_spawn_counts(get_spawned_object_counts());
	};

	/// @function get_layout_time_score()
	/// @description How much time a room with this layout costs at the current difficulty: the time score for what the layout
	///	definitely contains, plus an estimate of what it could spawn, with lighting its lanterns to banish a phantom, and its columns
	/// @returns {real}
	static get_layout_time_score = function() {
		var _spawn_counts = get_spawned_object_counts();
		var _phantom_lantern_time = get_count_from_struct(_spawn_counts, "obj_phantom") * get_object_count("obj_lantern") * PHANTOM_TIME_PER_LANTERN;
		return get_time_score_for_spawn_counts(_spawn_counts) + (_phantom_lantern_time / HAZARD_TIME_SCALE) + (get_estimated_object_count("obj_column") * LAYOUT_TIME_SCORE_PER_COLUMN);
	};

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
	/// @description Finds the exit and chest spots, which can destroy everything under them when the room is built, which of these spots cover each other
	///	instance, and whether anything overlaps the chest spot
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
			
			// A block spot's block is already there when the exits are set up, so it blocks like a wall, a solid or lava
			var _object_type = asset_get_index(_instance.object_name);
			var _is_blocker = (_instance.object_name == "obj_block_spot") || _object_type == obj_solid || object_is_ancestor(_object_type, obj_solid) || _object_type == obj_lava || object_is_ancestor(_object_type, obj_lava);

			// For each destroying spot, check if it destroys this instance, and add it to the covered instances array if so
			var _destroying_spots = [];
			for (var _j = 0; _j < array_length(destroying_spots); _j++) {
				// Skip spots that don't overlap this instance
				var _destroying_spot = destroying_spots[_j];
				if (!is_instance_overlapping_spot(_instance, _destroying_spot)) { continue; }

				array_push(_destroying_spots, _j);
				if (_is_blocker) { _destroying_spot.blocked = true; }
				if (_destroying_spot.exit_direction == -1) { chest_spot_is_alone = false; }
			}
			if (array_length(_destroying_spots) > 0) { array_push(covered_instances, { instance: _instance, object_name: _instance.object_name, destroying_spots: _destroying_spots }); }
		}
	};

	/// @function is_instance_overlapping_spot(_instance, _spot)
	/// @description Whether an instance overlaps a 16 pixel spot, like an exit, chest or stairs spot. A collectable spot is the only
	///	8 pixel instance, so it overlaps when their centers are less than 12 pixels apart on both axes. Any other instance is 16
	///	pixels, so it overlaps when they are less than 16 pixels apart instead
	/// @param {struct} _instance One of the layout's instances_to_create
	/// @param {struct} _spot The spot, with its x and y
	/// @returns {bool}
	static is_instance_overlapping_spot = function(_instance, _spot) {
		var _overlap_distance = (_instance.object_name == "obj_collectable_spot") ? 12 : 16;
		return abs(_instance.x - _spot.x) < _overlap_distance && abs(_instance.y - _spot.y) < _overlap_distance;
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
				case "obj_stairs_spot": { stairs_spot_is_alone = _instance_is_alone; break; }
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
		if (array_length(button_spots) == 0 && !stairs_spot_is_alone) { _problems += " needs at least one collectable or stairs spots where a button can be spawned;"; }
		if (count_hazards_with_tags(instance_object_counts, hazard_tags.stops_player_movement) > 0 && count_hazards_with_tags(instance_object_counts, TARGETS_PLAYER_TAGS) > 0) {
			_problems += " places a hazard that stops the player alongside one that chases or shoots at them;";
		}

		// Every instance must sit on the 8 pixel grid, which the tiles and the destroying spots' overlaps rely on
		for (var _i = 0; _i < array_length(instances_to_create); _i++) {
			var _instance = instances_to_create[_i];
			if (_instance.x % 8 != 0 || _instance.y % 8 != 0) { _problems += " has " + _instance.object_name + " off the 8 pixel grid at " + get_tile_key(_instance.x, _instance.y) + ";"; }
		}

		// A destroying spot takes everything under it, so it can't overlap another destroying spot
		for (var _i = 0; _i < array_length(destroying_spots); _i++) {
			for (var _j = _i + 1; _j < array_length(destroying_spots); _j++) {
				var _destroying_spot = destroying_spots[_i], _other_destroying_spot = destroying_spots[_j];
				if (abs(_destroying_spot.x - _other_destroying_spot.x) < 16 && abs(_destroying_spot.y - _other_destroying_spot.y) < 16) {
					_problems += " has overlapping exit or chest spots at " + get_tile_key(_destroying_spot.x, _destroying_spot.y) + ";";
				}
			}
		}

		// The stairs, the stairs spot object or the button spawns on the stairs spot without destroying anything there, so
		// nothing else can overlap the stairs spot
		for (var _i = 0; _i < array_length(instances_to_create); _i++) {
			var _stairs_spot = instances_to_create[_i];
			if (_stairs_spot.object_name != "obj_stairs_spot") { continue; }

			for (var _j = 0; _j < array_length(instances_to_create); _j++) {
				var _instance = instances_to_create[_j];
				if (_j != _i && is_instance_overlapping_spot(_instance, _stairs_spot)) { _problems += " has " + _instance.object_name + " on its stairs spot;"; }
			}
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

	/// @function get_instances_at_tile(_tile_key)
	/// @description Returns a list of instances present at that tile position, if any
	/// @param {string} _tile_key The string key of a tile position to check
	/// @returns {array} The instances present at that tile position, if any
	static get_instances_at_tile = function(_tile_key) {
		return (instances_at_tile[$ _tile_key] ?? []);
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
	
	instances_to_create = [];							// The { x, y, object_name } of each instance the room creates when it's built
	instance_object_counts = {};						// A map of each object type in the layout to the number of instances with that type in the layout
	instances_at_tile = {};								// A map of tiles in the layout to the instances present there, used when first setting up the layout
	destroying_spots = [];								// The exit and chest spots, as { x, y, exit_direction, blocked }: the direction an exit spot faces (-1 for the chest spot), and whether something under it blocks it
	covered_instances = [];								// Every other instance under any of them, as { instance, object_name, destroying_spots }: the indexes of the destroying spots over it
	
	key_spots = [];										// list of collectable spot numbers a floor key can take
	button_spots = [];									// list of collectable spot numbers a button can take
	stairs_spot_is_alone = false;						// Whether nothing else shares the stairs spot's tile, so a button can take it
	chest_spot_is_alone = true;							// Whether nothing else overlaps the chest spot, so a button can take it when no chest does

	// Read the room reference into the above variables
	get_instances_from_room_asset();
	setup_instance_object_and_tile_counts();
	setup_destroying_spots();
	setup_stairs_and_collectable_spots();

	// Set flags for this layout based on the instance object counts. Only instances no exit or chest spot can destroy count,
	// so every room with the layout has them, whatever its exits and difficulty
	var _guaranteed_counts = get_guaranteed_mapgen_spawns();
	has_lanterns = get_count_from_struct(_guaranteed_counts, "obj_lantern") > 0;
	has_hall_of_mirrors = get_count_from_struct(_guaranteed_counts, "obj_hall_of_mirrors") > 0;

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