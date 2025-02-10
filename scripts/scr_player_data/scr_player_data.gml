/// @function								update_death_log(obj_index, difficulty);
///	@param		{obj_id} obj_index			The object_index value to update
///	@param		{difficulty} difficulty		The difficulty to update the count for
function update_death_log(obj_index, difficulty) {
	var previous_death_count = get_death_count(obj_index, difficulty), var current_run = get_run_number_count(difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(difficulty), object_get_name(obj_index), previous_death_count+1);
	ini_write_real(get_difficulty_string(difficulty), object_get_name(obj_index)+"_last_killed_by", current_run);
	ini_close();
	
	update_log("outcome", "lost");
	update_log("killed_by", object_get_name(obj_index));
	
	update_best_score(difficulty);
}

/// @function								update_kill_log(obj_index, difficulty);
///	@param		{obj_id} obj_index			The object_index value to update
///	@param		{difficulty} difficulty		The difficulty to update the count for
///	@param		{obj_id} killer				The object that did the killing
function update_kill_log(obj_index, difficulty, killer) {
	var previous_kill_count = get_kill_count(obj_index, difficulty);
	var previous_kills__by_killer_count = get_kills_by_killer_count(obj_index, difficulty, killer);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(difficulty), object_get_name(obj_index)+"_kills", previous_kill_count+1);
	ini_write_real(get_difficulty_string(difficulty), object_get_name(obj_index)+"_kills_by_"+object_get_name(killer), previous_kills__by_killer_count+1);
	ini_close();
}

/// @function								get_death_count(obj_index, difficulty);
///	@param		{obj_id} obj_index			The object_index value to get the death count of
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_death_count(obj_index, difficulty) {
	var death_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			death_count += ini_read_real(get_difficulty_string(next_difficulty), object_get_name(obj_index), 0);
			ini_close();
		}
	}
	
	return death_count;
}

/// @function								get_kill_count(obj_index, difficulty);
///	@param		{obj_id} obj_index			The object_index value to get the death count of
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_kill_count(obj_index, difficulty) {
	var kill_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			kill_count += ini_read_real(get_difficulty_string(next_difficulty), object_get_name(obj_index)+"_kills", 0);
			ini_close();
		}
	}
	
	return kill_count;
}

/// @function								get_kills_by_killer_count(obj_index, difficulty);
///	@param		{obj_id} obj_index			The object_index value to get the death count of
///	@param		{difficulty} difficulty		The difficulty to return a count for
///	@param		{obj_id} killer				The object that did the killing
function get_kills_by_killer_count(obj_index, difficulty, killer) {
	var kill_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			kill_count += ini_read_real(get_difficulty_string(next_difficulty), object_get_name(obj_index)+"_kills_by_"+object_get_name(killer), 0);
			ini_close();
		}
	}
	
	return kill_count;
}

/// @function								get_kill_count(obj_index, difficulty);
///	@param		{obj_id} obj_index			The object_index value to get the death count of
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_last_killed(obj_index, difficulty) {
	var last_killed = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			last_killed = ini_read_real(get_difficulty_string(next_difficulty), object_get_name(obj_index)+"_last_killed_by", 0);
			ini_close();
		}
	}
	
	return last_killed;
}

/// @function								get_total_death_count(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_total_death_count(difficulty) {
	var death_count = 0;
	
	var death_types = get_death_types();
	while(array_length(death_types) > 0) {
		var death_type = array_pop(death_types);
		death_count += get_death_count(death_type, difficulty);
	}
	
	return death_count;
}

/// @function								get_death_count_string(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_death_count_string(difficulty) { 
	var deaths = get_total_death_count(difficulty);
	if (deaths == 0) { return noone; }
	
	return "Death Count: " + string(deaths);
}

/// @function								get_difficulties();
function get_difficulties() {
	var difficulties_array = global.difficulties_array;
	var new_array = array_create(array_length(difficulties_array));
	array_duplicate(new_array, difficulties_array);
	return new_array;
}

