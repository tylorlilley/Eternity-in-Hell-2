// Turning scores into game values
#macro DANGER_POINT_SCALE 8					// Score points per unit of danger
#macro HAZARD_FULL_TIME 30					// Seconds a time score of 1 is worth: hold-ups on top of walking
 
// Hazards that make each other worse. Each hazard's danger assumes the player can deal with it on their own terms, and the
// more likely the room is to take that away, the closer it gets to its worst case (see get_hazard_combination_multiplier)
#macro WORST_CASE_MULTIPLIER 3				// A hazard the player slows down for, rushed past instead, or ears drawn to the player by noise: like facing it three times, so a spider goes from 0.15 to about 0.39 danger
#macro STOPPED_WORST_CASE_MULTIPLIER 9		// A hazard that stops the player, while they're made to keep moving: eyes go from 0.12 to about 0.68 danger
#macro KEEPS_PLAYER_MOVING_MULTIPLIER 5		// 1 / 0.20: a chaser or shooter as deadly as a phantom (0.20) keeps the player moving all the time, and a less deadly one that share of the time
#macro INCEDENTAL_HAZARD_MAKES_PLAYER_MOVE_CHANCE 0.5	// A wanderer only gets in the way by chance, so it keeps the player moving half as much for its danger
#macro LURE_CHANCE_PER_LOUD_KIND 0.33		// How often each kind of hazard that makes loud noises on its own draws ears to the player
#macro DARK_DANGER_MULTIPLIER 5				// A hazard that's worse in the dark, when the player has no light: a cockroach goes from 0.02 to about 0.10 danger
#macro PHANTOM_TIME_PER_LANTERN 0.03		// Banishing a phantom means lighting every lantern, which takes longer the more there are
#macro TARGETS_PLAYER_TAGS (hazard_tags.moves_towards_player | hazard_tags.fires_at_player)						// What keeps the player on the move by coming for them
#macro STOPPED_BY_STAFF_TAGS (hazard_tags.fires_at_player | hazard_tags.fires_in_place | hazard_tags.immune_with_staff)	// What can't hurt a player holding a staff
#macro MAP_ENCOUNTER_CHANCE_MULTIPLIER 3		// How likely the player is to have something, per share of the map's rooms holding it: one sword chest in fifteen rooms gives a 0.2 chance of holding a sword
#macro BLOCK_COUNTER_MULTIPLIER 0.6			// A hazard a block can stop keeps this share of its danger: the layout lets a block be lined up with it about half the time, and setting the block up carries about a fifth of the hazard's own risk
 
// The room's other content
#macro COLLECTABLES_EXPOSURE 1.4			// Collecting everything crosses the whole room, so its hazard danger counts 1.4 times
#macro PORTCULLIS_TRAP_DANGER 0.03			// Shut in until the button is pressed, once per trap room
#macro SPECIAL_ITEM_REWARD_POINTS -2		// A special item makes the rest of the run easier, so the map can take more
 
// The time a careful novice needs, and how many times that the run gives
#macro PLAYER_STEPS_PER_SECOND 10			// One 8-pixel step a tick, 10 ticks a second
#macro ROOM_ENTRY_TIME 2					// Seconds each visit costs before any walking: the transition and a look around
#macro CAUTION_PER_DIFFICULTY_POINT 0.2			// Walking slows by this share for each point of the room's hazard danger
#macro TIME_ALLOWANCE get_probability_for_difficulty([0, 2.5, 2, 1.75, 1.5])	// Time given as a multiple of time needed; these keep the average run as long as now
#macro LOCK_BACKTRACK_SHARE 0.5				// How often a lock comes before its key, sending the player back for one
#macro ILLUSION_WALL_MISS_CHANCE 0.5		// How often an illusion wall passes for a dead end until everything else is explored
#macro ILLUSION_WALL_SEARCH_TIME 10			// Seconds to find the wall once back at it
#macro LAYOUT_SIZE 256						// Every layout room is this many pixels square
 
