/// @function get_dir_x_offset(_dir)
/// @description The horizontal step that one move in a direction takes
/// @param {real} _dir The direction (see directions)
/// @returns {real} 1 for right, -1 for left, and 0 for any other direction
function get_dir_x_offset(_dir) {
	if (_dir == directions.right) { return 1; }
	else if (_dir == directions.left) { return -1; }
	return 0;
}

/// @function get_dir_y_offset(_dir)
/// @description The vertical step that one move in a direction takes
/// @param {real} _dir The direction (see directions)
/// @returns {real} 1 for down, -1 for up, and 0 for any other direction
function get_dir_y_offset(_dir) {
	if (_dir == directions.down) { return 1; }
	else if (_dir == directions.up) { return -1; }
	return 0;
}
	
/// @function get_scaling_amount(_minimum, _maximum, _numerator, _denominator)
/// @description Scales linearly from _minimum to _maximum by the fraction _numerator / _denominator, such as a torch's
///	light range shrinking as it burns down
/// @param {real} _minimum The value for a fraction of 0
/// @param {real} _maximum The value for a fraction of 1
/// @param {real} _numerator The numerator of the fraction
/// @param {real} _denominator The denominator of the fraction
/// @returns {real} The scaled value, which isn't clamped, so a fraction outside 0 to 1 lands outside the range
function get_scaling_amount(_minimum, _maximum, _numerator, _denominator) {
	var _fraction = _numerator/_denominator;
	var _variable_portion = _maximum - _minimum;
	
	return (_minimum+(_variable_portion*(_fraction)));
}

/// @function get_zero_padded_string(_value_to_pad, _target_length)
/// @description Turns a value into a string with zeros added in front until it is _target_length characters long
/// @param {real} _value_to_pad The value to pad with zeros
/// @param {real} _target_length The length to pad the string to
/// @returns {string} The padded string, with no zeros added if it is already that long
function get_zero_padded_string(_value_to_pad, _target_length) {
	var _padded_value = string(_value_to_pad)
	
	while (string_length(_padded_value) < _target_length) {
	    _padded_value = "0"+_padded_value;
	}
	
	return _padded_value;
}

/// @function get_percentage_string(_value)
/// @description Formats a percentage with two decimal places, rounded down, such as "12.34 %" for 12.345
/// @param {real} _value The percentage, from 0 to 100 rather than 0 to 1
/// @returns {string}
function get_percentage_string(_value) {
	var _percentage_string = "", _percentage_value = floor(_value), _percentage_remainder = floor(frac(_value) * 100);
	
	_percentage_string += string(_percentage_value);
	_percentage_string += ".";
	if (_percentage_remainder < 10) { _percentage_string += "0"; }
	_percentage_string += string(_percentage_remainder);
	_percentage_string += " %";
	
	return _percentage_string;
}

/// @function get_opposite_dir(_dir)
/// @description The direction opposite a given one
/// @param {real} _dir The direction (see directions)
/// @returns {real} The opposite direction, or the same direction for stairs, respawn and none
function get_opposite_dir(_dir) {
	if (_dir == directions.stairs) { return directions.stairs; }
	if (_dir == directions.respawn) { return directions.respawn; }
	if (_dir == directions.none) { return directions.none; }
	
	return modulo((_dir+2), 4);
}

/// @function get_turn_right_dir(_dir)
/// @description The cardinal direction a quarter turn clockwise from a given one, such as right from up
/// @param {real} _dir The direction (see directions)
/// @returns {real} The turned direction, or -1 if _dir isn't a cardinal direction
function get_turn_right_dir(_dir) {
	if (_dir < directions.up || _dir > directions.left) { return -1; }
	else { return modulo((_dir+1), 4); }
}

/// @function get_turn_left_dir(_dir)
/// @description The cardinal direction a quarter turn counterclockwise from a given one, such as left from up
/// @param {real} _dir The direction (see directions)
/// @returns {real} The turned direction, or -1 if _dir isn't a cardinal direction
function get_turn_left_dir(_dir) {
	if (_dir < directions.up || _dir > directions.left) { return -1; }
	else { return modulo((_dir-1), 4); }
}

/// @function get_rotated_dir(_dir, _rotation)
/// @description The direction a side faces once its room is rotated to face _rotation
/// @param {real} _dir A side direction (see directions)
/// @param {real} _rotation The direction the room is rotated to face (see directions), where up leaves it unturned
/// @returns {real} The rotated direction (see directions)
function get_rotated_dir(_dir, _rotation) {
	switch (_rotation) {
		case directions.right: return get_turn_right_dir(_dir);
		case directions.down: return get_opposite_dir(_dir);
		case directions.left: return get_turn_left_dir(_dir);
		default: return _dir;
	}
}

