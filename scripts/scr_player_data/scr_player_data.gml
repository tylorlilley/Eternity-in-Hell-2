// Save files: one per difficulty and graphics mode, each holding a stats record of every run played with that pair

/// @function create_stats_record()
/// @description An empty stats record. It's the shape of every save file, of the run being played
///	(RunRecord.stats_record), and of the totals of any mix of save files, which add_stats_record adds together:
///	runs: how many runs ended, won, lost or given up
///	wins: how many runs were won
///	best_score: the best final grade
///	stats: each stat's total (see create_run_stats)
///	evaluation_messages: how many runs earned each achievement, by title (see get_evaluation_messages)
///	deaths: how many times each object killed the player, by object name
///	last_death_run_numbers: the number of the last run each object ended by killing the player, by object name
///	kills_by_killer: for each object killed or destroyed, how many of them each killer killed, by object names (the
///	death log counts the killers is_player_killer says were the player's doing)
///	item_wins: how many runs were won holding each item type, by object name
/// @returns {struct}
function create_stats_record() {
	return {
		runs: 0,
		wins: 0,
		best_score: 0,
		stats: create_run_stats(),
		evaluation_messages: {},
		deaths: {},
		last_death_run_numbers: {},
		kills_by_killer: {},
		item_wins: {}
	};
}

/// @function get_stats_file_name(_difficulty, _graphics_mode)
/// @description The name of the save file for one difficulty and graphics mode, like stats_easy_standard.json
/// @param {real} _difficulty The difficulty (see difficulties), not ALL
/// @param {real} _graphics_mode The graphics mode (see graphics_modes), not ALL
/// @returns {string}
function get_stats_file_name(_difficulty, _graphics_mode) {
	static difficulty_names = ["", "easy", "medium", "hard", "very_hard"];
	static graphics_mode_names = ["standard", "farmer", "unknown"];
	return "stats_" + difficulty_names[_difficulty] + "_" + graphics_mode_names[_graphics_mode] + ".json";
}

/// @function get_saved_stats_record(_difficulty, _graphics_mode)
/// @description The stats record saved for one difficulty and graphics mode. Each file is read once and then kept
///	in memory (global.saved_stats_records), and a missing file starts from what an older version of the game
///	saved in player_data.ini, if anything. Change it only to add a finished run, then write it.
/// @param {real} _difficulty The difficulty (see difficulties), not ALL
/// @param {real} _graphics_mode The graphics mode (see graphics_modes), not ALL
/// @returns {struct} The stats record (see create_stats_record)
function get_saved_stats_record(_difficulty, _graphics_mode) {
	var _file_name = get_stats_file_name(_difficulty, _graphics_mode);
	var _stats_record = global.saved_stats_records[$ _file_name];
	if (!is_undefined(_stats_record)) { return _stats_record; }

	_stats_record = create_stats_record();
	if (file_exists(_file_name)) { read_stats_record_file(_file_name, _stats_record); }
	else { import_stats_from_player_data_ini(_difficulty, _graphics_mode, _stats_record); }
	global.saved_stats_records[$ _file_name] = _stats_record;
	return _stats_record;
}

/// @function read_stats_record_file(_file_name, _stats_record)
/// @description Adds what a save file holds to a stats record. A file that can't be read adds nothing and leaves a
///	warning in the log.
/// @param {string} _file_name The save file
/// @param {struct} _stats_record The stats record to add to
function read_stats_record_file(_file_name, _stats_record) {
	var _buffer = buffer_load(_file_name);
	if (_buffer == -1) {
		write_debug_message("Couldn't open " + _file_name, debug_message_level.warning);
		return;
	}

	try { add_stats_record(_stats_record, json_parse(buffer_read(_buffer, buffer_string))); }
	catch (_error) { write_debug_message("Couldn't read " + _file_name + ": " + string(_error), debug_message_level.warning); }
	buffer_delete(_buffer);
}

