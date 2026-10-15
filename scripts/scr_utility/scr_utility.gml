/// @function								get_dir_x_offset(_dir);
/// @param		{dir} _dir					The direction to get the x_offset for
function get_dir_x_offset(_dir) {
	if (_dir == directions.right) { return 1; }
	else if (_dir == directions.left) { return -1; }
	return 0;
}

/// @function								get_dir_y_offset(_dir);
/// @param		{dir} _dir					The direction to get the y_offset for
function get_dir_y_offset(_dir) {
	if (_dir == directions.down) { return 1; }
	else if (_dir == directions.up) { return -1; }
	return 0;
}
	
/// @function								get_scaling_amount(_minimum, _maximum, _numerator, _denominator);
/// @param		{real}	_minimum				The minimum value the scaling amount can be
/// @param		{real}	_maximum				The maximum value the scaling amount can be
/// @param		{real}	_numerator			The numerator of the scaling amount to be added to the minimum
/// @param		{real}	_denominator			The denominator of the scaling amount to be added to the minimum
function get_scaling_amount(_minimum, _maximum, _numerator, _denominator) {
	var _fraction = _numerator/_denominator;
	var _variable_portion = _maximum - _minimum;
	
	return (_minimum+(_variable_portion*(_fraction)));
}

/// @function								get_zero_padded_string(_value_to_pad, _target_length);
/// @param		{real} _value_to_pad			The value to pad with zeros
/// @param		{real} target_legnth		The desired length of the padded string
function get_zero_padded_string(_value_to_pad, _target_length) {
	var _padded_value = string(_value_to_pad);
	
	while (string_length(_padded_value) < _target_length) {
	    _padded_value = "0"+_padded_value;
	}
	
	return _padded_value;
}

/// @function								get_percentage_string(value_to_pad, target_length);
/// @param		{real} _value				The value to transform into a percentage string
function get_percentage_string(_value) {
	var _percentage_string = "", _percentage_value = floor(_value), _percentage_remainder = floor(frac(_value) * 100);
	
	//if (percentage_value < 10) { percentage_string = "0"; }
	_percentage_string += string(_percentage_value);
	_percentage_string += ".";
	if (_percentage_remainder < 10) { _percentage_string += "0"; }
	_percentage_string += string(_percentage_remainder);
	_percentage_string += " %";
	
	return _percentage_string;
}

/// @function								get_opposite_dir(_dir);
/// @param		{direction}	_dir				The direction to return the opposite of
function get_opposite_dir(_dir) {
	if (_dir == directions.stairs) { return directions.stairs; }
	if (_dir == directions.respawn) { return directions.respawn; }
	if (_dir == directions.none) { return directions.none; }
	
	return modulo((_dir+2), 4);
}

/// @function								get_turn_right_dir(_dir);
/// @param		{direction}	_dir				The direction to return the direction to the right of
function get_turn_right_dir(_dir) {
	if (_dir < directions.up || _dir > directions.left) { return -1; }
	else { return modulo((_dir+1), 4); }
}

/// @function								get_turn_left_dir(_dir);
/// @param		{direction}	_dir				The direction to return the direction to the left of
function get_turn_left_dir(_dir) {
	if (_dir < directions.up || _dir > directions.left) { return -1; }
	else { return modulo((_dir-1), 4); }
}

/// @function get_rotated_dir(_dir, _rotation)
/// @description The direction a side faces once its room is rotated to face _rotation
/// @param {real} _dir A side direction
/// @param {real} _rotation The direction the room is rotated to face (directions.up leaves it unturned)
/// @returns {real}
function get_rotated_dir(_dir, _rotation) {
	switch (_rotation) {
		case directions.right: return get_turn_right_dir(_dir);
		case directions.down: return get_opposite_dir(_dir);
		case directions.left: return get_turn_left_dir(_dir);
		default: return _dir;
	}
}

/// @function								get_random_cardinal_dir();
function get_random_cardinal_dir() {
	return irandom(3);
}

/// @function								is_cardinal_direction();
/// @param		{direction}	_dir				The direction to return the cardinality of
function is_cardinal_direction(_dir) {
	return (_dir >= directions.up && _dir <= directions.left);
}