/// @function get_random_cardinal_dir()
/// @description Picks one of the four cardinal directions at random
/// @returns {real} Up, right, down or left (see directions)
function get_random_cardinal_dir() {
	return irandom(3);
}

/// @function is_cardinal_direction(_dir)
/// @description Whether a direction is up, right, down or left, rather than stairs, respawn or none
/// @param {real} _dir The direction (see directions)
/// @returns {bool}
function is_cardinal_direction(_dir) {
	return (_dir >= directions.up && _dir <= directions.left);
}

/// @function get_random_instance(_obj_index, [_exact_index])
/// @description Picks a random existing instance of an object, or of one of its children unless _exact_index is set
/// @param {Asset.GMObject} _obj_index The object to pick an instance of
/// @param {bool} [_exact_index] Whether to skip instances of the object's children (false by default)
/// @returns {Id.Instance} The instance, or noone if there is none
function get_random_instance(_obj_index, _exact_index = false) {
	// Count the instances of the object and its children
	var _total_instances = instance_number(_obj_index);
	if (_total_instances == 0) { return noone; }
	
	// Pick a random starting point and check all possible instances
	var _start_pos =  irandom(_total_instances - 1);
	for (var _i = 0; _i < _total_instances; _i++) {
		var _random_instance = instance_find(_obj_index, ((_i+_start_pos) % _total_instances));
		if (_exact_index && _random_instance.object_index != _obj_index) { continue; }
		else { return _random_instance; }
	}
	
	// Return noone if no matching instance is found
	return noone;
}

/// @function get_random_chance_out_of(_denominator)
/// @description Rolls a one-in-_denominator chance
/// @param {real} _denominator The denominator of the one-in-x chance
/// @returns {bool} True on a hit, and always false for a denominator of 0
function get_random_chance_out_of(_denominator) {
	if (_denominator == 0) { return false; }
	
	return (irandom(_denominator-1) == 0);
}

/// @function get_chance_out_of(_denominator)
/// @description How likely get_random_chance_out_of is to come up true for the same denominator: one in _denominator,
///	or never for 0
/// @param {real} _denominator The denominator of the one-in-x chance
/// @returns {real} From 0 to 1
function get_chance_out_of(_denominator) {
	return (_denominator == 0) ? 0 : 1 / _denominator;
}

/// @function get_coin_flip()
/// @description Rolls a fifty-fifty chance
/// @returns {bool}
function get_coin_flip() {
	return (irandom(1) == 0);
}

/// @function get_quadrant_x_pos(_quadrant_number)
/// @description The x position of a quadrant of the calling instance's cell, 4 pixels left or right of its x, where
///	walls, lava and other tiles place and draw their four parts. Quadrants are numbered 0 (top left), 1 (top right),
///	2 (bottom left) and 3 (bottom right).
/// @param {real} _quadrant_number The quadrant, from 0 to 3
/// @returns {real}
function get_quadrant_x_pos(_quadrant_number) {
    if (_quadrant_number mod 2 == 0) { return x-4; }
	else { return x+4; }
}

/// @function get_quadrant_y_pos(_quadrant_number)
/// @description The y position of a quadrant of the calling instance's cell, 4 pixels above or below its y
/// @param {real} _quadrant_number The quadrant, from 0 to 3 (see get_quadrant_x_pos)
/// @returns {real}
function get_quadrant_y_pos(_quadrant_number) {
    if (_quadrant_number < 2) { return y-4; }
	else { return y+4; }
}

/// @function get_exit_x_pos(_dir)
/// @description The x position of the cardinal exit on one side of the room, which sits in the middle of that side
/// @param {real} _dir The exit's side (see directions)
/// @returns {real} The position, or -16 (outside the room) for stairs, respawn or none
function get_exit_x_pos(_dir) {
	switch (_dir) {
		case directions.up: { return room_width/2; }
		case directions.right: { return room_width-8; }
		case directions.down: { return room_width/2; }
		case directions.left: { return 8; }
		default: { return -16; }
	}
}