/// @function write_saved_stats_record(_difficulty, _graphics_mode)
/// @description Writes the stats record for one difficulty and graphics mode to its save file, and forgets the
///	totals worked out from the old one
/// @param {real} _difficulty The difficulty (see difficulties), not ALL
/// @param {real} _graphics_mode The graphics mode (see graphics_modes), not ALL
function write_saved_stats_record(_difficulty, _graphics_mode) {
	var _json = json_stringify(get_saved_stats_record(_difficulty, _graphics_mode));
	var _buffer = buffer_create(string_byte_length(_json) + 1, buffer_fixed, 1);
	buffer_write(_buffer, buffer_string, _json);
	buffer_save(_buffer, get_stats_file_name(_difficulty, _graphics_mode));
	buffer_delete(_buffer);
	global.stats_record_totals = {};
}

/// @function get_stats_record_total(_difficulty, [_graphics_mode])
/// @description The saved stats records of one or every difficulty and one or every graphics mode, added together.
///	Totals are kept until the next save, so asking again costs nothing. Don't change the record it returns.
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {struct} A stats record (see create_stats_record)
function get_stats_record_total(_difficulty, _graphics_mode = graphics_modes.ALL) {
	var _total_name = string(_difficulty) + "_" + string(_graphics_mode);
	var _total = global.stats_record_totals[$ _total_name];
	if (!is_undefined(_total)) { return _total; }

	_total = create_stats_record();
	for (var _i = 0; _i < array_length(global.difficulties_array); _i++) {
		var _next_difficulty = global.difficulties_array[_i];
		if (_difficulty != difficulties.ALL && _difficulty != _next_difficulty) { continue; }

		for (var _j = 0; _j < array_length(global.graphics_modes_array); _j++) {
			var _next_graphics_mode = global.graphics_modes_array[_j];
			if (_graphics_mode != graphics_modes.ALL && _graphics_mode != _next_graphics_mode) { continue; }

			add_stats_record(_total, get_saved_stats_record(_next_difficulty, _next_graphics_mode));
		}
	}
	global.stats_record_totals[$ _total_name] = _total;
	return _total;
}

/// @function add_stats_record(_into, _from)
/// @description Adds one stats record to another: counts add up, while best_score and last_death_run_numbers keep
///	the highest. Anything _from lacks counts as 0, so files saved before a stat or message existed still add in.
/// @param {struct} _into The stats record to add to (see create_stats_record)
/// @param {struct} _from The stats record to add, which may be one read from a file
function add_stats_record(_into, _from) {
	_into.runs += get_struct_number(_from, "runs");
	_into.wins += get_struct_number(_from, "wins");
	_into.best_score = max(_into.best_score, get_struct_number(_from, "best_score"));
	add_struct_numbers(_into.stats, _from[$ "stats"]);
	add_struct_numbers(_into.evaluation_messages, _from[$ "evaluation_messages"]);
	add_struct_numbers(_into.deaths, _from[$ "deaths"]);
	keep_highest_struct_numbers(_into.last_death_run_numbers, _from[$ "last_death_run_numbers"]);
	add_struct_numbers(_into.item_wins, _from[$ "item_wins"]);

	// Kills by killer hold a struct of killers for each object killed
	var _kills_by_killer = _from[$ "kills_by_killer"];
	if (!is_struct(_kills_by_killer)) { return; }

	var _victim_names = variable_struct_get_names(_kills_by_killer);
	for (var _i = 0; _i < array_length(_victim_names); _i++) {
		var _victim_name = _victim_names[_i];
		if (!is_struct(_into.kills_by_killer[$ _victim_name])) { _into.kills_by_killer[$ _victim_name] = {}; }
		add_struct_numbers(_into.kills_by_killer[$ _victim_name], _kills_by_killer[$ _victim_name]);
	}
}

/// @function get_struct_number(_struct, _name)
/// @description A number kept in a struct under a name
/// @param {struct} _struct The struct, which may be undefined
/// @param {string} _name The name
/// @returns {real} The number, or 0 when there's no number under that name
function get_struct_number(_struct, _name) {
	if (!is_struct(_struct)) { return 0; }

	var _value = _struct[$ _name];
	return (is_numeric(_value)) ? _value : 0;
}

