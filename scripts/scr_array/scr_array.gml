/// @function								array_random_get(list);
/// @param		{index} list				The array to retrieve a random element from
function array_random_get(list) {
	if (array_length(list) == 0) { return noone; }
	else { return list[irandom(array_length(list)-1)]; }
}

/// @function								array_random_pop(list);
/// @param		{index} list				The array from which to pop a random value
function array_random_pop(list) {
	var popped_value = noone;
	if (array_length(list) > 0) {
		var pos = irandom(array_length(list)-1);
		popped_value = list[pos];
		array_delete(list, pos, 1);
	}
	return popped_value;
}

/// @function								array_duplicate(list, source_id);
/// @param		{index}	list				Array to add the values to
/// @param		{index}	source_list			Array to take the values being added from
function array_duplicate(list, source_list) {
	// This replaces the first array with a copy of the second array.
	array_copy(list, 0, source_list, 0, array_length(source_list));
}

/// @function									array_remove(list, value_to_find);
/// @param		{index}		list				List to remove the value from
/// @param		{value}		value_to_remove		Value to remove from the array
function array_remove(list, value_to_remove) {
	var list_pos = array_get_index(list, value_to_remove);
	while(list_pos != -1) {
		array_delete(list, list_pos, 1);
		list_pos = array_get_index(list, value_to_remove);
	}
}

/// @function									array_count_occurances(list, value_to_count);
/// @param		{index}		list				List to check for the value in
/// @param		{value}		value_to_count		Value to count ocurrances of in the array
function array_count_occurances(list, value_to_count) {
	var count = 0;
	for (var i = 0; i < array_length(list); i++) {
	    if (list[i] == value_to_count) {count += 1; }
	}
	
	 return count;
}
