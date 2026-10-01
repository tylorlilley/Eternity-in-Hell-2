/// @function RoomLayout(_room_asset)
/// @description One room layout, read from its room and its layout file when GameMap builds the layout cache: its exit kind and file difficulty, the instances building creates, which spots a floor key or a portcullis button can take (R52, R57), and how many of each object it places (R55). A room that isn't a usable layout gets is_usable = false, and GameMap leaves it out of the cache.
/// @param {Asset.GMRoom} _room_asset The room
function RoomLayout(_room_asset) constructor {
	/// @function get_exit_type_from_name(_name)
	/// @description Reads a layout's exit kind from its room name, like rm_three_exits_12.
	/// @param {string} _name The room name
	/// @returns {real} A mapgen_exit_types kind, or -1 if the room is not a layout
	static get_exit_type_from_name = function(_name) {
		if (string_pos("no_exits", _name) != 0) { return mapgen_exit_types.none; }
		if (string_pos("one_exit", _name) != 0) { return mapgen_exit_types.one; }
		if (string_pos("two_opposite_exits", _name) != 0) { return mapgen_exit_types.two_opposite; }
		if (string_pos("two_perpendicular_exits", _name) != 0) { return mapgen_exit_types.two_perpendicular; }
		if (string_pos("three_exits", _name) != 0) { return mapgen_exit_types.three; }
		if (string_pos("four_exits", _name) != 0) { return mapgen_exit_types.four; }
		return -1;
	};

	/// @function get_object_count(_object_name)
	/// @description How many of an object the layout places.
	/// @param {string} _object_name The object's name, like "obj_lantern"
	/// @returns {real} The count, or 0 if the layout places none
	static get_object_count = function(_object_name) {
		var _count = object_counts[$ _object_name];
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

	/// @function check_rules()
	/// @description Logs any way the layout breaks the spot rules generation relies on (L1 to L4). The ruby
	///	script also enforces these, so this should never warn, but it's a good failsafe.
	static check_rules = function() {
		var _problems = "";
		if (get_object_count("obj_chest_spot") != 1) { _problems += " needs exactly one chest spot (L1);"; }
		if (get_object_count("obj_stairs_spot") != 1) { _problems += " needs exactly one stairs spot (L2);"; }
		if (array_length(key_spots) < 2) { _problems += " needs at least two collectable spots off the exit and chest spots (L3);"; }
		if (get_object_count("obj_exit_spot_up") == 0 || get_object_count("obj_exit_spot_right") == 0 ||
			get_object_count("obj_exit_spot_down") == 0 || get_object_count("obj_exit_spot_left") == 0) {
			_problems += " needs an exit spot on every side (L4);";
		}
		if (_problems != "") { write_debug_message("Layout " + name + _problems, "WARNING"); }
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

	// The layout file: line 1 holds the file difficulty written by room_converter.rb, and line 2 the placed instances
	file_difficulty = -1;
	instances = [];										// What building the room creates
	if (is_usable) {
		var _file = file_text_open_read(name + ".json");
		if (_file == -1) {
			write_debug_message("Missing layout file, so the layout is never used: " + name + ".json", "WARNING");
			is_usable = false;
		}
		else {
			file_difficulty = real(string_digits(file_text_read_string(_file)));
			file_text_readln(_file);
			instances = json_parse(file_text_read_string(_file));
			file_text_close(_file);
		}
	}

	// How many of each object the layout places, by object name, how many instances share each tile, and
	// which tiles building may clear: an exit spot's, when its side closes, and the chest spot's
	object_counts = {};
	var _instances_on_tile = {}, _cleared_tiles = {};
	for (var _i = 0; _i < array_length(instances); _i++) {
		var _instance = instances[_i];
		var _tile = get_tile_key(_instance.x, _instance.y);
		object_counts[$ _instance.name] = get_object_count(_instance.name) + 1;
		var _tile_count = _instances_on_tile[$ _tile];
		_instances_on_tile[$ _tile] = is_undefined(_tile_count) ? 1 : _tile_count + 1;
		if (string_starts_with(_instance.name, "obj_exit_spot") || _instance.name == "obj_chest_spot") { _cleared_tiles[$ _tile] = true; }
	}

	// Collectable spots are numbered in file order, so building can find the ones generation picks (R57). A
	// floor key can take any spot building never clears. A portcullis button needs a spot alone on its tile,
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
		if (is_undefined(_cleared_tiles[$ _spot_tile])) { array_push(key_spots, _spot_number); }
		if (_is_alone) { array_push(button_spots, _spot_number); }
		_spot_number += 1;
	}

	// Skeleton spots (L5), lanterns (L6) and the hall of mirrors
	skeleton_spot_count = get_object_count("obj_skeleton_spot");
	has_lanterns = get_object_count("obj_lantern") > 0;
	is_hall_of_mirrors = get_object_count("obj_hall_of_mirrors") > 0;

	// Placed objects that rolled content builds on
	column_count = get_object_count("obj_column");
	statue_count = get_object_count("obj_statue");
	lava_count = get_object_count("obj_lava");
	mouth_count = get_object_count("obj_mouth");
	eyes_count = get_object_count("obj_eyes");

	// Other placed objects the score counts (R55)
	ears_count = get_object_count("obj_ears");
	gudetama_count = get_object_count("obj_gudetama");
	bumper_count = get_object_count("obj_bumper_old");
	spider_spot_count = get_object_count("obj_spider_spot");
	spider_count = get_object_count("obj_spider");
	fountain_count = get_object_count("obj_fountain");
	snake_count = get_object_count("obj_snake");
	worm_head_count = get_object_count("obj_giant_worm_head");
	worm_body_count = get_object_count("obj_giant_worm_body");
	block_spot_count = get_object_count("obj_block_spot");
	bones_count = get_object_count("obj_bones");
	corpse_count = get_object_count("obj_player_corpse");

	// Only a usable layout has spots to check
	if (is_usable) { check_rules(); }
}