/// @function add_to_struct_number(_struct, _name, _amount)
/// @description Adds to a number kept in a struct under a name, starting it from 0 if there's none
/// @param {struct} _struct The struct
/// @param {string} _name The name
/// @param {real} _amount How much to add
function add_to_struct_number(_struct, _name, _amount) {
	_struct[$ _name] = get_struct_number(_struct, _name) + _amount;
}

/// @function add_struct_numbers(_into, _from)
/// @description Adds each number in one struct to the number under the same name in another
/// @param {struct} _into The struct to add to
/// @param {struct} _from The struct of numbers to add, which may be undefined
function add_struct_numbers(_into, _from) {
	if (!is_struct(_from)) { return; }

	var _names = variable_struct_get_names(_from);
	for (var _i = 0; _i < array_length(_names); _i++) { add_to_struct_number(_into, _names[_i], get_struct_number(_from, _names[_i])); }
}

/// @function keep_highest_struct_numbers(_into, _from)
/// @description Raises each number in one struct to the number under the same name in another, where that's higher
/// @param {struct} _into The struct to raise numbers in
/// @param {struct} _from The struct of numbers to compare, which may be undefined
function keep_highest_struct_numbers(_into, _from) {
	if (!is_struct(_from)) { return; }

	var _names = variable_struct_get_names(_from);
	for (var _i = 0; _i < array_length(_names); _i++) { _into[$ _names[_i]] = max(get_struct_number(_into, _names[_i]), get_struct_number(_from, _names[_i])); }
}

/// @function add_kills_by_killer(_stats_record, _victim_name, _killer_name, _kills)
/// @description Adds kills of one type of thing by one killer to a stats record
/// @param {struct} _stats_record The stats record (see create_stats_record)
/// @param {string} _victim_name The object name of what was killed
/// @param {string} _killer_name The object name of its killer
/// @param {real} _kills How many to add
function add_kills_by_killer(_stats_record, _victim_name, _killer_name, _kills) {
	var _kills_by_killer = _stats_record.kills_by_killer;
	if (!is_struct(_kills_by_killer[$ _victim_name])) { _kills_by_killer[$ _victim_name] = {}; }
	add_to_struct_number(_kills_by_killer[$ _victim_name], _killer_name, _kills);
}

