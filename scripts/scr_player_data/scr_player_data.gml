/// @function								update_death_log(_obj_index, _difficulty, _has_rosary);
///	@param		{obj_id} _obj_index			The object_index value to update
///	@param		{difficulty} _difficulty		The difficulty to update the count for
///	@param		{boolean} _has_rosary		The difficulty to update the count for
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

/// @function								update_kill_log(_obj_index, _difficulty, _killer);
///	@param		{obj_id} _obj_index			The object_index value to update
///	@param		{difficulty} _difficulty		The difficulty to update the count for
///	@param		{obj_id} _killer				The object that did the killing
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

/// @function								get_death_count(_obj_index, _difficulty);
///	@param		{obj_id} _obj_index			The object_index value to get the death count of
///	@param		{difficulty} _difficulty		The difficulty to return a count for
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

/// @function								get_kill_count(_obj_index, _difficulty);
///	@param		{obj_id} _obj_index			The object_index value to get the death count of
///	@param		{difficulty} _difficulty		The difficulty to return a count for
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

/// @function								get_kills_by_killer_count(_obj_index, _difficulty);
///	@param		{obj_id} _obj_index			The object_index value to get the death count of
///	@param		{difficulty} _difficulty		The difficulty to return a count for
///	@param		{obj_id} _killer				The object that did the killing
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

/// @function								get_last_killed(_obj_index, _difficulty);
///	@param		{obj_id} _obj_index			The object_index value to get the last run killed 
///	@param		{difficulty} _difficulty		The difficulty to return a count for
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

/// @function								get_total_death_count(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a count for
function get_total_death_count(_difficulty) {
	var _death_count = 0;
	
	var _death_types = get_death_types();
	while(array_length(_death_types) > 0) {
		var _death_type = array_pop(_death_types);
		_death_count += get_death_count(_death_type, _difficulty);
	}
	
	return _death_count;
}

/// @function								get_death_count_string(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a count for
function get_death_count_string(_difficulty) { 
	var _deaths = get_total_death_count(_difficulty);
	if (_deaths == 0) { return ""; }
	
	return "Deaths: " + string(_deaths);
}

/// @function								get_run_count_string(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a count for
function get_run_count_string(_difficulty) { 
	var _runs = get_run_number_count(_difficulty);
	if (_runs == 0) { return noone; }
	
	return "Runs Attempted: " + string(_runs);
}

/// @function								get_difficulties();
function get_difficulties() {
	var _difficulties_array = global.difficulties_array;
	var _new_array = array_create(array_length(_difficulties_array));
	array_duplicate(_new_array, _difficulties_array);
	return _new_array;
}

/// @function								get_death_types();
function get_death_types() {
	return array_get_duplicate(global.death_types_array);
}

/// @function								get_death_types();
function array_get_duplicate(_old_array) {
	var _new_array = array_create(array_length(_old_array));
	array_duplicate(_new_array, _old_array);
	return _new_array;
}


/// @function								update_win_log(_difficulty, new_score);
///	@param		{difficulty} _difficulty		The difficulty to update the count for
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

/// @function								update_run_number_log(_difficulty, new_score);
///	@param		{difficulty} _difficulty		The difficulty to update the count for
function update_run_number_log(_difficulty) {
	var _previous_run_number = get_run_number_count(_difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), "run_number", _previous_run_number+1);
	ini_close();
	
	write_debug_message("updated_run_number += 1", debug_message_level.log);
	update_log("run_number", _previous_run_number+1);
}

/// @function								update_best_score(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to update the count for
///	@param		{real} _new_score			The new score to record
function update_best_score(_difficulty, _new_score) {
	var _previous_best = get_best_score(_difficulty);
	
	if (_new_score >= _previous_best) { 
		ini_open("player_data.ini");
		ini_write_real(get_difficulty_string(_difficulty), "best_score", _new_score);
		ini_close();
	}
	
	update_log("score", _new_score);
}

/// @function									get_win_count(_difficulty, [_graphics_mode]);
///	@param		{difficulty} _difficulty			The difficulty to return a count for
///	@param		{graphics_mode} _graphics_mode	The graphics mode to return a count for
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

/// @function								get_item_win_count(_item_type, _difficulty);
///	@param		{obj} _item_type				The object index of the item to check for
///	@param		{difficulty} _difficulty		The difficulty to return a count for
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

