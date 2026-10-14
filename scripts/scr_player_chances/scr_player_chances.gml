/// @function PlayerChances([_chance_holding_staff], [_chance_holding_sword], [_chance_holding_special_sword], [_chance_of_light])
/// @description Descibes how likely a player is to have things that will mitigate a given layout's hazards.
/// @param {real} [_chance_holding_staff] The chance of holding a staff (0 by default)
/// @param {real} [_chance_holding_sword] The chance of holding a plain sword (0 by default)
/// @param {real} [_chance_holding_special_sword] The chance of holding a special sword (0 by default)
/// @param {real} [_chance_of_light] The chance of having light (0 by default)
function PlayerChances(_chance_holding_staff = 0, _chance_holding_sword = 0, _chance_holding_special_sword = 0, _chance_of_light = 0) constructor {	
	/// @function get_total_difficulty_score_for_hazard_counts(_hazard_counts)
	/// @description The difficulty points for a room's hazards. Each hazard's points grow for the hazards it shares the room
	///	with and shrink for the blocks that can stop it. Then each item the player might hold takes away the points it would save,
	/// weighted by the chance of holding it.
	/// @param {struct} _hazard_counts Hazard names and how many of each
	/// @returns {real}
	static get_total_difficulty_score_for_hazard_counts = function(_hazard_counts) {
		// Work out each hazard's points in this room, and how much one sword kill would save
		var _table = get_difficulty_score_table(), _hazard_names = variable_struct_get_names(_hazard_counts);
		
		// Loop through each hazard present in the room, to determine its total difficulty score and find the best sword use
		var _total_difficulty_score = 0, _staff_hazard_counts = duplicate_count_struct(_hazard_counts), _special_sword_hazard_counts = duplicate_count_struct(_hazard_counts), _max_sword_kill_difference = 0;
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip hazards that aren't in the room or the table
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
			
			// Calculate the hazard score for the room
			var _total_difficulty_score_for_hazard = calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _hazard_counts);
			_total_difficulty_score += _total_difficulty_score_for_hazard;
			
			if ((_hazard_table_entry.tags & hazard_tags.killed_by_sword) != 0) {
				// Calculate the hazard score for the sword case
				var _sword_difficulty_score_for_hazard = calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count - 1, _hazard_counts);
				var _sword_kill_difference = abs(_total_difficulty_score_for_hazard - _sword_difficulty_score_for_hazard);
				_max_sword_kill_difference = max(_max_sword_kill_difference, _sword_kill_difference);
				
				// Set the special sword hazard counts
				_special_sword_hazard_counts[$ _hazard_name] = 0;
			}
			
			if ((_hazard_table_entry.tags & STOPPED_BY_STAFF_TAGS) != 0) {
				// Set the special sword hazard counts
				_staff_hazard_counts[$ _hazard_name] = 0;
			}
		}
		var _total_sword_difficulty_score = _total_difficulty_score - _max_sword_kill_difference;
		
		// Loop through the special sword hazard counts to determine its total danger score
		var _total_special_sword_difficulty_score = 0;
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip hazards that aren't in the room or the table
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_special_sword_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
			
			// Calculate the hazard score for the room
			_total_special_sword_difficulty_score += calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _special_sword_hazard_counts);
		}
		
		// Loop through the staff hazard counts to determine its total danger score
		var _total_staff_difficulty_score = 0;
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip hazards that aren't in the room or the table
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_staff_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
			
			// Calculate the hazard score for the room
			_total_staff_difficulty_score += calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _staff_hazard_counts);
		}

		// Calulate total danger score based on player chances
		var _chance_holding_nothing = (1 - chance_holding_staff - chance_holding_sword - chance_holding_special_sword);
		return max(0, ((_chance_holding_nothing * _total_difficulty_score) + (chance_holding_staff * _total_staff_difficulty_score) + (chance_holding_sword * _total_sword_difficulty_score) + (chance_holding_special_sword * _total_special_sword_difficulty_score)));
	};
	
	/// @function calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _hazard_counts)
	/// @description The difficulty points for a given hazard type for a given room's hazard counts.
	/// The difficulty grows for other hazards it shares a room with, the lit chance, and shrinks for blocks that can stop it, and then
	///	gets averaged over which counters the player might hold: a staff stops anything that shoots and lava, a special sword kills
	///	anything a sword can, and a plain sword kills the deadliest of those, once.
	/// @param {string} _hazard_name		Name of the hazard to calculate the difficulty score for
	/// @param {real} _hazard_count			Count of the given hazard name
	/// @param {struct} _hazard_counts		Hazard names and how many of each
	/// @returns {real}
	static calculate_hazard_difficulty_score_for_room = function(_hazard_name, _hazard_count, _hazard_counts) {
		var _base_hazard_danger_score = get_hazard_danger_from_table(_hazard_name, _hazard_count);
		var _base_hazard_difficulty_points = get_difficulty_points_from_danger_score(_base_hazard_danger_score);
		var _difficulty_score_with_light_chance = apply_lit_chance_to_difficulty_points(_hazard_name, _base_hazard_difficulty_points);
		var _difficulty_score_with_block_chance = apply_block_chance_to_difficulty_points(_hazard_name, _difficulty_score_with_light_chance, _hazard_counts);
		var _hazard_score_multiplier = get_hazard_combination_multiplier(_hazard_counts, _hazard_name);
		return _difficulty_score_with_block_chance * _hazard_score_multiplier;
	};	
	
	/// @function apply_lit_chance_to_difficulty_points(_hazard_name, _hazard_danger_score)
	/// @description Applies the effect of lit chances to the current danger score and returns it
	/// @param {string} _hazard_name					The hazard's name in the table
	/// @param {real} _hazard_difficulty_score			The current hazard difficulty score
	/// @returns {real}
	static apply_lit_chance_to_difficulty_points = function(_hazard_name, _hazard_difficulty_score) {
		if (!hazard_has_tag(_hazard_name, hazard_tags.dangerous_in_dark)) { return _hazard_difficulty_score; }
		
		var _chance_of_dark = (1 - chance_of_light);
		return (_hazard_difficulty_score * chance_of_light) + (_hazard_difficulty_score * DARK_DANGER_MULTIPLIER * _chance_of_dark);
	};
	
	/// @function apply_block_chance_to_difficulty_points(_hazard_name, _hazard_difficulty_score, _hazard_counts)
	/// @description Applies the effect of blocks in the room to the current difficulty score and returns it
	/// @param {string} _hazard_name					The hazard's name in the table
	/// @param {real} _hazard_difficulty_score			The current hazard difficulty score
	/// @param {struct} _hazard_counts					The count struct of all hazards in the room
	/// @returns {real}
	static apply_block_chance_to_difficulty_points = function(_hazard_name, _hazard_difficulty_score, _hazard_counts) {
		// Skip applying if blocks aren't present or hazard can't be stopped by blocks
		var _table = get_difficulty_score_table(), _hazard_table_entry = _table[$ _hazard_name];
		var _block_count = get_count_from_struct(_hazard_counts, "obj_block_spot") + get_count_from_struct(_hazard_counts, "obj_living_block");
		if (_block_count <= 0 || is_undefined(_hazard_table_entry) || (_hazard_table_entry.tags & (hazard_tags.stopped_by_block | hazard_tags.uses_up_block)) == 0) { return _hazard_difficulty_score; }
		
		// A block that isn't used up can be pushed on from one copy to the next, so it counters them all. One that is used up only
		// counters one copy, so only the share of copies the room has blocks for is countered. One that counts once, like lava, is one copy
		var _countered_share = 1;
		if ((_hazard_table_entry.tags & hazard_tags.uses_up_block) != 0) {
			var _copies = (_hazard_table_entry.many == 0) ? 1 : get_count_from_struct(_hazard_counts, _hazard_name);
			_countered_share = min(1, _block_count / max(1, _copies));
		}
		return _hazard_difficulty_score * (1 - ((1 - BLOCK_COUNTER_MULTIPLIER) * _countered_share));
	};
	
	// ============================
	// Instance Variables
	// ============================
	
	chance_holding_staff = _chance_holding_staff;
	chance_holding_sword = _chance_holding_sword;
	chance_holding_special_sword = _chance_holding_special_sword;
	chance_of_light = _chance_of_light;
}
 