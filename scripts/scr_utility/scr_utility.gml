/// @function								get_scaling_amount(minimum, maximum, numerator, denominator);
/// @param		{real}	minimum				The minimum value the scaling amount can be
/// @param		{real}	maximum				The maximum value the scaling amount can be
/// @param		{real}	numerator			The numerator of the scaling amount to be added to the minimum
/// @param		{real}	denominator			The denominator of the scaling amount to be added to the minimum
function get_scaling_amount(minimum, maximum, numerator, denominator) {
	var fraction = numerator/denominator;
	var variable_portion = maximum - minimum;
	
	return (minimum+(variable_portion*(fraction)));
}

/// @function								get_zero_padded_string(value_to_pad, target_length);
/// @param		{real} value_to_pad			The value to pad with zeros
/// @param		{real} target_legnth		The desired length of the padded string
function get_zero_padded_string(value_to_pad, target_length) {
	var padded_value = string(value_to_pad)
	
	while (string_length(padded_value) < target_length) {
	    padded_value = "0"+padded_value;
	}
	
	return padded_value;
}

/// @function								get_percentage_string(value_to_pad, target_length);
/// @param		{real} value				The value to transform into a percentage string
function get_percentage_string(value) {
	var percentage_string = "", percentage_value = floor(value), percentage_remainder = floor(frac(value) * 100);
	
	//if (percentage_value < 10) { percentage_string = "0"; }
	percentage_string += string(percentage_value);
	percentage_string += ".";
	if (percentage_remainder < 10) { percentage_string += "0"; }
	percentage_string += string(percentage_remainder);
	percentage_string += " %";
	
	return percentage_string;
}

/// @function								get_opposite_dir(dir);
/// @param		{direction}	dir				The direction to return the opposite of
function get_opposite_dir(dir) {
	if (dir < 0 || dir > 3) { return -1; }
	else { return modulo((dir+2), 4); }
}

/// @function								get_turn_right_dir(dir);
/// @param		{direction}	dir				The direction to return the direction to the right of
function get_turn_right_dir(dir) {
	if (dir < 0 || dir > 3) { return -1; }
	else { return modulo((dir+1), 4); }
}

/// @function								get_turn_left_dir(dir);
/// @param		{direction}	dir				The direction to return the direction to the left of
function get_turn_left_dir(dir) {
	if (dir < 0 || dir > 3) { return -1; }
	else { return modulo((dir-1), 4); }
}

/// @function								get_random_instance(obj_index);
/// @param		{index} obj_index			The type of object to get a random existing instance of
function get_random_instance(obj_index) {
	// Gets a random instance of the given object index
	return instance_find(obj_index, irandom(instance_number(obj_index) - 1));
}

/// @function								get_random_chance_out_of(denominator);
/// @param		{real}	denominator			The value to use as the denomimnator for the one-in-x chance
function get_random_chance_out_of(denominator) {
	if (denominator == 0) { return false; }
	
	return (irandom(denominator-1) == 0);
}

/// @function								get_coin_flip();
function get_coin_flip() {
	return (irandom(1) == 0);
}

/// @function								get_quadrant_x_pos(quadrant_number);
/// @param		{real}	quadrant_number		The number of the quadrant to get the x position for
function get_quadrant_x_pos(quadrant_number) {
    if (modulo(quadrant_number, 2) == 0) { return x-4; }
	else { return x+4; }
}

/// @function								get_quadrant_y_pos(quadrant_number);
/// @param		{real}	quadrant_number		The number of the quadrant to get the x position for
function get_quadrant_y_pos(quadrant_number) {
    if (quadrant_number < 2) { return y-4; }
	else { return y+4; }
}

/// @function								instance_place_all(x_pos, y_pos, obj_type);
/// @param		{real}	x_pos				The x_pos to check for instances
/// @param		{real}	y_pos				The x_pos to check for instances
/// @param		{real}	obj_type			The object type of instance to check for
function instance_place_all(x_pos, y_pos, obj_type) {
    var calling_instance_id = id, list_of_matches = array_create(0);
	
    with (obj_type) {
        var potential_match_id = id;
        with (calling_instance_id) {
            var potential_match = instance_place(x_pos, y_pos, potential_match_id);
            if (is_existing_instance(potential_match)) { array_push(list_of_matches, potential_match); }
        }
    }
	
    return list_of_matches;
}

/// @function								get_new_id();
function get_new_id() {
    global.id_counter++;
    return global.id_counter;
}

