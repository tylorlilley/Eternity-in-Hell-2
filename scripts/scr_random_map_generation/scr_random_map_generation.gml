///// @function										obj_controller_can_reach_all_rooms(list_of_unlocked_exits);
///// @param		{index} list_of_unlocked_exits		The list of all the unlocked exits generated so far
//function can_reach_all_rooms_old(list_of_unlocked_exits) {
//	// walk the map once with original list of unlocked exits to get list values of current state of map
//	var array_of_returned_lists;
//	var list_of_visited_rooms = ds_list_create(), list_of_unlockable_exits = ds_list_create(), list_of_available_rooms_with_keys = ds_list_create();
//	with current_room {
//	   array_of_returned_lists = walk_the_map(0, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
//	}
//	ds_list_shuffle(list_of_unlockable_exits);

//	var original_list_of_unlocked_exits = ds_list_create();
//	ds_list_copy(original_list_of_unlocked_exits, list_of_unlocked_exits);

//	// Set up values we care about based on the returned lists
//	var remaining_keys = ds_list_size(list_of_available_rooms_with_keys) - ds_list_size(list_of_unlocked_exits);
//	var number_of_existing_rooms = instance_number(obj_room);
//	var visited_all_rooms = (ds_list_size(list_of_visited_rooms) == number_of_existing_rooms);

//	if (!visited_all_rooms && remaining_keys > 0 && ds_list_size(list_of_unlockable_exits) > 0) {
//	    // for each unlockable exit, try unlocking just it and then checking if the whole map is accesible.
//	    // If the whole map is not accessible after unlocking any one of the possible exits first, the map is a failure.
//	    // Otherwise, it is a success
//	    if (remaining_keys >= ds_list_size(list_of_unlockable_exits)) {
//	        ds_list_combine(list_of_unlocked_exits, list_of_unlockable_exits);
//	        visited_all_rooms = can_reach_all_rooms(list_of_unlocked_exits);
//	    }
//	    else {
//			visited_all_rooms = true;
//	        for (var i = 0; i < ds_list_size(list_of_unlockable_exits); i+= 1;) {
//	            ds_list_copy(list_of_unlocked_exits, original_list_of_unlocked_exits);
//	            ds_list_add(list_of_unlocked_exits, ds_list_find_value(list_of_unlockable_exits, i));
//	            if !can_reach_all_rooms(list_of_unlocked_exits) { visited_all_rooms = false; break; }
//	        }
//	    }
//	}

//	ds_list_destroy(original_list_of_unlocked_exits);
//	ds_list_destroy(list_of_available_rooms_with_keys);
//	ds_list_destroy(list_of_unlockable_exits);
//	ds_list_destroy(list_of_visited_rooms);

//	return visited_all_rooms;
//}

///// @function													obj_controller_walk_the_map(iteration, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
///// @param		{integer}	iteration							The number of times this method has been recursively called previously on this walk
///// @param		{index}		list_of_unlocked_exits				The list of every unlocked exit reached so far on this walk
///// @param		{index}		list_of_visited_rooms				The list of every room visited so far on this walk
///// @param		{index}		list_of_unlockable_exits			The list of every locked exit reached so far on this walk
///// @param		{index}		list_of_available_rooms_with_keys	The list of every room with a key visited so far on this walk

//function walk_the_map_old(iteration, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys) {

//	if iteration > global.controller.MAX_MAP_DRAW_DISTANCE { return false; } // This is used for testing to short circuit out of the recursion after a certain number of iterations
//	if (iteration < distance_to_current_room) { distance_to_current_room = iteration; }
//	//visited = true; // NOT NECESSARY

//	// Add this room to list of visited rooms
//	if (!ds_list_contains(list_of_visited_rooms, id)) { ds_list_add(list_of_visited_rooms, id); }

//	// Add this room to list of available rooms with keys if it has one
//	if (has_key && !ds_list_contains(list_of_available_rooms_with_keys, id)) { ds_list_add(list_of_available_rooms_with_keys, id); }

//	// Create a list that's a copy of the list of visited rooms when this walk began.
//	var original_visited_rooms = ds_list_create();
//	ds_list_copy(original_visited_rooms, list_of_visited_rooms);

//	// For each of the cardinal directions, walk from here to each adjacent room and return if that walk was successful
//	for (var i = 0; i <= 4; i++;) {
//	    // Reset the list of visited rooms to the original set passed in for this room
//	    var next_list_of_visited_rooms = ds_list_create();
//	    ds_list_copy(next_list_of_visited_rooms, original_visited_rooms);
    
//	    // If the exit in this direction is locked, add it to list of locked exits
//	    if (locked_exits[i] && !ds_list_contains(list_of_unlocked_exits, locked_exits[i])) {
//	        if (!ds_list_contains(list_of_unlockable_exits, locked_exits[i])) { ds_list_add(list_of_unlockable_exits, locked_exits[i]); }
//	    }
//	    // Otherwise, walk the adjoining room in this direction if one exists and it hasn't yet been walked
//	    else if (!ds_list_contains(next_list_of_visited_rooms, adj_rooms[i])) {
//	        with adj_rooms[i] { 
//	            var array_of_returned_lists = walk_the_map(iteration+1, list_of_unlocked_exits, next_list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
//	            ds_list_combine(list_of_visited_rooms, array_of_returned_lists[0]); 
//	            ds_list_combine(list_of_unlockable_exits, array_of_returned_lists[1]); 
//	            ds_list_combine(list_of_available_rooms_with_keys, array_of_returned_lists[2]); 
//	        }
//	    }
		
