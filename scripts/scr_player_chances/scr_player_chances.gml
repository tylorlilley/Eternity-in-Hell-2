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
		var _staff_hazard_counts = duplicate_count_struct(_hazard_counts), _special_sword_hazard_counts = duplicate_count_struct(_hazard_counts), _block_hazard_counts = duplicate_count_struct(_hazard_counts);
		var _total_difficulty_score = 0, _max_sword_kill_difference = 0, _block_kill_differences = {}, _blocks_count = get_count_from_struct(_hazard_counts, "obj_block");
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip hazards that aren't in the room or the table
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
			
			// Calculate the hazard score for the room
			var _total_difficulty_score_for_hazard = calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _hazard_counts);
			_total_difficulty_score += _total_difficulty_score_for_hazard;
			
			// Calculate the hazard score when player has a sword
			if ((_hazard_table_entry.tags & hazard_tags.killed_by_sword) != 0) {
				// Calculate the hazard score for the sword case
				var _sword_difficulty_score_for_hazard = calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count - 1, _hazard_counts);
				var _sword_kill_difference = abs(_total_difficulty_score_for_hazard - _sword_difficulty_score_for_hazard);
				_max_sword_kill_difference = max(_max_sword_kill_difference, _sword_kill_difference);
				
				// Set the special sword hazard counts
				_special_sword_hazard_counts[$ _hazard_name] = 0;
			}
			
			// Calculate the hazard score when player has a staff
			if ((_hazard_table_entry.tags & STOPPED_BY_STAFF_TAGS) != 0) {
				// Set the special sword hazard counts
				_staff_hazard_counts[$ _hazard_name] = 0;
			}
			
			// Calculate the hazard score when room has blocks
			if (_blocks_count > 0) {
				if ((_hazard_table_entry.tags & hazard_tags.uses_up_block) != 0) {
					var _blocks_used = min(_block_count, _hazard_count);
					for (var _j = 0; _j < _blocks_used; _j++) {
						var _block_difficulty_score_for_hazard = calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count - _blocks_used, _hazard_counts);
						var _block_kill_difference = abs(_total_difficulty_score_for_hazard - _block_difficulty_score_for_hazard);
				
						_block_kill_differences[$ _hazard_name] = { blocks_used: _blocks_used, kill_difference: _block_kill_difference };
					}
				}
				else if ((_hazard_table_entry.tags & hazard_tags.destroyed_by_block) != 0) {
					// If you don't use up the block and can be destroyed by the block, assume the block can help mitigate that hazard
					_block_hazard_counts[$ _hazard_name] *= BLOCK_COUNTER_MULTIPLIER;
				}
			}
		}
		var _total_sword_difficulty_score = _total_difficulty_score - _max_sword_kill_difference;
		
		// Recursively oop through the block kill possibilities to find the optimal block usage combination
		get_best_of_subsequent_kill_differences = function(_start_pos, _block_kill_differences, _blocks_count, _max_block_kill_difference_value) {
			var _block_kill_differences_keys = variable_struct_get_names(_block_kill_differences), _current_kill_difference = _block_kill_differences[$ _block_kill_differences_keys[_start_pos]];
			var _current_kill_difference_value = _current_kill_difference.kill_difference, _blocks_used = _current_kill_difference.blocks_used, _max_block_kill_differences = [];

			for (var _i = _start_pos+1; _i < array_length(_block_kill_differences_keys); _i++) {
				var _best_subsequent_block_kill_differences = _get_best_of_subsequent_kill_differences(_i, _block_kill_differences, _blocks_count, _max_block_kill_difference_value);
				var _total_blocks_used = _blocks_used, _total_kill_difference = _current_kill_difference_value;
				// Tally up the block usage and kill difference for the returned best values
				var _best_subsequent_block_kill_differences_keys = variable_struct_get_names(_best_subsequent_block_kill_differences);
				for (var _j = 0; _j < _best_subsequent_block_kill_differences_keys; _j++) {
					var _best_block_kill_difference = _best_subsequent_block_kill_differences[$ _best_subsequent_block_kill_differences_keys[_j]];
					_total_blocks_used += _best_block_kill_difference.blocks_used;
					_total_kill_difference += _best_block_kill_difference.kill_difference;
				}
				
				// Skip solutions that use too many blocks
				if (_total_blocks_used > _blocks_count) { continue; }
				
				// Set the new maximum solution if applicable
				if (_total_kill_difference > _max_block_kill_difference_value) {
					_max_block_kill_differences = _best_subsequent_block_kill_differences;
					_max_block_kill_differences[$ _block_kill_differences_keys[_start_pos]] = _current_kill_difference;
					array_push (_max_block_kill_differences, _current_kill_difference);
					_max_block_kill_difference_value = _total_kill_difference;
				}
			}
			
			return _max_block_kill_differences;
		}
		var _best_block_kill_differences = get_best_of_subsequent_kill_differences(0, _block_kill_differences, _blocks_count, 0);
		
		// Apply the optimal block usage combination
		var _total_block_difficulty_score = 0;
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip hazards that aren't in the room or the table
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_block_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
			
			// Calculate the hazard score for the room
			var _best_block_kill_differences_for_hazard = _best_block_kill_differences[$ _hazard_name] ?? { blocks_used: 0, kill_difference: 0 };
			var _blocks_used = _best_block_kill_differences_for_hazard.blocks_used;
			_total_block_difficulty_score += calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count - _blocks_used, _block_hazard_counts);
			_total_block_difficulty_score += calculate_hazard_difficulty_score_for_room(_hazard_name, _blocks_used, _block_hazard_counts) * BLOCK_COUNTER_MULTIPLIER;
		}
		
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
		
		// The block difficulty score is the same as the total difficulty score in rooms without blocks
		return max(0, ((_chance_holding_nothing * _total_block_difficulty_score) + (chance_holding_staff * _total_staff_difficulty_score) + (chance_holding_sword * _total_sword_difficulty_score) + (chance_holding_special_sword * _total_special_sword_difficulty_score)));
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
		//var _difficulty_score_with_block_chance = apply_block_chance_to_difficulty_points(_hazard_name, _difficulty_score_with_light_chance, _hazard_counts);
		var _hazard_score_multiplier = get_hazard_combination_multiplier(_hazard_counts, _hazard_name);
		return _difficulty_score_with_light_chance * _hazard_score_multiplier;
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
		if (_block_count <= 0 || is_undefined(_hazard_table_entry) || (_hazard_table_entry.tags & (hazard_tags.destroyed_by_block | hazard_tags.uses_up_block)) == 0) { return _hazard_difficulty_score; }
		
		// A block that isn't used up can be pushed on from one copy to the next, so it counters them all. One that is used up only
		// counters one copy, so only the share of copies the room has blocks for is countered. One that counts once, like lava, is one copy
		var _percentage_of_coppies_countered = 1;
		if ((_hazard_table_entry.tags & hazard_tags.uses_up_block) != 0) {
			var _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name);
			_percentage_of_coppies_countered = _block_count / max(1, _hazard_count);
			_percentage_of_coppies_countered = min(1, _percentage_of_coppies_countered);
		}
		return _hazard_difficulty_score * (1 - ((1 - BLOCK_COUNTER_MULTIPLIER) * _percentage_of_coppies_countered));
	};
	
	// ============================
	// Instance Variables
	// ============================
	
	chance_holding_staff = _chance_holding_staff;
	chance_holding_sword = _chance_holding_sword;
	chance_holding_special_sword = _chance_holding_special_sword;
	chance_of_light = _chance_of_light;
}
 