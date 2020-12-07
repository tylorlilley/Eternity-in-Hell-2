/// @function								get_scaling_amount(minimum, maximum, numerator, denominator);
/// @param		{integer}	minimum			The minimum value the scaling amount can be
/// @param		{integer}	maximum			The maximum value the scaling amount can be
/// @param		{integer}	numerator		The numerator of the scaling amount to be added to the minimum
/// @param		{integer}	denominator		The denominator of the scaling amount to be added to the minimum
function get_scaling_amount(minimum, maximum, numerator, denominator) {
	var fraction = numerator/denominator;
	var variable_portion = maximum - minimum;
	
	return (minimum+(variable_portion*(fraction)));
}

/// @function								zero_padded_string(value_to_pad, target_length);
/// @param		{integer} value_to_pad		The value to pad with zeros
/// @param		{integer} target_legnth		The desired length of the padded string
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
