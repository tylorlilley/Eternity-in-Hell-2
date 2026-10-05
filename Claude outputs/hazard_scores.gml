// =====================================================================================================
// HAZARD SCORES: DANGER AND TIME, WORKED OUT FROM ONE TABLE
// =====================================================================================================
// A proposal in four parts, for you to paste in:
//	1. scr_hazard_scores (new script): the hazard table, its settings and the helpers that read it.
//	2. RoomLayout (scr_room_layout): stop reading the ruby script's difficulty, cache the layout's hazard
//	   counts and scores instead, and measure its walking distances.
//	3. GameRoom (scr_room): new get_difficulty_score, get_time_score, get_time_needed and get_time_provided.
//	4. GameMap (scr_game_map): a new calculate_time_provided that adds the map's backtracking.
// And one constant to change in scr_constants (the danger scale is new, so the targets are too):
//	#macro MAP_SCORE_TARGET get_probability_for_difficulty([0, 2.3, 11, 28.5, 43])
// AVERAGE_ROOM_DIFFICULTY, TIME_PROVIDED_PER_ROOM, MINIMUM_TIME_PROVIDED_PER_ROOM, TIME_PROVIDED_PER_COLLECTABLE
// and the three TIME_PROVIEDED_PER_* macros are then no longer used.
// Revision 7: swords from chests are counted, the nose and lava fire skeleton follow the bridge review, and the
// room's other contents use my ratings, with R55's values in brackets beside each to switch back.
// Revision 8: time is what a careful player needs (walking measured on the layout, slowed by danger, plus
// hold-ups and backtracking between rooms) times an allowance per difficulty, and the strong regular items
// count as rewards.


// =====================================================================================================
// 1. scr_hazard_scores (new script)
// =====================================================================================================

// Turning scores into game values
#macro DANGER_POINT_SCALE 8.1				// Score points per unit of danger, -ln(1 - danger); 8.1 keeps the median hazard where R55 had it, once swords are counted
#macro HAZARD_FULL_TIME 30					// Seconds a time score of 1 is worth: hold-ups on top of walking, like freezing for eyes or a sin's quest
#macro SWORD_CARRY_CHANCE get_probability_for_difficulty([0, 0.20, 0.13, 0.12, 0.18])	// How often the player holds a sword: chests give about 0.75/0.5/0.5/0.9 a map, and a plain one breaks on its first kill

// Which difficulties a layout can appear on, from its danger and time at Hard (set both time ones to 99 to gate by danger alone)
#macro LAYOUT_MEDIUM_DANGER 1.0				// At least this keeps a layout off Easy
#macro LAYOUT_HARD_DANGER 2.2				// At least this keeps it to Hard and Very Hard
#macro LAYOUT_MEDIUM_TIME 0.3
#macro LAYOUT_HARD_TIME 0.5

// Hazards that make each other worse (the conflict rules in the hazard analysis)
#macro EYES_WITH_FORCER_DANGER 0.70			// STOP vs GO: eyes, plus anything that keeps the player moving
#macro MOUTHS_WITH_HURRIER_DANGER 0.50		// RUSH vs MINES: 3 or more mouths, plus anything that makes the player hurry
#macro STATUE_WITH_CHASER_DANGER 0.15		// TIMING vs CHASE: each statue, when something chases the player
#macro EARS_DANGER_PER_LOUD_KIND 0.10		// SILENCE: added to the ears for each kind of hazard here that makes loud sounds on its own
#macro PHANTOM_TIME_PER_LANTERN 0.03		// Banishing a phantom means lighting every lantern, which takes longer the more there are

// The room's other contents (my ratings; R55's values in brackets)
#macro COLLECTABLES_EXPOSURE 0.4			// Collecting everything crosses the whole room, so its hazard danger counts 1.4 times [flat +0.25]
#macro PORTCULLIS_TRAP_DANGER 0.03			// Shut in until the button is pressed, once per trap room [+0.325 per exit]
#macro SPECIAL_ITEM_REWARD_POINTS -2		// A cursed item makes the rest of the run easier, so the map can take more [-2]
// Regular items count through item_reward_points [-0.25 for any chest without a key-role item]