/// @function								get_death_types();
function get_death_types() {
	return array_get_duplicate(global.death_types_array);
}

/// @function								get_death_types();
function array_get_duplicate(old_array) {
	var new_array = array_create(array_length(old_array));
	array_duplicate(new_array, old_array);
	return new_array;
}


/// @function								update_win_log(difficulty, new_score);
///	@param		{difficulty} difficulty		The difficulty to update the count for
function update_win_log(difficulty) {
	var previous_win_count = get_win_count(difficulty), previous_unknown_mode_win_count = 0, previous_extra_mode_win_count = 0, right_item = noone, left_item = noone, right_count = 0, left_count = 0;
	if (final_player_right_hand_item != noone) { var right_item = final_player_right_hand_item; right_count = get_item_win_count(right_item, difficulty); }
	if (final_player_left_hand_item != noone) { var left_item = final_player_left_hand_item; left_count = get_item_win_count(left_item, difficulty); }
	if (global.graphics_mode == graphics_modes.farmer) { previous_extra_mode_win_count = get_win_count(difficulty, graphics_modes.farmer); }
	if (global.graphics_mode == graphics_modes.unknown) { previous_unknown_mode_win_count = get_win_count(difficulty, graphics_modes.unknown); }
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(difficulty), "wins", previous_win_count+1);
	if (right_item != noone) { ini_write_real(get_difficulty_string(difficulty), object_get_name(right_item)+"_wins", right_count+1); }
	if (left_item != noone) { ini_write_real(get_difficulty_string(difficulty), object_get_name(left_item)+"_wins", left_count+1); }
	if (global.graphics_mode == graphics_modes.farmer) { ini_write_real(get_difficulty_string(difficulty), "extra_mode_wins", previous_extra_mode_win_count+1); }
	if (global.graphics_mode == graphics_modes.unknown) { ini_write_real(get_difficulty_string(difficulty), "unknown_mode_wins", previous_unknown_mode_win_count+1); }
	ini_close();
	
	var outcome_to_log = "won";
	if (right_item != noone) { outcome_to_log += "; right hand: "+object_get_name(right_item); }
	if (left_item != noone) { outcome_to_log += "; left hand: "+object_get_name(left_item); }
	
	update_log("outcome", outcome_to_log);
	
	update_best_score(difficulty)
}

/// @function								update_run_number_log(difficulty, new_score);
///	@param		{difficulty} difficulty		The difficulty to update the count for
function update_run_number_log(difficulty) {
	var previous_run_number = get_run_number_count(difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(difficulty), "run_number", previous_run_number+1);
	ini_close();
	
	update_log("run_number", previous_run_number+1);
}

/// @function								update_best_score(difficulty);
///	@param		{difficulty} difficulty		The difficulty to update the count for
///	@param		{real} new_score			The new score to record
function update_best_score(difficulty) {
	var previous_best = get_best_score(difficulty);
	var new_score = get_current_score();
	
	if (new_score >= previous_best) { 
		ini_open("player_data.ini");
		ini_write_real(get_difficulty_string(difficulty), "best_score", new_score);
		ini_close();
	}
	
	update_log("score", new_score);
	
	update_run_number_log(global.difficulty);
}

/// @function									get_win_count(difficulty, [graphics_mode]);
///	@param		{difficulty} difficulty			The difficulty to return a count for
///	@param		{graphics_mode} graphics_mode	The graphics mode to return a count for
function get_win_count(difficulty, graphics_mode = graphics_modes.standard) {
	var win_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			if (graphics_mode == graphics_modes.standard) { win_count += ini_read_real(get_difficulty_string(next_difficulty), "wins", 0); }
			if (graphics_mode == graphics_modes.farmer) { win_count += ini_read_real(get_difficulty_string(next_difficulty), "extra_mode_wins", 0); }
			if (graphics_mode == graphics_modes.unknown) { win_count += ini_read_real(get_difficulty_string(next_difficulty), "unknown_mode_wins", 0); }
			ini_close();
		}
	}
	
	return win_count;
}

