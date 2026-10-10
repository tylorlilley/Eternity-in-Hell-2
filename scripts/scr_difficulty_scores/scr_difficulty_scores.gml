// Turning scores into game values
#macro DANGER_POINT_SCALE 8					// Score points per unit of danger
#macro HAZARD_FULL_TIME 30					// Extra Seconds a time score of 1 is worth: hold-ups on top of walking,
 
// Hazards that make each other worse. Each hazard's danger assumes the player can deal with it on their own terms, and the
// more likely the room is to take that away, the closer it gets to its worst case (see get_hazard_combination_multiplier)
#macro WORST_CASE_MULTIPLIER 3				// A hazard the player slows down for, rushed past instead, or ears drawn to the player by noise: like facing it three times, so a spider goes from 0.15 to about 0.39 danger
#macro STOPPED_WORST_CASE_MULTIPLIER 9		// A hazard that stops the player, while they're made to keep moving: eyes go from 0.12 to about 0.68 danger
#macro KEEPS_PLAYER_MOVING_DANGER 0.20		// A chaser or shooter this deadly, like a phantom, keeps the player moving all the time, and a less deadly one that share of the time
#macro WANDERER_KEEPS_PLAYER_MOVING_SHARE 0.5	// A wanderer only gets in the way by chance, so it keeps the player moving half as much for its danger
#macro LURE_CHANCE_PER_LOUD_KIND 0.33		// How often each kind of hazard that makes loud noises on its own draws ears to the player
#macro DARK_DANGER_MULTIPLIER 5				// A hazard that's worse in the dark, when the player has no light: a cockroach goes from 0.02 to about 0.10 danger
#macro PHANTOM_TIME_PER_LANTERN 0.03		// Banishing a phantom means lighting every lantern, which takes longer the more there are
#macro TARGETS_PLAYER_TAGS (hazard_tags.moves_towards_player | hazard_tags.fires_at_player)						// What keeps the player on the move by coming for them
#macro STOPPED_BY_STAFF_TAGS (hazard_tags.fires_at_player | hazard_tags.fires_in_place | hazard_tags.immune_with_staff)	// What can't hurt a player holding a staff
#macro MAP_ENCOUNTER_CHANCE_MULTIPLIER 3		// How likely the player is to have something, per share of the map's rooms holding it: one sword chest in fifteen rooms gives a 0.2 chance of holding a sword
#macro BLOCK_COUNTER_MULTIPLIER 0.6			// A hazard a block can stop keeps this share of its danger: the layout lets a block be lined up with it about half the time, and setting the block up carries about a fifth of the hazard's own risk
 
// The room's other content Multipliers
#macro COLLECTABLES_EXPOSURE 1.4			// Collecting everything crosses the whole room, so its hazard danger counts 1.4 times
#macro PORTCULLIS_TRAP_DANGER 0.03			// Shut in until the button is pressed, once per trap room
#macro SPECIAL_ITEM_REWARD_POINTS -2		// A cursed item makes the rest of the run easier, so the map can take more
 