/// @function import_stats_from_player_data_ini(_difficulty, _graphics_mode, _stats_record)
/// @description Copies what an older version of the game saved in player_data.ini into the stats record of a save
///	file that doesn't exist yet, so a player's history and unlocks carry over. That version kept one section per
///	difficulty and only told graphics modes apart for wins, so the standard file takes everything but the farmer and
///	unknown wins, which go to their own files. Only the player's kills are copied, as the death log shows only
///	those. The ini is only read; once the file is first saved, this isn't needed again.
/// @param {real} _difficulty The difficulty (see difficulties), not ALL
/// @param {real} _graphics_mode The graphics mode (see graphics_modes), not ALL
/// @param {struct} _stats_record The empty stats record to copy into (see create_stats_record)
function import_stats_from_player_data_ini(_difficulty, _graphics_mode, _stats_record) {
	var _section = get_difficulty_string(_difficulty);
	ini_open("player_data.ini");
	var _farmer_wins = ini_read_real(_section, "extra_mode_wins", 0), _unknown_wins = ini_read_real(_section, "unknown_mode_wins", 0);
	switch (_graphics_mode) {
		case graphics_modes.farmer: { _stats_record.wins = _farmer_wins; break; }
		case graphics_modes.unknown: { _stats_record.wins = _unknown_wins; break; }
		case graphics_modes.standard: {
			_stats_record.wins = max(0, ini_read_real(_section, "wins", 0) - _farmer_wins - _unknown_wins);
			_stats_record.runs = ini_read_real(_section, "run_number", 0);
			_stats_record.best_score = ini_read_real(_section, "best_score", 0);

			// Deaths and last deaths were saved under each object's name, and kills under the names of what was killed
			// and its killer. Only the player's kills are copied, as only those are shown: kills credited to the player,
			// a pushed block, special meat, or a fireball, which was how a blast from a bomb the player set off was
			// credited. Phantoms and giant eyes credited themselves, though the player nearly always caused it.
			var _old_player_killer_names = ["obj_player", "obj_block", "obj_meat", "obj_fireball"], _player_killer_names = ["obj_player", "obj_block", "obj_meat", "obj_bomb"];
			for (var _i = 0; _i < array_length(global.death_types_array); _i++) {
				var _object_name = object_get_name(global.death_types_array[_i]);
				var _deaths = ini_read_real(_section, _object_name, 0), _last_death_run_number = ini_read_real(_section, _object_name + "_last_killed_by", 0);
				if (_deaths > 0) { _stats_record.deaths[$ _object_name] = _deaths; }
				if (_last_death_run_number > 0) { _stats_record.last_death_run_numbers[$ _object_name] = _last_death_run_number; }
				for (var _j = 0; _j < array_length(_old_player_killer_names); _j++) {
					var _kills = ini_read_real(_section, _object_name + "_kills_by_" + _old_player_killer_names[_j], 0);
					if (_kills > 0) { add_kills_by_killer(_stats_record, _object_name, _player_killer_names[_j], _kills); }
				}
				if (_object_name == "obj_phantom" || _object_name == "obj_giant_eye") {
					var _self_credited_kills = ini_read_real(_section, _object_name + "_kills_by_" + _object_name, 0);
					if (_self_credited_kills > 0) { add_kills_by_killer(_stats_record, _object_name, "obj_player", _self_credited_kills); }
				}
			}

			// Item wins were saved under each item's name
			var _item_types = global.available_items[difficulties.very_hard];
			for (var _i = 0; _i < array_length(_item_types); _i++) {
				var _item_name = object_get_name(_item_types[_i]), _item_wins = ini_read_real(_section, _item_name + "_wins", 0);
				if (_item_wins > 0) { _stats_record.item_wins[$ _item_name] = _item_wins; }
			}

			// Stats were saved under their names, and bomb kills were called fireball kills
			var _stat_names = variable_struct_get_names(_stats_record.stats);
			for (var _i = 0; _i < array_length(_stat_names); _i++) {
				var _stat_name = _stat_names[_i];
				_stats_record.stats[$ _stat_name] = ini_read_real(_section, (_stat_name == "bomb_kill_count") ? "fireball_kill_count" : _stat_name, 0);
			}

			// Achievements were saved under their titles, with underscores for spaces
			var _messages = get_evaluation_messages();
			for (var _i = 0; _i < array_length(_messages); _i++) {
				if (!_messages[_i].is_achievement) { continue; }

				var _title = _messages[_i].title, _times_earned = ini_read_real(_section, string_replace_all(_title, " ", "_"), 0);
				if (_times_earned > 0) { _stats_record.evaluation_messages[$ _title] = _times_earned; }
			}
			break;
		}
	}
	ini_close();
}


// Reading saved stats

/// @function get_death_count(_obj_index, _difficulty, [_graphics_mode])
/// @description How many times one type of thing has killed the player
/// @param {Asset.GMObject} _obj_index The killer
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_death_count(_obj_index, _difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_struct_number(get_stats_record_total(_difficulty, _graphics_mode).deaths, object_get_name(_obj_index));
}

/// @function get_player_kill_count(_obj_index, _difficulty, [_graphics_mode])
/// @description How many of one type of thing the player has killed or destroyed: the kills credited to killers
///	that is_player_killer says were the player's doing
/// @param {Asset.GMObject} _obj_index The type killed
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_player_kill_count(_obj_index, _difficulty, _graphics_mode = graphics_modes.ALL) {
	var _kills_by_killer = get_stats_record_total(_difficulty, _graphics_mode).kills_by_killer[$ object_get_name(_obj_index)];
	if (!is_struct(_kills_by_killer)) { return 0; }

	var _killer_names = variable_struct_get_names(_kills_by_killer), _kill_count = 0;
	for (var _i = 0; _i < array_length(_killer_names); _i++) {
		if (is_player_killer(asset_get_index(_killer_names[_i]))) { _kill_count += get_struct_number(_kills_by_killer, _killer_names[_i]); }
	}
	return _kill_count;
}

