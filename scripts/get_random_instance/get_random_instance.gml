/// @description  get_random_instance(obj_index)
function get_random_instance(argument0) {
	var obj_index = argument0;

	// Gets a random instance of the given object index
	return instance_find(obj_index, irandom(instance_number(obj_index) - 1));



}