/// @function get_exit_y_pos(_dir)
/// @description The y position of the cardinal exit on one side of the room, which sits in the middle of that side
/// @param {real} _dir The exit's side (see directions)
/// @returns {real} The position, or -16 (outside the room) for stairs, respawn or none
function get_exit_y_pos(_dir) {
	switch (_dir) {
		case directions.up: { return 8; }
		case directions.right: { return room_height/2; }
		case directions.down: { return room_height-8; }
		case directions.left: { return room_height/2; }
		default: { return -16; }
	}
}

/// @function instance_place_all(_x_pos, _y_pos, _obj_type)
/// @description Every instance of an object that the calling instance would touch if it stood at a position, like
///	instance_place but finding all of them rather than one
/// @param {real} _x_pos The x position to check at
/// @param {real} _y_pos The y position to check at
/// @param {Asset.GMObject} _obj_type The object to look for (instances of its children count too)
/// @returns {array} The instances found, empty if there are none
function instance_place_all(_x_pos, _y_pos, _obj_type) {
	static _potential_matches = ds_list_create();
    ds_list_clear(_potential_matches);
	
    var _total_potential_matches = instance_place_list(_x_pos, _y_pos, _obj_type, _potential_matches, false), _list_of_matches = array_create(_total_potential_matches);
    for (var _i = 0; _i < _total_potential_matches; _i++) { _list_of_matches[_i] = _potential_matches[| _i]; }
    return _list_of_matches;
}

/// @function play_sound(_snd, _loud_sound)
/// @description Queues a sound for the game manager to play. A loud sound also draws the ears enemies: each other ears
///	that isn't already at or heading to the calling instance's position, or at or heading to meat, wakes up and heads
///	there. If it finds a path, it plays its own sound (not a loud one) and moves at once if it hasn't moved yet.
/// @param {Asset.GMSound} _snd The sound to play
/// @param {bool} _loud_sound Whether ears enemies hear it
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

/// @function instance_create(_x_pos, _y_pos, _obj_index)
/// @description Creates an instance at depth 0 (a shorthand for instance_create_depth)
/// @param {real} _x_pos The x position to create it at
/// @param {real} _y_pos The y position to create it at
/// @param {Asset.GMObject} _obj_index The object to create an instance of
/// @returns {Id.Instance} The new instance
function instance_create(_x_pos, _y_pos, _obj_index) {
	return instance_create_depth(_x_pos, _y_pos, 0, _obj_index);
}

/// @function is_existing_instance(_inst)
/// @description Whether an instance reference is set (not noone) and the instance still exists
/// @param {Id.Instance} _inst The instance, or noone
/// @returns {bool}
function is_existing_instance(_inst) {
	return (_inst != noone && instance_exists(_inst));
}

/// @function get_shader_color_from_gms_color(_given_color)
/// @description Converts a GameMaker color into the form a shader uniform takes, with each channel from 0 to 1
/// @param {real} _given_color The GameMaker color
/// @returns {array} [red, green, blue, alpha], with alpha always 1
function get_shader_color_from_gms_color(_given_color) {
	var _red = color_get_red(_given_color);
	var _green = color_get_green(_given_color);
	var _blue = color_get_blue(_given_color);
	
	return [_red/255.0, _green/255.0, _blue/255.0, 1.0];
}

/// @function calculate_gms_game_color()
/// @description Converts the game color setting (global.game_color_string, a hex string in RRGGBB order) into a
///	GameMaker color, first adding any leading zeros it is missing
/// @returns {real}
function calculate_gms_game_color() {
	var _padded_game_color_string = global.game_color_string;
	while (string_length(_padded_game_color_string) < 6) { _padded_game_color_string = "0"+_padded_game_color_string; }
	return get_gms_color_from_hex_string(_padded_game_color_string);
}

/// @function get_game_bg_color()
/// @description The background color: black during a game, turning to the game color as time runs out (slowly at
///	first, then quickly near the end), and the game color itself when no game is in progress
/// @returns {real}
function get_game_bg_color() {
	var _controller = global.controller;
	var _tint_amount = is_existing_instance(_controller) ? power(1-(_controller.time_remaining/_controller.time_provided), 8) : 1;
	return merge_color(c_black, global.gms_game_color, _tint_amount);
}

/// @function get_inverted_game_color()
/// @description The reverse of get_game_bg_color, for text drawn over the background: the game color during a game,
///	turning to black as time runs out, and the game color itself when no game is in progress
/// @returns {real}
function get_inverted_game_color() {
	var _controller = global.controller;
	var _tint_amount = is_existing_instance(_controller) ? power(1-(_controller.time_remaining/_controller.time_provided), 8) : 0;
	return merge_color(global.gms_game_color, c_black, _tint_amount);
}