/// @function get_last_killed(_obj_index, _difficulty, [_graphics_mode])
/// @description The number of the last run one type of thing ended by killing the player. Runs are numbered per
///	difficulty, so across every difficulty this is the highest of each difficulty's numbers.
/// @param {Asset.GMObject} _obj_index The killer
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real} The run number, or 0 if it never has
function get_last_killed(_obj_index, _difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_struct_number(get_stats_record_total(_difficulty, _graphics_mode).last_death_run_numbers, object_get_name(_obj_index));
}

/// @function get_total_death_count(_difficulty, [_graphics_mode])
/// @description How many times the player has died, to anything
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_total_death_count(_difficulty, _graphics_mode = graphics_modes.ALL) {
	var _deaths = get_stats_record_total(_difficulty, _graphics_mode).deaths, _killer_names = variable_struct_get_names(_deaths), _death_count = 0;
	for (var _i = 0; _i < array_length(_killer_names); _i++) { _death_count += get_struct_number(_deaths, _killer_names[_i]); }
	return _death_count;
}

/// @function get_death_count_string(_difficulty, [_graphics_mode])
/// @description The title screen's death count
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {string} An empty string if the player has never died
function get_death_count_string(_difficulty, _graphics_mode = graphics_modes.ALL) {
	var _deaths = get_total_death_count(_difficulty, _graphics_mode);
	if (_deaths == 0) { return ""; }

	return "Deaths: " + string(_deaths);
}

/// @function get_run_count_string(_difficulty, [_graphics_mode])
/// @description The title screen's run count
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {string|real} The string, or noone if no run has ended
function get_run_count_string(_difficulty, _graphics_mode = graphics_modes.ALL) {
	var _runs = get_run_number_count(_difficulty, _graphics_mode);
	if (_runs == 0) { return noone; }

	return "Runs Attempted: " + string(_runs);
}

/// @function get_win_count(_difficulty, [_graphics_mode])
/// @description How many runs the player has won
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_win_count(_difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_stats_record_total(_difficulty, _graphics_mode).wins;
}

/// @function get_item_win_count(_item_type, _difficulty, [_graphics_mode])
/// @description How many runs the player has won while holding an item of one type
/// @param {Asset.GMObject} _item_type The item type
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_item_win_count(_item_type, _difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_struct_number(get_stats_record_total(_difficulty, _graphics_mode).item_wins, object_get_name(_item_type));
}

/// @function get_run_number_count(_difficulty, [_graphics_mode])
/// @description How many runs have ended, won, lost or given up. A run's number is one more than this for its
///	difficulty when it begins.
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_run_number_count(_difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_stats_record_total(_difficulty, _graphics_mode).runs;
}

/// @function get_win_count_string(_difficulty, [_graphics_mode])
/// @description The title screen's win count
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {string} An empty string if the player has never won
function get_win_count_string(_difficulty, _graphics_mode = graphics_modes.ALL) {
	var _wins = get_win_count(_difficulty, _graphics_mode);
	if (_wins == 0) { return ""; }

	return "Victories: " + string(_wins);
}

/// @function get_best_score(_difficulty, [_graphics_mode])
/// @description The best final grade the player has earned
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_best_score(_difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_stats_record_total(_difficulty, _graphics_mode).best_score;
}

/// @function get_best_score_string(_difficulty, [_graphics_mode])
/// @description The title screen's best grade
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {string}
function get_best_score_string(_difficulty, _graphics_mode = graphics_modes.ALL) {
	return "Highest Grade: " + get_percentage_string(get_best_score(_difficulty, _graphics_mode));
}

/// @function get_evaluation_message_count(_title, _difficulty, [_graphics_mode])
/// @description How many saved runs earned one achievement
/// @param {string} _title The achievement's title (see get_evaluation_messages)
/// @param {real} _difficulty The difficulty (see difficulties), or difficulties.ALL for every difficulty
/// @param {real} [_graphics_mode] The graphics mode (see graphics_modes), every graphics mode by default
/// @returns {real}
function get_evaluation_message_count(_title, _difficulty, _graphics_mode = graphics_modes.ALL) {
	return get_struct_number(get_stats_record_total(_difficulty, _graphics_mode).evaluation_messages, _title);
}


