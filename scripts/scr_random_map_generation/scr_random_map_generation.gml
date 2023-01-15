/// @function									is_current_map_possible();
function is_current_map_possible() {
	var unlocked_exit_lists_to_verify = array_create(0);
	var map_is_possible = true;
	
	// Start with a blank list of no locked exits and try verifying that
	array_push(unlocked_exit_lists_to_verify, array_create(0));
	
	// Verify each remaining list to verify is possible or map is impossible
	do {
		var current_unlocked_list = array_random_pop(unlocked_exit_lists_to_verify);
		
		if (map_is_possible) {
			// Walk the map with the current unlocked list and set up variables based on how the walk went
			var current_walk_results = walk_the_map(current_unlocked_list);
			var visited_all_rooms = current_walk_results[0], keys_collected = current_walk_results[1], locked_exits_encountered = current_walk_results[2];
			var keys_spent = array_length(current_unlocked_list);
			var keys_remaining = keys_collected - keys_spent;
		
			if (visited_all_rooms) { // || keys_remaining >= array_length(locked_exits_encountered)) { 
				// This walk is successful
			}
			else if (keys_remaining > 0) {
				// This walk could be successful if a walk through every currently available locked exit is successful.
				for (var i = 0; i < array_length(locked_exits_encountered); i += 1;) {
					var new_unlocked_list_to_verify = array_create(0);
					array_duplicate(new_unlocked_list_to_verify, current_unlocked_list);
					array_push(new_unlocked_list_to_verify, array_get(locked_exits_encountered, i));
					array_push(unlocked_exit_lists_to_verify, new_unlocked_list_to_verify);
				}
			}
			else {
				// Walking this map is impossible.
				map_is_possible = false;
			}
		}
		// Cut off caluculations if it is becoming too complex
		if (array_length(unlocked_exit_lists_to_verify) > global.controller.MAX_WALKING_DEPTH) { map_is_possible = false; }
		//show_debug_message(array_length(unlocked_exit_lists_to_verify));
	}
	until (array_length(unlocked_exit_lists_to_verify) == 0)
	
	return map_is_possible;
}

/// @function									walk_the_map(unlocked_exits);
/// @param		{index} unlocked_exits			The list of exits that have been unlocked by the player on this walk of the map.
function walk_the_map(unlocked_exits) {
	var visited_rooms = array_create(0), exits_to_walk_through = array_create(0), locked_exits = array_create(0);
	var keys_found = 0;
	
	// Add the initial room to the visited rooms
	// Add each of that rooms exits to the list of exits to walk through
	with global.controller.current_room { 
		distance_from_start_room = 0;
		walk_through_room(visited_rooms, exits_to_walk_through); 
	}
	
	// Walk through each exit while there are still exits to walk through
	while (array_length(exits_to_walk_through) > 0) {
		var chosen_exit = array_random_pop(exits_to_walk_through);
		var chosen_room = chosen_exit[0], chosen_dir = chosen_exit[1], target_room = chosen_room.adj_rooms[chosen_dir];
		
		// If the adjoining room hasn't been visited yet
		if (chosen_room.distance_from_start_room + 1 < target_room.distance_from_start_room) { target_room.distance_from_start_room = chosen_room.distance_from_start_room + 1; }
		if (!array_contains(visited_rooms, target_room)) {
			// If the exit in the chosen direction from the chosen room is not locked or is but is in the given list of unlocked_exits
			if (!chosen_room.locked_exits[chosen_dir] || array_contains(unlocked_exits, chosen_room.locked_exits[chosen_dir])) {
				// Walk through the target room
				if (target_room.has_key) { keys_found += (target_room.has_special_item && (target_room.item_type = obj_key || target_room.item_type == noone)) ? 9999 : 1; } //if (keys_found >= 9999) { show_debug_message("SPECIAL KEY FOUND ON WALK"); } }
				with target_room { walk_through_room(visited_rooms, exits_to_walk_through); }
			}
			// If the exit in the chosen direction from the chosen room is locked
			else if (chosen_room.locked_exits[chosen_dir]) {
				// Add this to the list of encountered locked exits
				array_push(locked_exits, chosen_room.locked_exits[chosen_dir]);
			}
		}
	}
	
	// return whether all rooms were visited or not
	// TODO: Return struct with keys and not ordered array
	var visited_all_rooms = (array_length(visited_rooms) == array_length(global.controller.game_rooms));
	//var test = 2;
	return [visited_all_rooms, keys_found, locked_exits];
}

