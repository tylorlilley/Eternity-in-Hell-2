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
		if (ds_list_size(unlocked_exit_lists_to_verify) > global.controller.MAX_WALKING_DEPTH) { map_is_possible = false; }
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
		
		// If the adjoining room hasn't been visited yet
		if (!ds_list_contains(visited_rooms, target_room.id)) {
			// If the exit in the chosen direction from the chosen room is not locked or is but is in the given list of unlocked_exits
			if (!chosen_room.locked_exits[chosen_dir] || ds_list_contains(unlocked_exits, chosen_room.locked_exits[chosen_dir].id)) {
				// Walk through the target room
				if (target_room.has_key) { keys_found += (target_room.has_special_item) ? 9999 : 1; }
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
	// Add each of this room's exsiting exits to the list of exits to try walking through at some point
	for (var i = 0; i <= 4; i += 1;) {
		if (exits[i] && adj_rooms[i]) { ds_list_add(exits_to_walk_through, array(id, i)); }
	}
}