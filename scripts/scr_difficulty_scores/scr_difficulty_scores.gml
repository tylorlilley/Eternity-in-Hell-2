// Turning scores into game values
#macro DANGER_POINT_SCALE 8					// Score points per unit of danger
#macro HAZARD_FULL_TIME 30					// Extra Seconds a time score of 1 is worth: hold-ups on top of walking,
#macro SWORD_CARRY_CHANCE 0.15				// Rough average of how often a player will have a sword
#macro STAFF_CARRY_CHANCE 0.1				// Rough average of how often a player will have a staff
 
// Difficulty and Time Thresholds
#macro LAYOUT_MEDIUM_DANGER 1.0				// Difficulty Threshold for Medium and Up
#macro LAYOUT_HARD_DANGER 2.2				// Time Threshold for Hard and Up
#macro LAYOUT_MEDIUM_TIME 0.3				// Time Threshold for Hard and up
#macro LAYOUT_HARD_TIME 0.5
 
// Hazards that make each other worse
#macro COCKROACH_WITH_DARK_DANGER 0.07		// Banishing a phantom means lighting every lantern, which takes longer the more there 
#macro EYES_WITH_FORCER_DANGER 0.70			// STOP vs GO: eyes, plus anything that keeps the player moving
#macro MOUTHS_WITH_HURRIER_DANGER 0.50		// RUSH vs MINES: 3 or more mouths, plus anything that makes the player hurry
#macro STATUE_WITH_CHASER_DANGER 0.15		// TIMING vs CHASE: each statue, when something chases the player
#macro EARS_DANGER_PER_LOUD_KIND 0.10		// SILENCE: added to the ears for each kind of hazard here that makes loud sounds on its own
#macro PHANTOM_TIME_PER_LANTERN 0.03		// Banishing a phantom means lighting every lantern, which takes longer the more there are
 
// The room's other content Multipliers
#macro COLLECTABLES_EXPOSURE 1.4			// Collecting everything crosses the whole room, so its hazard danger counts 1.4 times
#macro PORTCULLIS_TRAP_DANGER 0.03			// Shut in until the button is pressed, once per trap room
#macro SPECIAL_ITEM_REWARD_POINTS -2		// A cursed item makes the rest of the run easier, so the map can take more
// Regular items count through item_reward_points [-0.25 for any chest without a key-role item]
 
// Time variables hat a careful novice needs, then how many times that the run gives
#macro PLAYER_STEPS_PER_SECOND 10			// One 8-pixel step a tick, 10 ticks a second
#macro ROOM_ENTRY_TIME 2					// Seconds each visit costs before any walking: the transition and a look around
#macro CAUTION_PER_DANGER_POINT 0.2			// Walking slows by this share for each point of the room's hazard danger
#macro TIME_ALLOWANCE get_probability_for_difficulty([0, 2.5, 2, 1.75, 1.5])	// Time given as a multiple of time needed; these keep the average run as long as now
#macro LOCK_BACKTRACK_SHARE 0.5				// How often a lock comes before its key, sending the player back for one
#macro ILLUSION_WALL_MISS_CHANCE 0.5		// How often an illusion wall passes for a dead end until everything else is explored
#macro ILLUSION_WALL_SEARCH_TIME 10			// Seconds to find the wall once back at it
#macro LAYOUT_SIZE 256						// Every layout room is this many pixels square
 
/// @function get_difficulty_score_table()
/// @description Every hazard's scores, in one place. Placed hazards are named for their objects,
///	so a layout's object counts read straight into the table; generated ones have names of their own.
///
///	danger: the chance a novice dies to one in a typical room visit, from 0 to 1. It assumes the player knows
///		what the hazard does (luring the ears included), can see by a lit torch as R55 does, and holds no item;
///		swords come in through SWORD_CARRY_CHANCE.
///
///	time: the hold-ups it causes on top of walking, from 0 (none) to 1 (HAZARD_FULL_TIME seconds, like a sin's
///		quest). The walking itself is measured on the layout and slowed by danger (get_time_needed).
///
///	many, time_many: how more copies in one room add up, as a power of the count: 1 additive, under 1
///		diminishing, over 1 compounding, and 0 flat (only the first one counts).
///
///	min_difficulty: the lowest difficulty a layout that places it can appear on.
///
///	sword: how much of the danger a held sword can absorb, from 0 to 1: 1 for what it kills on touch, a part for
///		what it kills but that mostly shoots, and 0 (or missing) for what it can't kill.
///
///	Tags for the conflict rules:
		