// What the combination rules and counters need to know about each hazard. Each tag is its own bit, so a hazard's tags
// combine with |, and checking for any of several tags takes one &
enum hazard_tags {
	none = 0,
	stationary = 1,				// Always covers a set spot or path in the room, and can't move off it
	stops_player_movement = 2,		// While in the room, forces the player to stop moving entirely
	slows_player_movement = 4,		// While in the room, forces the player to move slower and more carefully
	moves_towards_player = 8,		// Always moves towards and chases the player
	fires_at_player = 16,			// Shoots projectiles aimed at the player
	fires_in_place = 32,			// Shoots projectiles in a fixed direction from where it stands
	killed_by_sword = 64,			// Can be destroyed with a sword
	makes_loud_noise = 128,			// Makes noises on its own that can alert ears
	listens_to_loud_noise = 256,	// Hunts down loud noises
	dangerous_in_dark = 512,		// Becomes much harder when the player has no light
	immune_with_staff = 1024,		// Can't hurt a player holding a staff, like lava
	lights_torches = 2048,			// Shoots fireballs, which light a torch dropped in their way
	stopped_by_block = 4096,		// A pushed block crushes it, covers the spot it shoots into, or turns it around, and can then be pushed on to another
	uses_up_block = 8192			// A pushed block stops it but is used up: lava turns it into a bridge, and mouths and fire skeletons take it with them
}
 
