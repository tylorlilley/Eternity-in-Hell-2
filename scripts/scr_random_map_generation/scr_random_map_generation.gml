/// @function										obj_controller_can_reach_all_rooms(list_of_unlocked_exits);
/// @param		{index} list_of_unlocked_exits		The list of all the unlocked exits generated so far
function obj_controller_can_reach_all_rooms(list_of_unlocked_exits) {
	// walk the map once with original list of unlocked exits to get list values of current state of map
	var array_of_returned_lists;
	with current_room {
	   array_of_returned_lists = obj_controller_walk_the_map(0, list_of_unlocked_exits, ds_list_create(), ds_list_create(), ds_list_create());
	}
	var list_of_visited_rooms = array_of_returned_lists[0];
	var list_of_unlockable_exits = array_of_returned_lists[1];
	var list_of_available_rooms_with_keys = array_of_returned_lists[2];
	ds_list_shuffle(list_of_unlockable_exits);

	var original_list_of_unlocked_exits = ds_list_create();
	ds_list_copy(original_list_of_unlocked_exits, list_of_unlocked_exits);

	// Set up values we care about based on the returned lists
	var remaining_keys = ds_list_size(list_of_available_rooms_with_keys) - ds_list_size(list_of_unlocked_exits);
	var number_of_existing_rooms = instance_number(obj_room);
	var visited_all_rooms = (ds_list_size(list_of_visited_rooms) == number_of_existing_rooms);

	if (!visited_all_rooms && remaining_keys > 0 && ds_list_size(list_of_unlockable_exits) > 0) {
	    // for each unlockable exit, try unlocking just it and then checking if the whole map is accesible.
	    // If the whole map is not accessible after unlocking any one of the possible exits first, the map is a failure.
	    // Otherwise, it is a success
	    if (remaining_keys >= ds_list_size(list_of_unlockable_exits)) {
	        ds_list_combine(list_of_unlocked_exits, list_of_unlockable_exits);
	        visited_all_rooms = obj_controller_can_reach_all_rooms(list_of_unlocked_exits);
	    }
	    else {
	        for (var i = 0; i < ds_list_size(list_of_unlockable_exits); i++) {
	            ds_list_copy(list_of_unlocked_exits, original_list_of_unlocked_exits);
	            var newly_unlocked_exit = ds_list_find_value(list_of_unlockable_exits, i);
	            ds_list_add(list_of_unlocked_exits, newly_unlocked_exit);
	            if !obj_controller_can_reach_all_rooms(list_of_unlocked_exits) { visited_all_rooms = false; break; }
	        }
	    }
	}

	ds_list_destroy(original_list_of_unlocked_exits);
	ds_list_destroy(list_of_available_rooms_with_keys);
	ds_list_destroy(list_of_unlockable_exits);
	ds_list_destroy(list_of_visited_rooms);

    
	return visited_all_rooms;
}

/// @function													obj_controller_walk_the_map(iteration, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
/// @param		{integer}	iteration							The number of times this method has been recursively called previously on this walk
/// @param		{index}		list_of_unlocked_exits				The list of every unlocked exit reached so far on this walk
/// @param		{index}		list_of_visited_rooms				The list of every room visited so far on this walk
/// @param		{index}		list_of_unlockable_exits			The list of every locked exit reached so far on this walk
/// @param		{index}		list_of_available_rooms_with_keys	The list of every room with a key visited so far on this walk

function obj_controller_walk_the_map(iteration, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys) {

	//if iteration > global.controller.MAX_MAP_DRAW_DISTANCE { return false; } // This is used for testing to short circuit out of the recursion after a certain number of iterations
	//if (iteration < distance_to_current_room) { distance_to_current_room = iteration; }
	//visited = true; // NOT NECESSARY

	// Add this room to list of visited rooms
	if (!ds_list_contains(list_of_visited_rooms, id)) { ds_list_add(list_of_visited_rooms, id); }

	// Add this room to list of available rooms with keys if it has one
	if (has_key && !ds_list_contains(list_of_available_rooms_with_keys, id)) { ds_list_add(list_of_available_rooms_with_keys, id); }

	// Add current room to list of visited rooms, then create a list that's a copy of that list.
	var original_visited_rooms = ds_list_create();
	ds_list_copy(original_visited_rooms, list_of_visited_rooms);

	// Walk from here to each adjacent room, and return if that walk was successful for every room before taking another direction
	for (var i = 0; i <= 4; i++) {
	    // Reset the list of visited rooms to the original set passed in for this room
	    var next_list_of_visited_rooms = ds_list_create();
	    ds_list_copy(next_list_of_visited_rooms, original_visited_rooms);
    
	    // If the exit in this direction is locked (and hasn't been unlocked yet), add it to list of locked exits
	    if (locked_exits[i] && !ds_list_contains(list_of_unlocked_exits, locked_exits[i])) {
	        if (!ds_list_contains(list_of_unlockable_exits, locked_exits[i])) { ds_list_add(list_of_unlockable_exits, locked_exits[i]); }
	    }
	    // Otherwise, walk the adjoining room in this direction if one exists and it hasn't yet been walked
	    else if (!ds_list_contains(list_of_visited_rooms, adj_rooms[i])) {
	        with adj_rooms[i] { 
	            var array_of_returned_lists = obj_controller_walk_the_map(iteration+1, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
	            ds_list_combine(list_of_visited_rooms, array_of_returned_lists[0]); 
	            ds_list_combine(list_of_unlockable_exits, array_of_returned_lists[1]); 
	            ds_list_combine(list_of_available_rooms_with_keys, array_of_returned_lists[2]); 
	        }
	    }
	    ds_list_destroy(next_list_of_visited_rooms);
	}
	ds_list_destroy(original_visited_rooms);

	// return true only if the walk in each direction was successful
	return array(list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
}