// Lists

/// @function get_difficulties()
/// @description Every difficulty (see global.difficulties_array)
/// @returns {array} A copy the caller may change
function get_difficulties() {
	var _difficulties_array = global.difficulties_array;
	var _new_array = array_create(array_length(_difficulties_array));
	array_duplicate(_new_array, _difficulties_array);
	return _new_array;
}

/// @function get_death_types()
/// @description Everything that can kill the player, in the death log's order (see global.death_types_array)
/// @returns {array} A copy the caller may change
function get_death_types() {
	return array_get_duplicate(global.death_types_array);
}

/// @function array_get_duplicate(_old_array)
/// @description A copy of an array
/// @param {array} _old_array The array to copy
/// @returns {array}
function array_get_duplicate(_old_array) {
	var _new_array = array_create(array_length(_old_array));
	array_duplicate(_new_array, _old_array);
	return _new_array;
}


// Settings, which stay in player_data.ini

/// @function update_setting(_setting_name, _new_value)
/// @description Saves a setting
/// @param {string} _setting_name The setting
/// @param {real|string} _new_value Its new value
function update_setting(_setting_name, _new_value) {
	ini_open("player_data.ini");
	if (is_string(_new_value)) { ini_write_string("Settings", _setting_name, _new_value); }
	else { ini_write_real("Settings", _setting_name, _new_value); }
	ini_close();
}

/// @function get_setting(_setting_name, _default_value)
/// @description A saved setting
/// @param {string} _setting_name The setting
/// @param {real|string} _default_value Its value if it was never saved, which also says whether it's a string
/// @returns {real|string}
function get_setting(_setting_name, _default_value) {
	var _setting_value = _default_value;

	ini_open("player_data.ini");
	if (is_string(_default_value)) { _setting_value = ini_read_string("Settings", _setting_name, _default_value); }
	else { _setting_value = ini_read_real("Settings", _setting_name, _default_value); }
	ini_close();

	return _setting_value;
}

/// @function update_setting_for_difficulty(_setting_name, _difficulty, _new_value)
/// @description Saves a setting kept separately for each difficulty
/// @param {string} _setting_name The setting
/// @param {real} _difficulty The difficulty (see difficulties)
/// @param {real|string} _new_value Its new value
function update_setting_for_difficulty(_setting_name, _difficulty, _new_value) {
	ini_open("player_data.ini");
	if (is_string(_new_value)) { ini_write_string(get_difficulty_string(_difficulty), _setting_name, _new_value); }
	else { ini_write_real(get_difficulty_string(_difficulty), _setting_name, _new_value); }
	ini_close();
}

/// @function get_setting_for_difficulty(_setting_name, _difficulty, _default_value)
/// @description A saved setting kept separately for each difficulty
/// @param {string} _setting_name The setting
/// @param {real} _difficulty The difficulty (see difficulties)
/// @param {real|string} _default_value Its value if it was never saved, which also says whether it's a string
/// @returns {real|string}
function get_setting_for_difficulty(_setting_name, _difficulty, _default_value) {
	var _setting_value = _default_value;

	ini_open("player_data.ini");
	if (is_string(_default_value)) { _setting_value = ini_read_string(get_difficulty_string(_difficulty), _setting_name, _default_value); }
	else { _setting_value = ini_read_real(get_difficulty_string(_difficulty), _setting_name, _default_value); }
	ini_close();

	return _setting_value;
}


// Game log

/// @function update_log(_line_name, _new_value)
/// @description Adds a line to game_log.txt, stamped with when the game or run began
/// @param {string} _line_name What the line records
/// @param {real|string} _new_value The value to record
function update_log(_line_name, _new_value) {
	var _file_id = file_text_open_append(working_directory + "game_log.txt");
	var _value_string = is_string(_new_value) ? _new_value : string(_new_value);
	var _new_line = "[" + global.datetime + "] - " + _line_name + ": " + _value_string;

	file_text_writeln(_file_id);
	file_text_write_string(_file_id, _new_line);
	file_text_close(_file_id);
}