/// @function								get_item_win_count(item_type, difficulty);
///	@param		{obj} item_type				The object index of the item to check for
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_item_win_count(item_type, difficulty) {
	var win_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			win_count += ini_read_real(get_difficulty_string(next_difficulty), object_get_name(item_type)+"_wins", 0);
			ini_close();
		}
	}
	
	return win_count;
}

/// @function								get_run_number_count(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_run_number_count(difficulty) {
	var run_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			run_count += ini_read_real(get_difficulty_string(next_difficulty), "run_number", 1);
			ini_close();
		}
	}
	
	return run_count;
}

/// @function								get_win_count_string(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_win_count_string(difficulty) { 
	var wins = get_win_count(difficulty);
	if (wins == 0) { return noone; }
	
	return "Victories: " + string(wins);
}

/// @function								get_best_score(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a score for
function get_best_score(difficulty) { 
	var max_score = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			var previous_score = ini_read_real(get_difficulty_string(next_difficulty), "best_score", 0);
			if (max_score < previous_score) { max_score = previous_score; }
			ini_close();
		}
	}
	
	return max_score;
}

/// @function								get_best_score_string(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_best_score_string(difficulty) { 
	return "Highest Grade: " + get_percentage_string(get_best_score(difficulty));
}

/// @function								update_setting(obj_index, setting_name, new_value);
///	@param		{string} setting_name	The setting to update the value for
///	@param		{real} new_value			The new value for the setting
function update_setting(setting_name, new_value) {
	ini_open("player_data.ini");
	if (is_string(new_value)) { ini_write_string("Settings", setting_name, new_value); }
	else { ini_write_real("Settings", setting_name, new_value); }
	ini_close();
}

/// @function								get_setting(setting_name, default_value);
///	@param		{string} setting_name		The setting to get the value of
///	@param		{real} new_value			The default value for the setting
function get_setting(setting_name, default_value) { 
	var setting_value = default_value;
	
	ini_open("player_data.ini");
	if (is_string(default_value)) { setting_value = ini_read_string("Settings", setting_name, default_value); }
	else { setting_value = ini_read_real("Settings", setting_name, default_value); }
	ini_close();
	
	return setting_value;
}

/// @function								update_setting_for_difficulty(obj_index, setting_name, new_value);
///	@param		{string} setting_name		The setting to update the value for
///	@param		{enum} difficulty			The difficulty to refrence when setting the setting
///	@param		{real} new_value			The new value for the setting
function update_setting_for_difficulty(setting_name, difficulty, new_value) {
	ini_open("player_data.ini");
	if (is_string(new_value)) { ini_write_string(get_difficulty_string(difficulty), setting_name, new_value); }
	else { ini_write_real(get_difficulty_string(difficulty), setting_name, new_value); }
	ini_close();
}

/// @function								get_setting_for_difficulty(setting_name, default_value);
///	@param		{string} setting_name		The setting to get the value of
///	@param		{enum} difficulty			The difficulty to refrence when getting the setting
///	@param		{real} new_value			The default value for the setting
function get_setting_for_difficulty(setting_name, difficulty, default_value) { 
	var setting_value = default_value;
	
	ini_open("player_data.ini");
	if (is_string(default_value)) { setting_value = ini_read_string(get_difficulty_string(difficulty), setting_name, default_value); }
	else { setting_value = ini_read_real(get_difficulty_string(difficulty), setting_name, default_value); }
	ini_close();
	
	return setting_value;
}

/// @function								update_log(line_name, new_value);
///	@param		{string} line_name			The line to update the date for
///	@param		{real} new_value			The new value for the setting
function update_log(line_name, new_value) {
	ini_open("game_log.ini");
	if (is_string(new_value)) { ini_write_string(global.datetime, line_name, new_value); }
	else { ini_write_real(global.datetime, line_name, new_value); }
	ini_close();
}