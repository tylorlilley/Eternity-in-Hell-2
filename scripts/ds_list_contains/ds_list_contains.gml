/// @description  ds_list_contains(list_id, value_to_find)
function ds_list_contains(argument0, argument1) {
	var list_id = argument0, value_to_find = argument1;

	// This returns whether the list contains a given value
	return (ds_list_find_index(list_id, value_to_find) != -1)



}