///		static					(hazard always covers a set spot or path in the room and it cannot move out o fit)
///		stops_player_movement	(while in the room, forces player to stop moving entirely)
///		slows_player_movement	(while in the room, forces a player to move slower and more carefully)
///		moves_towards_player	(always moves towards and chases the player)
///		fires_at_player			(shoots projectiles that are aimed at the player)
///		killed_by_sword			(can be destroyed with a sword)
///		makes_loud_noise		(makes a noise that can alert ears)
//		dangerous_in_dark		(becomes much harder in the dark)
		
///
/// @returns {struct}
function get_difficulty_score_table() {
	// TODO: We should turn these tags into enums and not strings?
	static _table = {
		// Placed by layouts
		obj_statue:				{ danger: 0.04,		many: 1,	time: 0.03,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["static"]},
		obj_fountain:			{ danger: 0.06,		many: 1.1,	time: 0.05,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["static", "fires_at_player"]},
		obj_mouth:				{ danger: 0.08,		many: 0.8,	time: 0.30,		time_many: 0.3,		min_difficulty: difficulties.easy,		tags: ["slows_player_movement", "killed_by_sword", "makes_loud_noise"]},	// Per mouth, extra ones included
		obj_spider:				{ danger: 0.15,		many: 1.3,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["slows_player_movement", "killed_by_sword", "makes_loud_noise"]},
		obj_spider_spot:		{ danger: 0.20,		many: 0,	time: 0.10,		time_many: 0,		min_difficulty: difficulties.easy,		tags: [] },	// One hidden spider, whatever the spot count
		obj_snake:				{ danger: 0.07,		many: 1.4,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.medium,	tags: ["slows_player_movement", "killed_by_sword", "makes_loud_noise"] },
		obj_giant_worm_head:	{ danger: 0.04,		many: 0.75,	time: 0.05,		time_many: 0.75,	min_difficulty: difficulties.easy,		tags: ["static"]},
		obj_giant_worm_body:	{ danger: 0,		many: 1,	time: 0.003,	time_many: 1,		min_difficulty: difficulties.easy,		tags: ["static"] },				// Per segment: long worms block corridors longer
		obj_eyes:				{ danger: 0.12,		many: 0,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["stops_player_movement", "slows_player_movement", "moves_towards_player", "killed_by_sword", "makes_loud_noise"]},
		obj_ears:				{ danger: 0.30,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["slows_player_movement", "killed_by_sword"] },
		obj_lava:				{ danger: 0.04,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.easy,		tags: ["static", "immune_with_staff"]},				// Per room, not per tile
		obj_block_spot:			{ danger: 0,		many: 1,	time: 0.015,	time_many: 1,		min_difficulty: difficulties.easy,		tags: ["static"]},				// Their danger is obj_living_block, below
		obj_bones:				{ danger: 0.0024,	many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["static", "slows_player_movement", "killed_by_sword", "makes_loud_noise"] },
		obj_player_corpse:		{ danger: 0.005,	many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["static"] }, // Score is for the red bugs it could spawn
 
		// Sin objects. The sin limit already keeps their rooms off Easy and Medium; time covers each sin's quest
		obj_giant_eye:			{ danger: 0.17,		many: 1,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["static", "fires_at_player"] },	// Killing it takes about 0.45 danger
		obj_inverted_cross:		{ danger: 0.25,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["moves_towards_player"] },				// The trip to the start cross and back is map travel (GameMap.get_backtracking_time)
		obj_hall_of_mirrors:	{ danger: 0,		many: 0,	time: 1.00,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["static"] },
		obj_red_chest:			{ danger: 0.01,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["static"] },
		obj_gudetama:			{ danger: 0.01,		many: 1,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		tags: ["static", "killed_by_sword"] },
 
		// Spawns on skeleton spots, named for their objects too (snakes and eyes use the entries above)
		obj_skeleton:			{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["killed_by_sword"] },
		obj_cockroach:			{ danger: 0.02,		many: 1,	time: 0.01,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["killed_by_sword", "dangerous_in_dark"] },				// In light; hunting in the dark it's 0.10
		obj_fast_skeleton:		{ danger: 0.13,		many: 1,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["killed_by_sword", "slows_player_movement"] },
		obj_fat_skeleton:		{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["killed_by_sword", "makes_loud_noise"] },
		obj_cultist:			{ danger: 0.16,		many: 1.2,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["killed_by_sword", "makes_loud_noise", "fires_at_player"] },	// A sword only helps against its touch, not its beams
		obj_fire_skeleton:		{ danger: 0.18,		many: 1.15,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["killed_by_sword", "fires_at_player", "immune_with_staff"] },	// A sword only helps against its touch, not its shots
 
		// Spawns during map creation
		obj_phantom:				{ danger: 0.20,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.easy,		tags: ["moves_towards_player"] },
		obj_floater:				{ danger: 0.08,		many: 0,	time: 0.15,		time_many: 0,		min_difficulty: difficulties.easy,		tags: ["moves_towards_player"] },
		obj_nose:					{ danger: 0.10,		many: 1,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["fires_at_player"] },	// Aimed where the player is, so walking along a bridge dodges it too
		//lava_fire_skeleton:		{ danger: 0.20,		many: 1,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["fires_at_player"] },	// Out of reach of a sword or block; its shots can be dodged on bridges, like a nose's
		obj_living_block:			{ danger: 0.10,		many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy,		tags: ["slows_player_movement"] },
		obj_chest:					{ danger: 0.12,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.easy,		tags: ["static"] }, // For trapped chests only
		obj_collectable:			{ danger: 0,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.easy,		tags: [] } // For moving collectables only
	};
	return _table;
}
 