/// @function get_difficulty_score_table()
/// @description Every hazard's scores, in one place. Hazards are named for their objects, so a layout's object counts read
///	straight into the table, and the ones generation adds use their objects' names too.
///
///	danger: the chance a novice dies to one in a typical room visit, from 0 to 1. It assumes the player knows
///		what the hazard does (luring the ears included), has light, and holds no item. The counters they might
///		hold, and the chance they have no light, come in through the room
///
///	time: the hold-ups it causes on top of walking, from 0 (none) to 1 (HAZARD_FULL_TIME seconds, like a special room's
///		quest). The walking itself is measured on the layout and slowed by danger (get_time_needed).
///
///	many, time_many: how more copies in one room add up, as a power of the count: 1 additive, under 1
///		diminishing, over 1 compounding, and 0 flat (only the first one counts).
///
///	min_difficulty: the lowest difficulty it appears on. A layout that places it only appears from there, however low
///		its scores (see RoomLayout.determine_minimum_difficulty). For a hazard no layout places, it only records the
///		lowest difficulty whose spawn chances can spawn it.
///
///	tags: what the combination rules and counters need to know about it (see hazard_tags).
///
///	Bones, bushes and corpses aren't in the table: they aren't dangerous themselves, only what spawns from them during
///	play (see RoomLayout.get_mid_game_spawns).
/// @returns {struct}
function get_difficulty_score_table() {
	static _table = {
		// Placed by layouts
		obj_statue:				{ danger: 0.04,		many: 1,	time: 0.03,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.stationary | hazard_tags.fires_in_place | hazard_tags.lights_torches | hazard_tags.stopped_by_block },
		obj_fountain:			{ danger: 0.06,		many: 1.1,	time: 0.05,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.stationary | hazard_tags.fires_at_player},
		// Per mouth the layout places; the extra ones higher difficulties add aren't counted
		obj_mouth:				{ danger: 0.08,		many: 0.8,	time: 0.30,		time_many: 0.3,		min_difficulty: difficulties.easy,		tags: hazard_tags.slows_player_movement | hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.uses_up_block },
		// Each one after the first adds less danger and time: already moving slowly for one, the player is mostly ready for the next, and rarely has to get past every one
		obj_spider:				{ danger: 0.15,		many: 0.7,	time: 0.08,		time_many: 0.7,	min_difficulty: difficulties.medium,	tags: hazard_tags.slows_player_movement | hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block },
		// One hidden spider, whatever the spot count: building always puts a spider on one of the spots, so it's tagged like one
		obj_spider_spot:		{ danger: 0.20,		many: 0,	time: 0.10,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.slows_player_movement | hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block },
		// Each one adds about its own danger: the player waits out each in turn, and two can pinch them between their paths
		obj_snake:				{ danger: 0.07,		many: 1,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.slows_player_movement | hazard_tags.killed_by_sword | hazard_tags.stopped_by_block },
		obj_giant_worm_head:	{ danger: 0.04,		many: 0.75,	time: 0.05,		time_many: 0.75,	min_difficulty: difficulties.medium,	tags: hazard_tags.stationary | hazard_tags.stopped_by_block },
		// Per segment: long worms block corridors longer
		obj_giant_worm_body:	{ danger: 0,		many: 1,	time: 0.003,	time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.stationary },
		obj_eyes:				{ danger: 0.12,		many: 0,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stops_player_movement | hazard_tags.slows_player_movement | hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block },
		obj_ears:				{ danger: 0.30,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.slows_player_movement | hazard_tags.killed_by_sword | hazard_tags.listens_to_loud_noise | hazard_tags.stopped_by_block },
		// Per room, not per tile:
		obj_lava:				{ danger: 0.04,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.stationary | hazard_tags.immune_with_staff | hazard_tags.uses_up_block },
		// The block each spot spawns, plain or living: no danger, but it takes time to push out of the way, and it can stop some hazards (see BLOCK_COUNTER_MULTIPLIER)
		obj_block_spot:			{ danger: 0,		many: 1,	time: 0.015,	time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.stationary},
 
		// Special room objects. The special room limit already keeps their rooms off Easy and Medium; time covers each special room's quest
		obj_giant_eye:			{ danger: 0.17,		many: 1,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary | hazard_tags.fires_at_player },
		// The trip to the start cross and back is map travel (GameMap.get_backtracking_time)
		obj_inverted_cross:		{ danger: 0.25,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.moves_towards_player },
		obj_hall_of_mirrors:	{ danger: 0,		many: 0,	time: 1.00,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary },
		obj_red_chest:			{ danger: 0.01,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary },
		obj_gudetama:			{ danger: 0.01,		many: 1,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary | hazard_tags.killed_by_sword | hazard_tags.stopped_by_block },
 
		// Spawns on skeleton spots, named for their objects too (snakes and eyes use the entries above)
		obj_skeleton:			{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.stopped_by_block },
		obj_cockroach:			{ danger: 0.02,		many: 1,	time: 0.01,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.dangerous_in_dark | hazard_tags.stopped_by_block },				// In light; hunting in the dark it's 0.10
		obj_fast_skeleton:		{ danger: 0.13,		many: 1,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.killed_by_sword | hazard_tags.slows_player_movement | hazard_tags.stopped_by_block },
		obj_fat_skeleton:		{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block },
		obj_cultist:			{ danger: 0.16,		many: 1.2,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.hard,		tags: hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.fires_at_player | hazard_tags.stopped_by_block },
		obj_fire_skeleton:		{ danger: 0.18,		many: 1.15,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.hard,		tags: hazard_tags.killed_by_sword | hazard_tags.fires_at_player | hazard_tags.immune_with_staff | hazard_tags.lights_torches | hazard_tags.uses_up_block },
 
		// Spawns during map creation
		obj_phantom:				{ danger: 0.20,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.moves_towards_player },
		obj_floater:				{ danger: 0.08,		many: 0,	time: 0.15,		time_many: 0,		min_difficulty: difficulties.medium,	tags: hazard_tags.moves_towards_player },
		obj_nose:					{ danger: 0.10,		many: 1,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.fires_at_player | hazard_tags.lights_torches },	// Aimed where the player is, so walking along a bridge dodges it too
		// Its spot still counts its block, for the push time and what it can stop
		obj_living_block:			{ danger: 0.10,		many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.slows_player_movement },
		// For trapped chests only:
		obj_chest:					{ danger: 0.12,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary },
		// For moving collectables only:
		obj_collectable:			{ danger: 0,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.medium,	tags: hazard_tags.none },
 
		// Spawns during play (see RoomLayout.get_mid_game_spawns)
		// A red bug: once it reaches the player, their moves are left to chance for a while. Bugs of other colors run away and can't harm them
		obj_bug:					{ danger: 0.05,		many: 1,	time: 0.20,		time_many: 1,		min_difficulty: difficulties.hard,		tags: hazard_tags.moves_towards_player | hazard_tags.stopped_by_block },
		// Comes for an item lying on the floor and runs off with it, laughing. It's deadly to touch, and the item has to be won back
		obj_hands:					{ danger: 0.06,		many: 1,	time: 0.30,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block }
	};
	return _table;
}
 