// Time (R56): what a careful novice needs, then how many times that the run gives
#macro PLAYER_STEPS_PER_SECOND 10			// One 8-pixel step a tick, 10 ticks a second
#macro ROOM_ENTRY_TIME 2					// Seconds each visit costs before any walking: the transition and a look around
#macro CAUTION_PER_DANGER_POINT 0.2			// Walking slows by this share for each point of the room's hazard danger
#macro TIME_ALLOWANCE get_probability_for_difficulty([0, 2.7, 2.1, 1.75, 1.6])	// Time given as a multiple of time needed; these keep the average run as long as now
#macro LOCK_BACKTRACK_SHARE 0.5				// How often a lock comes before its key, sending the player back for one
#macro ILLUSION_WALL_MISS_CHANCE 0.5		// How often an illusion wall passes for a dead end until everything else is explored
#macro ILLUSION_WALL_SEARCH_TIME 10			// Seconds to find the wall once back at it
#macro LAYOUT_SIZE 256						// Every layout room is this many pixels square

/// @function hazard_scores()
/// @description Every hazard's scores, in one place (R55, R56). Placed hazards are named for their objects,
///	so a layout's object counts read straight into the table; rolled ones have names of their own.
///	danger: the chance a novice dies to one in a typical room visit, from 0 to 1. It assumes the player knows
///		what the hazard does (luring the ears included), can see by a lit torch as R55 does, and holds no item;
///		swords come in through SWORD_CARRY_CHANCE.
///	time: the hold-ups it causes on top of walking, from 0 (none) to 1 (HAZARD_FULL_TIME seconds, like a sin's
///		quest). The walking itself is measured on the layout and slowed by danger (get_time_needed).
///	many, time_many: how more copies in one room add up, as a power of the count: 1 additive, under 1
///		diminishing, over 1 compounding, and 0 flat (only the first one counts).
///	min_difficulty: the lowest difficulty a layout that places it can appear on.
///	sword: how much of the danger a held sword can absorb, from 0 to 1: 1 for what it kills on touch, a part for
///		what it kills but that mostly shoots, and 0 (or missing) for what it can't kill.
///	Tags for the conflict rules: forces (keeps the player moving), hurries (makes the player rush), chases
///		(follows the player) and loud (makes loud sounds on its own).
/// @returns {struct}
function hazard_scores() {
	static _table = {
		// Placed by layouts
		obj_statue:				{ danger: 0.04,		many: 1,	time: 0.03,		time_many: 1,		min_difficulty: difficulties.easy },
		obj_fountain:			{ danger: 0.06,		many: 1.1,	time: 0.05,		time_many: 1,		min_difficulty: difficulties.easy,		forces: true },
		obj_mouth:				{ danger: 0.08,		many: 0.8,	time: 0.30,		time_many: 0.3,		min_difficulty: difficulties.easy,		sword: 1, loud: true },	// Per mouth, extra ones included
		obj_spider:				{ danger: 0.15,		many: 1.3,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 1, loud: true },
		obj_spider_spot:		{ danger: 0.20,		many: 0,	time: 0.10,		time_many: 0,		min_difficulty: difficulties.easy,		sword: 1, loud: true },	// One hidden spider, whatever the spot count
		obj_snake:				{ danger: 0.07,		many: 1.4,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.medium,	sword: 1, forces: true, hurries: true },
		obj_giant_worm_head:	{ danger: 0.04,		many: 0.75,	time: 0.05,		time_many: 0.75,	min_difficulty: difficulties.easy },
		obj_giant_worm_body:	{ danger: 0,		many: 1,	time: 0.003,	time_many: 1,		min_difficulty: difficulties.easy },				// Per segment: long worms block corridors longer
		obj_eyes:				{ danger: 0.12,		many: 0,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		sword: 1, hurries: true, loud: true },
		obj_ears:				{ danger: 0.30,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.hard,		sword: 1, forces: true },
		obj_lava:				{ danger: 0.04,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.easy },				// Per room, not per tile
		obj_block_spot:			{ danger: 0,		many: 1,	time: 0.015,	time_many: 1,		min_difficulty: difficulties.easy },				// Their danger is living_block, below
		obj_column:				{ danger: 0,		many: 1,	time: 0.004,	time_many: 1,		min_difficulty: difficulties.easy },				// Mazes take longer to cross
		obj_bones:				{ danger: 0.0024,	many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 1, loud: true },
		obj_player_corpse:		{ danger: 0.005,	many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy },

		// Sin objects. The sin limit already keeps their rooms off Easy and Medium; time covers each sin's quest
		obj_giant_eye:			{ danger: 0.17,		many: 1,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		forces: true },	// Killing it takes about 0.45 danger
		obj_inverted_cross:		{ danger: 0.25,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard },				// The trip to the start cross and back is map travel (GameMap.get_backtracking_time)
		obj_hall_of_mirrors:	{ danger: 0,		many: 0,	time: 1.00,		time_many: 0,		min_difficulty: difficulties.hard },
		obj_red_chest:			{ danger: 0.01,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.hard },
		obj_gudetama:			{ danger: 0.01,		many: 1,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		sword: 1 },

		// What spawns on skeleton spots, named for their objects too (snakes and eyes use the entries above)
		obj_skeleton:			{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 1 },
		obj_cockroach:			{ danger: 0.03,		many: 1,	time: 0.01,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 1 },				// In light; hunting in the dark it's 0.10
		obj_fast_skeleton:		{ danger: 0.13,		many: 1,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 1, forces: true },
		obj_fat_skeleton:		{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 1, loud: true },
		obj_cultist:			{ danger: 0.16,		many: 1.2,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 0.1, forces: true, loud: true },	// A sword only helps against its touch, not its beams
		obj_fire_skeleton:		{ danger: 0.18,		many: 1.15,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		sword: 0.2, forces: true },	// A sword only helps against its touch, not its shots

		// Rolled for a room
		phantom:				{ danger: 0.20,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.easy,		forces: true, hurries: true, chases: true },
		floater:				{ danger: 0.08,		many: 0,	time: 0.15,		time_many: 0,		min_difficulty: difficulties.easy,		forces: true, hurries: true, chases: true },
		nose:					{ danger: 0.10,		many: 1,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		forces: true },	// Aimed where the player is, so walking along a bridge dodges it too
		lava_fire_skeleton:		{ danger: 0.20,		many: 1,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		forces: true },	// Out of reach of a sword or block; its shots can be dodged on bridges, like a nose's
		living_block:			{ danger: 0.10,		many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy },				// Per expected living block
		trap_chest:				{ danger: 0.12,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.easy },
		moving_collectable:		{ danger: 0,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.easy }
	};
	return _table;
}

