/// @description  ds_list_combine(list_id, source_id)
function ds_list_combine(argument0, argument1) {
	var list_id = argument0, source_id = argument1;

	// This takes each value from the second list, and if it is not already present 
	// in the first list, adds it to the first list.
	for (var i = 0; i < ds_list_size(source_id); i++) {
	    var value_in_source_at_pos = ds_list_find_value(source_id, i);
    
	    if (!ds_list_contains(list_id, value_in_source_at_pos)) {
	        ds_list_add(list_id, value_in_source_at_pos);
	    }
	}



}
