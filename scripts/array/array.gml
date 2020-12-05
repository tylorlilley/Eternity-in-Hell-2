/// @description  array(...)
function array() {
	// Creates an array with the value of each argument given at the positions in 
	// the order given

	var arr;
	for (var i = argument_count-1; i >= 0; i -= 1) { arr[i] = argument[i]; }
	return arr;



}