/// @function get_hazard_time_score(_name, _count)
/// @description The time score for _count of a hazard in one room, following its time_many rule, at most 1.
/// @param {string} _name The hazard's name in the table
/// @param {real} _count How many; can be fractional when it's an expected count
/// @returns {real}
function get_hazard_time_score(_name, _count) {
	// Return 0 for hazards not in the hazard table or final room count
	var _table = get_difficulty_score_table(), _entry = _table[$ _name];
	if (is_undefined(_entry) || _count <= 0) { return 0; }
	
	// MOdify the time score based on the number of copies of this hazard, as per the table
	var _copies = (_entry.time_many == 0) ? min(1, _count) : power(_count, _entry.time_many);
	return min(1, _entry.time * _copies);
}
 
/// @function hazard_has_tag(_hazard_name, _tags)
/// @description Whether a hazard has any of some tags
/// @param {string} _hazard_name The hazard's name in the table
/// @param {real} _tags One hazard_tags flag, or several combined with |
/// @returns {bool}
function hazard_has_tag(_hazard_name, _tags) {
	var _table = get_difficulty_score_table(), _entry = _table[$ _hazard_name];
	return !is_undefined(_entry) && ((_entry.tags & _tags) != 0);
}
 
/// @function count_hazards_with_tags(_hazard_counts, _tags_to_count, [_ignored_hazard_name])
/// @description How many kinds of hazard in a room have any of a given taq
/// @param {struct} _hazard_counts 					The count struct of hazards in the room
/// @param {real} _tags_to_count  					The hazard tags that should be counted
/// @param {string|undefined} _ignored_hazard_name	The hazard to leave out, or undefined to count every hazard in the room
/// @returns {real}
function count_hazards_with_tags(_hazard_counts, _tags_to_count, _ignored_hazard_name = undefined) {
	var _table = get_difficulty_score_table(), _hazard_names = variable_struct_get_names(_hazard_counts), _tag_count = 0;
	
	// Loop through each hazard in the given hazard counts struct
	for (var _i = 0; _i < array_length(_hazard_names); _i++) {
		// Skip the hazard itself, and any that isn't in the room or the table
		var _hazard_name = _hazard_names[_i], _hazard_table_entry = _table[$ _hazard_name], _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name);
		if ((!is_undefined(_ignored_hazard_name) && _hazard_name == _ignored_hazard_name) || is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
		
		// Count it if it has one of the tags
		if ((_tags_to_count == hazard_tags.none) || ((_hazard_table_entry.tags & _tags_to_count) != 0)) { _tag_count += 1; }
	}
	
	return _tag_count;
}

/// @function get_time_score_for_hazard_counts(_counts)
/// @description The time score for a set of hazards in one room: each one's time score, added up.
/// @param {struct} _counts Hazard names and how many of each
/// @returns {real}
function get_time_score_for_hazard_counts(_counts) {
	var _names = variable_struct_get_names(_counts), _time = 0;
	for (var _i = 0; _i < array_length(_names); _i++) { _time += get_hazard_time_score(_names[_i], _counts[$ _names[_i]]); }
	return _time;
}
 
/// @function get_hazard_counts_with_spawn(_counts, _spawn)
/// @description A copy of a room's hazard counts with one more of something that might spawn, in place of what it replaces
/// @param {struct} _counts Hazard names and how many of each
/// @param {struct} _spawn What spawns (see ExpectedSpawn)
/// @returns {struct}
function get_hazard_counts_with_spawn(_counts, _spawn) {
	var _spawned_counts = hazard_counts_copy(_counts);
	hazard_count_add(_spawned_counts, _spawn.hazard_name, 1);
	if (!is_undefined(_spawn.replaced_hazard_name)) { hazard_count_add(_spawned_counts, _spawn.replaced_hazard_name, -1); }
	return _spawned_counts;
}
 