/// @function hazard_gate_rolls()
/// @description What Hard usually rolls for a layout, used only to judge which difficulties the layout fits:
///	the expected count of each rolled hazard per placed object, and the mix on a skeleton spot. Keep these in
///	step with the odds in scr_constants and get_skeleton_type.
/// @returns {struct}
function hazard_gate_rolls() {
	static _rolls = {
		mouths_per_mouth: 4,							// MOUTHS_PER_MOUTH at Hard
		phantoms_per_lantern_layout: (1 - 1/8) / 3,		// Not pre-lit (1 in 8 is), then PHANTOM_PROBABILITY (1 in 3)
		floaters_per_layout: 1/24,						// FLOATER_PROBABILITY
		noses_per_lava_layout: 2/3,						// 2 rolls of NOSE_PROBABILITY (1 in 3)
		fire_skeletons_per_lava_layout: 1/48,			// FIRE_SKELETON_IN_LAVA_PROBABILITY
		fountains_per_column: 1/96,						// COLUMN_FOUNTAIN_PROBABILITY
		fountains_per_statue: 1/32,						// STATUE_FOUNTAIN_PROBABILITY
		living_blocks_per_block: 1/64,					// LIVING_BLOCK_PROBABILITY
		sword_chance: 0.12,								// SWORD_CARRY_CHANCE
		skeleton_spot: { obj_skeleton: 0.60, obj_cockroach: 0.12, obj_fat_skeleton: 0.08, obj_fast_skeleton: 0.08, obj_cultist: 0.06, obj_fire_skeleton: 0.06 }
	};
	return _rolls;
}

