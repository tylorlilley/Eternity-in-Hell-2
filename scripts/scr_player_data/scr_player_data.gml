/// @function update_death_log(_obj_index, _difficulty, _has_rosary)
/// @description Records in player_data.ini that a death type killed the player, and logs it in the game log. Unless
///	the rosary brings the player back, it also records this run as the last one the death type ended, and logs the
///	run as lost.
/// @param {Asset.GMObject} _obj_index The death type that killed the player
/// @param {real} _difficulty The difficulty played (see difficulties)
/// @param {bool} _has_rosary Whether the player held the rosary, which brings them back, so the run goes on
function update_death_log(_obj_index, _difficulty, _has_rosary) {
	var _previous_death_count = get_death_count(_obj_index, _difficulty), _current_run = get_run_number_count(_difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), object_get_name(_obj_index), _previous_death_count+1);
	if (!_has_rosary) { ini_write_real(get_difficulty_string(_difficulty), object_get_name(_obj_index)+"_last_killed_by", _current_run); }
	ini_close();
	
	if (!_has_rosary) { update_log("outcome", "lost"); }
	update_log("killed_by", object_get_name(_obj_index));
	write_debug_message(object_get_name(_obj_index)+" += 1", debug_message_level.log);
	if (!_has_rosary) { write_debug_message(object_get_name(_obj_index)+"_last_killed_by += 1", debug_message_level.log); }
}

/// @function update_kill_log(_obj_index, _difficulty, _killer)
/// @description Records that a death type was killed: one more kill in the run's evaluation, and in player_data.ini,
///	one more kill of the death type overall and by the killer
/// @param {Asset.GMObject} _obj_index The death type that was killed
/// @param {real} _difficulty The difficulty played (see difficulties)
/// @param {Asset.GMObject} _killer The object that did the killing, such as obj_player
function update_kill_log(_obj_index, _difficulty, _killer) {
	global.controller.evaluation_manager.increment_evaluation_variable("kill_count");
		
	var _previous_kill_count = get_kill_count(_obj_index, _difficulty);
	var _previous_kills_by_killer_count = get_kills_by_killer_count(_obj_index, _difficulty, _killer);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), object_get_name(_obj_index)+"_kills", _previous_kill_count+1);
	ini_write_real(get_difficulty_string(_difficulty), object_get_name(_obj_index)+"_kills_by_"+object_get_name(_killer), _previous_kills_by_killer_count+1);
	ini_close();
	
	write_debug_message(object_get_name(_obj_index)+"_kills += 1", debug_message_level.log);
	write_debug_message(object_get_name(_obj_index)+"_kills_by_"+object_get_name(_killer)+"_kills += 1", debug_message_level.log);
}

/// @function get_death_count(_obj_index, _difficulty)
/// @description How many times a death type has killed the player, including deaths the rosary undid
/// @param {Asset.GMObject} _obj_index The death type
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real}
function get_death_count(_obj_index, _difficulty) {
	var _death_count = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);

		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			_death_count += ini_read_real(get_difficulty_string(_next_difficulty), object_get_name(_obj_index), 0);
			ini_close();
		}
	}
	
	return _death_count;
}

/// @function get_kill_count(_obj_index, _difficulty)
/// @description How many times a death type has been killed, by anything
/// @param {Asset.GMObject} _obj_index The death type
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real}
function get_kill_count(_obj_index, _difficulty) {
	var _kill_count = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			_kill_count += ini_read_real(get_difficulty_string(_next_difficulty), object_get_name(_obj_index)+"_kills", 0);
			ini_close();
		}
	}
	
	return _kill_count;
}

/// @function get_kills_by_killer_count(_obj_index, _difficulty, _killer)
/// @description How many times a death type has been killed by a given killer
/// @param {Asset.GMObject} _obj_index The death type
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {Asset.GMObject} _killer The object that did the killing
/// @returns {real}
function get_kills_by_killer_count(_obj_index, _difficulty, _killer) {
	var _kill_count = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			_kill_count += ini_read_real(get_difficulty_string(_next_difficulty), object_get_name(_obj_index)+"_kills_by_"+object_get_name(_killer), 0);
			ini_close();
		}
	}
	
	return _kill_count;
}

/// @function get_last_killed(_obj_index, _difficulty)
/// @description The number of the last run a death type ended, for the death log's "Last Run Ended" column. With
///	difficulties.ALL it's the highest of the difficulties' run numbers.
/// @param {Asset.GMObject} _obj_index The death type
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real} 0 if the death type has never ended a run
function get_last_killed(_obj_index, _difficulty) {
	var _last_killed = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			var _new_last_killed = ini_read_real(get_difficulty_string(_next_difficulty), object_get_name(_obj_index)+"_last_killed_by", 0);
			if (_new_last_killed > _last_killed) { _last_killed = _new_last_killed; }
			ini_close();
		}
	}
	
	return _last_killed;
}