/// @function								play_sound();
///	@param		{Sound}	  snd				The sound to play
///	@param		{Boolean} loud_soun			Whether the sound is heard by ears or not
function play_sound(snd, loud_sound) {
	array_push(global.sound_manager.sounds_to_play, snd);
	if (loud_sound) {
		with (obj_ears) {
			if id != other.id {
				if ((target_x != other.x || target_y != other.y) && !instance_place(target_x, target_y, obj_meat)) {
					target_x = other.x;
					target_y = other.y;
					awake = true;
					play_sound(snd_ears, true);
				}
			}
		}
	}
}

/// @function								initialize_shader_pointers();
function initialize_shader_pointers() {
	shader_color = shader_get_uniform(sh_eih, "new_color");
	shader_bg_color = shader_get_uniform(sh_eih, "bg_color");
	shader_color_fade = shader_get_uniform(sh_eih, "color_fade");
}

/// @function								set_eih_shader();
function set_eih_shader() {
	shader_set(sh_eih);
	shader_set_uniform_f_array(shader_color, global.game_color);
	shader_set_uniform_f_array(shader_bg_color, get_shader_color_from_gms_color(global.bg_color));
	shader_set_uniform_f(shader_color_fade, global.game_color_fade);
}

/// @function								instance_create(x_pos, y_pos, obj_index);
///	@param		{real} x_pos				The x_pos to create the instance at
///	@param		{real} y_pos				The y_pos to create the instance at
///	@param		{object_index} difficulty	The object_index to create an instance of
function instance_create(x_pos, y_pos, obj_index) {
	return instance_create_depth(x_pos, y_pos, 0, obj_index);
}

/// @function								is_existing_instance(x_pos, y_pos, obj_index);
///	@param		{id} insty					The instance to check existance for
function is_existing_instance(inst) {
	return (inst != noone && instance_exists(inst));
}

/// @function								get_shader_color_from_gms_color(given_color);
///	@param		{real} given_color			The gms color to convert to a shader color
function get_shader_color_from_gms_color(given_color) {
	var red = color_get_red(given_color);
	var green = color_get_green(given_color);
	var blue = color_get_blue(given_color);
	
	return [red/255.0, green/255.0, blue/255.0, 1.0];
}

/// @function								get_gms_color_from_hex_string(hex_string);
///	@param		{string} hex_string			The string to convert to a color
function get_gms_color_from_hex_string(hex_string) {
	var red = get_decimal_from_hex_string(string_copy(hex_string, 1, 2));
	var green = get_decimal_from_hex_string(string_copy(hex_string, 3, 2));
	var blue = get_decimal_from_hex_string(string_copy(hex_string, 5, 2));
	
	return make_color_rgb(red, green, blue);
}

/// @function								get_decimal_from_hex_string(hex_string);
///	@param		{string} hex_string			The string to convert to a decimal value
function get_decimal_from_hex_string(hex_string) {
	var result = 0;
	var ZERO = ord("0");
	var NINE = ord("9");
	var A = ord("A");
	var F = ord("F");
 
	for (var i = 1; i <= string_length(hex_string); i++) {
	    var c = ord(string_char_at(string_upper(hex_string), i));
	    // you could also multiply by 16 but you get more nerd points for bitshifts
	    var result = result << 4;
	    // if the character is a number or letter, add the value
	    // it represents to the total
	    if (c >= ZERO && c <= NINE) {
	        result = result + (c - ZERO);
	    } else if (c >= A && c <= F ) {
	        result = result + (c - A + 10);
	    } 
	}
 
	return result;
}

/// @function								reset_settings_to_defaults();
function reset_settings_to_defaults() {
	global.fullscreen = true;
	global.window_scaling = 2;
	global.input = inputs.keyboard_default;
	global.can_screen_flash = true;
	global.game_color_fade = 10;
	global.game_color_string = "FF0000";
	
	update_setting("fullscreen", global.fullscreen);
	update_setting("window_size", global.window_scaling);
	update_setting("input", global.input);
	update_setting("can_screen_flash", global.can_screen_flash );
	update_setting("game_color_fade", global.game_color_fade);
	update_setting("game_color", global.game_color_string);
	
	set_game_color();
}

/// @function								set_game_color();
function set_game_color() {
	var padded_game_color_string = global.game_color_string;
	while (string_length(padded_game_color_string) < 6) {
		padded_game_color_string = "0"+padded_game_color_string;
	}
	var new_color = get_gms_color_from_hex_string(padded_game_color_string);
	global.game_color = get_shader_color_from_gms_color(new_color);
}


/// @function								modulo(a, b);
///	@param		{number} a					The number to perform the mod on
///	@param		{number} b					The number to perform the mod with
function modulo(a, b) {
	var Q = (b < 0) ? ceil(a/b) : floor(a/b);
	return a - (Q * b)
}