/// @function danger_to_points(_danger)
/// @description Score points for a chance of dying. Points add up across hazards and rooms the way the
///	chances of surviving each one multiply.
/// @param {real} _danger From 0 to 1
/// @returns {real}
function danger_to_points(_danger) {
	return (_danger <= 0) ? 0 : -ln(1 - min(_danger, 0.99)) * DANGER_POINT_SCALE;
}

/// @function item_reward_points(_item)
/// @description How much easier a regular chest item makes the rest of the run, in score points (R55). Only the
///	strong counters count: the sword is left out because SWORD_CARRY_CHANCE already counts swords, the torch
///	because the scores assume light, and the map, compass, clock and shovel because they save time, not lives.
/// @param {Asset.GMObject} _item The item
/// @returns {real} Zero or less
function item_reward_points(_item) {
	switch (_item) {
		case obj_rosary: return -1.5;			// One extra life
		case obj_meat: return -1;				// The strongest counter, once
		case obj_staff: return -1;				// Lava, fireballs and beams can't kill you while you hold it
		case obj_bomb: return -0.5;				// One blast that clears statues, fountains and most enemies
		default: return 0;
	}
}

/// @function hazard_danger_points(_name, _count, [_danger])
/// @description Danger points for _count of a hazard in one room, following its many rule.
/// @param {string} _name The hazard's name in the table
/// @param {real} _count How many; can be fractional when it's an expected count
/// @param {real} [_danger] A danger to use instead of the table's, for the conflict rules
/// @returns {real}
function hazard_danger_points(_name, _count, _danger = undefined) {
	var _table = hazard_scores(), _entry = _table[$ _name];
	if (is_undefined(_entry) || _count <= 0) { return 0; }
	if (is_undefined(_danger)) { _danger = _entry.danger; }
	var _copies = (_entry.many == 0) ? min(1, _count) : power(_count, _entry.many);
	return _copies * danger_to_points(_danger);
}

/// @function hazard_time_score(_name, _count)
/// @description The time score for _count of a hazard in one room, following its time_many rule, at most 1.
/// @param {string} _name The hazard's name in the table
/// @param {real} _count How many; can be fractional when it's an expected count
/// @returns {real}
function hazard_time_score(_name, _count) {
	var _table = hazard_scores(), _entry = _table[$ _name];
	if (is_undefined(_entry) || _count <= 0) { return 0; }
	var _copies = (_entry.time_many == 0) ? min(1, _count) : power(_count, _entry.time_many);
	return min(1, _entry.time * _copies);
}

/// @function hazard_has_tag(_name, _tag)
/// @description Whether a hazard has a conflict-rule tag: forces, hurries, chases or loud.
/// @param {string} _name The hazard's name in the table
/// @param {string} _tag The tag
/// @returns {bool}
function hazard_has_tag(_name, _tag) {
	var _table = hazard_scores(), _entry = _table[$ _name];
	return !is_undefined(_entry) && variable_struct_exists(_entry, _tag) && _entry[$ _tag];
}

/// @function hazard_sword_share(_name)
/// @description How much of a hazard's danger a held sword can absorb, from 0 to 1 (the sword field, or 0).
/// @param {string} _name The hazard's name in the table
/// @returns {real}
function hazard_sword_share(_name) {
	var _table = hazard_scores(), _entry = _table[$ _name];
	return (!is_undefined(_entry) && variable_struct_exists(_entry, "sword")) ? _entry.sword : 0;
}

/// @function hazard_count_add(_counts, _name, _amount)
/// @description Adds to one hazard's count in a struct of hazard counts.
/// @param {struct} _counts Hazard names and how many of each
/// @param {string} _name The hazard's name in the table
/// @param {real} _amount How many to add; can be negative or fractional
function hazard_count_add(_counts, _name, _amount) {
	if (_amount == 0) { return; }
	var _count = _counts[$ _name];
	_counts[$ _name] = (is_undefined(_count) ? 0 : _count) + _amount;
}

