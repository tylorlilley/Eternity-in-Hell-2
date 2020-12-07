/// @function								ds_list_pop_random_value(list_id);
/// @param		{index} list_id				The list from which to pop a random value
function ds_list_pop_random_value(list_id) {
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

/// @function								ds_list_combine(list_id, source_id);
/// @param		{index}	list_id				List to add the values to
/// @param		{index}	source_id			List to take the values being added from
function ds_list_combine(list_id, source_id) {
	// This takes each value from the second list, and if it is not already present 
	// in the first list, adds it to the first list.
	for (var i = 0; i < ds_list_size(source_id); i++) {
	    var value_in_source_at_pos = ds_list_find_value(source_id, i);
    
	    if (!ds_list_contains(list_id, value_in_source_at_pos)) {
	        ds_list_add(list_id, value_in_source_at_pos);
	    }
	}
}

/// @function								ds_list_contains(list_id, value_to_find);
/// @param		{index}		list_id			List to check for the value in
/// @param		{value}		source_id		Value to check to see if the list contains
function ds_list_contains(list_id, value_to_find) {
	// This returns whether the list contains a given value
	return (ds_list_find_index(list_id, value_to_find) != -1)
}