/// @function get_total_death_count(_difficulty)
/// @description How many times the player has died, to every death type
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real}
function get_total_death_count(_difficulty) {
	var _death_count = 0;
	
	var _death_types = get_death_types();
	while(array_length(_death_types) > 0) {
		var _death_type = array_pop(_death_types);
		_death_count += get_death_count(_death_type, _difficulty);
	}
	
	return _death_count;
}

/// @function get_death_count_string(_difficulty)
/// @description The player's total deaths as text, such as "Deaths: 12"
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {string} An empty string before the first death
function get_death_count_string(_difficulty) { 
	var _deaths = get_total_death_count(_difficulty);
	if (_deaths == 0) { return ""; }
	
	return "Deaths: " + string(_deaths);
}

/// @function get_run_count_string(_difficulty)
/// @description The number of runs the player has started as text, such as "Runs Attempted: 30"
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {string|real} noone before the first run (unlike the other count strings, which give an empty string)
function get_run_count_string(_difficulty) { 
	var _runs = get_run_number_count(_difficulty);
	if (_runs == 0) { return noone; }
	
	return "Runs Attempted: " + string(_runs);
}

/// @function get_difficulties()
/// @description A copy of the playable difficulties, easy to very hard, that the caller can pop from without changing
///	the original
/// @returns {array}
function get_difficulties() {
	var _difficulties_array = global.difficulties_array;
	var _new_array = array_create(array_length(_difficulties_array));
	array_duplicate(_new_array, _difficulties_array);
	return _new_array;
}

/// @function get_death_types()
/// @description A copy of the death types (the objects the death log counts, as what ended a run or what was killed)
///	that the caller can pop from without changing the original
/// @returns {array}
function get_death_types() {
	return array_get_duplicate(global.death_types_array);
}

/// @function array_get_duplicate(_old_array)
/// @description A new array holding the same values as a given one (a shallow copy)
/// @param {array} _old_array The array to copy
/// @returns {array}
function array_get_duplicate(_old_array) {
	var _new_array = array_create(array_length(_old_array));
	array_duplicate(_new_array, _old_array);
	return _new_array;
}


/// @function update_win_log(_difficulty)
/// @description Records a win in player_data.ini: one more win on the difficulty, on each item the player ended the
///	run holding (which unlocks it as a starting item), and in the farmer or unknown graphics mode when played in it.
///	Also logs the outcome and the held items in the game log. Runs on obj_controller, which holds those items.
/// @param {real} _difficulty The difficulty won (see difficulties)
function update_win_log(_difficulty) {
	var _previous_win_count = get_win_count(_difficulty), _previous_unknown_mode_win_count = 0, _previous_extra_mode_win_count = 0, _right_item = noone, _left_item = noone, _right_count = 0, _left_count = 0;
	if (final_player_right_hand_item != noone) { var _right_item = final_player_right_hand_item; _right_count = get_item_win_count(_right_item, _difficulty); }
	if (final_player_left_hand_item != noone) { var _left_item = final_player_left_hand_item; _left_count = get_item_win_count(_left_item, _difficulty); }
	if (global.graphics_mode == graphics_modes.farmer) { _previous_extra_mode_win_count = get_win_count(_difficulty, graphics_modes.farmer); }
	if (global.graphics_mode == graphics_modes.unknown) { _previous_unknown_mode_win_count = get_win_count(_difficulty, graphics_modes.unknown); }
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), "wins", _previous_win_count+1);
	if (_right_item != noone) { ini_write_real(get_difficulty_string(_difficulty), object_get_name(_right_item)+"_wins", _right_count+1); }
	if (_left_item != noone) { ini_write_real(get_difficulty_string(_difficulty), object_get_name(_left_item)+"_wins", _left_count+1); }
	if (global.graphics_mode == graphics_modes.farmer) { ini_write_real(get_difficulty_string(_difficulty), "extra_mode_wins", _previous_extra_mode_win_count+1); }
	if (global.graphics_mode == graphics_modes.unknown) { ini_write_real(get_difficulty_string(_difficulty), "unknown_mode_wins", _previous_unknown_mode_win_count+1); }
	ini_close();
	
	var _outcome_to_log = "won";
	if (_right_item != noone) { _outcome_to_log += "; right hand: "+object_get_name(_right_item); }
	if (_left_item != noone) { _outcome_to_log += "; left hand: "+object_get_name(_left_item); }
	
	update_log("outcome", _outcome_to_log);
	
	
	write_debug_message("wins += 1", debug_message_level.log);
	if (_right_item != noone) { write_debug_message(object_get_name(_right_item)+"_wins += 1", debug_message_level.log); }
	if (_left_item != noone) { write_debug_message(object_get_name(_left_item)+"_wins += 1", debug_message_level.log); }
	if (global.graphics_mode == graphics_modes.farmer) {  write_debug_message("extra_mode_wins += 1", debug_message_level.log); }
	if (global.graphics_mode == graphics_modes.unknown) { write_debug_message("unknown_mode_wins += 1", debug_message_level.log); }
}

