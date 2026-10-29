// Player data that isn't part of any run mode's history: the lists of difficulties and death types, the settings
// kept in player_data.ini, and the game log

/// TODO: Review  the rest of this

// ============================
// Global List Functions
// ============================

/// @function get_difficulties()
/// @description Every difficulty (see global.difficulties_array)
/// @returns {array} A copy the caller may change
function get_difficulties() {
	return variable_clone(global.difficulties_array, 0);
}

/// @function get_death_types()
/// @description Everything that can kill the player, in the death log's order (see global.death_types_array)
/// @returns {array} A copy the caller may change
function get_death_types() {
	return variable_clone(global.death_types_array, 0);
}

// ============================
// Global Setting Functions - Settings stay in player_data.ini
// ============================

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

// ============================
// Global Game Log Functions
// ============================

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
