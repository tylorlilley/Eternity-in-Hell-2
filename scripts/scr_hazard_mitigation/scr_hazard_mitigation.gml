#macro BLOCK_MITIGATION_MULTIPLIER 0.6					// The share of its difficulty score a hazard keeps when a block mitigates its danger
#macro STAFF_PROJECTILE_MITIGATION_MULTIPLIER 0.3		// The share of a hazard that still counts with a staff, when the staff only mitigates the danger of its projectiles
#macro PROJECTILE_STOPPED_BY_STAFF_TAGS (hazard_tags.fires_at_player | hazard_tags.fires_in_place)	// What shoots projectiles the staff can block
#macro DARK_DIFFICULTY_SCORE_MULTIPLIER 5				// The amount worse a hazard that is dangerous in the dark gets, when the player has no light

/// @function HazardMitigation([_chance_holding_staff], [_chance_holding_sword], [_chance_holding_special_sword], [_chance_of_light])
/// @description Mitigates the danger of a room's hazards for what's outside them: how likely the room is to be lit, the
///	blocks in it, and how likely the player is to hold each item that mitigates them.
/// @param {real} [_chance_holding_staff] The chance of holding a staff (0 by default)
/// @param {real} [_chance_holding_sword] The chance of holding a plain sword (0 by default)
/// @param {real} [_chance_holding_special_sword] The chance of holding a special sword (0 by default)
/// @param {real} [_chance_of_light] The chance of having light (0 by default)
function HazardMitigation(_chance_holding_staff = 0, _chance_holding_sword = 0, _chance_holding_special_sword = 0, _chance_of_light = 0) constructor {
	// ============================
	// Public Functions
	// ============================

	/// @function get_total_difficulty_score_for_spawn_counts(_spawn_counts)
	/// @description The difficulty score for what spawns in a room. Each hazard's difficulty score grows for the hazards it
	///	shares the room with and shrinks for the blocks that mitigate its danger. Then each item the player might hold takes
	///	away the difficulty score its mitigation saves, weighted by the chance of holding it.
	/// @param {struct} _spawn_counts Object names and how many of each spawn in the room
	/// @returns {real}
	static get_total_difficulty_score_for_spawn_counts = function(_spawn_counts) {
		return apply_item_chances_to_difficulty_score(_spawn_counts);
	};

	// ============================
	// Private Functions
	// ============================

	/// @function apply_item_chances_to_difficulty_score(_spawn_counts)
	/// @description The difficulty score for the given spawn counts, averaged over the chance of holding each item that
	///	mitigates the danger of their hazards
	/// @param {struct} _spawn_counts Object names and how many of each spawn in the room
	/// @returns {real}
	static apply_item_chances_to_difficulty_score = function(_spawn_counts) {
		var _total_difficulty_score = get_difficulty_score_with_blocks(_spawn_counts);
		var _table = get_hazards_table(), _object_names = variable_struct_get_names(_spawn_counts);
		var _staff_spawn_counts = duplicate_count_struct(_spawn_counts), _special_sword_spawn_counts = duplicate_count_struct(_spawn_counts), _total_sword_difficulty_score = _total_difficulty_score;
		
		// Loop through each object type that spawns
		for (var _i = 0; _i < array_length(_object_names); _i++) {
			// Skip object types that aren't hazards, or don't spawn
			var _object_name = _object_names[_i], _object_count = get_count_from_struct(_spawn_counts, _object_name), _hazard_table_entry = _table[$ _object_name];
			if (is_undefined(_hazard_table_entry) || _object_count <= 0) { continue; }
		
			// Deal with hazards that can be killed by the sword
			if ((_hazard_table_entry.tags & hazard_tags.killed_by_sword) != 0) {
				// Try using the sword on this hazard, and remember the score if it is the smallest yet for the sword usage
				var _sword_spawn_counts = duplicate_count_struct(_spawn_counts);
				_sword_spawn_counts[$ _object_name] = max(0, _object_count - 1);
				_total_sword_difficulty_score = min(_total_sword_difficulty_score, get_difficulty_score_with_blocks(_sword_spawn_counts));
				
				// The special sword can be used on all hazards weak to the sword
				_special_sword_spawn_counts[$ _object_name] = 0;
			}
		
			// A staff partly mitigates the danger of anything that moves and shoots, and fully mitigates lava and anything only dangerous by shooting
			var _tags = _hazard_table_entry.tags;
			if ((_tags & hazard_tags.immune_with_staff) != 0 || ((_tags & PROJECTILE_STOPPED_BY_STAFF_TAGS) != 0 && (_tags & hazard_tags.stationary) != 0)) { _staff_spawn_counts[$ _object_name] = 0; }
			else if ((_tags & PROJECTILE_STOPPED_BY_STAFF_TAGS) != 0) { _staff_spawn_counts[$ _object_name] *= STAFF_PROJECTILE_MITIGATION_MULTIPLIER; }
		}
	
		var _chance_holding_nothing = (1 - chance_holding_staff - chance_holding_sword - chance_holding_special_sword);
		var _total_staff_difficulty_score = get_difficulty_score_with_blocks(_staff_spawn_counts), _total_special_sword_difficulty_score = get_difficulty_score_with_blocks(_special_sword_spawn_counts);
		return max(0, (_chance_holding_nothing * _total_difficulty_score) + (chance_holding_staff * _total_staff_difficulty_score) + (chance_holding_sword * _total_sword_difficulty_score) + (chance_holding_special_sword * _total_special_sword_difficulty_score));
	}

	/// @function get_difficulty_score_with_blocks(_spawn_counts)
	/// @description The sum of each hazard's difficulty score in a room, minus what its blocks mitigate. A block that isn't used
	///	up is pushed on from one copy to the next, so it mitigates them all. One that's used up only mitigates a single copy
	///	(lava counts as one), so the blocks go to the copies they save the most difficulty score on
	/// @param {struct} _spawn_counts Object names and how many of each spawn in the room
	/// @returns {real}
	static get_difficulty_score_with_blocks = function(_spawn_counts) {
		var _table = get_hazards_table(), _object_names = variable_struct_get_names(_spawn_counts);
		var _blocks_left = get_count_from_struct(_spawn_counts, "obj_block_spot"), _total_difficulty_score = 0, _block_uses = [];
		
		// Loop through each object type that spawns
		var _difficulty_score_saved_per_block_spent_arrays = [];
		for (var _i = 0; _i < array_length(_object_names); _i++) {
			// Skip object types that aren't hazards, or don't spawn
			var _object_name = _object_names[_i], _object_count = get_count_from_struct(_spawn_counts, _object_name), _hazard_table_entry = _table[$ _object_name];
			if (is_undefined(_hazard_table_entry) || _object_count <= 0) { continue; }
		
			// Get the difficulty score, and modify it based on the blocks present in the room
			var _hazard_difficulty_score = calculate_hazard_difficulty_score_for_room(_object_name, _object_count, _spawn_counts);
			if ((_hazard_table_entry.tags & hazard_tags.uses_up_block) != 0) {
				// Spend a block on each copy of this hazard, one at a time, to work out the difficulty score each number of blocks saves
				var _hazard_copies = (_hazard_table_entry.many == 0) ? 1 : ceil(_object_count), _difficulty_score_saved_per_block_spent = [];
				for (var _blocks_spent = 1; _blocks_spent <= _hazard_copies; _blocks_spent += 1) {
					var _hazard_copies_left = (_hazard_table_entry.many == 0) ? 0 : max(0, _object_count - _blocks_spent);
					var _difficulty_score_saved = _hazard_difficulty_score - calculate_hazard_difficulty_score_for_room(_object_name, _hazard_copies_left, _spawn_counts);
					array_push(_difficulty_score_saved_per_block_spent, _difficulty_score_saved * (1 - BLOCK_MITIGATION_MULTIPLIER));
				}
				array_push(_difficulty_score_saved_per_block_spent_arrays, _difficulty_score_saved_per_block_spent);
			}
			else if (_blocks_left > 0 && (_hazard_table_entry.tags & hazard_tags.destroyed_by_block) != 0) { _hazard_difficulty_score *= BLOCK_MITIGATION_MULTIPLIER; }
			_total_difficulty_score += _hazard_difficulty_score;
		}
	
		// Spend the limited block uses on the copies they save the most on. Estimated block counts can be fractional, so lerp between the whole counts around it
		var _best_savings_for_floor = get_best_block_savings(_difficulty_score_saved_per_block_spent_arrays, 0, floor(_blocks_left));
		var _best_savings_for_ceiling = get_best_block_savings(_difficulty_score_saved_per_block_spent_arrays, 0, ceil(_blocks_left));
		_total_difficulty_score -= lerp(_best_savings_for_floor, _best_savings_for_ceiling, frac(_blocks_left));
		return _total_difficulty_score;
	};

	/// @function calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _spawn_counts)
	/// @description One hazard's difficulty score in a room: its danger value for how many of it there are, turned into a
	///	difficulty score, averaged over the chance the room is lit, and multiplied for the other hazards it shares the room with
	/// @param {string} _hazard_name		The hazard's name in the hazards table
	/// @param {real} _hazard_count			How many of the hazard there are
	/// @param {struct} _spawn_counts		Object names and how many of each spawn in the room
	/// @returns {real}
	static calculate_hazard_difficulty_score_for_room = function(_hazard_name, _hazard_count, _spawn_counts) {
		var _base_hazard_danger = get_danger_for_hazard(_hazard_name, _hazard_count);
		var _base_hazard_difficulty_score = get_difficulty_score_from_danger(_base_hazard_danger);
		var _difficulty_score_with_light_chance = apply_lit_chance_to_difficulty_score(_hazard_name, _base_hazard_difficulty_score);
		var _hazard_combination_multiplier = get_hazard_combination_multiplier(_spawn_counts, _hazard_name);
		return _difficulty_score_with_light_chance * _hazard_combination_multiplier;
	};	

	/// @function apply_lit_chance_to_difficulty_score(_hazard_name, _hazard_difficulty_score)
	/// @description A hazard's difficulty score averaged over the chance the room is lit: one that's dangerous in the dark is
	///	DARK_DIFFICULTY_SCORE_MULTIPLIER times as hard without light
	/// @param {string} _hazard_name					The hazard's name in the hazards table
	/// @param {real} _hazard_difficulty_score			The hazard's difficulty score so far
	/// @returns {real}
	static apply_lit_chance_to_difficulty_score = function(_hazard_name, _hazard_difficulty_score) {
		if (!hazard_has_tag(_hazard_name, hazard_tags.dangerous_in_dark)) { return _hazard_difficulty_score; }
		
		var _chance_of_dark = (1 - chance_of_light);
		return (_hazard_difficulty_score * chance_of_light) + (_hazard_difficulty_score * DARK_DIFFICULTY_SCORE_MULTIPLIER * _chance_of_dark);
	};

	/// @function get_best_block_savings(_difficulty_score_saved_arrays, _index, _blocks_left)
	/// @description The most difficulty score the blocks left can save on the hazards that use up blocks, from _index on, trying
	///	every split of the blocks between them
	/// @param {array} _difficulty_score_saved_arrays	An array for each hazard that uses up blocks, of the difficulty score saved by each number of blocks spent on it
	/// @param {real} _index							Which hazard's array to start from
	/// @param {real} _blocks_left						The number of blocks left to spend
	/// @returns {real}
	static get_best_block_savings = function(_difficulty_score_saved_arrays, _index, _blocks_left) {
		// Return 0 when the end of the array is reached
		if (_index >= array_length(_difficulty_score_saved_arrays)) { return 0; }
	
		// Get the savings for this hazard's array
		var _difficulty_score_saved_array = _difficulty_score_saved_arrays[_index], _best_savings = 0;
		for (var _blocks_spent = 0; _blocks_spent < array_length(_difficulty_score_saved_array) && _blocks_spent <= _blocks_left; _blocks_spent += 1) {
			// Get the savings for this amount of blocks, and recursively check the remaining block spend configurations in the array
			var _current_savings = _difficulty_score_saved_array[_blocks_spent];
			var _remaining_savings = get_best_block_savings(_difficulty_score_saved_arrays, _index + 1, _blocks_left - _blocks_spent);
			var _new_savings = _current_savings + _remaining_savings;
			_best_savings = max(_best_savings, _new_savings);
		}
		return _best_savings;
	};

	// ============================
	// Instance Variables
	// ============================

	chance_holding_staff = _chance_holding_staff;
	chance_holding_sword = _chance_holding_sword;
	chance_holding_special_sword = _chance_holding_special_sword;
	chance_of_light = _chance_of_light;
}
