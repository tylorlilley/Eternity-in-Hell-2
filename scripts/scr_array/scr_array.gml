/// @function								array_random_get(list);
/// @param		{index} list				The array to retrieve a random element from
function array_random_get(list) {
	if (array_length(list) == 0) { return noone; }
	else { return list[irandom(array_length(list)-1)]; }
}

/// @function								array_random_pop(list);
/// @param		{index} list				The array from which to pop a random value
function array_random_pop(_list) {
	var _list_length = array_length(_list);
	if (_list_length < 1) { return noone; }
	
	var _random_index = irandom(_list_length - 1), _return_value = _list[_random_index];
	array_delete(_list, _random_index, 1);
	return _return_value;
}

/// @function								array_duplicate(list, source_id);
/// @param		{index}	list				Array to add the values to
/// @param		{index}	source_list			Array to take the values being added from
function array_duplicate(list, source_list) {
	// This replaces the first array with a copy of the second array.
	array_resize(list, 0)
	array_copy(list, 0, source_list, 0, array_length(source_list));
}

/// @function									array_shift(list);
/// @param		{index}		list				List to remove and return the first value from
function array_shift(_list)
{
    if (array_length(_list) <= 0) return undefined;

    var _first = _list[0];
    array_delete(_list, 0, 1);
    return _first;
}

/// @function									array_remove_first(list, value_to_find);
/// @param		{index}		list				List to remove the value from
/// @param		{value}		value_to_remove		Value to remove from the array
function array_remove_first(list, value_to_remove) {
	var list_pos = array_get_index(list, value_to_remove);
	if (list_pos != -1) { array_delete(list, list_pos, 1); }
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