//	    ds_list_destroy(next_list_of_visited_rooms);
//	}
//	ds_list_destroy(original_visited_rooms);

//	// return true only if the walk in each direction was successful
//	return array(list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys);
//}

/// @function									is_current_map_possible();
function is_current_map_possible() {
	var unlocked_exit_lists_to_verify = ds_list_create();
	var map_is_possible = true;
	
	// Start with a blank list of no locked exits and try verifying that
	ds_list_add(unlocked_exit_lists_to_verify, ds_list_create());
	
	// Verify each remaining list to verify is possible or map is impossible
	do {
		var current_unlocked_list = ds_list_pop_random_value(unlocked_exit_lists_to_verify);
		
		if (map_is_possible) {
			// Walk the map with the current unlocked list and set up variables based on how the walk went
			var current_walk_results = walk_the_map(current_unlocked_list);
			var visited_all_rooms = current_walk_results[0], keys_collected = current_walk_results[1], locked_exits_encountered = current_walk_results[2];
			var keys_spent = ds_list_size(current_unlocked_list);
			var keys_remaining = keys_collected - keys_spent;
		
			if (visited_all_rooms || keys_remaining >= ds_list_size(locked_exits_encountered)) { 
				// This walk is successful
			}
			else if (keys_remaining > 0) {
				// This walk could be successful if a walk through every currently available locked exit is successful.
				for (var i = 0; i < ds_list_size(locked_exits_encountered); i += 1;) {
					var new_unlocked_list_to_verify = ds_list_create();
					ds_list_copy(new_unlocked_list_to_verify, current_unlocked_list);
					ds_list_add(new_unlocked_list_to_verify, ds_list_find_value(locked_exits_encountered, i));
					ds_list_add(unlocked_exit_lists_to_verify, new_unlocked_list_to_verify);
				}
			}
			else {
				// Walking this map is impossible.
				map_is_possible = false;
			}
				
			ds_list_destroy(locked_exits_encountered);
		}
			
		ds_list_destroy(current_unlocked_list);
		
		// Cut off caluculations if it is becoming too complex
		if (ds_list_size(unlocked_exit_lists_to_verify) > 256) { map_is_possible = false; }
		show_debug_message(ds_list_size(unlocked_exit_lists_to_verify));
	}
	until (ds_list_size(unlocked_exit_lists_to_verify) == 0)
	
	return map_is_possible;
}

/// @function									walk_the_map(unlocked_exits);
/// @param		{index} unlocked_exits			The list of exits that have been unlocked by the player on this walk of the map.
function walk_the_map(unlocked_exits) {
	var visited_rooms = ds_list_create(), exits_to_walk_through = ds_list_create(), locked_exits = ds_list_create();
	var keys_found = 0;
	
	// Add the initial room to the visited rooms
	// Add each of that rooms exits to the list of exits to walk through
	with global.controller.current_room.id { walk_through_room(visited_rooms, exits_to_walk_through); }
	
	
	// Walk through each exit while there are still exits to walk through
	while (ds_list_size(exits_to_walk_through) > 0) {
		var chosen_exit = ds_list_pop_random_value(exits_to_walk_through);
		var chosen_room = chosen_exit[0], chosen_dir = chosen_exit[1], target_room = chosen_room.adj_rooms[chosen_dir];
		
		// If exit exists in this direction for this room and the adjoining room hasn't been visited yet
		if (chosen_room.exits[chosen_dir] && target_room && !ds_list_contains(visited_rooms, target_room.id)) {
			// If the exit in the chosen direction from the chosen room is not locked or is but is in the given list of unlocked_exits
			if (!chosen_room.locked_exits[chosen_dir] || ds_list_contains(unlocked_exits, chosen_room.locked_exits[chosen_dir].id)) {
				// Walk through the target room
				if (target_room.has_key) { keys_found += 1; }
				with target_room { walk_through_room(visited_rooms, exits_to_walk_through); }
			}
			// If the exit in the chosen direction from the chosen room is locked
			else if (chosen_room.locked_exits[chosen_dir]) {
				// Add this to the list of encountered locked exits
				ds_list_add(locked_exits, chosen_room.locked_exits[chosen_dir].id);
			}
		}
	}
	
	// Clean up ds_lists and return whether all rooms were visited or not
	var visited_all_rooms = (ds_list_size(visited_rooms) == instance_number(obj_room));
	ds_list_destroy(visited_rooms);
	ds_list_destroy(exits_to_walk_through);
	return array(visited_all_rooms, keys_found, locked_exits);
}

/// @function									walk_through_room(visited_rooms, exits_to_walk_through);
/// @param		{index} visited_rooms			The list of rooms that have been visited on this walk of the map.
/// @param		{index} exits_to_walk_through	The list of exits that need to be walked through to finish this walk of the map.
function walk_through_room(visited_rooms, exits_to_walk_through) {
	// Add this room to the list of visited rooms
	ds_list_add(visited_rooms, id);
	// Add each of this room's cardinal exits to the list of exits to try walking through at some point
	for (var i = 0; i <= 3; i += 1;) {
		ds_list_add(exits_to_walk_through, array(id, i));
	}
}