/// @function								get_random_instance(_obj_index);
/// @param		{index} _obj_index			The type of object to get a random existing instance of
/// @param		{boolean} _exact_index		Whether or not to get the exact object index or any ancestor
function get_random_instance(_obj_index, _exact_index = false) {
	// Gets the total number of eligible instances
	var _total_instances = instance_number(_obj_index);
	if (_total_instances == 0) { return noone; }
	
	// Pick a random starting point and check all possible instances
	var _start_pos =  irandom(_total_instances - 1);
	for (var _i = 0; _i < _total_instances; _i++) {
		var _random_instance = instance_find(_obj_index, ((_i+_start_pos) % _total_instances));
		if (_exact_index && _random_instance.object_index != _obj_index) { continue; }
		else { return _random_instance; }
	}
	
	// Return noone if instance is not found
	return noone;
}

/// @function								get_random_chance_out_of(_denominator);
/// @param		{real}	_denominator			The value to use as the denomimnator for the one-in-x chance
function get_random_chance_out_of(_denominator) {
	if (_denominator == 0) { return false; }
	
	return (irandom(_denominator-1) == 0);
}

/// @function get_chance_out_of(_denominator)
/// @description How likely get_random_chance_out_of is to come up true for the same denominator: one in _denominator, or never for 0
/// @param {real} _denominator The denominator of the one-in-x chance
/// @returns {real} From 0 to 1
function get_chance_out_of(_denominator) {
	return (_denominator == 0) ? 0 : 1 / _denominator;
}

/// @function get_binomial_chance(_tries, _chance, _successes)
/// @description The chance that rolling a chance a number of times succeeds exactly a given number of times
/// @param {real} _tries How many times it rolls
/// @param {real} _chance The chance each roll succeeds, from 0 to 1
/// @param {real} _successes How many successes
/// @returns {real} From 0 to 1
function get_binomial_chance(_tries, _chance, _successes) {
	if (_successes < 0 || _successes > _tries) { return 0; }

	var _ways = 1;
	for (var _i = 0; _i < _successes; _i++) { _ways = _ways * (_tries - _i) / (_i + 1); }
	return _ways * power(_chance, _successes) * power(1 - _chance, _tries - _successes);
}

/// @function get_capped_successes_chance(_tries, _chance, _cap, _successes)
/// @description The chance that rolling a chance up to a number of times, and stopping once it has succeeded a capped
///	number of times, ends with exactly a given number of successes
/// @param {real} _tries How many times it can roll
/// @param {real} _chance The chance each roll succeeds, from 0 to 1
/// @param {real} _cap The number of successes it stops at
/// @param {real} _successes How many successes, from 0 to the cap
/// @returns {real} From 0 to 1
function get_capped_successes_chance(_tries, _chance, _cap, _successes) {
	if (_successes < 0 || _successes > _cap) { return 0; }
	if (_successes < _cap) { return get_binomial_chance(_tries, _chance, _successes); }

	// Reaching the cap takes at least that many successes from the uncapped rolls
	var _below_cap = 0;
	for (var _k = 0; _k < _cap; _k++) { _below_cap += get_binomial_chance(_tries, _chance, _k); }
	return max(0, 1 - _below_cap);
}

/// @function get_expected_capped_successes(_tries, _chance, _cap)
/// @description How many successes rolling a chance up to a number of times gives on average, when it stops once it has
///	succeeded a capped number of times
/// @param {real} _tries How many times it can roll
/// @param {real} _chance The chance each roll succeeds, from 0 to 1
/// @param {real} _cap The number of successes it stops at
/// @returns {real}
function get_expected_capped_successes(_tries, _chance, _cap) {
	// A fractional cap, like the one left after an expected number of earlier successes, blends the two whole caps around it
	if (_cap != floor(_cap)) {
		var _lower_cap = floor(_cap);
		return lerp(get_expected_capped_successes(_tries, _chance, _lower_cap), get_expected_capped_successes(_tries, _chance, _lower_cap + 1), _cap - _lower_cap);
	}

	var _expected = 0;
	for (var _k = 1; _k <= _cap; _k++) { _expected += _k * get_capped_successes_chance(_tries, _chance, _cap, _k); }
	return _expected;
}

/// @function								get_coin_flip();
function get_coin_flip() {
	return (irandom(1) == 0);
}

