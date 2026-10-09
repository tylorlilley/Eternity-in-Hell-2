// The six kinds of layout file, named after the side exits they open
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
/// @description One room layout, read from its room and its layout file when GameMap builds the layout cache: its exit kind and file difficulty, the instances building creates, which spots a floor key or a portcullis button can take (R52, R57), and how many of each object it places (R55). A room that isn't a usable layout gets is_usable = false, and GameMap leaves it out of the cache.
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
	/// @description Logs any way the layout breaks the spot rules generation relies on (L1 to L4), or places eyes, which stop
	///	the player in place, alongside something that chases or shoots at them. The ruby script enforces the spot rules too,
	///	so this should never warn, but it's a good failsafe.
	static check_rules = function() {
		var _problems = "";
		if (get_object_count("obj_chest_spot") != 1) { _problems += " needs exactly one chest spot (L1);"; }
		if (get_object_count("obj_stairs_spot") != 1) { _problems += " needs exactly one stairs spot (L2);"; }
		if (array_length(key_spots) < 2) { _problems += " needs at least two collectable spots off the exit and chest spots (L3);"; }
		if (get_object_count("obj_exit_spot_up") == 0 || get_object_count("obj_exit_spot_right") == 0 ||
			get_object_count("obj_exit_spot_down") == 0 || get_object_count("obj_exit_spot_left") == 0) {
			_problems += " needs an exit spot on every side (L4);";
		}
		if (count_other_hazards_with_tags(hazard_counts, undefined, hazard_tags.stops_player_movement) > 0 && count_other_hazards_with_tags(hazard_counts, undefined, TARGETS_PLAYER_TAGS) > 0) {
			_problems += " places a hazard that stops the player alongside one that chases or shoots at them;";
		}
		if (_problems != "") { write_debug_message("Layout " + name + _problems, debug_message_level.warning); }
	};
	
	// @function get_hazard_counts_from_file()
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
 
	/// @function get_difficulty_from_file_line(_line)
	/// @description The lowest difficulty the layout appears on, from line 1 of its layout file ("difficulty: 2,"). The ruby
	///	script that converts rooms into layout files works it out from everything the room places, and the old generator
	///	filtered layouts on it the same way.
	/// @param {string} _line Line 1 of the layout file
	/// @returns {real} A difficulties value
	static get_difficulty_from_file_line = function(_line) {
		var _digits = string_digits(_line);
		return (_digits == "") ? difficulties.easy : max(difficulties.easy, real(_digits));
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
	/// @description Measures the layout's walking distances the first time a room asks (R56), so loading stays
	///	quick and each layout is only measured once.
	static ensure_walking = function() {
		if (walk_measured) { return; }
		walk_measured = true;
		var _sides = ["obj_exit_spot_up", "obj_exit_spot_right", "obj_exit_spot_down", "obj_exit_spot_left"];
		var _open = get_open_cardinal_exits();
 
		// The walk points: each open side's entrance (the middle of its exit spots on the room's edge), then the
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
 
		// The floor as building leaves it: the open sides' exit spots and the chest and stairs spots cleared, and
		// the closed sides' exit spots walled. Walls, columns, mirrors, statues, fountains, the red chest and the
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
	is_sin_room = false;								// Set when GameMap builds the layout cache, from the sin table

	// Only rooms named for their exits are layouts (rm_title, rm_start, rm_finish and rm_unused_* are not), and a
	// layout is only usable if its file can be read
	is_usable = (exit_type != -1) && !string_starts_with(name, "rm_unused");

	// The layout file: line 1 holds the difficulty room_converter.rb worked out, which sets the lowest difficulty the
	// layout appears on, and line 2 the placed instances
	minimum_difficulty = -1;
	instances = [];										// What building the room creates
	if (is_usable) {
		var _file = file_text_open_read(name + ".json");
		if (_file == -1) {
			write_debug_message("Missing layout file, so the layout is never used: " + name + ".json", debug_message_level.warning);
			is_usable = false;
		}
		else {
			minimum_difficulty = get_difficulty_from_file_line(file_text_read_string(_file));
			file_text_readln(_file);
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

	// Collectable spots are numbered in file order, so building can find the ones generation picks (R57). A
	// floor key can take any spot building never clears. A portcullis button needs one too, alone on its tile,
	// since anything else there, like an enemy or a block, could hold it down (R52)
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

	// Skeleton spots (L5), lanterns (L6) and the hall of mirrors
	has_lanterns = get_object_count("obj_lantern") > 0;
	is_hall_of_mirrors = get_object_count("obj_hall_of_mirrors") > 0;
	hazard_counts = get_hazard_counts_from_file();
 
	// Its walking distances (R56), measured by ensure_walking the first time a room needs them
	walk_measured = false;
	walk_points = [];									// { x, y }: the open sides' entrances, then the stairs, chest and collectable spots
	walk_entrance_count = 0;							// The first this many walk points are entrances
	walk_stairs_point = -1;
	walk_chest_point = -1;
	walk_collectable_points = [];						// The walk point of each collectable spot, by spot number
	walk_steps = [];									// walk_steps[a][b]: steps from walk point a to b, or -1 if there's no way
 
	// Only a usable layout has spots to check
	if (is_usable) { check_rules(); }
}

/// @function get_only_lantern_layouts(_layouts)
/// @description Returns only the layouts with lanterns from the given layouts
/// @param {array} _layouts Layouts (RoomLayout)
/// @returns {array}
function get_only_lantern_layouts(_layouts) {
	var _kept = [];
	for (var _i = 0; _i < array_length(_layouts); _i++) {
		if (_layouts[_i].has_lanterns) { array_push(_kept, _layouts[_i]); }
	}
	return _kept;
}