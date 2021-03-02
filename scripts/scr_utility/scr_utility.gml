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

/// @function								zero_padded_string(value_to_pad, target_length);
/// @param		{real} value_to_pad			The value to pad with zeros
/// @param		{real} target_legnth		The desired length of the padded string
function zero_padded_string(value_to_pad, target_length) {
	var padded_value = string(value_to_pad)
	
	while (string_length(padded_value) < target_length) {
	    padded_value = "0"+padded_value;
	}
	
	return padded_value;
}


/// @function								opposite_dir(dir);
/// @param		{direction}	dir				The direction to return the opposite of
function opposite_dir(dir) {
	if (dir < 0 || dir > 3) { return -1; }
	else { return (dir+2) mod 4; }
}

/// @function								dir_turn_right(dir);
/// @param		{direction}	dir				The direction to return the direction to the right of
function dir_turn_right(dir) {
	if (dir < 0 || dir > 3) { return -1; }
	else { return (dir+1) mod 4; }
}

/// @function								dir_turn_left(dir);
/// @param		{direction}	dir				The direction to return the direction to the left of
function dir_turn_left(dir) {
	if (dir < 0 || dir > 3) { return -1; }
	else { return (dir-1) mod 4; }
}

/// @function								array(...);
function array() {
	// Creates an array with the value of each argument given at the positions in the order given
	var arr;
	for (var i = argument_count-1; i >= 0; i -= 1) { arr[i] = argument[i]; }
	
	return arr;
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
	return (irandom(denominator-1) == 0);
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

/// @function								make_fullscreen();
/// @param		{boolean} is_fullscreen		Whether to ultiamtely set fullscreen to true or false
function set_fullscreen(is_fullscreen) {
	// Check if window has focus
	if (!window_has_focus()) {
		global.lostFocus = true;
		// Refocus
	} 
	else if (global.lostFocus) {
		global.lostFocus = false;
	
		// Fix windowed Gamemaker bug
		if (!global.windowed) {
			window_set_fullscreen(!is_fullscreen);
			window_set_fullscreen(is_fullscreen);
		}
	}
}