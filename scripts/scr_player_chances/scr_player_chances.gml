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
		var _table = get_difficulty_score_table(), _hazard_names = variable_struct_get_names(_hazard_counts);
		var _staff_hazard_counts = duplicate_count_struct(_hazard_counts), _special_sword_hazard_counts = duplicate_count_struct(_hazard_counts);
		var _total_difficulty_score = get_difficulty_score_with_blocks(_hazard_counts), _total_sword_difficulty_score = _total_difficulty_score;
		
		// Loop through each hazard in the counts
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip this hazard if it is not in the difficulty table or has a count of 0
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
		
			// Deal with hazards that can be killed by the sword
			if ((_hazard_table_entry.tags & hazard_tags.killed_by_sword) != 0) {
				// Try using the sword on this hazard, and remember the score if it is the smallest yet for the sword usage
				var _sword_hazard_counts = duplicate_count_struct(_hazard_counts);
				_sword_hazard_counts[$ _hazard_name] = max(0, _hazard_count - 1);
				_total_sword_difficulty_score = min(_total_sword_difficulty_score, get_difficulty_score_with_blocks(_sword_hazard_counts));
				
				// The special sword can be used on all hazards weak to the sword
				_special_sword_hazard_counts[$ _hazard_name] = 0;
			}
		
			// A staff helps partially against anything that moves and shoots, and fully against lava and anything that is only dangerous by shooting
			var _tags = _hazard_table_entry.tags;
			if ((_tags & hazard_tags.immune_with_staff) != 0 || ((_tags & PROJECTILE_STOPPED_BY_STAFF_TAGS) != 0 && (_tags & hazard_tags.stationary) != 0)) { _staff_hazard_counts[$ _hazard_name] = 0; }
			else if ((_tags & PROJECTILE_STOPPED_BY_STAFF_TAGS) != 0) { _staff_hazard_counts[$ _hazard_name] *= STAFF_PROJECTILE_COUNTER_MULTIPLIER; }
		}
	
		var _chance_holding_nothing = (1 - chance_holding_staff - chance_holding_sword - chance_holding_special_sword);
		var _total_staff_difficulty_score = get_difficulty_score_with_blocks(_staff_hazard_counts), _total_special_sword_difficulty_score = get_difficulty_score_with_blocks(_special_sword_hazard_counts);
		return max(0, (_chance_holding_nothing * _total_difficulty_score) + (chance_holding_staff * _total_staff_difficulty_score) + (chance_holding_sword * _total_sword_difficulty_score) + (chance_holding_special_sword * _total_special_sword_difficulty_score));
	};

	/// @function get_difficulty_score_with_blocks(_hazard_counts)
	/// @description The sum of each hazard's points in a room, less what its blocks save. A block that isn't used up is pushed on
	///	from one copy to the next, so it counters them all. One that's used up counters a single copy (lava counts as one), and
	///	saves the same share of that copy's points whichever copy it is, so the blocks go to the copies worth the most first
	/// @param {struct} _hazard_counts Hazard names and how many of each
	/// @returns {real}
	static get_difficulty_score_with_blocks = function(_hazard_counts) {
		var _table = get_difficulty_score_table(), _hazard_names = variable_struct_get_names(_hazard_counts);
		var _blocks_left = get_count_from_struct(_hazard_counts, "obj_block_spot"), _total_difficulty_score = 0, _block_uses = [];
		
		// Loop through each hazard name in the provided count struct
		for (var _i = 0; _i < array_length(_hazard_names); _i++) {
			// Skip this hazard if it is not in the difficulty table or has a count of 0
			var _hazard_name = _hazard_names[_i], _hazard_count = get_count_from_struct(_hazard_counts, _hazard_name), _hazard_table_entry = _table[$ _hazard_name];
			if (is_undefined(_hazard_table_entry) || _hazard_count <= 0) { continue; }
		
			// Get the difficulty score, and modify it based on the blocks present in the room
			var _hazard_difficulty_score = calculate_hazard_difficulty_score_for_room(_hazard_name, _hazard_count, _hazard_counts);
			if ((_hazard_table_entry.tags & hazard_tags.uses_up_block) != 0) {
				var _copies = (_hazard_table_entry.many == 0) ? 1 : _hazard_count;
				// A used-up block saves the same score × (1 − MULT) / copies on any copy of a given hazard.
				array_push(_block_uses, { copies: _copies, savings_per_copy: _hazard_difficulty_score * (1 - BLOCK_COUNTER_MULTIPLIER) / _copies });
			}
			else if (_blocks_left > 0 && (_hazard_table_entry.tags & hazard_tags.destroyed_by_block) != 0) { _hazard_difficulty_score *= BLOCK_COUNTER_MULTIPLIER; }
			_total_difficulty_score += _hazard_difficulty_score;
		}
	
		// Spend the limited block uses on the copies they save the most on
		array_sort(_block_uses, function(_a, _b) { return sign(_b.savings_per_copy - _a.savings_per_copy); });
		for (var _i = 0; _i < array_length(_block_uses) && _blocks_left > 0; _i++) {
			var _blocks_used = min(_blocks_left, _block_uses[_i].copies);
			_total_difficulty_score -= _blocks_used * _block_uses[_i].savings_per_copy;
			_blocks_left -= _blocks_used;
		}
		return _total_difficulty_score;
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
	
	// ============================
	// Instance Variables
	// ============================
	
	chance_holding_staff = _chance_holding_staff;
	chance_holding_sword = _chance_holding_sword;
	chance_holding_special_sword = _chance_holding_special_sword;
	chance_of_light = _chance_of_light;
}
 