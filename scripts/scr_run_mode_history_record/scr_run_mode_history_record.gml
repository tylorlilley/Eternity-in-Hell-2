// Save files: one per difficulty and graphics mode, each holding a history record of every run played with that pair

/// @function RunModeHistoryRecord(_difficulty, _graphics_mode)
/// @description An empty history record. It's the shape of every save file, of the run being played
///	(RunRecord.stats_record), and of the totals of any mix of save files, which combine_with_run_mode_history_record
///	adds together:
///	runs: how many runs ended, won, lost or given up. A run's number is one more than this for its difficulty when it
///	begins.
///	wins: how many runs were won
///	best_score: the best final grade
///	stats: each stat's total (see RunStats)
///	evaluation_messages: how many runs earned each achievement, by title (see get_evaluation_messages)
///	deaths: how many times each object killed the player, by object name
///	last_death_run_numbers: the number of the last run each object ended by killing the player, by object name
///	kills_by_killer: for each object killed or destroyed, how many of them each killer killed, by object names (the
///	death log counts the killers is_player_killer says were the player's doing)
///	item_wins: how many runs were won holding each item type, by object name
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for a total of every difficulty
/// @param {real} _graphics_mode The graphics mode (see graphics_modes), or graphics_modes.ALL for a total of every
///	graphics mode
function RunModeHistoryRecord(_difficulty, _graphics_mode) constructor {
	// ============================
	// Save File Functions
	// ============================

	/// @function read_run_mode_history_file()
	/// @description Adds what this record's save file holds to it. A file that can't be read adds nothing and leaves a
	///	warning in the log.
	/// @returns {bool} Whether the file could be read
	static read_run_mode_history_file = function() {
		// Attempt to open the file and return false if that fails
		var _file_name = get_history_file_name(), _buffer = buffer_load(_file_name);
		if (!buffer_exists(_buffer)) {
			write_debug_message("Couldn't open " + _file_name, debug_message_level.warning);
			return false;
		}
		
		// Parse the opened file, catching any errors
		var _was_read = false;
		try {
			var _file_json = json_parse(buffer_read(_buffer, buffer_string));
			add_from_file_json(_file_json);
			_was_read = true;
		}
		catch (_error) { write_debug_message("Couldn't read " + _file_name + ": " + string(_error), debug_message_level.warning); }
		
		// Close the file buffer and return whether the read was successful
		buffer_delete(_buffer);
		return _was_read;
	};

	/// @function add_from_file_json(_json)
	/// @description Adds one history file to this history record, the same way as any other history record, since
	///	that's what the file holds
	/// @param {struct} _json The file json to add to this history record
	static add_from_file_json = function(_json) {
		combine_with_run_mode_history_record(_json);
	};

	/// @function back_up_history_file()
	/// @description Copies the run history file for this run mode to a backup file, numbered with the first backup
	///	number no file has yet, since copying onto an existing file fails
	/// @returns {bool} Whether the backup file was made
	static back_up_history_file = function() {
		// Find a backup file name that hasn't been used yet
		var _backup_file_name = get_history_file_name(1);
		for (var _i = 2; file_exists(_backup_file_name); _i++) { _backup_file_name = get_history_file_name(_i); }
		
		// Copy the file, and return false if that fails
		var _file_name = get_history_file_name();
		file_copy(_file_name, _backup_file_name);
		if (!file_exists(_backup_file_name)) {
			write_debug_message("Couldn't copy " + _file_name + " to " + _backup_file_name + ", so the next save will replace it", debug_message_level.warning);
			return false;
		}
		
		// Return true if the copy was successful
		write_debug_message("Copied " + _file_name + ", which couldn't be read, to " + _backup_file_name + ", and started it over", debug_message_level.warning);
		return true;
	};

	/// @function write_run_mode_history_file()
	/// @description Writes this history record to its save file, and forgets the totals worked out from the old one
	static write_run_mode_history_file = function() {
		var _json = json_stringify(self);
		var _buffer = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
		buffer_write(_buffer, buffer_string, _json);
		buffer_save(_buffer, get_history_file_name());
		buffer_delete(_buffer);
		global.stats_record_totals = {};
	};

	/// @function get_history_file_name([_backup_number])
	/// @description The name of the save file for this run mode, like stats_easy_standard.json, or of one of its
	///	backup files, like stats_easy_standard-backup1.json
	/// @param {real} [_backup_number] The backup number to append (0 by default, for the save file itself)
	/// @returns {string}
	static get_history_file_name = function(_backup_number = 0) {
		static difficulty_names = ["", "easy", "medium", "hard", "very_hard"];
		static graphics_mode_names = ["standard", "farmer", "unknown"];
		var _backup_text = (_backup_number == 0) ? "" : "-backup" + string(_backup_number);
		return "stats_" + difficulty_names[difficulty] + "_" + graphics_mode_names[graphics_mode] + _backup_text + ".json";
	};

	// ============================
	// Public Functions
	// ============================

	/// @function combine_with_run_mode_history_record(_history_record)
	/// @description Adds another history record to this one: counts add up, while best_score and
	///	last_death_run_numbers keep the highest. Anything the other record lacks counts as 0, so history files saved
	///	before a stat or message existed still add in.
	/// @param {RunModeHistoryRecord|struct} _history_record The history record to add to this one, or the json of a
	///	history file
	static combine_with_run_mode_history_record = function(_history_record) {
		runs += get_count_from_struct(_history_record, "runs");
		wins += get_count_from_struct(_history_record, "wins");
		best_score = max(best_score, get_count_from_struct(_history_record, "best_score"));
		evaluation_messages = combine_count_structs(evaluation_messages, _history_record[$ "evaluation_messages"]);
		deaths = combine_count_structs(deaths, _history_record[$ "deaths"]);
		stats = combine_count_structs(stats, _history_record[$ "stats"]);
		item_wins = combine_count_structs(item_wins, _history_record[$ "item_wins"]);
		last_death_run_numbers = combine_count_structs(last_death_run_numbers, _history_record[$ "last_death_run_numbers"], max);
		kills_by_killer = combine_count_structs(kills_by_killer, _history_record[$ "kills_by_killer"]);		// Each struct of killers is combined too
	};

	/// @function add_kills_by_killer(_victim_name, _killer_name, _kills)
	/// @description Adds kills of one type of thing by one killer to this history record
	/// @param {string} _victim_name The object name of what was killed
	/// @param {string} _killer_name The object name of its killer
	/// @param {real} _kills How many to add
	static add_kills_by_killer = function(_victim_name, _killer_name, _kills) {
		if (!is_struct(kills_by_killer[$ _victim_name])) { kills_by_killer[$ _victim_name] = {}; }
		add_to_count_struct(kills_by_killer[$ _victim_name], _killer_name, _kills);
	};

	// ============================
	// Public Getter Functions - Called by the title screen and the run being evaluated
	// ============================

	/// @function get_run_count_string()
	/// @description The title screen's run count
	/// @returns {string|real} The string, or noone if no run has ended
	static get_run_count_string = function() {
		if (runs == 0) { return noone; }
		
		return "Runs Attempted: " + string(runs);
	};

	/// @function get_death_count_string()
	/// @description The title screen's death count
	/// @returns {string} An empty string if the player has never died
	static get_death_count_string = function() {
		var _deaths = get_total_death_count();
		if (_deaths == 0) { return ""; }
		
		return "Deaths: " + string(_deaths);
	};

	/// @function get_total_death_count()
	/// @description How many times the player has died, to anything
	/// @returns {real}
	static get_total_death_count = function() {
		var _killer_names = variable_struct_get_names(deaths), _death_count = 0;
		for (var _i = 0; _i < array_length(_killer_names); _i++) { _death_count += get_count_from_struct(deaths, _killer_names[_i]); }
		return _death_count;
	};

	/// @function get_win_count_string()
	/// @description The title screen's win count
	/// @returns {string} An empty string if the player has never won
	static get_win_count_string = function() {
		if (wins == 0) { return ""; }
		
		return "Victories: " + string(wins);
	};

	/// @function get_best_score_string()
	/// @description The title screen's best grade
	/// @returns {string}
	static get_best_score_string = function() {
		return "Highest Grade: " + get_percentage_string(best_score);
	};

	/// @function get_item_win_count(_item_type)
	/// @description How many runs the player has won while holding an item of one type
	/// @param {Asset.GMObject} _item_type The item type
	/// @returns {real}
	static get_item_win_count = function(_item_type) {
		return get_count_from_struct(item_wins, object_get_name(_item_type));
	};

	/// @function get_death_count(_obj_index)
	/// @description How many times one type of thing has killed the player
	/// @param {Asset.GMObject} _obj_index The killer
	/// @returns {real}
	static get_death_count = function(_obj_index) {
		return get_count_from_struct(deaths, object_get_name(_obj_index));
	};

	/// @function get_player_kill_count(_obj_index)
	/// @description How many of one type of thing the player has killed or destroyed: the kills credited to killers
	///	that is_player_killer says were the player's doing
	/// @param {Asset.GMObject} _obj_index The type killed
	/// @returns {real}
	static get_player_kill_count = function(_obj_index) {
		var _kills_by_killer = kills_by_killer[$ object_get_name(_obj_index)];
		if (!is_struct(_kills_by_killer)) { return 0; }
		
		var _killer_names = variable_struct_get_names(_kills_by_killer), _kill_count = 0;
		for (var _i = 0; _i < array_length(_killer_names); _i++) {
			if (is_player_killer(asset_get_index(_killer_names[_i]))) { _kill_count += get_count_from_struct(_kills_by_killer, _killer_names[_i]); }
		}
		return _kill_count;
	};

	/// @function get_last_killed(_obj_index)
	/// @description The number of the last run one type of thing ended by killing the player. Runs are numbered per
	///	difficulty, so in a total of every difficulty this is the highest of each difficulty's numbers.
	/// @param {Asset.GMObject} _obj_index The killer
	/// @returns {real} The run number, or 0 if it never has
	static get_last_killed = function(_obj_index) {
		return get_count_from_struct(last_death_run_numbers, object_get_name(_obj_index));
	};

	/// @function get_evaluation_message_count(_title)
	/// @description How many runs earned one achievement
	/// @param {string} _title The achievement's title (see get_evaluation_messages)
	/// @returns {real}
	static get_evaluation_message_count = function(_title) {
		return get_count_from_struct(evaluation_messages, _title);
	};

	// ============================
	// Instance Variables
	// ============================

	difficulty = _difficulty;
	graphics_mode = _graphics_mode;
	
	runs = 0;
	wins = 0;
	best_score = 0;
	evaluation_messages = {};
	deaths = {};
	kills_by_killer = {};
	item_wins = {};
	last_death_run_numbers = {};
	stats = new RunStats();
}