/// @function								get_quadrant_x_pos(_quadrant_number);
/// @param		{real}	_quadrant_number		The number of the quadrant to get the x position for
function get_quadrant_x_pos(_quadrant_number) {
    if (_quadrant_number mod 2 == 0) { return x-4; }
	else { return x+4; }
}

/// @function								get_quadrant_y_pos(_quadrant_number);
/// @param		{real}	_quadrant_number		The number of the quadrant to get the x position for
function get_quadrant_y_pos(_quadrant_number) {
    if (_quadrant_number < 2) { return y-4; }
	else { return y+4; }
}

/// @function								get_exit_x_pos(_dir);
/// @param		{dir}	_dir					The direction of the exit to get the x pos for
function get_exit_x_pos(_dir) {
	switch (_dir) {
		case directions.up: { return room_width/2; }
		case directions.right: { return room_width-8; }
		case directions.down: { return room_width/2; }
		case directions.left: { return 8; }
		default: { return -16; }
	}
}

/// @function								get_exit_y_pos(_dir);
/// @param		{dir}	_dir					The direction of the exit to get the y pos for
function get_exit_y_pos(_dir) {
	switch (_dir) {
		case directions.up: { return 8; }
		case directions.right: { return room_height/2; }
		case directions.down: { return room_height-8; }
		case directions.left: { return room_height/2; }
		default: { return -16; }
	}
}

/// @function								instance_place_all(_x_pos, _y_pos, _obj_type);
/// @param		{real}	_x_pos				The x_pos to check for instances
/// @param		{real}	_y_pos				The x_pos to check for instances
/// @param		{real}	_obj_type			The object type of instance to check for
function instance_place_all(_x_pos, _y_pos, _obj_type) {
	static _potential_matches = ds_list_create();
    ds_list_clear(_potential_matches);
	
    var _total_potential_matches = instance_place_list(_x_pos, _y_pos, _obj_type, _potential_matches, false), _list_of_matches = array_create(_total_potential_matches);
    for (var _i = 0; _i < _total_potential_matches; _i++) { _list_of_matches[_i] = _potential_matches[| _i]; }
    return _list_of_matches;
}

/// @function								play_sound();
///	@param		{Sound}	  _snd				The sound to play
///	@param		{Boolean} loud_soun			Whether the sound is heard by ears or not
function play_sound(_snd, _loud_sound) {
	array_push(global.game_manager.sounds_to_play, _snd);
	if (_loud_sound) {
		with (obj_ears) {
			if (id != other.id) {
				if ((x != other.x || y != other.y) &&
					(target_x != other.x || target_y != other.y) && 
					!instance_place(x, y, obj_meat) && 
					!instance_place(target_x, target_y, obj_meat)) {
						target_x = other.x;
						target_y = other.y;
						awake = true;
						set_automatic_target_path();
						if (target_path != noone) { 
							play_sound(snd_ears, false);
							if (!moved) { move_ears(); }
						}
				}
			}
		}
	}
}

/// @function								instance_create(_x_pos, _y_pos, _obj_index);
///	@param		{real} _x_pos				The x_pos to create the instance at
///	@param		{real} _y_pos				The y_pos to create the instance at
///	@param		{object_index} _obj_index	The object_index to create an instance of
function instance_create(_x_pos, _y_pos, _obj_index) {
	return instance_create_depth(_x_pos, _y_pos, 0, _obj_index);
}

/// @function								is_existing_instance(x_pos, y_pos, obj_index);
///	@param		{id} insty					The instance to check existance for
function is_existing_instance(_inst) {
	return (_inst != noone && instance_exists(_inst));
}

/// @function								get_shader_color_from_gms_color(_given_color);
///	@param		{real} _given_color			The gms color to convert to a shader color
function get_shader_color_from_gms_color(_given_color) {
	var _red = color_get_red(_given_color);
	var _green = color_get_green(_given_color);
	var _blue = color_get_blue(_given_color);
	
	return [_red/255.0, _green/255.0, _blue/255.0, 1.0];
}

/// @function								calculate_gms_game_color();
function calculate_gms_game_color() {
	var _padded_game_color_string = global.game_color_string;
	while (string_length(_padded_game_color_string) < 6) { _padded_game_color_string = "0"+_padded_game_color_string; }
	return get_gms_color_from_hex_string(_padded_game_color_string);
}

