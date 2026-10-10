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

/// @function RoomLayout(_room_asset)
/// @description One room layout, read from its room and its layout file when GameMap builds the layout cache: its exit
///	kind and the lowest difficulty it appears on, the instances building creates, which spots a floor key or a
///	portcullis button can take, how many of each object it places, and its walking distances. A room that isn't a
///	usable layout gets is_usable = false, and GameMap leaves it out of the cache.
/// @param {Asset.GMRoom} _room_asset The room
function RoomLayout(_room_asset) constructor {
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
	
	/// @function get_open_cardinal_exits()
	/// @description The cardinal exits the raw json room file starts with open, before it is flipped or rotated
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

	/// @function get_object_count(_object_name)
	/// @description How many of an object the layout places.
	/// @param {string} _object_name The object's name, like "obj_lantern"
	/// @returns {real} The count, or 0 if the layout places none
	static get_object_count = function(_object_name) {
		var _count = object_counts[$ _object_name];
		return is_undefined(_count) ? 0 : _count;
	};

	/// @function get_hazard_count(_hazard_name)
	/// @description How many of a hazard from the difficulty score table the layout places.
	/// @param {string} _hazard_name The hazard's name in the table, like "obj_statue"
	/// @returns {real} The count, or 0 if the layout places none
	static get_hazard_count = function(_hazard_name) {
		var _count = hazard_counts[$ _hazard_name];
		return is_undefined(_count) ? 0 : _count;
	};

	/// @function get_tile_key(_x, _y)
	/// @description The key a tile has in a struct of tiles, from the position of an instance on it.
	/// @param {real} _x The instance's x position
	/// @param {real} _y The instance's y position
	/// @returns {string}
	static get_tile_key = function(_x, _y) {
		return string(_x) + "," + string(_y);
	};

	/// @function is_cleared_by(_spot, _clearing_spots)
	/// @description Whether building clears a spot. It destroys everything overlapping the 16-pixel square of an
	///	exit spot (as it opens or closes that side) or of the chest spot (for a chest), and a spot's 8-pixel
	///	square overlaps one when their centres are less than 12 pixels apart on both axes.
	/// @param {struct} _spot An instance from the layout file
	/// @param {array} _clearing_spots The layout's exit spots and chest spot
	/// @returns {bool}
	static is_cleared_by = function(_spot, _clearing_spots) {
		for (var _i = 0; _i < array_length(_clearing_spots); _i++) {
			if (abs(_spot.x - _clearing_spots[_i].x) < 12 && abs(_spot.y - _clearing_spots[_i].y) < 12) { return true; }
		}
		return false;
	};

	/// @function check_rules()
	/// @description Logs any way the layout breaks the spot rules generation relies on, or places eyes, which stop the
	///	player in place, alongside something that chases or shoots at them. A layout needs one chest spot, one stairs spot,
	///	at least two collectable spots that building never clears, and an exit spot on every side. The ruby script enforces
	///	the spot rules too, so this should never warn, but it's a good failsafe.
	static check_rules = function() {
		var _problems = "";
		if (get_object_count("obj_chest_spot") != 1) { _problems += " needs exactly one chest spot;"; }
		if (get_object_count("obj_stairs_spot") != 1) { _problems += " needs exactly one stairs spot;"; }
		if (array_length(key_spots) < 2) { _problems += " needs at least two collectable spots off the exit and chest spots;"; }
		if (get_object_count("obj_exit_spot_up") == 0 || get_object_count("obj_exit_spot_right") == 0 ||
			get_object_count("obj_exit_spot_down") == 0 || get_object_count("obj_exit_spot_left") == 0) {
			_problems += " needs an exit spot on every side;";
		}
		if (count_hazards_with_tags(hazard_counts, hazard_tags.stops_player_movement) > 0 && count_hazards_with_tags(hazard_counts, TARGETS_PLAYER_TAGS) > 0) {
			_problems += " places a hazard that stops the player alongside one that chases or shoots at them;";
		}
		if (_problems != "") { write_debug_message("Layout " + name + _problems, debug_message_level.warning); }
	};
	
	/// @function get_hazard_counts_from_file()
	/// @description How many of each hazard in the hazard table the layout places.
	/// @returns {struct}
	static get_hazard_counts_from_file = function() {
		// Loop through every key-value pair as defined in the static difficulty score table
		var _hazard_counts = {}, _names = variable_struct_get_names(get_difficulty_score_table());
		for (var _i = 0; _i < array_length(_names); _i++) {
			var _hazard_name = _names[_i];
			var _hazard_count = get_object_count(_hazard_name); // Get the count of this hazard from the file
			if (_hazard_count > 0) { _hazard_counts[$ _hazard_name] = _hazard_count; }
		}
		
		return _hazard_counts;
	};
 
	/// @function can_have_hazard_with_eyes(_hazard_name)
	/// @description Whether generation can roll a hazard into a room with this layout: never one that chases or shoots at the
	///	player when the layout places eyes (see GameRoom.can_have_hazard_with_eyes)
	/// @param {string} _hazard_name The hazard's name in the difficulty score table
	/// @returns {bool}
	static can_have_hazard_with_eyes = function(_hazard_name) {
		return get_hazard_count("obj_eyes") == 0 || !hazard_has_tag(_hazard_name, TARGETS_PLAYER_TAGS);
	};
 
	/// @function get_base_hazard_counts()
	/// @description What a room with this layout spawns for sure: the hazards the layout places, and a basic skeleton on each
	///	skeleton spot, which is what a spot holds until generation rolls something else for it
	/// @returns {struct} A new struct, so the caller can change it
	static get_base_hazard_counts = function() {
		var _counts = hazard_counts_copy(hazard_counts);
		hazard_count_add(_counts, "obj_skeleton", get_object_count("obj_skeleton_spot")); // Skeleton spots aren't in the difficulty score table
		return _counts;
	};
 
	/// @function get_expected_map_generation_spawns(_counts)
	/// @description What generation can roll into a room with this layout at the current difficulty, and how many of each on
	///	average (see GameRoom.determine_random_room_content). The room maximum generation checks each roll against is left
	///	out, and so are the room's role and decorations, which the layout doesn't decide.
	/// @param {struct} _counts What the layout spawns for sure (see get_base_hazard_counts)
	/// @returns {array} Each spawn (see ExpectedSpawn)
	static get_expected_map_generation_spawns = function(_counts) {
		var _spawns = [];
		
		// Columns and statues that become fountains
		if (can_have_hazard_with_eyes("obj_fountain")) {
			array_push(_spawns, new ExpectedSpawn("obj_fountain", get_object_count("obj_column") * get_chance_out_of(COLUMN_FOUNTAIN_PROBABILITY))); // Columns aren't in the difficulty score table
			array_push(_spawns, new ExpectedSpawn("obj_fountain", get_hazard_count("obj_statue") * get_chance_out_of(STATUE_FOUNTAIN_PROBABILITY), "obj_statue"));
		}
		
		// Blocks that come alive
		array_push(_spawns, new ExpectedSpawn("obj_living_block", get_hazard_count("obj_block_spot") * get_chance_out_of(LIVING_BLOCK_PROBABILITY)));
		
		// The lava's fire skeleton and noses
		if (get_hazard_count("obj_lava") > 0) {
			if (can_have_hazard_with_eyes("obj_fire_skeleton")) { array_push(_spawns, new ExpectedSpawn("obj_fire_skeleton", get_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY))); }
			if (can_have_hazard_with_eyes("obj_nose")) { array_push(_spawns, new ExpectedSpawn("obj_nose", (global.difficulty - 1) * get_chance_out_of(NOSE_PROBABILITY))); }
		}
		
		// What each skeleton spot holds instead of its basic skeleton. On a map with the same skeleton type event, every
		// spot holds one type that isn't a basic skeleton, with the same chances between them
		var _skeleton_spot_count = get_object_count("obj_skeleton_spot"); // Skeleton spots aren't in the difficulty score table
		if (_skeleton_spot_count > 0) {
			var _type_chances = get_skeleton_type_chances(), _total_type_chance = 0, _same_type_chance = get_chance_out_of(SAME_SKELETON_TYPE_PROBABILITY);
			for (var _i = 0; _i < array_length(_type_chances); _i++) { _total_type_chance += _type_chances[_i].chance; }
			for (var _j = 0; _j < array_length(_type_chances); _j++) {
				var _type_name = object_get_name(_type_chances[_j].type);
				if (!can_have_hazard_with_eyes(_type_name)) { continue; }
				
				var _spot_chance = ((1 - _same_type_chance) * _type_chances[_j].chance / 100) + (_same_type_chance * _type_chances[_j].chance / _total_type_chance);
				array_push(_spawns, new ExpectedSpawn(_type_name, _skeleton_spot_count * _spot_chance, "obj_skeleton"));
			}
		}
		
		// A phantom in a lantern room that doesn't start lit, or else a floater. Special rooms get neither
		var _phantom_chance = 0;
		if (has_lanterns && !is_special_room && can_have_hazard_with_eyes("obj_phantom")) {
			_phantom_chance = (1 - get_chance_out_of(PRE_LIT_PROBABILITY)) * get_chance_out_of(PHANTOM_PROBABILITY);
			array_push(_spawns, new ExpectedSpawn("obj_phantom", _phantom_chance));
		}
		if (!is_special_room && can_have_hazard_with_eyes("obj_floater")) { array_push(_spawns, new ExpectedSpawn("obj_floater", (1 - _phantom_chance) * get_chance_out_of(FLOATER_PROBABILITY))); }
		
		// Eyes on a skeleton spot, only in a room where nothing chases or shoots at the player
		if (_skeleton_spot_count > 0 && get_hazard_count("obj_eyes") == 0 && count_hazards_with_tags(_counts, TARGETS_PLAYER_TAGS) == 0) {
			array_push(_spawns, new ExpectedSpawn("obj_eyes", get_chance_out_of(EYES_PROBABILITY), "obj_skeleton"));
		}
		
		return _spawns;
	};
 
	/// @function get_expected_spawns(_counts)
	/// @description Everything that might spawn into a room with this layout on top of what the layout spawns for sure, at
	///	the current difficulty: what generation rolls into it (see get_expected_map_generation_spawns) and what spawns into
	///	it during play (see get_mid_game_spawns), with no key on its floor, since the layout doesn't decide that
	/// @param {struct} _counts What the layout spawns for sure (see get_base_hazard_counts)
	/// @returns {array} Each spawn (see ExpectedSpawn)
	static get_expected_spawns = function(_counts) {
		var _spawns = get_expected_map_generation_spawns(_counts), _mid_game_spawns = get_mid_game_spawns(_counts, self, 0);
		array_copy(_spawns, array_length(_spawns), _mid_game_spawns, 0, array_length(_mid_game_spawns));
		return _spawns;
	};
 
	/// @function get_layout_difficulty_score()
	/// @description How hard a room with this layout is at the current difficulty, which decides whether the difficulty uses
	///	it at all (see determine_minimum_difficulty): what the layout spawns for sure, with what generation rolls into it and
	///	what spawns into it during play added on average. It's scored for a player holding nothing, who has light as often as
	///	the room starts lit.
	/// @returns {real}
	static get_layout_difficulty_score = function() {
		var _counts = get_base_hazard_counts();
		var _chance_starts_lit = (has_lanterns && !is_special_room) ? get_chance_out_of(PRE_LIT_PROBABILITY) : 0;
		var _room = { chance_holding_staff: 0, chance_holding_sword: 0, chance_holding_special_sword: 0, chance_of_light: _chance_starts_lit };
		return get_difficulty_score_with_spawns(_counts, get_expected_spawns(_counts), _room);
	};
 
	/// @function get_layout_time_score()
	/// @description How much time a room with this layout costs at the current difficulty, on top of walking, the same way
	///	get_layout_difficulty_score scores how hard it is
	/// @returns {real}
	static get_layout_time_score = function() {
		var _counts = get_base_hazard_counts(), _spawns = get_expected_spawns(_counts);
		var _time_score = get_time_score_with_spawns(_counts, _spawns);
		
		// Banishing a phantom means lighting every lantern (see GameRoom.get_time_score)
		for (var _i = 0; _i < array_length(_spawns); _i++) {
			var _spawn = _spawns[_i];
			if (_spawn.hazard_name == "obj_phantom") { _time_score += _spawn.expected_count * PHANTOM_TIME_PER_LANTERN * get_object_count("obj_lantern"); }
		}
		
		return _time_score;
	};
 
	/// @function get_placed_hazards_minimum_difficulty()
	/// @description The highest min_difficulty of the hazards the layout places (see get_difficulty_score_table)
	/// @returns {real} A difficulties value
	static get_placed_hazards_minimum_difficulty = function() {
		var _table = get_difficulty_score_table(), _names = variable_struct_get_names(hazard_counts), _minimum_difficulty = difficulties.easy;
		for (var _i = 0; _i < array_length(_names); _i++) { _minimum_difficulty = max(_minimum_difficulty, _table[$ _names[_i]].min_difficulty); }
		return _minimum_difficulty;
	};
 
	/// @function determine_minimum_difficulty()
	/// @description Sets the lowest difficulty the layout appears on: the lowest one, from the highest min_difficulty of the
	///	hazards it places, whose LAYOUT_DIFFICULTY_SCORE_LIMIT and LAYOUT_TIME_SCORE_LIMIT its scores fit in. Hard and Very
	///	Hard have no limits, so every layout appears from Hard at the latest. GameMap calls it while building the layout
	///	cache, once the layout knows whether it's a special room.
	static determine_minimum_difficulty = function() {
		// The chances behind the scores and the limits all read global.difficulty, so score the layout as each difficulty in
		// turn, and then put it back
		var _current_difficulty = global.difficulty;
		minimum_difficulty = difficulties.very_hard;
		for (var _difficulty = get_placed_hazards_minimum_difficulty(); _difficulty < difficulties.very_hard; _difficulty++) {
			global.difficulty = _difficulty;
			if (get_layout_difficulty_score() <= LAYOUT_DIFFICULTY_SCORE_LIMIT && get_layout_time_score() <= LAYOUT_TIME_SCORE_LIMIT) {
				minimum_difficulty = _difficulty;
				break;
			}
		}
		
		global.difficulty = _current_difficulty;
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
			for (var _i = 0; _i < array_length(instances); _i++) {
				var _inst = instances[_i];
				if (_inst.name != _sides[_side]) { continue; }
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
		for (var _j = 0; _j < array_length(instances); _j++) {
			var _spot = instances[_j];
			if (_spot.name == "obj_stairs_spot") { walk_stairs_point = array_length(walk_points); }
			else if (_spot.name == "obj_chest_spot") { walk_chest_point = array_length(walk_points); }
			else if (_spot.name == "obj_collectable_spot") { array_push(walk_collectable_points, array_length(walk_points)); }
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
		for (var _k = 0; _k < array_length(instances); _k++) {
			var _marker = instances[_k], _marker_side = -1;
			for (var _q = 0; _q < 4; _q++) { if (_marker.name == _sides[_q]) { _marker_side = _q; } }
			var _is_open = (_marker_side != -1) && array_contains(_open, _marker_side);
			if (_is_open || _marker.name == "obj_chest_spot" || _marker.name == "obj_stairs_spot") { _cleared[$ get_tile_key(_marker.x, _marker.y)] = true; }
			else if (_marker_side != -1) {
				block_walking_area(_with_lava, _marker.x, _marker.y, 8);
				block_walking_area(_without_lava, _marker.x, _marker.y, 8);
			}
		}
		for (var _m = 0; _m < array_length(instances); _m++) {
			var _obstacle = instances[_m];
			if (!is_undefined(_cleared[$ get_tile_key(_obstacle.x, _obstacle.y)])) { continue; }
			var _half = 0;
			switch (_obstacle.name) {
				case "obj_wall": case "obj_column": case "obj_mirror": case "obj_statue": case "obj_fountain": case "obj_red_chest": _half = 8; break;
				case "obj_giant_eye": _half = 24; break;
			}
			if (_half > 0) {
				block_walking_area(_with_lava, _obstacle.x, _obstacle.y, _half);
				block_walking_area(_without_lava, _obstacle.x, _obstacle.y, _half);
			}
			else if (_obstacle.name == "obj_lava") { block_walking_area(_with_lava, _obstacle.x, _obstacle.y, 8); }
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

	// The room
	room_reference = _room_asset;
	name = room_get_name(_room_asset);
	exit_type = get_exit_type_from_name(name);
	index = -1;											// Its position in the layout cache, set when GameMap builds the cache
	is_special_room = false;								// Set when GameMap builds the layout cache, from its table of special room types

	// Only rooms named for their exits are layouts (rm_title, rm_start, rm_finish and rm_unused_* are not), and a
	// layout is only usable if its file can be read
	is_usable = (exit_type != -1) && !string_starts_with(name, "rm_unused");

	// The layout file holds the instances the layout places, on one line. room_converter.rb writes it from the room asset
	minimum_difficulty = difficulties.very_hard;		// The lowest difficulty it appears on, set when GameMap builds the layout cache (see determine_minimum_difficulty)
	instances = [];										// What building the room creates
	if (is_usable) {
		var _file = file_text_open_read(name + ".json");
		if (_file == -1) {
			write_debug_message("Missing layout file, so the layout is never used: " + name + ".json", debug_message_level.warning);
			is_usable = false;
		}
		else {
			instances = json_parse(file_text_read_string(_file));
			file_text_close(_file);
		}
	}

	// How many of each object the layout places, by object name, how many instances share each tile, and
	// the spots whose squares building may clear: the exit spots and the chest spot
	object_counts = {};
	var _instances_on_tile = {}, _clearing_spots = [];
	for (var _i = 0; _i < array_length(instances); _i++) {
		var _instance = instances[_i];
		var _tile = get_tile_key(_instance.x, _instance.y);
		object_counts[$ _instance.name] = get_object_count(_instance.name) + 1;
		var _tile_count = _instances_on_tile[$ _tile];
		_instances_on_tile[$ _tile] = is_undefined(_tile_count) ? 1 : _tile_count + 1;
		if (string_starts_with(_instance.name, "obj_exit_spot") || _instance.name == "obj_chest_spot") { array_push(_clearing_spots, _instance); }
	}

	// Collectable spots are numbered in file order, so building can find the ones generation picks. A floor key
	// can take any spot building never clears. A portcullis button needs one too, alone on its tile, since anything
	// else there, like an enemy or a block, could hold it down
	key_spots = [];										// Collectable spot numbers a floor key can take
	button_spots = [];									// Collectable spot numbers a button can take
	stairs_spot_is_clear = false;						// Whether a button can take the stairs spot
	var _spot_number = 0;
	for (var _j = 0; _j < array_length(instances); _j++) {
		var _spot = instances[_j];
		var _spot_tile = get_tile_key(_spot.x, _spot.y);
		var _is_alone = (_instances_on_tile[$ _spot_tile] == 1);			// The loop above counted every instance's tile
		if (_spot.name == "obj_stairs_spot") { stairs_spot_is_clear = _is_alone; }
		if (_spot.name != "obj_collectable_spot") { continue; }
		var _is_cleared = is_cleared_by(_spot, _clearing_spots);
		if (!_is_cleared) { array_push(key_spots, _spot_number); }
		if (_is_alone && !_is_cleared) { array_push(button_spots, _spot_number); }
		_spot_number += 1;
	}

	// Its lanterns, its hall of mirrors, and the hazards it places
	has_lanterns = get_object_count("obj_lantern") > 0;
	has_hall_of_mirrors = get_object_count("obj_hall_of_mirrors") > 0;
	hazard_counts = get_hazard_counts_from_file();
 
	// Its walking distances, measured by ensure_walking the first time a room needs them
	walk_measured = false;
	walk_points = [];									// { x, y }: the open cardinal exits' entrances, then the stairs, chest and collectable spots
	walk_entrance_count = 0;							// The first this many walk points are entrances
	walk_stairs_point = -1;
	walk_chest_point = -1;
	walk_collectable_points = [];						// The walk point of each collectable spot, by spot number
	walk_steps = [];									// walk_steps[a][b]: steps from walk point a to b, or -1 if there's no way
 
	// Only a usable layout has spots to check
	if (is_usable) { check_rules(); }
}

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