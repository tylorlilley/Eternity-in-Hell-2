/// @description  obj_controller_walk_the_map(iteration, list_of_unlocked_exits, list_of_visited_rooms, list_of_unlockable_exits, list_of_available_rooms_with_keys, ...)
function obj_controller_walk_the_map() {
	var iteration = argument[0], list_of_unlocked_exits = argument[1], list_of_visited_rooms = argument[2], list_of_unlockable_exits = argument[3], list_of_available_rooms_with_keys = argument[4];

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