// ============================
// Global Run Mode History Functions
// ============================

/// @function get_run_mode_history_record(_difficulty, _graphics_mode)
/// @description Returns the history record for one given run mode, a difficulty and graphics mode combination.
///	Returns it from memory if it is there, otherwise, reads it from the given run mode file. A file that can't be read
///	is copied to a backup file and then started over as a new, empty file, so the player's history isn't lost.
///	Change the record only to add a finished run, then write it.
/// @param {real} _difficulty The difficulty (see difficulties), not ALL
/// @param {real} _graphics_mode The graphics mode (see graphics_modes), not ALL
/// @returns {RunModeHistoryRecord} The history record
function get_run_mode_history_record(_difficulty, _graphics_mode) {
	// Return the corresponding record from memory, if the file has already been opened
	var _run_mode_name = string(_difficulty) + "_" + string(_graphics_mode);
	var _run_mode_history_record = global.saved_history_records[$ _run_mode_name];
	if (!is_undefined(_run_mode_history_record)) { return _run_mode_history_record; }
	
	// Otherwise, create a new record and populate it from the appropriate history file
	_run_mode_history_record = new RunModeHistoryRecord(_difficulty, _graphics_mode);
	if (file_exists(_run_mode_history_record.get_history_file_name())) {
		// Attempt to read the file, and if that fails, attempt to back it up and replace it with one holding the empty record
		if (!_run_mode_history_record.read_run_mode_history_file() && _run_mode_history_record.back_up_history_file()) { _run_mode_history_record.write_run_mode_history_file(); }
	}
	
	// Save this record in memory
	global.saved_history_records[$ _run_mode_name] = _run_mode_history_record;
	return _run_mode_history_record;
}

