/// @description  ds_list_pop_random_value(list_id)
function ds_list_pop_random_value(argument0) {
	var list_id = argument0;

	// This takes a random value from this list by shuffling it and deletes that value
	// from the list and returns it, as long as the list has at least one value
	var value_to_return = noone

	if (ds_list_size(list_id) > 0) {
	    ds_list_shuffle(list_id);
	    value_to_return = ds_list_find_value(list_id, 0);
	    ds_list_delete(list_id, 0);
	}

	return value_to_return;



}