/// @function hazard_counts_copy(_counts)
/// @description A copy of a struct of hazard counts, to add to without changing the original.
/// @param {struct} _counts Hazard names and how many of each
/// @returns {struct}
function hazard_counts_copy(_counts) {
	var _copy = {}, _names = variable_struct_get_names(_counts);
	for (var _i = 0; _i < array_length(_names); _i++) { _copy[$ _names[_i]] = _counts[$ _names[_i]]; }
	return _copy;
}

/// @function hazard_counts_danger(_counts, _with_conflicts, [_sword_chance])
/// @description Danger points for a set of hazards in one room. With _with_conflicts, hazards that make each
///	other worse are raised as the conflict rules say. A held sword then absorbs the first fatal touch from
///	anything it kills: with c the chance of holding one, that part of the danger, x in -ln units, becomes
///	x - c * ln(1 + x).
/// @param {struct} _counts Hazard names and how many of each
/// @param {bool} _with_conflicts Whether to apply the conflict rules
/// @param {real} [_sword_chance] The chance the player holds a sword (SWORD_CARRY_CHANCE by default)
/// @returns {real}
function hazard_counts_danger(_counts, _with_conflicts, _sword_chance = undefined) {
	if (is_undefined(_sword_chance)) { _sword_chance = SWORD_CARRY_CHANCE; }
	var _names = variable_struct_get_names(_counts);

	// What kinds of trouble the room holds, for the conflict rules
	var _has_forcer = false, _has_hurrier = false, _has_chaser = false, _loud_kinds = 0;
	if (_with_conflicts) {
		for (var _i = 0; _i < array_length(_names); _i++) {
			var _kind = _names[_i];
			if (_counts[$ _kind] <= 0) { continue; }
			if (hazard_has_tag(_kind, "forces")) { _has_forcer = true; }
			if (hazard_has_tag(_kind, "hurries")) { _has_hurrier = true; }
			if (hazard_has_tag(_kind, "chases")) { _has_chaser = true; }
			if (hazard_has_tag(_kind, "loud")) { _loud_kinds += 1; }
		}
	}

	var _table = hazard_scores(), _points = 0, _sword_points = 0;
	for (var _j = 0; _j < array_length(_names); _j++) {
		var _name = _names[_j], _count = _counts[$ _name], _danger = undefined;
		if (_with_conflicts && _name == "obj_statue" && _has_chaser) { _danger = STATUE_WITH_CHASER_DANGER; }
		if (_with_conflicts && _name == "obj_ears") { _danger = min(0.9, _table.obj_ears.danger + EARS_DANGER_PER_LOUD_KIND * _loud_kinds); }

		var _hazard_points = hazard_danger_points(_name, _count, _danger);
		if (_with_conflicts && _name == "obj_eyes" && _count > 0 && _has_forcer) { _hazard_points = max(_hazard_points, danger_to_points(EYES_WITH_FORCER_DANGER)); }
		if (_with_conflicts && _name == "obj_mouth" && _count >= 3 && _has_hurrier) { _hazard_points = max(_hazard_points, danger_to_points(MOUTHS_WITH_HURRIER_DANGER)); }
		_points += _hazard_points;
		_sword_points += _hazard_points * hazard_sword_share(_name);
	}
	return _points - DANGER_POINT_SCALE * _sword_chance * ln(1 + _sword_points / DANGER_POINT_SCALE);
}

/// @function hazard_counts_time(_counts)
/// @description The time score for a set of hazards in one room: each one's time score, added up.
/// @param {struct} _counts Hazard names and how many of each
/// @returns {real}
function hazard_counts_time(_counts) {
	var _names = variable_struct_get_names(_counts), _time = 0;
	for (var _i = 0; _i < array_length(_names); _i++) { _time += hazard_time_score(_names[_i], _counts[$ _names[_i]]); }
	return _time;
}


// =====================================================================================================
// 2. RoomLayout (scr_room_layout)
// =====================================================================================================

// 2a. Replace the file-difficulty read. The block that reads the layout file becomes:

	// The layout file: line 1 holds the difficulty room_converter.rb wrote, which is no longer used (the
	// layout's difficulty is worked out from the hazard table, below), and line 2 the placed instances
	file_difficulty = -1;
	instances = [];										// What building the room creates
	if (is_usable) {
		var _file = file_text_open_read(name + ".json");
		if (_file == -1) {
			write_debug_message("Missing layout file, so the layout is never used: " + name + ".json", "WARNING");
			is_usable = false;
		}
		else {
			file_text_readln(_file);					// Skip line 1
			instances = json_parse(file_text_read_string(_file));
			file_text_close(_file);
		}
	}