/// @function get_gms_color_from_hex_string(_hex_string)
/// @description Converts a six-digit hex color string in RRGGBB order, such as "FF8000", into a GameMaker color
/// @param {string} _hex_string The hex string
/// @returns {real}
function get_gms_color_from_hex_string(_hex_string) {
	var _red = get_decimal_from_hex_string(string_copy(_hex_string, 1, 2));
	var _green = get_decimal_from_hex_string(string_copy(_hex_string, 3, 2));
	var _blue = get_decimal_from_hex_string(string_copy(_hex_string, 5, 2));
	
	return make_color_rgb(_red, _green, _blue);
}

/// @function get_decimal_from_hex_string(_hex_string)
/// @description Converts a hex string, in either case, into a number. Characters that aren't hex digits count as 0.
/// @param {string} _hex_string The hex string
/// @returns {real}
function get_decimal_from_hex_string(_hex_string) {
	var _result = 0;
	var _ZERO = ord("0");
	var _NINE = ord("9");
	var _A = ord("A");
	var _F = ord("F");
 
	for (var _i = 1; _i <= string_length(_hex_string); _i++) {
	    var _c = ord(string_char_at(string_upper(_hex_string), _i));
	    // Shift the total up one hex digit (the same as multiplying by 16)
	    var _result = _result << 4;
	    // Add the value of the digit if it is 0-9 or A-F (any other character adds nothing)
	    if (_c >= _ZERO && _c <= _NINE) {
	        _result = _result + (_c - _ZERO);
	    } else if (_c >= _A && _c <= _F ) {
	        _result = _result + (_c - _A + 10);
	    } 
	}
 
	return _result;
}

/// @function modulo(_a, _b)
/// @description A modulo that never comes out negative, unlike mod, so values wrap around: modulo(-1, 4) is 3
/// @param {real} _a The number to divide
/// @param {real} _b The number to divide by
/// @returns {real} From 0 up to (but not including) the absolute value of _b
function modulo(_a, _b) {
	var _Q = (_b < 0) ? ceil(_a/_b) : floor(_a/_b);
	return _a - (_Q * _b)
}

/// @function count_bits(_bitmask)
/// @description How many bits are set in a bitmask
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

/// @function mp_path_grid_add(_grid)
/// @description Marks the calling instance's sprite area, centered on its position, as blocked in a path grid
/// @param {Id.MpGrid} _grid The path grid
function mp_path_grid_add(_grid) {
	mp_grid_add_rectangle(_grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2 + 1, y + sprite_height/2 + 1);
}

/// @function mp_path_grid_remove(_grid)
/// @description Marks the calling instance's sprite area, centered on its position, as open again in a path grid
/// @param {Id.MpGrid} _grid The path grid
function mp_path_grid_remove(_grid) {
	mp_grid_clear_rectangle(_grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2 + 1, y + sprite_height/2 + 1);
}

/// @function destroy_instances_at_position()
/// @description Destroys every game object and placeholder that overlaps the calling instance, other than itself
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

/// @function hex_to_dec(_hex)
/// @description Converts a hex string of the digits 0-9 and A-F (capitals only) into a number, as the title screen does
///	for each digit of the game color
/// @param {string} _hex The hex string
/// @returns {real}
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

/// @function get_debug_message_level_string(_debug_message_level)
/// @description The label a debug message level is written with
/// @param {real} _debug_message_level The level (see debug_message_level)
/// @returns {string} "Log", "Eval", "WARNING" or "ERROR", or an empty string for an unknown level
function get_debug_message_level_string(_debug_message_level) {
	switch (_debug_message_level) {
		case debug_message_level.eval: { return "Eval"; }
		case debug_message_level.log: { return "Log"; }
		case debug_message_level.warning: { return "WARNING"; }
		case debug_message_level.error: { return "ERROR"; }
		default: { return ""; }
	}
}

/// @function write_debug_message(_msg, [_debug_level])
/// @description Writes a message, labeled with its level, to the game log (see update_log) and the debug output. An
///	error also shows an error box and ends the game.
/// @param {string} _msg The message to write
/// @param {real} [_debug_level] The level to file it under (see debug_message_level), log by default
function write_debug_message(_msg, _debug_level = debug_message_level.log) {
	var _debug_message_level_string = get_debug_message_level_string(_debug_level);
	update_log(_debug_message_level_string, _msg);
	show_debug_message(_debug_message_level_string + ": " + _msg);
	if (_debug_level == debug_message_level.error) { show_error(_msg, true); }
}