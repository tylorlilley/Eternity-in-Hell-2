/// @function								update_death_log(obj_index, difficulty, new_score);
///	@param		{obj_id} obj_index			The object_index value to update
///	@param		{difficulty} difficulty		The difficulty to update the count for
function update_death_log(obj_index, difficulty) {
	var previous_death_count = get_death_count(obj_index, difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(difficulty), object_get_name(obj_index), previous_death_count+1);
	ini_close();
	
	update_best_score(difficulty);
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
	var new_array = array_create(array_length(global.difficulties_array));
	array_copy(new_array, 0, global.difficulties_array, 0, array_length(global.difficulties_array));
	return new_array;
}

/// @function								get_death_types();
function get_death_types() {
	var new_array = array_create(array_length(global.death_types_array));
	array_copy(new_array, 0, global.death_types_array, 0, array_length(global.death_types_array));
	return new_array;

}

/// @function								update_win_log(difficulty, new_score);
///	@param		{difficulty} difficulty		The difficulty to update the count for
///	@param		{real} new_score			The new score to record
function update_win_log(difficulty) {
	var previous_win_count = get_win_count(difficulty);
	
	ini_open("player_data.ini");
	ini_write_real(get_difficulty_string(difficulty), "wins", previous_win_count+1);
	ini_close();
	
	update_best_score(difficulty)
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
}

/// @function								get_win_count(difficulty);
///	@param		{difficulty} difficulty		The difficulty to return a count for
function get_win_count(difficulty) {
	var win_count = 0;
	
	var all_difficulties = get_difficulties();
	while (array_length(all_difficulties) > 0) {
		var next_difficulty = array_pop(all_difficulties);
		
		if (difficulty == all || difficulty == next_difficulty) {
			ini_open("player_data.ini");
			win_count += ini_read_real(get_difficulty_string(next_difficulty), "wins", 0);
			ini_close();
		}
	}
	
	return win_count;
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