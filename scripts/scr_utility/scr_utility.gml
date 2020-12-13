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