/// @description  zero_padded_string(value_to_pad, target_length)
function zero_padded_string(argument0, argument1) {
	var value_to_pad = argument0, target_length = argument1;

	var padded_value = string(argument0)
	while (string_length(padded_value) < target_length) {
	    padded_value = "0"+padded_value;
	}
	return padded_value;



}