/// @function update_run_number_log(_difficulty)
/// @description Counts a new run on a difficulty in player_data.ini, and logs its run number in the game log
/// @param {real} _difficulty The difficulty played (see difficulties)
function update_run_number_log(_difficulty) {
	var _previous_run_number = get_run_number_count(_difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), "run_number", _previous_run_number+1);
	ini_close();
	
	write_debug_message("updated_run_number += 1", debug_message_level.log);
	update_log("run_number", _previous_run_number+1);
}

/// @function update_best_score(_difficulty, _new_score)
/// @description Logs a run's score in the game log, and saves it as the difficulty's best score if it's at least as
///	high as the previous best
/// @param {real} _difficulty The difficulty played (see difficulties)
/// @param {real} _new_score The run's score, from 0 to 100
function update_best_score(_difficulty, _new_score) {
	var _previous_best = get_best_score(_difficulty);
	
	if (_new_score >= _previous_best) { 
		ini_open("player_data.ini");
		ini_write_real(get_difficulty_string(_difficulty), "best_score", _new_score);
		ini_close();
	}
	
	update_log("score", _new_score);
}

/// @function get_win_count(_difficulty, [_graphics_mode])
/// @description How many runs the player has won. The standard graphics mode counts every win, while farmer and
///	unknown count only the wins played in that mode.
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode to count wins in (see graphics_modes; standard by default)
/// @returns {real}
function get_win_count(_difficulty, _graphics_mode = graphics_modes.standard) {
	var _win_count = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			if (_graphics_mode == graphics_modes.standard) { _win_count += ini_read_real(get_difficulty_string(_next_difficulty), "wins", 0); }
			if (_graphics_mode == graphics_modes.farmer) { _win_count += ini_read_real(get_difficulty_string(_next_difficulty), "extra_mode_wins", 0); }
			if (_graphics_mode == graphics_modes.unknown) { _win_count += ini_read_real(get_difficulty_string(_next_difficulty), "unknown_mode_wins", 0); }
			ini_close();
		}
	}
	
	return _win_count;
}

/// @function get_item_win_count(_item_type, _difficulty)
/// @description How many runs the player has won while holding an item. A win unlocks the item as a starting item on
///	that difficulty.
/// @param {Asset.GMObject} _item_type The item's object
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real}
function get_item_win_count(_item_type, _difficulty) {
	var _win_count = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			_win_count += ini_read_real(get_difficulty_string(_next_difficulty), object_get_name(_item_type)+"_wins", 0);
			ini_close();
		}
	}
	
	return _win_count;
}

/// @function get_run_number_count(_difficulty)
/// @description How many runs the player has started, which during a run is that run's number
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real}
function get_run_number_count(_difficulty) {
	var _run_count = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			_run_count += ini_read_real(get_difficulty_string(_next_difficulty), "run_number", 0);
			ini_close();
		}
	}
	
	return _run_count;
}

/// @function get_win_count_string(_difficulty)
/// @description The player's wins as text, such as "Victories: 3"
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {string} An empty string before the first win
function get_win_count_string(_difficulty) { 
	var _wins = get_win_count(_difficulty);
	if (_wins == 0) { return ""; }
	
	return "Victories: " + string(_wins);
}

/// @function get_best_score(_difficulty)
/// @description The player's best score, from 0 to 100
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for the best on any difficulty
/// @returns {real} 0 before the first scored run
function get_best_score(_difficulty) { 
	var _max_score = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			var _previous_score = ini_read_real(get_difficulty_string(_next_difficulty), "best_score", 0);
			if (_max_score < _previous_score) { _max_score = _previous_score; }
			ini_close();
		}
	}
	
	return _max_score;
}

/// @function get_best_score_string(_difficulty)
/// @description The player's best score as text, such as "Highest Grade: 85.00 %"
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for the best on any difficulty
/// @returns {string}
function get_best_score_string(_difficulty) { 
	return "Highest Grade: " + get_percentage_string(get_best_score(_difficulty));
}

/// @function update_setting(_setting_name, _new_value)
/// @description Saves a setting in the Settings section of player_data.ini: a string as a string, anything else as a
///	number
/// @param {string} _setting_name The setting's key
/// @param {any} _new_value The value to save (a string, number or bool)
function update_setting(_setting_name, _new_value) {
	ini_open("player_data.ini");
	if (is_string(_new_value)) { ini_write_string("Settings", _setting_name, _new_value); }
	else { ini_write_real("Settings", _setting_name, _new_value); }
	ini_close();
}

