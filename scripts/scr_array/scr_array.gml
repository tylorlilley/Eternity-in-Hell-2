/// @function array_random_get(_list)
/// @description Picks a random element of an array, leaving the array as it is
/// @param {array} _list The array to pick from
/// @returns {any} The element, or noone if the array is empty
function array_random_get(_list) {
	if (array_length(_list) == 0) { return noone; }
	else { return _list[irandom(array_length(_list)-1)]; }
}

/// @function array_random_pop(_list)
/// @description Removes a random element from an array and returns it
/// @param {array} _list The array to take the element from
/// @returns {any} The removed element, or noone if the array is empty
function array_random_pop(_list) {
	var _list_length = array_length(_list);
	if (_list_length < 1) { return noone; }
	
	var _random_index = irandom(_list_length - 1), _return_value = _list[_random_index];
	array_delete(_list, _random_index, 1);
	return _return_value;
}

/// @function array_duplicate(_list, _source_list)
/// @description Replaces an array's contents, in place, with a copy of another array's values
/// @param {array} _list The array to fill, whose old values are discarded
/// @param {array} _source_list The array to copy the values from, which is left as it is
function array_duplicate(_list, _source_list) {
	// This replaces the first array with a copy of the second array
	array_resize(_list, 0)
	array_copy(_list, 0, _source_list, 0, array_length(_source_list));
}

/// @function array_shift(_list)
/// @description Removes the first element from an array and returns it
/// @param {array} _list The array to take the element from
/// @returns {any} The removed element, or undefined if the array is empty
function array_shift(_list)
{
    if (array_length(_list) <= 0) return undefined;

    var _first = _list[0];
    array_delete(_list, 0, 1);
    return _first;
}

/// @function array_remove_first(_list, _value_to_remove)
/// @description Removes the first occurrence of a value from an array, and does nothing if the array doesn't hold it
/// @param {array} _list The array to remove the value from
/// @param {any} _value_to_remove The value to remove
function array_remove_first(_list, _value_to_remove) {
	var _list_pos = array_get_index(_list, _value_to_remove);
	if (_list_pos != -1) { array_delete(_list, _list_pos, 1); }
}

/// @function array_count_occurrences(_list, _value_to_count)
/// @description Counts the elements of an array that equal a value
/// @param {array} _list The array to search
/// @param {any} _value_to_count The value to count
/// @returns {real} How many elements equal the value (0 if none do)
function array_count_occurrences(_list, _value_to_count) {
	var _count = 0;
	for (var _i = 0; _i < array_length(_list); _i++) {
	    if (_list[_i] == _value_to_count) {_count += 1; }
	}
	
	 return _count;
}
