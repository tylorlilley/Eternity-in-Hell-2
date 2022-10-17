/// @function								array_shuffle(list);
/// @param		{index} list				The array to shuffle
function array_shuffle(list) {
	// This takes a random value from this array by shuffling it and deletes that value
	// from the array and returns it, as long as the array has at least one value

	for(var i = 0; i < array_length(list); i += 1) {
	    var j = irandom_range(i,(array_length(list)-1));
	    var temp = list[i];
	    list[i] = list[j];
	    list[j] = temp;
	}
}

/// @function									array_find_index(list, value_to_find);
/// @param		{index}		list				Array to check for the value in
/// @param		{value}		value_to_find		Value to check to see if the array contains
function array_find_index(list, value_to_find) {
	// This returns whether the index of the item in the list
	for(var i = 0; i < array_length(list); i += 1) {
	    if (list[i] == value_to_find) { return list[i]; }
	}
	
	return noone;
}

/// @function								array_pop_random(list);
/// @param		{index} list				The array from which to pop a random value
function array_random_pop(list) {
	// This takes a random value from this array by shuffling it and deletes that value
	// from the array and returns it, as long as the array has at least one value
	array_shuffle(list);
	return array_pop(list);
}

/// @function								array_combine(list, source_id);
/// @param		{index}	list				Array to add the values to
/// @param		{index}	source_list			Array to take the values being added from
function array_combine(list, source_list) {
	// This takes each value from the second array, and if it is not already present 
	// in the first array, adds it to the first array.
	for (var i = 0; i < array_length(source_list); i++) {
	    var value_in_source_at_pos = source_list[i];
    
	    if (!array_contains(list, value_in_source_at_pos)) {
	        array_push(list, value_in_source_at_pos);
	    }
	}
}

/// @function								array_copy(list, source_id);
/// @param		{index}	list				Array to add the values to
/// @param		{index}	source_list			Array to take the values being added from
function array_full_copy(list, source_list) {
	// This replaces the first array with a copy of the second array.
	list = array_create(0);
	array_copy(list, 0, source_list, 0, array_length(source_list));
}

/// @function								array_contains(list, value_to_find);
/// @param		{index}		list			List to check for the value in
/// @param		{value}		value_to_find	Value to check to see if the list contains
function array_contains(list, value_to_find) {
	// This returns whether the list contains a given value
	return (array_find_index(list, value_to_find) != noone);
}