/// @function get_setting(_setting_name, _default_value)
/// @description Reads a setting from the Settings section of player_data.ini, as a string if the default is a string
///	and as a number otherwise
/// @param {string} _setting_name The setting's key
/// @param {any} _default_value What to return when the setting isn't saved
/// @returns {any} The saved value, or the default
function get_setting(_setting_name, _default_value) { 
	var _setting_value = _default_value;
	
	ini_open("player_data.ini");
	if (is_string(_default_value)) { _setting_value = ini_read_string("Settings", _setting_name, _default_value); }
	else { _setting_value = ini_read_real("Settings", _setting_name, _default_value); }
	ini_close();
	
	return _setting_value;
}

/// @function update_setting_for_difficulty(_setting_name, _difficulty, _new_value)
/// @description Saves a setting for one difficulty, in that difficulty's section of player_data.ini: a string as a
///	string, anything else as a number
/// @param {string} _setting_name The setting's key
/// @param {real} _difficulty The difficulty (see difficulties)
/// @param {any} _new_value The value to save (a string, number or bool)
function update_setting_for_difficulty(_setting_name, _difficulty, _new_value) {
	ini_open("player_data.ini");
	if (is_string(_new_value)) { ini_write_string(get_difficulty_string(_difficulty), _setting_name, _new_value); }
	else { ini_write_real(get_difficulty_string(_difficulty), _setting_name, _new_value); }
	ini_close();
}

/// @function get_setting_for_difficulty(_setting_name, _difficulty, _default_value)
/// @description Reads a setting for one difficulty from that difficulty's section of player_data.ini, as a string if
///	the default is a string and as a number otherwise
/// @param {string} _setting_name The setting's key
/// @param {real} _difficulty The difficulty (see difficulties)
/// @param {any} _default_value What to return when the setting isn't saved
/// @returns {any} The saved value, or the default
function get_setting_for_difficulty(_setting_name, _difficulty, _default_value) { 
	var _setting_value = _default_value;
	
	ini_open("player_data.ini");
	if (is_string(_default_value)) { _setting_value = ini_read_string(get_difficulty_string(_difficulty), _setting_name, _default_value); }
	else { _setting_value = ini_read_real(get_difficulty_string(_difficulty), _setting_name, _default_value); }
	ini_close();
	
	return _setting_value;
}


/// @function update_log(_line_name, _new_value)
/// @description Appends a line, "[date and time] - name: value", to the history of runs in game_log.txt in the working
///	directory. The date and time are when the current run (or the game) started.
/// @param {string} _line_name What the line records, such as "outcome"
/// @param {any} _new_value The value, turned into a string if it isn't one
function update_log(_line_name, _new_value) {
	var _file_id = file_text_open_append(working_directory + "game_log.txt");
	var _value_string = is_string(_new_value) ? _new_value : string(_new_value);
	var _new_line = "[" + global.datetime + "] - " + _line_name + ": " + _value_string;
	
    file_text_writeln(_file_id);
	file_text_write_string(_file_id, _new_line);
	file_text_close(_file_id);
}

/// @function update_evaluation_variable(_variable_name, _difficulty, _value)
/// @description Adds to an evaluation variable's saved total for a difficulty in player_data.ini. Spaces in the name
///	become underscores in its key.
/// @param {string} _variable_name The variable's name
/// @param {real} _difficulty The difficulty played (see difficulties)
/// @param {real} _value The amount to add
function update_evaluation_variable(_variable_name, _difficulty, _value) {
	var _name_string = string_replace_all(_variable_name, " ", "_");
	var _previous_value = get_evaluation_variable(_name_string, _difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), _name_string, _previous_value+_value);
	ini_close();
}

/// @function get_evaluation_variable(_variable_name, _difficulty)
/// @description An evaluation variable's saved total (spaces in the name become underscores in its key)
/// @param {string} _variable_name The variable's name
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @returns {real} 0 if it was never saved
function get_evaluation_variable(_variable_name, _difficulty) {
	var _name_string = string_replace_all(_variable_name, " ", "_"), _value = 0;
	
	var _all_difficulties = get_difficulties();
	while (array_length(_all_difficulties) > 0) {
		var _next_difficulty = array_pop(_all_difficulties);
		
		if (_difficulty == difficulties.ALL || _difficulty == _next_difficulty) {
			ini_open("player_data.ini");
			_value += ini_read_real(get_difficulty_string(_next_difficulty), _name_string, 0);
			ini_close();
		}
	}
	
	return _value;
}
