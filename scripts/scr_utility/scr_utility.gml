/// @function								get_dir_x_offset(dir);
/// @param		{dir} dir					The direction to get the x_offset for
function get_dir_x_offset(dir) {
	if (dir == directions.right) { return 1; }
	else if (dir == directions.left) { return -1; }
	return 0;
}

/// @function								get_dir_y_offset(dir);
/// @param		{dir} dir					The direction to get the y_offset for
function get_dir_y_offset(dir) {
	if (dir == directions.down) { return 1; }
	else if (dir == directions.up) { return -1; }
	return 0;
}
	
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
	if (dir = directions.stairs) { return directions.stairs; }
	if (dir = directions.respawn) { return directions.respawn; }
	if (dir = directions.none) { return directions.none; }
	
	return modulo((dir+2), 4);
}

/// @function								get_turn_right_dir(dir);
/// @param		{direction}	dir				The direction to return the direction to the right of
function get_turn_right_dir(dir) {
	if (dir < directions.up || dir > directions.left) { return -1; }
	else { return modulo((dir+1), 4); }
}

/// @function								get_turn_left_dir(dir);
/// @param		{direction}	dir				The direction to return the direction to the left of
function get_turn_left_dir(dir) {
	if (dir < directions.up || dir > directions.left) { return -1; }
	else { return modulo((dir-1), 4); }
}

/// @function								get_random_carindal_dir();
function get_random_carindal_dir() {
	return irandom(3);
}

/// @function								is_cardinal_direction();
/// @param		{direction}	dir				The direction to return the cardinality of
function is_cardinal_direction(dir) {
	return (dir >= directions.up && dir <= directions.left);
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
    if (quadrant_number mod 2 == 0) { return x-4; }
	else { return x+4; }
}

/// @function								get_quadrant_y_pos(quadrant_number);
/// @param		{real}	quadrant_number		The number of the quadrant to get the x position for
function get_quadrant_y_pos(quadrant_number) {
    if (quadrant_number < 2) { return y-4; }
	else { return y+4; }
}

/// @function								get_exit_x_pos(dir);
/// @param		{dir}	dir					The direction of the exit to get the x pos for
function get_exit_x_pos(dir) {
	switch (dir) {
		case directions.up: { return room_width/2; }
		case directions.right: { return room_width-8; }
		case directions.down: { return room_width/2; }
		case directions.left: { return 8; }
		default: { return -16; }
	}
}

/// @function								get_exit_y_pos(dir);
/// @param		{dir}	dir					The direction of the exit to get the x pos for
function get_exit_y_pos(dir) {
	switch (dir) {
		case directions.up: { return 8; }
		case directions.right: { return room_width/2; }
		case directions.down: { return room_width-8; }
		case directions.left: { return room_width/2; }
		default: { return -16; }
	}
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

/// @function								play_sound();
///	@param		{Sound}	  snd				The sound to play
///	@param		{Boolean} loud_soun			Whether the sound is heard by ears or not
function play_sound(snd, loud_sound) {
	array_push(global.game_manager.sounds_to_play, snd);
	if (loud_sound) {
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
							play_sound(snd_ears, true);
							if (!moved) { move_ears(); }
						}
				}
			}
		}
	}
}

/// @function								instance_create(x_pos, y_pos, obj_index);
///	@param		{real} x_pos				The x_pos to create the instance at
///	@param		{real} y_pos				The y_pos to create the instance at
///	@param		{object_index} obj_index	The object_index to create an instance of
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

/// @function								get_game_color();
function get_game_color() {
	var padded_game_color_string = global.game_color_string;
	while (string_length(padded_game_color_string) < 6) { padded_game_color_string = "0"+padded_game_color_string; }
	return get_gms_color_from_hex_string(padded_game_color_string);
}

/// @function								get_game_bg_color();
function get_game_bg_color() {
	var controller = global.controller, tint_amount = power(1-(controller.time_remaining/controller.time_provided), 8);
	return merge_color(c_black, get_game_color(), tint_amount);
}

/// @function								get_inverted_game_bg_color();
function get_inverted_game_bg_color() {
	var controller = global.controller, tint_amount = power(1-(controller.time_remaining/controller.time_provided), 8);
	return merge_color(get_game_color(), c_black, tint_amount);
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

/// @function								modulo(a, b);
///	@param		{number} a					The number to perform the mod on
///	@param		{number} b					The number to perform the mod with
function modulo(a, b) {
	var Q = (b < 0) ? ceil(a/b) : floor(a/b);
	return a - (Q * b)
}

/// @function								mp_path_grid_add(grid);
///	@param		{id} grid					The mp_grid to add to
function mp_path_grid_add(grid) {
	mp_grid_add_rectangle(grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2 + 1, y + sprite_height/2 + 1);
}

/// @function								mp_path_grid_remove(grid);
///	@param		{id} grid					The mp_grid to remove from
function mp_path_grid_remove(grid) {
	mp_grid_clear_rectangle(grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2 + 1, y + sprite_height/2 + 1);
}

/// @function								mp_grid_add(grid);
///	@param		{id} grid					The mp_grid to add to
function mp_grid_add(grid) {
	mp_grid_add_rectangle(grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2, y + sprite_height/2 );
}

/// @function								mp_grid_remove(grid);
///	@param		{id} grid					The mp_grid to remove from
function mp_grid_remove(grid) {
	mp_grid_clear_rectangle(grid, x - sprite_width/2, y - sprite_height/2, x + sprite_width/2, y + sprite_height/2);
}

/// @function								destroy_instances_at_position();
function destroy_instances_at_position() {
	var game_objects = instance_place_all(x, y, obj_game_object);
	while (array_length(game_objects) > 0) {
		var game_object = array_pop(game_objects);
		if (is_existing_instance(game_object) && game_object.id != id) { instance_destroy(game_object); }
	}
	var placeholders = instance_place_all(x, y, obj_placeholder);
	while (array_length(placeholders) > 0) {
		var placeholder = array_pop(placeholders);
		if (is_existing_instance(placeholder) && placeholder.id != id) { instance_destroy(placeholder); }
	}
}

/*
function are_coordinates_within_instance(x_pos, y_pos, inst) {
	var nearest_inst = instance_nearest(x_pos, y_pos, inst);
	if (!is_existing_instance(nearest_inst)) { return noone; }
	
	return (x_pos > nearest_inst.x - nearest_inst.sprite_width / 2 && 
			x_pos < nearest_inst.x + nearest_inst.sprite_width / 2 &&
			y_pos > nearest_inst.y - nearest_inst.sprite_height / 2 && 
			y_pos < nearest_inst.y + nearest_inst.sprite_height / 2) ? nearest_inst : noone;
}
*/