// 2b. Add these static methods next to the others:

	/// @function get_placed_hazard_counts()
	/// @description How many of each hazard in the hazard table the layout places.
	/// @returns {struct}
	static get_placed_hazard_counts = function() {
		var _counts = {}, _names = variable_struct_get_names(hazard_scores());
		for (var _i = 0; _i < array_length(_names); _i++) {
			var _count = get_object_count(_names[_i]);			// Rolled hazards aren't objects, so they count 0
			if (_count > 0) { _counts[$ _names[_i]] = _count; }
		}
		return _counts;
	};

	/// @function get_gate_counts()
	/// @description The layout's hazards at Hard: what it places, plus what Hard usually rolls for it.
	/// @returns {struct}
	static get_gate_counts = function() {
		var _rolls = hazard_gate_rolls(), _counts = hazard_counts_copy(hazard_counts);
		hazard_count_add(_counts, "obj_mouth", mouth_count * (_rolls.mouths_per_mouth - 1));
		hazard_count_add(_counts, "obj_fountain", column_count * _rolls.fountains_per_column + statue_count * _rolls.fountains_per_statue);
		hazard_count_add(_counts, "obj_statue", -statue_count * _rolls.fountains_per_statue);
		var _mix = _rolls.skeleton_spot, _types = variable_struct_get_names(_mix);
		for (var _i = 0; _i < array_length(_types); _i++) { hazard_count_add(_counts, _types[_i], skeleton_spot_count * _mix[$ _types[_i]]); }
		if (has_lanterns) { hazard_count_add(_counts, "phantom", _rolls.phantoms_per_lantern_layout); }
		hazard_count_add(_counts, "floater", _rolls.floaters_per_layout);
		if (lava_count > 0) {
			hazard_count_add(_counts, "nose", _rolls.noses_per_lava_layout);
			hazard_count_add(_counts, "lava_fire_skeleton", _rolls.fire_skeletons_per_lava_layout);
		}
		hazard_count_add(_counts, "living_block", block_spot_count * _rolls.living_blocks_per_block);
		return _counts;
	};

	/// @function get_file_difficulty()
	/// @description The lowest difficulty that can use the layout: set by its danger and time at Hard, and by
	///	the most restricted hazard it places (min_difficulty in the hazard table).
	/// @returns {real} A difficulties value
	static get_file_difficulty = function() {
		var _difficulty = difficulties.easy;
		if (gate_danger >= LAYOUT_MEDIUM_DANGER || gate_time >= LAYOUT_MEDIUM_TIME) { _difficulty = difficulties.medium; }
		if (gate_danger >= LAYOUT_HARD_DANGER || gate_time >= LAYOUT_HARD_TIME) { _difficulty = difficulties.hard; }
		var _table = hazard_scores(), _names = variable_struct_get_names(hazard_counts);
		for (var _i = 0; _i < array_length(_names); _i++) {
			var _entry = _table[$ _names[_i]];
			_difficulty = max(_difficulty, _entry.min_difficulty);
		}
		return _difficulty;
	};

	/// @function get_open_sides()
	/// @description The sides the layout opens in its own frame, by its exit kind. The orientation step turns them
	///	to face the room's real exits (mapgen_roll_layout_orientation).
	/// @returns {array} Side directions
	static get_open_sides = function() {
		switch (exit_type) {
			case mapgen_exit_types.one: return [directions.up];
			case mapgen_exit_types.two_opposite: return [directions.up, directions.down];
			case mapgen_exit_types.two_perpendicular: return [directions.up, directions.right];
			case mapgen_exit_types.three: return [directions.up, directions.right, directions.down];
			case mapgen_exit_types.four: return [directions.up, directions.right, directions.down, directions.left];
			default: return [];
		}
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
		var _open = get_open_sides();

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

// 2c. At the end of the constructor, after the counts and before check_rules():

	// Its hazards and scores, worked out once from the hazard table (R55, R56)
	lantern_count = get_object_count("obj_lantern");
	hazard_counts = get_placed_hazard_counts();			// What it places, named as in the hazard table
	var _gate_counts = get_gate_counts(), _gate_rolls = hazard_gate_rolls();
	gate_danger = hazard_counts_danger(_gate_counts, false, _gate_rolls.sword_chance);	// Its danger at Hard, with Hard's usual rolls
	gate_time = hazard_counts_time(_gate_counts);				// Its time score at Hard
	file_difficulty = get_file_difficulty();

	// Its walking distances (R56), measured by ensure_walking the first time a room needs them
	walk_measured = false;
	walk_points = [];									// { x, y }: the open sides' entrances, then the stairs, chest and collectable spots
	walk_entrance_count = 0;							// The first this many walk points are entrances
	walk_stairs_point = -1;
	walk_chest_point = -1;
	walk_collectable_points = [];						// The walk point of each collectable spot, by spot number
	walk_steps = [];									// walk_steps[a][b]: steps from walk point a to b, or -1 if there's no way


// =====================================================================================================
// 3. GameRoom (scr_room)
// =====================================================================================================
// get_difficulty_score (through get_difficulty_score_for) and get_time_provided replace the R55 and R56
// versions; the rest are new. calculate_map_difficulty_score in GameMap stays as it is.

	/// @function get_hazard_counts()
	/// @description How many of each hazard the room holds, named as in the hazard table: its layout's placed
	///	ones and what was rolled for it (R33).
	/// @returns {struct}
	function get_hazard_counts() {
		var _counts = hazard_counts_copy(layout.hazard_counts);

		// Placed mouths bring difficulty-many more, and columns and statues may have turned into fountains
		hazard_count_add(_counts, "obj_mouth", initial_mouth_count);
		hazard_count_add(_counts, "obj_fountain", initial_fountain_count + initial_statue_fountain_count);
		hazard_count_add(_counts, "obj_statue", -initial_statue_fountain_count);

		// What spawned on the skeleton spots; eyes count once, below
		for (var _i = 0; _i < array_length(skeleton_types); _i++) {
			if (skeleton_types[_i] != obj_eyes) { hazard_count_add(_counts, object_get_name(skeleton_types[_i]), 1); }
		}
		if (has_eyes) { _counts[$ "obj_eyes"] = 1; }

		// Rolled enemies and features
		if (has_phantom) { _counts[$ "phantom"] = 1; }
		if (has_floater) { _counts[$ "floater"] = 1; }
		hazard_count_add(_counts, "nose", initial_nose_count);
		hazard_count_add(_counts, "lava_fire_skeleton", initial_fire_skeleton_count);
		if (has_trap_chest()) { _counts[$ "trap_chest"] = 1; }
		if (has_moving_collectable && has_collectables) { _counts[$ "moving_collectable"] = 1; }
		if (LIVING_BLOCK_PROBABILITY > 0) { hazard_count_add(_counts, "living_block", layout.block_spot_count / LIVING_BLOCK_PROBABILITY); }
		return _counts;
	}

	/// @function get_difficulty_score_for(_counts)
	/// @description Scores how dangerous the room would be with these hazards (R55): their danger and the
	///	conflicts between them, from the hazard table, plus the room's other contents. Higher means more likely
	///	to kill the player. How much time the room costs is scored separately, by get_time_score.
	/// @param {struct} _counts The room's hazards, as get_hazard_counts returns them
	/// @returns {real}
	function get_difficulty_score_for(_counts) {
		var _score = hazard_counts_danger(_counts, true);

		// Collecting everything crosses the whole room, not just the way to one objective
		if (has_collectables) { _score *= 1 + COLLECTABLES_EXPOSURE; }

		// Shut in until the button is pressed. One button opens every exit, so it counts once
		var _is_trap_room = false;
		for (var _dir = directions.up; _dir <= directions.left; _dir++) {
			var _exit = exits[_dir];
			if (_exit != -1 && _exit.has_closed_portcullis_for_room(self)) { _is_trap_room = true; }
		}
		if (_is_trap_room) { _score += danger_to_points(PORTCULLIS_TRAP_DANGER); }

		// A cursed item makes the rest of the run easier, and so do the strong regular items
		if (has_special_item) { _score += SPECIAL_ITEM_REWARD_POINTS; }
		if (holds_regular_item()) { _score += item_reward_points(chest_obj); }

		// Not scored, with R55's values: any hazard (+0.25); a sin room (+5: the sin limit already keeps it off
		// Easy and Medium, and its quest is time); hidden and locked chests (+0.125 each), optional; lanterns and
		// a lit room (-0.125 each: the player is assumed to see by a lit torch); no cardinal exits (+0.125: the
		// stairs are the way out); misleading exits (+0.125); and doors, locks and illusion walls (+0.025, +0.125
		// and +0.25 per side), which cost time, not danger
		return _score;
	}

	/// @function get_difficulty_score()
	/// @description Scores how dangerous the room is (R55), from its hazards and other contents.
	/// @returns {real}
	function get_difficulty_score() {
		return get_difficulty_score_for(get_hazard_counts());
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
		return get_difficulty_score_for(_counts);
	}

	/// @function get_time_score()
	/// @description How much time the room's hazards cost (R56): 0 for none, and about 1 for each very
	///	significant hold-up, like solving a sin's quest.
	/// @returns {real}
	function get_time_score() {
		var _time = hazard_counts_time(get_hazard_counts());
		if (has_phantom) { _time += PHANTOM_TIME_PER_LANTERN * layout.lantern_count; }
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
	/// @description The walk points a visit must reach (R56): the chest or the heart, the floor key, every
	///	collectable when the room has them, and in a portcullis trap room every spot the button could be under
	///	(just its own spot if the room is lit, since then it shows).
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
		return 1 + CAUTION_PER_DANGER_POINT * max(0, hazard_counts_danger(get_hazard_counts(), true));
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


// =====================================================================================================
// 4. GameMap (scr_game_map)
// =====================================================================================================
// calculate_time_provided replaces the R56 version; the other two are new.

	/// @function calculate_time_provided()
	/// @description The run's total time (R56): every room's share, plus the trips between rooms the map adds,
	///	both times the difficulty's allowance.
	static calculate_time_provided = function() {
		time_provided = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) { time_provided += rooms[_i].get_time_provided(); }
		time_provided += TIME_ALLOWANCE * get_backtracking_time();
	};

	/// @function measure_travel_times(_from_room, _skip_exit, _crossing)
	/// @description Seconds from one room to every other by the quickest way, through side exits and stairs
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
	/// @description Seconds of walking between rooms on top of each room's own visit (R56): carrying the heart
	///	back to the start cross, going back for a key when a lock comes first, coming back to an illusion wall
	///	taken for a dead end, and the wrath quest's trip to the start cross and back. Trips take the quickest way
	///	through the rooms, stairs included, so shortcuts shorten them.
	/// @returns {real}
	static get_backtracking_time = function() {
		var _crossing = array_create(array_length(rooms), 0), _from_start = measure_distances(start_room), _extra = 0;
		for (var _i = 0; _i < array_length(rooms); _i++) { _crossing[rooms[_i].mapgen_index] = rooms[_i].get_crossing_time(); }

		// The finish: the heart has to be carried back to the start cross, from the far end of the map (R10)
		var _heart_times = measure_travel_times(heart_room, undefined, _crossing);
		var _to_finish = _heart_times[start_room.mapgen_index];
		if (_to_finish > 0) { _extra += _to_finish; }

		for (var _j = 0; _j < array_length(side_links); _j++) {
			var _exit = side_links[_j];
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

		// Wrath: the trip to the start cross to lift the curse, and back for the chest
		for (var _n = 0; _n < array_length(rooms); _n++) {
			var _room = rooms[_n];
			if (_room.layout.get_object_count("obj_inverted_cross") == 0) { continue; }
			var _wrath_times = measure_travel_times(_room, undefined, _crossing);
			var _to_start = _wrath_times[start_room.mapgen_index];
			if (_to_start > 0) { _extra += 2 * _to_start; }
		}
		return _extra;
	};