/// @function get_time_score_with_spawns(_counts, _spawns)
/// @description The time score for a room's hazards (see get_time_score_for_hazard_counts), with what might spawn into it
///	added on average, the same way PlayerChance adds their difficulty points
/// @param {struct} _counts Hazard names and how many of each, for the room
/// @param {array} _spawns What might spawn (see ExpectedSpawn)
/// @returns {real}
function get_time_score_with_spawns(_counts, _spawns) {
	var _time_score = get_time_score_for_hazard_counts(_counts), _expected_time_score = 0;
	for (var _i = 0; _i < array_length(_spawns); _i++) {
		var _spawn = _spawns[_i];
		if (_spawn.expected_count <= 0) { continue; }
		
		_expected_time_score += _spawn.expected_count * (get_time_score_for_hazard_counts(get_hazard_counts_with_spawn(_counts, _spawn)) - _time_score);
	}
	
	return _time_score + _expected_time_score;
}

/// @function get_skeleton_type_chances()
/// @description What a skeleton spot can hold at the current difficulty, aside from a basic skeleton, with it's chance out of SKELETON_TYPE_CHANCE_MAX
/// @returns {array} The ordered array of each type as { type, chance }
function get_skeleton_type_chances() {
	switch (global.difficulty) {
		case difficulties.easy: return [{ type: obj_cockroach, chance: 3 }];
		case difficulties.medium: return [{ type: obj_cockroach, chance: 6 }, { type: obj_fast_skeleton, chance: 6 }, { type: obj_fat_skeleton, chance: 4 }];
		case difficulties.hard: return [{ type: obj_cockroach, chance: 12 }, { type: obj_fat_skeleton, chance: 8 }, { type: obj_fast_skeleton, chance: 8 }, { type: obj_cultist, chance: 6 }, { type: obj_fire_skeleton, chance: 6 }];
		case difficulties.very_hard: return [{ type: obj_cockroach, chance: 15 }, { type: obj_fat_skeleton, chance: 20 }, { type: obj_fast_skeleton, chance: 15 }, { type: obj_cultist, chance: 12 }, { type: obj_fire_skeleton, chance: 13 }, { type: obj_snake, chance: 5 }];
		default: return [];
	}
}

/// @function get_hazard_danger_from_table(_hazard_name, _hazard_count)
/// @description Return's a hazards danger score based on it's danger and many entries from the table
/// @param {string} _hazard_name		The hazard's name in the table
/// @param {real} _hazard_count			The number of this hazard in the room
/// @returns {real}
function get_hazard_danger_from_table(_hazard_name, _hazard_count) {
	// Return 0 for hazards not in the hazard table or final room count
	var _table = get_difficulty_score_table(), _table_entry = _table[$ _hazard_name];
	if (is_undefined(_table_entry) || _hazard_count <= 0) { return 0; }
	
	// Modify the difficulty score based on the number of copies of this hazard, as per the table
	var _table_danger = _table_entry.danger, _table_many = _table_entry.many;
	var _hazard_copies = (_table_many == 0) ? min(1, _hazard_count) : power(_hazard_count, _table_many);
	return _hazard_copies * _table_danger;
}

/// @function get_hazard_combination_multiplier(_counts, _hazard_name)
/// @description How many times its own danger points a hazard is worth, for the hazards it shares a room with. Its danger
///	assumes the player can deal with it on their own terms: slowing down for it, stopping when it says to, or keeping it
///	from hearing them. The more likely the others are to take that away, by keeping the player moving or by drawing the
///	ears to them with their noise, the closer it gets to its worst case: WORST_CASE_MULTIPLIER, or
///	STOPPED_WORST_CASE_MULTIPLIER for one that stops the player.
/// @param {struct} _hazard_counts		Hazard names and how many of each, for the room
/// @param {string} _hazard_name		The hazard's name in the table
/// @returns {real} At least 1
function get_hazard_combination_multiplier(_hazard_counts, _hazard_name) {
	// A factor of 1 if it is the only relevant hazard in the room
	var _hazard_score_factor = 1;
	
	// Shrink the hazard score factor based on the relevant tags of other hazards in the hazards counts
	if (hazard_has_tag(_hazard_name, hazard_tags.slows_player_movement | hazard_tags.stops_player_movement)) {
		_hazard_score_factor *= 1 - get_chance_to_make_player_move(_hazard_counts, _hazard_name);
	}
	if (hazard_has_tag(_hazard_name, hazard_tags.listens_to_loud_noise)) {
		_hazard_score_factor *= power(1 - LURE_CHANCE_PER_LOUD_KIND, count_hazards_with_tags(_hazard_counts, hazard_tags.makes_loud_noise, _hazard_name));
	}
	
	// Scale the hazard score factor by the appropriate worst case multiplier and the inverse of the hazard score factor
	var _worst_case_multiplier = hazard_has_tag(_hazard_name, hazard_tags.stops_player_movement) ? STOPPED_WORST_CASE_MULTIPLIER : WORST_CASE_MULTIPLIER;
	var _hazard_combination_multiplier = (_worst_case_multiplier - 1) * (1 - _hazard_score_factor);
	return 1 + (_hazard_combination_multiplier);
}

