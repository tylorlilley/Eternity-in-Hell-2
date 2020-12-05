/// @description  get_scaling_amount(minimum, maximum, numerator, denominator)
function get_scaling_amount(argument0, argument1, argument2, argument3) {
	var minimum = argument0, maximum = argument1, numerator = argument2, denominator = argument3;

	var fraction = numerator/denominator;
	var variable_portion = maximum - minimum;
	return (minimum+(variable_portion*(fraction)));



}
