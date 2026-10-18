/// @function								array_random_get(_list);
/// @param		{index} _list				The array to retrieve a random element from
function array_random_get(_list) {
	if (array_length(_list) == 0) { return noone; }
	else { return _list[irandom(array_length(_list)-1)]; }
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

/// @function									array_remove_first(_list, value_to_find);
/// @param		{index}		_list				List to remove the value from
/// @param		{value}		_value_to_remove		Value to remove from the array
function array_remove_first(_list, _value_to_remove) {
	var _list_pos = array_get_index(_list, _value_to_remove);
	if (_list_pos != -1) { array_delete(_list, _list_pos, 1); }
	return _list_pos;
}

/// @function									array_count_occurrences(_list, _value_to_count);
/// @param		{index}		_list				List to check for the value in
/// @param		{value}		_value_to_count		Value to count ocurrances of in the array
function array_count_occurrences(_list, _value_to_count) {
	var _count = 0;
	for (var _i = 0; _i < array_length(_list); _i++) {
	    if (_list[_i] == _value_to_count) {_count += 1; }
	}
	
	 return _count;
}