/// @function get_chance_kept_moving(_hazard_counts, _hazard_name)
/// @description How likely the other hazards in a room are to keep the player moving while they deal with this hazard.
///	 Hazards that are stationary or slow the player down don't effect this. They all push at once, so their chances overlap rather than add up.
/// @param {struct} _hazard_counts		Hazard names and how many of each, for the room
/// @param {string} _hazard_name		The hazard being dealt with
/// @returns {real} How likely the player is to be forced to move while dealing with this hazard, From 0 to 1
function get_chance_to_make_player_move(_hazard_counts, _hazard_name) {
	var _table = get_difficulty_score_table(), _hazard_names = variable_struct_get_names(_hazard_counts), _chance_to_not_make_player_move = 1;
	var _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name);
	if (_hazard_count <= 0) { return 0; }

	// If the hazard exists, loop through each other hazard type in the given count struct
	for (var _i = 0; _i < array_length(_hazard_names); _i++) {
		// Skip the hazard itself, and any others that aren't in the room or the table
		var _other_hazard_name = _hazard_names[_i], _other_hazard_table_entry = _table[$ _other_hazard_name], _other_hazard_count = get_count_from_struct(_hazard_counts, _other_hazard_name);
		if (_other_hazard_count <= 0 || _other_hazard_name == _hazard_name || is_undefined(_other_hazard_table_entry)) { continue; }
		
		// Things that target the player apply their full danger, things that incedentally can kill the player apply only half
		var _danger_ratio = 0, _other_hazard_tages = _other_hazard_table_entry.tags;
		if ((_other_hazard_tages & TARGETS_PLAYER_TAGS) != 0) { _danger_ratio = 1; }
		else if ((_other_hazard_tages & (hazard_tags.stationary | hazard_tags.slows_player_movement)) == 0) { _danger_ratio = INCEDENTAL_HAZARD_MAKES_PLAYER_MOVE_CHANCE; }
		
		// Use this danger ratio to determine the chance this hazard makes the player move
		var _other_hazard_danger = get_hazard_danger_from_table(_other_hazard_name, _other_hazard_count) * KEEPS_PLAYER_MOVING_MULTIPLIER;
		var _player_moving_chance = min(1, _danger_ratio * _other_hazard_danger);
		_chance_to_not_make_player_move *= 1 - _player_moving_chance;
	}
	
	return 1 - _chance_to_not_make_player_move;
}

/// @function get_difficulty_points_from_danger_score(_danger_score)
/// @description A danger is a chance of dying, and chances can't simply be added: two hazards that each kill half the time don't kill
/// every time together, only three times out of four, since surviving means surviving both. What combines simply is
/// surviving: the chances of surviving each hazard multiply. Taking -ln of the chance of surviving, 1 - danger, turns
/// that multiplying into adding, so the result (difficulty points) can be added up across hazards and rooms. Small dangers
/// stay about the same (0.05 is 0.051 points), but the points grow faster as a danger nears certain death (0.5 is 0.69,
/// 0.9 is 2.3), and capping the danger at 0.99 stops certain death from being worth infinite points.
/// @param {real} _danger_score		The danger score to translate into difficulty points
/// @returns {real}
function get_difficulty_points_from_danger_score(_danger_score) {
	return -ln(1 - min(_danger_score, 0.99)) * DANGER_POINT_SCALE;
}