// Time variables hat a careful novice needs, then how many times that the run gives
#macro PLAYER_STEPS_PER_SECOND 10			// One 8-pixel step a tick, 10 ticks a second
#macro ROOM_ENTRY_TIME 2					// Seconds each visit costs before any walking: the transition and a look around
#macro CAUTION_PER_DANGER_POINT 0.2			// Walking slows by this share for each point of the room's hazard danger
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
///	time: the hold-ups it causes on top of walking, from 0 (none) to 1 (HAZARD_FULL_TIME seconds, like a sin's
///		quest). The walking itself is measured on the layout and slowed by danger (get_time_needed).
///
///	many, time_many: how more copies in one room add up, as a power of the count: 1 additive, under 1
///		diminishing, over 1 compounding, and 0 flat (only the first one counts).
///
///	min_difficulty: the lowest difficulty a layout that places it appears on, however low its scores (see
///		RoomLayout.determine_minimum_difficulty).
///
///	tags: what the combination rules and counters need to know about it (see hazard_tags).
///
///	Bones, bushes and corpses aren't in the table: they aren't dangerous themselves, only what spawns from them during
///	play (see get_mid_game_spawns).
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
 
		// Sin objects. The sin limit already keeps their rooms off Easy and Medium; time covers each sin's quest
		obj_giant_eye:			{ danger: 0.17,		many: 1,	time: 0.50,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary | hazard_tags.fires_at_player },
		// The trip to the start cross and back is map travel (GameMap.get_backtracking_time)
		obj_inverted_cross:		{ danger: 0.25,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.moves_towards_player },
		obj_hall_of_mirrors:	{ danger: 0,		many: 0,	time: 1.00,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary },
		obj_red_chest:			{ danger: 0.01,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary },
		obj_gudetama:			{ danger: 0.01,		many: 1,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.hard,		tags: hazard_tags.stationary | hazard_tags.killed_by_sword | hazard_tags.stopped_by_block },
 
		// Spawns on skeleton spots, named for their objects too (snakes and eyes use the entries above)
		obj_skeleton:			{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.stopped_by_block },
		obj_cockroach:			{ danger: 0.02,		many: 1,	time: 0.01,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.dangerous_in_dark | hazard_tags.stopped_by_block },				// In light; hunting in the dark it's 0.10
		obj_fast_skeleton:		{ danger: 0.13,		many: 1,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.slows_player_movement | hazard_tags.stopped_by_block },
		obj_fat_skeleton:		{ danger: 0.04,		many: 1,	time: 0.02,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block },
		obj_cultist:			{ danger: 0.16,		many: 1.2,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.fires_at_player | hazard_tags.stopped_by_block },
		obj_fire_skeleton:		{ danger: 0.18,		many: 1.15,	time: 0.06,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.killed_by_sword | hazard_tags.fires_at_player | hazard_tags.immune_with_staff | hazard_tags.lights_torches | hazard_tags.uses_up_block },
 
		// Spawns during map creation
		obj_phantom:				{ danger: 0.20,		many: 0,	time: 0.20,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.moves_towards_player },
		obj_floater:				{ danger: 0.08,		many: 0,	time: 0.15,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.moves_towards_player },
		obj_nose:					{ danger: 0.10,		many: 1,	time: 0.08,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.fires_at_player | hazard_tags.lights_torches },	// Aimed where the player is, so walking along a bridge dodges it too
		// Its spot still counts its block, for the push time and what it can stop
		obj_living_block:			{ danger: 0.10,		many: 1,	time: 0,		time_many: 1,		min_difficulty: difficulties.easy,		tags: hazard_tags.slows_player_movement },
		// For trapped chests only:
		obj_chest:					{ danger: 0.12,		many: 0,	time: 0.05,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.stationary },
		// For moving collectables only:
		obj_collectable:			{ danger: 0,		many: 0,	time: 0.30,		time_many: 0,		min_difficulty: difficulties.easy,		tags: hazard_tags.none },
 
		// Spawns during play (see get_mid_game_spawns)
		// A red bug: once it reaches the player, their moves are left to chance for a while. Bugs of other colors run away and can't harm them
		obj_bug:					{ danger: 0.05,		many: 1,	time: 0.20,		time_many: 1,		min_difficulty: difficulties.hard,		tags: hazard_tags.moves_towards_player | hazard_tags.stopped_by_block },
		// Comes for an item lying on the floor and runs off with it, laughing. It's deadly to touch, and the item has to be won back
		obj_hands:					{ danger: 0.06,		many: 1,	time: 0.30,		time_many: 1,		min_difficulty: difficulties.medium,	tags: hazard_tags.killed_by_sword | hazard_tags.makes_loud_noise | hazard_tags.stopped_by_block }
	};
	return _table;
}
 