/// @function get_difficulty_score_for_danger_level(_danger)
/// @description Translate the danger value to a difficulty_score
/// @param {real} _danger From 0 to 1
/// @returns {real}
function get_difficulty_score_for_danger_level(_danger) {
	// TODO: Why do we need to maintain a separate scoring system for danger and difficulty points? Can't we simply convert everywhere that used difficulty points to be 1/8 their points and thus equivalent to the difficulty score? Then we don't need to do this extra translation
	return (_danger <= 0) ? 0 : -ln(1 - min(_danger, 0.99)) * DANGER_POINT_SCALE;
}

/// @function get_hazard_difficulty_score(_name, _count)
/// @description Danger points for _count of a hazard in one room, following its many rule.
/// @param {string} _name The hazard's name in the table
/// @param {real} _count How many; can be fractional when it's an expected count
/// @returns {real}
function get_hazard_difficulty_score(_name, _count) {
	// Return 0 for hazards not in the hazard table or final room count
	var _table = get_difficulty_score_table(), _entry = _table[$ _name];
	if (is_undefined(_entry) || _count <= 0) { return 0; }
	
	// Modify the difficulty score based on the number of copies of this hazard, as per the table
	var _copies = (_entry.many == 0) ? min(1, _count) : power(_count, _entry.many);
	return _copies * get_difficulty_score_for_danger_level( _entry.danger);
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
 
/// @function hazard_has_tag(_name, _tag)
/// @description Whether a hazard has a conflict-rule tag: forces, hurries, chases or loud.
/// @param {string} _name The hazard's name in the table
/// @param {string} _tag The tag
/// @returns {bool}
function hazard_has_tag(_name, _tag) {
	var _table = get_difficulty_score_table(), _entry = _table[$ _name];
	return !is_undefined(_entry) && variable_struct_exists(_entry, _tag) && _entry[$ _tag];
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
 
/// @function get_difficulty_score_for_hazard_counts(_counts)
/// @description Totals the difficulty score for all hazards in the room. Takes into account multiple coppies of a given hazard, and how hazard's traits affect each other.
/// @param {struct} _counts Hazard names and how many of each
/// @returns {real}
function get_difficulty_score_for_hazard_counts(_counts) {
	var _hazard_names = variable_struct_get_names(_counts), _table = get_difficulty_score_table()
	// TODO: for this and the sword carry chance, we should base this on what items were spawned on the map, not on a hardcoded average chance.
	// It should be the chance that the item spawned and the player encountered it before hand - maybe a dumb approach like total rooms divded by
	// rooms with that item type assigned? And a separate count should be used for the regular and special sword. Similar for lit rooms, total lit rooms/total rooms?
	var _staff_carry_chance = 0.125;
	var _sword_carry_chance = 0.15;
	var _special_sword_carry_chance = 0.01;
	var _torch_carry_chance = 0.2;
	var _lit_room_encountered_chance = 0.2;
 
	// Loop through each row of the table, to accumulate what tags are present for this room
	var _room_hazard_tag_counts = {};
	for (var _i = 0; _i < array_length(_hazard_names); _i++) {
		// Skip hazards that aren't present in the room
		var _hazard_name = _hazard_names[_j], _hazard_count = _counts[$ _hazard_name];
		if (_hazard_count == 0) { continue; }
		
		// Add each tag for this hazard to the present tag counts
		var _hazard_tags = _table[$ _hazard_name].tags
		for (var _j = 0; _j < array_length(_hazard_tags); _j++) {
			var _hazard_tag = _hazard_tags[_j];
			_room_hazard_tag_counts[$ _hazard_tag] ??= 0;
			_room_hazard_tag_counts[$ _hazard_tag] += 1;
		}
	}

	// Loop through each row of the difficulty table, and sum it's score appropriately for the given counts
	var _max_difficulty_saved_by_sword = 0; // Assume a sword is used on just a single one of the worst enemies in the room
	var _hazard_tags = variable_struct_get_names(_room_hazard_tag_counts), _total_room_difficulty = 0;
	for (var _j = 0; _j < array_length(_hazard_names); _j++) {
		// Skip hazards that aren't present in the room
		var _hazard_name = _hazard_names[_j], _hazard_count = _counts[$ _hazard_name], _hazard_tags = _table[$ _hazard_name];
		if (_hazard_count == 0) { continue; }
		
		// Get the standard difficulty score for this hazard type
		var _hazard_difficulty_score = get_hazard_difficulty_score(_hazard_name, _hazard_count);
		if (array_contains(_hazard_tags, "killed_by_sword")) {
			var _hazard_difficulty_score_after_used_sword = get_hazard_difficulty_score(_hazard_name, _hazard_count-1);
			var _difficulty_saved_by_sword = _hazard_difficulty_score - _hazard_difficulty_score_after_used_sword
			_max_difficulty_saved_by_sword = max(_max_difficulty_saved_by_sword, _difficulty_saved_by_sword);
		}
		
		// Modify difficulty score based on tags that are present
		// TODO: Can we genericize any of the below repeated code into functions?
		if (array_contains(_hazard_tags, "stops_player_movement")) {
			// Flag as an impossible combination; this should NEVER happen
			// TODO: How can we ensure this never happens?
			var _impossible_combination_tag_count = _room_hazard_tag_counts["moves_towards_player"] + _room_hazard_tag_counts["fires_at_player"]
			if (_impossible_combination_tag_count > 0) {
				_hazard_difficulty_score *= 9999;
				write_debug_message("Impossible tag combination encountered", debug_message_level.warning);
			}
		}
		if (array_contains(_hazard_tags, "slows_player_movement")) {
			// Multiply difficulty when combined with other hazard types that also slow or target player movement
			// TODO: What should these multiplier constants be? I took a guess
			var _other_slow_tag_count = _room_hazard_tag_counts["slows_player_movement"] - 1 // Doesn't count itself
			_hazard_difficulty_score += _other_slow_tag_count * 1.12;
			
			var _other_chase_tag_count = _room_hazard_tag_counts["moves_towards_player"]
			if array_contains(_hazard_tags, "moves_towards_player") { _other_chase_tag_count -= 1; } // Doesn't count itself
			_hazard_difficulty_score += _other_chase_tag_count * 2.25;
			
			var _other_shoot_tag_count = _room_hazard_tag_counts["fires_at_player"]
			if array_contains(_hazard_tags, "fires_at_player") { _other_shoot_tag_count -= 1; } // Doesn't count itself
			_hazard_difficulty_score += _other_shoot_tag_count * 2.25;
		}
		if (_hazard_name == "obj_ears" && array_contains(_hazard_tags, "makes_loud_noise")) {
			// Noises make things much harder in an ears room
			var _other_noise_tag_count = _room_hazard_tag_counts["makes_loud_noise"]
			if array_contains(_hazard_tags, "makes_loud_noise") { _other_noise_tag_count -= 1; } // Doesn't count itself
			_hazard_difficulty_score += _other_noise_tag_count * 2.25;
		}
		if (array_contains(_hazard_tags, "fires_at_player") || array_contains(_hazard_tags, "immune_with_staff")) {
			// Having a staff fully protects against this hazard
			_hazard_difficulty_score *= (1 - _staff_carry_chance);
		}
		if (array_contains(_hazard_tags, "killed_by_sword")) {
			// Having a special sword fully protects against this hazard
			_hazard_difficulty_score *= (1 - _special_sword_carry_chance);
		}
		if (array_contains(_hazard_tags, "dangerous_in_dark")) {
			// Having a special sword fully protects against this hazard
			// TODO: Don't increase score at all if current room is pre-lit
			// This attempts to increase the score based on the chance that a player will show up without a lit torch
			_hazard_difficulty_score *= 2 * (1 - (_lit_room_encountered_chance * _torch_carry_chance));
		}

		// Add score for hazard to running total
		_total_room_difficulty += _hazard_difficulty_score;
	}
	
	// Return the running total, minus the calculated effect of the sword, converted from danger to difficulty points
	return (_hazard_difficulty_score - (_max_difficulty_saved_by_sword * _sword_carry_chance)) * DANGER_POINT_SCALE;
}
 
/// @function hazard_counts_time(_counts)
/// @description The time score for a set of hazards in one room: each one's time score, added up.
/// @param {struct} _counts Hazard names and how many of each
/// @returns {real}
function get_time_score_for_hazard_counts(_counts) {
	var _names = variable_struct_get_names(_counts), _time = 0;
	for (var _i = 0; _i < array_length(_names); _i++) { _time += get_hazard_time_score(_names[_i], _counts[$ _names[_i]]); }
	return _time;
}