/// @function								get_game_bg_color();
function get_game_bg_color() {
	var _controller = global.controller;
	var _tint_amount = is_existing_instance(_controller) ? power(1-(_controller.time_remaining/_controller.time_provided), 8) : 1;
	return merge_color(c_black, global.gms_game_color, _tint_amount);
}

/// @function								get_inverted_game_color();
function get_inverted_game_color() {
	var _controller = global.controller;
	var _tint_amount = is_existing_instance(_controller) ? power(1-(_controller.time_remaining/_controller.time_provided), 8) : 0;
	return merge_color(global.gms_game_color, c_black, _tint_amount);
}

/// @function								get_gms_color_from_hex_string(_hex_string);
///	@param		{string} _hex_string			The string to convert to a color
function get_gms_color_from_hex_string(_hex_string) {
	var _red = get_decimal_from_hex_string(string_copy(_hex_string, 1, 2));
	var _green = get_decimal_from_hex_string(string_copy(_hex_string, 3, 2));
	var _blue = get_decimal_from_hex_string(string_copy(_hex_string, 5, 2));
	
	return make_color_rgb(_red, _green, _blue);
}

/// @function								get_decimal_from_hex_string(_hex_string);
///	@param		{string} _hex_string			The string to convert to a decimal value
function get_decimal_from_hex_string(_hex_string) {
	var _result = 0;
	var _ZERO = ord("0");
	var _NINE = ord("9");
	var _A = ord("A");
	var _F = ord("F");
 
	for (var _i = 1; _i <= string_length(_hex_string); _i++) {
	    var _c = ord(string_char_at(string_upper(_hex_string), _i));
	    // you could also multiply by 16 but you get more nerd points for bitshifts
	    _result = _result << 4;
	    // if the character is a number or letter, add the value
	    // it represents to the total
	    if (_c >= _ZERO && _c <= _NINE) {
	        _result = _result + (_c - _ZERO);
	    } else if (_c >= _A && _c <= _F ) {
	        _result = _result + (_c - _A + 10);
	    } 
	}
 
	return _result;
}

/// @function								modulo(_a, _b);
///	@param		{number} _a					The number to perform the mod on
///	@param		{number} _b					The number to perform the mod with
function modulo(_a, _b) {
	var _Q = (_b < 0) ? ceil(_a/_b) : floor(_a/_b);
	return _a - (_Q * _b);
}

/// @function count_bits(_bitmask)
/// @description How many bits are set in a bitmask.
/// @param {real} _bitmask The bitmask
/// @returns {real}
function count_bits(_bitmask) {
	var _count = 0;
	while (_bitmask != 0) {
		_bitmask &= _bitmask - 1;	// Clears the lowest set bit
		_count += 1;
	}
	return _count;
}

/// @function								mp_path_grid_add(_grid);
///	@param		{id} _grid					The mp_grid to add to
function mp_path_grid_add(_grid) {
	mp_grid_add_rectangle(_grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2 + 1, y + sprite_height/2 + 1);
}

/// @function								mp_path_grid_remove(_grid);
///	@param		{id} _grid					The mp_grid to remove from
function mp_path_grid_remove(_grid) {
	mp_grid_clear_rectangle(_grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2 + 1, y + sprite_height/2 + 1);
}

/// @function								destroy_instances_at_position();
function destroy_instances_at_position() {
	var _game_objects = instance_place_all(x, y, obj_game_object);
	while (array_length(_game_objects) > 0) {
		var _game_object = array_pop(_game_objects);
		if (is_existing_instance(_game_object) && _game_object.id != id) { instance_destroy(_game_object); }
	}
	var _placeholders = instance_place_all(x, y, obj_placeholder);
	while (array_length(_placeholders) > 0) {
		var _placeholder = array_pop(_placeholders);
		if (is_existing_instance(_placeholder) && _placeholder.id != id) { instance_destroy(_placeholder); }
	}
}

/// @hex_to_dec								hex_to_dec(hex);
function hex_to_dec(_hex) 
{
    var _dec = 0;
 
    var _dig = "0123456789ABCDEF";
    var _len = string_length(_hex);
    for (var _pos = 1; _pos <= _len; _pos += 1) {
        _dec = _dec << 4 | (string_pos(string_char_at(_hex, _pos), _dig) - 1);
    }
 
    return _dec;
}

/// Debug Messaging

enum debug_message_level {
	log,
	eval,
	warning,
	error
}