/// @function get_stats_record_total(_difficulty, [_graphics_mode])
/// @description The saved history records of one or every difficulty and one or every graphics mode, added together.
///	Totals are kept until the next save, so asking again costs nothing. Don't change the record it returns.
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {RunModeHistoryRecord} The total history record
function get_stats_record_total(_difficulty, _graphics_mode = graphics_modes.ALL) {
	var _total_name = string(_difficulty) + "_" + string(_graphics_mode);
	var _total = global.stats_record_totals[$ _total_name];
	if (!is_undefined(_total)) { return _total; }
	
	_total = new RunModeHistoryRecord(_difficulty, _graphics_mode);
	for (var _i = 0; _i < array_length(global.difficulties_array); _i++) {
		var _next_difficulty = global.difficulties_array[_i];
		if (_difficulty != difficulties.ALL && _difficulty != _next_difficulty) { continue; }
		
		for (var _j = 0; _j < array_length(global.graphics_modes_array); _j++) {
			var _next_graphics_mode = global.graphics_modes_array[_j];
			if (_graphics_mode != graphics_modes.ALL && _graphics_mode != _next_graphics_mode) { continue; }
			
			_total.combine_with_run_mode_history_record(get_run_mode_history_record(_next_difficulty, _next_graphics_mode));
		}
	}
	global.stats_record_totals[$ _total_name] = _total;
	return _total;
}