/// @function								get_run_number_count(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a count for
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

/// @function								get_win_count_string(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a count for
function get_win_count_string(_difficulty) { 
	var _wins = get_win_count(_difficulty);
	if (_wins == 0) { return ""; }
	
	return "Victories: " + string(_wins);
}

/// @function								get_best_score(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a score for
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

/// @function								get_best_score_string(_difficulty);
///	@param		{difficulty} _difficulty		The difficulty to return a count for
function get_best_score_string(_difficulty) { 
	return "Highest Grade: " + get_percentage_string(get_best_score(_difficulty));
}

/// @function								update_setting(obj_index, _setting_name, _new_value);
///	@param		{string} _setting_name		The setting to update the value for
///	@param		{real} _new_value			The new value for the setting
function update_setting(_setting_name, _new_value) {
	ini_open("player_data.ini");
	if (is_string(_new_value)) { ini_write_string("Settings", _setting_name, _new_value); }
	else { ini_write_real("Settings", _setting_name, _new_value); }
	ini_close();
}

/// @function								get_setting(_setting_name, _default_value);
///	@param		{string} _setting_name		The setting to get the value of
///	@param		{real} new_value			The default value for the setting
function get_setting(_setting_name, _default_value) { 
	var _setting_value = _default_value;
	
	ini_open("player_data.ini");
	if (is_string(_default_value)) { _setting_value = ini_read_string("Settings", _setting_name, _default_value); }
	else { _setting_value = ini_read_real("Settings", _setting_name, _default_value); }
	ini_close();
	
	return _setting_value;
}

/// @function								update_setting_for_difficulty(obj_index, _setting_name, _new_value);
///	@param		{string} _setting_name		The setting to update the value for
///	@param		{enum} _difficulty			The difficulty to refrence when setting the setting
///	@param		{real} _new_value			The new value for the setting
function update_setting_for_difficulty(_setting_name, _difficulty, _new_value) {
	ini_open("player_data.ini");
	if (is_string(_new_value)) { ini_write_string(get_difficulty_string(_difficulty), _setting_name, _new_value); }
	else { ini_write_real(get_difficulty_string(_difficulty), _setting_name, _new_value); }
	ini_close();
}

/// @function								get_setting_for_difficulty(_setting_name, _default_value);
///	@param		{string} _setting_name		The setting to get the value of
///	@param		{enum} _difficulty			The difficulty to refrence when getting the setting
///	@param		{real} new_value			The default value for the setting
function get_setting_for_difficulty(_setting_name, _difficulty, _default_value) { 
	var _setting_value = _default_value;
	
	ini_open("player_data.ini");
	if (is_string(_default_value)) { _setting_value = ini_read_string(get_difficulty_string(_difficulty), _setting_name, _default_value); }
	else { _setting_value = ini_read_real(get_difficulty_string(_difficulty), _setting_name, _default_value); }
	ini_close();
	
	return _setting_value;
}


/// @function								update_log(_line_name, _new_value);
///	@param		{string} _line_name			The line to update the date for
///	@param		{real} _new_value			The new value for the setting
function update_log(_line_name, _new_value) {
	var _file_id = file_text_open_append(working_directory + "game_log.txt");
	var _value_string = is_string(_new_value) ? _new_value : string(_new_value);
	var _new_line = "[" + global.datetime + "] - " + _line_name + ": " + _value_string;
	
    file_text_writeln(_file_id);
	file_text_write_string(_file_id, _new_line);
	file_text_close(_file_id);
}

/// @function								update_evaluation_variable(_variable_name, _difficulty, _value);
///	@param		{string} _variable_name		The given name of the variable to update
///	@param		{difficulty} _difficulty		The difficulty to update the value for
///	@param		{int} _value					The amount to increase the variable by
function update_evaluation_variable(_variable_name, _difficulty, _value) {
	var _name_string = string_replace_all(_variable_name, " ", "_");
	var _previous_value = get_evaluation_variable(_name_string, _difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(_difficulty), _name_string, _previous_value+_value);
	ini_close();
}

/// @function								get_evaluation_variable(obj_index, _difficulty);
///	@param		{string} _variable_name		The given name of the variable to get the value for
///	@param		{difficulty} _difficulty		The difficulty to get the value for
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