/// @function									get_debug_message_level_string(_debug_message_level);
///	@param		{real} _debug_message_level		The debug message level to translate to a string value
///	@returns	{string}
function get_debug_message_level_string(_debug_message_level) {
	switch (_debug_message_level) {
		case debug_message_level.eval: { return "Eval"; }
		case debug_message_level.log: { return "Log"; }
		case debug_message_level.warning: { return "WARNING"; }
		case debug_message_level.error: { return "ERROR"; }
		default: { return ""; }
	}
}

/// @function								write_debug_message(_msg, [_debug_level]);
///	@param		{string} _msg				The message to write
///	@param		{real} [_debug_level]		Optional level to file the message under
function write_debug_message(_msg, _debug_level = debug_message_level.log) {
	var _debug_message_level_string = get_debug_message_level_string(_debug_level);
	update_log(_debug_message_level_string, _msg);
	show_debug_message(_debug_message_level_string + ": " + _msg);
	if (_debug_level == debug_message_level.error) { show_error(_msg, true); }
}

// ============================
// Count Struct Functions
// ============================

/// @function get_count_from_struct(_count_struct, _key)
/// @description Returnsthe count in a struct of object counts.
/// @param {struct} _count_struct 	The struct of counts to check
/// @param {string} _key			The key to return the count for
/// @returns {real} The count for the key within this struct
function get_count_from_struct(_count_struct, _key) {
	var _count = _count_struct[$ _key];
	return is_undefined(_count) ? 0 : _count;
};

/// @function add_to_count(_count_struct, _key, _value = 1)
/// @description Adds to one the count in a struct of object counts.
/// @param {struct} _count_struct 	The struct of counts to add to
/// @param {string} _key			The key to add to
/// @param {real} _value			Amount to increase the count by
function add_to_count_struct(_count_struct, _key, _value = 1) {
	if (_value == 0) { return; }
	
	_count_struct[$ _key] = get_count_from_struct(_count_struct, _key) + _value;
};

/// @function add_counts_to_count_struct(_count_struct, _added_counts, [_multiplier])
/// @description Adds every count in one count struct to another, each times a multiplier
/// @param {struct} _count_struct 	The struct of counts to add to
/// @param {struct} _added_counts	The struct of counts to add
/// @param {real} [_multiplier]		What to multiply each added count by (1 by default, -1 to take them away)
function add_counts_to_count_struct(_count_struct, _added_counts, _multiplier = 1) {
	var _keys = variable_struct_get_names(_added_counts);
	for (var _i = 0; _i < array_length(_keys); _i++) { add_to_count_struct(_count_struct, _keys[_i], _added_counts[$ _keys[_i]] * _multiplier); }
};

/// @function duplicate_count_struct()
/// @description Makes a copy of the count struct and returns it
/// @param {struct} _count_struct The struct of counts to copy
/// @returns {struct} A copy of the passed in count struct
function duplicate_count_struct(_count_struct) {
	var _count_struct_copy = {}, _keys = variable_struct_get_names(_count_struct);
	for (var _i = 0; _i < array_length(_keys); _i++) { _count_struct_copy[$ _keys[_i]] = _count_struct[$ _keys[_i]]; }
	return _count_struct_copy;
};

/// @function Combine_count_structs(_first_count_struct, _second_count_struct)
/// @description Returns a new count struct that is a combination of the given two structs
/// @param {struct} _first_count_struct The first struct of counts to copy
/// @param {struct} _second_count_struct The second struct of counts to copy
/// @returns {struct} A combined copy of the passed in count structs
function combine_count_structs(_first_count_struct, _second_count_struct) {
	// Get the unique keys present in either of the provided structs
	var _combined_count_struct = {}, _first_keys = variable_struct_get_names(_first_count_struct), _second_keys = variable_struct_get_names(_second_count_struct);
	var _unqiue_keys = array_unique(array_concat(_first_keys, _second_keys));
	
	// For each unique key, get it's counts from both structs, sum them, and add them to the combined struct
	for (var _i = 0; _i < array_length(_unqiue_keys); _i++) {
		var _key = _unqiue_keys[_i];
		_combined_count_struct[$ _key] = get_count_from_struct(_first_count_struct, _key) + get_count_from_struct(_second_count_struct, _key);
	}
	
	// Return the new combined count struct
	return _combined_count_struct;
}