/// @function get_difficulty_score_for_danger_level(_danger)
/// @description Turns a danger, the chance of dying, into difficulty points. Chances of dying don't add up: two hazards that
///	each kill half the time kill three times out of four together, not always. -ln(1 - danger) does add up, the way the
///	chances of surviving each hazard multiply, so points can be summed across hazards and rooms. Anything that mixes chances,
///	like whether the player holds a counter, has to mix the chances of surviving instead of the points. DANGER_POINT_SCALE only sets the size of a point.
/// @param {real} _danger From 0 to 1
/// @returns {real}
function get_difficulty_score_for_danger_level(_danger) {
	return (_danger <= 0) ? 0 : -ln(1 - min(_danger, 0.99)) * DANGER_POINT_SCALE;
}
 
/// @function get_survival_chance_for_difficulty_score(_difficulty_score)
/// @description The chance of surviving hazards worth some difficulty points, the other way around from get_difficulty_score_for_danger_level
/// @param {real} _difficulty_score The points
/// @returns {real} From 0 to 1
function get_survival_chance_for_difficulty_score(_difficulty_score) {
	return exp(-_difficulty_score / DANGER_POINT_SCALE);
}
 
/// @function get_difficulty_score_for_survival_chance(_survival_chance)
/// @description The difficulty points for a chance of surviving, so a mix of chances can be turned back into points
/// @param {real} _survival_chance From 0 to 1
/// @returns {real}
function get_difficulty_score_for_survival_chance(_survival_chance) {
	return -ln(max(_survival_chance, 0.000001)) * DANGER_POINT_SCALE;
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
 
/// @function hazard_has_tag(_hazard_name, _tags)
/// @description Whether a hazard has any of some tags
/// @param {string} _hazard_name The hazard's name in the table
/// @param {real} _tags One hazard_tags flag, or several combined with |
/// @returns {bool}
function hazard_has_tag(_hazard_name, _tags) {
	var _table = get_difficulty_score_table(), _entry = _table[$ _hazard_name];
	return !is_undefined(_entry) && ((_entry.tags & _tags) != 0);
}
 
/// @function count_hazards_with_tags(_counts, _tags, [_ignored_hazard_name])
/// @description How many kinds of hazard in a room have any of some tags, leaving out one of them if given
/// @param {struct} _counts Hazard names and how many of each, for the room
/// @param {real} _tags hazard_tags flags a hazard needs any of to count, or hazard_tags.none to count it whatever its tags
/// @param {string|undefined} _ignored_hazard_name The hazard to leave out, or undefined to count every hazard in the room
/// @returns {real}
function count_hazards_with_tags(_counts, _tags, _ignored_hazard_name = undefined) {
	var _table = get_difficulty_score_table(), _names = variable_struct_get_names(_counts), _count = 0;
	for (var _i = 0; _i < array_length(_names); _i++) {
		// Skip the hazard itself, and any that isn't in the room or the table
		var _name = _names[_i], _entry = _table[$ _name];
		if ((!is_undefined(_ignored_hazard_name) && _name == _ignored_hazard_name) || is_undefined(_entry) || _counts[$ _name] <= 0) { continue; }
		
		// Count it if it has one of the tags
		if ((_tags == hazard_tags.none) || ((_entry.tags & _tags) != 0)) { _count += 1; }
	}
	
	return _count;
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
 
/// @function get_chance_kept_moving(_counts, _hazard_name)
/// @description How likely the other hazards in a room are to keep the player moving while they deal with one hazard. One
///	that chases or shoots at them does it in proportion to its danger, all the time once it's as deadly as
///	KEEPS_PLAYER_MOVING_DANGER, and one that wanders about does it less (WANDERER_KEEPS_PLAYER_MOVING_SHARE). Hazards that
///	stay put or slow the player down don't. They all push at once, so their chances overlap rather than add up.
/// @param {struct} _counts Hazard names and how many of each, for the room
/// @param {string} _hazard_name The hazard being dealt with
/// @returns {real} From 0 to 1
function get_chance_kept_moving(_counts, _hazard_name) {
	var _table = get_difficulty_score_table(), _names = variable_struct_get_names(_counts), _chance_never_kept_moving = 1;
	var _always_keeps_moving_points = get_difficulty_score_for_danger_level(KEEPS_PLAYER_MOVING_DANGER);
	for (var _i = 0; _i < array_length(_names); _i++) {
		// Skip the hazard itself, and any that isn't in the room or the table
		var _name = _names[_i], _entry = _table[$ _name];
		if (_name == _hazard_name || is_undefined(_entry) || _counts[$ _name] <= 0) { continue; }
		
		// Chasers and shooters keep the player moving in full for their danger, and wanderers in part
		var _share = 0;
		if ((_entry.tags & TARGETS_PLAYER_TAGS) != 0) { _share = 1; }
		else if ((_entry.tags & (hazard_tags.stationary | hazard_tags.slows_player_movement)) == 0) { _share = WANDERER_KEEPS_PLAYER_MOVING_SHARE; }
		var _chance_this_keeps_moving = min(1, _share * get_hazard_difficulty_score(_name, _counts[$ _name]) / _always_keeps_moving_points);
		_chance_never_kept_moving *= 1 - _chance_this_keeps_moving;
	}
	
	return 1 - _chance_never_kept_moving;
}
 
/// @function get_hazard_combination_multiplier(_counts, _hazard_name)
/// @description How many times its own danger points a hazard is worth, for the hazards it shares a room with. Its danger
///	assumes the player can deal with it on their own terms: slowing down for it, stopping when it says to, or keeping it
///	from hearing them. The more likely the others are to take that away, by keeping the player moving or by drawing the
///	ears to them with their noise, the closer it gets to its worst case: WORST_CASE_MULTIPLIER, or
///	STOPPED_WORST_CASE_MULTIPLIER for one that stops the player.
/// @param {struct} _counts Hazard names and how many of each, for the room
/// @param {string} _hazard_name The hazard's name in the table
/// @returns {real} At least 1
function get_hazard_combination_multiplier(_counts, _hazard_name) {
	// Work out how likely the player is to deal with it on their own terms
	var _chance_on_own_terms = 1;
	if (hazard_has_tag(_hazard_name, hazard_tags.slows_player_movement | hazard_tags.stops_player_movement)) {
		_chance_on_own_terms *= 1 - get_chance_kept_moving(_counts, _hazard_name);
	}
	if (hazard_has_tag(_hazard_name, hazard_tags.listens_to_loud_noise)) {
		_chance_on_own_terms *= power(1 - LURE_CHANCE_PER_LOUD_KIND, count_hazards_with_tags(_counts, hazard_tags.makes_loud_noise, _hazard_name));
	}
	
	// Then move it that much of the way to its worst case
	var _worst_case_multiplier = hazard_has_tag(_hazard_name, hazard_tags.stops_player_movement) ? STOPPED_WORST_CASE_MULTIPLIER : WORST_CASE_MULTIPLIER;
	return 1 + ((_worst_case_multiplier - 1) * (1 - _chance_on_own_terms));
}
 
/// @function get_hazard_points_in_room(_hazard_name, _count, _multiplier, _room)
/// @description A hazard's danger points in a room: its count's points times its combination multiplier. For one that's
///	worse in the dark, the chance of surviving it is mixed over whether the player has light there.
/// @param {string} _hazard_name The hazard's name in the table
/// @param {real} _count How many of it
/// @param {real} _multiplier Its combination multiplier (see get_hazard_combination_multiplier)
/// @param {struct} _room The room, or a struct with the same chances, for its chance_of_light
/// @returns {real}
function get_hazard_points_in_room(_hazard_name, _count, _multiplier, _room) {
	var _points = get_hazard_difficulty_score(_hazard_name, _count) * _multiplier;
	if (!hazard_has_tag(_hazard_name, hazard_tags.dangerous_in_dark)) { return _points; }
	
	var _survival_chance_with_light = get_survival_chance_for_difficulty_score(_points);
	var _survival_chance_in_dark = get_survival_chance_for_difficulty_score(_points * DARK_DANGER_MULTIPLIER);
	return get_difficulty_score_for_survival_chance((_room.chance_of_light * _survival_chance_with_light) + ((1 - _room.chance_of_light) * _survival_chance_in_dark));
}
 
/// @function apply_block_counters(_hazards, _block_count)
/// @description Lowers the points of the hazards a room's blocks can stop, to BLOCK_COUNTER_MULTIPLIER of them. A block
///	that isn't used up can be pushed on from one hazard to the next, so a single block lowers all of those, the way a special
///	sword kills them all. One that's used up only stops one copy of a hazard, the way a plain sword kills once, so the blocks
///	go to the deadliest copies first. A copy is an even share of its hazard's points, and a hazard that counts once whatever
///	its count, like lava, is one copy.
/// @param {array} _hazards Each hazard's points, sword kill points, tags and copies (see get_difficulty_score_for_hazard_counts)
/// @param {real} _block_count How many blocks the room has, living ones included
function apply_block_counters(_hazards, _block_count) {
	if (_block_count <= 0) { return; }
	
	// Any block lowers every hazard it isn't used up on, and the hazards it is used up on wait for theirs
	var _used_up_on = [];
	for (var _i = 0; _i < array_length(_hazards); _i++) {
		var _hazard = _hazards[_i];
		if ((_hazard.tags & hazard_tags.stopped_by_block) != 0) {
			_hazard.points *= BLOCK_COUNTER_MULTIPLIER;
			_hazard.sword_kill_points *= BLOCK_COUNTER_MULTIPLIER;
		}
		else if ((_hazard.tags & hazard_tags.uses_up_block) != 0) { array_push(_used_up_on, _hazard); }
	}
	
	// Spend the blocks on the deadliest copies first
	array_sort(_used_up_on, function(_a, _b) { return sign((_b.points / _b.copies) - (_a.points / _a.copies)); });
	var _blocks_left = _block_count;
	for (var _j = 0; _j < array_length(_used_up_on) && _blocks_left > 0; _j++) {
		var _stopped_hazard = _used_up_on[_j], _copies_stopped = min(_stopped_hazard.copies, _blocks_left);
		var _multiplier = 1 - ((1 - BLOCK_COUNTER_MULTIPLIER) * (_copies_stopped / _stopped_hazard.copies));
		_stopped_hazard.points *= _multiplier;
		_stopped_hazard.sword_kill_points *= _multiplier;
		_blocks_left -= _copies_stopped;
	}
}
 
/// @function get_difficulty_score_for_hazard_counts(_counts, [_room], [_has_light])
/// @description The difficulty points for a room's hazards. Each hazard's points grow for the hazards it shares the room
///	with and shrink for the blocks that can stop it (see apply_block_counters). Then the chance of surviving them all is
///	averaged over which counters the player might hold: a staff stops anything that shoots and lava, a special sword kills
///	anything a sword can, and a plain sword kills the deadliest of those, once. The average has to be taken over the chances
///	of surviving, so it's turned back into points at the end.
/// @param {struct} _counts Hazard names and how many of each
/// @param {struct} [_room] The room, or a struct with the same chances, for how likely the player is to hold each counter and to have light there. Without one, the player holds no counters
/// @param {bool} [_has_light] Without a room, whether the player has light
/// @returns {real}
function get_difficulty_score_for_hazard_counts(_counts, _room = undefined, _has_light = false) {
	// Without a room, score it for a player holding no counters, with light only if _has_light says so
	_room ??= { chance_holding_staff: 0, chance_holding_sword: 0, chance_holding_special_sword: 0, chance_of_light: _has_light ? 1 : 0 };

	// Work out each hazard's points in this room, and how much one sword kill would save
	var _table = get_difficulty_score_table(), _hazard_names = variable_struct_get_names(_counts), _hazards = [];
	for (var _i = 0; _i < array_length(_hazard_names); _i++) {
		// Skip hazards that aren't in the room or the table
		var _hazard_name = _hazard_names[_i], _hazard_count = _counts[$ _hazard_name], _entry = _table[$ _hazard_name];
		if (is_undefined(_entry) || _hazard_count <= 0) { continue; }
		
		// Grow its points for the hazards around it. Generation never puts something that stops the player in a room with
		// something that chases or shoots at them, but what spawns during play can, and the multiplier scores that too
		var _multiplier = get_hazard_combination_multiplier(_counts, _hazard_name);
		var _points = get_hazard_points_in_room(_hazard_name, _hazard_count, _multiplier, _room);
		
		// How much a plain sword saves by killing one of them
		var _sword_kill_points = 0;
		if ((_entry.tags & hazard_tags.killed_by_sword) != 0) { _sword_kill_points = _points - get_hazard_points_in_room(_hazard_name, _hazard_count - 1, _multiplier, _room); }
		array_push(_hazards, { points: _points, sword_kill_points: _sword_kill_points, tags: _entry.tags, copies: (_entry.many == 0) ? 1 : _hazard_count });
	}
	
	// The room's blocks, living ones included, lower the danger of the hazards they can stop
	apply_block_counters(_hazards, _counts[$ "obj_block_spot"] ?? 0);
	
	// Average the chance of surviving over every mix of counters the player might hold: a staff, a special sword and a plain sword
	var _survival_chance = 0;
	for (var _held_counters = 0; _held_counters < 8; _held_counters++) {
		// Skip mixes that can't happen on this map
		var _holds_staff = (_held_counters & 1) != 0, _holds_special_sword = (_held_counters & 2) != 0, _holds_sword = (_held_counters & 4) != 0;
		var _mix_chance = (_holds_staff ? _room.chance_holding_staff : 1 - _room.chance_holding_staff) *
			(_holds_special_sword ? _room.chance_holding_special_sword : 1 - _room.chance_holding_special_sword) *
			(_holds_sword ? _room.chance_holding_sword : 1 - _room.chance_holding_sword);
		if (_mix_chance <= 0) { continue; }
		
		// Total the points of every hazard these counters don't stop, less what a plain sword's one kill saves
		var _mix_points = 0, _best_sword_kill_points = 0;
		for (var _j = 0; _j < array_length(_hazards); _j++) {
			var _hazard = _hazards[_j];
			if (_holds_staff && ((_hazard.tags & STOPPED_BY_STAFF_TAGS) != 0)) { continue; }
			
			if (_holds_special_sword && ((_hazard.tags & hazard_tags.killed_by_sword) != 0)) { continue; }
			
			_mix_points += _hazard.points;
			if (_holds_sword) { _best_sword_kill_points = max(_best_sword_kill_points, _hazard.sword_kill_points); }
		}
		_survival_chance += _mix_chance * get_survival_chance_for_difficulty_score(_mix_points - _best_sword_kill_points);
	}
	
	return get_difficulty_score_for_survival_chance(_survival_chance);
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
 
/// @function ExpectedSpawn(_hazard_name, _expected_count, [_replaced_hazard_name])
/// @description Something that might spawn into a room, with how many of it spawn there on average
/// @param {string} _hazard_name The hazard's name in the table
/// @param {real} _expected_count How many spawn on average, which for one roll is its chance
/// @param {string} [_replaced_hazard_name] A hazard it takes the place of, like a skeleton spot's basic skeleton
function ExpectedSpawn(_hazard_name, _expected_count, _replaced_hazard_name = undefined) constructor {
	hazard_name = _hazard_name;
	expected_count = _expected_count;
	replaced_hazard_name = _replaced_hazard_name;
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
 
/// @function get_difficulty_score_with_spawns(_counts, _spawns, [_room], [_has_light])
/// @description The difficulty points for a room's hazards (see get_difficulty_score_for_hazard_counts), with what might
///	spawn into it added on average: for each, how many spawn on average times the points one more of it adds to the room.
///	Each is scored against the room as it is, not alongside the others.
/// @param {struct} _counts Hazard names and how many of each, for the room
/// @param {array} _spawns What might spawn (see ExpectedSpawn)
/// @param {struct} [_room] The room, or a struct with the same chances, as for get_difficulty_score_for_hazard_counts
/// @param {bool} [_has_light] Without a room, whether the player has light
/// @returns {real}
function get_difficulty_score_with_spawns(_counts, _spawns, _room = undefined, _has_light = false) {
	var _difficulty_score = get_difficulty_score_for_hazard_counts(_counts, _room, _has_light), _expected_difficulty_score = 0;
	for (var _i = 0; _i < array_length(_spawns); _i++) {
		var _spawn = _spawns[_i];
		if (_spawn.expected_count <= 0) { continue; }
		
		var _spawned_difficulty_score = get_difficulty_score_for_hazard_counts(get_hazard_counts_with_spawn(_counts, _spawn), _room, _has_light);
		_expected_difficulty_score += _spawn.expected_count * (_spawned_difficulty_score - _difficulty_score);
	}
	
	return _difficulty_score + _expected_difficulty_score;
}
 
/// @function get_time_score_with_spawns(_counts, _spawns)
/// @description The time score for a room's hazards (see get_time_score_for_hazard_counts), with what might spawn into it
///	added on average, the same way get_difficulty_score_with_spawns adds their difficulty points
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
 
/// @function get_mid_game_spawns(_counts, _layout, _floor_item_count)
/// @description What can spawn into a room each time the player enters it, and how many of each on average, from what the
///	room holds (see game_room_start and game_room_start_spawn_instances, which roll these again on every visit):
///	- each bone can be a trap that rises as a skeleton when the player comes near
///	- each bone and bush can hide a bug, and a corpse always hides two unless it crumbles first. Only red bugs can harm the
///		player, so only they count
///	- lava brings up a nose, or failing that a fire skeleton if the room has none. One roll for the room, however much
///		lava it has
///	- hands come for each item lying on the floor, as long as the player holds something to trade, which they nearly
///		always do
/// @param {struct} _counts Hazard names and how many of each, for the room
/// @param {struct} _layout The room's layout (see RoomLayout), for its bones, bushes and corpses
/// @param {real} _floor_item_count How many items lie on the room's floor, like a key
/// @returns {array} Each spawn (see ExpectedSpawn)
function get_mid_game_spawns(_counts, _layout, _floor_item_count) {
	// Skeletons rising from trapped bones
	var _bone_count = _layout.get_object_count("obj_bones"), _bush_count = _layout.get_object_count("obj_bush"), _corpse_count = _layout.get_object_count("obj_player_corpse");
	var _spawns = [new ExpectedSpawn("obj_skeleton", _bone_count * get_chance_out_of(TRAP_BONES_PROBABILITY))];
	
	// Red bugs from bones, bushes and corpses
	var _bug_count = ((_bone_count + _bush_count) * get_chance_out_of(BUG_PROBABILITY)) + (_corpse_count * (1 - get_chance_out_of(CORPSE_DISINTEGRATE_PROBABILITY)) * 2);
	array_push(_spawns, new ExpectedSpawn("obj_bug", _bug_count * get_chance_out_of(RED_BUG_PROBABILITY)));
	
	// A nose or a fire skeleton from the lava
	if ((_counts[$ "obj_lava"] ?? 0) > 0) {
		var _nose_chance = get_chance_out_of(NOSE_PROBABILITY * 4);
		array_push(_spawns, new ExpectedSpawn("obj_nose", _nose_chance));
		if ((_counts[$ "obj_fire_skeleton"] ?? 0) <= 0) { array_push(_spawns, new ExpectedSpawn("obj_fire_skeleton", (1 - _nose_chance) * get_chance_out_of(FIRE_SKELETON_IN_LAVA_PROBABILITY))); }
	}
	
	// Hands for the items on the floor
	array_push(_spawns, new ExpectedSpawn("obj_hands", _floor_item_count * get_chance_out_of(HANDS_PROBABILITY)));
	return _spawns;
}